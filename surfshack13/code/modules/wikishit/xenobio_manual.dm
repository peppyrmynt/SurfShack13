/obj/item/holomanual
	name = "Holo Manual"
	desc = "A holographic manual. A rather dense reference manual made of refined hardlight. It's about the size of playing card."
	icon = 'icons/obj/service/bureaucracy.dmi'
	icon_state ="alienpaper_words"
	w_class = WEIGHT_CLASS_TINY
	throw_range = 1
	throw_speed = 1
	throwforce = 0
	max_integrity = 100
	interaction_flags_click = NEED_DEXTERITY|ALLOW_RESTING
	interaction_flags_atom = INTERACT_ATOM_UI_INTERACT
	/// the complete html for the manual.
	var/static/ui

/obj/item/holomanual/examine(mob/user)
	. = ..()
	. += span_notice("It fits in a wallet. There's a library terminal print mark on the back.")

/obj/item/holomanual/xenobiology
	name = "Xenobiology Manual"

/obj/item/holomanual/xenobiology/ui_interact(mob/user)
	if(!ui)
		ui = 'surfshack13/frogui/slime_manual.html'
	SSfrogui.open_ui(user, src, ui, "size=433x450;", ui_flags = FROG_UI_NO_TOPIC)
