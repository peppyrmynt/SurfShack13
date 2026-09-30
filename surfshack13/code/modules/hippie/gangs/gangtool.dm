// Gangtool: the gang leadership's shop, messenger and shuttle recaller.

/obj/item/gangtool
	name = "suspicious device"
	desc = "A strange device of sorts. Hard to really make out what it actually does if you don't know how to operate it."
	icon = 'surfshack13/icons/hippie/gang_items.dmi'
	icon_state = "gangtool"
	inhand_icon_state = "radio"
	lefthand_file = 'icons/mob/inhands/items/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/devices_righthand.dmi'
	throwforce = 0
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 3
	throw_range = 7
	obj_flags = CONDUCTS_ELECTRICITY
	/// Which gang this is registered to
	var/datum/team/gang/gang
	/// Whether a recall is in progress
	var/recalling = FALSE
	/// The next recruitment pen from this tool is free
	var/free_pen = FALSE
	/// Registering this tool promotes a gangster to lieutenant
	var/promotable = FALSE
	/// category = list(id = /datum/gang_item)
	var/list/buyable_items = list()
	/// Which shop items this tool sells (GANG_MODE_* flag)
	var/mode_flag = GANG_MODE_GANGS
	/// What the shop's currency is called
	var/currency_name = "Influence"

/obj/item/gangtool/Initialize(mapload)
	. = ..()
	for(var/datum/gang_item/item_type as anything in subtypesof(/datum/gang_item))
		var/id = initial(item_type.id)
		if(!id || !(initial(item_type.mode_flags) & mode_flag))
			continue
		var/category = initial(item_type.category)
		LAZYINITLIST(buyable_items[category])
		buyable_items[category][id] = new item_type()
	update_appearance()

/obj/item/gangtool/Destroy()
	gang?.gangtools -= src
	gang = null
	for(var/category in buyable_items)
		QDEL_LIST_ASSOC_VAL(buyable_items[category])
	buyable_items.Cut()
	return ..()

/obj/item/gangtool/update_overlays()
	. = ..()
	var/mutable_appearance/light = mutable_appearance(icon, "[icon_state]-overlay")
	if(gang)
		light.color = gang.color
	. += light

/obj/item/gangtool/attack_self(mob/user, modifiers)
	. = ..()
	if(.)
		return
	if(!can_use(user))
		return TRUE
	show_menu(user)
	return TRUE

/// Opens the gangtool window
/obj/item/gangtool/proc/show_menu(mob/user)
	ui_interact(user)

// Gangtools can live in pockets, bags or nullspace (personal tools), so access is decided by can_use()
/obj/item/gangtool/ui_state(mob/user)
	return GLOB.always_state

/obj/item/gangtool/ui_status(mob/user, datum/ui_state/state)
	return can_use(user, silent = TRUE) ? UI_INTERACTIVE : UI_CLOSE

/obj/item/gangtool/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Gangtool")
		ui.open()

/obj/item/gangtool/ui_data(mob/user)
	var/list/data = list()
	var/datum/antagonist/gang/member = user.mind?.has_antag_datum(/datum/antagonist/gang)
	data["vigilante"] = FALSE
	data["title"] = "GangTool v4.0"
	data["registered"] = !!gang
	data["is_leader"] = istype(member, /datum/antagonist/gang/boss)
	data["promotable"] = promotable
	data["positions_open"] = member ? length(member.gang.leaders) < member.gang.max_leaders : FALSE
	data["points"] = get_points()
	data["currency"] = currency_name
	if(gang)
		data["gang_name"] = gang.name
		data["gang_color"] = gang.color
		data["members"] = length(gang.members)
		data["territories"] = length(gang.territories)
		data["control"] = gang.station_control_percent()
		data["next_payout"] = max(0, round((gang.next_point_time - world.time) / 10))
		data["dominating"] = gang.domination_time != GANG_NOT_DOMINATING
		data["dom_time_left"] = max(0, gang.domination_time_remaining())
		data["dom_attempts"] = gang.dom_attempts
		data["recalls"] = gang.recalls
	data["categories"] = shop_data(user)
	return data

