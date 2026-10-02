/**
 * # Body Molding Art
 *
 * The other road. Instead of gathering qi, you temper the flesh itself, one limb at a time, through nine stages
 * from Copper Skin to the Primordial Chaos Body. It's one or the other: a body cultivator's meridians are sealed into muscle,
 * and a qi cultivator can't go past mortal-level tempering.
 *
 * Anyone (a mortal) can reach the first stage, Copper Skin, just by training hard. Going further means committing to the
 * path by reading the Body Molding Art (or being accepted as a disciple), which closes the qi path for good.
 *
 * Loop: train (gym, fighting, getting hurt, mining, tempering pills) -> pending tempering -> Forge the Body to pour it into
 * one limb at a time -> once every limb is tempered past your stage, endure the Tribulation of Flesh to reach the next stage.
 *
 * Like the dantian, the power lives in the body: each limb carries its own tempering (a component on the bodypart),
 * so a severed arm takes its iron bones with it and a new arm has to be forged from scratch.
 */

/// Trait source for everything the body path grants
#define BODY_TRAIT_SOURCE "body_cultivation"
/// Trait source for benefits that come from specific limbs' tempering
#define BODY_PART_TRAIT_SOURCE "body_cultivation_parts"

/// Tempering needed to raise a limb to a level
#define BODY_PART_COST(level) (6 + 3 * (level))

/// The six limbs that are tempered
GLOBAL_LIST_INIT(body_tempered_zones, list(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))

// ===================== Limb tempering =====================

/// The tempering of one limb. Rides on the bodypart, so it goes wherever the limb goes.
/datum/component/body_tempering
	/// Tempered level, 0 to BODY_STAGE_MAX
	var/level = 0
	/// Progress towards the next level
	var/progress = 0
	/// Brute multiplier we applied to the limb
	var/applied_brute_factor = 1
	/// Wound resistance we added
	var/applied_wound_resistance = 0
	/// Unarmed damage we added (fists and kicks)
	var/applied_unarmed = 0

/datum/component/body_tempering/Initialize()
	if(!istype(parent, /obj/item/bodypart))
		return COMPONENT_INCOMPATIBLE

/datum/component/body_tempering/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))

/datum/component/body_tempering/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ATOM_EXAMINE)
	apply_level(0)

/datum/component/body_tempering/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(level)
		examine_list += span_notice("It has been tempered by the Body Molding Art (level [level]). It feels unnaturally dense.")

/// Set the limb's tempered level and its physical effects
/datum/component/body_tempering/proc/apply_level(new_level)
	var/obj/item/bodypart/part = parent
	var/new_factor = 1 - 0.03 * new_level
	part.brute_modifier = part.brute_modifier / applied_brute_factor * new_factor
	applied_brute_factor = new_factor
	part.wound_resistance += 3 * new_level - applied_wound_resistance
	applied_wound_resistance = 3 * new_level
	if(istype(part, /obj/item/bodypart/arm) || istype(part, /obj/item/bodypart/leg))
		part.unarmed_damage_low += new_level - applied_unarmed
		part.unarmed_damage_high += new_level - applied_unarmed
		applied_unarmed = new_level
	level = new_level

/// Pour tempering in. Returns how many levels were gained.
/datum/component/body_tempering/proc/add_progress(amount, cap)
	if(level >= cap)
		return 0
	progress += amount
	var/gained = 0
	while(level < cap && progress >= BODY_PART_COST(level + 1))
		progress -= BODY_PART_COST(level + 1)
		apply_level(level + 1)
		gained++
	if(level >= cap)
		progress = min(progress, BODY_PART_COST(level + 1) - 1)
	return gained

/// The tempered level of a mob's limb in a zone (0 if missing or untempered)
/proc/body_part_level(mob/living/carbon/body, zone)
	var/obj/item/bodypart/part = body?.get_bodypart(zone)
	var/datum/component/body_tempering/tempering = part?.GetComponent(/datum/component/body_tempering)
	return tempering ? tempering.level : 0

// ===================== The body cultivator =====================

