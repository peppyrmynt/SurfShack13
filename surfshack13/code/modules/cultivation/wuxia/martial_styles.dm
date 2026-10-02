/**
 * Wuxia martial arts styles, learned from secret manuals hidden around the station.
 * H = punch (harm), D = shove (disarm), G = grab. Each style has a "Recall Teachings" verb listing its combos.
 * Every martial artist also learns to issue honor duels.
 */
/datum/martial_art/wuxia
	name = "Wuxia Style"
	display_combos = TRUE
	/// combo string -> proc name, checked longest first
	var/list/combos = list()
	/// Base punch damage range
	var/punch_low = 8
	var/punch_high = 12
	/// Verbs for normal punches
	var/list/punch_verbs = list("strike")
	/// The duel action we hand out
	var/datum/action/cooldown/jianghu_duel/duel_action

/datum/martial_art/wuxia/on_teach(mob/living/new_holder)
	. = ..()
	if(!locate(/datum/action/cooldown/jianghu_duel) in new_holder.actions)
		duel_action = new(new_holder.mind || new_holder)
		duel_action.Grant(new_holder)

/datum/martial_art/wuxia/on_remove(mob/living/remove_from)
	QDEL_NULL(duel_action)
	return ..()

/datum/martial_art/wuxia/proc/check_streak(mob/living/attacker, mob/living/defender)
	for(var/combo in combos)
		if(findtext(streak, combo))
			reset_streak()
			perform_combo(combos[combo], attacker, defender)
			// Pulling off a combo is good practice
			cultivation_insight(attacker, 2, "martial_combo", 60 SECONDS)
			return TRUE
	return FALSE

/// Each style runs its own combos by name
/datum/martial_art/wuxia/proc/perform_combo(combo_name, mob/living/attacker, mob/living/defender)
	return

/// Shared plain hit used by styles and combos
/datum/martial_art/wuxia/proc/strike(mob/living/attacker, mob/living/defender, damage, verb_used, effect = ATTACK_EFFECT_PUNCH, damage_type, sharpness = NONE, sound = 'sound/items/weapons/punch1.ogg')
	var/obj/item/bodypart/affecting = defender.get_bodypart(defender.get_random_valid_zone(attacker.zone_selected))
	attacker.do_attack_animation(defender, effect)
	defender.visible_message(
		span_danger("[attacker] [verb_used]s [defender]!"),
		span_userdanger("[attacker] [verb_used]s you!"),
		span_hear("You hear a sickening sound of flesh hitting flesh!"),
		COMBAT_MESSAGE_RANGE,
		attacker,
	)
	to_chat(attacker, span_danger("You [verb_used] [defender]!"))
	playsound(defender, sound, 40, TRUE, -1)
	defender.apply_damage(damage, damage_type || attacker.get_attack_type(), affecting, sharpness = sharpness)
	log_combat(attacker, defender, "[verb_used] ([name])")

/datum/martial_art/wuxia/harm_act(mob/living/attacker, mob/living/defender)
	var/verb_used = pick(punch_verbs)
	var/damage = rand(punch_low, punch_high) + bonus_damage(attacker)
	if(defender.check_block(attacker, damage, "[attacker]'s [verb_used]", UNARMED_ATTACK))
		return MARTIAL_ATTACK_FAIL
	add_to_streak("H", defender)
	if(check_streak(attacker, defender))
		return MARTIAL_ATTACK_SUCCESS
	strike(attacker, defender, damage, verb_used)
	after_punch(attacker, defender)
	return MARTIAL_ATTACK_SUCCESS

/datum/martial_art/wuxia/disarm_act(mob/living/attacker, mob/living/defender)
	if(defender.check_block(attacker, 0, attacker.name, UNARMED_ATTACK))
		return MARTIAL_ATTACK_FAIL
	add_to_streak("D", defender)
	if(check_streak(attacker, defender))
		return MARTIAL_ATTACK_SUCCESS
	return MARTIAL_ATTACK_INVALID

/datum/martial_art/wuxia/grab_act(mob/living/attacker, mob/living/defender)
	if(defender.check_block(attacker, 0, "[attacker]'s grab", UNARMED_ATTACK))
		return MARTIAL_ATTACK_FAIL
	add_to_streak("G", defender)
	if(check_streak(attacker, defender))
		return MARTIAL_ATTACK_SUCCESS
	return MARTIAL_ATTACK_INVALID

