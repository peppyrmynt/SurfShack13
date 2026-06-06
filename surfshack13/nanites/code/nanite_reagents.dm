/datum/reagent/medicine/naniteremover
	name = "Anti-Nanolytic Agent"
	description = "Creates an environment that in unsuitable for nanites, causing them to rapidly break down."
	color = "#ff00d4"
	metabolization_rate = 2.5 * REAGENTS_METABOLISM // 5 units takes 250 nanites
	taste_description = "acidic oil"
	var/nanite_reduction = -50

/datum/reagent/medicine/naniteremover/on_mob_life(mob/living/carbon/my_carbon)
	var/datum/component/nanites/our_nanites = my_carbon.GetComponent(/datum/component/nanites)
	if(our_nanites)
		our_nanites.adjust_nanites(null, nanite_reduction)
	return ..()

/datum/reagent/medicine/nanitebooster
	name = "Nanolytic Agent"
	description = "A synthesized compound of metallic material often produced by nanites during construction of new nanites, it's effectively nanite food. Increases nanite replication speed."
	color = "#FFE5FA"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM // 1 unit = 10 nanites
	taste_description = "metallic slurry"
	var/nanite_boost = 1

/datum/reagent/medicine/nanitebooster/on_mob_life(mob/living/carbon/my_carbon)
	var/datum/component/nanites/our_nanites = my_carbon.GetComponent(/datum/component/nanites)
	if(our_nanites)
		our_nanites.adjust_nanites(null, nanite_boost)
	return ..()

/obj/item/reagent_containers/pill/naniteremover
	name = "anti-nanite pill"
	desc = "Used to quickly purge someone's nanite supply. Often used in emergencies should a nanite's code be corrupted or sabotaged."
	icon_state = "pill10"
	volume = 10
	list_reagents = list(/datum/reagent/medicine/naniteremover = 10)
	rename_with_volume = TRUE

/obj/item/reagent_containers/pill/naniteremover/better
	volume = 20
	list_reagents = list(/datum/reagent/medicine/naniteremover = 20)

/obj/item/reagent_containers/pill/nanitebooster
	name = "nanite booster"
	desc = "A metallic-tasting pill used to increase one's nanite saturation."
	icon_state = "pill10"
	volume = 10
	list_reagents = list(/datum/reagent/medicine/nanitebooster = 10)
	rename_with_volume = TRUE

/obj/item/reagent_containers/cup/bottle/naniteremover
	name = "anti-nanite bottle"
	desc = "A small bottle of anti-nanite slurry. Tastes awful."
	list_reagents = list(/datum/reagent/medicine/naniteremover = 30)

/obj/item/reagent_containers/cup/bottle/nanitebooster
	name = "nanite booster bottle"
	desc = "A small bottle of nanite food. Tastes like iron."
	list_reagents = list(/datum/reagent/medicine/nanitebooster = 30)
