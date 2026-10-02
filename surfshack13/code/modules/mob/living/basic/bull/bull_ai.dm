/// world.time we last had someone to charge at
#define BB_BULL_LAST_TARGET_TIME "bb_bull_last_target_time"
/// Are we currently rampaging around with nobody to charge at
#define BB_BULL_RAMPAGING "bb_bull_rampaging"
/// Whatever we've decided to charge at while rampaging
#define BB_BULL_RAMPAGE_TARGET "bb_bull_rampage_target"
/// world.time we're allowed to make our next rampage charge
#define BB_BULL_NEXT_RAMPAGE_CHARGE "bb_bull_next_rampage_charge"
/// Direction we're currently ambling in
#define BB_BULL_WANDER_DIR "bb_bull_wander_dir"

/datum/ai_controller/basic_controller/bull
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic,
		// Once someone is down we move on and look for fresh victims
		BB_TARGET_MINIMUM_STAT = CONSCIOUS,
		BB_BULL_LAST_TARGET_TIME = 0,
		BB_BULL_RAMPAGING = FALSE,
		BB_BULL_NEXT_RAMPAGE_CHARGE = 0,
	)
	// Keep thinking even with nobody nearby, so it roams the station on its own
	can_idle = FALSE
	ai_movement = /datum/ai_movement/basic_avoidance
	idle_behavior = /datum/idle_behavior/bull_wander
	planning_subtrees = list(
		/datum/ai_planning_subtree/target_retaliate/check_faction,
		/datum/ai_planning_subtree/simple_find_target,
		// Charge whenever it's off cooldown; missed charges come back quickly so it just lines up again
		/datum/ai_planning_subtree/targeted_mob_ability/bull,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
		/datum/ai_planning_subtree/bull_rampage,
	)

/// Charges at our target, but drops targets that are already down and leaves point blank ones to our horns
/datum/ai_planning_subtree/targeted_mob_ability/bull

/datum/ai_planning_subtree/targeted_mob_ability/bull/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return
	var/datum/targeting_strategy/targeting = GET_TARGETING_STRATEGY(controller.blackboard[BB_TARGETING_STRATEGY])
	if(!targeting?.can_attack(controller.pawn, target, controller.blackboard[BB_AGGRO_RANGE] || 9))
		controller.clear_blackboard_key(target_key)
		return
	// Can't charge at something on our own tile, just gore it normally
	if(get_turf(target) == get_turf(controller.pawn))
		return
	return ..()

/**
 * With nobody around to gore for a while the bull gets mad and starts charging on its own:
 * at someone it can smell through the walls, at something nearby to wreck, or just off in a random direction.
 * Since charges go through walls and doors, this also carries it all over the station looking for victims.
 */
/datum/ai_planning_subtree/bull_rampage
	/// How long without a target before we get mad
	var/calm_down_time = 8 SECONDS
	/// How far away we can smell people through walls
	var/scent_range = 30
	/// Chance to charge towards someone we can smell instead of wrecking whatever's nearby
	var/scent_chance = 60
	/// How far we look for stuff to wreck
	var/smash_range = 7
	/// How far a charge in a random direction aims
	var/wander_range = 12
	/// Chance to charge off in a random direction when there's nothing to smell or smash, otherwise we just keep wandering
	var/random_charge_chance = 25
	/// Shortest wander between rampage charges
	var/min_charge_gap = 4 SECONDS
	/// Longest wander between rampage charges
	var/max_charge_gap = 9 SECONDS

