/*
 * Ultraviolent gore helpers.
 *
 * Hotline Miami style carnage: blood pools, gib streaks, bodies flung into walls, exploding heads, spilled organs.
 * None of these procs deal extra damage on their own, they only destroy what was already lethal.
 * Brains are always spilled rather than deleted so victims stay revivable through a brain transplant.
 */

/// Fewest times a fresh corpse's blood pool spreads.
#define GORE_POOL_SPREADS_MIN 4
/// Most times a fresh corpse's blood pool spreads.
#define GORE_POOL_SPREADS_MAX 9
/// Shortest time between each spread of a corpse's blood pool, in deciseconds.
#define GORE_POOL_SPREAD_DELAY_MIN 8
/// Longest time between each spread of a corpse's blood pool, in deciseconds.
#define GORE_POOL_SPREAD_DELAY_MAX 22
/// How far floor splatters get nudged off the centre of their tile, so they don't all line up on the grid.
#define GORE_SPLATTER_NUDGE 7
/// How far away people are horrified by ultraviolence.
#define GORE_WITNESS_RANGE 7

/// Returns TRUE if this mob's body can be torn apart by gore effects.
/mob/living/carbon/proc/can_be_gored()
	return !HAS_TRAIT(src, TRAIT_GODMODE) && !HAS_TRAIT(src, TRAIT_NODISMEMBER)

/// Returns TRUE if this mob has red blood to paint the room with.
/mob/living/carbon/proc/can_gore_bleed()
	return !HAS_TRAIT(src, TRAIT_NOBLOOD) && get_blood_id() == /datum/reagent/blood

/**
 * Picks a direction close to the passed one, so sprays fan out instead of all flying in a straight line.
 * Mostly dead on, sometimes 45 degrees off, rarely 90.
 */
/proc/gore_jitter_dir(direction)
	if(!direction)
		return pick(GLOB.alldirs)
	switch(rand(1, 100))
		if(1 to 55)
			return direction
		if(56 to 75)
			return turn(direction, 45)
		if(76 to 95)
			return turn(direction, -45)
		else
			return turn(direction, pick(90, -90))

/// Adds a floor splatter to the turf and nudges it off-grid so pools look organic.
/mob/living/carbon/proc/gore_splatter_floor(turf/target_turf, small_drip = FALSE)
	if(!target_turf)
		return
	add_splatter_floor(target_turf, small_drip)
	var/obj/effect/decal/cleanable/blood/splatter = locate() in target_turf
	if(splatter)
		splatter.pixel_x = rand(-GORE_SPLATTER_NUDGE, GORE_SPLATTER_NUDGE)
		splatter.pixel_y = rand(-GORE_SPLATTER_NUDGE, GORE_SPLATTER_NUDGE)

/**
 * Sprays blood out of us. Each call is different: how many sprays, how far they fly,
 * and which way they fan out around splatter_dir are all randomised.
 *
 * Arguments:
 * * strength - rough strength of the spray, 1 to 5.
 * * splatter_dir - direction the blood mostly flies in, or null for everywhere.
 * * max_sprays - most sprays this call can make.
 */
/mob/living/carbon/proc/gore_spray(strength = 2, splatter_dir, max_sprays = 2)
	if(!can_gore_bleed() || !isturf(loc))
		return
	for(var/i in 1 to rand(1, max(max_sprays, 1)))
		var/direction = (splatter_dir && prob(85)) ? gore_jitter_dir(splatter_dir) : pick(GLOB.alldirs)
		spray_blood(direction, clamp(strength + rand(-1, 1), 1, 6))

/**
 * Paints the floor around us red. No two bursts look the same: the size, spread,
 * number of sprays and trail of drips are all rolled each time.
 *
 * Arguments:
 * * intensity - 1 to 5, roughly how much of the room gets covered.
 * * splatter_dir - optional direction the blood should mostly fly in, for that "shot from the doorway" look.
 */
