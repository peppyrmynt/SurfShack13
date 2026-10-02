// Modular hooks that tell a mob when it did something a cultivation law might find enlightening.
// Kept as thin overrides so no core files need editing.

/datum/component/personal_crafting/make_action(datum/crafting_recipe/recipe, mob/user)
	. = ..()
	if(. && ismob(user))
		SEND_SIGNAL(user, COMSIG_MOB_CULTIVATION_CRAFTED, recipe, null)

/atom/tool_act(mob/living/user, obj/item/tool, list/modifiers)
	. = ..()
	if((. & ITEM_INTERACT_SUCCESS) && user && tool)
		SEND_SIGNAL(user, COMSIG_MOB_CULTIVATION_TOOL_USED, src, tool)

/datum/mind/adjust_experience(skill, amt, silent = FALSE, force_old_level = 0)
	. = ..()
	if(current)
		SEND_SIGNAL(current, COMSIG_MOB_CULTIVATION_SKILL_EXP, skill, amt)

/obj/machinery/hydroponics/update_tray(mob/user, product_count)
	. = ..()
	if(user)
		SEND_SIGNAL(user, COMSIG_MOB_CULTIVATION_HARVESTED, src)
