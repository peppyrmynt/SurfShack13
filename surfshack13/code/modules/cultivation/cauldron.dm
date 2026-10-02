/**
 * # Alchemy cauldron
 *
 * A bronze ding for refining pills properly. Heat it (a welder, Kindle, any fire, or a Fire cultivator's palm),
 * drop in herbs, then a cultivator pours in qi to refine them. Better pills than hand crafting, a chance of spirit-grade pills,
 * a few pills you can only make here, and a chance of blowing up in your face.
 *
 * Drop a bound artifact in with precious sheets instead and it gets tempered: a big boost to its refinement grade.
 */

#define CAULDRON_MAX_CONTENTS 8
#define CAULDRON_QI_COST 20

/obj/structure/alchemy_cauldron
	name = "alchemy cauldron"
	desc = "A three-legged bronze cauldron etched with the eight trigrams. Heat it, add herbs, and pour in your qi."
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'
	icon_state = "cauldron"
	density = TRUE
	anchored = FALSE
	max_integrity = 200
	pass_flags_self = PASSTABLE | LETPASSTHROW
	/// world.time until which the fire under it keeps burning
	var/heat_until = 0
	/// Someone is refining right now
	var/refining = FALSE
	/// Steam and embers while hot
	var/obj/effect/abstract/particle_holder/embers
	/// Every recipe, built once
	var/static/list/datum/cauldron_recipe/recipes
	/// Sheets that temper an artifact, and how much each one is worth
	var/static/list/tempering_materials = list(
		/obj/item/stack/sheet/mineral/silver = 1,
		/obj/item/stack/sheet/mineral/gold = 2,
		/obj/item/stack/sheet/mineral/plasma = 2,
		/obj/item/stack/sheet/mineral/diamond = 4,
		/obj/item/stack/sheet/bluespace_crystal = 4,
	)

/obj/structure/alchemy_cauldron/Initialize(mapload)
	. = ..()
	if(!recipes)
		recipes = list()
		for(var/recipe_type in subtypesof(/datum/cauldron_recipe))
			recipes += new recipe_type()

/obj/structure/alchemy_cauldron/Destroy()
	QDEL_NULL(embers)
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/alchemy_cauldron/examine(mob/user)
	. = ..()
	. += span_notice("It is [is_hot() ? "<b>hot</b>, a fire crackling underneath" : "cold"].")
	if(length(contents))
		var/list/names = list()
		for(var/atom/movable/thing as anything in contents)
			names += thing.name
		. += span_notice("Inside: [english_list(names)].")
	. += span_notice("Heat it with a welder or fire, add herbs (or a bound artifact and precious sheets), then a cultivator can refine. Alt-click to empty it.")

/obj/structure/alchemy_cauldron/update_icon_state()
	icon_state = is_hot() ? "cauldron_lit" : "cauldron"
	return ..()

/obj/structure/alchemy_cauldron/proc/is_hot()
	return world.time < heat_until

/obj/structure/alchemy_cauldron/proc/heat(duration = 3 MINUTES)
	var/was_hot = is_hot()
	heat_until = max(heat_until, world.time + duration)
	if(!was_hot)
		visible_message(span_notice("Flames lick up around [src]."))
		playsound(src, 'sound/effects/fire_puff.ogg', 40, TRUE)
		embers = cultivation_particles(src, /particles/cultivation/embers)
		set_light(2, 1, "#ff8a3c")
		START_PROCESSING(SSobj, src)
	update_appearance(UPDATE_ICON_STATE)

/obj/structure/alchemy_cauldron/process(seconds_per_tick)
	if(is_hot())
		return
	QDEL_NULL(embers)
	set_light(0)
	update_appearance(UPDATE_ICON_STATE)
	return PROCESS_KILL

/obj/structure/alchemy_cauldron/fire_act(exposed_temperature, exposed_volume)
	. = ..()
	heat()

