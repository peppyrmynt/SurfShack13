#define STAND_TIME_ERASURE_TRAIT "stand_time_erasure"

/// The arrow's budget is spent after choosing an ability, just as in Hippie's later system.
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

/datum/stand_stats/proc/apply(mob/living/basic/guardian/guardian)
	guardian.melee_damage_lower = damage * 5
	guardian.melee_damage_upper = damage * 5
	guardian.obj_damage = damage * 16
	guardian.melee_attack_cooldown = (22.5 / speed)
	var/resistance = max(0.25, (6 - defense) * 0.2)
	guardian.damage_coeff = list(BRUTE = resistance, BURN = resistance, TOX = resistance, STAMINA = 0, OXY = resistance)
	guardian.range = range * 2
	guardian.unleash()
	if(!QDELETED(guardian.summoner))
		guardian.leash_to(guardian, guardian.summoner)

/datum/stand_stats/proc/describe()
	var/list/grades = list("F", "D", "C", "B", "A")
	return "Damage: [grades[damage]] | Defense: [grades[defense]] | Speed: [grades[speed]] | Potential: [grades[potential]] | Range: [grades[range]]"

/// Plain modern guardian shell used by Hippie powers which have no stock SurfShack guardian type.
/mob/living/basic/guardian/arrow_stand
	guardian_type = GUARDIAN_STANDARD
	creator_name = "Stand"
	creator_desc = "A Stand awakened by a mysterious arrow. Its abilities and statistics are unpredictable."
	creator_icon = "standard"
	playstyle_string = span_holoparasite("You are a <b>Stand</b> awakened by a mysterious arrow. Your exact capabilities depend on your randomized power and statistics.")

/// Metadata connects arrow generation to modern guardian implementations.
/datum/stand_power
	var/name = "Stand"
	var/cost = 0
	var/weight = 1
	var/guardian_type = /mob/living/basic/guardian/arrow_stand

/datum/stand_power/assassin
	name = "Assassin"
	cost = 4
	weight = 0.9
	guardian_type = /mob/living/basic/guardian/assassin

/datum/stand_power/explosive
	name = "Explosive"
	cost = 4
	guardian_type = /mob/living/basic/guardian/explosive

/datum/stand_power/frenzy
	name = "Frenzy"
	cost = 3

/datum/stand_power/gravity
	name = "Gravity"
	cost = 3
	guardian_type = /mob/living/basic/guardian/gravitokinetic

/datum/stand_power/hand
	name = "The Hand"
	cost = 5

/datum/stand_power/healing
	name = "Healing"
	cost = 4
	weight = 1.1
	guardian_type = /mob/living/basic/guardian/support

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

/// Only arrow-created guardians have this component; stock guardians retain their existing balance.
/datum/component/arrow_stand
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/stand_stats/stats
	var/datum/stand_power/power
	var/requiem = FALSE
	var/transforming = FALSE
	var/datum/weakref/creator_arrow
	var/list/datum/action/granted_actions = list()
	var/list/mob/living/carbon/human/tracked_prey = list()

/datum/component/arrow_stand/Initialize(datum/stand_stats/stats, datum/stand_power/power, obj/item/stand_arrow/arrow)
	if(!isguardian(parent))
		return COMPONENT_INCOMPATIBLE
	src.stats = stats
	src.power = power
	creator_arrow = WEAKREF(arrow)
	stats.apply(parent)
	var/mob/living/basic/guardian/guardian = parent
	guardian.playstyle_string += "<br><b>[power.name]</b><br>[stats.describe()]"
	if(istype(guardian, /mob/living/basic/guardian/assassin))
		var/mob/living/basic/guardian/assassin/assassin = guardian
		assassin.stealth_cooldown_time = 7.5 SECONDS / stats.potential
	if(istype(guardian, /mob/living/basic/guardian/explosive))
		var/mob/living/basic/guardian/explosive/explosive = guardian
		explosive.bomb.decay_time = stats.potential * 18 SECONDS
	if(istype(guardian, /mob/living/basic/guardian/gravitokinetic))
		var/mob/living/basic/guardian/gravitokinetic/gravity = guardian
		gravity.gravity_power_range = stats.potential * 2
	if(istype(guardian, /mob/living/basic/guardian/support))
		var/datum/component/healing_touch/healing = guardian.GetComponent(/datum/component/healing_touch)
		if(healing)
			healing.heal_brute = stats.potential * 1.5
			healing.heal_burn = stats.potential * 1.5
			healing.heal_tox = stats.potential * 1.5
			healing.heal_oxy = stats.potential * 1.5
	setup_custom_power(guardian)

