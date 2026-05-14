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
	desc = "The nanites purge toxins and chemicals from the host's bloodstream. Doesn't consume nanites until the host is poisoned."
	id = "purging_nanites"
	category = list(NANITE_CATEGORY_MEDICAL)
	program_type = /datum/nanite_program/purging

/datum/design/nanites/purging_advanced
	name = "Selective Blood Purification"
	desc = "The nanites purge toxins and dangerous chemicals from the host's bloodstream, while ignoring beneficial chemicals. \
			The added processing power required to analyze the chemicals severely increases the nanite consumption rate. \
			Doesn't consume nanites should the host not be poisoned."
	id = "purging_plus_nanites"
	category = list(NANITE_CATEGORY_MEDICAL)
	program_type = /datum/nanite_program/purging_advanced

/datum/design/nanites/brain_heal
	name = "Neural Regeneration"
	desc = "The nanites fix neural connections in the host's brain, reversing brain damage and minor traumas. Doesn't consume nanites unless you HAVE brain damage."
	id = "brainheal_nanites"
	category = list(NANITE_CATEGORY_MEDICAL)
	program_type = /datum/nanite_program/brain_heal

/datum/design/nanites/brain_heal_advanced
	name = "Neural Reimaging"
	desc = "The nanites are able to backup and restore the host's neural connections, potentially replacing entire chunks of missing or damaged brain matter. \
			Doesn't consume nanites if the host's brain isn't damaged in any capacity."
	id = "brainheal_plus_nanites"
	category = list(NANITE_CATEGORY_MEDICAL)
	program_type = /datum/nanite_program/brain_heal_advanced

/datum/design/nanites/blood_restoring
	name = "Blood Regeneration"
	desc = "The nanites stimulate and boost blood cell production in the host. Automatically de-activates should the host have 'Safe' blood levels."
	id = "bloodheal_nanites"
	category = list(NANITE_CATEGORY_MEDICAL)
	program_type = /datum/nanite_program/blood_restoring

/datum/design/nanites/repairing
	name = "Mechanical Repair"
	desc = "The nanites fix damage in the host's mechanical limbs. Automatically turns itself off if the host's mechanical limbs aren't damaged."
	id = "repairing_nanites"
	category = list(NANITE_CATEGORY_MEDICAL)
	program_type = /datum/nanite_program/repairing

/datum/design/nanites/defib
	name = "Defibrillation"
	desc = "The nanites, when triggered, send a defibrillating shock to the host's heart."
	id = "defib_nanites"
	category = list(NANITE_CATEGORY_MEDICAL)
	program_type = /datum/nanite_program/defib

/datum/design/nanites/corpsepreserve
	name = "Corpse Preservation"
	desc = "The nanites will synthesize a small amount of formaldehyde upon the host's death."
	id = "corpsepreserve_nanites"
	program_type = /datum/nanite_program/corpsepreserve
	category = list(NANITE_CATEGORY_MEDICAL)

/datum/design/nanites/naniteresus
	name = "Nanite Resurrection"
	desc = "The nanites expend a large portion of themselves to create a strange reagent while the host is dead, which may result in their resurrection. Only works on animals."
	id = "naniteresus_nanites"
	program_type = /datum/nanite_program/naniteresus
	category = list(NANITE_CATEGORY_MEDICAL)
