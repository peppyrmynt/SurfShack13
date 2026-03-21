#define CREW_ANNOUNCE_COOLDOWN (11 MINUTES)
#define ANNOUNCE_COST 900

/obj/machinery/computer/public_announcement
	name = "Public Announcements console"
	desc = "A commerical announcement console, with built in transmitters."
	icon_screen = "civ_bounty"
	icon_keyboard = "tech_key"
	circuit = /obj/item/circuitboard/computer/public_announcement

	STATIC_COOLDOWN_DECLARE(crew_announce_cooldown)
	/// how long crew messages can be
	var/static/max_length = round(MAX_MESSAGE_LEN/2)
	/// If someone is actively using the console
	var/in_use = FALSE


/obj/machinery/computer/public_announcement/examine(mob/user)
	. = ..()
	. += "It cost [ANNOUNCE_COST] credits to fire."

/obj/machinery/computer/public_announcement/Initialize(mapload)
	. = ..()
	REGISTER_REQUIRED_MAP_ITEM(1, INFINITY)
	// stop roundstart spam. cooldown should always have a value so only runs if this isnt set.
	if(!crew_announce_cooldown)
		crew_announce_cooldown = CREW_ANNOUNCE_COOLDOWN / 2

/obj/machinery/computer/public_announcement/emag_act(mob/user, obj/item/card/emag/emag_card)
	if(!is_operational || obj_flags & EMAGGED)
		return
	say("Breaker circuit offline.")
	do_sparks(2, source=src)
	obj_flags |= EMAGGED

/obj/machinery/computer/public_announcement/interact(mob/living/user)
	. = ..()
	if(!is_operational || in_use || !iscarbon(user))
		return

	var/turf/current_turf = get_turf(src)
	var/zlevel = current_turf.z
	if(!is_station_level(zlevel))
		return

	if(!COOLDOWN_FINISHED(src, crew_announce_cooldown))
		var/cooldown_left = COOLDOWN_TIMELEFT(src, crew_announce_cooldown)
		cooldown_left = ceil(cooldown_left / (1 MINUTES))
		say("The transmitter is charging. [cooldown_left] minute[cooldown_left ? "s" : ""] left.")
		return

	if(obj_flags & EMAGGED)
		overload_transmitters(user)
		return


	in_use = TRUE
	var/input = tgui_input_text(user, "Costs [ANNOUNCE_COST] credits", "Announcement", max_length = max_length)
	if(!input || !user.can_perform_action(src))
		in_use = FALSE
		return
	if(user.try_speak(input))
		//Adds slurs and so on. Someone should make this use languages too.
		var/list/input_data = user.treat_message(input)
		input = input_data["message"]
	else
		//No cheating, mime/random mute guy!
		input = "..."
		user.visible_message(
			span_notice("[user] holds down [src]'s announcement button, leaving the mic on in awkward silence."),
			span_notice("You leave the mic on in awkward silence..."),
			span_hear("You hear an awkward silence, somehow."),
			vision_distance = 4,
			)
	to_chat(user, span_notice("You manually tab through several EULA's and the payment prompt... (This will take a few seconds.)"))
	if(do_after(user, 8 SECONDS, src) && pay_for_announcement(user))
		minor_announce(input, "Crew Announcement:", players = GLOB.player_list)
		deadchat_broadcast(" made a announcement from [span_name("[get_area_name(user, TRUE)]")].", span_name("[user.real_name]"), user, message_type=DEADCHAT_ANNOUNCEMENT)
		COOLDOWN_START(src, crew_announce_cooldown, CREW_ANNOUNCE_COOLDOWN)
	in_use = FALSE


/obj/machinery/computer/public_announcement/proc/pay_for_announcement(mob/living/user)
	var/datum/bank_account/account
	var/obj/item/card/id/id_card = user.get_idcard(TRUE)
	if(!istype(id_card))
		say("No ID card detected.")
		return FALSE
	if(IS_DEPARTMENTAL_CARD(id_card))
		say("The [src] rejects [id_card].")
		return FALSE
	account = id_card.registered_account
	if(!istype(account))
		say("Invalid bank account.")
		return FALSE
	if(!account.has_money(ANNOUNCE_COST))
		say("Not enough credits. Requires [ANNOUNCE_COST] credits.")
		return FALSE
	if(account.adjust_money(-1 * ANNOUNCE_COST, "Purchased announcement"))
		return TRUE


/obj/machinery/computer/public_announcement/proc/overload_transmitters(mob/user)
	say("ERR: Transmitter overloaded.")
	var/turf/T = get_turf(src)
	if(T)
		T.hotspot_expose(700,125)
	explosion(src, devastation_range = -1, heavy_impact_range = 1, light_impact_range = 3, flash_range = 4)
	Destroy()
#undef ANNOUNCE_COST
#undef CREW_ANNOUNCE_COOLDOWN
