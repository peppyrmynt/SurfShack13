/datum/quirk/natural_def
	name = "Naturally Robust"
	desc = "You've been through thick and thin many times before, and have become naturally resistant to physical damage. You'll take 5% less brute and burn damage."
	icon = FA_ICON_SHIELD_ALT
	value = 8
	hardcore_value = -3
	medical_record_text = "Patient has above-average robustness against most forms of physical damage."

/datum/quirk/natural_def/add(client/client_source)
	var/mob/living/carbon/human/human_holder = quirk_holder

	human_holder.physiology.brute_mod *= 0.95
	human_holder.physiology.burn_mod *= 0.95