/mob/living/basic/flood
	name = "Flood combat form"
	desc = "A biomass-driven combat form belonging to a parasitic hive mind."
	icon = 'icons/mob/flood/flood_combat_human.dmi'
	icon_state = "nudist"
	icon_living = "nudist"
	icon_dead = "nudist_dead"
	mob_biotypes = MOB_ORGANIC | MOB_HUMANOID
	basic_mob_flags = FLAMMABLE_MOB
	sentience_type = SENTIENCE_HUMANOID
	initial_language_holder = /datum/language_holder/flood
	faction = list("Flood")
	combat_mode = TRUE
	see_in_dark = 5
	habitable_atmos = null
	unsuitable_atmos_damage = 0
	minimum_survivable_temperature = 0
	maximum_survivable_temperature = NPC_DEFAULT_MAX_TEMP
	fire_stack_decay_rate = -0.5
	maxHealth = 125
	health = 125
	melee_damage_lower = 20
	melee_damage_upper = 30
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	attack_sound = 'sound/flood/melee.melee1.ogg'
	attacked_sound = 'sound/flood/pain.pain1.ogg'
	death_message = "collapses into a twitching mass of biomass."
	obj_damage = 60
	damage_coeff = list(BRUTE = 1, BURN = 1.5, TOX = 1, STAMINA = 0, OXY = 1)
	ai_controller = /datum/ai_controller/basic_controller/simple_hostile_obstacles/flood
	var/next_evolution = 0
	var/next_idle_sound = 0

/mob/living/basic/flood/Initialize(mapload)
	. = ..()
	if(stat != DEAD && world.time < GLOB.flood_overseer_replacement_at)
		apply_status_effect(/datum/status_effect/flood_overseer_loss, GLOB.flood_overseer_replacement_at - world.time)
	RegisterSignal(src, COMSIG_MOB_MIND_TRANSFERRED_INTO, PROC_REF(on_flood_mind_transfer))
	// Infection forms remain AI-controlled; other AI forms can join the ghost spawners menu.
	if(!istype(src, /mob/living/basic/flood/infestor))
		AddComponent(/datum/component/ghost_direct_control, ban_type = ROLE_FLOOD, poll_candidates = FALSE)
	grant_actions_by_list(get_flood_actions())
	attacked_sound = pick(
		'sound/flood/pain.pain1.ogg',
		'sound/flood/pain.pain2.ogg',
		'sound/flood/pain.pain5.ogg',
		'sound/flood/pain.pain3.ogg',
		'sound/flood/pain.pain6.ogg',
		'sound/flood/pain.pain15.ogg',
	)
	next_idle_sound = world.time + rand(300, 600)

/mob/living/basic/flood/mind_initialize()
	. = ..()
	grant_flood_antag()

/mob/living/basic/flood/Login()
	. = ..()
	for(var/mob/eye/flood_overseer/eye as anything in GLOB.flood_overseer_eyes)
		if(eye.flood_marker)
			client?.images += eye.flood_marker
	for(var/obj/effect/countdown/flood_growth/countdown as anything in GLOB.flood_growth_countdowns)
		if(countdown.flood_display)
			client?.images += countdown.flood_display

/mob/living/basic/flood/Logout()
	for(var/mob/eye/flood_overseer/eye as anything in GLOB.flood_overseer_eyes)
		if(eye.flood_marker)
			client?.images -= eye.flood_marker
	for(var/obj/effect/countdown/flood_growth/countdown as anything in GLOB.flood_growth_countdowns)
		if(countdown.flood_display)
			client?.images -= countdown.flood_display
	return ..()

/mob/living/basic/flood/proc/on_flood_mind_transfer(mob/living/basic/flood/source, mob/living/old_body)
	SIGNAL_HANDLER
	grant_flood_antag()

/// Any mind taking control of a Flood body joins the Flood, including manual possession.
/mob/living/basic/flood/proc/grant_flood_antag()
	var/datum/mind/flood_mind = mind
	if(!flood_mind || flood_mind.has_antag_datum(/datum/antagonist/flood))
		return
	if(flood_mind.add_antag_datum(/datum/antagonist/flood))
		flood_mind.special_role = ROLE_FLOOD

