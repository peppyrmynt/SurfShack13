/*DNA Saboteur
 * Lowers stealth
 * Lowers resistance greatly
 * No change to stage speed
 * Decreases transmissibility greatly
 * Fatal level
 * Bonus: Cleans the DNA of a person and then randomly gives them a trait.
*/

/datum/symptom/genetic_mutation
	name = "Dormant DNA Activator"
	desc = "The virus bonds with the DNA of the host, activating random dormant mutations within their DNA. When the virus is cured, the host's genetic alterations are undone."
	illness = "Lycanthropy"
	stealth = -2
	resistance = -3
	stage_speed = 0
	transmittable = -3
	level = 7
	severity = 4
	base_message_chance = 50
	symptom_delay_min = 30
	symptom_delay_max = 60
	var/excludemuts = NONE
	var/no_reset = FALSE
	var/mutadone_proof_muts = FALSE
	threshold_descs = list(
		"Resistance 8" = "The negative and mildly negative mutations caused by the virus are mutadone-proof (but will still be undone when the virus is cured if the resistance 14 threshold is not met).",
		"Resistance 14" = "The host's genetic alterations are not undone when the virus is cured.",
		"Stage Speed 10" = "The virus activates dormant mutations at a much faster rate.",
		"Stealth 5" = "Only activates negative mutations in hosts."
	)
	var/list/disease_mutations = list()

/datum/symptom/genetic_mutation/Start(datum/disease/advance/A)
	. = ..()
	if(!.)
		return
	if(A.totalStealth() >= 5) //only give them bad mutations
		excludemuts = POSITIVE
	if(A.totalStageSpeed() >= 10) //activate dormant mutations more often at around 1.5x the pace
		symptom_delay_min = 20
		symptom_delay_max = 40
	if(A.totalResistance() >= 8) //mutadone won't save you now
		mutadone_proof_muts = TRUE
	if(A.totalResistance() >= 14) //one does not simply escape Nurgle's grasp
		no_reset = TRUE

/datum/symptom/genetic_mutation/Activate(datum/disease/advance/A)
	. = ..()
	if(!.)
		return
	var/mob/living/carbon/C = A.affected_mob
	if(!C.has_dna())
		return
	switch(A.stage)
		if(4, 5)
			to_chat(C, span_warning("[pick("Your skin feels itchy.", "You feel light headed.")]"))
			var/random_mut_activation = C.easy_random_mutate((NEGATIVE | MINOR_NEGATIVE | POSITIVE) - excludemuts, TRUE, TRUE, TRUE, NONE, TRUE)
			if(isnull(random_mut_activation))
				return
			C.dna.activate_mutation(random_mut_activation)
			disease_mutations += random_mut_activation
			var/datum/mutation/human/HM = C.dna.get_mutation(random_mut_activation)
			if(HM && mutadone_proof_muts)
				HM.mutadone_proof = TRUE

/datum/symptom/genetic_mutation/End(datum/disease/advance/A)
	. = ..()
	if(!.)
		return
	if(!no_reset)
		var/mob/living/carbon/M = A.affected_mob
		if(M.has_dna())
			for(var/datum/mutation/human/human_mutation as anything in disease_mutations)
				M.dna.remove_mutation(human_mutation)
			disease_mutations = null

/datum/symptom/good_genetic_mutation
	name = "Beneficial DNA Activator"
	desc = "The virus bonds with the DNA of the host, activating random dormant beneficial mutations within their DNA to improve host survivability. When the virus is cured, the host's genetic alterations are undone."
	stealth = -4
	resistance = -3
	stage_speed = -1
	transmittable = -2
	level = 12
	base_message_chance = 50
	symptom_delay_min = 30
	symptom_delay_max = 60
	var/no_reset = FALSE
	var/mutadone_proof_muts = NONE
	threshold_descs = list(
		"Resistance 10" = "The positive mutations caused by the virus are mutadone-proof (but will still be undone when the virus is cured if the resistance 16 threshold is not met).",
		"Resistance 16" = "The host's genetic alterations are not undone when the virus is cured.",
		"Stage Speed 10" = "The virus activates dormant mutations at a much faster rate.",
	)
	var/list/disease_mutations = list()

/datum/symptom/good_genetic_mutation/Start(datum/disease/advance/A)
	. = ..()
	if(!.)
		return
	if(A.totalStageSpeed() >= 10) //activate dormant mutations more often at around 1.5x the pace
		symptom_delay_min = 20
		symptom_delay_max = 40
	if(A.totalResistance() >= 8) // Fuck your mutadone sprays.
		mutadone_proof_muts = TRUE
	if(A.totalResistance() >= 14) // A true god amongst men.
		no_reset = TRUE

/datum/symptom/good_genetic_mutation/Activate(datum/disease/advance/A)
	. = ..()
	if(!.)
		return
	var/mob/living/carbon/C = A.affected_mob
	if(!C.has_dna())
		return
	switch(A.stage)
		if(4, 5)
			to_chat(C, span_warning("[pick("Your skin feels rubbery.", "You feel a spark of energy curl up within you.")]"))
			var/random_mut_activation = C.easy_random_mutate((POSITIVE), TRUE, TRUE, TRUE, NONE, TRUE)
			if(isnull(random_mut_activation))
				return
			C.dna.activate_mutation(random_mut_activation)
			disease_mutations += random_mut_activation
			var/datum/mutation/human/HM = C.dna.get_mutation(random_mut_activation)
			if(HM && mutadone_proof_muts)
				HM.mutadone_proof = TRUE

/datum/symptom/good_genetic_mutation/End(datum/disease/advance/A)
	. = ..()
	if(!.)
		return
	if(!no_reset)
		var/mob/living/carbon/M = A.affected_mob
		if(M.has_dna())
			for(var/datum/mutation/human/human_mutation as anything in disease_mutations)
				M.dna.remove_mutation(human_mutation)
			disease_mutations = null