/obj/structure/alchemy_cauldron/welder_act(mob/living/user, obj/item/tool)
	if(!tool.use_tool(src, user, 2 SECONDS, amount = 1, volume = 50))
		return ITEM_INTERACT_BLOCKING
	heat()
	return ITEM_INTERACT_SUCCESS

/obj/structure/alchemy_cauldron/proc/is_ingredient(obj/item/thing)
	if(istype(thing, /obj/item/food/grown) || istype(thing, /obj/item/food/meat/slab))
		return TRUE
	if(is_type_in_list(thing, tempering_materials))
		return TRUE
	return !!thing.GetComponent(/datum/component/cultivation_artifact)

/obj/structure/alchemy_cauldron/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!is_ingredient(tool))
		return NONE
	if(refining)
		balloon_alert(user, "busy refining!")
		return ITEM_INTERACT_BLOCKING
	if(length(contents) >= CAULDRON_MAX_CONTENTS)
		balloon_alert(user, "it's full!")
		return ITEM_INTERACT_BLOCKING
	if(!user.transferItemToLoc(tool, src))
		return ITEM_INTERACT_BLOCKING
	user.visible_message(span_notice("[user] drops [tool] into [src]."), span_notice("You drop [tool] into [src]."))
	playsound(src, 'sound/effects/bubbles/bubbles.ogg', 30, TRUE)
	return ITEM_INTERACT_SUCCESS

/obj/structure/alchemy_cauldron/click_alt(mob/user)
	if(refining || !length(contents))
		return CLICK_ACTION_BLOCKING
	for(var/atom/movable/thing as anything in contents)
		thing.forceMove(drop_location())
	to_chat(user, span_notice("You tip out [src]."))
	return CLICK_ACTION_SUCCESS

/obj/structure/alchemy_cauldron/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(user)
	if(!cultivator)
		to_chat(user, span_warning("You stir [src] with your hand. Nothing happens. Refining pills takes qi."))
		return TRUE
	if(!is_hot())
		if(cultivator.has_element(ELEMENT_FIRE) && cultivator.qi >= 10)
			cultivator.adjust_qi(-10)
			user.visible_message(span_notice("[user] presses a glowing palm to [src], and fire blooms beneath it."))
			heat()
			return TRUE
		to_chat(user, span_warning("[src] is cold. Light a fire under it first."))
		return TRUE
	if(refining)
		return TRUE
	if(!length(contents))
		to_chat(user, span_warning("[src] is empty."))
		return TRUE
	INVOKE_ASYNC(src, PROC_REF(refine), user, cultivator)
	return TRUE

/// What's in the pot right now: a recipe, artifact tempering, or nothing usable
/obj/structure/alchemy_cauldron/proc/find_recipe()
	var/datum/cauldron_recipe/best
	for(var/datum/cauldron_recipe/recipe as anything in recipes)
		if(recipe.matches(contents) && (!best || recipe.total_ingredients() > best.total_ingredients()))
			best = recipe
	return best

/obj/structure/alchemy_cauldron/proc/find_artifact()
	for(var/obj/item/thing in contents)
		var/datum/component/cultivation_artifact/bond = thing.GetComponent(/datum/component/cultivation_artifact)
		if(bond)
			return bond
	return null

