/// Blackboard key, set while Cupcake has gone feral and is hunting her former owners
#define BB_CUPCAKE_FERAL "BB_cupcake_feral"
/// How many 45 degree steps make up one full spin
#define SPIN_STEPS 8

/**
 * # Cupcake
 *
 * A tanky, mean pitbull that lurks in maintenance. Anyone can tame her with meat (assistants have a knack for it),
 * after which she'll follow, attack and neck bite on command. Meat also patches her up.
 * Owners need to keep feeding her though - let her go hungry for too long and she turns feral and goes for them.
 */
/mob/living/basic/pitbull
	name = "Cupcake"
	desc = "A stocky, scarred pitbull with a mouth full of teeth and a name that is clearly someone's idea of a joke."
	icon = 'surfshack13/icons/mob/cupcake.dmi'
	icon_state = "cupcake"
	icon_living = "cupcake"
	icon_dead = "cupcake_dead"
	gender = FEMALE
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	gold_core_spawnable = NO_SPAWN
	faction = list("pitbull")
	speak_emote = list("growls", "snarls", "barks")
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "shoves"
	response_disarm_simple = "shove"
	response_harm_continuous = "kicks"
	response_harm_simple = "kick"

	maxHealth = 220
	health = 220
	damage_coeff = list(BRUTE = 0.8, BURN = 1, TOX = 1, STAMINA = 0, OXY = 1)
	obj_damage = 20
	melee_damage_lower = 12
	melee_damage_upper = 16
	wound_bonus = 0
	sharpness = SHARP_POINTY
	melee_attack_cooldown = 1.2 SECONDS
	attack_verb_continuous = "mauls"
	attack_verb_simple = "maul"
	attack_sound = 'sound/items/weapons/bite.ogg'
	attack_vis_effect = ATTACK_EFFECT_BITE
	death_message = "lets out a final whimper and goes still."
	move_force = MOVE_FORCE_STRONG
	move_resist = MOVE_FORCE_STRONG
	pull_force = MOVE_FORCE_STRONG

	butcher_results = list(/obj/item/food/meat/slab = 3)
	ai_controller = /datum/ai_controller/basic_controller/pitbull

	/// Is someone currently looking after us
	var/tamed = FALSE
	/// Have we turned on our owners
	var/feral = FALSE
	/// world.time we last ate
	var/last_fed = 0
	/// Have our owners been warned that we're getting hungry
	var/hunger_warned = FALSE
	/// How long after eating until we start getting irritable
	var/hunger_warning_time = 5 MINUTES
	/// How long after eating until we turn on our owners
	var/feral_time = 7 MINUTES
	/// How much health a single piece of meat restores
	var/meat_heal = 30
	/// Our neck bite ability
	var/datum/action/cooldown/mob_cooldown/neck_bite/neck_bite
	/// Stops us from barking over ourselves
	COOLDOWN_DECLARE(noise_cooldown)
	/// Cooldown between latching on and spinning someone around
	COOLDOWN_DECLARE(spin_cooldown)
	/// How long between spins
	var/spin_cooldown_time = 15 SECONDS
	/// Whoever we currently have clamped in our jaws and are spinning around
	var/mob/living/carbon/spin_victim

	/// Snarling, angry barks for when we're about to hurt someone
	var/static/list/aggro_sounds = list(
		'surfshack13/sound/mobs/cupcake/aggro_bark1.ogg',
		'surfshack13/sound/mobs/cupcake/aggro_bark2.ogg',
		'surfshack13/sound/mobs/cupcake/aggro_bark3.ogg',
		'surfshack13/sound/mobs/cupcake/aggro_bark4.ogg',
	)
	/// Low warning growls
	var/static/list/growl_sounds = list(
		'surfshack13/sound/mobs/cupcake/growl1.ogg',
		'surfshack13/sound/mobs/cupcake/growl2.ogg',
		'surfshack13/sound/mobs/cupcake/growl3.ogg',
		'surfshack13/sound/mobs/cupcake/growl4.ogg',
		'surfshack13/sound/mobs/cupcake/growl5.ogg',
		'sound/mobs/non-humanoids/dog/growl1.ogg',
		'sound/mobs/non-humanoids/dog/growl2.ogg',
	)
	/// Happy barks, for when someone's being nice to us
	var/static/list/happy_sounds = list(
		'surfshack13/sound/mobs/cupcake/bark1.ogg',
		'surfshack13/sound/mobs/cupcake/bark2.ogg',
	)
	/// Whimpers
	var/static/list/whine_sounds = list(
		'surfshack13/sound/mobs/cupcake/whine1.ogg',
		'surfshack13/sound/mobs/cupcake/whine2.ogg',
		'surfshack13/sound/mobs/cupcake/whine3.ogg',
		'surfshack13/sound/mobs/cupcake/whine4.ogg',
		'surfshack13/sound/mobs/cupcake/whine5.ogg',
	)

	/// What we eat, and what tames us
	var/static/list/food_types = list(
		/obj/item/food/meat,
	)
	/// Commands we listen to while tamed
	var/static/list/pet_commands = list(
		/datum/pet_command/idle,
		/datum/pet_command/free,
		/datum/pet_command/follow/cupcake,
		/datum/pet_command/point_targeting/attack,
		/datum/pet_command/point_targeting/use_ability/neck_bite,
		/datum/pet_command/protect_owner,
	)

