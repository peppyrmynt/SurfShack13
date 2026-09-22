//Gun crafting parts til they can be moved elsewhere

// PARTS //

/obj/item/weaponcrafting/Initialize(mapload)
	. = ..()
	create_slapcraft_component()

/obj/item/weaponcrafting/proc/create_slapcraft_component()
	return

/obj/item/weaponcrafting/receiver
	name = "modular receiver"
	desc = "A prototype modular receiver and trigger assembly for a firearm."
	icon = 'icons/obj/weapons/improvised.dmi'
	icon_state = "receiver"

/obj/item/weaponcrafting/receiver/create_slapcraft_component()
	var/static/list/slapcraft_recipe_list = list(/datum/crafting_recipe/pipegun)

	AddElement(
		/datum/element/slapcrafting,\
		slapcraft_recipes = slapcraft_recipe_list,\
	)

/obj/item/weaponcrafting/stock
	name = "rifle stock"
	desc = "A classic rifle stock that doubles as a grip, roughly carved out of wood."
	custom_materials = list(/datum/material/wood = SHEET_MATERIAL_AMOUNT * 6)
	resistance_flags = FLAMMABLE
	icon = 'icons/obj/weapons/improvised.dmi'
	icon_state = "riflestock"