/datum/component/arrow_stand/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOB_GET_STATUS_TAB_ITEMS, PROC_REF(show_stats))
	if(istype(power, /datum/stand_power/frenzy))
		RegisterSignal(parent, COMSIG_GUARDIAN_MANIFESTED, PROC_REF(frenzy_manifested))
		RegisterSignal(parent, COMSIG_GUARDIAN_RECALLED, PROC_REF(frenzy_recalled))

/datum/component/arrow_stand/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_MOB_GET_STATUS_TAB_ITEMS, COMSIG_GUARDIAN_MANIFESTED, COMSIG_GUARDIAN_RECALLED))

/datum/component/arrow_stand/Destroy()
	var/mob/living/basic/guardian/guardian = parent
	if(istype(power, /datum/stand_power/frenzy) && !QDELETED(guardian))
		guardian.remove_movespeed_modifier(/datum/movespeed_modifier/stand_frenzy)
		guardian.summoner?.remove_movespeed_modifier(/datum/movespeed_modifier/stand_frenzy_summoner)
	if(istype(power, /datum/stand_power/scout) && !QDELETED(guardian))
		guardian.remove_status_effect(/datum/status_effect/guardian_scout_mode)
	QDEL_LIST(granted_actions)
	tracked_prey = null
	QDEL_NULL(stats)
	QDEL_NULL(power)
	return ..()

/datum/component/arrow_stand/proc/show_stats(mob/source, list/items)
	SIGNAL_HANDLER
	items += "[power.name][requiem ? " Requiem" : ""]"
	items += stats.describe()

/datum/component/arrow_stand/proc/grant_power_action(mob/living/basic/guardian/guardian, action_type)
	var/datum/action/action = new action_type(guardian)
	action.Grant(guardian)
	granted_actions += action
	return action

/datum/component/arrow_stand/proc/setup_custom_power(mob/living/basic/guardian/guardian)
	if(istype(power, /datum/stand_power/frenzy))
		guardian.add_movespeed_modifier(/datum/movespeed_modifier/stand_frenzy)
		grant_power_action(guardian, /datum/action/cooldown/mob_cooldown/stand_frenzy_rush)
		guardian.playstyle_string += "<br>Frenzy greatly increases your speed. While manifested, your summoner is accelerated too. Frenzy Rush teleports you into a target and knocks them away."
		return
	if(istype(power, /datum/stand_power/hand))
		var/datum/action/cooldown/mob_cooldown/stand_hand/hand = grant_power_action(guardian, /datum/action/cooldown/mob_cooldown/stand_hand)
		hand.cooldown_time = 10 SECONDS / stats.potential
		guardian.playstyle_string += "<br>The Hand erases the space between you and a distant tile, violently pulling its unanchored contents toward you."
		return
	if(istype(power, /datum/stand_power/predator))
		grant_power_action(guardian, /datum/action/cooldown/mob_cooldown/stand_predator_analyze)
		grant_power_action(guardian, /datum/action/cooldown/mob_cooldown/stand_predator_track)
		guardian.playstyle_string += "<br>Predator can learn identities from blood or fingerprints, then track learned prey. Potential improves tracking precision."
		return
	if(istype(power, /datum/stand_power/scout))
		grant_power_action(guardian, /datum/action/cooldown/mob_cooldown/stand_scout_toggle)
		guardian.playstyle_string += "<br>Scout mode makes you nearly invisible and incorporeal with unlimited leash range, but prevents interaction and attacks."
		return
	if(istype(power, /datum/stand_power/time_erasure))
		grant_power_action(guardian, /datum/action/cooldown/mob_cooldown/stand_time_erasure)
		guardian.playstyle_string += "<br>Time Erasure makes you, your summoner, and their linked Stands intangible and untouchable for a short period, but unable to attack. Potential increases its duration."