/mob/living/basic/pitbull/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/footstep, FOOTSTEP_MOB_CLAW)
	AddElement(/datum/element/ai_retaliate)
	AddElement(/datum/element/basic_eating, heal_amt = meat_heal, food_types = food_types)
	make_tameable()

	neck_bite = new(src)
	neck_bite.Grant(src)
	ai_controller.set_blackboard_key(BB_TARGETED_ACTION, neck_bite)

	RegisterSignal(src, COMSIG_MOB_ATE, PROC_REF(on_ate))
	RegisterSignal(src, COMSIG_HOSTILE_PRE_ATTACKINGTARGET, PROC_REF(on_pre_attack))
	RegisterSignal(src, COMSIG_HOSTILE_POST_ATTACKINGTARGET, PROC_REF(on_post_attack))
	RegisterSignals(src, list(COMSIG_AI_BLACKBOARD_KEY_SET(BB_BASIC_MOB_CURRENT_TARGET), COMSIG_AI_BLACKBOARD_KEY_SET(BB_CURRENT_PET_TARGET)), PROC_REF(on_target_set))
	RegisterSignals(src, list(COMSIG_AI_BLACKBOARD_KEY_CLEARED(BB_BASIC_MOB_CURRENT_TARGET), COMSIG_AI_BLACKBOARD_KEY_CLEARED(BB_CURRENT_PET_TARGET)), PROC_REF(on_target_cleared))

/mob/living/basic/pitbull/Destroy()
	reset_spin_victim()
	QDEL_NULL(neck_bite)
	return ..()

/mob/living/basic/pitbull/death(gibbed)
	. = ..()
	reset_spin_victim()
	remove_movespeed_modifier(/datum/movespeed_modifier/cupcake_dwarf_hunt)
	make_noise(whine_sounds, volume = 60, force = TRUE)

/// Plays a random sound from the list, unless we made a noise very recently
/mob/living/basic/pitbull/proc/make_noise(list/sounds, volume = 60, cooldown = 3 SECONDS, force = FALSE)
	if(!force && !COOLDOWN_FINISHED(src, noise_cooldown))
		return FALSE
	COOLDOWN_START(src, noise_cooldown, cooldown)
	playsound(src, pick(sounds), volume, TRUE)
	return TRUE

/mob/living/basic/pitbull/proc/make_tameable()
	AddComponent(/datum/component/tameable/cupcake, food_types = food_types, tame_chance = 20, bonus_tame_chance = 10)

/mob/living/basic/pitbull/examine(mob/user)
	. = ..()
	if(stat == DEAD)
		return
	if(feral)
		. += span_danger("[p_Their()] eyes are wild and [p_theyre()] foaming at the mouth. Some meat might calm [p_them()] down... if you can get close.")
		return
	if(!tamed || !(user in ai_controller?.blackboard[BB_FRIENDS_LIST]))
		return
	var/time_since_fed = world.time - last_fed
	if(time_since_fed >= hunger_warning_time)
		. += span_warning("[p_Theyre()] starving and getting snappy. Feed [p_them()] meat, now!")
	else if(time_since_fed >= hunger_warning_time / 2)
		. += span_notice("[p_They()] [p_are()] eyeing your pockets for a snack.")
	else
		. += span_notice("[p_They()] look[p_s()] well fed and content.")

