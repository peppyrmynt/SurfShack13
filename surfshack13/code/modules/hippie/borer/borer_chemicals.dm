// Chemicals a cortical borer can secrete into its host.
// Hippie's bicaridine, kelotane, charcoal and crayon powder no longer exist, so their modern replacements are used.

GLOBAL_LIST_INIT(borer_chems, init_borer_chems())

/proc/init_borer_chems()
	var/list/chems = list()
	for(var/chem_type in subtypesof(/datum/borer_chem))
		chems[chem_type] = new chem_type()
	return chems

/datum/borer_chem
	/// Shown to the borer
	var/name = "chemical"
	var/chem_desc = "This is a chemical."
	/// Reagent injected into the host
	var/datum/reagent/reagent_type
	/// Chemical points it costs
	var/chemuse = 30
	/// Units injected
	var/quantity = 10

/datum/borer_chem/epinephrine
	name = "Epinephrine"
	reagent_type = /datum/reagent/medicine/epinephrine
	chem_desc = "Stabilizes critical condition and slowly restores oxygen damage. If overdosed, it will deal toxin and oxyloss damage."

/datum/borer_chem/leporazine
	name = "Leporazine"
	reagent_type = /datum/reagent/medicine/leporazine
	chem_desc = "This keeps a patient's body temperature stable. High doses can allow short periods of unprotected EVA."
	chemuse = 75

/datum/borer_chem/mannitol
	name = "Mannitol"
	reagent_type = /datum/reagent/medicine/mannitol
	chem_desc = "Heals brain damage."

/datum/borer_chem/libital
	name = "Libital"
	reagent_type = /datum/reagent/medicine/c2/libital
	chem_desc = "Heals brute damage."

/datum/borer_chem/aiuri
	name = "Aiuri"
	reagent_type = /datum/reagent/medicine/c2/aiuri
	chem_desc = "Heals burn damage."

/datum/borer_chem/multiver
	name = "Multiver"
	reagent_type = /datum/reagent/medicine/c2/multiver
	chem_desc = "Heals toxin damage and slowly removes other chemicals."

/datum/borer_chem/methamphetamine
	name = "Methamphetamine"
	reagent_type = /datum/reagent/drug/methamphetamine
	chem_desc = "Reduces stun times, increases stamina and run speed while dealing brain damage. If overdosed it will deal toxin and brain damage."
	chemuse = 50
	quantity = 9

/datum/borer_chem/salbutamol
	name = "Salbutamol"
	reagent_type = /datum/reagent/medicine/salbutamol
	chem_desc = "Heals suffocation damage."

/datum/borer_chem/space_drugs
	name = "Space Drugs"
	reagent_type = /datum/reagent/drug/space_drugs
	chem_desc = "Get your host high as a kite."
	chemuse = 75

/datum/borer_chem/colorful_powder
	name = "Colorful Powder"
	reagent_type = /datum/reagent/colorful_reagent/powder
	chem_desc = "Change the colour of your host."
	chemuse = 5

/datum/borer_chem/ethanol
	name = "Ethanol"
	reagent_type = /datum/reagent/consumable/ethanol
	chem_desc = "The most potent alcoholic 'beverage', with the fastest toxicity."
	chemuse = 50

/datum/borer_chem/rezadone
	name = "Rezadone"
	reagent_type = /datum/reagent/medicine/rezadone
	chem_desc = "Heals cellular damage."

// ---- Secrete Chemicals window ----

/mob/living/basic/cortical_borer/ui_state(mob/user)
	return GLOB.always_state

/mob/living/basic/cortical_borer/ui_status(mob/user, datum/ui_state/state)
	if(user != src || stat != CONSCIOUS || !host)
		return UI_CLOSE
	return UI_INTERACTIVE

/mob/living/basic/cortical_borer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BorerChemicals")
		ui.open()

/mob/living/basic/cortical_borer/ui_data(mob/user)
	var/list/data = list()
	data["chemicals"] = round(chemicals)
	data["max_chemicals"] = 250 // BORER_MAX_CHEMICALS, which borer.dm undefines
	data["docile"] = docile
	data["host_name"] = host?.real_name
	var/list/chems = list()
	for(var/chem_type in GLOB.borer_chems)
		var/datum/borer_chem/chem = GLOB.borer_chems[chem_type]
		chems += list(list(
			"id" = "[chem_type]",
			"name" = chem.name,
			"desc" = chem.chem_desc,
			"cost" = chem.chemuse,
			"units" = chem.quantity,
		))
	data["chems"] = chems
	return data

/mob/living/basic/cortical_borer/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(action != "secrete")
		return
	var/chem_type = text2path(params["id"])
	var/datum/borer_chem/chem = GLOB.borer_chems[chem_type]
	if(!chem || !can_use_ability(chem_cost = chem.chemuse))
		return TRUE
	host.reagents.add_reagent(chem.reagent_type, chem.quantity)
	chemicals -= chem.chemuse
	to_chat(src, span_userdanger("You squirt a measure of [chem.name] from your reservoirs into [host]'s bloodstream."))
	log_combat(src, host, "injected [chem.name] into")
	return TRUE
