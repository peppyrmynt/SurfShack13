/datum/quirk/mut_activate
	name = "Positive DNA Activation"
	desc = "You previously volunteered for genetic experimentation, and came out of it with a positive mutation."
	icon = FA_ICON_DNA
	value = 6
	hardcore_value = -2
	medical_record_text = "Patient was previously used in genetic experimentation, and the changes were certainly positive."

/datum/quirk/mut_activate/add_unique(client/client_source)
	var/mob/living/carbon/human/human_holder = quirk_holder
	human_holder.easy_random_mutate((POSITIVE), TRUE, TRUE, TRUE, NONE)