/obj/structure/alchemy_cauldron/proc/refine(mob/living/user, datum/antagonist/cultivator/cultivator)
	var/datum/component/cultivation_artifact/artifact_bond = find_artifact()
	var/datum/cauldron_recipe/recipe = artifact_bond ? null : find_recipe()
	if(!artifact_bond && !recipe)
		to_chat(user, span_warning("These ingredients won't combine into anything."))
		return
	if(cultivator.qi < CAULDRON_QI_COST)
		to_chat(user, span_warning("You need [CAULDRON_QI_COST] qi to refine."))
		return
	refining = TRUE
	user.visible_message(span_notice("[user] places both palms on [src] and pours qi into it. The contents begin to churn and glow."), span_notice("You begin refining..."))
	var/obj/effect/abstract/particle_holder/steam = cultivation_particles(src, /particles/cultivation/steam)
	Shake(1, 1, 12 SECONDS)
	playsound(src, 'sound/effects/bubbles/bubbles2.ogg', 40, TRUE)
	var/finished = do_after(user, 12 SECONDS, src)
	QDEL_NULL(steam)
	refining = FALSE
	if(!finished || !is_hot() || cultivator.qi < CAULDRON_QI_COST)
		to_chat(user, span_warning("You lose control of the refining. The contents settle, unchanged."))
		return
	cultivator.adjust_qi(-CAULDRON_QI_COST)
	if(artifact_bond)
		temper(user, artifact_bond)
		return
	var/quality = 40 + 10 * cultivator.effective_realm() + rand(-25, 25) - round(cultivator.instability / 4)
	if(cultivator.has_element(ELEMENT_FIRE))
		quality += 15
	if(cultivator.has_element(ELEMENT_WOOD))
		quality += 10
	recipe.consume(contents)
	if(quality < 15)
		blow_up(user, cultivator)
		return
	var/spirit_grade = quality >= 85
	for(var/i in 1 to recipe.result_amount)
		var/obj/item/cultivation_pill/pill = new recipe.result(drop_location())
		if(spirit_grade)
			pill.make_spirit_grade()
	new /obj/effect/temp_visual/cultivation_spark(get_turf(src), spirit_grade ? "#ffffff" : null, 0, 10)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold(get_turf(src))
	playsound(src, 'sound/effects/magic/charge.ogg', 30, TRUE, frequency = 1.4)
	cultivation_guqin_phrase(src, spirit_grade ? list(1, 3, 5, 6) : list(3, 5), 0.12 SECONDS, 35)
	user.visible_message(span_notice("[src] gives a deep hum, and [recipe.result_amount > 1 ? "pills pop" : "a pill pops"] out of it[spirit_grade ? ", ringed with a halo of light" : ""]!"))
	if(spirit_grade)
		to_chat(user, span_boldnotice("A perfect refinement! Spirit-grade pills: stronger, and kinder to your meridians."))
	cultivator.gain_insight(3, "alchemy_general", cooldown = 2 MINUTES, silent = TRUE)
	cultivator.notify_laws(INSIGHT_SOURCE_ALCHEMY, src)
	jianghu_mission_progress(user.mind, SECT_MISSION_PILLS, recipe.result_amount)

/// Pour qi and precious metal into a bound artifact
/obj/structure/alchemy_cauldron/proc/temper(mob/living/user, datum/component/cultivation_artifact/bond)
	var/points = 0
	for(var/obj/item/stack/sheet/sheet in contents)
		var/value = tempering_materials[sheet.type]
		if(!value)
			continue
		var/used = min(sheet.amount, 5)
		points += value * used
		sheet.use(used)
	var/obj/item/artifact = bond.parent
	artifact.forceMove(drop_location())
	if(!points)
		to_chat(user, span_warning("Without precious metal to temper it, [artifact] only gets warm."))
		return
	bond.add_refinement(points, user)
	new /obj/effect/temp_visual/circle_wave/cultivation/fire(get_turf(src))
	playsound(src, 'sound/items/tools/welder.ogg', 40, TRUE)
	to_chat(user, span_notice("You temper [artifact] in the cauldron's fire. ([bond.refinement_grade_name()]-grade, [bond.refine_points]/[bond.points_for_next_grade()])"))
	jianghu_mission_progress(user.mind, SECT_MISSION_PILLS, 1)

/obj/structure/alchemy_cauldron/proc/blow_up(mob/living/user, datum/antagonist/cultivator/cultivator)
	visible_message(span_danger("[src] belches a cloud of black smoke and spits scalding sludge everywhere!"))
	playsound(src, 'sound/effects/smoke.ogg', 50, TRUE)
	var/datum/effect_system/fluid_spread/smoke/bad/smoke = new
	smoke.set_up(1, holder = src, location = get_turf(src))
	smoke.start()
	for(var/mob/living/victim in range(1, src))
		victim.apply_damage(10, BURN)
	cultivator.adjust_instability(10)
	to_chat(user, span_warning("Your qi backfires through the cauldron. The pills are ruined."))

