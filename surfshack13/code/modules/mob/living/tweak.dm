/datum/emote/living/tweak
	key = "tweak"
	key_third_person = "tweaks"
	message = "starts tweaking"

// muscle twitching is incredibly energy intensive, IRL the body does it in an attempt to increase circulation and flush harmful chemicals out the body, or to warm up the body
/datum/emote/living/tweak/run_emote(mob/user, params, type_override, intentional)
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		if(!C.adjustStaminaLoss(60))
			return
	user.AddComponent(/datum/component/tweak, time=8 SECONDS)
	return ..()

// HYPER ADRENALINE: force the global damage/healing multiplier to at least 2x.
// This late-loaded modular definition overrides the upstream config entry defaults
// and rejects a lower value from game_options.txt.
/datum/config_entry/number/damage_multiplier
	default = 2
	min_val = 2
	integer = FALSE

// HYPER ADRENALINE: preserve the upstream item initialization behavior while
// doubling the impact force of every thrown item instance.
/obj/item/Initialize(mapload)
	throwforce *= 2

	if(attack_verb_continuous)
		attack_verb_continuous = string_list(attack_verb_continuous)
	if(attack_verb_simple)
		attack_verb_simple = string_list(attack_verb_simple)
	if(species_exception)
		species_exception = string_list(species_exception)

	if(sharpness && force > 5) //give sharp objects butchering functionality, for consistency
		AddComponent(/datum/component/butchering, speed = 8 SECONDS * toolspeed)

	if(!greyscale_config && greyscale_colors && (greyscale_config_worn || greyscale_config_belt || greyscale_config_inhand_right || greyscale_config_inhand_left))
		update_greyscale()

	. = ..()

	// Handle adding item associated actions
	for(var/path in actions_types)
		add_item_action(path)
	actions_types = null

	if(force_string)
		item_flags |= FORCE_STRING_OVERRIDE

	if(!hitsound)
		if(damtype == BURN)
			hitsound = 'sound/items/tools/welder.ogg'
		if(damtype == BRUTE)
			hitsound = SFX_SWING_HIT

	add_weapon_description()

	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_NEW_ITEM, src)

	setup_reskinning()

// HYPER ADRENALINE: preserve the complete shared timed-action behavior while
// halving the requested duration before normal action-speed modifiers apply.
/proc/do_after(mob/user, delay, atom/target, timed_action_flags = NONE, progress = TRUE, datum/callback/extra_checks, interaction_key, max_interact_count = 1, hidden = FALSE)
	if(!user)
		return FALSE
	if(!isnum(delay))
		CRASH("do_after was passed a non-number delay: [delay || "null"].")

	delay *= HYPER_ADRENALINE_ACTION_TIME_MULTIPLIER

	if(!interaction_key && target)
		interaction_key = target //Use the direct ref to the target
	if(interaction_key) //Do we have a interaction_key now?
		var/current_interaction_count = LAZYACCESS(user.do_afters, interaction_key) || 0
		if(current_interaction_count >= max_interact_count) //We are at our peak
			return
		LAZYSET(user.do_afters, interaction_key, current_interaction_count + 1)

	var/atom/user_loc = user.loc
	var/atom/target_loc = target?.loc

	var/drifting = FALSE
	if(GLOB.move_manager.processing_on(user, SSspacedrift))
		drifting = TRUE

	var/holding = user.get_active_held_item()

	if(!(timed_action_flags & IGNORE_SLOWDOWNS))
		delay *= user.cached_multiplicative_actions_slowdown

	var/datum/progressbar/progbar
	var/datum/cogbar/cog

	if(progress)
		if(user.client)
			progbar = new(user, delay, target || user)

		if(!hidden && delay >= 1 SECONDS)
			cog = new(user)

	SEND_SIGNAL(user, COMSIG_DO_AFTER_BEGAN)

	var/endtime = world.time + delay
	var/starttime = world.time
	. = TRUE
	while (world.time < endtime)
		stoplag(1)

		if(!QDELETED(progbar))
			progbar.update(world.time - starttime)

		if(drifting && !GLOB.move_manager.processing_on(user, SSspacedrift))
			drifting = FALSE
			user_loc = user.loc

		if(QDELETED(user) \
			|| (!(timed_action_flags & IGNORE_USER_LOC_CHANGE) && !drifting && user.loc != user_loc) \
			|| (!(timed_action_flags & IGNORE_HELD_ITEM) && user.get_active_held_item() != holding) \
			|| (!(timed_action_flags & IGNORE_INCAPACITATED) && HAS_TRAIT(user, TRAIT_INCAPACITATED)) \
			|| (extra_checks && !extra_checks.Invoke()))
			. = FALSE
			break

		if(target && (user != target) && \
			(QDELETED(target) \
			|| (!(timed_action_flags & IGNORE_TARGET_LOC_CHANGE) && target.loc != target_loc)))
			. = FALSE
			break

	if(!QDELETED(progbar))
		progbar.end_progress()

	cog?.remove()

	if(interaction_key)
		var/reduced_interaction_count = (LAZYACCESS(user.do_afters, interaction_key) || 0) - 1
		if(reduced_interaction_count > 0) // Not done yet!
			LAZYSET(user.do_afters, interaction_key, reduced_interaction_count)
			return
		// all out, let's clear er out fully
		LAZYREMOVE(user.do_afters, interaction_key)
	SEND_SIGNAL(user, COMSIG_DO_AFTER_ENDED)

// HYPER ADRENALINE: route every explosion through doubled ranges while keeping
// the upstream subsystem implementation and all its caps, logging, and signals.
/proc/explosion(atom/origin, devastation_range = 0, heavy_impact_range = 0, light_impact_range = 0, flame_range = null, flash_range = null, adminlog = TRUE, ignorecap = FALSE, silent = FALSE, smoke = FALSE, protect_epicenter = FALSE, atom/explosion_cause = null, explosion_direction = 0, explosion_arc = 360)
	devastation_range *= HYPER_ADRENALINE_EXPLOSION_MULTIPLIER
	heavy_impact_range *= HYPER_ADRENALINE_EXPLOSION_MULTIPLIER
	light_impact_range *= HYPER_ADRENALINE_EXPLOSION_MULTIPLIER

	if(!isnull(flame_range))
		flame_range *= HYPER_ADRENALINE_EXPLOSION_MULTIPLIER

	if(!isnull(flash_range))
		flash_range *= HYPER_ADRENALINE_EXPLOSION_MULTIPLIER

	return SSexplosions.explode(
		origin,
		devastation_range,
		heavy_impact_range,
		light_impact_range,
		flame_range,
		flash_range,
		adminlog,
		ignorecap,
		silent,
		smoke,
		protect_epicenter,
		explosion_cause,
		explosion_direction,
		explosion_arc,
	)
