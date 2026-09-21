/datum/martial_art/psychotic_brawling
	name = "Psychotic Brawling"
	id = MARTIALART_PSYCHOBRAWL
	pacifist_style = TRUE

/datum/martial_art/psychotic_brawling/disarm_act(mob/living/attacker, mob/living/defender)
	return psycho_attack(attacker, defender)

/datum/martial_art/psychotic_brawling/grab_act(mob/living/attacker, mob/living/defender)
	return psycho_attack(attacker, defender, TRUE)

/datum/martial_art/psychotic_brawling/harm_act(mob/living/attacker, mob/living/defender)
	return psycho_attack(attacker, defender)

/datum/martial_art/psychotic_brawling/proc/psycho_attack(mob/living/attacker, mob/living/defender, grab_attack)
	var/atk_verb
	switch(rand(1,8))
		if(1)
			if(iscarbon(defender) && iscarbon(attacker))
				var/mob/living/carbon/carbon_defender = defender
				carbon_defender.help_shake_act(attacker)
			atk_verb = "helped"
		if(2)
			attacker.emote("cry")
			attacker.Stun(2 SECONDS)
			atk_verb = "cried looking at"
		if(3)
			if(defender.check_block(attacker, 0, "[attacker]'s grab", UNARMED_ATTACK))
				return MARTIAL_ATTACK_FAIL
			if(attacker.body_position == LYING_DOWN)
				return MARTIAL_ATTACK_INVALID

			if(attacker.grab_state >= GRAB_AGGRESSIVE)
				defender.grabbedby(attacker, 1)
			else
				attacker.start_pulling(defender, supress_message = TRUE)
				if(attacker.pulling)
					defender.drop_all_held_items()
					defender.stop_pulling()
					if(grab_attack)
						log_combat(attacker, defender, "grabbed", addition="aggressively")
						defender.visible_message(
							span_warning("[attacker] violently grabs [defender]!"),
							span_userdanger("You're violently grabbed by [attacker]!"),
							span_hear("You hear sounds of aggressive fondling!"),
							null,
							attacker,
						)
						to_chat(attacker, span_danger("You violently grab [defender]!"))
						attacker.setGrabState(GRAB_AGGRESSIVE) //Instant aggressive grab
					else
						log_combat(attacker, defender, "grabbed", addition="passively")
						attacker.setGrabState(GRAB_PASSIVE)
		if(4)
			atk_verb = "headbutt"
			var/defender_damage = rand(5, 10)
			if(defender.check_block(attacker, defender_damage, "[attacker]'s [atk_verb]", UNARMED_ATTACK))
				return MARTIAL_ATTACK_FAIL

			attacker.do_attack_animation(defender, ATTACK_EFFECT_PUNCH)
			attacker.emote("flip")
			defender.visible_message(
				span_danger("[attacker] [atk_verb]s [defender]!"),
				span_userdanger("You're [atk_verb]ed by [attacker]!"),
				span_hear("You hear a sickening sound of flesh hitting flesh!"),
				null,
				attacker,
			)
			to_chat(attacker, span_danger("You [atk_verb] [defender]!"))
			playsound(defender, 'sound/items/weapons/punch1.ogg', 40, TRUE, -1)
			defender.apply_damage(defender_damage, attacker.get_attack_type(), BODY_ZONE_HEAD)
			attacker.apply_damage(rand(5, 10), attacker.get_attack_type(), BODY_ZONE_HEAD)
			if(iscarbon(defender))
				var/mob/living/carbon/carbon_defender = defender
				if(!istype(carbon_defender.head, /obj/item/clothing/head/helmet/) && !istype(carbon_defender.head, /obj/item/clothing/head/utility/hardhat))
					carbon_defender.adjustOrganLoss(ORGAN_SLOT_BRAIN, 5)
			attacker.Stun(rand(1 SECONDS, 4.5 SECONDS))
			defender.Stun(rand(0.5 SECONDS, 3 SECONDS))
			if(HAS_TRAIT(attacker, TRAIT_PACIFISM))
				attacker.add_mood_event("bypassed_pacifism", /datum/mood_event/pacifism_bypassed)
		if(5,6)
			atk_verb = pick("kick", "hit", "slam")
			if(defender.check_block(attacker, 0, "[attacker]'s [atk_verb]", UNARMED_ATTACK))
				return MARTIAL_ATTACK_FAIL

			attacker.do_attack_animation(defender, ATTACK_EFFECT_PUNCH)
			defender.visible_message(
				span_danger("[attacker] [atk_verb]s [defender] with such inhuman strength that it sends [defender.p_them()] flying backwards!"),
				span_userdanger("You're [atk_verb]ed by [attacker] with such inhuman strength that it sends you flying backwards!"),
				span_hear("You hear a sickening sound of flesh hitting flesh!"),
				null,
				attacker,
			)
			to_chat(attacker, span_danger("You [atk_verb] [defender] with such inhuman strength that it sends [defender.p_them()] flying backwards!"))
			defender.apply_damage(rand(15, 30), attacker.get_attack_type())
			playsound(defender, 'sound/effects/meteorimpact.ogg', 25, TRUE, -1)
			var/throwtarget = get_edge_target_turf(attacker, get_dir(attacker, get_step_away(defender, attacker)))
			defender.throw_at(throwtarget, 4, 2, attacker)//So stuff gets tossed around at the same time.
			defender.Paralyze(6 SECONDS)
			if(HAS_TRAIT(attacker, TRAIT_PACIFISM))
				attacker.add_mood_event("bypassed_pacifism", /datum/mood_event/pacifism_bypassed)
		if(7,8)
			return MARTIAL_ATTACK_INVALID //Resume default behaviour

	if(atk_verb)
		log_combat(attacker, defender, "[atk_verb] (Psychotic Brawling)")
		return MARTIAL_ATTACK_SUCCESS

	return MARTIAL_ATTACK_FAIL

