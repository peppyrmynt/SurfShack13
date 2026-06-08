/obj/item/gun/ballistic/shotgun/automatic/combat/kammerer
	name = "\improper Kammerer"
	desc = "A semi-automatic shotgun with a four-shell capacity. Often favored over compact shotguns for their slightly better performance."
	fire_delay = 2
	inhand_x_dimension = 32
	inhand_y_dimension = 32
	icon = 'surfshack13/icons/obj/weapons/guns/ballistic.dmi'
	icon_state = "Kammerer"
	inhand_icon_state = "kammerer"
	lefthand_file = 'surfshack13/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'surfshack13/icons/mob/inhands/weapons/guns_righthand.dmi'
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/shot/kammerer
	w_class = WEIGHT_CLASS_HUGE
	worn_icon = 'surfshack13/icons/mob/clothing/back.dmi'
	worn_icon_state = "Kammerer"

/obj/item/gun/ballistic/shotgun/automatic/combat/kammerer/nopin
	pin = null

/obj/item/gun/ballistic/shotgun/enforcer
	name = "\improper Enforcer"
	desc = "A semi-auto shotgun for combat in narrow corridors, originally conceived to compete against the syndicate's famous 'Bulldog'. Must be loaded with shells one-by-one for a maximum of 7 shells."
	icon = 'surfshack13/icons/obj/weapons/guns/ballistic.dmi'
	icon_state = "Enforcer"
	inhand_icon_state = "enforcer"
	lefthand_file = 'surfshack13/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'surfshack13/icons/mob/inhands/weapons/guns_righthand.dmi'
	w_class = WEIGHT_CLASS_HUGE
	weapon_weight = WEAPON_MEDIUM
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/shot/enforcer
	can_suppress = FALSE
	burst_size = 1
	fire_delay = 2
	inhand_x_dimension = 32
	inhand_y_dimension = 32
	pin = /obj/item/firing_pin
	actions_types = list()
	semi_auto = TRUE
	custom_price = 7500
	worn_icon = 'surfshack13/icons/mob/clothing/back.dmi'
	worn_icon_state = "Enforcer"

/obj/item/gun/ballistic/shotgun/enforcer/nopin
	pin = null
