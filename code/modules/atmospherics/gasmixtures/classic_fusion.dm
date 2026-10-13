// SURFSHACK EDIT: restored classic gas-mixture fusion, independent of HFR.
// Formula: tgstation 1471cd16956e0c3e671b076595722798f62d637f.
// Tier power/products/effects: efe3f1e9de1494cb8780c4916900eca160f6626e.
// This is intentionally a hybrid: tiers act on the final formula's waste yield,
// rather than consuming the entire mixture as the older one-shot reaction did.

/datum/gas_reaction/fusion
	priority_group = PRIORITY_PRE_FORMATION
	name = "Plasmic Fusion"
	id = "fusion"
	desc = "Chaotic plasma-CO2 fusion catalyzed by tritium. Produces heat or absorbs it, tier-dependent gases, radiation, nuclear particles and electrical arcs."

/datum/gas_reaction/fusion/init_reqs()
	requirements = list(
		"MIN_TEMP" = CLASSIC_FUSION_TEMPERATURE_THRESHOLD,
		/datum/gas/tritium = CLASSIC_FUSION_TRITIUM_MOLES_USED,
		/datum/gas/plasma = CLASSIC_FUSION_MOLE_THRESHOLD,
		/datum/gas/carbon_dioxide = CLASSIC_FUSION_MOLE_THRESHOLD,
	)

/datum/gas_reaction/fusion/init_factors()
	factor = list(
		"Temperature" = "Requires at least 9000 K. Exothermic heating stops above 100 million K; endothermic reactions can still cool the mixture.",
		GAS_PLASMA = "Requires at least 250 mol. Plasma and carbon dioxide follow a chaotic kicked-rotator reaction.",
		GAS_CO2 = "Requires at least 250 mol.",
		GAS_TRITIUM = "Consumes 1 mol per successful reaction.",
		"Products" = "Low: BZ and carbon dioxide. Mid: nitrium and nitrous oxide. High: nitrium and pluoxium. Super: tritium. Yield scales with the absolute reaction energy.",
		"Dangers" = "Radiation, nuclear particles and Tesla arcs. High and super tiers can generate explosive shockwaves. Hyper-noblium suppresses this reaction.",
	)

/// Resolve real locations, including component-only networks and empty pipenets.
/datum/gas_reaction/fusion/proc/reaction_turf(datum/holder)
	if(istype(holder, /datum/pipeline))
		var/datum/pipeline/network = holder
		var/list/candidates = length(network.members) ? network.members : network.other_atmos_machines
		if(length(candidates))
			return get_turf(pick(candidates))
		return null
	if(isatom(holder))
		return get_turf(holder)
	return null

/// Separate classic weights preserve the final pre-HFR dynamics without changing HFR metadata.
/datum/gas_reaction/fusion/proc/gas_power(datum/gas_mixture/air)
	var/power = 0
	for(var/gas_id in air.gases)
		var/list/gas_entry = air.gases[gas_id]
		if(!gas_entry)
			continue
		var/list/gas_meta = gas_entry[GAS_META]
		var/weight = gas_meta ? gas_meta[META_GAS_FUSION_POWER] : 0
		// These gases changed fusion weights after this reaction was removed. Keep the old
		// values local to gas-mixture fusion so modern/HFR gas metadata remains untouched.
		switch(gas_id)
			if(/datum/gas/carbon_dioxide)
				weight = 3
			if(/datum/gas/tritium)
				weight = 1
			if(/datum/gas/nitrous_oxide)
				weight = 0
			if(/datum/gas/pluoxium)
				weight = 10
			if(/datum/gas/hydrogen, /datum/gas/hypernoblium)
				weight = 0
			// Nitrium superseded stimulum/nitryl; use its current weight of 7.
		power += weight * gas_entry[MOLES]
	return power

/// Original efficiency/mediation power ratio. Clamp negative modern gas weights to low tier.
/datum/gas_reaction/fusion/proc/power_ratio(datum/gas_mixture/air, power)
	var/list/plasma_entry = air.gases[/datum/gas/plasma]
	if(!plasma_entry)
		return 0
	var/plasma = plasma_entry[MOLES]
	var/total_moles = air.total_moles()
	var/non_plasma = total_moles - plasma
	if(non_plasma <= 0 || total_moles <= 0)
		return 0
	var/list/plasma_meta = plasma_entry[GAS_META]
	if(!plasma_meta)
		return 0
	var/mediation = 80 * (air.heat_capacity() - plasma * plasma_meta[META_GAS_SPECIFIC_HEAT]) / non_plasma
	if(mediation <= 0)
		return 0
	var/differential = (plasma - non_plasma) / total_moles
	var/efficiency = 60 ** (-(differential ** 2) / 0.6)
	return max(efficiency * power / mediation, 0)