/datum/component/arrow_stand/proc/frenzy_manifested(mob/living/basic/guardian/source)
	SIGNAL_HANDLER
	if(!QDELETED(source.summoner))
		source.summoner.add_movespeed_modifier(/datum/movespeed_modifier/stand_frenzy_summoner)

/datum/component/arrow_stand/proc/frenzy_recalled(mob/living/basic/guardian/source)
	SIGNAL_HANDLER
	source.summoner?.remove_movespeed_modifier(/datum/movespeed_modifier/stand_frenzy_summoner)

/datum/movespeed_modifier/stand_frenzy
	multiplicative_slowdown = -1

/datum/movespeed_modifier/stand_frenzy_summoner
	multiplicative_slowdown = -1.5

/datum/action/cooldown/mob_cooldown/stand_power
	button_icon = 'icons/hud/guardian.dmi'
	button_icon_state = "standard"
	background_icon = 'icons/hud/guardian.dmi'
	background_icon_state = "base"
	shared_cooldown = NONE
	melee_cooldown_time = 0

/datum/action/cooldown/mob_cooldown/stand_power/proc/get_stand_component()
	if(!isguardian(owner))
		return null
	return owner.GetComponent(/datum/component/arrow_stand)

/datum/action/cooldown/mob_cooldown/stand_frenzy_rush
	parent_type = /datum/action/cooldown/mob_cooldown/stand_power
	name = "Frenzy Rush"
	desc = "Rush instantly into a living target, strike them, and knock them away."
	cooldown_time = 3 SECONDS
	click_to_activate = TRUE

/datum/action/cooldown/mob_cooldown/stand_frenzy_rush/Activate(atom/target)
	var/datum/component/arrow_stand/stand_component = get_stand_component()
	var/mob/living/basic/guardian/guardian = owner
	if(!stand_component || !guardian.is_deployed() || !isliving(target))
		return FALSE
	var/mob/living/living_target = target
	if(living_target == guardian || living_target == guardian.summoner || guardian.shares_summoner(living_target))
		return FALSE
	if(QDELETED(guardian.summoner) || get_dist_euclidean(guardian.summoner, living_target) > guardian.range)
		guardian.balloon_alert(guardian, "target is out of range!")
		return FALSE
	var/turf/destination = get_step(get_turf(living_target), get_dir(living_target, guardian))
	if(!destination)
		return FALSE
	guardian.forceMove(destination)
	guardian.face_atom(living_target)
	guardian.melee_attack(living_target, ignore_cooldown = TRUE)
	living_target.safe_throw_at(get_edge_target_turf(living_target, get_dir(guardian, living_target)), 4, 2, guardian)
	StartCooldown()
	return TRUE

/datum/action/cooldown/mob_cooldown/stand_hand
	parent_type = /datum/action/cooldown/mob_cooldown/stand_power
	name = "The Hand"
	desc = "Erase the intervening space and drag everything loose on a distant tile toward you."
	cooldown_time = 10 SECONDS
	click_to_activate = TRUE

