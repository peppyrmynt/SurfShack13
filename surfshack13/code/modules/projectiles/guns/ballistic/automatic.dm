// Lecter Automatic Rifle

/obj/item/gun/ballistic/automatic/lecter
	name = "\improper Lecter"
	desc = "A high end military grade assault rifle. Uses 5.56mm rifle ammo."
	icon = 'surfshack13/icons/obj/weapons/guns/ballistic.dmi'
	icon_state = "Lecter"
	inhand_icon_state = "lecter"
	lefthand_file = 'surfshack13/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'surfshack13/icons/mob/inhands/weapons/guns_righthand.dmi'
	accepted_magazine_type = /obj/item/ammo_box/magazine/r556
	fire_delay = 2
	burst_size = 2
	spread = 2
	w_class = WEIGHT_CLASS_HUGE
	slot_flags = ITEM_SLOT_BACK
	weapon_weight = WEAPON_MEDIUM
	mag_display = TRUE
	mag_display_ammo = FALSE
	empty_indicator = FALSE
	custom_price = 7500
	worn_icon = 'surfshack13/icons/mob/clothing/back.dmi'

/obj/item/gun/ballistic/automatic/lecter/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/automatic_fire, 0.4 SECONDS)

/obj/item/gun/ballistic/automatic/lecter/freshprint
	spawnwithmagazine = FALSE
	pin = null

// Drozd SMG

/obj/item/gun/ballistic/automatic/drozd
	name = "\improper Drozd"
	desc = "An excellent fully automatic Heavy SMG. Uses 5.56mm rifle ammo."
	icon = 'surfshack13/icons/obj/weapons/guns/ballistic.dmi'
	icon_state = "Drozd"
	inhand_icon_state = "drozd"
	lefthand_file = 'surfshack13/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'surfshack13/icons/mob/inhands/weapons/guns_righthand.dmi'
	accepted_magazine_type = /obj/item/ammo_box/magazine/r556
	fire_delay = 2
	burst_size = 3
	spread = 1
	w_class = WEIGHT_CLASS_HUGE
	slot_flags = ITEM_SLOT_BACK
	weapon_weight = WEAPON_MEDIUM
	mag_display = TRUE
	mag_display_ammo = FALSE
	empty_indicator = FALSE
	custom_price = 8000
	worn_icon = 'surfshack13/icons/mob/clothing/back.dmi'

/obj/item/gun/ballistic/automatic/drozd/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/automatic_fire, 0.3 SECONDS)

/obj/item/gun/ballistic/automatic/drozd/freshprint
	spawnwithmagazine = FALSE
	pin = null
