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
#define BODY_PART_COST(level) (6 + 4 * (level))

/// The six limbs that are tempered
GLOBAL_LIST_INIT(body_tempered_zones, list(BODY_ZONE_HEAD, BODY_ZONE_CHEST, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))

/**
 * Nine powers per body part type. Head and chest use their own level, arms and legs use the weaker of the pair
 * (arm strike powers use the arm you hit with). Each entry: list(name, description, trait or null).
 */
GLOBAL_LIST_INIT(body_part_powers, list(
	"head" = list(
		list("Keen Ears", "You hear whispers from further away.", TRAIT_GOOD_HEARING),
		list("Clear Eyes", "You see in the dark.", TRAIT_NIGHT_VISION),
		list("Unblinking Eyes", "Flashes can't blind you.", TRAIT_NOFLASH),
		list("Hunter's Sight", "True night vision: darkness hides nothing.", TRAIT_TRUE_NIGHT_VISION),
		list("Still Mind", "Sleep and sedation can't take you.", TRAIT_SLEEPIMMUNE),
		list("Heat Sight", "You see the warmth of living things through walls.", TRAIT_THERMAL_VISION),
		list("Indomitable Will", "Pain doesn't slow you.", TRAIT_ANALGESIA),
		list("Iron Skull", "Your head can't be severed.", null),
		list("Primordial Gaze", "You see straight through walls.", TRAIT_XRAY_VISION),
	),
	"chest" = list(
		list("Iron Belly", "Nothing turns your stomach.", TRAIT_STRONG_STOMACH),
		list("Bellows Lungs", "Half damage from suffocation.", null),
		list("Iron Guts", "Half damage from toxins.", null),
		list("Stable Heart", "Your heart never fails.", TRAIT_STABLEHEART),
		list("Furnace Core", "Cold and heat don't hurt you.", null),
		list("Endless Wind", "Half stamina damage.", null),
		list("Pressure-Proof Body", "Low and high pressure don't hurt you.", null),
		list("Heart of the Mountain", "You fight on in critical condition.", TRAIT_NOSOFTCRIT),
		list("Breathless Body", "You no longer need to breathe. With Furnace Core and Pressure-Proof Body, you can walk through space.", TRAIT_NOBREATH),
	),
	"arms" = list(
		list("Iron Palms", "Hot things don't burn your hands.", TRAIT_RESISTHEATHANDS),
		list("Quick Hands", "You carry people faster.", TRAIT_QUICKER_CARRY),
		list("Iron Grip", "Your grabs start aggressive.", TRAIT_STRONG_GRABBER),
		list("Strength of an Ox", "Faster gym gains and stronger lifts.", TRAIT_STRENGTH),
		list("Crushing Blows", "Punches with a level 5 arm stagger.", null),
		list("Toppling Blows", "Punches with a level 6 arm sometimes knock people down.", null),
		list("Thunder Fists", "Punches with a level 7 arm sometimes hurl people back.", null),
		list("Breaking Fists", "Punches with a level 8 arm smash windows, tables, grilles and machines.", null),
		list("Mountain-Breaking Fists", "Punches with a level 9 arm knock down plain walls.", null),
	),
	"legs" = list(
		list("Light Step", "You tread lightly over glass and sharp things.", TRAIT_LIGHT_STEP),
		list("Sure Footing", "Wet floors don't slip you.", TRAIT_NO_SLIP_WATER),
		list("Swift Feet", "You move a little faster.", null),
		list("Vaulting", "You vault over tables.", TRAIT_FREERUNNING),
		list("Sturdy Frame", "Heavy equipment barely slows you.", TRAIT_STURDY_FRAME),
		list("Rooted", "You can't be shoved.", TRAIT_PUSHIMMUNE),
		list("Silent Stride", "Your footsteps make no sound, and you're faster still.", TRAIT_SILENT_FOOTSTEPS),
		list("Unslippable", "Nothing makes you slip.", TRAIT_NO_SLIP_ALL),
		list("Thousand-League Legs", "Nothing slows you down, and you're faster still.", TRAIT_IGNORESLOWDOWN),
	),
))

/// The level a body part type counts as: its own level for head and chest, the weaker of the pair for arms and legs
/proc/body_group_level(mob/living/carbon/body, group)
	switch(group)
		if("head")
			return body_part_level(body, BODY_ZONE_HEAD)
		if("chest")
			return body_part_level(body, BODY_ZONE_CHEST)
		if("arms")
			return min(body_part_level(body, BODY_ZONE_L_ARM), body_part_level(body, BODY_ZONE_R_ARM))
		if("legs")
			return min(body_part_level(body, BODY_ZONE_L_LEG), body_part_level(body, BODY_ZONE_R_LEG))
	return 0

/datum/movespeed_modifier/body_swift_feet
	multiplicative_slowdown = -0.1

/datum/movespeed_modifier/body_silent_stride
	multiplicative_slowdown = -0.2

