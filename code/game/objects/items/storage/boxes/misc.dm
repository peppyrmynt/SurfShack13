/obj/item/storage/box/methdealer
	name = "box"
	desc = "A brown box."
	icon_state = "blank_package"

/obj/item/storage/box/methdealer/PopulateContents()
	var/static/list/items_inside = list(
		/obj/item/food/drug/meth_crystal = 4,
		/obj/item/cigarette/pipe/crackpipe = 2,
	)
	generate_items_inside(items_inside, src)

/obj/item/storage/box/opiumdealer
	name = "box"
	desc = "A brown box."
	icon_state = "blank_package"

/obj/item/storage/box/opiumdealer/PopulateContents()
	var/static/list/items_inside = list(
		/obj/item/food/drug/opium = 4,
		/obj/item/cigarette/pipe/cobpipe = 2,
	)
	generate_items_inside(items_inside, src)

/obj/item/storage/box/kronkdealer
	name = "box"
	desc = "A brown box."
	icon_state = "blank_package"

/obj/item/storage/box/kronkdealer/PopulateContents()
	var/static/list/items_inside = list(
		/obj/item/food/drug/moon_rock = 4,
		/obj/item/cigarette/pipe/crackpipe = 2,
	)
	generate_items_inside(items_inside, src)
