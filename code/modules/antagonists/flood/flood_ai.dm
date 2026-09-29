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

/// Combat forms recover useful weapons; other Flood units retain the melee controller.
/datum/ai_controller/basic_controller/simple_hostile_obstacles/flood/armed
	planning_subtrees = list(
		/datum/ai_planning_subtree/flood_avoid_grenade,
		/datum/ai_planning_subtree/flood_rally,
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/flood_recover_weapon,
		/datum/ai_planning_subtree/flood_prepare_weapon,
		/datum/ai_planning_subtree/flood_use_ranged_weapon,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
		/datum/ai_planning_subtree/flood_patrol,
	)

/// Stay out of the blast radius until a thrown grenade detonates.
/datum/ai_planning_subtree/flood_avoid_grenade/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/mob/living/basic/flood/combat_form/human/flood = controller.pawn
	if(!istype(flood) || flood.client)
		return
	var/obj/item/grenade/grenade = flood.recent_thrown_grenade
	if(QDELETED(grenade) || !grenade.active || world.time >= flood.grenade_flee_until)
		flood.recent_thrown_grenade = null
		flood.recent_grenade_target = null
		controller.clear_blackboard_key("flood_thrown_grenade")
		return
	// The grenade starts in our tile before its throw animation moves it.
	var/atom/hazard = get_turf(grenade) == get_turf(flood) ? flood.recent_grenade_target : grenade
	if(!hazard)
		hazard = grenade
	controller.set_blackboard_key("flood_thrown_grenade", hazard)
	if(get_dist(flood, hazard) < 6)
		controller.queue_behavior(/datum/ai_behavior/run_away_from_target/flood_grenade, "flood_thrown_grenade")
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/ai_behavior/run_away_from_target/flood_grenade
	run_distance = 6
	clear_failed_targets = FALSE

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

/// Recover visible weapons between fights, or a weapon within reach during a fight.
/datum/ai_planning_subtree/flood_recover_weapon/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/mob/living/basic/flood/combat_form/human/armed_form = controller.pawn
	if(!istype(armed_form) || armed_form.client)
		return
	armed_form.drop_empty_guns()
	var/obj/item/grenade/held_grenade = armed_form.get_active_held_item()
	if(istype(held_grenade) && held_grenade.active)
		return
	// The rocket variant replenishes its launcher on a timer; it should hold on to it while empty.
	if(istype(armed_form, /mob/living/basic/flood/combat_form/human/rocket) && istype(armed_form.get_active_held_item(), /obj/item/gun/ballistic/rocketlauncher/unrestricted/flood))
		return
	var/has_enemy = controller.blackboard_key_exists(BB_BASIC_MOB_CURRENT_TARGET)
	if(world.time >= armed_form.next_weapon_check)
		armed_form.next_weapon_check = world.time + 2 SECONDS
		armed_form.recovery_target = armed_form.find_recovery_weapon(only_adjacent = has_enemy)
	var/obj/item/weapon = armed_form.recovery_target
	var/mob/living/carbon/dead_enemy = weapon?.loc
	if(QDELETED(weapon) || (!isturf(weapon.loc) && (!istype(dead_enemy) || dead_enemy.stat != DEAD || !(weapon in dead_enemy.held_items))) || armed_form.weapon_score(weapon) <= max(armed_form.weapon_score(armed_form.get_active_held_item()), armed_form.weapon_score(armed_form.get_inactive_held_item())) || (has_enemy && !armed_form.Adjacent(weapon)))
		armed_form.recovery_target = null
		return
	controller.queue_behavior(/datum/ai_behavior/flood_recover_weapon, weapon)
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/ai_behavior/flood_recover_weapon
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_REQUIRE_REACH | AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION
	required_distance = 1

/datum/ai_behavior/flood_recover_weapon/setup(datum/ai_controller/controller, obj/item/weapon)
	. = ..()
	if(QDELETED(weapon))
		return FALSE
	set_movement_target(controller, ismob(weapon.loc) ? weapon.loc : weapon)

/datum/ai_behavior/flood_recover_weapon/perform(seconds_per_tick, datum/ai_controller/controller, obj/item/weapon)
	var/mob/living/basic/flood/combat_form/human/armed_form = controller.pawn
	return AI_BEHAVIOR_DELAY | (armed_form.recover_weapon(weapon) ? AI_BEHAVIOR_SUCCEEDED : AI_BEHAVIOR_FAILED)

