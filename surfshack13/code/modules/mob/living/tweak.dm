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

// HYPER ADRENALINE
// The mode defaults to off on every server boot. Admins may toggle it only
// during startup or pregame; once the round begins, the state is locked.
GLOBAL_VAR_INIT(hyper_adrenaline_active, FALSE)
GLOBAL_VAR_INIT(hyper_adrenaline_base_damage_multiplier, null)

#define HA_HAS_SILENT_TOXIN 0
#define HA_HAS_NO_TOXIN 1
#define HA_HAS_PAINFUL_TOXIN 2
#define HA_MAX_TOXIN_LIVER_DAMAGE 2

/obj/item/var/hyper_adrenaline_throwforce_scaled = FALSE

/obj/item/proc/set_hyper_adrenaline_throwforce(enabled)
	if(enabled)
		if(hyper_adrenaline_throwforce_scaled)
			return
		throwforce *= 2
		hyper_adrenaline_throwforce_scaled = TRUE
		return

	if(!hyper_adrenaline_throwforce_scaled)
		return
	throwforce *= 0.5
	hyper_adrenaline_throwforce_scaled = FALSE

/proc/set_hyper_adrenaline_enabled(enabled)
	if(enabled == GLOB.hyper_adrenaline_active)
		return

	if(enabled)
		GLOB.hyper_adrenaline_base_damage_multiplier = CONFIG_GET(number/damage_multiplier)
		CONFIG_SET(number/damage_multiplier, GLOB.hyper_adrenaline_base_damage_multiplier * 2)
	else
		if(!isnull(GLOB.hyper_adrenaline_base_damage_multiplier))
			CONFIG_SET(number/damage_multiplier, GLOB.hyper_adrenaline_base_damage_multiplier)
		GLOB.hyper_adrenaline_base_damage_multiplier = null

	GLOB.hyper_adrenaline_active = enabled

	// Map-loaded items already exist by the time an admin makes the lobby choice.
	// Scale or restore those items immediately; later-created items are handled by Initialize().
	for(var/obj/item/item in world)
		item.set_hyper_adrenaline_throwforce(enabled)

ADMIN_VERB(toggle_hyper_adrenaline, R_SERVER, "Toggle Hyper Adrenaline", "Enable or disable Hyper Adrenaline before the round starts.", ADMIN_CATEGORY_SERVER)
	if(SSticker.current_state > GAME_STATE_PREGAME)
		to_chat(user, span_warning("Hyper Adrenaline is locked for the current round and can only be changed before round start."))
		return

	var/new_state = !GLOB.hyper_adrenaline_active
	set_hyper_adrenaline_enabled(new_state)
	var/state_text = new_state ? "enabled" : "disabled"

	log_admin("[key_name(user)] [state_text] Hyper Adrenaline for the upcoming round.")
	message_admins(span_adminnotice("[key_name_admin(user)] has [state_text] Hyper Adrenaline for the upcoming round."))
	to_chat(world, span_notice("<b>Hyper Adrenaline has been [state_text] for the upcoming round.</b>"), confidential = TRUE)
	SSblackbox.record_feedback("nested tally", "admin_toggle", 1, list("Toggle Hyper Adrenaline", new_state ? "Enabled" : "Disabled"))

// Preserve upstream item initialization while applying the selected lobby state
// to every item created after the toggle.
/obj/item/Initialize(mapload)
	set_hyper_adrenaline_throwforce(GLOB.hyper_adrenaline_active)

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

// Preserve the complete shared timed-action behavior while conditionally
// halving the requested duration before normal action-speed modifiers apply.
/proc/do_after(mob/user, delay, atom/target, timed_action_flags = NONE, progress = TRUE, datum/callback/extra_checks, interaction_key, max_interact_count = 1, hidden = FALSE)
	if(!user)
		return FALSE
	if(!isnum(delay))
		CRASH("do_after was passed a non-number delay: [delay || "null"].")

	if(GLOB.hyper_adrenaline_active)
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

