/datum/preference/choiced/saiyan_tail
	savefile_key = "tail_saiyan"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	relevant_external_organ = /obj/item/organ/tail/monkey/saiyan
	can_randomize = FALSE

/datum/preference/choiced/saiyan_tail/init_possible_values()
	return assoc_to_keys_features(SSaccessories.tails_list_saiyan)

/datum/preference/choiced/saiyan_tail/apply_to_human(mob/living/carbon/human/target, value)
	target.dna.features["tail_saiyan"] = value

/datum/preference/choiced/saiyan_tail/create_default_value()
	return /datum/sprite_accessory/tails/saiyan/default::name