/datum/antagonist/body_cultivator
	name = "\improper Body Cultivator"
	roundend_category = "body cultivators"
	antagpanel_category = "Cultivator"
	show_in_antagpanel = TRUE
	prevent_roundtype_conversion = FALSE
	antag_flags = FLAG_FAKE_ANTAG
	count_against_dynamic_roll_chance = FALSE
	ui_name = null
	suicide_cry = "MY BODY IS MY DAO!!"
	/// Body stage, 0 (untempered) to BODY_STAGE_MAX
	var/stage = 0
	/// Has committed to the path (read the Body Molding Art or was accepted as a disciple). Mortals stop at Copper Skin.
	var/committed = FALSE
	/// Tempering earned from training but not yet forged into a limb
	var/tempering = 0
	/// source -> world.time we can next earn tempering from it
	var/list/tempering_cooldowns = list()
	/// Techniques we've been granted
	var/list/datum/action/techniques = list()
	/// Max health we added
	var/applied_health = 0
	/// Running Tribulation of Flesh, if any
	var/datum/body_tribulation/tribulation
	var/tribulations_survived = 0
	var/tribulations_failed = 0
	/// Undying Flesh regrows lost limbs this often
	COOLDOWN_DECLARE(limb_regrowth_cooldown)

	/// Display names per stage (index = stage)
	var/static/list/stage_names = list("Copper Skin", "Iron Bone", "Steel Sinew", "Jade Marrow", "Crimson Blood", "Vajra Viscera", "Golden Body", "Undying Flesh", "Primordial Chaos Body")
	/// Max health added by each stage (cumulative)
	var/static/list/stage_health = list(10, 10, 10, 10, 15, 15, 15, 20, 20)
	/// What each stage gives you, for the panel
	var/static/list/stage_benefits = list(
		"+10 max health. Every tempered limb shrugs off brute damage and wounds, and fists and kicks hit harder.",
		"+10 max health. Bones that barely break (fewer wounds). Iron Shirt and Mountain Leap.",
		"+10 max health. Strength of an ox: faster gym gains, quicker fireman carries. Shattering Fist and Bone Setting.",
		"+10 max health. Marrow that makes blood fast and a heart that won't fail. Body Molding: regrow a lost limb.",
		"+15 max health. Wounds close on their own and pain doesn't slow you. Blood Boil.",
		"+15 max health. Organs like iron: half toxin damage, cold and low pressure don't hurt.",
		"+15 max health. A golden body: batons and needles don't bite. Vajra Golden Body.",
		"+20 max health. Undying: you fight on in critical condition, heal fast and regrow lost limbs on your own.",
		"+20 max health. Primordial Chaos Body: shock immune, vault anything. Primordial Roar.",
	)
	/// Body techniques, by stage required
	var/static/list/body_techniques = list(
		/datum/action/body_panel = 0,
		/datum/action/cooldown/spell/body_art/forge_body = 0,
		/datum/action/cooldown/spell/body_art/body_breakthrough = 0,
		/datum/action/cooldown/spell/body_art/iron_shirt = 2,
		/datum/action/cooldown/spell/pointed/body_art/mountain_leap = 2,
		/datum/action/cooldown/spell/pointed/body_art/shattering_fist = 3,
		/datum/action/cooldown/spell/body_art/bone_setting = 3,
		/datum/action/cooldown/spell/pointed/body_art/body_disciple = 3,
		/datum/action/cooldown/spell/body_art/remold_limb = 4,
		/datum/action/cooldown/spell/body_art/blood_boil = 5,
		/datum/action/cooldown/spell/body_art/vajra_body = 7,
		/datum/action/cooldown/spell/body_art/primordial_roar = 9,
	)

/datum/antagonist/body_cultivator/on_gain()
	. = ..()
	refresh_techniques()
	apply_stage_benefits()

/datum/antagonist/body_cultivator/on_removal()
	tribulation?.cancel("Your body cultivation is severed!")
	for(var/datum/action/technique as anything in techniques)
		qdel(technique)
	techniques.Cut()
	var/mob/living/body = owner.current
	if(body)
		clear_stage_benefits(body)
	return ..()

