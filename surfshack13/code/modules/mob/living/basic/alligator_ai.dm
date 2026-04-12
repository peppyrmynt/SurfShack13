/**
 * AI controller for alligator (ripped from carp)
 * Expected flow is:
 * * If health is low, mark that we want to run away.
 * * If we want to run away, find nearest target and run out of view of it.
 * * Look for anything we want to eat in the area and target it.
 * * If we don't have a target already, find something to attack.
 * * Go and attack our target (which might be food, or might be a mob).
 */
/datum/ai_controller/basic_controller/alligator
	movement_delay = 3 SECONDS
	blackboard = list(
		BB_BASIC_MOB_STOP_FLEEING = TRUE,
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic,
	)

	ai_movement = /datum/ai_movement/basic_avoidance
	idle_behavior = /datum/idle_behavior/idle_random_walk
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_nearest_target_to_flee,
		/datum/ai_planning_subtree/find_food,
		/datum/ai_planning_subtree/find_target_prioritize_traits,
		/datum/ai_planning_subtree/basic_melee_attack_subtree
	)