/// The shop listing, shared by every gangtool type
/obj/item/gangtool/proc/shop_data(mob/user)
	var/list/categories = list()
	for(var/category in buyable_items)
		var/list/items = list()
		for(var/id in buyable_items[category])
			var/datum/gang_item/item = buyable_items[category][id]
			if(!item.can_see(user, gang, src))
				continue
			var/atom/shown = item.get_icon_type(gang)
			items += list(list(
				"id" = id,
				"name" = item.get_name_display(user, gang, src),
				"cost" = item.get_cost_display(user, gang, src),
				"desc" = item.get_description(user, gang, src),
				"icon" = shown ? initial(shown.icon) : null,
				"icon_state" = shown ? initial(shown.icon_state) : null,
				"can_buy" = item.can_buy(user, gang, src),
			))
		if(length(items))
			categories += list(list("name" = category, "items" = items))
	return categories

/obj/item/gangtool/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/user = usr
	if(!can_use(user))
		return
	add_fingerprint(user)
	switch(action)
		if("buy")
			var/list/category = buyable_items[params["category"]]
			var/datum/gang_item/item = category?[params["id"]]
			if(gang && item?.can_buy(user, gang, src))
				INVOKE_ASYNC(item, TYPE_PROC_REF(/datum/gang_item, purchase), user, gang, src)
			return TRUE
		if("register")
			register_device(user)
			return TRUE
		if("message")
			if(gang)
				INVOKE_ASYNC(src, PROC_REF(ping_gang), user)
			return TRUE
		if("recall")
			if(gang)
				recall(user)
			return TRUE

/// Currency available to spend in this tool's shop
/obj/item/gangtool/proc/get_points()
	return gang?.influence || 0

/obj/item/gangtool/proc/spend_points(amount)
	gang?.adjust_influence(-amount)

/// The mob currently carrying this tool, if any
/obj/item/gangtool/proc/get_holder()
	return get(loc, /mob/living)

/// Sends a gang-wide message
/obj/item/gangtool/proc/ping_gang(mob/user)
	var/message = tgui_input_text(user, "Discreetly send a gang-wide message.", "Send Message", max_length = MAX_MESSAGE_LEN)
	if(!message || !can_use(user))
		return
	if(!is_station_level(user.z))
		to_chat(user, span_info("[icon2html(src, user)]Error: Station out of range."))
		return
	var/datum/antagonist/gang/sender = user.mind.has_antag_datum(/datum/antagonist/gang)
	if(!sender)
		return
	var/ping = span_danger("<b><i>[gang.name] [sender.message_name] [user.real_name]</i>: [message]</b>")
	for(var/datum/mind/gangster as anything in gang.members)
		if(gangster.current && is_station_level(gangster.current.z) && gangster.current.stat == CONSCIOUS)
			to_chat(gangster.current, ping)
	for(var/mob/dead/observer/ghost in GLOB.dead_mob_list)
		to_chat(ghost, "[FOLLOW_LINK(ghost, user)] [ping]")
	user.log_talk(message, LOG_SAY, tag = "[gang.name] gangster")

/obj/item/gangtool/proc/register_device(mob/user)
	if(gang)
		return
	var/datum/antagonist/gang/member = user.mind?.has_antag_datum(/datum/antagonist/gang)
	if(!member)
		to_chat(user, span_warning("ACCESS DENIED: Unauthorized user."))
		return
	gang = member.gang
	gang.gangtools += src
	update_appearance()
	if(promotable && !(user.mind in gang.leaders))
		member.promote()
		free_pen = TRUE
		gang.message_gangtools("[user] has been promoted to Lieutenant.")
		to_chat(user, "The <b>Gangtool</b> you registered will allow you to purchase weapons and equipment, and send messages to your gang.")
		to_chat(user, "Unlike regular gangsters, you may use <b>recruitment pens</b> to add recruits to your gang. Use them on unsuspecting crew members to recruit them. Don't forget to get your one free pen from the gangtool.")