/proc/classic_fusion_tier(power)
	if(power > CLASSIC_FUSION_SUPER_THRESHOLD)
		return "super"
	if(power > CLASSIC_FUSION_HIGH_THRESHOLD)
		return "high"
	if(power > CLASSIC_FUSION_MID_THRESHOLD)
		return "mid"
	return "low"

/datum/gas_reaction/fusion/react(datum/gas_mixture/air, datum/holder)
	// The reaction scheduler caches temperature before the first reaction. Recheck it here.
	if(!air || air.volume <= 0 || air.temperature < CLASSIC_FUSION_TEMPERATURE_THRESHOLD)
		return NO_REACTION
	var/list/cached_gases = air.gases
	// Reactions can be invoked directly by unit tests or callers outside the scheduler.
	// Never assume init_reqs() has already guaranteed that these entries exist.
	var/list/plasma_entry = cached_gases[/datum/gas/plasma]
	var/list/carbon_dioxide_entry = cached_gases[/datum/gas/carbon_dioxide]
	var/list/tritium_entry = cached_gases[/datum/gas/tritium]
	if(!plasma_entry || !carbon_dioxide_entry || !tritium_entry)
		return NO_REACTION
	if(plasma_entry[MOLES] < CLASSIC_FUSION_MOLE_THRESHOLD || carbon_dioxide_entry[MOLES] < CLASSIC_FUSION_MOLE_THRESHOLD || tritium_entry[MOLES] < CLASSIC_FUSION_TRITIUM_MOLES_USED)
		return NO_REACTION
	var/old_heat_capacity = air.heat_capacity()
	var/initial_plasma = plasma_entry[MOLES]
	var/initial_carbon_dioxide = carbon_dioxide_entry[MOLES]
	var/scale_factor = air.volume / PI
	var/toroidal_size = 2 * PI
	var/power = gas_power(air)
	var/instability = MODULUS((power * 0.003) ** 2, toroidal_size)
	var/tier_power = power_ratio(air, power)
	var/tier = classic_fusion_tier(tier_power)
	var/plasma = (initial_plasma - CLASSIC_FUSION_MOLE_THRESHOLD) / scale_factor
	var/carbon_dioxide = (initial_carbon_dioxide - CLASSIC_FUSION_MOLE_THRESHOLD) / scale_factor

	// Classic kicked-rotator formula using carbon dioxide as the second reactant.
	plasma = MODULUS(plasma - instability * sin(TODEGREES(carbon_dioxide)), toroidal_size)
	carbon_dioxide = MODULUS(carbon_dioxide - plasma, toroidal_size)
	var/new_plasma = plasma * scale_factor + CLASSIC_FUSION_MOLE_THRESHOLD
	var/new_carbon_dioxide = carbon_dioxide * scale_factor + CLASSIC_FUSION_MOLE_THRESHOLD
	var/reaction_energy = (initial_plasma - new_plasma) * CLASSIC_FUSION_BINDING_ENERGY
	if(instability < CLASSIC_FUSION_ENDOTHERMALITY)
		reaction_energy = max(reaction_energy, 0)
	else if(reaction_energy < 0)
		reaction_energy *= sqrt(instability - CLASSIC_FUSION_ENDOTHERMALITY)
	if(air.thermal_energy() + reaction_energy < 0)
		return NO_REACTION

	plasma_entry[MOLES] = new_plasma
	carbon_dioxide_entry[MOLES] = new_carbon_dioxide
	tritium_entry[MOLES] -= CLASSIC_FUSION_TRITIUM_MOLES_USED
	// The older reaction consumed ALL gas at once. Apply its product fractions to
	// the final reaction's waste budget instead, retaining sustained fusion.
	var/waste = CLASSIC_FUSION_TRITIUM_MOLES_USED * abs(reaction_energy) * 1e-10
	produce_gases(air, tier, waste)

	var/new_heat_capacity = air.heat_capacity()
	if(new_heat_capacity > MINIMUM_HEAT_CAPACITY && (air.temperature <= CLASSIC_FUSION_MAXIMUM_TEMPERATURE || reaction_energy <= 0))
		air.temperature = clamp((air.temperature * old_heat_capacity + reaction_energy) / new_heat_capacity, TCMB, INFINITY)

	LAZYINITLIST(air.analyzer_results)
	air.analyzer_results[id] = list("power" = tier_power, "tier" = tier, "instability" = instability, "energy" = reaction_energy)
	LAZYINITLIST(air.reaction_results)
	air.reaction_results[type] = CLASSIC_FUSION_TRITIUM_MOLES_USED
	var/turf/location = reaction_turf(holder)
	if(location && reaction_energy)
		fusion_effects(location, tier_power, instability, reaction_energy)
	// Even a zero-energy step consumes tritium and changes the phase-space state.
	return REACTING

