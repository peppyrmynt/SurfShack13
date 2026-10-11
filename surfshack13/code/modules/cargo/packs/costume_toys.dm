/datum/supply_pack/costumes_toys/paintball
	name = "Paintball Crate"
	desc = "Laser Tag is for men. But paintball is for REAL MEN. \
		Contains 3 Red and Blue paintball guns, spare magazines, and masks."
	cost = CARGO_CRATE_VALUE * 4
	contains = list(
		/obj/item/gun/ballistic/automatic/paintball/red = 3,
		/obj/item/gun/ballistic/automatic/paintball/blue = 3,
		/obj/item/ammo_box/magazine/paintball/red = 3,
		/obj/item/ammo_box/magazine/paintball/blue = 3,
		/obj/item/clothing/mask/gas/paintball = 3,
		/obj/item/clothing/mask/gas/paintball/red = 3,
	)
	crate_name = "paintball crate"
