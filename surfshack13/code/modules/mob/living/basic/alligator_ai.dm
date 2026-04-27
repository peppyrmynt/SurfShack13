/datum/ai_controller/basic_controller/alligator
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/alligator,
		BB_NEXT_EAT_HUNT = 0,
	)

	ai_movement = /datum/ai_movement/basic_avoidance
	idle_behavior = /datum/idle_behavior/idle_random_walk
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target/if_hungry,
		/datum/ai_planning_subtree/find_food/if_hungry,
		/datum/ai_planning_subtree/target_retaliate,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

/datum/ai_controller/basic_controller/alligator/proc/on_ate_food()
	set_blackboard_key(BB_NEXT_EAT_HUNT, world.time + 10 SECONDS)
	set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, null)
	set_blackboard_key(BB_TARGET_FOOD, null)

/datum/targeting_strategy/alligator
//modular ai is cool, but hard to use, because everything is very spread out and hard to comprehend.
/datum/targeting_strategy/alligator/can_attack(mob/living/living_mob, atom/the_target, vision_range)
	var/datum/ai_controller/basic_controller/our_controller = living_mob.ai_controller

	if(isnull(our_controller))
		return FALSE

	if(isturf(the_target) || isnull(the_target)) // bail out on invalids
		return FALSE

	if(isobj(the_target.loc))
		var/obj/container = the_target.loc
		if(container.resistance_flags & INDESTRUCTIBLE)
			return FALSE

	if(ismob(the_target)) //Target is in godmode, ignore it.
		if(living_mob.loc == the_target)
			return FALSE // We've either been eaten or are shapeshifted, let's assume the latter because we're still alive
		if(HAS_TRAIT(the_target, TRAIT_GODMODE))
			return FALSE

	if (vision_range && get_dist(living_mob, the_target) > vision_range)
		return FALSE

	if(!can_see(living_mob, the_target, vision_range)) //Target has moved behind cover and we have lost line of sight to it
		return FALSE

	if(living_mob.see_invisible < the_target.invisibility) //Target's invisible to us, forget it
		return FALSE

	if(!isturf(living_mob.loc))
		return FALSE
	if(isturf(the_target.loc) && living_mob.z != the_target.z) // z check will always fail if target is in a mech or pawn is shapeshifted or jaunting
		return FALSE

	if(ishuman(the_target))
		var/mob/living/carbon/human/human_target = the_target
		if(faction_check(living_mob.faction, human_target.faction))
			return FALSE
		//always eat legs
		for(var/obj/item/bodypart/leg/L in human_target.bodyparts)
			return TRUE

	if(isliving(the_target)) //Targeting vs living mobs
		var/mob/living/living_target = the_target
		if(faction_check(living_mob.faction, living_target.faction))
			return FALSE
		if(living_target.stat > SOFT_CRIT)
			return FALSE
		return TRUE

	if(ismecha(the_target)) //Targeting vs mechas
		var/obj/vehicle/sealed/mecha/M = the_target
		for(var/occupant in M.occupants)
			if(can_attack(living_mob, occupant)) //Can we attack any of the occupants?
				return TRUE

	if(istype(the_target, /obj/machinery/porta_turret)) //Cringe turret! kill it!
		var/obj/machinery/porta_turret/P = the_target
		if(P.in_faction(living_mob)) //Don't attack if the turret is in the same faction
			return FALSE
		if(P.has_cover && !P.raised) //Don't attack invincible turrets
			return FALSE
		if(P.machine_stat & BROKEN) //Or turrets that are already broken
			return FALSE
		return TRUE

	return FALSE

/datum/ai_planning_subtree/simple_find_target/if_hungry

/datum/ai_planning_subtree/simple_find_target/if_hungry/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	if(controller.blackboard[BB_NEXT_EAT_HUNT] <= world.time)
		return ..()

/datum/ai_planning_subtree/find_food/if_hungry

/datum/ai_planning_subtree/find_food/if_hungry/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	if(controller.blackboard[BB_NEXT_EAT_HUNT] <= world.time)
		return ..()
