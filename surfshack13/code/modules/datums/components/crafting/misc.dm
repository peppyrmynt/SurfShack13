/datum/crafting_recipe/clown_prop
	crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_MUST_BE_LEARNED

/datum/crafting_recipe/clown_prop/spinning_banana
	name = "Spinning banana prop"
	result = /obj/item/clown_prop/spinning_banana
	time = 2 SECONDS
	reqs = list(
		/obj/item/stack/cable_coil = 15,
		/obj/item/food/grown/banana = 1,
		/obj/item/stack/sheet/mineral/bananium = 3
	)
	category = CAT_MISC


/datum/mind/proc/teach_clown_prop_recipies()
	var/list/clown_props = 	subtypesof(/datum/crafting_recipe/clown_prop/)
	if(!learned_recipes)
		learned_recipes = list()
	learned_recipes |= clown_props