// Surf Shack: methamphetamine overdose martial art.
#define TWEAKER_FLURRY_COMBO "HH"
#define TWEAKER_ROCKET_KICK_COMBO "HD"
#define TWEAKER_SHAKEDOWN_COMBO "GH"

/mob/living/proc/tweaker_fu_help()
	set name = "Recall Tweaker Fu"
	set desc = "Remember the combat geometry currently screaming through your bloodstream."
	set category = "Tweaker Fu"

	var/brain_damage = 0
	if(iscarbon(src))
		var/mob/living/carbon/carbon_user = src
		brain_damage = clamp(carbon_user.get_organ_loss(ORGAN_SLOT_BRAIN), 0, BRAIN_DAMAGE_DEATH)
	var/brain_ratio = brain_damage / BRAIN_DAMAGE_DEATH
	var/damage_bonus = round(brain_ratio * 20, 0.1)
	var/damage_reduction = round(brain_ratio * 10, 0.1)
	var/stamina_reduction = round(brain_ratio * 15, 0.1)

	to_chat(src, span_boldnotice("Tweaker Fu"))
	to_chat(src, span_notice("Meth overdose unlocked this temporary martial art. It remains usable while methamphetamine is still in your system."))
	to_chat(src, span_notice("The more brain damage you have, the stronger your Tweaker Fu becomes: up to 20% more attack damage, 10% less incoming physical damage, and 15% less stamina damage at 200 brain damage."))
	to_chat(src, span_notice("Current brain damage: [round(brain_damage, 0.1)] / [BRAIN_DAMAGE_DEATH]. Current bonuses: +[damage_bonus]% attack damage, -[damage_reduction]% incoming physical damage, -[stamina_reduction]% stamina damage."))
	to_chat(src, span_notice("While Tweaker Fu is active, you slowly recover brain damage and stamina."))
	to_chat(src, span_boldnotice("Combos:"))
	to_chat(src, span_notice("Machine-Gun Jabs: Harm, Harm - five rapid punches, plus up to 7.5 brain damage if all five land."))
	to_chat(src, span_notice("Rocket Kick: Harm, Shove - a flying kick that sends the target backwards and deals 9 brain damage."))
	to_chat(src, span_notice("Shakedown: Grab, Harm - while pulling the target, rattle them hard enough to deal stamina damage and floor them."))
	to_chat(src, span_notice("Every Tweaker Fu attack makes you scream."))

