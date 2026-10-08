//Reagents produced by metabolising/reacting fermichems inoptimally these specifically are for toxins
//Inverse = Splitting
//Invert = Whole conversion
//Failed = End reaction below purity_min

////////////////////TOXINS///////////////////////////

//Lipolicide - Impure Version
/datum/reagent/impurity/ipecacide
	name = "Ipecacide"
	description = "An extremely gross substance that induces vomiting. It is produced when Lipolicide reactions are impure."
	metabolization_rate = 2 * REAGENTS_METABOLISM
	overdose_threshold = 25
	ph = 7
	liver_damage = 0
	var/yuck_cycle = 0 //! The `current_cycle` when puking starts

/datum/reagent/impurity/ipecacide/on_mob_add(mob/living/affected_mob)
	if(HAS_TRAIT(affected_mob, TRAIT_NOHUNGER))
		holder.del_reagent(type)
	return ..()

#define YUCK_PUKE_CYCLES 3
#define YUCK_PUKES_TO_STUN 3

/datum/reagent/impurity/ipecacide/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	. = ..()

	affected_mob.set_dizzy_if_lower(10 SECONDS)
	affected_mob.set_jitter_if_lower(10 SECONDS)

	if(!yuck_cycle)
		if(!yuck_cycle && current_cycle >= 3)
			var/dread = pick(
				"Something is moving in your stomach...",
				"A wet growl echoes from your stomach...",
				"For a moment you feel like your surroundings are moving, but it's your stomach...")
			to_chat(affected_mob, span_userdanger("[dread]"))
			yuck_cycle = current_cycle
		return

	var/yuck_cycles = current_cycle - yuck_cycle

	for(var/datum/reagent/target_reagent as anything in affected_mob.reagents.reagent_list)
		if(istype(target_reagent, /datum/reagent/impurity/ipecacide))
			continue
		affected_mob.reagents.remove_reagent(target_reagent.type, 4 * target_reagent.purge_multiplier * REM * seconds_per_tick)

	if(yuck_cycles % YUCK_PUKE_CYCLES == 0)

		if(yuck_cycles >= YUCK_PUKE_CYCLES * YUCK_PUKES_TO_STUN)
			if(holder)
				holder.remove_reagent(type, 3)

		var/passable_flags = (MOB_VOMIT_MESSAGE | MOB_VOMIT_HARM)

		if(yuck_cycles >= (YUCK_PUKE_CYCLES * YUCK_PUKES_TO_STUN))
			passable_flags |= MOB_VOMIT_STUN

		affected_mob.vomit(
			vomit_flags = passable_flags,
			lost_nutrition = rand(14, 26)
		)

#undef YUCK_PUKE_CYCLES
#undef YUCK_PUKES_TO_STUN

/datum/reagent/impurity/ipecacide/on_mob_end_metabolize(mob/living/affected_mob)
	. = ..()
	yuck_cycle = 0

/datum/reagent/impurity/ipecacide/overdose_process(mob/living/affected_mob, seconds_per_tick, times_fired)
	. = ..()

	affected_mob.reagents.remove_reagent(type, 6 * REM * seconds_per_tick)
	affected_mob.adjustOrganLoss(ORGAN_SLOT_STOMACH, 2 * REM * seconds_per_tick, required_organ_flag = affected_organ_flags)
	affected_mob.adjustOrganLoss(ORGAN_SLOT_HEART, 1.5 * REM * seconds_per_tick, required_organ_flag = affected_organ_flags)

//Formaldehyde - Impure Version
/datum/reagent/impurity/methanol
	name = "Methanol"
	description = "A light, colourless liquid with a distinct smell. Ingestion can lead to blindness."
	reagent_state = LIQUID
	color = "#aae7e4"
	ph = 7
	liver_damage = 0

/datum/reagent/impurity/methanol/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	. = ..()
	if(!affected_mob)
		return
	var/obj/item/organ/eyes/eyes = affected_mob.get_organ_slot(ORGAN_SLOT_EYES)
	eyes?.apply_organ_damage(0.5 * REM * seconds_per_tick, required_organ_flag = affected_organ_flags)

	if(SPT_PROB(20, seconds_per_tick))
		to_chat(affected_mob, span_warning("Your head aches as your vision blurs."))
		affected_mob.adjust_eye_blur(5 SECONDS * REM * seconds_per_tick)
		affected_mob.adjust_confusion_up_to(5 SECONDS, 20 SECONDS)
		affected_mob.adjust_hallucinations(10 SECONDS)
		affected_mob.emote(pick("stare","drool","moan","look"))
		affected_mob.adjustToxLoss(2 * REM * seconds_per_tick, updating_health = FALSE, required_biotype = affected_biotype)

