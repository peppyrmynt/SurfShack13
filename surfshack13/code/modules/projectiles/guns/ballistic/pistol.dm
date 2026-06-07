/obj/item/gun/ballistic/automatic/pistol/mk58
	name = "\improper Mk58"
	desc = "A classic .38 handgun with a small magazine capacity."
	icon = 'surfshack13/icons/obj/weapons/guns/ballistic.dmi'
	icon_state = "Mk58"
	inhand_icon_state = "mk58"
	lefthand_file = 'surfshack13/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'surfshack13/icons/mob/inhands/weapons/guns_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	accepted_magazine_type = /obj/item/ammo_box/magazine/v38
	mag_display = TRUE
	can_suppress = FALSE
	bolt_type = BOLT_TYPE_LOCKING
	fire_sound = 'surfshack13/sound/weapons/mk58.ogg'
	custom_price = 2500
	worn_icon = 'surfshack13/icons/mob/clothing/belt.dmi'

/obj/item/gun/ballistic/automatic/pistol/mk58/Initialize(mapload) // this is a security pistol, not contraband.
	. = ..()
	ADD_TRAIT(src, TRAIT_CONTRABAND_EXCEPTION, INNATE_TRAIT)

/obj/item/gun/ballistic/automatic/pistol/mk58/nopin
	pin = null

/obj/item/gun/ballistic/automatic/pistol/mk58/no_mag
	spawnwithmagazine = FALSE

/obj/item/gun/ballistic/automatic/pistol/mk58/rubber
	spawn_magazine_type = /obj/item/ammo_box/magazine/v38/rubber

/obj/item/gun/ballistic/automatic/pistol/mk58/freshprint
	spawnwithmagazine = FALSE
	pin = null
