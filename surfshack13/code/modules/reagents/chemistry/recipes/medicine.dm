/datum/chemical_reaction/medicine/naniteremover
	results = list(/datum/reagent/medicine/naniteremover = 4)
	required_reagents = list(/datum/reagent/aluminium = 1, /datum/reagent/iron = 1, /datum/reagent/bromine = 1, /datum/reagent/silicon = 1)
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_OTHER

/datum/chemical_reaction/medicine/nanitebooster
	results = list(/datum/reagent/medicine/nanitebooster = 2)
	required_reagents = list(/datum/reagent/medicine/naniteremover = 1, /datum/reagent/fuel/oil = 1)
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_OTHER
