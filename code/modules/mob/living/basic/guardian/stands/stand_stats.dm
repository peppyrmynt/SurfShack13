/// Randomized JoJo-style stats used only by arrow-created guardians.
/datum/stand_stats
	var/damage = 1
	var/defense = 1
	var/speed = 1
	var/potential = 1
	var/range = 1

/datum/stand_stats/proc/randomize(points)
	var/list/categories = list(NAMEOF(src, damage), NAMEOF(src, defense), NAMEOF(src, speed), NAMEOF(src, potential), NAMEOF(src, range))
	while(points > 0 && length(categories))
		var/category = pick(categories)
		vars[category]++
		points--
		if(vars[category] >= 5)
			categories -= category

/datum/stand_stats/proc/requiem_upgrade()
	for(var/category in list(NAMEOF(src, damage), NAMEOF(src, defense), NAMEOF(src, speed), NAMEOF(src, potential), NAMEOF(src, range)))
		vars[category] = min(vars[category] + rand(1, 3), 5)

/datum/stand_stats/proc/apply(mob/living/basic/guardian/guardian)
	guardian.melee_damage_lower = damage * 5
	guardian.melee_damage_upper = damage * 5
	guardian.obj_damage = damage * 16
	guardian.melee_attack_cooldown = 22.5 / speed
	var/resistance = max(0.25, (6 - defense) * 0.2)
	guardian.damage_coeff = list(BRUTE = resistance, BURN = resistance, TOX = resistance, STAMINA = 0, OXY = resistance)
	guardian.range = range * 2
	guardian.unleash()
	if(!QDELETED(guardian.summoner))
		guardian.leash_to(guardian, guardian.summoner)

/datum/stand_stats/proc/describe()
	var/list/grades = list("F", "D", "C", "B", "A")
	return "Damage: [grades[damage]] | Defense: [grades[defense]] | Speed: [grades[speed]] | Potential: [grades[potential]] | Range: [grades[range]]"

/// Every arrow Stand uses one neutral modern Guardian shell so its major power can be completely replaced by Requiem.
/mob/living/basic/guardian/arrow_stand
	guardian_type = GUARDIAN_STANDARD
	creator_name = "Stand"
	creator_desc = "A Stand awakened by a mysterious arrow. Its abilities and statistics are unpredictable."
	creator_icon = "standard"
	playstyle_string = span_holoparasite("You are a <b>Stand</b> awakened by a mysterious arrow.")

/// Metadata for Hippie's normal Stand-arrow major abilities.
/datum/stand_power
	var/name = "Stand"
	var/cost = 0
	var/weight = 1
	var/guardian_type = /mob/living/basic/guardian/arrow_stand

/datum/stand_power/assassin
	name = "Assassin"
	cost = 4
	weight = 0.9

/datum/stand_power/explosive
	name = "Explosive"
	cost = 4

/datum/stand_power/frenzy
	name = "Frenzy"
	cost = 3

/datum/stand_power/gravity
	name = "Gravity"
	cost = 3

/datum/stand_power/hand
	name = "The Hand"
	cost = 5

/datum/stand_power/healing
	name = "Healing"
	cost = 4
	weight = 1.1

/datum/stand_power/predator
	name = "Predator"
	cost = 2

/datum/stand_power/scout
	name = "Scout"
	cost = 1

/datum/stand_power/time_erasure
	name = "Time Erasure"
	cost = 6
	weight = 0.2

/// Arrow-only component which owns all temporary power state. Stock guardians remain untouched.
/datum/component/arrow_stand
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/stand_stats/stats
	var/datum/stand_power/power
	var/requiem = FALSE
	var/transforming = FALSE
	var/datum/weakref/creator_arrow
	var/base_playstyle_string
	var/list/datum/action/granted_actions = list()
	var/list/mob/living/carbon/human/tracked_prey = list()
	var/list/gravity_targets = list()
	var/datum/component/healing_touch/healing_touch

/datum/component/arrow_stand/Initialize(datum/stand_stats/stats, datum/stand_power/power, obj/item/stand_arrow/arrow)
	if(!isguardian(parent))
		return COMPONENT_INCOMPATIBLE
	src.stats = stats
	src.power = power
	creator_arrow = WEAKREF(arrow)
	var/mob/living/basic/guardian/guardian = parent
	base_playstyle_string = guardian.playstyle_string
	stats.apply(guardian)
	setup_major_power()

/datum/component/arrow_stand/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOB_GET_STATUS_TAB_ITEMS, PROC_REF(show_stats))

/datum/component/arrow_stand/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_GET_STATUS_TAB_ITEMS)

/datum/component/arrow_stand/Destroy()
	clear_major_power()
	QDEL_NULL(stats)
	QDEL_NULL(power)
	return ..()

/datum/component/arrow_stand/proc/show_stats(mob/source, list/items)
	SIGNAL_HANDLER
	items += "[power?.name || "Stand"][requiem ? " Requiem" : ""]"
	items += stats.describe()

