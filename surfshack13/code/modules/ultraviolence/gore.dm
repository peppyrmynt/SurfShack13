/*
 * Ultraviolent gore helpers.
 *
 * Hotline Miami style carnage: blood pools, gib streaks, exploding heads, spilled organs.
 * None of these procs deal extra damage on their own, they only destroy what was already lethal.
 * Brains are always spilled rather than deleted so victims stay revivable through a brain transplant.
 */

/// Returns TRUE if this mob's body can be torn apart by gore effects.
/mob/living/carbon/proc/can_be_gored()
	return !HAS_TRAIT(src, TRAIT_GODMODE) && !HAS_TRAIT(src, TRAIT_NODISMEMBER)

/**
 * Paints the floor around us red and throws some gibs around.
 *
 * Arguments:
 * * intensity - 1 to 5, how many tiles and splatters get covered.
 * * splatter_dir - optional direction the blood should mostly fly in, for that "shot from the doorway" look.
 */
/mob/living/carbon/proc/gore_blood_burst(intensity = 1, splatter_dir)
	var/turf/location = get_turf(src)
	if(!location || HAS_TRAIT(src, TRAIT_NOBLOOD))
		return

	intensity = clamp(intensity, 1, 5)
	add_splatter_floor(location)
	for(var/turf/nearby_turf in range(intensity > 2 ? 1 : 0, location))
		if(prob(40 + intensity * 10))
			add_splatter_floor(nearby_turf)

	for(var/i in 1 to intensity)
		spray_blood(splatter_dir && prob(70) ? splatter_dir : pick(GLOB.alldirs), clamp(intensity, 2, 5))

	var/obj/effect/decal/cleanable/blood/gibs/gibs = new(location)
	gibs.add_blood_DNA(get_blood_dna_list())
	gibs.streak(splatter_dir ? list(splatter_dir, turn(splatter_dir, 45), turn(splatter_dir, -45)) : GLOB.alldirs)
	playsound(location, 'sound/effects/wounds/splatter.ogg', 60, TRUE)

/// Rips every organ in the given zone out of us and scatters it on the floor. Returns the list of spilled organs.
/mob/living/carbon/proc/gore_spill_organs(zone, splatter_dir)
	var/list/spilled_organs = list()
	var/atom/drop_loc = drop_location()
	for(var/obj/item/organ/organ as anything in organs)
		if(check_zone(organ.zone) != zone)
			continue
		spilled_organs += organ

	for(var/obj/item/organ/organ as anything in spilled_organs)
		organ.Remove(src)
		if(!drop_loc)
			continue
		organ.forceMove(drop_loc)
		if(!HAS_TRAIT(src, TRAIT_NOBLOOD))
			organ.add_mob_blood(src)
		var/throw_dir = splatter_dir && prob(60) ? splatter_dir : pick(GLOB.alldirs)
		organ.throw_at(get_ranged_target_turf(src, throw_dir, rand(1, 3)), 3, 2)
	return spilled_organs

/**
 * Pops our head like a grape. Organs inside the head are thrown out, the head itself is destroyed or ripped off.
 *
 * Arguments:
 * * attacker - who did it, for messages and logs.
 * * splatter_dir - direction the mess flies in.
 * * crushed - TRUE for blunt force (stomps, bats), FALSE for gunshots/explosive force.
 * * delete_head - if TRUE the head is destroyed, otherwise it's torn off whole.
 */
/mob/living/carbon/proc/gore_destroy_head(mob/living/attacker, splatter_dir, crushed = FALSE, delete_head = TRUE)
	var/obj/item/bodypart/head/head_part = get_bodypart(BODY_ZONE_HEAD)
	if(!head_part || !can_be_gored())
		return FALSE

	var/verb_text = crushed ? "caved in" : "blown apart"
	visible_message(
		span_danger("<B>[src]'s head is [verb_text], spraying blood and brains everywhere!</B>"),
		span_userdanger("Your head is [verb_text]!"),
		span_hear("You hear a sickening wet crunch!"),
		ignored_mobs = attacker,
	)
	if(attacker && attacker != src)
		to_chat(attacker, span_danger("[src]'s head is [verb_text] in a shower of gore!"))
	playsound(src, crushed ? 'sound/effects/wounds/crackandbleed.ogg' : 'sound/effects/splat.ogg', 80, TRUE)

	gore_spill_organs(BODY_ZONE_HEAD, splatter_dir)
	gore_blood_burst(5, splatter_dir)
	if(!HAS_TRAIT(src, TRAIT_NOBLOOD))
		head_part.add_mob_blood(src)

	if(delete_head)
		head_part.drop_limb(dismembered = TRUE)
		qdel(head_part)
	else
		head_part.dismember(BRUTE, silent = TRUE, wounding_type = crushed ? WOUND_BLUNT : WOUND_PIERCE)

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