/mob/living/basic/pitbull/tamed(mob/living/tamer, atom/food)
	. = ..()
	tamed = TRUE
	last_fed = world.time
	hunger_warned = FALSE
	if(feral)
		calm_down()
	new /obj/effect/temp_visual/heart(loc)
	if(!GetComponent(/datum/component/obeys_commands))
		AddComponent(/datum/component/obeys_commands, pet_commands)
	ai_controller.ai_traits |= STOP_MOVING_WHEN_PULLED
	make_noise(happy_sounds, force = TRUE)
	visible_message(span_notice("[src] wolfs down the meat and starts wagging [p_their()] stumpy tail at [tamer]."))

/mob/living/basic/pitbull/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. = ..()
	if(stat == DEAD)
		return
	if(!tamed)
		// wild, growling at anyone who wanders too close
		if(!feral && SPT_PROB(3, seconds_per_tick) && (locate(/mob/living/carbon/human) in oview(4, src)))
			make_noise(growl_sounds, volume = 45, cooldown = 8 SECONDS)
		return
	var/time_since_fed = world.time - last_fed
	if(time_since_fed >= feral_time)
		go_feral()
		return
	if(time_since_fed < hunger_warning_time)
		return
	if(!hunger_warned)
		hunger_warned = TRUE
		for(var/mob/living/friend in ai_controller.blackboard[BB_FRIENDS_LIST])
			to_chat(friend, span_warning("[src] is getting hungry and irritable. Feed [p_them()] some meat before [p_they()] turn[p_s()] on you!"))
		growl()
	else if(SPT_PROB(4, seconds_per_tick))
		growl()

/mob/living/basic/pitbull/proc/growl()
	make_noise(growl_sounds, volume = 55, force = TRUE)
	visible_message(span_warning("[src] growls hungrily, baring [p_their()] teeth."))

/// Feeding us keeps us loyal (and healing is handled by basic_eating)
/mob/living/basic/pitbull/proc/on_ate(datum/source, atom/food, mob/living/feeder)
	SIGNAL_HANDLER
	if(!tamed)
		return
	last_fed = world.time
	hunger_warned = FALSE
	if(feeder)
		balloon_alert(feeder, "wags tail")
		make_noise(happy_sounds)

/// Our owners let us starve, time to bite the hand that (didn't) feed us
/mob/living/basic/pitbull/proc/go_feral()
	tamed = FALSE
	feral = TRUE
	hunger_warned = FALSE
	var/list/friends_list = ai_controller.blackboard[BB_FRIENDS_LIST]
	var/list/former_owners = friends_list?.Copy()
	for(var/mob/living/former_owner as anything in former_owners)
		unfriend(former_owner)
	qdel(GetComponent(/datum/component/obeys_commands))
	ai_controller.ai_traits &= ~STOP_MOVING_WHEN_PULLED
	ai_controller.clear_blackboard_key(BB_ACTIVE_PET_COMMAND)
	ai_controller.clear_blackboard_key(BB_CURRENT_PET_TARGET)
	ai_controller.set_blackboard_key(BB_CUPCAKE_FERAL, TRUE)

	var/mob/living/first_victim
	for(var/mob/living/former_owner as anything in former_owners)
		if(QDELETED(former_owner) || former_owner.stat == DEAD)
			continue
		ai_controller.insert_blackboard_key_lazylist(BB_BASIC_MOB_RETALIATE_LIST, former_owner)
		to_chat(former_owner, span_userdanger("[src] has gone feral from hunger and is coming for you!"))
		// dwarfs first, then whoever is closest
		if(isnull(first_victim) || (HAS_TRAIT(former_owner, TRAIT_DWARF) && !HAS_TRAIT(first_victim, TRAIT_DWARF)))
			first_victim = former_owner
		else if(HAS_TRAIT(former_owner, TRAIT_DWARF) == HAS_TRAIT(first_victim, TRAIT_DWARF) && get_dist(src, former_owner) < get_dist(src, first_victim))
			first_victim = former_owner
	if(first_victim)
		ai_controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, first_victim)

	add_atom_colour("#ffb0b0", FIXED_COLOUR_PRIORITY)
	make_noise(aggro_sounds, volume = 90, force = TRUE)
	visible_message(span_danger("[src]'s eyes go wild as hunger takes over. [p_They()] [p_are()] feral!"))
	// she can be won back, if you're brave enough to get close with some meat
	make_tameable()

