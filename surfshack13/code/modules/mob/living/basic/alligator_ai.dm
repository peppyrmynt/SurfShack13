/datum/ai_controller/basic_controller/alligator
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic,
		BB_EAT_FOOD_COOLDOWN = 5 SECONDS,
	)

	ai_movement = /datum/ai_movement/basic_avoidance
	idle_behavior = /datum/idle_behavior/idle_random_walk
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/find_food,
		/datum/ai_planning_subtree/target_retaliate,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)


// // only find a target if BB_NEXT_FOOD_EAT < world.time
// /datum/ai_planning_subtree/simple_find_target/if_hungry

// /datum/ai_planning_subtree/simple_find_target/if_hungry/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
// 	if(controller.blackboard[BB_NEXT_FOOD_EAT] > world.time)
// 		return
// 	controller.queue_behavior(/datum/ai_behavior/find_potential_targets, target_key, BB_TARGETING_STRATEGY, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)

// /datum/ai_planning_subtree/open_mouth_if_targeting



// /datum/ai_behavior/attack