/// Extra damage on plain punches
/datum/martial_art/wuxia/proc/bonus_damage(mob/living/attacker)
	return 0

/datum/martial_art/wuxia/proc/after_punch(mob/living/attacker, mob/living/defender)
	return

// ===================== Drunken Fist =====================

/datum/martial_art/wuxia/drunken_fist
	name = "Drunken Fist"
	id = "drunken_fist"
	help_verb = /mob/living/proc/drunken_fist_help
	punch_verbs = list("wobble-punch", "stagger-strike", "lurch into", "hiccup-jab")
	combos = list(
		"HDD" = "staggering_lotus",
		"DH" = "immortal_offers_wine",
		"GH" = "drunken_embrace",
	)

/datum/martial_art/wuxia/drunken_fist/on_teach(mob/living/new_holder)
	. = ..()
	RegisterSignal(new_holder, COMSIG_LIVING_CHECK_BLOCK, "sway")

/datum/martial_art/wuxia/drunken_fist/on_remove(mob/living/remove_from)
	UnregisterSignal(remove_from, COMSIG_LIVING_CHECK_BLOCK)
	return ..()

/// 0 sober, up to 3 properly sloshed
/datum/martial_art/wuxia/drunken_fist/proc/drunkenness(mob/living/attacker)
	var/drunk = attacker.get_drunk_amount()
	if(drunk >= 60)
		return 3
	if(drunk >= 30)
		return 2
	if(drunk >= 10)
		return 1
	return 0

/datum/martial_art/wuxia/drunken_fist/bonus_damage(mob/living/attacker)
	return drunkenness(attacker) * 3

/// The drunker you are, the harder you are to hit
/datum/martial_art/wuxia/drunken_fist/proc/sway(mob/living/source, atom/hit_by, damage, attack_text, attack_type, armour_penetration, damage_type)
	SIGNAL_HANDLER
	if(!source.combat_mode || source.incapacitated || !(attack_type in list(MELEE_ATTACK, UNARMED_ATTACK, THROWN_PROJECTILE_ATTACK)))
		return NONE
	var/level = drunkenness(source)
	if(!level || !prob(10 + level * 10))
		return NONE
	source.visible_message(span_warning("[source] sways drunkenly out of the way of [attack_text]!"), span_notice("You wobble aside from [attack_text]. *hic*"))
	cultivation_afterimage(source, 0.3 SECONDS)
	return SUCCESSFUL_BLOCK

/datum/martial_art/wuxia/drunken_fist/perform_combo(combo_name, mob/living/attacker, mob/living/defender)
	switch(combo_name)
		if("staggering_lotus")
			staggering_lotus(attacker, defender)
		if("immortal_offers_wine")
			immortal_offers_wine(attacker, defender)
		if("drunken_embrace")
			drunken_embrace(attacker, defender)

/datum/martial_art/wuxia/drunken_fist/proc/staggering_lotus(mob/living/attacker, mob/living/defender)
	attacker.emote("spin")
	strike(attacker, defender, 6 + drunkenness(attacker) * 3, "sweeps the legs out from under", ATTACK_EFFECT_KICK, sound = 'sound/effects/hit_kick.ogg')
	defender.Knockdown(2 SECONDS)
	defender.adjust_staggered_up_to(STAGGERED_SLOWDOWN_LENGTH, 10 SECONDS)
	attacker.say("Staggering Lotus Sweep! *hic*", forced = "drunken fist")

/datum/martial_art/wuxia/drunken_fist/proc/immortal_offers_wine(mob/living/attacker, mob/living/defender)
	var/level = drunkenness(attacker)
	strike(attacker, defender, 14 + level * 5, "delivers a spinning uppercut to", sound = 'sound/items/weapons/punch4.ogg')
	defender.throw_at(get_edge_target_turf(defender, get_dir(attacker, defender)), 1 + level, 2, attacker)
	new /obj/effect/temp_visual/kinetic_blast(get_turf(defender))
	attacker.say("The Drunken Immortal Offers Wine!", forced = "drunken fist")

