/obj/item/organ/ears/werewolf
	name = "wolf ears"
	icon = 'icons/obj/clothing/head/costume.dmi'
	worn_icon = 'icons/mob/clothing/head/costume.dmi'
	icon_state = "kitty"
	desc = "Allows the user to more easily hear whispers. The user becomes extra vulnerable to loud noises, however"
	visual = TRUE
	// Same sensitivity as felinid ears
	damage_multiplier = 2

	dna_block = DNA_EARS_BLOCK
	bodypart_overlay = /datum/bodypart_overlay/mutant/cat_ears
	sprite_accessory_override = /datum/sprite_accessory/ears/werewolf

/*
/obj/item/organ/ears/werewolf/Insert(mob/living/carbon/receiver, special, drop_if_replaced)
	. = ..()
	organ_traits = list(TRAIT_GOOD_HEARING)
*/

/obj/item/organ/eyes/werewolf
	name = "wolf eyes"
	desc = "Large and powerful eyes."
	icon = 'surfshack13/icons/obj/antags/mutant_bodyparts.dmi'
	icon_state = "werewolf_eyes"
	sight_flags = SEE_MOBS
	color_cutoffs = list(25, 5, 42)

/obj/item/organ/heart/werewolf
	name = "massive heart"
	desc = "An absolutely monstrous heart."
	icon_state = "heart-on"
	base_icon_state = "heart"
	maxHealth = 2 * STANDARD_ORGAN_THRESHOLD

/obj/item/organ/heart/werewolf/Initialize(mapload)
	. = ..()
	transform = transform.Scale(1.5)


/obj/item/organ/liver/werewolf
	name = "Beastly liver"
	desc = "A large monstrous liver."
	icon_state = "liver"
	///Var for brute healing via blood
	var/blood_brute_healing = 2.5
	///Var for burn healing via blood
	var/blood_burn_healing = 2.5

/obj/item/organ/liver/werewolf/handle_chemical(mob/living/carbon/organ_owner, datum/reagent/chem, seconds_per_tick)
	. = ..()
	//parent returned COMSIG_MOB_STOP_REAGENT_CHECK or we are failing
	if((. & COMSIG_MOB_STOP_REAGENT_CHECK) || (organ_flags & ORGAN_FAILING))
		return
	if(istype(chem, /datum/reagent/silver))
		organ_owner.adjustStaminaLoss(7.5 * REM * seconds_per_tick)
		organ_owner.adjustFireLoss(5.0 * REM * seconds_per_tick, updating_health = TRUE)


/obj/item/organ/tongue/werewolf
	name = "wolf tongue"
	desc = "A large tongue that looks like a mix of a human's and a wolf's."
	icon_state = "werewolf_tongue"
	icon = 'surfshack13/icons/obj/antags/mutant_bodyparts.dmi'
	say_mod = "growls"
	modifies_speech = TRUE
	taste_sensitivity = 5
	//liked_foodtypes = GROSS | MEAT | RAW | GORE
	//disliked_foodtypes = SUGAR

/obj/item/organ/tongue/werewolf/modify_speech(datum/source, list/speech_args)
	var/message = speech_args[SPEECH_MESSAGE]
	if(message[1] != "*")

		// all occurrences of characters "eiou" (case-insensitive) are replaced with "r"
		message = replacetext(message, regex(@"[eiou]", "ig"), "r")
		// all characters other than "zhrgbmna .!?-" (case-insensitive) are stripped
		message = replacetext(message, regex(@"[^zhrgbmna.!?-\s]", "ig"), "")
		// multiple spaces are replaced with a single (whitespace is trimmed)
		message = replacetext(message, regex(@"(\s+)", "g"), " ")

		var/list/old_words = splittext(message, " ")
		var/list/new_words = list()
		for(var/word in old_words)
			// lower-case "r" at the end of words replaced with "rh"
			word = replacetext(word, regex(@"\lr\b"), "rh")
			// an "a" or "A" by itself will be replaced with "hra"
			word = replacetext(word, regex(@"\b[Aa]\b"), "hra")
			new_words += word

		message = new_words.Join(" ")
		message = capitalize(message)
		speech_args[SPEECH_MESSAGE] = message

/obj/item/organ/tail/werewolf
	name = "werewolf tail"
	bodypart_overlay = /datum/bodypart_overlay/mutant/tail/werewolf
	dna_block = DNA_WEREWOLF_TAIL_BLOCK
	wag_flags = WAG_ABLE

/datum/bodypart_overlay/mutant/tail/werewolf
	feature_key = "werewolf_tail"
	color_source = ORGAN_COLOR_HAIR

/datum/bodypart_overlay/mutant/tail/werewolf/get_global_feature_list()
	return SSaccessories.tails_list_werewolf

/datum/bodypart_overlay/mutant/tail/werewolf/on_mob_insert(obj/item/organ/parent, mob/living/carbon/receiver)
	if(imprint_on_next_insertion && !receiver.dna.features["werewolf_tail"])
		receiver.dna.features["werewolf_tail"] = pick(SSaccessories.tails_list_werewolf)
		receiver.dna.update_uf_block(DNA_WEREWOLF_TAIL_BLOCK)

	return ..()

/obj/item/organ/brain/werewolf
	name = "werewolf brain"
	desc = "a strange mixture of a human and wolf brain"
	organ_traits = list(TRAIT_PRIMITIVE, TRAIT_CAN_STRIP)

/obj/item/organ/brain/werewolf/get_attacking_limb(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(target.body_position == LYING_DOWN && user.body_position == LYING_DOWN) // We're... dogfighting?!? Ba-dum tiss
		return owner.get_bodypart(BODY_ZONE_HEAD)
	return ..()