/datum/antagonist/body_cultivator/greet()
	. = ..()
	if(committed)
		to_chat(owner.current, span_boldnotice("You have committed to the Body Molding Art. Your meridians seal themselves into muscle and bone: the way of qi is closed to you, and the way of the flesh is endless."))
	else
		to_chat(owner.current, span_boldnotice("Your hard training has begun to temper your body!"))
		to_chat(owner.current, span_notice("Earn <b>tempering</b> by training at the gym, fighting, mining and taking hits, then use <b>Forge the Body</b> to pour it into a limb (it forges whichever part you have selected). \
			Temper all six limbs, then endure the <b>Tribulation of Flesh</b> to reach Copper Skin. Going further takes the Body Molding Art, and closes the way of qi."))

/datum/antagonist/body_cultivator/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = mob_override || owner.current
	RegisterSignal(current, COMSIG_LIVING_LIFE, PROC_REF(on_life))
	RegisterSignal(current, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(current, COMSIG_LIVING_UNARMED_ATTACK, PROC_REF(on_unarmed_attack))
	RegisterSignal(current, COMSIG_MOB_AFTER_APPLY_DAMAGE, PROC_REF(on_damaged))
	RegisterSignal(current, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, PROC_REF(damage_modifiers))
	RegisterSignals(current, list(COMSIG_CARBON_POST_ATTACH_LIMB, COMSIG_CARBON_POST_REMOVE_LIMB), PROC_REF(on_limbs_changed))
	apply_stage_benefits()

/datum/antagonist/body_cultivator/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = mob_override || owner.current
	UnregisterSignal(current, list(
		COMSIG_LIVING_LIFE,
		COMSIG_ATOM_EXAMINE,
		COMSIG_LIVING_UNARMED_ATTACK,
		COMSIG_MOB_AFTER_APPLY_DAMAGE,
		COMSIG_MOB_APPLY_DAMAGE_MODIFIERS,
		COMSIG_CARBON_POST_ATTACH_LIMB,
		COMSIG_CARBON_POST_REMOVE_LIMB,
	))
	clear_stage_benefits(current)

/datum/antagonist/body_cultivator/on_body_transfer(mob/living/old_body, mob/living/new_body)
	tribulation?.cancel("Your soul is torn from your body mid-tribulation!")
	return ..()

// ----- Accessors -----

/datum/antagonist/body_cultivator/proc/stage_name(stage_to_name = stage)
	if(stage_to_name <= 0)
		return "Untempered"
	return stage_names[clamp(stage_to_name, 1, length(stage_names))]

/// Highest stage this cultivator can reach
/datum/antagonist/body_cultivator/proc/stage_cap()
	return committed ? BODY_STAGE_MAX : BODY_STAGE_MORTAL_CAP

/// Highest level a limb can be forged to right now
/datum/antagonist/body_cultivator/proc/part_cap()
	return min(stage + 1, stage_cap())

/// Where this body stands among qi cultivators, for realm comparisons (Realm Pressure, artifacts, sect ranks)
/datum/antagonist/body_cultivator/proc/realm_equivalent()
	if(stage <= 0)
		return REALM_MORTAL
	return min(round((stage + 1) / 2), REALM_MAX)

/// Lowest tempered level across all six limbs (a missing limb counts as 0)
/datum/antagonist/body_cultivator/proc/weakest_part_level()
	var/lowest = BODY_STAGE_MAX
	for(var/zone in GLOB.body_tempered_zones)
		lowest = min(lowest, body_part_level(owner.current, zone))
	return lowest

/datum/antagonist/body_cultivator/proc/can_attempt_tribulation()
	return stage < stage_cap() && weakest_part_level() >= stage + 1

// ----- Tempering -----

/// Earn tempering from training. Each source has its own cooldown. Returns the amount gained.
/datum/antagonist/body_cultivator/proc/gain_tempering(amount, source, cooldown = 30 SECONDS, silent = FALSE)
	if(amount <= 0)
		return 0
	if(source)
		if(world.time < tempering_cooldowns[source])
			return 0
		tempering_cooldowns[source] = world.time + cooldown
	var/gained = min(amount, BODY_TEMPERING_CAP - tempering)
	if(gained <= 0)
		if(!silent)
			to_chat(owner.current, span_warning("Your body can't absorb any more training. Forge the Body to temper a limb!"))
		return 0
	tempering += gained
	owner.current?.balloon_alert(owner.current, "+[round(gained, 0.1)] tempering")
	return gained

/// Pour pending tempering into one limb. Returns levels gained.
/datum/antagonist/body_cultivator/proc/forge_part(obj/item/bodypart/part, amount)
	var/datum/component/body_tempering/part_tempering = part.GetComponent(/datum/component/body_tempering) || part.AddComponent(/datum/component/body_tempering)
	amount = min(amount, tempering)
	tempering -= amount
	var/gained = part_tempering.add_progress(amount, part_cap())
	if(gained)
		on_limbs_changed()
	return gained

// ----- Stage benefits -----

/datum/antagonist/body_cultivator/proc/clear_stage_benefits(mob/living/body)
	body.remove_traits(list(TRAIT_HARDLY_WOUNDED, TRAIT_STRENGTH, TRAIT_QUICKER_CARRY, TRAIT_STABLEHEART, TRAIT_ANALGESIA, TRAIT_RESISTCOLD, TRAIT_RESISTLOWPRESSURE, \
		TRAIT_BATON_RESISTANCE, TRAIT_PIERCEIMMUNE, TRAIT_NOSOFTCRIT, TRAIT_SHOCKIMMUNE, TRAIT_FREERUNNING), BODY_TRAIT_SOURCE)
	body.remove_traits(list(TRAIT_NIGHT_VISION, TRAIT_NOFLASH, TRAIT_FREERUNNING), BODY_PART_TRAIT_SOURCE)
	body.maxHealth -= applied_health
	applied_health = 0
	body.updatehealth()
	body.update_sight()

/datum/antagonist/body_cultivator/proc/apply_stage_benefits()
	var/mob/living/body = owner.current
	if(!body)
		return
	clear_stage_benefits(body)
	var/health_bonus = 0
	for(var/i in 1 to stage)
		health_bonus += stage_health[i]
	applied_health = health_bonus
	body.maxHealth += applied_health
	var/list/traits = list()
	if(stage >= 2)
		traits += TRAIT_HARDLY_WOUNDED
	if(stage >= 3)
		traits += list(TRAIT_STRENGTH, TRAIT_QUICKER_CARRY)
	if(stage >= 4)
		traits += TRAIT_STABLEHEART
	if(stage >= 5)
		traits += TRAIT_ANALGESIA
	if(stage >= 6)
		traits += list(TRAIT_RESISTCOLD, TRAIT_RESISTLOWPRESSURE)
	if(stage >= 7)
		traits += list(TRAIT_BATON_RESISTANCE, TRAIT_PIERCEIMMUNE)
	if(stage >= 8)
		traits += TRAIT_NOSOFTCRIT
	if(stage >= 9)
		traits += list(TRAIT_SHOCKIMMUNE, TRAIT_FREERUNNING)
	if(length(traits))
		body.add_traits(traits, BODY_TRAIT_SOURCE)
	body.updatehealth()
	on_limbs_changed()

/// Benefits that come from particular limbs: tempered eyes and legs
/datum/antagonist/body_cultivator/proc/on_limbs_changed(datum/source)
	SIGNAL_HANDLER
	var/mob/living/carbon/body = owner.current
	if(!istype(body))
		return
	body.remove_traits(list(TRAIT_NIGHT_VISION, TRAIT_NOFLASH, TRAIT_FREERUNNING), BODY_PART_TRAIT_SOURCE)
	var/head_level = body_part_level(body, BODY_ZONE_HEAD)
	if(head_level >= 4)
		ADD_TRAIT(body, TRAIT_NIGHT_VISION, BODY_PART_TRAIT_SOURCE)
	if(head_level >= 6)
		ADD_TRAIT(body, TRAIT_NOFLASH, BODY_PART_TRAIT_SOURCE)
	if(min(body_part_level(body, BODY_ZONE_L_LEG), body_part_level(body, BODY_ZONE_R_LEG)) >= 4)
		ADD_TRAIT(body, TRAIT_FREERUNNING, BODY_PART_TRAIT_SOURCE)
	body.update_sight()

/datum/antagonist/body_cultivator/proc/refresh_techniques()
	for(var/technique_type in body_techniques)
		if(stage < body_techniques[technique_type])
			continue
		if(technique_type == /datum/action/cooldown/spell/pointed/body_art/body_disciple && !committed)
			continue
		grant_technique(technique_type)

/datum/antagonist/body_cultivator/proc/grant_technique(technique_type)
	for(var/datum/action/technique as anything in techniques)
		if(technique.type == technique_type)
			return technique
	var/datum/action/new_technique = new technique_type(owner)
	techniques += new_technique
	RegisterSignal(new_technique, COMSIG_QDELETING, PROC_REF(on_technique_deleted))
	if(owner.current)
		new_technique.Grant(owner.current)
	return new_technique

/datum/antagonist/body_cultivator/proc/on_technique_deleted(datum/action/source)
	SIGNAL_HANDLER
	techniques -= source

/// Commit to the full path. Closes the way of qi.
/datum/antagonist/body_cultivator/proc/commit()
	if(committed)
		return FALSE
	committed = TRUE
	to_chat(owner.current, span_boldnotice("You commit to the Body Molding Art. Your meridians seal into muscle and bone: the way of qi is closed to you, but your body can now be forged to the Primordial Chaos Body."))
	new /obj/effect/temp_visual/circle_wave/cultivation/earth(get_turf(owner.current))
	refresh_techniques()
	return TRUE

/datum/antagonist/body_cultivator/proc/advance_stage()
	stage = min(stage + 1, BODY_STAGE_MAX)
	tribulations_survived++
	refresh_techniques()
	apply_stage_benefits()
	owner.current?.fully_heal(HEAL_DAMAGE)
	SEND_SIGNAL(owner.current, COMSIG_MOB_CULTIVATION_REALM_CHANGED, null)

// ----- Life and training -----

/datum/antagonist/body_cultivator/proc/on_life(mob/living/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER
	if(source.stat == DEAD)
		return
	if(stage >= 4 && iscarbon(source))
		var/mob/living/carbon/carbon_source = source
		if(carbon_source.blood_volume < BLOOD_VOLUME_NORMAL)
			carbon_source.blood_volume = min(carbon_source.blood_volume + 1 * seconds_per_tick, BLOOD_VOLUME_NORMAL)
	if(stage >= 5 && (source.getBruteLoss() || source.getFireLoss()))
		var/regen = (stage >= 8 ? 0.8 : 0.3) * seconds_per_tick
		source.heal_overall_damage(brute = regen, burn = regen)
	if(stage >= 8 && iscarbon(source) && COOLDOWN_FINISHED(src, limb_regrowth_cooldown))
		var/mob/living/carbon/carbon_source = source
		var/list/missing = carbon_source.get_missing_limbs()
		if(length(missing))
			COOLDOWN_START(src, limb_regrowth_cooldown, 2 MINUTES)
			var/zone = pick(missing)
			carbon_source.regenerate_limb(zone)
			carbon_source.visible_message(span_warning("Flesh boils out of [carbon_source]'s stump and knits itself into a new limb!"), span_notice("Your undying flesh regrows your [parse_zone(zone)]."))

/// Punching things (people, walls, bags) toughens the arms that do it
/datum/antagonist/body_cultivator/proc/on_unarmed_attack(mob/living/source, atom/target, proximity, modifiers)
	SIGNAL_HANDLER
	if(!proximity)
		return
	if(isliving(target) && target != source)
		gain_tempering(2, BODY_TRAINING_FIGHT, 30 SECONDS, silent = TRUE)
	else if(isclosedturf(target) || istype(target, /obj/structure/punching_bag))
		gain_tempering(3, BODY_TRAINING_STRIKE, 45 SECONDS, silent = TRUE)

/// Being beaten is training too
/datum/antagonist/body_cultivator/proc/on_damaged(mob/living/source, damage, damagetype, def_zone, blocked, wound_bonus, bare_wound_bonus, sharpness, attack_direction, attacking_item)
	SIGNAL_HANDLER
	if(damage >= 5 && (damagetype == BRUTE || damagetype == BURN) && source.stat == CONSCIOUS)
		gain_tempering(2, BODY_TRAINING_BEATEN, 30 SECONDS, silent = TRUE)

/datum/antagonist/body_cultivator/proc/damage_modifiers(mob/living/source, list/damage_mods, damage, damagetype, ...)
	SIGNAL_HANDLER
	if(damagetype == TOX && stage >= 6)
		damage_mods += 0.5

/// Training any mob does: gym work starts mortals on the path, everything else only counts once they're on it
/proc/body_cultivation_train(mob/living/user, amount, source, cooldown = 60 SECONDS, can_start = FALSE)
	if(!ishuman(user) || !user.mind || IS_CULTIVATOR(user))
		return 0
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(user)
	if(!body_datum)
		if(!can_start)
			return 0
		body_datum = user.mind.add_antag_datum(/datum/antagonist/body_cultivator)
	return body_datum.gain_tempering(amount, source, cooldown, silent = TRUE)

// ----- Examine, roundend, admin -----

/datum/antagonist/body_cultivator/proc/on_examine(mob/living/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	var/static/list/physique = list(
		"%THEIR% skin has a faint coppery sheen.",
		"%THEY_ARE% built like an iron statue.",
		"Steel-cable sinews ripple under %THEIR% skin.",
		"%THEY_ARE% unnervingly solid, like something carved from jade.",
		"%THEIR% veins glow a faint crimson.",
		"%THEY_ARE% so dense the floor creaks under %THEM%.",
		"%THEIR% skin gleams like a temple's golden statue.",
		"Every wound on %THEM% seems to be closing as you watch.",
		"Looking at %THEM% too long makes your eyes ache, like staring at the first mountain.",
	)
	if(stage <= 0)
		return
	var/line = physique[stage]
	line = replacetext(line, "%THEIR%", source.p_their())
	line = replacetext(line, "%THEY_ARE%", "[source.p_They()] [source.p_are()]")
	line = replacetext(line, "%THEM%", source.p_them())
	examine_list += span_notice(capitalize(line))
	var/their_realm = cultivation_realm_of(user)
	if(IS_CULTIVATOR(user) || IS_BODY_CULTIVATOR(user))
		examine_list += span_notice("A body cultivator at [stage_name()][their_realm < realm_equivalent() ? ". You would not want to trade blows." : "."]")

/datum/antagonist/body_cultivator/roundend_report()
	var/list/report = list()
	report += printplayer(owner)
	report += "Tempered [owner.current?.p_their() || "their"] body to <b>[stage_name()]</b>[committed ? " on the Body Molding Art" : " through mortal training"]."
	report += "Tribulations of Flesh survived: [tribulations_survived]. Failed: [tribulations_failed]."
	return report.Join("<br>")

/datum/antagonist/body_cultivator/get_admin_commands()
	. = ..()
	.["Commit to Body Molding Art"] = CALLBACK(src, PROC_REF(commit))
	.["Give 50 Tempering"] = CALLBACK(src, PROC_REF(admin_give_tempering))
	.["Force Stage Up (tempers all limbs)"] = CALLBACK(src, PROC_REF(admin_stage_up))

/datum/antagonist/body_cultivator/proc/admin_give_tempering(mob/admin)
	tempering = min(tempering + 50, BODY_TEMPERING_CAP)

/datum/antagonist/body_cultivator/proc/admin_stage_up(mob/admin)
	var/mob/living/carbon/body = owner.current
	if(!istype(body) || stage >= BODY_STAGE_MAX)
		return
	for(var/obj/item/bodypart/part as anything in body.bodyparts)
		var/datum/component/body_tempering/part_tempering = part.GetComponent(/datum/component/body_tempering) || part.AddComponent(/datum/component/body_tempering)
		part_tempering.apply_level(max(part_tempering.level, stage + 1))
	advance_stage()

#undef BODY_TRAIT_SOURCE
#undef BODY_PART_TRAIT_SOURCE