/mob/living/carbon/proc/gore_blood_burst(intensity = 1, splatter_dir)
	var/turf/location = get_turf(src)
	if(!location || !can_gore_bleed())
		return

	intensity = clamp(intensity + rand(-1, 1), 1, 5)
	gore_splatter_floor(location)

	// Patchy pool around the body, leaning towards the direction of the hit.
	var/radius = intensity >= 4 ? rand(1, 2) : (intensity >= 2 ? 1 : 0)
	for(var/turf/open/nearby_turf in range(radius, location))
		var/chance = 25 + intensity * 10
		if(splatter_dir && (get_dir(location, nearby_turf) & splatter_dir))
			chance += 25
		if(get_dist(location, nearby_turf) > 1)
			chance -= 30
		if(prob(chance))
			gore_splatter_floor(nearby_turf)

	// Splatters that reach a wall paint it, which is most of the look.
	gore_spray(intensity, splatter_dir, intensity + rand(0, intensity))

	// A few drips flung further out.
	for(var/i in 1 to rand(0, intensity))
		var/turf/drip_turf = get_ranged_target_turf(src, gore_jitter_dir(splatter_dir), rand(1, intensity + 1))
		if(isopenturf(drip_turf))
			gore_splatter_floor(drip_turf, small_drip = TRUE)

	playsound(location, 'sound/effects/wounds/splatter.ogg', rand(45, 70), TRUE)

/// Slowly spreads a pool of blood out from under a fresh corpse, at an uneven pace.
/mob/living/carbon/proc/gore_blood_pool(spreads_left = rand(GORE_POOL_SPREADS_MIN, GORE_POOL_SPREADS_MAX))
	if(QDELETED(src) || spreads_left <= 0 || !can_gore_bleed())
		return
	var/turf/location = get_turf(src)
	if(!location)
		return
	var/list/pool_turfs = list(location, location) // twice as likely to pool right under the body
	for(var/turf/open/adjacent in orange(1, location))
		pool_turfs += adjacent
	gore_splatter_floor(pick(pool_turfs), small_drip = prob(30))
	addtimer(CALLBACK(src, PROC_REF(gore_blood_pool), spreads_left - 1), rand(GORE_POOL_SPREAD_DELAY_MIN, GORE_POOL_SPREAD_DELAY_MAX))

/**
 * Flings the body backwards, smearing blood along every tile it slides over.
 *
 * Arguments:
 * * fling_dir - direction to fling in.
 * * distance - max tiles; stops early at walls.
 * * thrower - who's responsible.
 */
/mob/living/carbon/proc/gore_fling(fling_dir, distance, mob/living/thrower)
	if(!fling_dir || distance <= 0 || anchored || buckled || !isturf(loc))
		return
	var/turf/landing = get_turf(src)
	for(var/i in 1 to distance)
		var/turf/next = get_step(landing, fling_dir)
		if(!next || next.is_blocked_turf(exclude_mobs = TRUE))
			break
		landing = next
		if(can_gore_bleed())
			gore_splatter_floor(landing, small_drip = prob(35))
	if(landing == get_turf(src))
		return
	throw_at(landing, distance, 2, thrower, spin = FALSE)

/// Everyone who can see this gets their mood hit. Morbid folks and the truly evil enjoy the show.
/mob/living/carbon/proc/gore_witnessed(mob/living/attacker)
	for(var/mob/living/carbon/witness in viewers(GORE_WITNESS_RANGE, src))
		if(witness == src || witness == attacker || witness.stat != CONSCIOUS || witness.is_blind())
			continue
		if(HAS_TRAIT(witness, TRAIT_MORBID) || HAS_TRAIT(witness, TRAIT_EVIL))
			witness.add_mood_event("ultraviolence", /datum/mood_event/ultraviolence_enjoyed)
		else
			witness.add_mood_event("ultraviolence", /datum/mood_event/ultraviolence_witnessed)

/**
 * Rips the organs in the given zone out of us and scatters them on the floor.
 *
 * Only ever moves organs that are really inside this body right now. It never creates organs, so a body with
 * nothing left in that zone spills nothing, and an organ can't be spilled twice.
 * Gib decals only appear when something was actually spilled.
 *
 * Returns the list of organs that ended up on the floor.
 */
