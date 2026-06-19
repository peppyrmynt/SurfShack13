/datum/quirk/good_weak_virus
	name = "Weak Good Virus"
	desc = "You previously volunteered to be the host of an experimental beneficial virus. It won't do a whole lot, but it can be helpful."
	icon = FA_ICON_DISEASE
	value = 8
	hardcore_value = -3
	medical_record_text = "Patient was previously given a simple beneficial virus."

/datum/quirk/good_weak_virus/add(client/client_source)
	var/datum/disease/advance/onerandompos/goodvirus = new /datum/disease/advance/onerandompos()
	quirk_holder.ForceContractDisease(goodvirus)