/datum/action/cooldown/mob_cooldown/stand_hand/Activate(atom/target)
	var/datum/component/arrow_stand/stand_component = get_stand_component()
	var/mob/living/basic/guardian/guardian = owner
	if(!stand_component || !guardian.is_deployed() || !target || guardian.Adjacent(target) || !isturf(guardian.loc))
		return FALSE
	if(QDELETED(guardian.summoner) || get_dist_euclidean(guardian.summoner, target) > guardian.range)
		guardian.balloon_alert(guardian, "target is out of range!")
		return FALSE
	var/turf/source_turf = get_turf(target)
	var/turf/hand_turf = get_step(guardian, get_dir(guardian, source_turf))
	if(!source_turf || !hand_turf)
		return FALSE
	for(var/atom/movable/movable in source_turf)
		if(movable.anchored || movable == guardian)
			continue
		movable.forceMove(hand_turf)
		if(isliving(movable))
			var/mob/living/pulled = movable
			pulled.Stun(1 SECONDS)
	guardian.face_atom(hand_turf)
	StartCooldown()
	return TRUE

/datum/action/cooldown/mob_cooldown/stand_predator_analyze
	parent_type = /datum/action/cooldown/mob_cooldown/stand_power
	name = "Predator: Analyze Evidence"
	desc = "Analyze an adjacent atom for blood and fingerprints and learn any matching living identities."
	cooldown_time = 1 SECONDS
	click_to_activate = TRUE

/datum/action/cooldown/mob_cooldown/stand_predator_analyze/Activate(atom/target)
	var/datum/component/arrow_stand/stand_component = get_stand_component()
	if(!stand_component || !target || get_dist(owner, target) > 1)
		return FALSE
	var/list/prints = GET_ATOM_FINGERPRINTS(target)
	var/list/blood = GET_ATOM_BLOOD_DNA(target)
	var/found = FALSE
	for(var/mob/living/carbon/human/human in GLOB.alive_mob_list)
		if(QDELETED(human) || !human.dna)
			continue
		if((prints && prints[md5(human.dna.unique_identity)]) || (blood && blood[human.dna.unique_enzymes]))
			if(!(human in stand_component.tracked_prey))
				stand_component.tracked_prey += human
				to_chat(owner, span_notice("You learn the identity of [human.real_name]."))
			found = TRUE
	if(!found)
		owner.balloon_alert(owner, "no useful identity found")
	StartCooldown()
	return TRUE

/datum/action/cooldown/mob_cooldown/stand_predator_track
	parent_type = /datum/action/cooldown/mob_cooldown/stand_power
	name = "All-Seeing Predator"
	desc = "Track one of the identities you have learned from forensic evidence."
	cooldown_time = 60 SECONDS
	click_to_activate = FALSE

/datum/action/cooldown/mob_cooldown/stand_predator_track/Activate()
	var/datum/component/arrow_stand/stand_component = get_stand_component()
	if(!stand_component)
		return FALSE
	for(var/mob/living/carbon/human/prey as anything in stand_component.tracked_prey.Copy())
		if(QDELETED(prey) || prey.stat == DEAD)
			stand_component.tracked_prey -= prey
	if(!length(stand_component.tracked_prey))
		owner.balloon_alert(owner, "no prey learned")
		return FALSE
	var/mob/living/carbon/human/prey = tgui_input_list(owner, "Select your prey.", "All-Seeing Predator", sort_names(stand_component.tracked_prey))
	if(QDELETED(src) || QDELETED(owner) || QDELETED(prey))
		return FALSE
	var/turf/here = get_turf(owner)
	var/turf/there = get_turf(prey)
	if(!here || !there)
		return FALSE
	var/datum/component/arrow_stand/current_component = get_stand_component()
	if(!current_component)
		return FALSE
	if(here.z != there.z)
		if(current_component.stats.potential >= 4)
			to_chat(owner, span_notice("[prey.real_name] is far away, on z-level [there.z]."))
		else
			to_chat(owner, span_notice("[prey.real_name] is far away from here."))
	else
		var/direction = dir2text(get_dir(here, there))
		var/distance = round(get_dist_euclidean(here, there))
		var/fuzz = max(0, (10 / current_component.stats.potential) - 1)
		var/estimated_distance = max(0, distance + rand(-round(fuzz), round(fuzz)))
		to_chat(owner, span_notice("You sense [prey.real_name] to the [direction], roughly [estimated_distance] tile[estimated_distance == 1 ? "" : "s"] away."))
	owner.log_message("tracked [key_name(prey)] using Predator.", LOG_GAME)
	StartCooldown()
	return TRUE

