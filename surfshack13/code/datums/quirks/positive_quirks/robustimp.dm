/datum/quirk/robustimp
	name = "Health Implantee"
	desc = "You've recently invested a lump sum of your funds into a high-tech implant that'll help keep you alive."
	icon = FA_ICON_SYRINGE
	value = 10
	hardcore_value = -5
	medical_record_text = "Patient has previously purchased a R.O.B.U.S.T health implant."

/datum/quirk/robustimp/add_unique(client/client_source)
	var/mob/living/carbon/human/human_holder = quirk_holder
	var/obj/item/implant/robusttec/lesser/robustimp = new /obj/item/implant/robusttec/lesser(human_holder)
	robustimp.implant(human_holder, null, silent = TRUE)
