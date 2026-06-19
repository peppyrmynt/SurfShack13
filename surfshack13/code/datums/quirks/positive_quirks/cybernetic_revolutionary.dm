/datum/quirk/cyber_rev
	name = "Cybernetic Revolutionary"
	desc = "You believe in the superiority of cybernetic enhancements and have since opted to have one installed!"
	icon = FA_ICON_LUNGS
	value = 8
	hardcore_value = -8
	medical_record_text = "Patient has had a cybernetic organ installed within them."

/datum/quirk/cyber_rev/add_unique(client/player_client)
	var/list/item_list = list(
		/obj/item/organ/cyberimp/brain/anti_drop,
		/obj/item/organ/cyberimp/brain/anti_stun,
		/obj/item/organ/cyberimp/mouth/breathing_tube,
		/obj/item/organ/cyberimp/eyes/hud/diagnostic,
		/obj/item/organ/cyberimp/eyes/hud/medical,
		/obj/item/organ/cyberimp/chest/reviver,
		/obj/item/organ/cyberimp/chest/nutriment,
		/obj/item/organ/cyberimp/arm/surgery,
		/obj/item/organ/cyberimp/arm/toolset,
		/obj/item/organ/cyberimp/chest/thrusters,
		/obj/item/organ/cyberimp/chest/nutriment/plus, // nice!
		/obj/item/organ/cyberimp/arm/paperwork // not so nice.
	)
	var/organ_to_give = pick(item_list)


	var/cybernetic_type = organ_to_give
	var/mob/living/carbon/human/human_holder = quirk_holder
	var/obj/item/organ/cybernetic = new cybernetic_type()
	cybernetic.Insert(human_holder, special = TRUE, movement_flags = DELETE_IF_REPLACED)
