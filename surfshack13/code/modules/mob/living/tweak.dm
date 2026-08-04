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

GLOBAL_VAR_INIT(hyper_adrenaline_next_round, FALSE)
GLOBAL_VAR_INIT(hyper_adrenaline_active, FALSE)
GLOBAL_DATUM_INIT(hyper_adrenaline_controller, /datum/hyper_adrenaline_controller, new)

/proc/hyper_adrenaline_is_active()
	return GLOB.hyper_adrenaline_active

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

	var/damage_multiplier_already_hyper = CONFIG_GET(number/damage_multiplier) >= HYPER_ADRENALINE_DAMAGE_MULTIPLIER_THRESHOLD
	GLOB.hyper_adrenaline_active = GLOB.hyper_adrenaline_next_round || damage_multiplier_already_hyper
	if(!GLOB.hyper_adrenaline_active)
		return

	if(!damage_multiplier_already_hyper)
		CONFIG_SET(number/damage_multiplier, CONFIG_GET(number/damage_multiplier) * HYPER_ADRENALINE_DAMAGE_MULTIPLIER)
	INVOKE_ASYNC(src, PROC_REF(apply_current_item_throwforce))

	to_chat(world, span_notice("<b>Hyper Adrenaline is active for this round.</b>"), confidential = TRUE)
	message_admins(span_adminnotice("Hyper Adrenaline was enabled at round start."))

/datum/hyper_adrenaline_controller/proc/apply_current_item_throwforce()
	for(var/obj/item/item in world)
		CHECK_TICK
		if(!(item.flags_1 & INITIALIZED_1) || QDELETED(item))
			continue
		item.apply_hyper_adrenaline_throwforce()

/datum/hyper_adrenaline_controller/proc/on_atom_post_init(datum/source, atom/created_atom)
	SIGNAL_HANDLER

	if(istype(created_atom, /area))
		RegisterSignal(created_atom, COMSIG_AREA_INTERNAL_EXPLOSION, PROC_REF(on_area_internal_explosion))
		return

	if(!hyper_adrenaline_is_active() || !isitem(created_atom))
		return

	var/obj/item/created_item = created_atom
	created_item.apply_hyper_adrenaline_throwforce()

/datum/hyper_adrenaline_controller/proc/on_area_internal_explosion(datum/source, list/arguments)
	SIGNAL_HANDLER

	if(!hyper_adrenaline_is_active())
		return

	arguments[EXARG_KEY_DEV_RANGE] *= HYPER_ADRENALINE_EXPLOSION_MULTIPLIER
	arguments[EXARG_KEY_HEAVY_RANGE] *= HYPER_ADRENALINE_EXPLOSION_MULTIPLIER
	arguments[EXARG_KEY_LIGHT_RANGE] *= HYPER_ADRENALINE_EXPLOSION_MULTIPLIER

	if(!isnull(arguments[EXARG_KEY_FLAME_RANGE]))
		arguments[EXARG_KEY_FLAME_RANGE] *= HYPER_ADRENALINE_EXPLOSION_MULTIPLIER

	if(!isnull(arguments[EXARG_KEY_FLASH_RANGE]))
		arguments[EXARG_KEY_FLASH_RANGE] *= HYPER_ADRENALINE_EXPLOSION_MULTIPLIER

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