/datum/martial_art/tweaker_fu
	name = "Tweaker Fu"
	id = MARTIALART_TWEAKER_FU
	help_verb = /mob/living/proc/tweaker_fu_help
	display_combos = TRUE
	combo_timer = 4 SECONDS
	max_streak_length = 2
	var/meth_check_timer
	var/datum/weakref/tweaker_holder

/datum/martial_art/tweaker_fu/on_teach(mob/living/new_holder)
	. = ..()
	tweaker_holder = WEAKREF(new_holder)
	RegisterSignal(new_holder, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, PROC_REF(tweaker_damage_resistance))
	to_chat(new_holder, span_userdanger("Your heart hammers. Every twitch suddenly looks like a combat technique. You have discovered Tweaker Fu!"))
	to_chat(new_holder, span_notice("Use the 'Recall Tweaker Fu' button in the Tweaker Fu actions category to read your moves and current brain-damage bonuses."))
	meth_check_timer = addtimer(CALLBACK(src, PROC_REF(check_meth)), 2 SECONDS, TIMER_STOPPABLE)

/datum/martial_art/tweaker_fu/on_remove(mob/living/remove_from)
	if(meth_check_timer)
		deltimer(meth_check_timer)
		meth_check_timer = null
	UnregisterSignal(remove_from, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS)
	tweaker_holder = null
	to_chat(remove_from, span_notice("The impossible combat geometry finally stops making sense."))
	return ..()

/datum/martial_art/tweaker_fu/can_use(mob/living/martial_artist)
	if(!martial_artist.reagents?.has_reagent(/datum/reagent/drug/methamphetamine))
		return FALSE
	return ..()

/datum/martial_art/tweaker_fu/proc/get_brain_damage(mob/living/user)
	if(!iscarbon(user))
		return 0
	var/mob/living/carbon/carbon_user = user
	return clamp(carbon_user.get_organ_loss(ORGAN_SLOT_BRAIN), 0, BRAIN_DAMAGE_DEATH)

/datum/martial_art/tweaker_fu/proc/get_power_multiplier(mob/living/user)
	return 1 + (0.2 * get_brain_damage(user) / BRAIN_DAMAGE_DEATH)

/datum/martial_art/tweaker_fu/proc/tweaker_damage_resistance(datum/source, list/damage_mods, damage_amount, damagetype, def_zone, sharpness, attack_direction, obj/item/attacking_item)
	SIGNAL_HANDLER

	var/mob/living/current_holder = source
	var/brain_ratio = get_brain_damage(current_holder) / BRAIN_DAMAGE_DEATH
	if(brain_ratio <= 0)
		return

	if(damagetype == STAMINA)
		damage_mods += 1 - (0.15 * brain_ratio)
	else if(damagetype == BRUTE || damagetype == BURN || damagetype == TOX || damagetype == OXY)
		damage_mods += 1 - (0.1 * brain_ratio)

/datum/martial_art/tweaker_fu/proc/check_meth()
	meth_check_timer = null
	var/mob/living/current_holder = tweaker_holder?.resolve()
	if(isnull(current_holder))
		return
	if(!current_holder.reagents?.has_reagent(/datum/reagent/drug/methamphetamine))
		fully_remove(current_holder)
		return

	var/brain_damage = get_brain_damage(current_holder)
	if(iscarbon(current_holder) && brain_damage > 0)
		var/mob/living/carbon/carbon_holder = current_holder
		carbon_holder.adjustOrganLoss(ORGAN_SLOT_BRAIN, -0.625)
	current_holder.adjustStaminaLoss(-(0.25 + (0.5 * brain_damage / BRAIN_DAMAGE_DEATH)))
	meth_check_timer = addtimer(CALLBACK(src, PROC_REF(check_meth)), 2 SECONDS, TIMER_STOPPABLE)

