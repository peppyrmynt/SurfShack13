/datum/ai_controller/basic_controller/simple_hostile_obstacles/flood
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic/flood,
		BB_TARGET_MINIMUM_STAT = HARD_CRIT,
	)
	planning_subtrees = list(
		/datum/ai_planning_subtree/flood_rally,
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
		/datum/ai_planning_subtree/flood_patrol,
	)

/datum/ai_controller/basic_controller/simple_hostile_obstacles/flood/infestor
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic/flood/infestor,
		BB_TARGET_MINIMUM_STAT = DEAD,
	)

/// Human combat forms can use guns they find on the station. Other Flood forms
/// retain the normal melee controller.
/datum/ai_controller/basic_controller/simple_hostile_obstacles/flood/armed
	planning_subtrees = list(
		/datum/ai_planning_subtree/flood_rally,
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/flood_use_gun,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
		/datum/ai_planning_subtree/flood_patrol,
	)

/// Overseer orders temporarily take priority over ordinary target acquisition and patrols.
/datum/ai_planning_subtree/flood_rally
	var/rally_key = "flood_rally_destination"

/datum/ai_planning_subtree/flood_rally/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/turf/destination = controller.blackboard[rally_key]
	if(QDELETED(destination))
		return
	var/mob/living/basic/flood/pawn = controller.pawn
	if(get_dist(pawn, destination) <= 1)
		controller.clear_blackboard_key(rally_key)
		return
	controller.queue_behavior(/datum/ai_behavior/travel_towards/stop_on_arrival, rally_key)
	return SUBTREE_RETURN_FINISH_PLANNING

/// Map assault and patrol points are used only while an NPC has no target.
/datum/ai_planning_subtree/flood_patrol/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/mob/living/basic/flood/patroller = controller.pawn
	if(!istype(patroller) || patroller.client || istype(patroller, /mob/living/basic/flood/infestor) || controller.blackboard_key_exists(BB_BASIC_MOB_CURRENT_TARGET))
		return
	var/obj/effect/landmark/destination = controller.blackboard[BB_TRAVEL_DESTINATION]
	if(QDELETED(destination) || get_dist(patroller, destination) <= 1)
		var/list/possible_destinations = list()
		for(var/obj/effect/landmark/assault_target/flood/objective as anything in GLOB.flood_assault_targets)
			if(objective.z != patroller.z)
				continue
			var/distance = get_dist(patroller, objective)
			if(distance > 1 && distance <= 20)
				possible_destinations += objective
		if(length(possible_destinations))
			destination = pick(possible_destinations)
		else
			for(var/obj/effect/landmark/flood_patrol_target/point as anything in GLOB.flood_patrol_targets)
				if(point.z != patroller.z)
					continue
				var/distance = get_dist(patroller, point)
				if(distance > 1 && distance <= 10)
					possible_destinations += point
			if(length(possible_destinations))
				destination = pick(possible_destinations)
		if(QDELETED(destination) || get_dist(patroller, destination) <= 1)
			controller.clear_blackboard_key(BB_TRAVEL_DESTINATION)
			return
		controller.set_blackboard_key(BB_TRAVEL_DESTINATION, destination)
	controller.queue_behavior(/datum/ai_behavior/travel_towards/stop_on_arrival, BB_TRAVEL_DESTINATION)
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/ai_planning_subtree/flood_use_gun/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/mob/living/basic/flood/combat_form/human/armed_form = controller.pawn
	if(!istype(armed_form) || armed_form.client)
		return
	var/obj/item/gun/held_gun = armed_form.get_active_held_item()
	if(!istype(held_gun) || !held_gun.can_shoot())
		return
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(QDELETED(target) || armed_form.Adjacent(target))
		return
	controller.queue_behavior(/datum/ai_behavior/basic_ranged_attack/flood_gun, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETING_STRATEGY, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/ai_behavior/basic_ranged_attack/flood_gun
	action_cooldown = 1.5 SECONDS
	required_distance = 5
	avoid_friendly_fire = TRUE

/datum/ai_behavior/basic_ranged_attack/flood_gun/perform(seconds_per_tick, datum/ai_controller/controller, target_key, targeting_strategy_key, hiding_location_key)
	var/mob/living/basic/flood/combat_form/human/armed_form = controller.pawn
	if(!istype(armed_form))
		return AI_BEHAVIOR_INSTANT | AI_BEHAVIOR_FAILED
	var/obj/item/gun/held_gun = armed_form.get_active_held_item()
	if(!istype(held_gun) || !held_gun.can_shoot() || armed_form.Adjacent(controller.blackboard[target_key]))
		return AI_BEHAVIOR_INSTANT | AI_BEHAVIOR_FAILED
	return ..()

/// Flood can acquire visible hosts without having to be attacked first.
/// The basic AI calls can_attack without a range during both target discovery
/// and pursuit, so provide the same sight range used by its target finder.
/datum/targeting_strategy/basic/flood/can_attack(mob/living/living_mob, atom/the_target, vision_range = 9)
	if(ismob(the_target) && is_flood_target(the_target))
		return FALSE
	return ..()

/datum/targeting_strategy/basic/flood/infestor/can_attack(mob/living/living_mob, atom/the_target, vision_range = 9)
	if(!ishuman(the_target))
		return FALSE
	return ..()