/datum/gas_reaction/fusion/proc/produce_gases(datum/gas_mixture/air, tier, waste)
	switch(tier)
		if("super")
			air.assert_gas(/datum/gas/tritium)
			air.gases[/datum/gas/tritium][MOLES] += waste * 0.40
		if("high")
			// Nitrium is SurfShack's successor to stimulum; do not resurrect its old physiology.
			air.assert_gases(/datum/gas/nitrium, /datum/gas/pluoxium)
			air.gases[/datum/gas/nitrium][MOLES] += waste * 0.05
			air.gases[/datum/gas/pluoxium][MOLES] += waste * 0.55
		if("mid")
			// Nitrium also replaces the removed nitryl gas.
			air.assert_gases(/datum/gas/nitrium, /datum/gas/nitrous_oxide)
			air.gases[/datum/gas/nitrium][MOLES] += waste * 0.20
			air.gases[/datum/gas/nitrous_oxide][MOLES] += waste * 0.60
		else
			air.assert_gases(/datum/gas/bz, /datum/gas/carbon_dioxide)
			air.gases[/datum/gas/bz][MOLES] += waste * 0.05
			air.gases[/datum/gas/carbon_dioxide][MOLES] += waste * 0.85

/datum/gas_reaction/fusion/proc/fusion_effects(turf/location, power, instability, reaction_energy)
	var/tier = classic_fusion_tier(power)
	var/zap_range = 3
	var/particle_factor = 1
	var/danger_chance = power * 5
	var/shockwave = FALSE
	switch(tier)
		if("mid")
			zap_range = 5
			particle_factor = 2
			danger_chance = power * 2
		if("high")
			zap_range = 7
			particle_factor = 3
			danger_chance = power
			shockwave = TRUE
		if("super")
			zap_range = 9
			particle_factor = 4
			danger_chance = 100
			shockwave = TRUE
	var/dangerous_event = prob(danger_chance)
	if(dangerous_event)
		if(shockwave)
			// The old fifth argument was flash radius, NOT the current flame radius.
			explosion(location, light_impact_range = 5, flash_range = min(power, 50), adminlog = TRUE)
		playsound(location, 'sound/effects/supermatter.ogg', 100, FALSE)
	else
		playsound(location, 'sound/effects/phasein.ogg', 75, FALSE)

	// Modern radiation uses range/penetration/chance, not the old strength parameter.
	// Preserve instability-dependent radiation, safely handling the stable zero limit.
	var/rad_power = instability > 0 ? max(1500 - 1000 / instability, 0) : 0
	if(dangerous_event)
		rad_power = max(rad_power, 15000 * power / (power + 30))
	if(rad_power > 0)
		radiation_pulse(location, max_range = zap_range, threshold = 0.3, chance = min(100, rad_power / 15))
	var/zap_power = 50000 * power / (power + 75) + 1000
	// The modern default cutoff is 400 kJ, above every historical fusion zap.
	tesla_zap(location, zap_range = zap_range, power = zap_power, cutoff = 1000, zap_flags = ZAP_FUSION_FLAGS)
	for(var/particle in 1 to rand(3, 6) * particle_factor)
		location.fire_nuclear_particle()
	// Final classic's extra particle is exothermic only; avoid its endothermic singularity.
	if(reaction_energy > 0 && prob(100 * reaction_energy / (reaction_energy + CLASSIC_FUSION_BINDING_ENERGY)))
		location.fire_nuclear_particle()