/obj/item/gangtool/proc/recall(mob/user)
	if(!recall_checks(user))
		return
	if(recalling)
		to_chat(user, span_warning("Error: Recall already in progress."))
		return
	gang.message_gangtools("[user] is attempting to recall the emergency shuttle.")
	recalling = TRUE
	to_chat(user, span_info("[icon2html(src, user)]Generating shuttle recall order with codes retrieved from last call signal..."))
	addtimer(CALLBACK(src, PROC_REF(recall_step), user, 1), rand(10 SECONDS, 30 SECONDS))

/obj/item/gangtool/proc/recall_step(mob/user, step)
	if(!recall_checks(user))
		recalling = FALSE
		return
	switch(step)
		if(1)
			to_chat(user, span_info("[icon2html(src, user)]Shuttle recall order generated. Accessing station long-range communication arrays..."))
		if(2)
			var/living_crew = 0
			for(var/mob/player as anything in GLOB.player_list)
				if(player.mind && player.stat != DEAD && isliving(player) && !isbrain(player))
					living_crew++
			if(living_crew / max(1, length(GLOB.joined_player_list)) <= 0.7) // Hippie read this ratio from config; Surf no longer has that entry
				to_chat(user, span_warning("[icon2html(src, user)]Error: Station communication systems compromised. Unable to establish connection."))
				recalling = FALSE
				return
			to_chat(user, span_info("[icon2html(src, user)]Comm arrays accessed. Broadcasting recall signal..."))
		if(3)
			recalling = FALSE
			log_game("[key_name(user)] has tried to recall the shuttle with a gangtool.")
			message_admins("[ADMIN_LOOKUPFLW(user)] has tried to recall the shuttle with a gangtool.")
			if(SSshuttle.cancelEvac(user))
				gang.recalls--
			else
				to_chat(user, span_info("[icon2html(src, user)]No response received. Emergency shuttle cannot be recalled at this time."))
			return
	addtimer(CALLBACK(src, PROC_REF(recall_step), user, step + 1), rand(10 SECONDS, 30 SECONDS))

/obj/item/gangtool/proc/recall_checks(mob/user)
	if(!can_use(user) || SSshuttle.emergency_no_recall)
		return FALSE
	if(!gang.recalls || !gang.dom_attempts)
		to_chat(user, span_warning("Error: Unable to access communication arrays. Firewall has logged our signature and is blocking all further attempts."))
		return FALSE
	if(SSshuttle.emergency.mode != SHUTTLE_CALL)
		to_chat(user, span_warning("[icon2html(src, user)]Emergency shuttle cannot be recalled at this time."))
		return FALSE
	if(!is_station_level(user.z))
		to_chat(user, span_warning("[icon2html(src, user)]Error: Device out of range of station communication arrays."))
		return FALSE
	return TRUE

/// Whether this user can operate the tool. silent skips the chat feedback (used when the window polls it).
/obj/item/gangtool/proc/can_use(mob/living/carbon/human/user, silent = FALSE)
	if(!istype(user) || user.incapacitated || !user.mind || !(src in user.get_all_contents()))
		return FALSE
	var/datum/antagonist/gang/member = user.mind.has_antag_datum(/datum/antagonist/gang)
	if(!member)
		if(!silent)
			to_chat(user, span_notice("Huh, what's this?"))
		return FALSE
	if(gang && member.gang != gang)
		if(!silent)
			to_chat(user, span_danger("You cannot use gang tools owned by enemy gangs!"))
		return FALSE
	return TRUE

/// Spare gangtools bought from the shop
/obj/item/gangtool/spare

/// Spares that promote whoever registers them
/obj/item/gangtool/spare/lieutenant
	promotable = TRUE
