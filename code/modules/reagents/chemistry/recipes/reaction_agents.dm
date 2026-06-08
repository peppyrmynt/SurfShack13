/datum/chemical_reaction/basic_buffer
	results = list(/datum/reagent/reaction_agent/basic_buffer = 10)
	required_reagents = list(/datum/reagent/ammonia = 3, /datum/reagent/chlorine = 2, /datum/reagent/hydrogen = 2, /datum/reagent/oxygen = 2) //vagely NH4OH + NH4Cl buffer
	mix_message = "The solution fizzes in the beaker."
	//FermiChem vars:
	required_temp = 100
	optimal_temp = 200
	overheat_temp = NO_OVERHEAT
	optimal_ph_min = 0
	optimal_ph_max = 14
	determin_ph_range = 0
	temp_exponent_factor = 4
	ph_exponent_factor = 0
	thermic_constant = 0
	H_ion_release = 0.01
	rate_up_lim = 20
	purity_min = 0
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_CHEMICAL

/datum/chemical_reaction/acidic_buffer
	results = list(/datum/reagent/reaction_agent/acidic_buffer = 10)
	required_reagents = list(/datum/reagent/sodium = 2, /datum/reagent/hydrogen = 2, /datum/reagent/consumable/ethanol = 2, /datum/reagent/water = 2)
	mix_message = "The solution froths in the beaker."
	required_temp = 100
	optimal_temp = 200
	overheat_temp = NO_OVERHEAT
	optimal_ph_min = 0
	optimal_ph_max = 14
	determin_ph_range = 0
	temp_exponent_factor = 4
	ph_exponent_factor = 0
	thermic_constant = 0
	H_ion_release = -0.01
	rate_up_lim = 20
	purity_min = 0
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_CHEMICAL

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////// Example competitive reaction (REACTION_COMPETITIVE)  //////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


/datum/chemical_reaction/prefactor_a
	results = list(/datum/reagent/prefactor_a = 5)
	required_reagents = list(/datum/reagent/phenol = 1, /datum/reagent/consumable/ethanol = 3, /datum/reagent/toxin/plasma = 1)
	mix_message = "The solution's viscosity increases."
	required_temp = 100
	optimal_temp = 300
	overheat_temp = 500
	optimal_ph_min = 0
	optimal_ph_max = 14
	determin_ph_range = 0
	temp_exponent_factor = 1
	ph_exponent_factor = 0
	thermic_constant = -300
	H_ion_release = 0
	rate_up_lim = 4
	purity_min = 0.25
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_CHEMICAL


/datum/chemical_reaction/prefactor_b
	results = list(/datum/reagent/prefactor_b = 5)
	required_reagents = list(/datum/reagent/acetone = 1, /datum/reagent/consumable/ethanol = 3, /datum/reagent/toxin/plasma = 1)
	mix_message = "The solution's viscosity decreases."
	mix_sound = 'sound/effects/chemistry/bluespace.ogg' //Maybe use this elsewhere instead
	required_temp = 100
	optimal_temp = 300
	overheat_temp = 500
	optimal_ph_min = 0
	optimal_ph_max = 14
	determin_ph_range = 0
	temp_exponent_factor = 1
	ph_exponent_factor = 2
	thermic_constant = -300
	H_ion_release = -0.02
	rate_up_lim = 6
	purity_min = 0.35
	reaction_tags = REACTION_TAG_EASY | REACTION_TAG_CHEMICAL

/datum/chemical_reaction/prefactor_b/overheated(datum/reagents/holder, datum/equilibrium/equilibrium, step_volume_added)
	. = ..()
	explode_shockwave(holder, equilibrium)
	var/vol = max(20, holder.total_volume/5) //Not letting you have more than 5
	clear_reagents(holder, vol)//Lest we explode forever

/datum/chemical_reaction/prefactor_b/overly_impure(datum/reagents/holder, datum/equilibrium/equilibrium, step_volume_added)
	explode_fire(holder, equilibrium)
	var/vol = max(20, holder.total_volume/5) //Not letting you have more than 5
	clear_reagents(holder, vol)

////////////////////////////////End example/////////////////////////////////////////////////////////////////////////////