/datum/reagent/impurity/methanol/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume)
	. = ..()
	if(isliving(exposed_mob) && (methods & (TOUCH|VAPOR|PATCH)))
		exposed_mob.adjust_fire_stacks(min(reac_volume/4, 20))

//Chloral Hydrate - Impure Version
/datum/reagent/impurity/chloralax
	name = "Chloralax"
	description = "A miracle cleaning solution and dental disenfectant. Can be used to dry and sanitize surfaces, while also having a mild antibiotic effect. It is somewhat toxic."
	reagent_state = LIQUID
	color = "#387774"
	ph = 7
	var/clean_types = CLEAN_WASH
	liver_damage = 0
	metabolization_rate = REAGENTS_METABOLISM

/datum/reagent/impurity/chloralax/on_mob_life(mob/living/carbon/M, seconds_per_tick, times_fired)
	. = ..()

	if(M.adjustToxLoss(2 * REM * seconds_per_tick, updating_health = FALSE, required_biotype = affected_biotype))
		. = UPDATE_MOB_HEALTH

	if((M.mob_biotypes & MOB_ORGANIC) && prob(0.3))
		for(var/thing in M.diseases) // can clean viruses from organic lifeforms.
			var/datum/disease/D = thing
			D.cure()

/datum/reagent/impurity/chloralax/expose_obj(obj/exposed_obj, reac_volume, methods=TOUCH, show_message=TRUE)
	. = ..()
	exposed_obj?.wash(clean_types)

/datum/reagent/impurity/chloralax/expose_turf(turf/open/exposed_turf, reac_volume)
	. = ..()
	if(reac_volume < 1)
		return

	exposed_turf.wash(clean_types)
	for(var/am in exposed_turf)
		var/atom/movable/movable_content = am
		if(ismopable(movable_content)) // Mopables will be cleaned anyways by the turf wash
			continue
		movable_content.wash(clean_types)

	for(var/mob/living/basic/slime/exposed_slime in exposed_turf)
		exposed_slime.adjustToxLoss(rand(5,10))

	if(!istype(exposed_turf))
		return
	// We want one spray of this stuff (5u) to take out a wet floor. Feels better that way
	exposed_turf.MakeDry(ALL, TRUE, reac_volume * 10 SECONDS)

/datum/reagent/impurity/chloralax/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume, show_message=TRUE, touch_protection=0)
	. = ..()
	if(methods & (TOUCH|VAPOR))
		exposed_mob.wash(clean_types)

/datum/reagent/impurity/chloralax/on_burn_wound_processing(datum/wound/burn/flesh/burn_wound)
	burn_wound.sanitization += 0.3
	if(prob(5))
		to_chat(burn_wound.victim, span_notice("Your [burn_wound] stings and burns from [src] covering it! It <i>does</i> look pretty clean though."))
		burn_wound.victim.apply_damage(0.5, TOX)
		burn_wound.victim.apply_damage(0.5, BURN, burn_wound.limb, wound_bonus = CANT_WOUND)

//Mindbreaker Toxin - Impure Version
/datum/reagent/impurity/rosenol
	name = "Rosenol"
	description = "A strange, blue liquid that is produced during impure mindbreaker toxin reactions. Historically it has been abused to write poetry."
	reagent_state = LIQUID
	color = "#0963ad"
	ph = 7
	liver_damage = 0
	metabolization_rate = 0.5 * REAGENTS_METABOLISM

/datum/reagent/impurity/rosenol/on_mob_life(mob/living/carbon/owner, seconds_per_tick)
	. = ..()
	var/obj/item/organ/tongue/tongue = owner.get_organ_slot(ORGAN_SLOT_TONGUE)
	if(!tongue)
		return
	if(SPT_PROB(4.0, seconds_per_tick))
		owner.manual_emote("clicks with [owner.p_their()] tongue.")
		owner.say("Noice.", forced = /datum/reagent/impurity/rosenol)
	if(SPT_PROB(2.0, seconds_per_tick))
		owner.say(pick("Ah! That was a mistake!", "Horrible.", "Watch out everybody, the potato is really hot.", "When I was six I ate a bag of plums.", "And if there is one thing I can't stand it's tomatoes.", "And if there is one thing I love it's tomatoes.", "We had a captain who was so strict, you weren't allowed to breathe in their station.", "The unrobust ones just used to keel over and die, you'd hear them going down behind you."), forced = /datum/reagent/impurity/rosenol)