/datum/movespeed_modifier/body_thousand_league
	multiplicative_slowdown = -0.3

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
	/// Mountain-Breaking Fists can only fell a wall this often
	COOLDOWN_DECLARE(wall_punch_cooldown)
	/// Traits the body part powers currently grant
	var/list/part_traits = list()
	/// The head Iron Skull made unremovable, so we can give it back
	var/datum/weakref/iron_skull_ref

	/// Display names per stage (index = stage)
	var/static/list/stage_names = list("Copper Skin", "Iron Bone", "Steel Sinew", "Jade Marrow", "Crimson Blood", "Vajra Viscera", "Golden Body", "Undying Flesh", "Primordial Chaos Body")
	/// Max health added by each stage (cumulative)
	var/static/list/stage_health = list(10, 10, 10, 10, 15, 15, 15, 20, 20)
	/// What each stage gives you, for the panel
	var/static/list/stage_benefits = list(
		"+10 max health.",
		"+10 max health. Bones that barely break (fewer wounds). Iron Shirt, Mountain Leap, Earth-Shattering Stomp.",
		"+10 max health. Stamina comes back fast. Shattering Fist, Hundred Fist Barrage, Bone Setting, Accept Body Disciple.",
		"+10 max health. Marrow that makes blood fast. Remold Limb (regrow a lost limb), Raging Bull Charge.",
		"+15 max health. Wounds close on their own. Blood Boil, Falling Mountain Descent, Mountain-Toppling Throw.",
		"+15 max health. Organs that heal themselves. Sky-Splitting Palm; Raging Bull Charge breaks walls.",
		"+15 max health. A golden body: batons and needles don't bite, Shattering Fist breaks walls. Vajra Golden Body.",
		"+20 max health. Undying: heal fast and regrow lost limbs on your own. Heaven-Shaking Quake.",
		"+20 max health. Primordial Chaos Body: shock immune. Primordial Roar.",
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
		/datum/action/cooldown/spell/body_art/earth_stomp = 2,
		/datum/action/cooldown/spell/pointed/body_art/hundred_fists = 3,
		/datum/action/cooldown/spell/pointed/body_art/bull_charge = 4,
		/datum/action/cooldown/spell/pointed/body_art/falling_star = 5,
		/datum/action/cooldown/spell/pointed/body_art/mountain_hurl = 5,
		/datum/action/cooldown/spell/pointed/body_art/sky_splitting_palm = 6,
		/datum/action/cooldown/spell/body_art/heaven_quake = 8,
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
	body.remove_traits(list(TRAIT_HARDLY_WOUNDED, TRAIT_BATON_RESISTANCE, TRAIT_PIERCEIMMUNE, TRAIT_SHOCKIMMUNE), BODY_TRAIT_SOURCE)
	clear_part_powers(body)
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
	if(stage >= 7)
		traits += list(TRAIT_BATON_RESISTANCE, TRAIT_PIERCEIMMUNE)
	if(stage >= 9)
		traits += TRAIT_SHOCKIMMUNE
	if(length(traits))
		body.add_traits(traits, BODY_TRAIT_SOURCE)
	body.updatehealth()
	on_limbs_changed()

/datum/antagonist/body_cultivator/proc/clear_part_powers(mob/living/body)
	if(length(part_traits))
		body.remove_traits(part_traits, BODY_PART_TRAIT_SOURCE)
	part_traits = list()
	body.remove_movespeed_modifier(/datum/movespeed_modifier/body_swift_feet)
	body.remove_movespeed_modifier(/datum/movespeed_modifier/body_silent_stride)
	body.remove_movespeed_modifier(/datum/movespeed_modifier/body_thousand_league)
	var/obj/item/bodypart/head/iron_skull = iron_skull_ref?.resolve()
	if(iron_skull)
		iron_skull.bodypart_flags &= ~BODYPART_UNREMOVABLE
	iron_skull_ref = null

/// Re-apply every body part power from the limbs this body has right now
/datum/antagonist/body_cultivator/proc/on_limbs_changed(datum/source)
	SIGNAL_HANDLER
	var/mob/living/carbon/body = owner.current
	if(!istype(body))
		return
	clear_part_powers(body)
	for(var/group in GLOB.body_part_powers)
		var/level = body_group_level(body, group)
		var/list/powers = GLOB.body_part_powers[group]
		for(var/i in 1 to min(level, length(powers)))
			var/list/power = powers[i]
			if(power[3])
				part_traits |= power[3]
	var/chest_level = body_group_level(body, "chest")
	if(chest_level >= 5)
		part_traits |= list(TRAIT_RESISTCOLD, TRAIT_RESISTHEAT)
	if(chest_level >= 7)
		part_traits |= list(TRAIT_RESISTLOWPRESSURE, TRAIT_RESISTHIGHPRESSURE)
	if(length(part_traits))
		body.add_traits(part_traits, BODY_PART_TRAIT_SOURCE)
	var/legs_level = body_group_level(body, "legs")
	if(legs_level >= 9)
		body.add_movespeed_modifier(/datum/movespeed_modifier/body_thousand_league)
	else if(legs_level >= 7)
		body.add_movespeed_modifier(/datum/movespeed_modifier/body_silent_stride)
	else if(legs_level >= 3)
		body.add_movespeed_modifier(/datum/movespeed_modifier/body_swift_feet)
	var/obj/item/bodypart/head/head = body.get_bodypart(BODY_ZONE_HEAD)
	if(head && body_group_level(body, "head") >= 8 && !(head.bodypart_flags & BODYPART_UNREMOVABLE))
		head.bodypart_flags |= BODYPART_UNREMOVABLE
		iron_skull_ref = WEAKREF(head)
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
	if(stage >= 3 && source.getStaminaLoss())
		source.adjustStaminaLoss(-1 * seconds_per_tick)
	if(stage >= 6 && iscarbon(source))
		var/mob/living/carbon/organ_owner = source
		for(var/obj/item/organ/organ as anything in organ_owner.organs)
			if(organ.damage && !(organ.organ_flags & ORGAN_ROBOTIC))
				organ.apply_organ_damage(-0.2 * seconds_per_tick)
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

/// Punching things (people, walls, bags) is training, and a forged arm hits like it
/datum/antagonist/body_cultivator/proc/on_unarmed_attack(mob/living/source, atom/target, proximity, modifiers)
	SIGNAL_HANDLER
	if(!proximity)
		return
	if(isliving(target) && target != source)
		gain_tempering(2, BODY_TRAINING_FIGHT, 30 SECONDS, silent = TRUE)
	else if(isclosedturf(target) || istype(target, /obj/structure/punching_bag))
		gain_tempering(3, BODY_TRAINING_STRIKE, 45 SECONDS, silent = TRUE)
	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		return
	var/obj/item/bodypart/arm = source.get_active_hand()
	var/datum/component/body_tempering/arm_tempering = arm?.GetComponent(/datum/component/body_tempering)
	if(!arm_tempering || arm_tempering.level < 5)
		return
	INVOKE_ASYNC(src, PROC_REF(forged_strike), source, target, arm_tempering.level)

/// What a forged arm's punch does on top of the punch
/datum/antagonist/body_cultivator/proc/forged_strike(mob/living/source, atom/target, arm_level)
	if(isliving(target))
		var/mob/living/victim = target
		if(victim.stat == DEAD || cultivation_realm_of(victim) > cultivation_realm_of(source))
			return
		victim.adjust_staggered_up_to(STAGGERED_SLOWDOWN_LENGTH, 10 SECONDS)
		if(arm_level >= 7 && prob(25) && !HAS_TRAIT(victim, TRAIT_PUSHIMMUNE))
			victim.visible_message(span_danger("[source]'s punch hurls [victim] back like a thunderclap!"))
			playsound(victim, 'sound/effects/meteorimpact.ogg', 30, TRUE)
			victim.throw_at(get_edge_target_turf(victim, get_dir(source, victim)), 2, 2, source)
		else if(arm_level >= 6 && prob(15))
			victim.Knockdown(1 SECONDS)
		return
	if(arm_level >= 9 && iswallturf(target) && !istype(target, /turf/closed/wall/r_wall) && COOLDOWN_FINISHED(src, wall_punch_cooldown))
		COOLDOWN_START(src, wall_punch_cooldown, 5 SECONDS)
		source.visible_message(span_danger("[source] punches clean through [target]!"))
		playsound(target, 'sound/effects/meteorimpact.ogg', 60, TRUE)
		body_art_smash(target, source, 0, break_walls = TRUE)
		return
	if(arm_level >= 8 && isobj(target))
		var/obj/thing = target
		if(!(thing.resistance_flags & INDESTRUCTIBLE) && (isstructure(thing) || ismachinery(thing)))
			thing.take_damage(25, BRUTE, MELEE)

/// Being beaten is training too
/datum/antagonist/body_cultivator/proc/on_damaged(mob/living/source, damage, damagetype, def_zone, blocked, wound_bonus, bare_wound_bonus, sharpness, attack_direction, attacking_item)
	SIGNAL_HANDLER
	if(damage >= 5 && (damagetype == BRUTE || damagetype == BURN) && source.stat == CONSCIOUS)
		gain_tempering(2, BODY_TRAINING_BEATEN, 30 SECONDS, silent = TRUE)

/datum/antagonist/body_cultivator/proc/damage_modifiers(mob/living/source, list/damage_mods, damage, damagetype, ...)
	SIGNAL_HANDLER
	var/chest_level = body_group_level(source, "chest")
	switch(damagetype)
		if(OXY)
			if(chest_level >= 2)
				damage_mods += 0.5
		if(TOX)
			if(chest_level >= 3)
				damage_mods += 0.5
		if(STAMINA)
			if(chest_level >= 6)
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