/mob/living/carbon/proc/gore_spill_organs(zone, splatter_dir)
	var/atom/drop_loc = drop_location()
	// Nowhere to put them (nullspace), so leave them where they are.
	if(!drop_loc)
		return list()
	var/list/obj/item/organ/to_spill = list()
	for(var/obj/item/organ/organ as anything in organs)
		if(QDELETED(organ) || organ.owner != src || check_zone(organ.zone) != zone)
			continue
		if(organ.organ_flags & ORGAN_UNREMOVABLE)
			continue
		to_spill += organ

	var/list/obj/item/organ/spilled_organs = list()
	for(var/obj/item/organ/organ as anything in to_spill)
		// Something earlier in this loop (like the brain leaving) may have already taken it out or deleted it.
		if(QDELETED(organ) || organ.owner != src)
			continue
		organ.Remove(src)
		// Some organs delete themselves or refuse to leave when removed.
		if(QDELETED(organ) || organ.owner)
			continue
		organ.forceMove(drop_loc)
		if(can_gore_bleed())
			organ.add_mob_blood(src)
		var/throw_dir = splatter_dir && prob(60) ? splatter_dir : pick(GLOB.alldirs)
		organ.throw_at(get_ranged_target_turf(src, throw_dir, rand(1, 3)), 3, 2)
		spilled_organs += organ

	if(length(spilled_organs) && can_gore_bleed())
		var/obj/effect/decal/cleanable/blood/gibs/gibs = new(get_turf(drop_loc))
		gibs.add_blood_DNA(get_blood_dna_list())
		gibs.streak(splatter_dir ? list(splatter_dir, turn(splatter_dir, 45), turn(splatter_dir, -45)) : GLOB.alldirs)
	return spilled_organs

/**
 * Pops our head like a grape. Organs inside the head are thrown out, the head itself is destroyed or ripped off.
 *
 * Arguments:
 * * attacker - who did it, for messages and logs.
 * * splatter_dir - direction the mess flies in.
 * * method - GORE_HEAD_CRUSHED, GORE_HEAD_BLASTED or GORE_HEAD_STABBED, changes the flavour text and sound.
 * * delete_head - if TRUE the head is destroyed, otherwise it's torn off whole.
 */
/mob/living/carbon/proc/gore_destroy_head(mob/living/attacker, splatter_dir, method = GORE_HEAD_BLASTED, delete_head = TRUE)
	var/obj/item/bodypart/head/head_part = get_bodypart(BODY_ZONE_HEAD)
	if(!head_part || !can_be_gored())
		return FALSE

	var/verb_text
	var/sound_file
	switch(method)
		if(GORE_HEAD_CRUSHED)
			verb_text = "caved in"
			sound_file = 'sound/effects/wounds/crackandbleed.ogg'
		if(GORE_HEAD_STABBED)
			verb_text = "stabbed into pulp"
			sound_file = 'sound/effects/wounds/pierce1.ogg'
		else
			verb_text = "blown apart"
			sound_file = 'sound/effects/splat.ogg'

	var/spilled_anything = length(gore_spill_organs(BODY_ZONE_HEAD, splatter_dir))
	visible_message(
		span_danger("<B>[src]'s head is [verb_text], spraying blood[spilled_anything ? " and brains" : ""] everywhere!</B>"),
		span_userdanger("Your head is [verb_text]!"),
		span_hear("You hear a sickening wet crunch!"),
		ignored_mobs = attacker,
	)
	if(attacker && attacker != src)
		to_chat(attacker, span_danger("[src]'s head is [verb_text] in a shower of gore!"))
	playsound(src, sound_file, 80, TRUE)
	gore_blood_burst(5, splatter_dir)
	if(can_gore_bleed())
		head_part.add_mob_blood(src)

	if(delete_head)
		head_part.drop_limb(dismembered = TRUE)
		qdel(head_part)
	else
		var/wounding_type = WOUND_PIERCE
		if(method == GORE_HEAD_CRUSHED)
			wounding_type = WOUND_BLUNT
		head_part.dismember(BRUTE, silent = TRUE, wounding_type = wounding_type)

	if(attacker)
		log_combat(attacker, src, "destroyed the head of (ultraviolence)")
	return TRUE

