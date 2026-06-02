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
	description = "A light, colourless liquid with a distinct smell. Ingestion can lead to blindness. It is a byproduct of organisms processing impure Formaldehyde."
	reagent_state = LIQUID
	color = "#aae7e4"
	ph = 7
	liver_damage = 0

/datum/reagent/impurity/methanol/on_mob_life(mob/living/carbon/affected_mob, seconds_per_tick, times_fired)
	. = ..()
	var/obj/item/organ/eyes/eyes = affected_mob.get_organ_slot(ORGAN_SLOT_EYES)
	if(eyes?.apply_organ_damage(0.5 * REM * seconds_per_tick, required_organ_flag = affected_organ_flags))
		return UPDATE_MOB_HEALTH

//Chloral Hydrate - Impure Version
/datum/reagent/impurity/chloralax
	name = "Chloralax"
	description = "An oily, colorless and slightly toxic liquid. It is produced when impure choral hydrate is broken down inside an organism."
	reagent_state = LIQUID
	color = "#387774"
	ph = 7
	liver_damage = 0

/datum/reagent/impurity/chloralax/on_mob_life(mob/living/carbon/owner, seconds_per_tick)
	. = ..()
	if(owner.adjustToxLoss(1 * REM * seconds_per_tick, updating_health = FALSE, required_biotype = affected_biotype))
		return UPDATE_MOB_HEALTH

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