/particles/cultivation/steam
	icon_state = "qi_mote"
	color = "#e8f0f0"
	spawning = 4
	velocity = list(0, 0.8)
	position = generator(GEN_BOX, list(-8, 8), list(8, 12), NORMAL_RAND)
	scale = generator(GEN_VECTOR, list(1, 1), list(2, 2), NORMAL_RAND)

/datum/crafting_recipe/alchemy_cauldron
	name = "Alchemy Cauldron"
	result = /obj/structure/alchemy_cauldron
	reqs = list(/obj/item/stack/sheet/iron = 10, /obj/item/stack/sheet/mineral/gold = 2)
	tool_behaviors = list(TOOL_WELDER)
	time = 10 SECONDS
	category = CAT_STRUCTURE

// ===================== Recipes =====================

/datum/cauldron_recipe
	/// Ingredient type -> how many
	var/list/reqs = list()
	var/obj/item/cultivation_pill/result
	var/result_amount = 1

/datum/cauldron_recipe/proc/total_ingredients()
	. = 0
	for(var/ingredient in reqs)
		. += reqs[ingredient]

/datum/cauldron_recipe/proc/matches(list/contents)
	for(var/ingredient in reqs)
		var/found = 0
		for(var/atom/movable/thing as anything in contents)
			if(istype(thing, ingredient))
				found++
		if(found < reqs[ingredient])
			return FALSE
	return TRUE

/datum/cauldron_recipe/proc/consume(list/contents)
	for(var/ingredient in reqs)
		var/needed = reqs[ingredient]
		for(var/atom/movable/thing as anything in contents.Copy())
			if(needed <= 0)
				break
			if(istype(thing, ingredient))
				qdel(thing)
				needed--

/datum/cauldron_recipe/qi_gathering
	reqs = list(/obj/item/food/grown/mushroom/reishi = 1, /obj/item/food/grown/herbs = 1)
	result = /obj/item/cultivation_pill/qi_gathering
	result_amount = 3

/datum/cauldron_recipe/foundation
	reqs = list(/obj/item/food/grown/mushroom/reishi = 2, /obj/item/food/grown/ambrosia = 1)
	result = /obj/item/cultivation_pill/foundation
	result_amount = 2

/datum/cauldron_recipe/tribulation
	reqs = list(/obj/item/food/grown/mushroom/reishi = 1, /obj/item/food/grown/galaxythistle = 1, /obj/item/food/grown/garlic = 1)
	result = /obj/item/cultivation_pill/tribulation
	result_amount = 2

/datum/cauldron_recipe/tempering
	reqs = list(/obj/item/food/grown/chili = 1, /obj/item/food/grown/mushroom/plumphelmet = 1)
	result = /obj/item/cultivation_pill/tempering
	result_amount = 3

/datum/cauldron_recipe/marrow_cleansing
	reqs = list(/obj/item/food/grown/aloe = 1, /obj/item/food/grown/harebell = 1, /obj/item/food/grown/mushroom/reishi = 1)
	result = /obj/item/cultivation_pill/marrow_cleansing

/datum/cauldron_recipe/spirit_beast
	reqs = list(/obj/item/food/meat/slab = 1, /obj/item/food/grown/ambrosia = 1, /obj/item/food/grown/mushroom/reishi = 1)
	result = /obj/item/cultivation_pill/spirit_beast

/datum/cauldron_recipe/pure_heart
	reqs = list(/obj/item/food/grown/poppy = 1, /obj/item/food/grown/tea = 1, /obj/item/food/grown/mushroom/glowshroom = 1)
	result = /obj/item/cultivation_pill/pure_heart

