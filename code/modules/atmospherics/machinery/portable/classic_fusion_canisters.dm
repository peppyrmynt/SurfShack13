// SURFSHACK EDIT: admin-spawnable classic fusion presets for local testing.
// These inherit the existing fusion_test canister safety limits and appear in the Game Panel object spawner.
// Each mix keeps plasma equal to all non-plasma fuel combined for peak classic-fusion efficiency.

/obj/machinery/portable_atmospherics/canister/fusion_test/classic_low
	name = "classic fusion test canister - low"
	desc = "Admin testing canister preset for stable low-tier classic plasma-CO2-tritium fusion."

/obj/machinery/portable_atmospherics/canister/fusion_test/classic_low/create_gas()
	air_contents.gases.Cut()
	air_contents.add_gases(/datum/gas/plasma, /datum/gas/carbon_dioxide, /datum/gas/tritium)
	air_contents.gases[/datum/gas/plasma][MOLES] = 3250
	air_contents.gases[/datum/gas/carbon_dioxide][MOLES] = 250
	air_contents.gases[/datum/gas/tritium][MOLES] = 3000
	air_contents.temperature = 20000
	SSair.start_processing_machine(src)

/obj/machinery/portable_atmospherics/canister/fusion_test/classic_mid
	name = "classic fusion test canister - mid"
	desc = "Admin testing canister preset for mid-tier classic plasma-CO2-tritium fusion."

/obj/machinery/portable_atmospherics/canister/fusion_test/classic_mid/create_gas()
	air_contents.gases.Cut()
	air_contents.add_gases(/datum/gas/plasma, /datum/gas/carbon_dioxide, /datum/gas/tritium)
	air_contents.gases[/datum/gas/plasma][MOLES] = 9250
	air_contents.gases[/datum/gas/carbon_dioxide][MOLES] = 250
	air_contents.gases[/datum/gas/tritium][MOLES] = 9000
	air_contents.temperature = 20000
	SSair.start_processing_machine(src)

/obj/machinery/portable_atmospherics/canister/fusion_test/classic_high
	name = "classic fusion test canister - high"
	desc = "Admin testing canister preset for high-tier classic plasma-CO2-tritium fusion."

/obj/machinery/portable_atmospherics/canister/fusion_test/classic_high/create_gas()
	air_contents.gases.Cut()
	air_contents.add_gases(/datum/gas/plasma, /datum/gas/carbon_dioxide, /datum/gas/tritium)
	air_contents.gases[/datum/gas/plasma][MOLES] = 25250
	air_contents.gases[/datum/gas/carbon_dioxide][MOLES] = 250
	air_contents.gases[/datum/gas/tritium][MOLES] = 25000
	air_contents.temperature = 20000
	SSair.start_processing_machine(src)

/obj/machinery/portable_atmospherics/canister/fusion_test/classic_super
	name = "classic fusion test canister - super"
	desc = "Admin testing canister preset for super-tier classic plasma-CO2-tritium fusion. Extremely dangerous once processing begins."

/obj/machinery/portable_atmospherics/canister/fusion_test/classic_super/create_gas()
	air_contents.gases.Cut()
	air_contents.add_gases(/datum/gas/plasma, /datum/gas/carbon_dioxide, /datum/gas/tritium)
	air_contents.gases[/datum/gas/plasma][MOLES] = 45250
	air_contents.gases[/datum/gas/carbon_dioxide][MOLES] = 250
	air_contents.gases[/datum/gas/tritium][MOLES] = 45000
	air_contents.temperature = 20000
	SSair.start_processing_machine(src)