/datum/ai_planning_subtree/bull_rampage/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/mob/living/bull = controller.pawn
	if(controller.blackboard_key_exists(BB_BASIC_MOB_CURRENT_TARGET))
		controller.set_blackboard_key(BB_BULL_LAST_TARGET_TIME, world.time)
		controller.set_blackboard_key(BB_BULL_RAMPAGING, FALSE)
		return
	if(!controller.blackboard[BB_BULL_LAST_TARGET_TIME]) // freshly spawned, give it a moment before it gets mad
		controller.set_blackboard_key(BB_BULL_LAST_TARGET_TIME, world.time)
		return
	if(world.time < controller.blackboard[BB_BULL_LAST_TARGET_TIME] + calm_down_time)
		return
	if(world.time < controller.blackboard[BB_BULL_NEXT_RAMPAGE_CHARGE])
		return
	var/datum/action/cooldown/charge = controller.blackboard[BB_TARGETED_ACTION]
	if(!charge?.IsAvailable())
		return

	if(!controller.blackboard[BB_BULL_RAMPAGING])
		controller.set_blackboard_key(BB_BULL_RAMPAGING, TRUE)
		bull.visible_message(span_danger("[bull] snorts furiously and starts looking for something to wreck!"))

	var/atom/rampage_target
	if(prob(scent_chance))
		rampage_target = find_scent(bull)
	if(!rampage_target)
		rampage_target = find_smashable(bull)
	if(!rampage_target)
		if(!prob(random_charge_chance))
			// Nothing worth charging at, amble around a bit more and check again soon
			controller.set_blackboard_key(BB_BULL_NEXT_RAMPAGE_CHARGE, world.time + min_charge_gap)
			return
		rampage_target = get_ranged_target_turf(bull, pick(GLOB.alldirs), wander_range)
	if(!rampage_target || get_turf(rampage_target) == get_turf(bull))
		return

	controller.set_blackboard_key(BB_BULL_NEXT_RAMPAGE_CHARGE, world.time + rand(min_charge_gap, max_charge_gap))

	controller.set_blackboard_key(BB_BULL_RAMPAGE_TARGET, rampage_target)
	controller.queue_behavior(/datum/ai_behavior/targeted_mob_ability, BB_TARGETED_ACTION, BB_BULL_RAMPAGE_TARGET)
	return SUBTREE_RETURN_FINISH_PLANNING

/// Returns the turf of the closest player we can smell, if any
/datum/ai_planning_subtree/bull_rampage/proc/find_scent(mob/living/bull)
	var/turf/bull_turf = get_turf(bull)
	var/mob/living/closest
	var/closest_dist = scent_range + 1
	for(var/mob/living/carbon/human/victim in GLOB.alive_player_list)
		var/turf/victim_turf = get_turf(victim)
		if(!victim_turf || victim_turf.z != bull_turf.z || victim.stat != CONSCIOUS)
			continue
		var/dist = get_dist(bull_turf, victim_turf)
		if(dist < closest_dist && dist > 0)
			closest = victim
			closest_dist = dist
	return closest ? get_turf(closest) : null

/// Returns something nearby worth charging through
/datum/ai_planning_subtree/bull_rampage/proc/find_smashable(mob/living/bull)
	var/list/candidates = list()
	for(var/obj/thing in oview(smash_range, bull))
		if(!thing.density || (thing.resistance_flags & INDESTRUCTIBLE))
			continue
		if(!ismachinery(thing) && !isstructure(thing))
			continue
		candidates += thing
	return length(candidates) ? pick(candidates) : null

/// Ambles along in one direction for a while instead of jittering on the spot
/datum/idle_behavior/bull_wander
	/// Chance per second to take a step
	var/walk_chance = 60
	/// Chance per step to pick a new direction even if the way is clear
	var/turn_chance = 15

/datum/idle_behavior/bull_wander/perform_idle_behavior(seconds_per_tick, datum/ai_controller/controller)
	. = ..()
	var/mob/living/living_pawn = controller.pawn
	if(LAZYLEN(living_pawn.do_afters) || !(living_pawn.mobility_flags & MOBILITY_MOVE) || !isturf(living_pawn.loc) || living_pawn.pulledby)
		return FALSE
	if(!SPT_PROB(walk_chance, seconds_per_tick))
		return TRUE
	var/move_dir = controller.blackboard[BB_BULL_WANDER_DIR]
	if(!move_dir || prob(turn_chance))
		move_dir = pick(GLOB.alldirs)
	var/turf/destination_turf = get_step(living_pawn, move_dir)
	if(!destination_turf?.can_cross_safely(living_pawn) || !living_pawn.Move(destination_turf, move_dir))
		// Blocked, try somewhere else next time
		move_dir = pick(GLOB.alldirs)
	controller.set_blackboard_key(BB_BULL_WANDER_DIR, move_dir)
	return TRUE

#undef BB_BULL_NEXT_RAMPAGE_CHARGE
#undef BB_BULL_WANDER_DIR
#undef BB_BULL_LAST_TARGET_TIME
#undef BB_BULL_RAMPAGING
#undef BB_BULL_RAMPAGE_TARGET
