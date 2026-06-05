/datum/disease/transformation/lycanthropy
	name = "Lycanthropy"
	cure_text = "Silver"
	cures = list(/datum/reagent/silver)
	cure_chance = 2.5
	stage_prob = 0.5 // 0.5% chance per tick
	agent = "Lycan Microbes"
	desc = "This disease changes the victim into a werewolf."
	severity = DISEASE_SEVERITY_BIOHAZARD
	visibility_flags = NONE
	stage1 = list()
	stage2 = list("All hair upon your body fluffs up.", span_danger("You feel an unsettling urge to howl..."))
	stage3 = list(
		span_danger("You feel an urge to move around on all fours."),
		span_danger("You feel your muscles bulk up."),
		span_warning("You notice a strange new odor upon you."),
	)
	stage4 = list(
		span_danger("You can smell things you've never noticed before."),
		span_danger("Your eyes flicker as your vision enhances for a moment!"),
		span_danger("Your hands feel hairy."),
	)
	stage5 = list(span_danger("You grit your teeth as a low growl springs forth!"))
	//new_form = /mob/living/carbon/human/species/werewolf
	bantype = ROLE_WEREWOLF

/datum/disease/transformation/lycanthropy/do_disease_transformation(mob/living/carbon/human/affected_mob)
	if(!iswerewolf(affected_mob))
		affected_mob.regenerate_limbs()
		affected_mob.uncuff()

		var/datum/mind/new_werewolf_mind = affected_mob.mind
		new_werewolf_mind.add_antag_datum(/datum/antagonist/werewolf/lycanthropy)

		affected_mob.set_species(/datum/species/werewolf)

	qdel(src) // Remove the disease from us, we transformed.

/datum/disease/transformation/lycanthropy/stage_act(seconds_per_tick)
	. = ..()
	if(!.)
		return

	switch(stage)
		if(3)
			if(SPT_PROB(2, seconds_per_tick))
				to_chat(affected_mob, span_danger("You feel hairs prickle out from your flesh."))
		if(4)
			if(SPT_PROB(10, seconds_per_tick))
				affected_mob.say(pick("ARROOOOO", "ARF ARF ARF", "AWOOOO"), forced = "werewolf transformation")
