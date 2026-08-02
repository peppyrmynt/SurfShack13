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
// Admins select the mode during startup or pregame. The selection is copied
// into the active state at COMSIG_TICKER_ROUND_STARTING and is then immutable.
GLOBAL_VAR_INIT(hyper_adrenaline_next_round, FALSE)
GLOBAL_VAR_INIT(hyper_adrenaline_active, FALSE)
GLOBAL_DATUM_INIT(hyper_adrenaline_controller, /datum/hyper_adrenaline_controller, new)

/obj/item/var/hyper_adrenaline_throwforce_scaled = FALSE

/obj/item/proc/apply_hyper_adrenaline_throwforce()
	if(hyper_adrenaline_throwforce_scaled)
		return
	throwforce *= 2
	hyper_adrenaline_throwforce_scaled = TRUE

/datum/hyper_adrenaline_controller
	var/round_effects_applied = FALSE

/datum/hyper_adrenaline_controller/New()
	. = ..()
	RegisterSignal(SSticker, COMSIG_TICKER_ROUND_STARTING, PROC_REF(on_round_start))
	RegisterSignal(SSdcs, COMSIG_GLOB_ATOM_AFTER_POST_INIT, PROC_REF(on_atom_post_init))

/datum/hyper_adrenaline_controller/proc/on_round_start(datum/source, round_start_time)
	SIGNAL_HANDLER

	if(round_effects_applied)
		return
	round_effects_applied = TRUE

	GLOB.hyper_adrenaline_active = GLOB.hyper_adrenaline_next_round
	if(!GLOB.hyper_adrenaline_active)
		return

	CONFIG_SET(number/damage_multiplier, CONFIG_GET(number/damage_multiplier) * 2)

	for(var/obj/item/item in world)
		item.apply_hyper_adrenaline_throwforce()

	to_chat(world, span_notice("<b>Hyper Adrenaline is active for this round.</b>"), confidential = TRUE)
	message_admins(span_adminnotice("Hyper Adrenaline was enabled at round start."))

/datum/hyper_adrenaline_controller/proc/on_atom_post_init(datum/source, atom/created_atom)
	SIGNAL_HANDLER

	if(!GLOB.hyper_adrenaline_active || !isitem(created_atom))
		return
	var/obj/item/created_item = created_atom
	created_item.apply_hyper_adrenaline_throwforce()

ADMIN_VERB(toggle_hyper_adrenaline, R_SERVER, "Toggle Hyper Adrenaline", "Enable or disable Hyper Adrenaline for the upcoming round.", ADMIN_CATEGORY_SERVER)
	if(SSticker.current_state > GAME_STATE_PREGAME)
		to_chat(user, span_warning("Hyper Adrenaline is locked for the current round and can only be selected before round start."))
		return

	GLOB.hyper_adrenaline_next_round = !GLOB.hyper_adrenaline_next_round
	var/state_text = GLOB.hyper_adrenaline_next_round ? "enabled" : "disabled"

	log_admin("[key_name(user)] [state_text] Hyper Adrenaline for the upcoming round.")
	message_admins(span_adminnotice("[key_name_admin(user)] has [state_text] Hyper Adrenaline for the upcoming round."))
	to_chat(world, span_notice("<b>Hyper Adrenaline has been [state_text] for the upcoming round.</b>"), confidential = TRUE)
	SSblackbox.record_feedback("nested tally", "admin_toggle", 1, list("Toggle Hyper Adrenaline", GLOB.hyper_adrenaline_next_round ? "Enabled" : "Disabled"))

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