/datum/ai_behavior/flood_recover_weapon/finish_action(datum/ai_controller/controller, succeeded, obj/item/weapon)
	var/mob/living/basic/flood/combat_form/human/armed_form = controller.pawn
	if(armed_form?.recovery_target == weapon)
		armed_form.recovery_target = null
	return ..()

/// Prime grenades and wield or switch on weapons before choosing an attack.
/datum/ai_planning_subtree/flood_prepare_weapon/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/mob/living/basic/flood/combat_form/human/armed_form = controller.pawn
	if(!istype(armed_form) || armed_form.client || !controller.blackboard_key_exists(BB_BASIC_MOB_CURRENT_TARGET))
		return
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(QDELETED(target) || !armed_form.should_activate_weapon(target))
		return
	controller.queue_behavior(/datum/ai_behavior/flood_prepare_weapon, BB_BASIC_MOB_CURRENT_TARGET)
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/ai_behavior/flood_prepare_weapon
	behavior_flags = AI_BEHAVIOR_CAN_PLAN_DURING_EXECUTION
	action_cooldown = 1 SECONDS

/datum/ai_behavior/flood_prepare_weapon/perform(seconds_per_tick, datum/ai_controller/controller, target_key)
	var/mob/living/basic/flood/combat_form/human/armed_form = controller.pawn
	var/atom/target = controller.blackboard[target_key]
	if(!istype(armed_form) || QDELETED(target))
		return AI_BEHAVIOR_INSTANT | AI_BEHAVIOR_FAILED
	return AI_BEHAVIOR_DELAY | (armed_form.activate_weapon(target) ? AI_BEHAVIOR_SUCCEEDED : AI_BEHAVIOR_FAILED)

/datum/ai_planning_subtree/flood_use_ranged_weapon/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/mob/living/basic/flood/combat_form/human/armed_form = controller.pawn
	if(!istype(armed_form) || armed_form.client)
		return
	var/obj/item/held_weapon = armed_form.get_active_held_item()
	var/obj/item/grenade/held_grenade = held_weapon
	var/primed_grenade = istype(held_grenade) && held_grenade.active
	if(!istype(held_weapon, /obj/item/gun) && !primed_grenade && (armed_form.weapon_score(held_weapon) <= 0 || held_weapon.throwforce <= 10 || HAS_TRAIT(held_weapon, TRAIT_WIELDED)))
		return
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(QDELETED(target) || (armed_form.Adjacent(target) && !primed_grenade))
		return
	if(istype(armed_form, /mob/living/basic/flood/combat_form/human/rocket) && get_dist(armed_form, target) < 3)
		return
	var/attack_behavior = /datum/ai_behavior/basic_ranged_attack/flood_weapon/throwable
	if(istype(held_weapon, /obj/item/gun))
		attack_behavior = /datum/ai_behavior/basic_ranged_attack/flood_weapon
	else if(primed_grenade)
		attack_behavior = /datum/ai_behavior/basic_ranged_attack/flood_weapon/throwable/grenade
	controller.queue_behavior(attack_behavior, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETING_STRATEGY, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/ai_behavior/basic_ranged_attack/flood_weapon
	action_cooldown = 1.5 SECONDS
	required_distance = 5
	avoid_friendly_fire = TRUE

/datum/ai_behavior/basic_ranged_attack/flood_weapon/throwable
	required_distance = 3

/datum/ai_behavior/basic_ranged_attack/flood_weapon/throwable/grenade
	required_distance = 7

/datum/ai_behavior/basic_ranged_attack/flood_weapon/perform(seconds_per_tick, datum/ai_controller/controller, target_key, targeting_strategy_key, hiding_location_key)
	var/mob/living/basic/flood/combat_form/human/armed_form = controller.pawn
	if(!istype(armed_form))
		return AI_BEHAVIOR_INSTANT | AI_BEHAVIOR_FAILED
	var/obj/item/held_weapon = armed_form.get_active_held_item()
	var/obj/item/grenade/grenade = held_weapon
	if(armed_form.weapon_score(held_weapon) <= 0 || (armed_form.Adjacent(controller.blackboard[target_key]) && !(istype(grenade) && grenade.active)))
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
	if(ismecha(the_target))
		var/obj/vehicle/sealed/mecha/mecha = the_target
		if(!length(mecha.occupants))
			return FALSE
	else if(!isliving(the_target) || !is_flood_infectable(the_target))
		return FALSE
	return ..()