/datum/martial_art/tweaker_fu/proc/combat_scream(mob/living/attacker)
	attacker.emote("scream")

/datum/martial_art/tweaker_fu/proc/check_streak(mob/living/attacker, mob/living/defender)
	if(findtext(streak, TWEAKER_FLURRY_COMBO))
		reset_streak()
		return machinegun_jabs(attacker, defender)
	if(findtext(streak, TWEAKER_ROCKET_KICK_COMBO))
		reset_streak()
		return rocket_kick(attacker, defender)
	if(findtext(streak, TWEAKER_SHAKEDOWN_COMBO))
		reset_streak()
		return shakedown(attacker, defender)
	return FALSE

/datum/martial_art/tweaker_fu/harm_act(mob/living/attacker, mob/living/defender)
	var/final_damage = 9 * get_power_multiplier(attacker)
	if(defender.check_block(attacker, final_damage, "[attacker]'s frantic punch", UNARMED_ATTACK))
		return MARTIAL_ATTACK_FAIL

	combat_scream(attacker)
	add_to_streak("H", defender)
	if(check_streak(attacker, defender))
		return MARTIAL_ATTACK_SUCCESS

	var/obj/item/bodypart/affecting = defender.get_bodypart(defender.get_random_valid_zone(attacker.zone_selected))
	attacker.do_attack_animation(defender, ATTACK_EFFECT_PUNCH)
	playsound(defender, 'sound/items/weapons/punch1.ogg', 30, TRUE, -1)
	defender.apply_damage(final_damage, attacker.get_attack_type(), affecting)
	defender.visible_message(
		span_danger("[attacker] snaps a twitchy punch into [defender]!"),
		span_userdanger("[attacker] snaps a twitchy punch into you!"),
		span_hear("You hear a quick smack of flesh!"),
		COMBAT_MESSAGE_RANGE,
		attacker,
	)
	to_chat(attacker, span_danger("You twitch-punch [defender]!"))
	log_combat(attacker, defender, "punched (Tweaker Fu)")
	return MARTIAL_ATTACK_SUCCESS

/datum/martial_art/tweaker_fu/disarm_act(mob/living/attacker, mob/living/defender)
	if(defender.check_block(attacker, 0, "[attacker]'s twitchy shove", UNARMED_ATTACK))
		return MARTIAL_ATTACK_FAIL

	combat_scream(attacker)
	add_to_streak("D", defender)
	if(check_streak(attacker, defender))
		return MARTIAL_ATTACK_SUCCESS

	defender.apply_damage(10 * get_power_multiplier(attacker), STAMINA)
	return MARTIAL_ATTACK_INVALID

/datum/martial_art/tweaker_fu/grab_act(mob/living/attacker, mob/living/defender)
	if(defender.check_block(attacker, 0, "[attacker]'s twitchy grab", UNARMED_ATTACK))
		return MARTIAL_ATTACK_FAIL

	combat_scream(attacker)
	add_to_streak("G", defender)
	return MARTIAL_ATTACK_INVALID

