/datum/design/nanites/regenerative
	name = "Accelerated Regeneration"
	desc = "The nanites boost the host's natural regeneration, increasing their healing speed."
	id = "regenerative_nanites"
	category = list(NANITE_CATEGORY_MEDICAL)
	program_type = /datum/nanite_program/regenerative

/datum/design/nanites/regenerative_advanced
	name = "Bio-Reconstruction"
	desc = "The nanites manually repair and replace organic cells, acting much faster than normal regeneration. \
			However, this program cannot detect the difference between harmed and unharmed, causing it to consume nanites even if it has no effect."
	id = "regenerative_plus_nanites"
	category = list(NANITE_CATEGORY_MEDICAL)
	program_type = /datum/nanite_program/regenerative_advanced

/datum/design/nanites/temperature
	name = "Temperature Adjustment"
	desc = "The nanites adjust the host's internal temperature to an ideal level."
	id = "temperature_nanites"
	category = list(NANITE_CATEGORY_MEDICAL)
	program_type = /datum/nanite_program/temperature

/datum/design/nanites/purging
	name = "Blood Purification"
	desc = "The nanites purge toxins and chemicals from the host's bloodstream."
	id = "purging_nanites"
	category = list(NANITE_CATEGORY_MEDICAL)
	program_type = /datum/nanite_program/purging

/datum/design/nanites/purging_advanced
	name = "Selective Blood Purification"
	desc = "The nanites purge toxins and dangerous chemicals from the host's bloodstream, while ignoring beneficial chemicals. \
			The added processing power required to analyze the chemicals severely increases the nanite consumption rate."
	id = "purging_plus_nanites"
	category = list(NANITE_CATEGORY_MEDICAL)
	program_type = /datum/nanite_program/purging_advanced

/datum/design/nanites/brain_heal
	name = "Neural Regeneration"
	desc = "The nanites fix neural connections in the host's brain, reversing brain damage and minor traumas."
	id = "brainheal_nanites"
	category = list(NANITE_CATEGORY_MEDICAL)
	program_type = /datum/nanite_program/brain_heal

/datum/design/nanites/brain_heal_advanced
	name = "Neural Reimaging"
	desc = "The nanites are able to backup and restore the host's neural connections, potentially replacing entire chunks of missing or damaged brain matter."
	id = "brainheal_plus_nanites"
	category = list(NANITE_CATEGORY_MEDICAL)
	program_type = /datum/nanite_program/brain_heal_advanced

/datum/design/nanites/blood_restoring
	name = "Blood Regeneration"
	desc = "The nanites stimulate and boost blood cell production in the host."
	id = "bloodheal_nanites"
	category = list(NANITE_CATEGORY_MEDICAL)
	program_type = /datum/nanite_program/blood_restoring

/datum/design/nanites/repairing
	name = "Mechanical Repair"
	desc = "The nanites fix damage in the host's mechanical limbs."
	id = "repairing_nanites"
	category = list(NANITE_CATEGORY_MEDICAL)
	program_type = /datum/nanite_program/repairing

/datum/design/nanites/defib
	name = "Defibrillation"
	desc = "The nanites, when triggered, send a defibrillating shock to the host's heart."
	id = "defib_nanites"
	category = list(NANITE_CATEGORY_MEDICAL)
	program_type = /datum/nanite_program/defib


/datum/design/nanites/organrepair
	name = "Organ Repair"
	desc = "The nanites begin repairing the host's organs should they be damaged."
	id = "organrepair_nanites"
	program_type = /datum/nanite_program/organrepair
	category = list(NANITE_CATEGORY_MEDICAL)

/datum/design/nanites/corpsepreserve
	name = "Corpse Preservation"
	desc = "The nanites will synthesize a small amount of formaldehyde upon the host's death."
	id = "corpsepreserve_nanites"
	program_type = /datum/nanite_program/corpsepreserve
	category = list(NANITE_CATEGORY_MEDICAL)

/datum/design/nanites/critstable
	name = "Critical Stabilization"
	desc = "The nanites will synthesize epinephrine when the host enters a critical state."
	id = "critstable_nanites"
	program_type = /datum/nanite_program/critstable
	category = list(NANITE_CATEGORY_MEDICAL)

/datum/design/nanites/naniteresus
	name = "Nanite Resurrection"
	desc = "The nanites expend a large portion of themselves to create a strange reagent while the host is dead, which may result in their resurrection."
	id = "naniteresus_nanites"
	program_type = /datum/nanite_program/naniteresus
	category = list(NANITE_CATEGORY_MEDICAL)

/datum/design/nanites/synthflesh
	name = "Corpse Repair"
	desc = "The nanites will slowly produce synthetic flesh over time, and use that to both patch the host's injuries and unhusk them."
	id = "synthflesh_nanites"
	program_type = /datum/nanite_program/synthflesh
	category = list(NANITE_CATEGORY_MEDICAL)

/datum/design/nanites/mendingbrute
	name = "Brute Mending"
	desc = "The nanites quickly and efficiently repair blunt force, slashes, and punctures within the host."
	id = "mendingbrute_nanites"
	program_type = /datum/nanite_program/mendingbrute
	category = list(NANITE_CATEGORY_MEDICAL)

/datum/design/nanites/mendingburn
	name = "Burn Mending"
	desc = "The nanites quickly and efficiently repair burns, frostbite, and electric scars within the host."
	id = "mendingburn_nanites"
	program_type = /datum/nanite_program/mendingburn
	category = list(NANITE_CATEGORY_MEDICAL)

/datum/design/nanites/mendingtoxin
	name = "Toxin Cleansing"
	desc = "The nanites run through the host's bloodstream and re-construct cells killed by toxins."
	id = "mendingtoxin_nanites"
	program_type = /datum/nanite_program/mendingtoxin
	category = list(NANITE_CATEGORY_MEDICAL)

/datum/design/nanites/selfresp
	name = "Self-Respiration"
	desc = "The nanites synthesize breathable air within the host's lungs and blood, negating the need to breathe."
	id = "selfresp_nanites"
	program_type = /datum/nanite_program/selfresp
	category = list(NANITE_CATEGORY_MEDICAL)

/datum/design/nanites/repairingplus
	name = "Synthetic Regeneration"
	desc = "The nanites repair damage within robotic organisms or limbs including both denting and melting."
	id = "repairingplus_nanites"
	program_type = /datum/nanite_program/repairingplus
	category = list(NANITE_CATEGORY_MEDICAL)

/datum/design/nanites/woundfixer
	name = "Wound-Tending"
	desc = "The nanites slowly and methodically scan the host for major injuries and will slowly fix any wounds detected such as broken bones or hairline fractures -- without ever needing surgery."
	id = "woundfixer_nanites"
	program_type = /datum/nanite_program/woundfixer
	category = list(NANITE_CATEGORY_MEDICAL)