/datum/martial_art/wuxia/drunken_fist/proc/drunken_embrace(mob/living/attacker, mob/living/defender)
	attacker.visible_message(span_danger("[attacker] throws a sloppy arm around [defender] and headbutts [defender.p_them()]!"))
	strike(attacker, defender, 8, "headbutts", sound = 'sound/items/weapons/punch2.ogg')
	defender.adjust_confusion_up_to(6 SECONDS, 10 SECONDS)
	defender.adjust_dizzy_up_to(6 SECONDS, 10 SECONDS)
	attacker.adjust_dizzy_up_to(2 SECONDS, 10 SECONDS)

/mob/living/proc/drunken_fist_help()
	set name = "Recall Teachings"
	set desc = "Remember the techniques of the Drunken Fist."
	set category = "Drunken Fist"
	to_chat(usr, boxed_message("<b><i>You take a swig and remember the way of the Drunken Immortals...</i></b><br>\
		[span_notice("Your style gets stronger the drunker you are")]: more punch damage, and in combat mode you may sway out of the way of melee and thrown attacks.<br>\
		[span_notice("Staggering Lotus Sweep")]: Punch, Shove, Shove. Knock them down and leave them staggering.<br>\
		[span_notice("The Drunken Immortal Offers Wine")]: Shove, Punch. A huge uppercut that launches them further the drunker you are.<br>\
		[span_notice("Drunken Embrace")]: Grab, Punch. A sloppy headbutt that leaves them confused and dizzy (and you a little dizzy too)."))

// ===================== Eagle Claw =====================

/datum/martial_art/wuxia/eagle_claw
	name = "Eagle Claw"
	id = "eagle_claw"
	help_verb = /mob/living/proc/eagle_claw_help
	punch_low = 9
	punch_high = 13
	punch_verbs = list("claws", "rakes", "tears at")
	combos = list(
		"HHH" = "claw_rake",
		"GH" = "eagle_seizes_prey",
		"DG" = "joint_lock",
	)

/datum/martial_art/wuxia/eagle_claw/perform_combo(combo_name, mob/living/attacker, mob/living/defender)
	switch(combo_name)
		if("claw_rake")
			claw_rake(attacker, defender)
		if("eagle_seizes_prey")
			eagle_seizes_prey(attacker, defender)
		if("joint_lock")
			joint_lock(attacker, defender)

/datum/martial_art/wuxia/eagle_claw/proc/claw_rake(mob/living/attacker, mob/living/defender)
	strike(attacker, defender, 18, "rakes deep furrows across", ATTACK_EFFECT_CLAW, BRUTE, SHARP_EDGED, 'sound/items/weapons/slash.ogg')
	new /obj/effect/temp_visual/slash(get_turf(defender), defender, rand(10, 22), rand(10, 22), "#ffffff")
	attacker.say("Eagle Claw Rake!", forced = "eagle claw")

/datum/martial_art/wuxia/eagle_claw/proc/eagle_seizes_prey(mob/living/attacker, mob/living/defender)
	attacker.do_attack_animation(defender, ATTACK_EFFECT_CLAW)
	defender.visible_message(span_danger("[attacker] seizes [defender] like an eagle snatching prey!"), span_userdanger("[attacker]'s fingers dig into your pressure points!"))
	defender.apply_damage(35, STAMINA)
	defender.drop_all_held_items()
	playsound(defender, 'sound/items/weapons/cqchit1.ogg', 50, TRUE)
	log_combat(attacker, defender, "seized prey (Eagle Claw)")

/datum/martial_art/wuxia/eagle_claw/proc/joint_lock(mob/living/attacker, mob/living/defender)
	if(!iscarbon(defender))
		return
	var/mob/living/carbon/victim = defender
	attacker.do_attack_animation(victim, ATTACK_EFFECT_DISARM)
	victim.visible_message(span_danger("[attacker] twists [victim]'s arm into a painful joint lock!"), span_userdanger("Your arm is locked and goes numb!"))
	playsound(victim, 'sound/effects/wounds/crack1.ogg', 40, TRUE)
	var/obj/item/held = victim.get_active_held_item()
	if(held)
		victim.dropItemToGround(held)
	var/trait = (victim.active_hand_index % 2) ? TRAIT_PARALYSIS_L_ARM : TRAIT_PARALYSIS_R_ARM
	ADD_TRAIT(victim, trait, "eagle_claw")
	addtimer(TRAIT_CALLBACK_REMOVE(victim, trait, "eagle_claw"), 5 SECONDS)
	victim.apply_damage(15, BRUTE, victim.get_active_hand()?.body_zone || BODY_ZONE_CHEST)
	log_combat(attacker, victim, "joint locked (Eagle Claw)")