/datum/component/arrow_stand/proc/rebuild_playstyle(power_text)
	var/mob/living/basic/guardian/guardian = parent
	guardian.playstyle_string = "[base_playstyle_string]<br><b>[power.name][requiem ? " Requiem" : ""]</b><br>[stats.describe()]<br>[power_text]"

/datum/component/arrow_stand/proc/grant_power_action(action_type)
	var/mob/living/basic/guardian/guardian = parent
	var/datum/action/action = new action_type(guardian)
	action.Grant(guardian)
	granted_actions += action
	return action

/// Remove everything belonging to the current major power. Requiem relies on this being complete.
/datum/component/arrow_stand/proc/clear_major_power()
	var/mob/living/basic/guardian/guardian = parent
	if(QDELETED(guardian))
		return
	UnregisterSignal(guardian, list(COMSIG_GUARDIAN_MANIFESTED, COMSIG_GUARDIAN_RECALLED, COMSIG_HOSTILE_POST_ATTACKINGTARGET, COMSIG_MOVABLE_MOVED))
	guardian.remove_movespeed_modifier(/datum/movespeed_modifier/stand_frenzy)
	guardian.summoner?.remove_movespeed_modifier(/datum/movespeed_modifier/stand_frenzy_summoner)
	guardian.remove_status_effect(/datum/status_effect/stand_assassin_stealth)
	guardian.remove_status_effect(/datum/status_effect/guardian_scout_mode)
	guardian.remove_status_effect(/datum/status_effect/stand_time_erasure)
	if(!QDELETED(guardian.summoner))
		guardian.summoner.remove_status_effect(/datum/status_effect/stand_time_erasure)
		for(var/mob/living/basic/guardian/linked as anything in guardian.summoner.get_all_linked_holoparasites())
			linked.remove_status_effect(/datum/status_effect/stand_time_erasure)
	for(var/datum/action/action as anything in granted_actions)
		qdel(action)
	granted_actions.Cut()
	QDEL_NULL(healing_touch)
	GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]?.hide_from(guardian)
	clear_gravity_targets()
	tracked_prey.Cut()

/datum/component/arrow_stand/proc/replace_major_power(power_type)
	clear_major_power()
	QDEL_NULL(power)
	power = new power_type
	setup_major_power()

/datum/component/arrow_stand/proc/setup_major_power()
	var/mob/living/basic/guardian/guardian = parent
	if(istype(power, /datum/stand_power/assassin))
		var/datum/action/cooldown/mob_cooldown/stand_assassin_stealth/stealth = grant_power_action(/datum/action/cooldown/mob_cooldown/stand_assassin_stealth)
		stealth.cooldown_time = 7.5 SECONDS / stats.potential
		rebuild_playstyle("Enter near-invisible stealth. Your next attack deals 50 damage with full armor penetration; attacking, taking damage, or recalling breaks stealth.")
		return
	if(istype(power, /datum/stand_power/explosive))
		var/datum/action/cooldown/mob_cooldown/stand_explosive_trap/bomb = grant_power_action(/datum/action/cooldown/mob_cooldown/stand_explosive_trap)
		bomb.decay_time = stats.potential * 18 SECONDS
		RegisterSignal(guardian, COMSIG_HOSTILE_POST_ATTACKINGTARGET, PROC_REF(explosive_attack))
		rebuild_playstyle("Turn an object into a hidden explosive trap. Successful punches also have a 40% chance to violently displace and blast the target.")
		return
	if(istype(power, /datum/stand_power/frenzy))
		guardian.add_movespeed_modifier(/datum/movespeed_modifier/stand_frenzy)
		RegisterSignal(guardian, COMSIG_GUARDIAN_MANIFESTED, PROC_REF(frenzy_manifested))
		RegisterSignal(guardian, COMSIG_GUARDIAN_RECALLED, PROC_REF(frenzy_recalled))
		grant_power_action(/datum/action/cooldown/mob_cooldown/stand_frenzy_rush)
		rebuild_playstyle("Move at extreme speed. While manifested your summoner is accelerated too; Frenzy Rush closes distance and knocks a victim away.")
		return
	if(istype(power, /datum/stand_power/gravity))
		RegisterSignal(guardian, COMSIG_HOSTILE_POST_ATTACKINGTARGET, PROC_REF(gravity_attack))
		RegisterSignal(guardian, COMSIG_MOVABLE_MOVED, PROC_REF(gravity_source_moved))
		rebuild_playstyle("Punches apply crushing gravity to living targets while they remain within your Potential-scaled influence range.")
		return
	if(istype(power, /datum/stand_power/hand))
		var/datum/action/cooldown/mob_cooldown/stand_hand/hand = grant_power_action(/datum/action/cooldown/mob_cooldown/stand_hand)
		hand.cooldown_time = 10 SECONDS / stats.potential
		rebuild_playstyle("Erase the space between yourself and a distant tile, dragging its loose contents violently toward you.")
		return
	if(istype(power, /datum/stand_power/healing))
		var/healing_amount = stats.potential * 1.5
		healing_touch = guardian.AddComponent(\
			/datum/component/healing_touch,\
			heal_brute = healing_amount,\
			heal_burn = healing_amount,\
			heal_tox = healing_amount,\
			heal_oxy = healing_amount,\
			heal_time = 0,\
			action_text = "",\
			complete_text = "",\
			required_modifier = RIGHT_CLICK,\
		)
		GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]?.show_to(guardian)
		rebuild_playstyle("Right-click living targets to heal brute, burn, toxin, and oxygen damage by an amount scaled by Potential.")
		return
	if(istype(power, /datum/stand_power/predator))
		grant_power_action(/datum/action/cooldown/mob_cooldown/stand_predator_analyze)
		grant_power_action(/datum/action/cooldown/mob_cooldown/stand_predator_track)
		rebuild_playstyle("Learn identities from adjacent blood or fingerprints, then track learned prey. Potential improves tracking precision.")
		return
	if(istype(power, /datum/stand_power/scout))
		grant_power_action(/datum/action/cooldown/mob_cooldown/stand_scout_toggle)
		rebuild_playstyle("Scout mode makes you nearly invisible, incorporeal, and effectively unlimited-range, but unable to attack or interact.")
		return
	if(istype(power, /datum/stand_power/time_erasure))
		grant_power_action(/datum/action/cooldown/mob_cooldown/stand_time_erasure)
		rebuild_playstyle("Erase yourself, your summoner, and allied Stands from normal interaction for a Potential-scaled duration. You cannot attack while erased.")