/datum/cauldron_recipe/nine_revolutions
	reqs = list(/obj/item/food/grown/ambrosia/gaia = 1, /obj/item/food/grown/mushroom/reishi = 2, /obj/item/food/grown/mushroom/libertycap = 1)
	result = /obj/item/cultivation_pill/nine_revolutions

// ===================== Cauldron-only pills =====================

/obj/item/cultivation_pill/marrow_cleansing
	name = "Marrow Cleansing Pill"
	desc = "A milky white pill that scours the meridians clean. Clears pill toxicity and calms unstable qi."
	icon_state = "pill_marrow"
	toxicity = 0

/obj/item/cultivation_pill/marrow_cleansing/cultivator_effect(mob/living/eater, datum/antagonist/cultivator/cultivator)
	cultivator.pill_toxicity = 0
	cultivator.adjust_instability(-30 * potency)
	new /obj/effect/temp_visual/circle_wave/cultivation/water(get_turf(eater))
	to_chat(eater, span_nicegreen("Something cool washes through your marrow, carrying away the residue of every pill you've eaten."))

/obj/item/cultivation_pill/spirit_beast
	name = "Beast Awakening Pill"
	desc = "A pungent, meaty pill. Feed it to a contracted spirit beast to awaken its bloodline, if its master's realm can support it."
	icon_state = "pill_beast"
	toxicity = 5

/obj/item/cultivation_pill/spirit_beast/consume(mob/living/eater, mob/living/feeder)
	var/datum/component/spirit_beast/contract = eater.GetComponent(/datum/component/spirit_beast)
	if(!contract)
		return ..()
	eater.visible_message(span_notice("[eater] wolfs down [src]."))
	playsound(eater, 'sound/items/eatfood.ogg', 40, TRUE)
	if(!contract.evolve())
		to_chat(feeder, span_warning("[eater] shudders, but its master's cultivation can't support another awakening yet."))
	qdel(src)

/obj/item/cultivation_pill/spirit_beast/cultivator_effect(mob/living/eater, datum/antagonist/cultivator/cultivator)
	to_chat(eater, span_warning("It tastes like a very expensive dog treat. Nothing happens."))

/obj/item/cultivation_pill/pure_heart
	name = "Pure Heart Pill"
	desc = "A translucent pink pill that smells of tea and poppies. Steadies the Dao heart, as if you had faced your heart demon."
	icon_state = "pill_heart"
	toxicity = 10

/obj/item/cultivation_pill/pure_heart/cultivator_effect(mob/living/eater, datum/antagonist/cultivator/cultivator)
	eater.apply_status_effect(/datum/status_effect/dao_heart_tempered)
	cultivator.adjust_instability(-15 * potency)
	new /obj/effect/temp_visual/circle_wave/cultivation/sense(get_turf(eater))
	to_chat(eater, span_nicegreen("Your heart grows still and clear. (+15 breakthrough readiness for 20 minutes)"))

/obj/item/cultivation_pill/nine_revolutions
	name = "Nine Revolutions Golden Pill"
	desc = "A heavy golden pill that has been refined nine times over. Pours foundation straight into a cultivator, even past the limits of their realm."
	icon_state = "pill_nine"
	toxicity = 25

/obj/item/cultivation_pill/nine_revolutions/cultivator_effect(mob/living/eater, datum/antagonist/cultivator/cultivator)
	var/amount = round(25 * potency)
	var/next = cultivator.next_threshold()
	cultivator.progress = next ? min(cultivator.progress + amount, next) : cultivator.progress + amount
	cultivator.update_hud()
	cultivation_particles(eater, /particles/cultivation/gold, 3 SECONDS)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(get_turf(eater))
	to_chat(eater, span_nicegreen("Molten gold seems to pour through your meridians! (+[amount] consolidated insight)"))

#undef CAULDRON_MAX_CONTENTS
#undef CAULDRON_QI_COST
