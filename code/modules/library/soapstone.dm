#define SACRED 25
#define WORSHIPPED 50

#define DELETE_AT -5
#define INF_LOOP -1
#define LOOP_OFFSET 1000

/obj/item/soapstone
	name = "soapstone"
	desc = "Leave informative messages for the crew, including the crew of future shifts!\nEven if out of uses, it can still be used to remove messages.\n(Not suitable for engraving on shuttles, off station or on cats. Side effects may include prompt beatings, psychotic clown incursions, and/or orbital bombardment.)"
	icon = 'icons/obj/art/artstuff.dmi'
	icon_state = "soapstone"
	throw_speed = 3
	throw_range = 5
	w_class = WEIGHT_CLASS_TINY
	var/tool_speed = 50
	var/remaining_uses = 3

/obj/item/soapstone/Initialize(mapload)
	. = ..()
	check_name()

/obj/item/soapstone/examine(mob/user)
	. = ..()
	if(remaining_uses != -1)
		. += "It has [remaining_uses] uses left."

/obj/item/soapstone/interact_with_atom(atom/target, mob/living/user, list/modifiers)
	. = ..()

	if(!good_chisel_message_location(target))
		to_chat(user, span_warning("It's not appropriate to engrave on [target]."))
		return

	var/obj/structure/chisel_message/existing_message = \
		istype(target, /obj/structure/chisel_message) ? target : locate() in target

	if(!remaining_uses && !existing_message)
		to_chat(user, span_warning("[src] is too worn out to use."))
		return

	if(existing_message)
		user.visible_message(span_notice("[user] starts erasing [existing_message]."), span_notice("You start erasing [existing_message]."), span_hear("You hear a chipping sound."))
		playsound(loc, 'sound/items/gavel.ogg', 50, TRUE, -1)
		if(do_after(user, tool_speed, target = existing_message))
			user.visible_message(span_notice("[user] erases [existing_message]."), span_notice("You erase [existing_message][existing_message.creator_key == user.ckey ? ", refunding a use" : ""]."))
			existing_message.persists = FALSE
			qdel(existing_message)
			playsound(loc, 'sound/items/gavel.ogg', 50, TRUE, -1)
			if(existing_message.creator_key == user.ckey)
				refund_use()
		return

	var/message = stripped_input(user, "What would you like to engrave?", "Leave a message")
	if(!message)
		to_chat(user, span_notice("You decide to not engrave anything."))
		return

	if(!target.Adjacent(user) && locate(/obj/structure/chisel_message) in target)
		to_chat(user, span_warning("Someone wrote here before you chose! Find another spot."))
		return
	playsound(loc, 'sound/items/gavel.ogg', 50, TRUE, -1)
	user.visible_message(span_notice("[user] starts engraving a message into [target]..."), span_notice("You start engraving a message into [target]..."), span_hear("You hear a chipping sound."))
	if(can_use() && do_after(user, tool_speed, target = target) && can_use())
		if(!locate(/obj/structure/chisel_message) in target)
			user.visible_message(span_notice("[user] leaves a message for future spacemen!"), span_notice("You engrave a message into [target]!"), span_hear("You hear a chipping sound."))
			playsound(loc, 'sound/items/gavel.ogg', 50, TRUE, -1)
			var/obj/structure/chisel_message/M = new(target)
			M.register(user, message)
			remove_use()

/obj/item/soapstone/proc/can_use()
	return remaining_uses == -1 || remaining_uses > 0

/obj/item/soapstone/proc/remove_use()
	if(remaining_uses <= 0)
		return
	remaining_uses--
	check_name()

/obj/item/soapstone/proc/refund_use()
	if(remaining_uses == -1)
		return
	remaining_uses++
	check_name()

/obj/item/soapstone/proc/check_name()
	if(remaining_uses)
		// This will mess up RPG loot names, but w/e
		name = initial(name)
	else
		name = "dull [initial(name)]"

/* Persistent engraved messages, etched onto the station turfs to serve
as instructions and/or memes for the next generation of spessmen.

Limited in location to station_z only. Can be smashed out or exploded,
but only permanently removed with the curator's soapstone.
*/

/obj/item/soapstone/infinite
	remaining_uses = -1

/obj/item/soapstone/empty
	remaining_uses = 0

/proc/good_chisel_message_location(target)
	return isfloorturf(target) || iswallturf(target) || istype(target, /obj/structure/chisel_message)

/obj/structure/chisel_message
	name = "engraved message"
	desc = "A message from a past traveler."
	icon = 'icons/obj/structures.dmi'
	icon_state = "soapstone_message"
	layer = LATTICE_LAYER
	density = FALSE
	anchored = TRUE
	max_integrity = 30

	var/hidden_message
	var/creator_key
	var/creator_name
	var/realdate
	var/map
	var/round_color
	var/persists = TRUE
	var/list/like_keys = list()
	var/list/dislike_keys = list()
	var/turf/original_turf

/obj/structure/chisel_message/Initialize(mapload)
	. = ..()
	SSpersistence.chisel_messages += src
	var/turf/target = get_turf(src)
	original_turf = target

	if(!good_chisel_message_location(target))
		persists = FALSE
		return INITIALIZE_HINT_QDEL

	if(like_keys.len - dislike_keys.len <= DELETE_AT)
		persists = FALSE
		return

	var/list/random_hsv = list(
		rand() * 360,
		100 - (rand() * 50),
		100 - (rand() * 30),
	)
	round_color = hsv2rgb(random_hsv)

/obj/structure/chisel_message/proc/register(mob/user, newmessage)
	hidden_message = newmessage
	creator_name = user.real_name
	creator_key = user.ckey
	realdate = world.realtime
	map = SSmapping.current_map.map_name
	update_appearance()
	update_filters()