/// Someone was brave enough to feed us while we were feral
/mob/living/basic/pitbull/proc/calm_down()
	feral = FALSE
	remove_atom_colour(FIXED_COLOUR_PRIORITY, "#ffb0b0")
	ai_controller.clear_blackboard_key(BB_CUPCAKE_FERAL)
	ai_controller.clear_blackboard_key(BB_BASIC_MOB_RETALIATE_LIST)
	ai_controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)

/// Snarl when we pick someone to go after
/mob/living/basic/pitbull/proc/on_target_set(datum/source, key)
	SIGNAL_HANDLER
	if(stat == DEAD)
		return
	update_hunt_speed()
	var/atom/target = ai_controller?.blackboard[key]
	if(!isliving(target) || (target in ai_controller.blackboard[BB_FRIENDS_LIST]))
		return
	make_noise(aggro_sounds, volume = 70, cooldown = 4 SECONDS)

/mob/living/basic/pitbull/proc/on_target_cleared(datum/source, key)
	SIGNAL_HANDLER
	update_hunt_speed()

/// Is this someone we'd love to chase down?
/mob/living/basic/pitbull/proc/is_dwarf_prey(atom/target)
	if(!isliving(target) || !HAS_TRAIT(target, TRAIT_DWARF))
		return FALSE
	var/mob/living/living_target = target
	if(living_target.stat == DEAD || (living_target in ai_controller?.blackboard[BB_FRIENDS_LIST]))
		return FALSE
	return TRUE

/// Put on a burst of speed while we're chasing a dwarf
/mob/living/basic/pitbull/proc/update_hunt_speed()
	if(stat != DEAD && (is_dwarf_prey(ai_controller?.blackboard[BB_BASIC_MOB_CURRENT_TARGET]) || is_dwarf_prey(ai_controller?.blackboard[BB_CURRENT_PET_TARGET])))
		add_movespeed_modifier(/datum/movespeed_modifier/cupcake_dwarf_hunt)
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/cupcake_dwarf_hunt)

/// We've laid eyes on a dwarf, everyone should know about it
/mob/living/basic/pitbull/proc/spotted_dwarf(mob/living/dwarf)
	visible_message(span_bolddanger("[src]'s ears shoot up as [p_they()] lock[p_s()] eyes on [dwarf]. Midget spotted!"), \
		blind_message = span_hear("You hear furious barking."), ignored_mobs = dwarf)
	to_chat(dwarf, span_userdanger("[src] has spotted you, and [p_they()] [p_are()] coming for you fast!"))
	make_noise(aggro_sounds, volume = 90, force = TRUE)

/// The odd snarl while mauling someone
/mob/living/basic/pitbull/proc/on_post_attack(datum/source, atom/target, result)
	SIGNAL_HANDLER
	if(isliving(target) && prob(25))
		make_noise(aggro_sounds, volume = 60, cooldown = 4 SECONDS)

/// The AI goes for the throat whenever the neck bite is ready
/// Anyone on the floor gets grabbed and spun, otherwise the AI goes for the throat whenever the neck bite is ready
/mob/living/basic/pitbull/proc/on_pre_attack(mob/living/source, atom/target, proximity, modifiers)
	SIGNAL_HANDLER
	if(spin_victim)
		return COMPONENT_HOSTILE_NO_ATTACK
	if(!proximity || !isliving(target))
		return NONE
	var/mob/living/victim = target
	if(victim.stat == DEAD)
		return NONE
	if(iscarbon(victim) && check_spin(victim))
		INVOKE_ASYNC(src, PROC_REF(spin_and_throw), victim)
		return COMPONENT_HOSTILE_NO_ATTACK
	if(client || !neck_bite?.IsAvailable())
		return NONE
	INVOKE_ASYNC(neck_bite, TYPE_PROC_REF(/datum/action, Trigger), NONE, victim)
	return COMPONENT_HOSTILE_NO_ATTACK

