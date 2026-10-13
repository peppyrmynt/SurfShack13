/obj/item/grenade/hypnotic
	name = "flashbang"
	desc = "A modified flashbang which uses hypnotic flashes and mind-altering soundwaves to induce an instant trance upon detonation, the user is immune to it's effects so no protection is required. A crude stencil on the casing reads: 'MULTITOOL ORDNANCE BEFORE USE'."
	icon_state = "flashbang"
	inhand_icon_state = "flashbang"
	lefthand_file = 'icons/mob/inhands/equipment/security_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/security_righthand.dmi'
	var/flashbang_range = 7
	var/hypno_phrase = ""
	var/datum/weakref/primer_ref

/obj/item/grenade/hypnotic/examine(mob/user)
	. = ..()
	if(hypno_phrase)
		. += span_notice("Its cognitive payload display reads: <i>\"[hypno_phrase]\"</i>.")
	else
		. += span_warning("The payload memory registers as completely blank. You should probably configure the grenade with a multitool BEFORE use.")

/obj/item/grenade/hypnotic/multitool_act(mob/living/user, obj/item/multitool/tool)
	if(!istype(tool))
		return FALSE
	var/new_phrase = stripped_input(user, "Enter the hypnotic cognitive trigger phrase to flash-burn into targets upon detonation:", "Hypnotic Ordnance Configuration", hypno_phrase, 400)
	if(!user.Adjacent(src))
		return TRUE
	if(!new_phrase)
		to_chat(user, span_warning("You clear the cognitive payload memory on [src]. Detonating it unconfigured will cause an inert payload fizzle!"))
		hypno_phrase = ""
		return TRUE
	hypno_phrase = new_phrase
	playsound(src, 'sound/machines/click.ogg', 30, TRUE)
	to_chat(user, span_notice("You interface [tool] with the logic port, setting the detonation trigger phrase to: <i>\"[hypno_phrase]\"</i>."))
	return TRUE

/obj/item/grenade/hypnotic/arm_grenade(mob/user, delay_override, msg = TRUE, volume = 60)
	if(user)
		primer_ref = WEAKREF(user)
	return ..()

/obj/item/grenade/hypnotic/apply_grenade_fantasy_bonuses(quality)
	flashbang_range = modify_fantasy_variable("flashbang_range", flashbang_range, quality)

/obj/item/grenade/hypnotic/remove_grenade_fantasy_bonuses(quality)
	flashbang_range = reset_fantasy_variable("flashbang_range", flashbang_range)

/obj/item/grenade/hypnotic/detonate(mob/living/lanced_by)
	. = ..()
	if(!.)
		return

	update_mob()
	var/flashbang_turf = get_turf(src)
	if(!flashbang_turf)
		return

	if(!hypno_phrase)
		visible_message(span_warning("[src] emits a dull mechanical pop and a harmless plume of static-charged mist! The ordnance was unconfigured!"))
		playsound(flashbang_turf, 'sound/items/weapons/flashbang.ogg', 25, TRUE, 4)
		do_sparks(2, FALSE, src)
		qdel(src)
		return

	do_sparks(rand(5, 9), FALSE, src)
	playsound(flashbang_turf, 'sound/effects/screech.ogg', 100, TRUE, 8, 0.9)
	new /obj/effect/dummy/lighting_obj(flashbang_turf, flashbang_range + 2, 4, LIGHT_COLOR_PURPLE, 2)
	for(var/mob/living/living_mob in get_hearers_in_view(flashbang_range, flashbang_turf))
		bang(get_turf(living_mob), living_mob)
	qdel(src)

/obj/item/grenade/hypnotic/proc/bang(turf/turf, mob/living/living_mob)
	if(living_mob.stat == DEAD)
		return

	if(primer_ref && living_mob == primer_ref.resolve())
		to_chat(living_mob, span_notice("Your synchronized ocular-cochlear cipher rejects [src]'s hypnotic feedback burst!"))
		return

	var/distance = max(0, get_dist(get_turf(src), turf))
	var/hypno_sound = FALSE

	if(iscarbon(living_mob))
		var/mob/living/carbon/target = living_mob
		var/list/reflist = list(1)
		SEND_SIGNAL(target, COMSIG_CARBON_SOUNDBANG, reflist)
		var/intensity = reflist[1]
		var/ear_safety = target.get_ear_protection()
		var/effect_amount = intensity - ear_safety
		if(effect_amount > 0)
			hypno_sound = TRUE

	if(!distance || loc == living_mob || loc == living_mob.loc)
		living_mob.Paralyze(10)
		living_mob.Knockdown(100)
		to_chat(living_mob, span_hypnophrase("The sound echoes in your brain..."))
		living_mob.adjust_hallucinations(100 SECONDS)
	else
		if(distance <= 1)
			living_mob.Paralyze(5)
			living_mob.Knockdown(30)
		if(hypno_sound)
			to_chat(living_mob, span_hypnophrase("The sound echoes in your brain..."))
			living_mob.adjust_hallucinations(100 SECONDS)

	if(living_mob.flash_act(affect_silicon = 1))
		living_mob.Paralyze(max(10 / max(1, distance), 5))
		living_mob.Knockdown(max(100 / max(1, distance), 40))
		if(iscarbon(living_mob))
			var/mob/living/carbon/target = living_mob
			if(target.hypnosis_vulnerable())
				target.apply_status_effect(/datum/status_effect/trance, 100, TRUE)
				if(hypno_phrase)
					var/datum/brain_trauma/hypnosis/trauma = new /datum/brain_trauma/hypnosis(hypno_phrase)
					target.gain_trauma(trauma, TRAUMA_RESILIENCE_SURGERY)
					target.mind?.add_antag_datum(/datum/antagonist/hypnotized)
			else
				to_chat(target, span_hypnophrase("The light is so pretty..."))
				target.adjust_drowsiness_up_to(20 SECONDS, 40 SECONDS)
				target.adjust_confusion_up_to(10 SECONDS, 20 SECONDS)
				target.adjust_dizzy_up_to(20 SECONDS, 40 SECONDS)