/obj/structure/chisel_message/update_filters()
	. = ..()

	if (like_keys.len - dislike_keys.len >= WORSHIPPED && isnull(get_filter("soap_rays")))
		//1000 is the repeat...
		add_filter(name ="soap_rays",
			priority = 1,
			params = list(
				type = "rays",
				size = 40,
				density = 7,
				color = COLOR_SOAPSTONE_RAYS,
				threshold = 0.3,
				factor = 0.3,
			))
		animate(get_filter("soap_rays"), offset = LOOP_OFFSET, time = 1 HOURS, loop = INF_LOOP)

	if (like_keys.len - dislike_keys.len < WORSHIPPED && !isnull(get_filter("soap_rays")))
		remove_filter("soap_rays")


/obj/structure/chisel_message/update_icon()
	. = ..()

	var/new_color = round_color
	var/likeness = like_keys.len - dislike_keys.len
	if (likeness < 0)
		new_color = COLOR_SOAPSTONE_WANING
	else if (likeness >= SACRED)
		new_color = COLOR_SOAPSTONE_SACRED

	add_atom_colour("[new_color]", FIXED_COLOUR_PRIORITY)
	set_light(l_range = 2,
		l_power = 0.7,
		l_color = new_color,
		l_angle = 360,
		l_on = TRUE)

/obj/structure/chisel_message/update_name()
	var/likeness = like_keys.len - dislike_keys.len
	if (likeness < 0)
		name = "waning [initial(name)]"
	else if (likeness < SACRED)
		name = initial(name)
	else if (likeness >= SACRED && likeness < WORSHIPPED)
		name = "sacred [initial(name)]"
	else
		name = "worshipped [initial(name)]"

	return ..()

/obj/structure/chisel_message/proc/pack()
	var/list/data = list()
	data["hidden_message"] = hidden_message
	data["creator_name"] = creator_name
	data["creator_key"] = creator_key
	data["realdate"] = realdate
	data["map"] = SSmapping.current_map.map_name
	data["x"] = original_turf.x
	data["y"] = original_turf.y
	data["z"] = original_turf.z
	data["like_keys"] = like_keys
	data["dislike_keys"] = dislike_keys
	return data

/obj/structure/chisel_message/proc/unpack(list/data)
	if(!islist(data))
		return

	hidden_message = data["hidden_message"]
	creator_name = data["creator_name"]
	creator_key = data["creator_key"]
	realdate = data["realdate"]
	like_keys = data["like_keys"]
	if(!like_keys)
		like_keys = list()
	dislike_keys = data["dislike_keys"]
	if(!dislike_keys)
		dislike_keys = list()

	var/x = data["x"]
	var/y = data["y"]
	var/z = data["z"]
	var/turf/newloc = locate(x, y, z)
	if(isturf(newloc))
		forceMove(newloc)
	update_appearance()
	update_filters()

/obj/structure/chisel_message/examine(mob/user)
	. = ..()
	ui_interact(user)

/obj/structure/chisel_message/Destroy()
	if(persists)
		SSpersistence.save_chisel_message(src)
	SSpersistence.chisel_messages -= src
	return ..()

/obj/structure/chisel_message/interact()
	return

/obj/structure/chisel_message/ui_status(mob/user)
	if(isobserver(user)) // ignore proximity restrictions if we're an observer
		return UI_INTERACTIVE
	return ..()

/obj/structure/chisel_message/ui_state(mob/user)
	return GLOB.always_state

/obj/structure/chisel_message/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "EngravedMessage", name)
		ui.open()

/obj/structure/chisel_message/ui_data(mob/user)
	var/list/data = list()

	data["hidden_message"] = hidden_message
	data["realdate"] = ISOtime(realdate)
	data["num_likes"] = like_keys.len
	data["num_dislikes"] = dislike_keys.len
	data["is_creator"] = user.ckey == creator_key
	data["has_liked"] = (user.ckey in like_keys)
	data["has_disliked"] = (user.ckey in dislike_keys)

	if(check_rights_for(user.client, R_ADMIN))
		data["admin_mode"] = TRUE
		data["creator_key"] = creator_key
		data["creator_name"] = creator_name
	else
		data["admin_mode"] = FALSE
		data["creator_key"] = null
		data["creator_name"] = null

	return data

/obj/structure/chisel_message/ui_act(action, params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	var/mob/user = usr
	var/is_admin = check_rights_for(user.client, R_ADMIN)
	var/is_creator = user.ckey == creator_key
	var/has_liked = (user.ckey in like_keys)
	var/has_disliked = (user.ckey in dislike_keys)

	switch(action)
		if("like")
			if(is_creator)
				return
			if(has_disliked)
				dislike_keys -= user.ckey
			like_keys |= user.ckey
			. = TRUE
		if("dislike")
			if(is_creator)
				return
			if(has_liked)
				like_keys -= user.ckey
			dislike_keys |= user.ckey
			. = TRUE
		if("neutral")
			if(is_creator)
				return
			dislike_keys -= user.ckey
			like_keys -= user.ckey
			. = TRUE
		if("delete")
			if(!is_admin)
				return
			var/confirm = tgui_alert(user, "Confirm deletion of engraved message?", "Confirm Deletion", list("Yes", "No"))
			if(confirm == "Yes")
				persists = FALSE
				qdel(src)
				return

	update_appearance()
	update_filters()
	persists = like_keys.len - dislike_keys.len > DELETE_AT

#undef SACRED
#undef WORSHIPPED
#undef DELETE_AT
#undef INF_LOOP
#undef LOOP_OFFSET