/// Can we clamp down on this person and spin them around? Like the gators, they need to be on the floor first.
/mob/living/basic/pitbull/proc/check_spin(mob/living/carbon/victim)
	if(victim.body_position != LYING_DOWN || victim.buckled || victim.mob_size > MOB_SIZE_HUMAN)
		return FALSE
	if(!isturf(loc) || !isturf(victim.loc))
		return FALSE
	if(!has_gravity())
		to_chat(src, span_notice("You can't get a grip to spin [victim] without gravity!"))
		return FALSE
	if(!COOLDOWN_FINISHED(src, spin_cooldown))
		to_chat(src, span_notice("Your jaw is still sore from the last spin, wait a second."))
		return FALSE
	if(HAS_TRAIT(victim.loc, TRAIT_ELEVATED_TURF) && !HAS_TRAIT(loc, TRAIT_ELEVATED_TURF))
		to_chat(src, span_notice("[victim] is too high up to grab."))
		return FALSE
	return TRUE

/// Is the spin still going? Checked between every step since we sleep.
/mob/living/basic/pitbull/proc/can_keep_spinning(mob/living/carbon/victim)
	if(QDELETED(src) || stat == DEAD || QDELETED(victim) || spin_victim != victim)
		return FALSE
	if(get_dist(src, victim) > 1 || !isturf(loc) || !isturf(victim.loc))
		return FALSE
	return TRUE

/// Clamp down on the victim, swing them a full 360 around us like a wrestler, then send them flying
/mob/living/basic/pitbull/proc/spin_and_throw(mob/living/carbon/victim)
	spin_victim = victim
	COOLDOWN_START(src, spin_cooldown, spin_cooldown_time)
	victim.add_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED, TRAIT_INCAPACITATED), REF(src))
	ADD_TRAIT(src, TRAIT_IMMOBILIZED, REF(src))
	face_atom(victim)
	victim.visible_message(span_danger("[src] clamps down on [victim] and starts spinning [victim.p_them()] around!"), \
		span_userdanger("[src] clamps down on you and starts spinning you around!"), span_hear("You hear snarling and aggressive shuffling!"), null, src)
	playsound(src, 'sound/items/weapons/bite.ogg', 70, TRUE)
	make_noise(aggro_sounds, volume = 80, force = TRUE)
	victim.emote("scream")

	for(var/i in 1 to SPIN_STEPS)
		var/delay = 0.5
		switch(i)
			if(1 to 2)
				delay = 3
			if(3 to 4)
				delay = 2
			if(5 to 6)
				delay = 1
		if(!can_keep_spinning(victim))
			reset_spin_victim()
			return
		setDir(turn(dir, -45))
		var/turf/next_turf = get_step(src, dir)
		var/turf/victim_turf = victim.loc
		if(next_turf && victim_turf.Exit(victim, get_dir(victim_turf, next_turf)) && next_turf.Enter(victim))
			victim.forceMove(next_turf)
			victim.setDir(get_dir(victim, src))
		sleep(delay)

	if(!can_keep_spinning(victim))
		reset_spin_victim()
		return
	reset_spin_victim()
	victim.forceMove(loc) // same trick as the wrestling throw, stops people getting thrown through walls
	victim.visible_message(span_danger("[src] lets go and sends [victim] flying!"), \
		span_userdanger("[src] lets go and sends you flying!"), span_hear("You hear a snarl and a loud thud!"), null, src)
	playsound(src, SFX_SWING_HIT, 50, TRUE)
	var/turf/throw_target = get_edge_target_turf(src, dir)
	if(throw_target)
		victim.throw_at(throw_target, 7, 4, src, TRUE, TRUE, callback = CALLBACK(victim, TYPE_PROC_REF(/mob/living, Paralyze), 2 SECONDS))
	log_combat(src, victim, "spun around and threw")

/// Let go of whoever we're spinning
/mob/living/basic/pitbull/proc/reset_spin_victim()
	REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, REF(src))
	if(!spin_victim)
		return
	spin_victim.remove_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED, TRAIT_INCAPACITATED), REF(src))
	spin_victim = null

/// Ghosts always get to watch Cupcake, even when nobody is controlling her
/datum/orbit_menu/validate_mob_poi(datum/point_of_interest/mob_poi/potential_poi)
	if(istype(potential_poi.target, /mob/living/basic/pitbull))
		return potential_poi.validate()
	return ..()

/// Tameable, with assistants getting a bonus. Something about kindred spirits.
/datum/component/tameable/cupcake
	/// Bonus tame chance for assistants
	var/assistant_bonus = 25