// Route every explosion through doubled ranges only while the mode is active,
// while keeping upstream caps, logging, and signals.
/proc/explosion(atom/origin, devastation_range = 0, heavy_impact_range = 0, light_impact_range = 0, flame_range = null, flash_range = null, adminlog = TRUE, ignorecap = FALSE, silent = FALSE, smoke = FALSE, protect_epicenter = FALSE, atom/explosion_cause = null, explosion_direction = 0, explosion_arc = 360)
	if(GLOB.hyper_adrenaline_active)
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

// Conditional replacement for the upstream embedding roll. This supersedes the
// earlier branch edit and restores normal probabilities while the mode is off.
/datum/embedding/proc/roll_embed_chance(mob/living/carbon/victim, hit_zone, datum/thrownthing/throwingdatum)
	var/chance = embed_chance
	if(GLOB.hyper_adrenaline_active)
		chance = min(chance * HYPER_ADRENALINE_EMBED_CHANCE_MULTIPLIER, 100)

	// Something threw us really, really fast
	if (throwingdatum?.speed > parent.throw_speed)
		chance += (throwingdatum.speed - parent.throw_speed) * EMBED_CHANCE_SPEED_BONUS

	if (is_harmless())
		return prob(chance)

	// We'll be nice and take the better of bullet and bomb armor, halved
	var/armor = max(victim.run_armor_check(hit_zone, BULLET, armour_penetration = parent.armour_penetration, silent = TRUE), victim.run_armor_check(hit_zone, BOMB, armour_penetration = parent.armour_penetration,  silent = TRUE)) * 0.5
	// We only care about armor penetration if there's actually armor to penetrate
	if(!armor)
		return prob(chance)

	if (parent.weak_against_armour)
		armor *= ARMOR_WEAKENED_MULTIPLIER

	chance -= armor
	if (chance < 0)
		victim.visible_message(span_danger("[parent] bounces off [victim]'s armor, unable to embed!"),
			span_notice("[parent] bounces off your armor, unable to embed!"), vision_distance = COMBAT_MESSAGE_RANGE)
		return FALSE

	return prob(chance)

// Conditional replacement for normal reagent metabolism.
/datum/reagents/proc/metabolize(mob/living/carbon/owner, seconds_per_tick, times_fired, can_overdose = FALSE, liverless = FALSE, dead = FALSE)
	if(GLOB.hyper_adrenaline_active)
		seconds_per_tick *= HYPER_ADRENALINE_CHEM_EFFECT_MULTIPLIER

	var/list/cached_reagents = reagent_list
	if(owner)
		expose_temperature(owner.bodytemperature, 0.25)

	var/need_mob_update = FALSE
	var/obj/item/organ/stomach/belly = owner.get_organ_slot(ORGAN_SLOT_STOMACH)
	var/obj/item/organ/liver/liver = owner.get_organ_slot(ORGAN_SLOT_LIVER)
	var/liver_tolerance = 0
	var/liver_damage = 0
	var/provide_pain_message
	var/amount
	if(liver)
		var/liver_health_percent = (liver.maxHealth - liver.damage) / liver.maxHealth
		liver_tolerance = liver.toxTolerance * liver_health_percent
		provide_pain_message = HA_HAS_NO_TOXIN

	for(var/datum/reagent/reagent as anything in cached_reagents)
		var/datum/reagent/toxin/toxin
		if(istype(reagent, /datum/reagent/toxin))
			toxin = reagent
		// skip metabolizing effects for small units of toxins
		if(toxin && liver && !dead)
			amount = toxin.volume
			if(belly)
				amount += belly.reagents.get_reagent_amount(toxin.type)

			if(amount <= liver_tolerance * toxin.liver_tolerance_multiplier)
				owner.reagents.remove_reagent(toxin.type, toxin.metabolization_rate * owner.metabolism_efficiency * seconds_per_tick)
				continue

		need_mob_update += metabolize_reagent(owner, reagent, seconds_per_tick, times_fired, can_overdose, liverless, dead)

		// If applicable, calculate any toxin-related liver damage
		// Note: we have to do this AFTER metabolize_reagent, because we want handle_reagent to run before we make the determination.
		// The order is really important unfortunately.
		if(toxin && !liverless && liver && liver.filterToxins && !HAS_TRAIT(owner, TRAIT_TOXINLOVER))
			if(toxin.affected_organ_flags && !(liver.organ_flags & toxin.affected_organ_flags)) //this particular toxin does not affect this type of organ
				continue

			// a 15u syringe is a nice baseline to scale lethality by
			liver_damage += ((amount/15) * toxin.toxpwr * toxin.liver_damage_multiplier) / liver.liver_resistance

			if(provide_pain_message != HA_HAS_PAINFUL_TOXIN)
				provide_pain_message = toxin.silent_toxin ? HA_HAS_SILENT_TOXIN : HA_HAS_PAINFUL_TOXIN

	// if applicable, apply our liver damage and display the accompanying pain message
	if(liver_damage)
		liver.apply_organ_damage(min(liver_damage * seconds_per_tick , HA_MAX_TOXIN_LIVER_DAMAGE * seconds_per_tick))

	if(provide_pain_message && liver.damage > 10 && SPT_PROB(liver.damage/6, seconds_per_tick)) //the higher the damage the higher the probability
		to_chat(owner, span_warning("You feel a dull pain in your abdomen."))

	if(owner && need_mob_update) //some of the metabolized reagents had effects on the mob that requires some updates.
		owner.updatehealth()
	update_total()

