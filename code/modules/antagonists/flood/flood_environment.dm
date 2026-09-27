/// Environmental pieces used by the Flood infestation.
///
/// These are SurfShack-native structures using the visual assets from the
/// original HaloSpaceStation13 implementation.

/obj/structure/flood_biomass
	name = "Flood biomass"
	desc = "A pulsating mass of alien flesh."
	icon = 'icons/mob/flood/flood_bio.dmi'
	icon_state = "spore1"
	anchored = TRUE
	density = FALSE
	max_integrity = 400
	resistance_flags = ACID_PROOF
	var/next_spawn = 0
	var/spawn_delay = 60 SECONDS
	var/max_nearby_flood = 6
	var/max_nearby_growth = 12
	var/next_spread = 0
	var/spread_delay = 30 SECONDS

/obj/structure/flood_biomass/Initialize(mapload)
	. = ..()
	icon_state = "spore[rand(1, 8)]"
	next_spawn = world.time + spawn_delay
	next_spread = world.time + spread_delay
	START_PROCESSING(SSobj, src)

/obj/structure/flood_biomass/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/flood_biomass/process()
	if(world.time >= next_spread)
		next_spread = world.time + spread_delay
		spread_growth()

	if(world.time < next_spawn)
		return
	next_spawn = world.time + spawn_delay

	var/nearby_flood = 0
	for(var/mob/living/basic/flood/flood_form in range(7, src))
		if(flood_form.stat != DEAD)
			nearby_flood++
			if(nearby_flood >= max_nearby_flood)
				return

	var/turf/spawn_turf = get_turf(src)
	if(!spawn_turf)
		return

	var/spawn_type = pick(
		/mob/living/basic/flood/infestor,
		/mob/living/basic/flood/combat_form/human,
		/mob/living/basic/flood/carrier,
	)
	var/mob/living/basic/flood/new_flood = new spawn_type(spawn_turf)
	visible_message(span_warning("[src] writhes and produces [new_flood]."))

/obj/structure/flood_biomass/proc/spread_growth()
	var/nearby_growth = 0
	for(var/obj/structure/flood_growth/existing_growth in range(4, src))
		nearby_growth++
		if(nearby_growth >= max_nearby_growth)
			return

	var/list/valid_turfs = list()
	for(var/turf/open/candidate in range(1, src))
		if(candidate == loc)
			continue
		if(isspaceturf(candidate))
			continue
		if(locate(/obj/structure/flood_growth) in candidate)
			continue
		valid_turfs += candidate

	if(!length(valid_turfs))
		return

	var/turf/open/target = pick(valid_turfs)
	new /obj/structure/flood_growth(target)

/obj/structure/flood_biomass/take_damage(damage_amount, damage_type = BRUTE, damage_flag = "", sound_effect = TRUE, attack_dir, armour_penetration = 0)
	if(damage_type == BURN)
		damage_amount *= 2
	return ..(damage_amount, damage_type, damage_flag, sound_effect, attack_dir, armour_penetration)

/obj/structure/flood_biomass/examine(mob/user)
	. = ..()
	var/health_ratio = get_integrity() / max_integrity
	if(health_ratio > 0.66)
		. += span_notice("It looks very healthy.")
	else if(health_ratio > 0.33)
		. += span_notice("It looks damaged.")
	else
		. += span_warning("It is heavily damaged!")

/obj/structure/flood_biomass/medium
	name = "large Flood biomass"
	icon = 'icons/mob/flood/flood_bio_med.dmi'
	icon_state = "biomass1"
	max_integrity = 600
	spawn_delay = 50 SECONDS
	max_nearby_flood = 10
	max_nearby_growth = 20
	spread_delay = 20 SECONDS

/obj/structure/flood_biomass/medium/Initialize(mapload)
	. = ..()
	icon_state = pick(icon_states(icon))

/obj/structure/flood_biomass/large
	name = "massive Flood biomass"
	icon = 'icons/mob/flood/flood_bio_large.dmi'
	icon_state = "biomass1"
	max_integrity = 1500
	spawn_delay = 40 SECONDS
	max_nearby_flood = 15
	max_nearby_growth = 32
	spread_delay = 10 SECONDS

/obj/structure/flood_biomass/large/Initialize(mapload)
	. = ..()
	icon_state = pick(icon_states(icon))

/obj/structure/flood_biomass/tiny
	name = "Flood growth"
	icon = 'icons/mob/flood/flood_bio.dmi'
	icon_state = "pulsating"
	max_integrity = 250
	spawn_delay = 90 SECONDS
	max_nearby_flood = 3

/obj/structure/flood_growth
	name = "Flood growth"
	desc = "A thin layer of pulsating Flood biomass."
	icon = 'icons/mob/flood/flood_floor.dmi'
	icon_state = "floor"
	anchored = TRUE
	density = FALSE
	max_integrity = 100
	layer = ABOVE_OPEN_TURF_LAYER

/obj/structure/flood_wall_growth
	name = "Flood wall growth"
	desc = "Thick Flood biomass clings to the surrounding structure."
	icon = 'icons/mob/flood/Flood_Spore.dmi'
	icon_state = "flood wall gif"
	anchored = TRUE
	density = FALSE
	max_integrity = 250

/obj/structure/flood_door
	name = "Flood biomass door"
	desc = "A fleshy membrane capable of sealing an infested passage."
	icon = 'icons/mob/flood/flood_door.dmi'
	icon_state = "flood"
	anchored = TRUE
	density = TRUE
	opacity = TRUE
	max_integrity = 350

/obj/structure/flood_door/CanAllowThrough(atom/movable/mover, border_dir)
	if(istype(mover, /mob/living/basic/flood))
		return TRUE
	return ..()