/datum/component/tameable/cupcake/try_tame(atom/source, obj/item/food, mob/living/attacker)
	var/bonus = is_assistant_job(attacker?.mind?.assigned_role) ? assistant_bonus : 0
	current_tame_chance += bonus
	. = ..()
	current_tame_chance -= bonus

/**
 * # Neck Bite
 * Go for the throat, leaving the victim bleeding heavily.
 */
/datum/action/cooldown/mob_cooldown/neck_bite
	name = "Neck Bite"
	desc = "Lunge for your prey's throat and tear it open, leaving them bleeding heavily."
	button_icon = 'icons/effects/effects.dmi'
	button_icon_state = "bite"
	cooldown_time = 25 SECONDS
	shared_cooldown = NONE
	/// Brute damage dealt by the bite
	var/bite_damage = 20

/datum/action/cooldown/mob_cooldown/neck_bite/Activate(atom/target)
	if(!isliving(target) || target == owner)
		return FALSE
	var/mob/living/victim = target
	if(victim.stat == DEAD)
		return FALSE
	if(!owner.Adjacent(victim))
		if(owner.client)
			owner.balloon_alert(owner, "too far!")
		return FALSE

	owner.face_atom(victim)
	owner.do_attack_animation(victim, ATTACK_EFFECT_BITE)
	playsound(owner, 'sound/items/weapons/bite.ogg', 70, TRUE)
	playsound(owner, 'surfshack13/sound/mobs/cupcake/neck_tear.ogg', 70, TRUE)
	var/mob/living/basic/pitbull/cupcake = owner
	if(istype(cupcake))
		cupcake.make_noise(cupcake.aggro_sounds, volume = 80, force = TRUE)
	victim.visible_message(
		span_danger("[owner] lunges at [victim]'s neck and tears into it!"),
		span_userdanger("[owner] clamps down on your neck and rips it open!"),
	)
	if(iscarbon(victim))
		var/mob/living/carbon/carbon_victim = victim
		var/obj/item/bodypart/neck = carbon_victim.get_bodypart(BODY_ZONE_HEAD) || carbon_victim.get_bodypart(BODY_ZONE_CHEST)
		carbon_victim.apply_damage(bite_damage, BRUTE, neck, wound_bonus = CANT_WOUND)
		var/severity = prob(40) ? WOUND_SEVERITY_CRITICAL : WOUND_SEVERITY_SEVERE
		carbon_victim.cause_wound_of_type_and_severity(list(WOUND_PIERCE, WOUND_SLASH), neck, severity, wound_source = "pitbull bite")
		// drags them to the floor, setting them up to be grabbed and spun
		carbon_victim.Knockdown(2 SECONDS)
	else
		// no neck to bleed from, so it just hurts a lot more
		victim.apply_damage(bite_damage * 2, BRUTE)
	StartCooldown()
	return TRUE

