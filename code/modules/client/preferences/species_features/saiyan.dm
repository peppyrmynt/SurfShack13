/datum/preference/choiced/tail_saiyan
	savefile_key = "feature_saiyan_tail"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_SECONDARY_FEATURES
	relevant_external_organ = /obj/item/organ/tail/monkey/saiyan
	can_randomize = FALSE

/datum/preference/choiced/monkey_tail/init_possible_values()
	return assoc_to_keys_features(SSaccessories.tails_list_monkey)

/datum/preference/choiced/tail_saiyan/apply_to_human(mob/living/carbon/human/target, value)
	target.dna.features["tail_saiyan"] = value

/datum/preference/choiced/tail_saiyan/create_default_value()
	return /datum/sprite_accessory/tails/saiyan/default::name
