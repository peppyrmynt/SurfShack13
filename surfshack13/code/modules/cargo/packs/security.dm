/datum/supply_pack/security/armory/pepperball
	name = "Pepperball Crate"
	desc = "Contains three Pepperball Guns, spare magazines, and 'special purpose' masks, firing precise balls filled with pepperspray capable of non-lethally incapacitating people."
	cost = CARGO_CRATE_VALUE * 7
	contains = list(
		/obj/item/gun/ballistic/automatic/paintball/pepper = 3,
		/obj/item/ammo_box/magazine/paintball/pepper = 3,
		/obj/item/clothing/mask/gas/paintball/red = 3,
	)
	crate_name = "pepperball crate"
	crate_type = /obj/structure/closet/crate/secure/weapon