/datum/ai_controller/basic_controller/pitbull
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic,
		BB_PET_TARGETING_STRATEGY = /datum/targeting_strategy/basic/not_friends,
		BB_TARGET_MINIMUM_STAT = HARD_CRIT,
		BB_TARGET_PRIORITY_TRAIT = TRAIT_DWARF,
		BB_OWNER_SELF_HARM_RESPONSES = list(
			"*me whines.",
			"*me growls in disapproval.",
			"*me tugs at your sleeve.",
		),
	)
	ai_movement = /datum/ai_movement/basic_avoidance
	idle_behavior = /datum/idle_behavior/idle_random_walk
	planning_subtrees = list(
		/datum/ai_planning_subtree/pet_planning,
		/datum/ai_planning_subtree/hunt_dwarfs,
		/datum/ai_planning_subtree/target_retaliate/prefer_dwarfs,
		/datum/ai_planning_subtree/find_target_prioritize_traits/cupcake_feral,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

/// Only goes looking for victims on its own while feral, otherwise it just defends itself
/datum/ai_planning_subtree/find_target_prioritize_traits/cupcake_feral

/datum/ai_planning_subtree/find_target_prioritize_traits/cupcake_feral/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	if(!controller.blackboard[BB_CUPCAKE_FERAL])
		return
	return ..()

/// Goes for any dwarf she can see, even when nobody has provoked her
/datum/ai_planning_subtree/hunt_dwarfs

/datum/ai_planning_subtree/hunt_dwarfs/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	controller.queue_behavior(/datum/ai_behavior/hunt_dwarfs, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETING_STRATEGY)

/datum/ai_behavior/hunt_dwarfs
	action_cooldown = 2 SECONDS
	/// How far away we can spot a dwarf
	var/vision_range = 9

/datum/ai_behavior/hunt_dwarfs/perform(seconds_per_tick, datum/ai_controller/controller, target_key, targeting_strategy_key)
	var/mob/living/living_pawn = controller.pawn
	var/datum/targeting_strategy/targeting_strategy = GET_TARGETING_STRATEGY(controller.blackboard[targeting_strategy_key])
	if(!targeting_strategy)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	// already chasing one down
	var/atom/current_target = controller.blackboard[target_key]
	if(isliving(current_target) && HAS_TRAIT(current_target, TRAIT_DWARF) && targeting_strategy.can_attack(living_pawn, current_target, vision_range))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

	var/mob/living/closest_dwarf
	for(var/mob/living/potential_dwarf in oview(vision_range, living_pawn))
		if(!HAS_TRAIT(potential_dwarf, TRAIT_DWARF) || !targeting_strategy.can_attack(living_pawn, potential_dwarf, vision_range))
			continue
		if(isnull(closest_dwarf) || get_dist(living_pawn, potential_dwarf) < get_dist(living_pawn, closest_dwarf))
			closest_dwarf = potential_dwarf
	if(isnull(closest_dwarf))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	// on the shitlist so retaliation keeps us locked onto them
	controller.insert_blackboard_key_lazylist(BB_BASIC_MOB_RETALIATE_LIST, closest_dwarf)
	controller.set_blackboard_key(target_key, closest_dwarf)
	var/mob/living/basic/pitbull/cupcake = living_pawn
	if(istype(cupcake))
		cupcake.spotted_dwarf(closest_dwarf)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

/// Fights back against whoever hurt us, dwarfs first
/datum/ai_planning_subtree/target_retaliate/prefer_dwarfs

/datum/ai_planning_subtree/target_retaliate/prefer_dwarfs/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	controller.queue_behavior(/datum/ai_behavior/target_from_retaliate_list/prefer_dwarfs, BB_BASIC_MOB_RETALIATE_LIST, target_key, targeting_strategy_key, hiding_place_key, check_faction)

/datum/ai_behavior/target_from_retaliate_list/prefer_dwarfs

/datum/ai_behavior/target_from_retaliate_list/prefer_dwarfs/pick_final_target(datum/ai_controller/controller, list/enemies_list)
	var/list/dwarfs = list()
	for(var/mob/living/enemy as anything in enemies_list)
		if(HAS_TRAIT(enemy, TRAIT_DWARF))
			dwarfs += enemy
	if(length(dwarfs))
		return pick(dwarfs)
	return ..()

/// Recall, come back to your owner
/datum/pet_command/follow/cupcake
	command_name = "Heel"
	command_desc = "Recall your pitbull to your side."
	speech_commands = list("heel", "follow", "come", "here", "recall")

/// Order a neck bite on whatever you point at
/datum/pet_command/point_targeting/use_ability/neck_bite
	command_name = "Neck bite"
	command_desc = "Command your pitbull to go for someone's throat."
	radial_icon = 'icons/effects/effects.dmi'
	radial_icon_state = "bite"
	speech_commands = list("throat", "neck", "rip")
	command_feedback = "snarl"
	pointed_reaction = "and snarls"
	pet_ability_key = BB_TARGETED_ACTION
	ability_behavior = /datum/ai_behavior/pet_use_ability/then_attack

/datum/pet_command/point_targeting/use_ability/neck_bite/set_command_target(mob/living/parent, atom/target)
	if(!target)
		return
	var/datum/targeting_strategy/targeter = GET_TARGETING_STRATEGY(parent.ai_controller.blackboard[targeting_strategy_key])
	if(!targeter?.can_attack(parent, target))
		parent.balloon_alert_to_viewers("shakes head!")
		return FALSE
	return ..()

/datum/movespeed_modifier/cupcake_dwarf_hunt
	multiplicative_slowdown = -0.6

#undef BB_CUPCAKE_FERAL
#undef SPIN_STEPS
