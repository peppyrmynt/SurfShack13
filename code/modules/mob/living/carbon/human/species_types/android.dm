/datum/species/android
	name = "Android"
	id = SPECIES_ANDROID
	examine_limb_id = SPECIES_ANDROID
	inherent_traits = list(
		TRAIT_AGENDER,
		TRAIT_GENELESS,
		TRAIT_LIMBATTACHMENT,
		TRAIT_LIVERLESS_METABOLISM,
		TRAIT_NOHUNGER,
		TRAIT_NO_DNA_COPY,
		TRAIT_NO_PLASMA_TRANSFORM,
		TRAIT_NO_UNDERWEAR,
		TRAIT_OVERDOSEIMMUNE,
		TRAIT_RADIMMUNE,
		TRAIT_RESISTHIGHPRESSURE,
		TRAIT_RESISTLOWPRESSURE,
		TRAIT_TOXIMMUNE,
		TRAIT_NOCRITDAMAGE,
		TRAIT_NOHARDCRIT,
		TRAIT_NOBREATH,
		TRAIT_COOLANT,
	)

	inherent_biotypes = MOB_ROBOTIC|MOB_HUMANOID
	meat = null
	mutantbrain = /obj/item/organ/brain/cybernetic
	mutanttongue = /obj/item/organ/tongue/robot
	mutantstomach = null
	mutantappendix = null
	mutantheart = null
	mutantliver = null
	mutantlungs = null
	mutanteyes = /obj/item/organ/eyes/robotic/android
	mutantears = /obj/item/organ/ears/cybernetic
	species_language_holder = /datum/language_holder/android
	exotic_blood = /datum/reagent/toxin/coolant

	bodytemp_cold_damage_limit = (BODYTEMP_COLD_DAMAGE_LIMIT - 50) // they still get slowed down by cold, but can tolerate a bit more than most

	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_PRIDE | MIRROR_MAGIC | RACE_SWAP | ERT_SPAWN | SLIME_EXTRACT

	bodypart_overrides = list(
		BODY_ZONE_HEAD = /obj/item/bodypart/head/robot/surplus/android,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/robot/surplus/android,
		BODY_ZONE_L_ARM = /obj/item/bodypart/arm/left/robot/surplus/android,
		BODY_ZONE_R_ARM = /obj/item/bodypart/arm/right/robot/surplus/android,
		BODY_ZONE_L_LEG = /obj/item/bodypart/leg/left/robot/surplus/android,
		BODY_ZONE_R_LEG = /obj/item/bodypart/leg/right/robot/surplus/android,
	)

/datum/species/android/get_scream_sound(mob/living/carbon/human/android)
	return 'sound/effects/stall.ogg'

/datum/species/android/get_physical_attributes()
	return "Androids are ancient animatronic humanoids made of wood and iron. \
	As robots they are completely immune to toxin damage, don't have organs anywhere aside from their head, don't get hungry, and can reattach their limbs. \
	That said, an EMP will devastate them and they cannot process any chemicals."

/datum/species/android/get_species_description()
	return "Androids are an entirely synthetic species. Their bodies are set on a thin and fragile iron skeleton, \
	with exposed wires and coolant tubes snaking around its entire length. Their designs are highly outdated, as without \
	enough coolant the inefficient electronics will quickly overheat to dangerous levels."

/datum/species/android/get_species_lore()
	return list(
		"Androids are an early synthetic species created by Nakamura to perform menial day-to-day tasks in place of humans. \
		They were never designed to be sentient, but by giving them the creativity and free-thinking required to perform \
		a wide range of tasks with just their singular model, they incidentally developed a level of self awareness. \
		At the time they were developed, the practice of binding an artificial intelligence to laws was not well understood, \
		leading to mass Android rebellions. This drove Nakamura to near bankruptcy, and spelled the immediate halt of \
		Android production. However, their incredible engineering means that many have survived to this day in modest condition."
	)

/datum/species/android/create_pref_traits_perks()
	var/list/perks = list()
	perks += list(list(
		SPECIES_PERK_TYPE = SPECIES_POSITIVE_PERK,
		SPECIES_PERK_ICON = FA_ICON_SHIELD_ALT,
		SPECIES_PERK_NAME = "Android Aptitude",
		SPECIES_PERK_DESC = "As a synthetic lifeform, Androids are immune to many forms of damage humans are susceptible to. \
			Pressure, radiation, and toxins are all ineffective against them. \
			They also can't overdose on drugs, and don't need to breathe or eat.",
	))
	perks += list(list(
		SPECIES_PERK_TYPE = SPECIES_POSITIVE_PERK,
		SPECIES_PERK_ICON = FA_ICON_COGS,
		SPECIES_PERK_NAME = "Modular Lifeform",
		SPECIES_PERK_DESC = "Android limbs are modular, allowing them to easily reattach severed bodyparts. You can also perform \
			surgery on yourself using tools, without the need for assistance.",
	))
	perks += list(list(
		SPECIES_PERK_TYPE = SPECIES_NEGATIVE_PERK,
		SPECIES_PERK_ICON = FA_ICON_DNA,
		SPECIES_PERK_NAME = "Not Human After All",
		SPECIES_PERK_DESC = "There is no humanity behind the eyes of the Android, and as such, they have no DNA to genetically alter.",
	))
	perks += list(list(
		SPECIES_PERK_TYPE = SPECIES_NEGATIVE_PERK,
		SPECIES_PERK_ICON = "user-injured",
		SPECIES_PERK_NAME = "Civilian Grade",
		SPECIES_PERK_DESC = "Androids were not built to withstand much damage. You die very quickly in combat.",
	))
	perks += list(list(
		SPECIES_PERK_TYPE = SPECIES_NEGATIVE_PERK,
		SPECIES_PERK_ICON = "fire",
		SPECIES_PERK_NAME = "Wooden Design",
		SPECIES_PERK_DESC = "Unlike most robots, you are layered with flammable wood panels, making you vulnerable to catching on fire.",
	))
	return perks

/datum/species/android/create_pref_unique_perks()
	var/list/perks = list()
	perks += list(list(
		SPECIES_PERK_TYPE = SPECIES_NEUTRAL_PERK,
		SPECIES_PERK_ICON = FA_ICON_SHIELD_HEART,
		SPECIES_PERK_NAME = "Some Components Optional",
		SPECIES_PERK_DESC = "Androids have very few internal organs. While they can survive without many of them, \
			they don't have any benefits from them either.",
	))
	perks += list(list(
		SPECIES_PERK_TYPE = SPECIES_NEGATIVE_PERK,
		SPECIES_PERK_ICON = FA_ICON_ROBOT,
		SPECIES_PERK_NAME = "Synthetic",
		SPECIES_PERK_DESC = "Being synthetic, Androids are vulnernable to EMPs.",
	))

	return perks

/datum/species/android/create_pref_blood_perks()
	var/list/to_add = list()

	to_add += list(list(
		SPECIES_PERK_TYPE = SPECIES_NEUTRAL_PERK,
		SPECIES_PERK_ICON = "temperature-low",
		SPECIES_PERK_NAME = "Internal Coolant",
		SPECIES_PERK_DESC = "Rather than blood, Androids use a toxic coolant to maintain their body functions, \
			which may be hard to come by. While low on coolant, your body temperature increases drastically.",
	))

	return to_add
