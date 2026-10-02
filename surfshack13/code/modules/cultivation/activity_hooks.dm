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
		// Hard physical training tempers the body. The gym starts anyone on Copper Skin.
		if(amt > 0 && skill == /datum/skill/athletics)
			body_cultivation_train(current, 12, BODY_TRAINING_GYM, 20 SECONDS, can_start = TRUE)
		else if(amt > 0 && skill == /datum/skill/mining)
			body_cultivation_train(current, 8, BODY_TRAINING_MINING, 30 SECONDS)

/obj/machinery/hydroponics/update_tray(mob/user, product_count)
	. = ..()
	if(user)
		SEND_SIGNAL(user, COMSIG_MOB_CULTIVATION_HARVESTED, src)

/// Give a mob insight if it's a cultivator. For hooks that don't belong to any one law.
/proc/cultivation_insight(mob/living/user, amount, source, cooldown = 60 SECONDS)
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(user)
	return cultivator?.gain_insight(amount, source, cooldown, silent = TRUE)

/obj/item/book/display_content(mob/living/user)
	. = ..()
	cultivation_insight(user, 3, INSIGHT_SOURCE_READING, 3 MINUTES)

/datum/reagent/consumable/tea/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	. = ..()
	if(cultivation_insight(affected_mob, 2, INSIGHT_SOURCE_TEA, 2 MINUTES))
		to_chat(affected_mob, span_notice("<i>The tea clears your mind. A sip of the Dao.</i>"))

/datum/reagent/water/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	. = ..()
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(affected_mob)
	cultivator?.notify_laws(INSIGHT_SOURCE_DRINK_WATER, null)