/datum/action/cooldown/mob_cooldown/stand_scout_toggle
	parent_type = /datum/action/cooldown/mob_cooldown/stand_power
	name = "Toggle Scout Mode"
	desc = "Become nearly invisible and incorporeal with unlimited leash range, but unable to attack or interact."
	cooldown_time = 1 SECONDS
	click_to_activate = FALSE

/datum/action/cooldown/mob_cooldown/stand_scout_toggle/Activate()
	var/datum/component/arrow_stand/stand_component = get_stand_component()
	var/mob/living/basic/guardian/guardian = owner
	if(!stand_component)
		return FALSE
	if(guardian.has_status_effect(/datum/status_effect/guardian_scout_mode))
		guardian.remove_status_effect(/datum/status_effect/guardian_scout_mode)
	else
		if(guardian.is_deployed())
			guardian.balloon_alert(guardian, "recall before scouting!")
			return FALSE
		guardian.apply_status_effect(/datum/status_effect/guardian_scout_mode)
	StartCooldown()
	return TRUE

/datum/action/cooldown/mob_cooldown/stand_time_erasure
	parent_type = /datum/action/cooldown/mob_cooldown/stand_power
	name = "Erase Time"
	desc = "Erase yourself, your summoner, and their linked Stands from normal interaction for a short period."
	cooldown_time = 90 SECONDS
	click_to_activate = FALSE

/datum/action/cooldown/mob_cooldown/stand_time_erasure/Activate()
	var/datum/component/arrow_stand/stand_component = get_stand_component()
	var/mob/living/basic/guardian/guardian = owner
	if(!stand_component || !guardian.is_deployed())
		return FALSE
	var/duration = stand_component.stats.potential * 2 SECONDS
	var/list/mob/living/immune = list(guardian)
	if(!QDELETED(guardian.summoner))
		immune |= guardian.summoner
		for(var/mob/living/basic/guardian/linked_stand as anything in guardian.summoner.get_all_linked_holoparasites())
			immune |= linked_stand
	for(var/mob/living/affected as anything in immune)
		affected.apply_status_effect(/datum/status_effect/stand_time_erasure, duration)
	guardian.visible_message(span_holoparasite("The world seems to skip around [guardian] as time is erased!"))
	StartCooldown()
	return TRUE

/datum/status_effect/stand_time_erasure
	id = "stand_time_erasure"
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	var/old_density
	var/old_opacity
	var/old_mouse_opacity
	var/old_alpha
	var/had_godmode = FALSE

/datum/status_effect/stand_time_erasure/on_creation(mob/living/new_owner, duration = 2 SECONDS)
	src.duration = duration
	return ..()

/datum/status_effect/stand_time_erasure/on_apply()
	old_density = owner.density
	old_opacity = owner.opacity
	old_mouse_opacity = owner.mouse_opacity
	old_alpha = owner.alpha
	had_godmode = !!(owner.status_flags & GODMODE)
	owner.status_flags |= GODMODE
	owner.density = FALSE
	owner.opacity = FALSE
	owner.mouse_opacity = FALSE
	owner.alpha = 128
	ADD_TRAIT(owner, TRAIT_PACIFISM, STAND_TIME_ERASURE_TRAIT)
	return TRUE

/datum/status_effect/stand_time_erasure/on_remove()
	if(!had_godmode)
		owner.status_flags &= ~GODMODE
	owner.density = old_density
	owner.opacity = old_opacity
	owner.mouse_opacity = old_mouse_opacity
	owner.alpha = old_alpha
	REMOVE_TRAIT(owner, TRAIT_PACIFISM, STAND_TIME_ERASURE_TRAIT)

#undef STAND_TIME_ERASURE_TRAIT
