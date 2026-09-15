/datum/quirk/dexterous
	name = "Dexterous"
	desc = "You've got extra-ordinary ability with your hands, and can perform all actions that have a 'progress bar' 10% faster."
	icon = FA_ICON_BOLT
	value = 7
	hardcore_value = -2
	medical_record_text = "Patient demonstrates heightened ability with their hands."

/datum/quirk/dexterous/add_unique(client/client_source)
	var/mob/living/carbon/human/dex_man = quirk_holder

	dex_man.add_actionspeed_modifier(/datum/actionspeed_modifier/dexterous)

/datum/quirk/dexterous/remove(client/client_source)
	var/mob/living/carbon/human/dex_man = quirk_holder

	dex_man.remove_actionspeed_modifier(/datum/actionspeed_modifier/dexterous)
