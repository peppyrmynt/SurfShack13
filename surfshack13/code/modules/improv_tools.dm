/obj/item/screwdriver/improvised
	name = "improvised screwdriver"
	desc = "A shoddily sharpened iron rod, made to work as a screwdriver. Or you could stab someone with it."
	icon = 'surfshack13/icons/improvtools.dmi'
	icon_state = "screwdriver_improv"
	toolspeed = 2.5
	custom_materials = list(/datum/material/iron=HALF_SHEET_MATERIAL_AMOUNT)
	random_color = FALSE

/obj/item/trash/broken_crowbar
	name = "oddly bent rod"
	desc = "In a past life, it may have been a crowbar. Now it is useless."
	icon = 'surfshack13/icons/improvtools.dmi'
	icon_state = "crowbar_improv_broken"

/obj/item/crowbar/improvised
	name = "improvised crowbar"
	desc = "Its a metal rod with a small hook made on the end."
	icon = 'surfshack13/icons/improvtools.dmi'
	icon_state = "crowbar_improv"
	toolspeed = 1.5
	/// How many more uses the crowbar has before it breaks
	var/durability = 10
	/// What object the tool should break into once its durability runs out
	var/broken_type = /obj/item/trash/broken_crowbar
	/// What sound should be played when the tool breaks
	var/break_sound = 'sound/items/handling/materials/metal_drop.ogg'

/obj/item/crowbar/improvised/use_tool(atom/target, mob/living/user, delay, amount, volume, datum/callback/extra_checks)
	. = ..()
	if(!durability)
		if(broken_type && user)
			new broken_type(user.loc)
		if(break_sound)
			playsound(src, break_sound, 40, TRUE)
		qdel(src)
	else
		durability -= 1

/obj/item/wirecutters/improvised
	name = "improvised wirecutters"
	desc = "It's just two sharp rods... that you use to snip things... I don't know what you expected."
	icon = 'surfshack13/icons/improvtools.dmi'
	icon_state = "cutters_improv"
	toolspeed = 3
	custom_materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT)
	random_color = FALSE

/obj/item/wrench/improvised
	name = "improvised wrench"
	desc = "A rather modestly built ghetto wrench. It looks like its just two iron rods welded together and shaped."
	icon = 'surfshack13/icons/improvtools.dmi'
	icon_state = "wrench_improv"
	toolspeed = 2
	custom_materials = list(/datum/material/iron=SHEET_MATERIAL_AMOUNT)

/obj/item/weldingtool/improvised
	name = "improvised welding tool"
	desc = "A weak welder made with a can, some beer, and a pipe. Once the beer is burning, you can't put it out. Use a screwdriver to put more beer in."
	icon = 'surfshack13/icons/improvtools.dmi'
	icon_state = "impwelder"
	inhand_icon_state = "impwelder"
	max_fuel = 10
	reagent_fuel = /datum/reagent/consumable/ethanol/beer
	custom_materials = list(/datum/material/iron=SHEET_MATERIAL_AMOUNT)
	activation_sound = 'sound/items/match_strike.ogg'
	deactivation_sound = 'sound/items/tools/wirecutter.ogg'
	can_disable = FALSE
	toolspeed = 2

/datum/crafting_recipe/welder_improv
	name = "Improvised Welding Tool"
	result = /obj/item/weldingtool/improvised
	time = 15 SECONDS
	tool_behaviors = list(TOOL_SCREWDRIVER)
	reqs = list(/obj/item/reagent_containers/cup/soda_cans = 1,
				/datum/reagent/consumable/ethanol/beer = 10,
				/obj/item/pipe/quaternary/pipe = 1,
				/obj/item/stock_parts/power_store/cell = 1,
				/obj/item/stack/cable_coil = 1)
	category = CAT_TOOLS

/datum/crafting_recipe/cutters_improv
	name = "Improvised Wirecutters"
	result = /obj/item/wirecutters/improvised
	time = 8 SECONDS
	reqs = list(/obj/item/screwdriver/improvised = 2)
	category = CAT_TOOLS

/datum/crafting_recipe/wrench_improv
	name = "Improvised Wrench"
	result = /obj/item/wrench/improvised
	time = 15 SECONDS
	tool_behaviors = list(TOOL_WELDER)
	reqs = list(/obj/item/stack/rods = 2)
	category = CAT_TOOLS

/datum/crafting_recipe/crowbar_improv
	name = "Improvised Crowbar"
	result = /obj/item/crowbar/improvised
	time = 10 SECONDS
	reqs = list(/obj/item/stack/rods = 1)
	category = CAT_TOOLS

/datum/crafting_recipe/screwdriver_improv
	name = "Improvised Screwdriver"
	result = /obj/item/screwdriver/improvised
	time = 5 SECONDS
	reqs = list(/obj/item/stack/rods = 1)
	category = CAT_TOOLS
