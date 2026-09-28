/mob/living/basic/flood/constructor
	name = "Flood Constructor"
	unique_name = TRUE
	desc = "A specialized Flood unit that converts its surroundings into infestation."
	icon = 'icons/mob/flood/flood_constructor_builder.dmi'
	icon_state = "constructor"
	icon_living = "constructor"
	icon_dead = "constructor_dead"
	maxHealth = 175
	health = 175
	melee_damage_lower = 5
	melee_damage_upper = 10
	var/next_build = 0
	var/next_wall_build = 0
	var/next_spore_build = 0
	var/next_infestor = 0
	var/next_auto_growth = 0

/mob/living/basic/flood/constructor/Initialize(mapload)
	. = ..()
	next_auto_growth = world.time + rand(10, 20) SECONDS

/mob/living/basic/flood/constructor/get_flood_actions()
	. = ..()
	. += list(
		/datum/action/cooldown/flood/infest_floor,
		/datum/action/cooldown/flood/grow_barrier,
		/datum/action/cooldown/flood/grow_door,
		/datum/action/cooldown/flood/grow_membrane,
		/datum/action/cooldown/flood/grow_spores,
		/datum/action/cooldown/flood/produce_infestor,
		/datum/action/cooldown/flood/become_overseer,
	)

/mob/living/basic/flood/constructor/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. = ..()
	if(!. || stat == DEAD || client)
		return
	if(world.time >= next_infestor)
		produce_infestor()
	if(world.time < next_auto_growth)
		return
	next_auto_growth = world.time + 20 SECONDS
	auto_grow()

/// NPC constructors grow beneath themselves as they move through the nest.
/mob/living/basic/flood/constructor/proc/auto_grow()
	var/nearby_growth = 0
	for(var/turf/open/floor/flood_biomass/existing in range(4, src))
		nearby_growth++
	if(nearby_growth >= 10)
		return
	var/turf/target = get_build_turf()
	if(!isfloorturf(target))
		return
	if(can_grow_flood_floor(target) && can_build(target, /turf/open/floor/flood_biomass))
		grow_flood_floor(target)
		return
	// Keep spreading when the constructor is already standing on Flood floor.
	var/list/adjacent_floors = list()
	for(var/turf/open/floor/candidate in range(1, src))
		if(candidate != target && can_grow_flood_floor(candidate))
			adjacent_floors += candidate
	if(length(adjacent_floors))
		grow_flood_floor(pick(adjacent_floors))

/mob/living/basic/flood/constructor/proc/can_build(turf/target_turf, structure_type, solid = FALSE)
	if(stat == DEAD)
		return FALSE
	if(!isfloorturf(target_turf) || target_turf != get_turf(src))
		to_chat(src, span_warning("You need to stand on a floor to grow Flood tissue."))
		return FALSE
	if(structure_type == /turf/open/floor/flood_biomass)
		if(!can_grow_flood_floor(target_turf))
			to_chat(src, span_warning("Flood growth cannot cover that floor."))
			return FALSE
	else if(locate(structure_type) in target_turf)
		to_chat(src, span_warning("That tile already has this kind of Flood growth."))
		return FALSE
	if(solid)
		if(locate(/obj/structure/flood_door) in target_turf || locate(/obj/structure/flood_window) in target_turf || locate(/obj/structure/flood_wall) in target_turf)
			to_chat(src, span_warning("A Flood structure already occupies that tile."))
			return FALSE
		for(var/atom/movable/obstacle in target_turf)
			if(obstacle != src && obstacle.density)
				to_chat(src, span_warning("Something blocks the new Flood structure."))
				return FALSE
	if(world.time < next_build)
		to_chat(src, span_warning("Your biomass is still reshaping itself."))
		return FALSE
	next_build = world.time + 2 SECONDS
	start_build_recovery()
	return TRUE

/// Keep the HUD timers in sync with the shared construction recovery.
/mob/living/basic/flood/constructor/proc/start_build_recovery()
	for(var/datum/action/cooldown/flood/build_action in actions)
		if(!istype(build_action, /datum/action/cooldown/flood/infest_floor) && !istype(build_action, /datum/action/cooldown/flood/grow_barrier) && !istype(build_action, /datum/action/cooldown/flood/grow_door) && !istype(build_action, /datum/action/cooldown/flood/grow_membrane))
			continue
		if(build_action.next_use_time < next_build)
			build_action.StartCooldownSelf(next_build - world.time)

/mob/living/basic/flood/constructor/proc/get_build_turf()
	return get_turf(src)

