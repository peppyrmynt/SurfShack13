/**
 * Pill alchemy. Anyone can refine pills from botany produce (botanists and chefs can sell them),
 * but only cultivators get the full effect. Every pill adds pill toxicity; too much turns into instability.
 */

/obj/item/cultivation_pill
	name = "pill"
	desc = "A small, glossy pill that smells faintly of herbs."
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'
	icon_state = "pill_qi"
	w_class = WEIGHT_CLASS_TINY
	/// Pill toxicity added to cultivators
	var/toxicity = 8
	/// Effect multiplier. Spirit-grade pills from a cauldron are stronger.
	var/potency = 1
	/// Refined to perfection in a cauldron
	var/spirit_grade = FALSE

/// A perfect cauldron refinement: stronger, half the toxicity, and it glows
/obj/item/cultivation_pill/proc/make_spirit_grade()
	spirit_grade = TRUE
	potency = 1.5
	toxicity = round(toxicity / 2)
	name = "spirit-grade [name]"
	add_filter("spirit_grade", 2, list("type" = "outline", "color" = "#fff6c8", "size" = 1, "alpha" = 180))

/obj/item/cultivation_pill/attack_self(mob/living/user)
	consume(user, user)

/obj/item/cultivation_pill/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isliving(interacting_with) || interacting_with == user)
		return NONE
	var/mob/living/target = interacting_with
	user.visible_message(span_notice("[user] tries to feed [src] to [target]."))
	if(!do_after(user, 3 SECONDS, target))
		return ITEM_INTERACT_BLOCKING
	consume(target, user)
	return ITEM_INTERACT_SUCCESS

/obj/item/cultivation_pill/proc/consume(mob/living/eater, mob/living/feeder)
	eater.visible_message(span_notice("[eater] swallows [src]."), span_notice("You swallow [src]."))
	playsound(eater, 'sound/items/eatfood.ogg', 40, TRUE)
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(eater)
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(eater)
	if(cultivator)
		cultivator.add_pill_toxicity(toxicity)
		cultivator_effect(eater, cultivator)
	else if(body_datum)
		body_effect(eater, body_datum)
	else
		mortal_effect(eater)
	qdel(src)

/// What it does for a body cultivator. Most pills are made for qi and only warm them up.
/obj/item/cultivation_pill/proc/body_effect(mob/living/eater, datum/antagonist/body_cultivator/body_datum)
	mortal_effect(eater)

/obj/item/cultivation_pill/proc/cultivator_effect(mob/living/eater, datum/antagonist/cultivator/cultivator)
	return

/obj/item/cultivation_pill/proc/mortal_effect(mob/living/eater)
	to_chat(eater, span_notice("You feel pleasantly warm, and nothing else."))

/obj/item/cultivation_pill/qi_gathering
	name = "Qi Gathering Pill"
	desc = "A pale blue pill refined from lingzhi. Floods a cultivator's meridians with qi and a little insight."
	icon_state = "pill_qi"
	toxicity = 8