/datum/martial_art/tweaker_fu/proc/machinegun_jabs(mob/living/attacker, mob/living/defender)
	var/obj/item/bodypart/affecting = defender.get_bodypart(defender.get_random_valid_zone(attacker.zone_selected))
	var/power_multiplier = get_power_multiplier(attacker)
	var/hits_landed = 0
	defender.visible_message(
		span_danger("[attacker]'s arms blur into a frantic barrage of jabs at [defender]!"),
		span_userdanger("[attacker]'s arms blur into a frantic barrage of jabs at you!"),
		span_hear("You hear a rapid series of thuds!"),
		COMBAT_MESSAGE_RANGE,
		attacker,
	)
	to_chat(attacker, span_danger("You machine-gun jab [defender]!"))
	for(var/i in 1 to 5)
		if(QDELETED(defender) || !attacker.Adjacent(defender))
			break
		attacker.do_attack_animation(defender, ATTACK_EFFECT_PUNCH)
		playsound(defender, 'sound/items/weapons/punch1.ogg', 35, TRUE, -1)
		defender.apply_damage(4 * power_multiplier, attacker.get_attack_type(), affecting)
		hits_landed++
		sleep(0.1 SECONDS)
	if(QDELETED(defender))
		return TRUE
	defender.apply_damage(10 * power_multiplier, STAMINA)
	if(iscarbon(defender) && hits_landed)
		var/mob/living/carbon/carbon_defender = defender
		carbon_defender.adjustOrganLoss(ORGAN_SLOT_BRAIN, hits_landed * 1.5)
	log_combat(attacker, defender, "machine-gun jabbed (Tweaker Fu), [hits_landed] hits")
	return TRUE

/datum/martial_art/tweaker_fu/proc/rocket_kick(mob/living/attacker, mob/living/defender)
	attacker.do_attack_animation(defender, ATTACK_EFFECT_KICK)
	playsound(defender, 'sound/effects/hit_kick.ogg', 50, TRUE, -1)
	defender.apply_damage(12 * get_power_multiplier(attacker), attacker.get_attack_type(), BODY_ZONE_CHEST)
	if(iscarbon(defender))
		var/mob/living/carbon/carbon_defender = defender
		carbon_defender.adjustOrganLoss(ORGAN_SLOT_BRAIN, 9)
	var/atom/throw_target = get_edge_target_turf(defender, get_dir(attacker, defender))
	defender.throw_at(throw_target, 4, 2, attacker)
	defender.visible_message(
		span_danger("[attacker] launches a wildly overcommitted kick into [defender], sending [defender.p_them()] flying!"),
		span_userdanger("[attacker] launches a wildly overcommitted kick into you, sending you flying!"),
		span_hear("You hear a heavy kick connect!"),
		COMBAT_MESSAGE_RANGE,
		attacker,
	)
	to_chat(attacker, span_danger("You rocket-kick [defender]!"))
	log_combat(attacker, defender, "rocket kicked (Tweaker Fu)")
	return TRUE

/datum/martial_art/tweaker_fu/proc/shakedown(mob/living/attacker, mob/living/defender)
	if(attacker.pulling != defender)
		return FALSE

	attacker.do_attack_animation(defender, ATTACK_EFFECT_PUNCH)
	playsound(defender, 'sound/items/weapons/thudswoosh.ogg', 40, TRUE, -1)
	defender.apply_damage(25 * get_power_multiplier(attacker), STAMINA)
	defender.Knockdown(3 SECONDS)
	defender.visible_message(
		span_danger("[attacker] violently rattles [defender] around before dumping [defender.p_them()] onto the floor!"),
		span_userdanger("[attacker] violently rattles you around and dumps you onto the floor!"),
		span_hear("You hear frantic shuffling and a thud!"),
		COMBAT_MESSAGE_RANGE,
		attacker,
	)
	to_chat(attacker, span_danger("You shake [defender] down!"))
	log_combat(attacker, defender, "shook down (Tweaker Fu)")
	return TRUE

/datum/reagent/drug/methamphetamine/overdose_start(mob/living/affected_mob)
	. = ..()
	var/datum/martial_art/tweaker_fu/style = new()
	if(!style.teach(affected_mob, make_temporary = TRUE))
		qdel(style)

#undef TWEAKER_FLURRY_COMBO
#undef TWEAKER_ROCKET_KICK_COMBO
#undef TWEAKER_SHAKEDOWN_COMBO