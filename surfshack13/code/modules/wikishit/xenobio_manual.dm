/obj/item/holomanual
	name = "Holo Manual"
	desc = "A holographic manual."
	icon = 'icons/obj/service/bureaucracy.dmi'
	icon_state ="alienpaper_words"
	w_class = WEIGHT_CLASS_TINY
	throw_range = 1
	throw_speed = 1
	throwforce = 0
	max_integrity = 100
	interaction_flags_click = NEED_DEXTERITY|NEED_HANDS|ALLOW_RESTING
	interaction_flags_atom = INTERACT_ATOM_UI_INTERACT
	/// the complete html for the manual.
	var/static/ui

/obj/item/holomanual/xenobiology
	name = "Slime holo manual"

/obj/item/holomanual/xenobiology/ui_interact(mob/user)
	if(!ui)
		ui = 'surfshack13/frogui/slime_manual.html'
	SSfrogui.open_ui(user, src, ui, "size=433x450;")