/mob/living/proc/eagle_claw_help()
	set name = "Recall Teachings"
	set desc = "Remember the techniques of the Eagle Claw."
	set category = "Eagle Claw"
	to_chat(usr, boxed_message("<b><i>You flex your fingers like talons...</i></b><br>\
		[span_notice("Your punches are claws")] and hit a little harder than normal.<br>\
		[span_notice("Eagle Claw Rake")]: Punch, Punch, Punch. A deep, bleeding slash.<br>\
		[span_notice("Eagle Seizes Prey")]: Grab, Punch. Dig into their pressure points: heavy stamina damage and they drop everything.<br>\
		[span_notice("Joint Lock")]: Shove, Grab. Twist their arm: they drop what's in their active hand and the arm goes numb for a few seconds."))

// ===================== Wing Chun =====================

/datum/martial_art/wuxia/wing_chun
	name = "Wing Chun"
	id = "wing_chun"
	help_verb = /mob/living/proc/wing_chun_help
	punch_low = 6
	punch_high = 9
	punch_verbs = list("jabs", "chain-punches", "straight-punches")
	combos = list(
		"HHHH" = "chain_punch_flurry",
		"DD" = "sticky_hands",
		"HD" = "centerline_strike",
	)
	/// world.time until which Sticky Hands deflects the next melee attack
	var/sticky_until = 0

/datum/martial_art/wuxia/wing_chun/on_teach(mob/living/new_holder)
	. = ..()
	RegisterSignal(new_holder, COMSIG_LIVING_CHECK_BLOCK, "deflect")

/datum/martial_art/wuxia/wing_chun/on_remove(mob/living/remove_from)
	UnregisterSignal(remove_from, COMSIG_LIVING_CHECK_BLOCK)
	return ..()

/// Wing Chun punches come fast
/datum/martial_art/wuxia/wing_chun/after_punch(mob/living/attacker, mob/living/defender)
	attacker.changeNext_move(CLICK_CD_MELEE * 0.6)

/datum/martial_art/wuxia/wing_chun/perform_combo(combo_name, mob/living/attacker, mob/living/defender)
	switch(combo_name)
		if("chain_punch_flurry")
			chain_punch_flurry(attacker, defender)
		if("sticky_hands")
			sticky_hands(attacker, defender)
		if("centerline_strike")
			centerline_strike(attacker, defender)

/datum/martial_art/wuxia/wing_chun/proc/chain_punch_flurry(mob/living/attacker, mob/living/defender)
	attacker.say("Chain punch!", forced = "wing chun")
	for(var/i in 0 to 3)
		addtimer(CALLBACK(src, "flurry_hit", attacker, defender), i * 0.15 SECONDS)

/datum/martial_art/wuxia/wing_chun/proc/flurry_hit(mob/living/attacker, mob/living/defender)
	if(QDELETED(attacker) || QDELETED(defender) || !attacker.Adjacent(defender) || attacker.incapacitated)
		return
	strike(attacker, defender, 5, "chain-punches", sound = pick('sound/items/weapons/punch1.ogg', 'sound/items/weapons/punch2.ogg', 'sound/items/weapons/punch3.ogg'))
	defender.apply_damage(8, STAMINA)

/datum/martial_art/wuxia/wing_chun/proc/sticky_hands(mob/living/attacker, mob/living/defender)
	sticky_until = world.time + 5 SECONDS
	attacker.visible_message(span_notice("[attacker] raises [attacker.p_their()] hands into a flowing guard, sticking to [defender]'s arms."), span_notice("Sticky hands: you'll deflect the next blow."))
	attacker.add_filter("sticky_hands", 2, list("type" = "outline", "color" = "#d8f4ff", "size" = 1))
	addtimer(CALLBACK(attacker, TYPE_PROC_REF(/datum, remove_filter), "sticky_hands"), 5 SECONDS)