/mob/living/basic/flood/constructor/proc/produce_infestor()
	if(stat == DEAD || world.time < next_infestor)
		return FALSE
	var/turf/spawn_turf = get_turf(src)
	if(!spawn_turf)
		return FALSE
	if(!flood_try_spawn_ai(/mob/living/basic/flood/infestor, spawn_turf))
		if(client)
			to_chat(src, span_warning("The hive cannot support more AI Flood right now."))
		else
			next_infestor = world.time + 10 SECONDS
		return FALSE
	next_infestor = world.time + 45 SECONDS
	visible_message(span_warning("[src] produces a Flood Infector."))
	for(var/datum/action/cooldown/flood/produce_infestor/infestor_action in actions)
		infestor_action.StartCooldownSelf()
	return TRUE

/mob/living/basic/flood/constructor/proc/infest_floor()
	var/turf/target_turf = get_build_turf()
	if(!can_build(target_turf, /turf/open/floor/flood_biomass))
		return FALSE
	if(!grow_flood_floor(target_turf))
		return FALSE
	visible_message(span_warning("Pulsating Flood tissue creeps across the floor."))
	for(var/datum/action/cooldown/flood/infest_floor/floor_action in actions)
		floor_action.StartCooldownSelf()
	return TRUE

/mob/living/basic/flood/constructor/proc/grow_barrier()
	if(!client)
		return FALSE
	if(world.time < next_wall_build)
		to_chat(src, span_warning("Your biomass is still recovering from growing a wall."))
		return FALSE
	var/turf/target_turf = get_build_turf()
	if(!can_build(target_turf, /obj/structure/flood_wall, TRUE))
		return FALSE
	next_wall_build = world.time + 15 SECONDS
	new /obj/structure/flood_wall(target_turf)
	visible_message(span_warning("[src] raises a solid wall of Flood biomass."))
	for(var/datum/action/cooldown/flood/grow_barrier/wall_action in actions)
		wall_action.StartCooldownSelf()
	return TRUE

/mob/living/basic/flood/constructor/proc/grow_door()
	if(!client)
		return FALSE
	var/turf/target_turf = get_build_turf()
	if(!can_build(target_turf, /obj/structure/flood_door, TRUE))
		return FALSE
	new /obj/structure/flood_door(target_turf)
	visible_message(span_warning("Flood tissue swells into a thick membrane."))
	for(var/datum/action/cooldown/flood/grow_door/door_action in actions)
		door_action.StartCooldownSelf()
	return TRUE

/mob/living/basic/flood/constructor/proc/grow_membrane()
	if(!client)
		return FALSE
	var/turf/target_turf = get_build_turf()
	if(!can_build(target_turf, /obj/structure/flood_window, TRUE))
		return FALSE
	new /obj/structure/flood_window(target_turf)
	visible_message(span_warning("A translucent Flood membrane hardens into place."))
	for(var/datum/action/cooldown/flood/grow_membrane/membrane_action in actions)
		membrane_action.StartCooldownSelf()
	return TRUE

/mob/living/basic/flood/constructor/proc/become_overseer()
	if(stat == DEAD || !mind)
		return FALSE
	if(flood_has_living_overseer())
		to_chat(src, span_warning("The hive already has a living overseer."))
		return FALSE
	if(world.time < GLOB.flood_overseer_replacement_at)
		to_chat(src, span_warning("The hive is still grieving. You can become the overseer in [round((GLOB.flood_overseer_replacement_at - world.time) / 10)] seconds."))
		return FALSE
	var/turf/evolution_turf = get_turf(src)
	if(!evolution_turf)
		return FALSE
	var/mob/living/basic/flood/overseer/new_overseer = new(evolution_turf)
	var/datum/mind/flood_mind = mind
	flood_mind.transfer_to(new_overseer)
	visible_message(span_warning("[src] reshapes into the new Flood Overseer!"))
	qdel(src)
	return TRUE

/mob/living/basic/flood/constructor/proc/grow_spores()
	if(world.time < next_spore_build)
		to_chat(src, span_warning("Your spores have not recovered yet."))
		return FALSE
	var/turf/target_turf = get_build_turf()
	if(!can_build(target_turf, /obj/structure/flood_spore_trap))
		return FALSE
	var/nearby_traps = 0
	for(var/obj/structure/flood_spore_trap/trap in range(3, target_turf))
		nearby_traps++
		if(nearby_traps >= 2)
			to_chat(src, span_warning("This area already has enough spore clusters."))
			return FALSE
	next_spore_build = world.time + 180 SECONDS
	new /obj/structure/flood_spore_trap(target_turf)
	visible_message(span_warning("[src] weaves a cluster of Flood spores across the floor."))
	for(var/datum/action/cooldown/flood/grow_spores/spore_action in actions)
		spore_action.StartCooldownSelf()
	return TRUE

/mob/living/basic/flood/overseer
	name = "Flood Overseer"
	desc = "A specialized Flood unit directing the spread of infestation."
	icon = 'icons/mob/flood/flood_constructor_builder.dmi'
	icon_state = "designator"
	icon_living = "designator"
	icon_dead = "designator_dead"
	maxHealth = 150
	health = 150
	melee_damage_lower = 5
	melee_damage_upper = 10
	var/next_biomass_build = 0
	var/next_constructor = 0
	var/next_carrier = 0
	var/next_direct_growth = 0
	var/next_auto_direct = 0
	var/mob/eye/flood_overseer/overseer_eye