/datum/reagents/proc/handle_stasis_chems(mob/living/carbon/owner, seconds_per_tick, times_fired)
	if(GLOB.hyper_adrenaline_active)
		seconds_per_tick *= HYPER_ADRENALINE_CHEM_EFFECT_MULTIPLIER

	var/need_mob_update = FALSE
	for(var/datum/reagent/reagent as anything in reagent_list)
		if(!(reagent.chemical_flags & REAGENT_IGNORE_STASIS))
			continue
		need_mob_update += metabolize_reagent(owner, reagent, seconds_per_tick, times_fired, can_overdose = TRUE)
	if(owner && need_mob_update) //some of the metabolized reagents had effects on the mob that requires some updates.
		owner.updatehealth()
	update_total()

// Conditional replacement for shared wound generation.
/obj/item/bodypart/proc/check_wounding(woundtype, damage, wound_bonus, bare_wound_bonus, attack_direction, damage_source, wound_clothing)
	SHOULD_CALL_PARENT(TRUE)
	RETURN_TYPE(/datum/wound)

	if(GLOB.hyper_adrenaline_active)
		damage *= HYPER_ADRENALINE_WOUND_MULTIPLIER

	if(HAS_TRAIT(owner, TRAIT_NEVER_WOUNDED) || HAS_TRAIT(owner, TRAIT_GODMODE))
		return

	// note that these are fed into an exponent, so these are magnified
	if(HAS_TRAIT(owner, TRAIT_EASILY_WOUNDED))
		damage *= 1.5
	else
		damage = min(damage, WOUND_MAX_CONSIDERED_DAMAGE)

	if(HAS_TRAIT(owner,TRAIT_HARDLY_WOUNDED))
		damage *= 0.85

	if(HAS_TRAIT(owner, TRAIT_EASYDISMEMBER))
		damage *= 1.1

	if(HAS_TRAIT(owner, TRAIT_EASYBLEED) && ((woundtype == WOUND_PIERCE) || (woundtype == WOUND_SLASH)))
		damage *= 1.5

	var/base_roll = rand(1, round(damage ** WOUND_DAMAGE_EXPONENT))
	var/injury_roll = base_roll
	injury_roll += check_woundings_mods(woundtype, damage, wound_bonus, bare_wound_bonus, wound_clothing)
	var/list/series_wounding_mods = check_series_wounding_mods()

	if(injury_roll > WOUND_DISMEMBER_OUTRIGHT_THRESH && prob(get_damage() / max_damage * 100) && can_dismember())
		var/datum/wound/loss/dismembering = new
		dismembering.apply_dismember(src, woundtype, outright = TRUE, attack_direction = attack_direction)
		return

	var/list/datum/wound/possible_wounds = list()
	for (var/datum/wound/type as anything in GLOB.all_wound_pregen_data)
		var/datum/wound_pregen_data/pregen_data = GLOB.all_wound_pregen_data[type]
		if (pregen_data.can_be_applied_to(src, list(woundtype), random_roll = TRUE))
			possible_wounds[type] = pregen_data.get_weight(src, woundtype, damage, attack_direction, damage_source)
	// quick re-check to see if bare_wound_bonus applies, for the benefit of log_wound(), see about getting the check from check_woundings_mods() somehow
	if(ishuman(owner))
		var/mob/living/carbon/human/human_wearer = owner
		var/list/clothing = human_wearer.get_clothing_on_part(src)
		for(var/obj/item/clothing/clothes_check as anything in clothing)
			// unlike normal armor checks, we tabluate these piece-by-piece manually so we can also pass on appropriate damage the clothing's limbs if necessary
			if(clothes_check.get_armor_rating(WOUND))
				bare_wound_bonus = 0
				break

	for (var/datum/wound/iterated_path as anything in possible_wounds)
		for (var/datum/wound/existing_wound as anything in wounds)
			if (iterated_path == existing_wound.type)
				possible_wounds -= iterated_path
				break // breaks out of the nested loop

		var/datum/wound_pregen_data/pregen_data = GLOB.all_wound_pregen_data[iterated_path]
		var/specific_injury_roll = (injury_roll + series_wounding_mods[pregen_data.wound_series])
		if (pregen_data.get_threshold_for(src, attack_direction, damage_source) > specific_injury_roll)
			possible_wounds -= iterated_path
			continue

		if (pregen_data.compete_for_wounding)
			for (var/datum/wound/other_path as anything in possible_wounds)
				if (other_path == iterated_path)
					continue
				if (initial(iterated_path.severity) == initial(other_path.severity) && pregen_data.overpower_wounds_of_even_severity)
					possible_wounds -= other_path
					continue
				else if (pregen_data.competition_mode == WOUND_COMPETITION_OVERPOWER_LESSERS)
					if (initial(iterated_path.severity) > initial(other_path.severity))
						possible_wounds -= other_path
						continue
				else if (pregen_data.competition_mode == WOUND_COMPETITION_OVERPOWER_GREATERS)
					if (initial(iterated_path.severity) < initial(other_path.severity))
						possible_wounds -= other_path
						continue

	while (TRUE)
		var/datum/wound/possible_wound = pick_weight(possible_wounds)
		if (isnull(possible_wound))
			break

		possible_wounds -= possible_wound
		var/datum/wound_pregen_data/possible_pregen_data = GLOB.all_wound_pregen_data[possible_wound]

		var/datum/wound/replaced_wound
		for(var/datum/wound/existing_wound as anything in wounds)
			var/datum/wound_pregen_data/existing_pregen_data = GLOB.all_wound_pregen_data[existing_wound.type]
			if(existing_pregen_data.wound_series == possible_pregen_data.wound_series)
				if(existing_wound.severity >= initial(possible_wound.severity))
					continue
				else
					replaced_wound = existing_wound
			// if we get through this whole loop without continuing, we found our winner

		var/datum/wound/new_wound = new possible_wound
		if(replaced_wound)
			new_wound = replaced_wound.replace_wound(new_wound, attack_direction = attack_direction)
		else
			new_wound.apply_wound(src, attack_direction = attack_direction, wound_source = damage_source)
		log_wound(owner, new_wound, damage, wound_bonus, bare_wound_bonus, base_roll) // dismembering wounds are logged in the apply_wound() for loss wounds since they delete themselves immediately, these will be immediately returned
		return new_wound

#undef HA_HAS_SILENT_TOXIN
#undef HA_HAS_NO_TOXIN
#undef HA_HAS_PAINFUL_TOXIN
#undef HA_MAX_TOXIN_LIVER_DAMAGE
