/datum/emote_panel
	var/list/blacklisted_emotes = list("me", "help")

/datum/emote_panel/ui_static_data(mob/user)
	var/list/data = list()

	var/list/emotes = list()
	var/list/keys = list()

	for(var/key in GLOB.emote_list)
		for(var/datum/emote/emote in GLOB.emote_list[key])
			if(emote.key in keys)
				continue
			if(emote.key in blacklisted_emotes)
				continue
			if(emote.can_run_emote(user, status_check = FALSE, intentional = FALSE))
				keys += emote.key
				emotes += list(list(
					"key" = emote.key,
					"name" = emote.name,
					"hands" = emote.hands_use_check,
					"visible" = emote.emote_type & EMOTE_VISIBLE,
					"audible" = emote.emote_type & EMOTE_AUDIBLE,
					"sound" = !isnull(emote.get_sound(user)),
					"use_params" = emote.message_param,
				))

	data["emotes"] = emotes

	return data

/datum/emote_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("play_emote")
			var/emote_key = params["emote_key"]
			if(isnull(emote_key) || !GLOB.emote_list[emote_key])
				return
			var/use_params = params["use_params"]
			var/datum/emote/emote = GLOB.emote_list[emote_key][1]
			var/emote_param
			if(emote.message_param && use_params)
				emote_param = tgui_input_text(ui.user, "Add params to the emote...", emote.message_param, max_length = MAX_MESSAGE_LEN)
			ui.user.emote(emote_key, message = emote_param, intentional = TRUE)

/datum/emote_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "EmotePanel")
		ui.open()

/datum/emote_panel/ui_state(mob/user)
	return GLOB.always_state

/mob/living/verb/emote_panel()
	set name = "Emote Panel"
	set category = "IC"

	var/static/datum/emote_panel/emote_panel
	if(isnull(emote_panel))
		emote_panel = new
	emote_panel.ui_interact(src)

/// Image emotes remain in help and accept typed commands while the wheel is tested.
/mob/living/verb/emote_wheel()
	set name = "Emote Wheel"
	set category = "IC"

	if(!client)
		return
	var/client/opening_client = client
	var/list/options = list()
	for(var/key in GLOB.emote_wheel_choices)
		var/datum/emote/emote = GLOB.emote_wheel_emotes[key]
		if(emote.can_run_emote(src, status_check = FALSE, intentional = TRUE))
			options[key] = GLOB.emote_wheel_choices[key]

	var/compact = opening_client.prefs.read_preference(/datum/preference/toggle/compact_emote_wheel)
	var/selection = show_radial_menu(
		src, src, options,
		uniqueid = "emote_wheel_[REF(opening_client)]",
		radius = compact ? 80 : 160,
		custom_check = CALLBACK(src, PROC_REF(emote_wheel_available), opening_client),
		tooltips = TRUE,
		autopick_single_option = FALSE,
		entry_animation = TRUE,
		menu_type = compact ? /datum/radial_menu/emote_wheel/compact : /datum/radial_menu/emote_wheel,
	)
	if(selection && emote_wheel_available(opening_client) && (selection in options))
		emote(selection, intentional = TRUE)

/mob/living/proc/emote_wheel_available(client/opening_client)
	return !QDELETED(src) && client == opening_client && opening_client?.mob == src

/// All fourteen current emotes fit on one page; additional emotes can paginate normally.
/datum/radial_menu/emote_wheel
	min_angle = 22.5

/// Bible-style pagination: seven emotes and a next-page button.
/// Extra radius compared to the Bible leaves room for command labels.
/datum/radial_menu/emote_wheel/compact
	min_angle = 45

/datum/radial_menu/emote_wheel/SetElement(atom/movable/screen/radial/slice/element, choice_id, angle, anim, anim_order)
	. = ..()
	element.maptext_width = 80
	element.maptext_height = 14
	element.maptext_x = -24
	element.maptext_y = -14
	var/label = element.next_page ? "Next page" : "*[element.name]"
	element.maptext = "<div style='text-align:center;font-size:7px;color:white;background-color:#202020'>[html_encode(label)]</div>"

/// Explicit shortcuts also work while the chat input is focused (classic/non-hotkey mode).
/client/var/next_emote_wheel_press = 0
/client/var/list/emote_wheel_macros

/client/proc/update_emote_wheel_macros(datum/preferences/current_preferences)
	for(var/macro_id in emote_wheel_macros)
		winset(src, macro_id, "parent=null")
	emote_wheel_macros = list()
	for(var/key in current_preferences.key_bindings["emote_wheel"])
		if(key == "Unbound")
			continue
		var/macro_key = replacetext(replacetext(replacetext(key, "Alt", "Alt+"), "Ctrl", "Ctrl+"), "Shift", "Shift+")
		var/macro_id = "emote-wheel-[length(emote_wheel_macros) + 1]"
		winset(src, macro_id, "parent=default;name=[macro_key];command=open-emote-wheel")
		emote_wheel_macros += macro_id

/client/verb/open_emote_wheel()
	set name = "open-emote-wheel"
	set hidden = TRUE
	set instant = TRUE
	var/datum/keybinding/living/emote_wheel/binding = GLOB.keybindings_by_name["emote_wheel"]
	if(binding?.can_use(src))
		binding.down(src, from_macro = TRUE)

GLOBAL_LIST_EMPTY(emote_wheel_choices)
GLOBAL_LIST_EMPTY(emote_wheel_emotes)

/// Generate and cache the small static thumbnails before players open the wheel.
/proc/init_emote_wheel_choices()
	for(var/key in GLOB.emote_list)
		for(var/datum/emote/emote as anything in GLOB.emote_list[key])
			if(!istype(emote, /datum/emote/living/seventv) && !istype(emote, /datum/emote/living/carbon/human/laugh_king))
				continue
			if(GLOB.emote_wheel_choices[emote.key])
				continue
			var/icon/thumbnail
			if(istype(emote, /datum/emote/living/seventv))
				var/datum/emote/living/seventv/image_emote = emote
				thumbnail = icon(image_emote.emote_icon, image_emote.emote_icon_state, frame = 1)
			else
				thumbnail = icon('icons/hud/laugh_king.dmi', frame = 1)
			var/scale = min(32 / thumbnail.Width(), 32 / thumbnail.Height())
			var/width = max(1, round(thumbnail.Width() * scale))
			var/height = max(1, round(thumbnail.Height() * scale))
			thumbnail.Scale(width, height)
			var/offset_x = round((32 - width) / 2)
			var/offset_y = round((32 - height) / 2)
			thumbnail.Crop(1 - offset_x, 1 - offset_y, 32 - offset_x, 32 - offset_y)
			GLOB.emote_wheel_choices[emote.key] = image(thumbnail)
			GLOB.emote_wheel_emotes[emote.key] = emote

/datum/radial_menu/emote_wheel/Destroy()
	hide()
	QDEL_LIST(elements)
	QDEL_NULL(close_button)
	QDEL_NULL(menu_holder)
	return ..()
