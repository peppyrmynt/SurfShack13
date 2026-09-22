/// A sealed dose: injecting or splashing the crafting reagent cannot grant a shield.
/obj/item/shield_potion
	name = "shield potion"
	desc = "A squat jar of shimmering blue liquid. Drink for five seconds to gain 50 shield, up to 100."
	icon = 'icons/obj/drinks/shield_potions.dmi'
	icon_state = "big"
	lefthand_file = 'icons/mob/inhands/items/shield_potions_left.dmi'
	righthand_file = 'icons/mob/inhands/items/shield_potions_right.dmi'
	inhand_icon_state = "big"
	w_class = WEIGHT_CLASS_SMALL
	/// Shield granted only after a successful drink.
	var/shield_gain = 50
	/// Minis cannot raise the pool above 50; big pots can reach 100.
	var/shield_cap = 100
	var/drink_time = 5 SECONDS
	/// User-supplied Fortnite clip, fitted to the action duration.
	var/drink_sound = 'sound/effects/shield_potion/drink_big.ogg'
	var/mob/living/carbon/drinker
	var/drink_interrupted = FALSE
	var/drink_channel
	var/list/drink_listeners

/obj/item/shield_potion/small
	name = "small shield potion"
	desc = "A small, wide-necked blue flask. Drink for two seconds to gain 25 shield, up to 50."
	icon_state = "small"
	inhand_icon_state = "small"
	shield_gain = 25
	shield_cap = 50
	drink_time = 2 SECONDS
	drink_sound = 'sound/effects/shield_potion/drink_small.ogg'

/obj/item/shield_potion/Destroy()
	finish_drinking()
	return ..()

/obj/item/shield_potion/attack_self(mob/user, modifiers)
	. = ..()
	if(drinker || !iscarbon(user))
		return
	var/mob/living/carbon/consumer = user
	if(!can_drink(consumer))
		to_chat(user, span_warning("You must be able to drink, hold the potion, and have less than [shield_cap] shield."))
		return
	drinker = consumer
	drink_interrupted = FALSE
	RegisterSignal(drinker, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_damage))
	RegisterSignals(drinker, COMSIG_LIVING_ADJUST_ALL_DAMAGE_TYPES, PROC_REF(on_adjust_damage))
	RegisterSignal(drinker, COMSIG_CARBON_LIMB_DAMAGED, PROC_REF(on_limb_damage))
	RegisterSignal(drinker, COMSIG_QDELETING, PROC_REF(on_drinker_deleted))
	drinker.visible_message(span_notice("[drinker] starts drinking [src]."), span_notice("You start drinking [src]."))
	drink_channel = SSsounds.random_available_channel()
	var/sound/gulping = sound(drink_sound)
	drink_listeners = playsound(src, gulping, 35, FALSE, channel = drink_channel)
	var/completed = do_after(drinker, drink_time, src, timed_action_flags = IGNORE_SLOWDOWNS, extra_checks = CALLBACK(src, PROC_REF(drinking_checks)), interaction_key = "shield_potion")
	if(QDELETED(src))
		return
	completed = completed && !drink_interrupted && can_drink(consumer)
	finish_drinking()
	if(!completed)
		return
	if(consumer.add_potion_shield(shield_gain, shield_cap) <= 0)
		return
	to_chat(consumer, span_notice("You finish the potion. Your shield is now [consumer.get_potion_shield()]/100."))
	qdel(src)

/obj/item/shield_potion/proc/can_drink(mob/living/carbon/consumer)
	return !QDELETED(consumer) && consumer.stat == CONSCIOUS && !HAS_TRAIT(consumer, TRAIT_INCAPACITATED) \
		&& consumer.get_active_held_item() == src && !consumer.is_mouth_covered() \
		&& consumer.get_bodypart(BODY_ZONE_HEAD) && consumer.get_potion_shield() < shield_cap

/obj/item/shield_potion/proc/drinking_checks()
	return !QDELETED(src) && !drink_interrupted && can_drink(drinker)

/obj/item/shield_potion/proc/on_adjust_damage(datum/source, damage_type, amount)
	SIGNAL_HANDLER
	if(amount > 0)
		drink_interrupted = TRUE
		stop_drinking_sound()

/obj/item/shield_potion/proc/on_damage(datum/source, damage)
	SIGNAL_HANDLER
	if(damage > 0)
		drink_interrupted = TRUE
		stop_drinking_sound()

/obj/item/shield_potion/proc/on_limb_damage(datum/source, obj/item/bodypart/limb, brute, burn)
	SIGNAL_HANDLER
	if(brute > 0 || burn > 0)
		drink_interrupted = TRUE
		stop_drinking_sound()

/obj/item/shield_potion/proc/on_drinker_deleted(datum/source)
	SIGNAL_HANDLER
	finish_drinking()

/obj/item/shield_potion/proc/stop_drinking_sound()
	for(var/mob/listener as anything in drink_listeners)
		if(!QDELETED(listener))
			listener.stop_sound_channel(drink_channel)
	drink_listeners = null
	drink_channel = null

/obj/item/shield_potion/proc/finish_drinking()
	stop_drinking_sound()
	if(drinker)
		UnregisterSignal(drinker, list(COMSIG_MOB_APPLY_DAMAGE, COMSIG_CARBON_LIMB_DAMAGED, COMSIG_QDELETING))
		UnregisterSignal(drinker, COMSIG_LIVING_ADJUST_ALL_DAMAGE_TYPES)
	drinker = null

/// Inert precursor: only the sealed, timed potion item grants shield.
/datum/reagent/shield_concentrate
	name = "Shield concentrate"
	description = "An unstable blue concentrate. It must be bottled with silver in a shaker before use."
	color = "#18BAEF"
	taste_description = "electric blueberries"

/// A deliberately difficult bartender recipe requiring chemistry/mining cooperation.
/datum/chemical_reaction/shield_concentrate
	results = list(/datum/reagent/shield_concentrate = 10)
	required_reagents = list(
		/datum/reagent/consumable/ethanol/singulo = 10,
		/datum/reagent/consumable/ethanol/curacao = 5,
		/datum/reagent/bluespace = 2,
		/datum/reagent/consumable/frostoil = 3,
	)
	mob_react = FALSE
	required_temp = 270
	required_other = TRUE
	reaction_flags = REACTION_INSTANT
	mix_message = "The mixture condenses into a brilliant blue shield concentrate."

/datum/chemical_reaction/shield_concentrate/pre_reaction_other_checks(datum/reagents/holder)
	return holder.chem_temp >= 270 && holder.chem_temp <= 280

/datum/crafting_recipe/shield_potion
	name = "Shield potion"
	result = /obj/item/shield_potion
	time = 10 SECONDS
	category = CAT_CHEMISTRY
	tool_paths = list(/obj/item/reagent_containers/cup/glass/shaker)
	reqs = list(
		/datum/reagent/shield_concentrate = 20,
		/obj/item/stack/sheet/glass = 1,
		/obj/item/stack/sheet/mineral/silver = 1,
	)

/datum/crafting_recipe/shield_potion/small
	name = "Small shield potion"
	result = /obj/item/shield_potion/small
	reqs = list(
		/datum/reagent/shield_concentrate = 10,
		/obj/item/stack/sheet/glass = 1,
		/obj/item/stack/sheet/mineral/silver = 1,
	)