/datum/component/arrow_stand/proc/frenzy_manifested(mob/living/basic/guardian/source)
	SIGNAL_HANDLER
	if(!QDELETED(source.summoner))
		source.summoner.add_movespeed_modifier(/datum/movespeed_modifier/stand_frenzy_summoner)

/datum/component/arrow_stand/proc/frenzy_recalled(mob/living/basic/guardian/source)
	SIGNAL_HANDLER
	source.summoner?.remove_movespeed_modifier(/datum/movespeed_modifier/stand_frenzy_summoner)

/datum/component/arrow_stand/proc/explosive_attack(mob/living/basic/guardian/source, atom/target, success)
	SIGNAL_HANDLER
	if(!success || !isliving(target) || !prob(40))
		return
	var/mob/living/victim = target
	if(victim.anchored || victim == source.summoner || source.shares_summoner(victim))
		return
	new /obj/effect/temp_visual/guardian/phase/out(get_turf(victim))
	do_teleport(victim, victim, 10, channel = TELEPORT_CHANNEL_BLUESPACE)
	for(var/mob/living/nearby in range(1, victim))
		if(nearby == source || nearby == source.summoner || source.shares_summoner(nearby))
			continue
		nearby.apply_damage(15, BRUTE)
	new /obj/effect/temp_visual/explosion(get_turf(victim))

/datum/component/arrow_stand/proc/gravity_attack(mob/living/basic/guardian/source, atom/target, success)
	SIGNAL_HANDLER
	if(!success || !isliving(target) || target == source || target == source.summoner || source.shares_summoner(target) || gravity_targets[target])
		return
	var/mob/living/victim = target
	victim.AddElement(/datum/element/forced_gravity, 5)
	gravity_targets[victim] = 5
	RegisterSignal(victim, COMSIG_MOVABLE_MOVED, PROC_REF(gravity_target_moved))
	RegisterSignal(victim, COMSIG_QDELETING, PROC_REF(gravity_target_deleted))
	playsound(source, 'sound/effects/gravhit.ogg', 100, TRUE)
	to_chat(source, span_bolddanger("Your punch applies crushing gravity to [victim]!"))
	to_chat(victim, span_userdanger("Everything feels incredibly heavy!"))

/datum/component/arrow_stand/proc/gravity_source_moved()
	SIGNAL_HANDLER
	check_gravity_ranges()

/datum/component/arrow_stand/proc/gravity_target_moved(atom/movable/source)
	SIGNAL_HANDLER
	check_gravity_target(source)

/datum/component/arrow_stand/proc/gravity_target_deleted(atom/source)
	SIGNAL_HANDLER
	gravity_targets -= source

/datum/component/arrow_stand/proc/check_gravity_ranges()
	for(var/atom/target as anything in gravity_targets.Copy())
		check_gravity_target(target)

/datum/component/arrow_stand/proc/check_gravity_target(atom/target)
	var/mob/living/basic/guardian/guardian = parent
	if(QDELETED(target) || get_dist(guardian, target) > stats.potential * 2)
		remove_gravity_target(target)

/datum/component/arrow_stand/proc/remove_gravity_target(atom/target)
	var/gravity_strength = gravity_targets[target]
	if(isnull(gravity_strength))
		return
	if(!QDELETED(target))
		UnregisterSignal(target, list(COMSIG_MOVABLE_MOVED, COMSIG_QDELETING))
		target.RemoveElement(/datum/element/forced_gravity, gravity_strength)
	gravity_targets -= target

/datum/component/arrow_stand/proc/clear_gravity_targets()
	for(var/atom/target as anything in gravity_targets.Copy())
		remove_gravity_target(target)

#include "stand_powers.dm"