/datum/martial_art/wuxia/wing_chun/proc/deflect(mob/living/source, atom/hit_by, damage, attack_text, attack_type, armour_penetration, damage_type)
	SIGNAL_HANDLER
	if(world.time > sticky_until || !(attack_type in list(MELEE_ATTACK, UNARMED_ATTACK)))
		return NONE
	sticky_until = 0
	source.remove_filter("sticky_hands")
	source.visible_message(span_warning("[source] redirects [attack_text] with a flick of the wrist!"))
	playsound(source, 'sound/items/weapons/parry.ogg', 50, TRUE)
	return SUCCESSFUL_BLOCK

/datum/martial_art/wuxia/wing_chun/proc/centerline_strike(mob/living/attacker, mob/living/defender)
	strike(attacker, defender, 10, "drives a straight punch into the centerline of", sound = 'sound/items/weapons/punch4.ogg')
	defender.apply_damage(30, STAMINA)
	if(defender.getStaminaLoss() >= 50)
		defender.Knockdown(1.5 SECONDS)
	new /obj/effect/temp_visual/kinetic_blast(get_turf(defender))

/mob/living/proc/wing_chun_help()
	set name = "Recall Teachings"
	set desc = "Remember the techniques of Wing Chun."
	set category = "Wing Chun"
	to_chat(usr, boxed_message("<b><i>You settle into a centred stance...</i></b><br>\
		[span_notice("Your punches are light but very fast")].<br>\
		[span_notice("Chain Punch Flurry")]: Punch x4. A rapid burst of four extra punches that also tire them out.<br>\
		[span_notice("Sticky Hands")]: Shove, Shove. For 5 seconds the next melee attack against you is deflected.<br>\
		[span_notice("Centerline Strike")]: Punch, Shove. Heavy stamina damage, knocks down anyone already worn out."))

// ===================== Manuals =====================

/obj/item/book/granter/martial/wuxia
	name = "martial arts manual"
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'
	icon_state = "manual"
	remarks = list(
		"Lower your stance. Lower. LOWER.",
		"The master says to strike like the wind. The diagrams show a man falling over.",
		"Your body is the weapon. Your mind is the hand that holds it.",
		"Practice this form ten thousand times before breakfast.",
	)

/obj/item/book/granter/martial/wuxia/drunken_fist
	name = "Drunken Fist manual"
	desc = "A wine-stained manual of the Drunken Fist. Several pages are stuck together."
	color = "#e6b4a0"
	martial = /datum/martial_art/wuxia/drunken_fist
	martial_name = "the Drunken Fist"
	greet = "<span class='sciradio'>You have learned the Drunken Fist. Use Recall Teachings in the Drunken Fist tab. Best enjoyed responsibly.</span>"

/obj/item/book/granter/martial/wuxia/eagle_claw
	name = "Eagle Claw manual"
	desc = "A manual of the Eagle Claw, its margins full of angry talon sketches."
	color = "#c8b28a"
	martial = /datum/martial_art/wuxia/eagle_claw
	martial_name = "the Eagle Claw"
	greet = "<span class='sciradio'>You have learned the Eagle Claw. Use Recall Teachings in the Eagle Claw tab.</span>"

/obj/item/book/granter/martial/wuxia/wing_chun
	name = "Wing Chun manual"
	desc = "A slim, practical manual of Wing Chun. Someone has written 'chain punch!!' on every page."
	color = "#b4c8e6"
	martial = /datum/martial_art/wuxia/wing_chun
	martial_name = "Wing Chun"
	greet = "<span class='sciradio'>You have learned Wing Chun. Use Recall Teachings in the Wing Chun tab.</span>"

/obj/effect/spawner/random/wuxia_manual
	name = "random martial arts manual"
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'
	icon_state = "manual"
	loot = list(
		/obj/item/book/granter/martial/wuxia/drunken_fist,
		/obj/item/book/granter/martial/wuxia/eagle_claw,
		/obj/item/book/granter/martial/wuxia/wing_chun,
	)
