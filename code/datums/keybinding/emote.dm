/datum/keybinding/emote
	category = CATEGORY_EMOTE
	weight = WEIGHT_EMOTE
	keybind_signal = COMSIG_KB_EMOTE
	var/emote_key

/datum/keybinding/emote/proc/link_to_emote(datum/emote/faketype)
	hotkey_keys = list("Unbound")
	classic_keys = list("Unbound")
	emote_key = initial(faketype.key)
	name = initial(faketype.key)
	full_name = capitalize(initial(faketype.key))

/datum/keybinding/emote/down(client/user)
	. = ..()
	if(.)
		return
	return user.mob.emote(emote_key, intentional=TRUE)

/datum/keybinding/living/emote_wheel
	hotkey_keys = list("AltE")
	classic_keys = list("AltE")
	name = "emote_wheel"
	full_name = "Emote Wheel"
	description = "Open the image emote wheel (7TV emotes and laugh_k). Press again to close."
	category = CATEGORY_EMOTE
	keybind_signal = COMSIG_KB_EMOTE_WHEEL

/datum/keybinding/living/emote_wheel/down(client/user, from_macro = FALSE)
	. = ..()
	if(.)
		return
	// Explicit macros own this shortcut; the generic Any-key handler must not toggle it again.
	if(length(user.emote_wheel_macros) && !from_macro)
		return TRUE
	if(world.time < user.next_emote_wheel_press)
		return TRUE
	user.next_emote_wheel_press = world.time + 0.25 SECONDS
	var/mob/living/living_user = user.mob
	INVOKE_ASYNC(living_user, TYPE_VERB_REF(/mob/living, emote_wheel))
	return TRUE
