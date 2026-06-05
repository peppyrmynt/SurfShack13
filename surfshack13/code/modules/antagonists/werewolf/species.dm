/datum/species/werewolf
	name = "Werewolf"
	id = SPECIES_WEREWOLF
	inherent_traits = list(
		TRAIT_NO_UNDERWEAR,
		TRAIT_USES_SKINTONES,
		TRAIT_NO_AUGMENTS,
		//TRAIT_IGNOREDAMAGESLOWDOWN,
		TRAIT_PUSHIMMUNE,
		TRAIT_STUNIMMUNE,
		TRAIT_PRIMITIVE,
		TRAIT_CAN_STRIP,
		TRAIT_CHUNKYFINGERS,
	)
	mutanttongue = /obj/item/organ/tongue/werewolf
	mutantears = /obj/item/organ/ears/werewolf
	mutanteyes = /obj/item/organ/eyes/werewolf
	mutantbrain = /obj/item/organ/brain/werewolf
	mutantliver = /obj/item/organ/liver/werewolf
	mutant_organs = list(
		/obj/item/organ/tail/werewolf = "Werewolf",
	)
	skinned_type = /obj/item/stack/sheet/animalhide/human
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_MAGIC | MIRROR_PRIDE | ERT_SPAWN | RACE_SWAP | SLIME_EXTRACT
	no_equip_flags = ITEM_SLOT_MASK | ITEM_SLOT_OCLOTHING | ITEM_SLOT_GLOVES | ITEM_SLOT_FEET | ITEM_SLOT_ICLOTHING | ITEM_SLOT_SUITSTORE

	bodypart_overrides = list(
		BODY_ZONE_HEAD = /obj/item/bodypart/head/werewolf,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/werewolf,
		BODY_ZONE_L_ARM = /obj/item/bodypart/arm/left/werewolf,
		BODY_ZONE_R_ARM = /obj/item/bodypart/arm/right/werewolf,
		BODY_ZONE_L_LEG = /obj/item/bodypart/leg/left/werewolf,
		BODY_ZONE_R_LEG = /obj/item/bodypart/leg/right/werewolf,
	)

/obj/item/organ/brain/werewolf/get_attacking_limb(mob/living/carbon/human/target)
	name = "werewolf brain"
	desc = "a strange mixture of a human and wolf brain"
	organ_traits = list(TRAIT_PRIMITIVE, TRAIT_CAN_STRIP)

	if(target.body_position == LYING_DOWN)
		return owner.get_bodypart(BODY_ZONE_HEAD)
	return ..()

/datum/species/werewolf/prepare_human_for_preview(mob/living/carbon/human/human)
	human.hair_color = "#bb9966" // brown
	human.hairstyle = "Business Hair"

/datum/species/werewolf/get_species_description()
	return "N/A"

/datum/species/werewolf/create_pref_unique_perks()
	var/list/to_add = list()

	to_add += list(
		list(
			SPECIES_PERK_TYPE = SPECIES_POSITIVE_PERK,
			SPECIES_PERK_ICON = "paw",
			SPECIES_PERK_NAME = "Lupine Regeneration",
			SPECIES_PERK_DESC = "Werewolves slowly recover from brute and burn damage on their own, and will regrow their limbs with time.",
		),
		list(
			SPECIES_PERK_TYPE = SPECIES_NEGATIVE_PERK,
			SPECIES_PERK_ICON = "paw",
			SPECIES_PERK_NAME = "Primal Primate",
			SPECIES_PERK_DESC = "Werewolves are monstrous humans, and can't do most things a human can do. Computers are impossible, \
				complex machines are right out, and most clothes don't fit your larger form.",
		),
		list(
			SPECIES_PERK_TYPE = SPECIES_NEGATIVE_PERK,
			SPECIES_PERK_ICON = "assistive-listening-systems",
			SPECIES_PERK_NAME = "Sensitive Hearing",
			SPECIES_PERK_DESC = "Werewolves are more sensitive to loud sounds, such as flashbangs.",
		))

	return to_add

/datum/species/werewolf/spec_life(mob/living/carbon/human/werewolf, seconds_per_tick, times_fired)
	. = ..()
	if(werewolf.stat == DEAD)
		return

	var/need_mob_update = FALSE
	need_mob_update += werewolf.heal_overall_damage(brute = 1 * seconds_per_tick, burn = 1 * seconds_per_tick, updating_health = FALSE, required_bodytype = BODYTYPE_ORGANIC)
	if(need_mob_update)
		werewolf.updatehealth()
	if(prob(2))
		werewolf.regenerate_limbs()

/datum/species/werewolf/get_scream_sound(mob/living/carbon/human/human)
	if(human.physique == MALE)
		return pick(
			'surfshack13/sound/mobs/humanoid/werewolf/howl1.ogg',
			'surfshack13/sound/mobs/humanoid/werewolf/howl2.ogg',
			'surfshack13/sound/mobs/humanoid/werewolf/howl3.ogg',
		)

	return pick(
		'surfshack13/sound/mobs/humanoid/werewolf/howl4.ogg',
		'surfshack13/sound/mobs/humanoid/werewolf/howl5.ogg',
		'surfshack13/sound/mobs/humanoid/werewolf/howl6.ogg',
	)