/obj/structure/flood_window
	name = "Flood biomass membrane"
	desc = "A translucent sheet of hardened Flood tissue."
	icon = 'icons/mob/flood/flood_window.dmi'
	icon_state = "flood_window"
	anchored = TRUE
	density = TRUE
	max_integrity = 200

/mob/living/basic/flood/constructor
	name = "Flood constructor form"
	desc = "A specialized Flood form that converts its surroundings into infestation."
	icon = 'icons/mob/flood/flood_constructor_builder.dmi'
	icon_state = "constructor"
	icon_living = "constructor"
	icon_dead = "constructor_dead"
	maxHealth = 175
	health = 175
	melee_damage_lower = 5
	melee_damage_upper = 10
	var/next_build = 0

/mob/living/basic/flood/constructor/proc/can_build(turf/open/target_turf, structure_type, solid = FALSE)
	if(stat == DEAD)
		return FALSE
	if(!target_turf || isspaceturf(target_turf))
		to_chat(src, span_warning("You need an adjacent floor to grow Flood tissue."))
		return FALSE
	if(locate(structure_type) in target_turf)
		to_chat(src, span_warning("That tile already has this kind of Flood growth."))
		return FALSE
	if(structure_type == /obj/structure/flood_biomass)
		var/nearby_biomass = 0
		for(var/obj/structure/flood_biomass/biomass in range(4, target_turf))
			nearby_biomass++
			if(nearby_biomass >= 2)
				to_chat(src, span_warning("This area has enough biomass already."))
				return FALSE
	if(solid)
		for(var/atom/movable/obstacle in target_turf)
			if(obstacle.density)
				to_chat(src, span_warning("Something blocks the new membrane."))
				return FALSE
	if(world.time < next_build)
		to_chat(src, span_warning("Your biomass is still reshaping itself."))
		return FALSE
	next_build = world.time + 2 SECONDS
	return TRUE

/mob/living/basic/flood/constructor/proc/get_build_turf()
	return get_step(src, dir)

/mob/living/basic/flood/constructor/verb/grow_biomass()
	set name = "Grow Biomass"
	set category = "Flood"

	var/turf/target_turf = get_build_turf()
	if(!can_build(target_turf, /obj/structure/flood_biomass))
		return
	new /obj/structure/flood_biomass/tiny(target_turf)
	visible_message(span_warning("Flood biomass spreads outward beneath [src]."))

/mob/living/basic/flood/constructor/verb/infest_floor()
	set name = "Infest Floor"
	set category = "Flood"

	var/turf/target_turf = get_build_turf()
	if(!can_build(target_turf, /obj/structure/flood_growth))
		return
	new /obj/structure/flood_growth(target_turf)
	visible_message(span_warning("Pulsating Flood tissue creeps across the floor."))

/mob/living/basic/flood/constructor/verb/grow_wall()
	set name = "Grow Wall Biomass"
	set category = "Flood"

	var/turf/target_turf = get_build_turf()
	if(!can_build(target_turf, /obj/structure/flood_wall_growth))
		return
	new /obj/structure/flood_wall_growth(target_turf)
	visible_message(span_warning("Thick Flood biomass climbs across the nearby structure."))

/mob/living/basic/flood/constructor/verb/grow_door()
	set name = "Grow Biomass Door"
	set category = "Flood"

	var/turf/target_turf = get_build_turf()
	if(!can_build(target_turf, /obj/structure/flood_door, TRUE))
		return
	new /obj/structure/flood_door(target_turf)
	visible_message(span_warning("Flood tissue swells into a thick membrane."))

/mob/living/basic/flood/constructor/verb/grow_membrane()
	set name = "Grow Biomass Membrane"
	set category = "Flood"

	var/turf/target_turf = get_build_turf()
	if(!can_build(target_turf, /obj/structure/flood_window, TRUE))
		return
	new /obj/structure/flood_window(target_turf)
	visible_message(span_warning("A translucent Flood membrane hardens into place."))

/mob/living/basic/flood/overseer
	name = "Flood overseer form"
	desc = "A specialized Flood form directing the spread of infestation."
	icon = 'icons/mob/flood/flood_constructor_builder.dmi'
	icon_state = "designator"
	icon_living = "designator"
	icon_dead = "designator_dead"
	maxHealth = 150
	health = 150
	melee_damage_lower = 5
	melee_damage_upper = 10
	var/next_constructor = 0
	var/next_direct_growth = 0

/mob/living/basic/flood/overseer/verb/create_constructor()
	set name = "Create Constructor Form"
	set category = "Flood"

	if(stat == DEAD)
		return
	if(world.time < next_constructor)
		to_chat(src, span_warning("Your biomass is not ready to form another constructor."))
		return
	next_constructor = world.time + 30 SECONDS
	new /mob/living/basic/flood/constructor(loc)
	visible_message(span_warning("[src] buds off a new Flood constructor form."))

/mob/living/basic/flood/overseer/verb/direct_growth()
	set name = "Direct Infestation Growth"
	set category = "Flood"

	if(stat == DEAD)
		return
	if(world.time < next_direct_growth)
		to_chat(src, span_warning("The nearby biomass has not recovered yet."))
		return

	next_direct_growth = world.time + 20 SECONDS
	var/created = 0
	for(var/turf/open/target_turf in range(1, src))
		if(isspaceturf(target_turf))
			continue
		if(locate(/obj/structure/flood_growth) in target_turf)
			continue
		new /obj/structure/flood_growth(target_turf)
		created++
		if(created >= 3)
			break

	if(created)
		visible_message(span_warning("Flood growth surges outward under [src]'s direction."))
	else
		to_chat(src, span_warning("There is nowhere nearby for the infestation to spread."))
