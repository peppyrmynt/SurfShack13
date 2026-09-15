/obj/item/card/weapon_permit
	name = "weapon permit"
	desc = "A small card, that when used on any ID, will add weapon permit access. Self-destructs when used."
	icon = 'surfshack13/icons/obj/card.dmi'
	icon_state = "idsec"

/obj/item/card/weapon_permit/interact_with_atom(atom/interacting_with, mob/user, proximity)
	. = ..()
	if(istype(interacting_with, /obj/item/card/id) && proximity)
		var/obj/item/card/id/I = interacting_with
		I.access |=	ACCESS_WEAPONS
		to_chat(user, "You upgrade [I] with weapon permit access.")
		qdel(src)