/obj/item/cultivation_pill/qi_gathering/cultivator_effect(mob/living/eater, datum/antagonist/cultivator/cultivator)
	cultivator.adjust_qi(40 * potency)
	cultivator.gain_insight(8 * potency, null, silent = TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation(get_turf(eater))
	to_chat(eater, span_nicegreen("Qi surges through your meridians!"))

/obj/item/cultivation_pill/foundation
	name = "Foundation Establishment Pill"
	desc = "A golden pill said to steady one's foundation before a breakthrough. Its effect lasts ten minutes."
	icon_state = "pill_foundation"
	toxicity = 15

/obj/item/cultivation_pill/foundation/cultivator_effect(mob/living/eater, datum/antagonist/cultivator/cultivator)
	eater.apply_status_effect(/datum/status_effect/cultivation_pill_buff/foundation)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold(get_turf(eater))
	to_chat(eater, span_nicegreen("Your foundation feels as steady as a mountain. (+20 breakthrough readiness for 10 minutes)"))

/obj/item/cultivation_pill/tribulation
	name = "Tribulation Warding Pill"
	desc = "A violet pill that tastes of ozone. Heaven's lightning bites half as hard for ten minutes."
	icon_state = "pill_tribulation"
	toxicity = 15

/obj/item/cultivation_pill/tribulation/cultivator_effect(mob/living/eater, datum/antagonist/cultivator/cultivator)
	eater.apply_status_effect(/datum/status_effect/cultivation_pill_buff/tribulation)
	new /obj/effect/temp_visual/circle_wave/cultivation(get_turf(eater))
	to_chat(eater, span_nicegreen("Your skin prickles with static. Let heaven do its worst. (half lightning damage for 10 minutes)"))

/obj/item/cultivation_pill/tempering
	name = "Body Tempering Pill"
	desc = "A fiery red pill that knits flesh and burns away fatigue. Works on mortals too."
	icon_state = "pill_tempering"
	toxicity = 10

/obj/item/cultivation_pill/tempering/cultivator_effect(mob/living/eater, datum/antagonist/cultivator/cultivator)
	mortal_effect(eater)
	eater.heal_overall_damage(brute = 10 * potency, burn = 10 * potency)

/obj/item/cultivation_pill/tempering/body_effect(mob/living/eater, datum/antagonist/body_cultivator/body_datum)
	mortal_effect(eater)
	body_datum.gain_tempering(15 * potency, null)
	eater.apply_status_effect(/datum/status_effect/cultivation_pill_buff/body_tempering)
	to_chat(eater, span_nicegreen("The pill's fire sinks into your bones. (+tempering, +20 Tribulation of Flesh readiness for 10 minutes)"))

/obj/item/cultivation_pill/tempering/mortal_effect(mob/living/eater)
	eater.heal_overall_damage(brute = 20, burn = 10)
	eater.adjustStaminaLoss(-40)
	new /obj/effect/temp_visual/heal(get_turf(eater), "#e05a3c")
	to_chat(eater, span_nicegreen("Heat spreads through your body, closing wounds and burning away fatigue!"))

/datum/status_effect/cultivation_pill_buff
	id = "cultivation_pill_buff"
	alert_type = null
	duration = 10 MINUTES
	status_type = STATUS_EFFECT_REFRESH

/datum/status_effect/cultivation_pill_buff/foundation
	id = "foundation_pill"

/datum/status_effect/cultivation_pill_buff/tribulation
	id = "tribulation_pill"

/datum/antagonist/cultivator/proc/add_pill_toxicity(amount)
	pill_toxicity += amount
	if(pill_toxicity > 30)
		adjust_instability(round((pill_toxicity - 30) / 2))
		to_chat(owner.current, span_warning("Pill toxicity builds in your meridians. Your qi grows unstable!"))
	update_hud()

// ----- Recipes: anyone can refine pills -----

/datum/crafting_recipe/cultivation_pill
	name = "Qi Gathering Pills (x2)"
	result = /obj/item/cultivation_pill/qi_gathering
	result_amount = 2
	reqs = list(/obj/item/food/grown/mushroom/reishi = 1, /obj/item/food/grown/herbs = 1)
	time = 8 SECONDS
	category = CAT_CHEMISTRY

/datum/crafting_recipe/cultivation_pill/foundation
	name = "Foundation Establishment Pill"
	result = /obj/item/cultivation_pill/foundation
	result_amount = 1
	reqs = list(/obj/item/food/grown/mushroom/reishi = 2, /obj/item/food/grown/ambrosia = 1)

/datum/crafting_recipe/cultivation_pill/tribulation
	name = "Tribulation Warding Pill"
	result = /obj/item/cultivation_pill/tribulation
	result_amount = 1
	reqs = list(/obj/item/food/grown/mushroom/reishi = 1, /obj/item/food/grown/galaxythistle = 1, /obj/item/food/grown/garlic = 1)

/datum/crafting_recipe/cultivation_pill/tempering
	name = "Body Tempering Pills (x2)"
	result = /obj/item/cultivation_pill/tempering
	result_amount = 2
	reqs = list(/obj/item/food/grown/chili = 1, /obj/item/food/grown/mushroom/plumphelmet = 1)