/mob/living/basic/flood/overseer/Initialize(mapload)
	. = ..()
	next_auto_direct = world.time + rand(15, 25) SECONDS

/mob/living/basic/flood/overseer/get_flood_actions()
	. = ..()
	. += list(
		/datum/action/cooldown/flood/grow_biomass,
		/datum/action/cooldown/flood/infest_floor,
		/datum/action/cooldown/flood/create_constructor,
		/datum/action/cooldown/flood/create_carrier,
		/datum/action/cooldown/flood/direct_growth,
		/datum/action/cooldown/flood/toggle_overseer_mode,
	)

/mob/living/basic/flood/overseer/proc/infest_floor()
	if(stat == DEAD)
		return FALSE
	var/turf/target_turf = get_turf(src)
	if(!isfloorturf(target_turf))
		to_chat(src, span_warning("You need to stand on a floor to grow Flood tissue."))
		return FALSE
	if(!grow_flood_floor(target_turf))
		to_chat(src, span_warning("Flood growth cannot cover that floor."))
		return FALSE
	visible_message(span_warning("Pulsating Flood tissue creeps across the floor."))
	for(var/datum/action/cooldown/flood/infest_floor/floor_action in actions)
		floor_action.StartCooldownSelf()
	return TRUE

/mob/living/basic/flood/overseer/proc/grow_biomass()
	if(stat == DEAD || world.time < next_biomass_build)
		return FALSE
	var/turf/target_turf = get_turf(src)
	if(!isfloorturf(target_turf))
		to_chat(src, span_warning("You need to stand on a floor to grow Flood tissue."))
		return FALSE
	if(locate(/obj/structure/flood_biomass) in target_turf)
		to_chat(src, span_warning("That tile already has a biomass spawner."))
		return FALSE
	var/nearby_biomass = 0
	for(var/obj/structure/flood_biomass/biomass in range(4, target_turf))
		nearby_biomass++
		if(nearby_biomass >= 2)
			to_chat(src, span_warning("This area has enough biomass already."))
			return FALSE
	next_biomass_build = world.time + 60 SECONDS
	new /obj/structure/flood_biomass/tiny(target_turf)
	visible_message(span_warning("Flood biomass spreads outward beneath [src]."))
	for(var/datum/action/cooldown/flood/grow_biomass/growth_action in actions)
		growth_action.StartCooldownSelf()
	return TRUE

/mob/living/basic/flood/overseer/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. = ..()
	if(!. || stat == DEAD || client || world.time < next_auto_direct)
		return
	next_auto_direct = world.time + 20 SECONDS
	direct_growth()
	if(world.time < next_constructor)
		return
	var/nearby_constructors = 0
	for(var/mob/living/basic/flood/constructor/ally in range(5, src))
		if(ally.stat != DEAD)
			nearby_constructors++
	if(nearby_constructors < 2)
		create_constructor()

/mob/living/basic/flood/overseer/proc/create_constructor()
	if(stat == DEAD)
		return FALSE
	if(world.time < next_constructor)
		to_chat(src, span_warning("Your biomass is not ready to form another constructor."))
		return FALSE
	if(!flood_try_spawn_ai(/mob/living/basic/flood/constructor, get_turf(src)))
		if(client)
			to_chat(src, span_warning("The hive cannot support more AI Flood right now."))
		return FALSE
	next_constructor = world.time + 180 SECONDS
	visible_message(span_warning("[src] buds off a new Flood Constructor."))
	return TRUE

/mob/living/basic/flood/overseer/proc/create_carrier()
	if(stat == DEAD || world.time < next_carrier)
		return FALSE
	var/turf/spawn_turf = get_turf(src)
	if(!spawn_turf)
		return FALSE
	if(!flood_try_spawn_ai(/mob/living/basic/flood/carrier, spawn_turf))
		if(client)
			to_chat(src, span_warning("The hive cannot support more AI Flood right now."))
		return FALSE
	next_carrier = world.time + 120 SECONDS
	visible_message(span_warning("[src] buds off a Flood Carrier."))
	return TRUE

/mob/living/basic/flood/overseer/proc/direct_growth()
	if(stat == DEAD)
		return
	if(world.time < next_direct_growth)
		to_chat(src, span_warning("The nearby biomass has not recovered yet."))
		return

	next_direct_growth = world.time + 30 SECONDS
	var/created = 0
	for(var/turf/open/floor/target_turf in range(1, src))
		if(!grow_flood_floor(target_turf))
			continue
		created++
		if(created >= 3)
			break

	if(created)
		visible_message(span_warning("Flood growth surges outward under [src]'s direction."))
	else
		to_chat(src, span_warning("There is nowhere nearby for the infestation to spread."))
