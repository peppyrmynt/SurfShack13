/datum/disease/advance/onerandompos
	copy_type = /datum/disease/advance

/datum/disease/advance/onerandompos/New()
	name = "Weak Positive Virus"

	var/list/datum/symptom/possible_symptoms = list(
		/datum/symptom/good_genetic_mutation,
		/datum/symptom/heal/calorie,
		/datum/symptom/heal/darkness,
		/datum/symptom/heal/water,
		/datum/symptom/heal/starlight,
		/datum/symptom/heal/plasma,
		/datum/symptom/heal/radiation,
		/datum/symptom/heal/chem,
		/datum/symptom/heal/coma,
		/datum/symptom/oxygen,
		/datum/symptom/actionspd,
		/datum/symptom/mind_restoration,
		/datum/symptom/sensory_restoration,
	)

	var/symptom = pick(possible_symptoms)

	symptoms = list(new symptom)
	..()