/// Cuts our head clean off.
/mob/living/carbon/proc/gore_decapitate(mob/living/attacker, splatter_dir)
	var/obj/item/bodypart/head/head_part = get_bodypart(BODY_ZONE_HEAD)
	if(!head_part || !can_be_gored())
		return FALSE

	visible_message(
		span_danger("<B>[src]'s head is hacked clean off!</B>"),
		span_userdanger("Your head is hacked clean off!"),
		span_hear("You hear a wet slicing sound!"),
		ignored_mobs = attacker,
	)
	if(attacker && attacker != src)
		to_chat(attacker, span_danger("You hack [src]'s head clean off!"))
	gore_blood_burst(4, splatter_dir)
	if(!head_part.dismember(BRUTE, silent = TRUE, wounding_type = WOUND_SLASH))
		return FALSE

	if(attacker)
		log_combat(attacker, src, "decapitated (ultraviolence)")
	return TRUE

/// Bursts our chest open and throws our guts on the floor.
/mob/living/carbon/proc/gore_disembowel(mob/living/attacker, splatter_dir)
	var/obj/item/bodypart/chest/chest_part = get_bodypart(BODY_ZONE_CHEST)
	if(!chest_part || !can_be_gored())
		return FALSE

	var/list/spilled = gore_spill_organs(BODY_ZONE_CHEST, splatter_dir)
	if(chest_part.cavity_item)
		chest_part.cavity_item.forceMove(drop_location())
		spilled += chest_part.cavity_item
		chest_part.cavity_item = null
	if(!length(spilled))
		return FALSE

	visible_message(
		span_danger("<B>[src]'s chest bursts open, spilling [p_their()] guts across the floor!</B>"),
		span_userdanger("Your chest bursts open!"),
		span_hear("You hear a horrible wet tearing sound!"),
		ignored_mobs = attacker,
	)
	if(attacker && attacker != src)
		to_chat(attacker, span_danger("[src]'s chest bursts open, spilling [p_their()] guts!"))
	playsound(src, 'sound/misc/splort.ogg', 80, TRUE)
	gore_blood_burst(3, splatter_dir)

	if(attacker)
		log_combat(attacker, src, "disemboweled (ultraviolence)")
	return TRUE

/// Cleaves us in half at the waist: both legs go flying and our guts pour out of the gap.
/mob/living/carbon/proc/gore_bisect(mob/living/attacker, splatter_dir)
	if(!get_bodypart(BODY_ZONE_CHEST) || !can_be_gored())
		return FALSE
	var/list/obj/item/bodypart/legs = list()
	for(var/zone in list(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
		var/obj/item/bodypart/leg = get_bodypart(zone)
		if(leg)
			legs += leg
	if(!length(legs))
		return FALSE

	visible_message(
		span_danger("<B>[src] is cleaved in half at the waist!</B>"),
		span_userdanger("You are cleaved in half!"),
		span_hear("You hear something heavy tear apart!"),
		ignored_mobs = attacker,
	)
	if(attacker && attacker != src)
		to_chat(attacker, span_danger("You cleave [src] in half!"))

	for(var/obj/item/bodypart/leg as anything in legs)
		leg.dismember(BRUTE, silent = TRUE, wounding_type = WOUND_SLASH)
	gore_spill_organs(BODY_ZONE_CHEST, splatter_dir)
	gore_blood_burst(5, splatter_dir)

	if(attacker)
		log_combat(attacker, src, "bisected (ultraviolence)")
	return TRUE

/// Tears off the limb in the given zone and sends it flying.
/mob/living/carbon/proc/gore_sever_limb(zone, mob/living/attacker, splatter_dir)
	var/obj/item/bodypart/limb = get_bodypart(zone)
	if(!limb || !can_be_gored())
		return FALSE

	gore_blood_burst(2, splatter_dir)
	if(!limb.dismember(BRUTE, silent = FALSE, wounding_type = WOUND_SLASH))
		return FALSE

	if(attacker)
		log_combat(attacker, src, "severed the [parse_zone(zone)] of (ultraviolence)")
	return TRUE

/datum/mood_event/ultraviolence_witnessed
	description = "I just watched someone get torn apart. There was so much blood..."
	mood_change = -6
	timeout = 4 MINUTES

/datum/mood_event/ultraviolence_enjoyed
	description = "What a beautiful mess."
	mood_change = 4
	timeout = 4 MINUTES

#undef GORE_POOL_SPREADS_MIN
#undef GORE_POOL_SPREADS_MAX
#undef GORE_POOL_SPREAD_DELAY_MIN
#undef GORE_POOL_SPREAD_DELAY_MAX
#undef GORE_SPLATTER_NUDGE
#undef GORE_WITNESS_RANGE