/mob/living/basic/flood/proc/get_flood_actions()
	return list(/datum/action/cooldown/flood/chorus)

/mob/living/basic/flood/get_fire_overlay(stacks, on_fire)
	var/fire_icon = "human_[(stat == DEAD || stacks <= MOB_BIG_FIRE_STACK_THRESHOLD) ? "small_fire" : "big_fire"]"
	if(!GLOB.fire_appearances[fire_icon])
		GLOB.fire_appearances[fire_icon] = mutable_appearance(
			'icons/mob/effects/onfire.dmi',
			fire_icon,
			-HIGHEST_LAYER,
			appearance_flags = RESET_COLOR,
		)
	return GLOB.fire_appearances[fire_icon]

/mob/living/basic/flood/fire_act()
	. = ..()
	if(stat != DEAD)
		adjustFireLoss(2)

/mob/living/basic/flood/melee_attack(atom/target, list/modifiers, ignore_cooldown)
	if(istype(src, /mob/living/basic/flood/infestor))
		attack_sound = pick(
			'sound/flood/leap.leap1.ogg',
			'sound/flood/leap.leap2.ogg',
			'sound/flood/leap.leap5.ogg',
			'sound/flood/leap.leap11.ogg',
			'sound/flood/leap.leap15.ogg',
		)
	else
		attack_sound = pick(
			'sound/flood/melee.melee1.ogg',
			'sound/flood/melee.melee2.ogg',
			'sound/flood/melee.melee5.ogg',
			'sound/flood/melee.melee7.ogg',
			'sound/flood/melee.melee6.ogg',
			'sound/flood/melee.melee8.ogg',
			'sound/flood/melee.melee10.ogg',
			'sound/flood/melee.melee11.ogg',
			'sound/flood/melee.melee15.ogg',
			'sound/flood/melee.melee20.ogg',
		)
	return ..()

/mob/living/basic/flood/proc/flood_chorus()
	if(stat == DEAD || !mind?.has_antag_datum(/datum/antagonist/flood))
		return
	if(world.time < GLOB.flood_overseer_replacement_at)
		to_chat(src, span_warning("The hive is in shock. Flood Chorus returns when the overseer death penalty ends."))
		return
	var/message = tgui_input_text(src, "Speak to the Flood chorus.", "Flood Chorus", max_length = MAX_MESSAGE_LEN)
	if(!message || stat == DEAD || world.time < GLOB.flood_overseer_replacement_at || !mind?.has_antag_datum(/datum/antagonist/flood))
		return
	if(client?.prefs.muted & MUTE_IC)
		to_chat(src, span_warning("You cannot send IC messages while muted."))
		return
	if(client?.handle_spam_prevention(message, MUTE_IC))
		return
	var/list/filter_result = CAN_BYPASS_FILTER(src) ? null : is_ic_filtered(message)
	if(filter_result)
		REPORT_CHAT_FILTER_TO_USER(src, filter_result)
		return
	var/list/soft_filter_result = CAN_BYPASS_FILTER(src) ? null : is_soft_ic_filtered(message)
	if(soft_filter_result)
		if(tgui_alert(src, "Your message contains \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\". [soft_filter_result[CHAT_FILTER_INDEX_REASON]]", "Soft Blocked Word", list("Yes", "No")) != "Yes")
			return
		message_admins("[ADMIN_LOOKUPFLW(src)] passed the soft filter for Flood Chorus: [html_encode(message)]")
	if(stat == DEAD || world.time < GLOB.flood_overseer_replacement_at || !mind?.has_antag_datum(/datum/antagonist/flood))
		return
	message = trim(copytext_char(sanitize(message), 1, MAX_MESSAGE_LEN))
	if(!message)
		return
	var/rendered_message = span_notice("<b>Flood Chorus — [name]:</b> [message]")
	for(var/datum/antagonist/flood/other_flood in GLOB.antagonists)
		var/mob/living/basic/flood/recipient = other_flood.owner?.current
		if(istype(recipient) && recipient.stat != DEAD)
			to_chat(recipient, rendered_message)
	log_talk(message, LOG_SAY, tag = "Flood Chorus")
