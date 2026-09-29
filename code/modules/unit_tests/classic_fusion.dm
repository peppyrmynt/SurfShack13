/// Regression coverage for the restored reaction and existing portable processing.
/datum/unit_test/classic_fusion
	abstract_type = /datum/unit_test/classic_fusion

/datum/unit_test/classic_fusion/proc/fuel(datum/gas_mixture/air)
	air.gases.Cut()
	air.assert_gases(/datum/gas/plasma, /datum/gas/hydrogen, /datum/gas/tritium)
	air.gases[/datum/gas/plasma][MOLES] = 1000
	air.gases[/datum/gas/hydrogen][MOLES] = 1000
	air.gases[/datum/gas/tritium][MOLES] = 100
	air.temperature = 20000

/datum/unit_test/classic_fusion/reaction/Run()
	var/datum/gas_mixture/air = allocate(/datum/gas_mixture, 1000)
	fuel(air)
	TEST_ASSERT(air.react(null) & REACTING, "Classic fusion must run through the normal gas reaction scheduler")
	TEST_ASSERT_EQUAL(air.gases[/datum/gas/tritium][MOLES], 99, "Fusion must consume one mole of tritium")
	TEST_ASSERT(air.analyzer_results?["fusion"], "Successful fusion must record a persistent analyzer reading")
	TEST_ASSERT(air.gases[/datum/gas/bz][MOLES] > 0, "Low tier must create BZ")
	TEST_ASSERT(air.temperature > 20000, "The stable test mixture must heat up")
	var/list/reading = air.analyzer_results["fusion"]
	air.temperature = T20C
	air.react(null)
	TEST_ASSERT_EQUAL(air.analyzer_results["fusion"], reading, "A later non-fusion tick must preserve the last reading")
	var/list/parsed = gas_mixture_parser(air, "Test")
	TEST_ASSERT_EQUAL(parsed["fusion"], reading, "The analyzer UI must receive the persistent reading")

	// The late classic hydrogen requirement is essential, as is the temperature gate.
	fuel(air)
	air.gases[/datum/gas/hydrogen][MOLES] = 249
	air.react(null)
	TEST_ASSERT_EQUAL(air.gases[/datum/gas/tritium][MOLES], 100, "Fusion below the hydrogen threshold")
	fuel(air)
	air.temperature = CLASSIC_FUSION_TEMPERATURE_THRESHOLD - 1
	air.react(null)
	TEST_ASSERT_EQUAL(air.gases[/datum/gas/tritium][MOLES], 100, "Fusion below the temperature threshold")
	fuel(air)
	air.assert_gas(/datum/gas/hypernoblium)
	air.gases[/datum/gas/hypernoblium][MOLES] = REACTION_OPPRESSION_THRESHOLD
	TEST_ASSERT_EQUAL(air.react(null), STOP_REACTIONS, "Hyper-noblium must still suppress fusion")

/datum/unit_test/classic_fusion/products/Run()
	var/datum/gas_reaction/fusion/reaction = new
	var/list/expected = list(
		"low" = list(/datum/gas/bz = 5, /datum/gas/carbon_dioxide = 85),
		"mid" = list(/datum/gas/nitrium = 20, /datum/gas/nitrous_oxide = 60),
		"high" = list(/datum/gas/nitrium = 5, /datum/gas/pluoxium = 55),
		"super" = list(/datum/gas/tritium = 40),
	)
	for(var/tier in expected)
		var/datum/gas_mixture/air = allocate(/datum/gas_mixture)
		reaction.produce_gases(air, tier, 100)
		var/list/products = expected[tier]
		for(var/gas in products)
			// Fractional yields have single-precision rounding in BYOND.
			TEST_ASSERT(abs(air.gases[gas][MOLES] - products[gas]) < 0.001, "Incorrect [tier] tier product yield for [gas]")
	TEST_ASSERT_EQUAL(classic_fusion_tier(5), "low", "Low tier boundary")
	TEST_ASSERT_EQUAL(classic_fusion_tier(20), "mid", "Mid tier boundary")
	TEST_ASSERT_EQUAL(classic_fusion_tier(50), "high", "High tier boundary")
	TEST_ASSERT_EQUAL(classic_fusion_tier(51), "super", "Super tier boundary")
	qdel(reaction)

/datum/unit_test/classic_fusion/portable_holders/Run()
	for(var/machine_type in list(/obj/machinery/portable_atmospherics/canister, /obj/machinery/portable_atmospherics/pump, /obj/machinery/portable_atmospherics/scrubber))
		var/obj/machinery/portable_atmospherics/machine = allocate(machine_type)
		// Nullspace suppresses physical effects while exercising the real processing chain.
		machine.moveToNullspace()
		fuel(machine.air_contents)
		machine.air_contents.temperature = 1e9
		var/integrity = machine.get_integrity()
		TEST_ASSERT(!machine.take_atmos_damage(), "[machine_type] must not take internal pressure/heat damage")
		TEST_ASSERT_EQUAL(machine.get_integrity(), integrity, "Internal gas damaged [machine_type]")
		// An excited device must still react; this used to short-circuit air_contents.react().
		machine.excited = TRUE
		machine.process_atmos()
		TEST_ASSERT(machine.air_contents.analyzer_results?["fusion"], "[machine_type] did not fuse during process_atmos()")
		TEST_ASSERT_EQUAL(machine.get_integrity(), integrity, "Unshielded processing damaged [machine_type]")
		machine.take_damage(10, BRUTE, MELEE)
		TEST_ASSERT(machine.get_integrity() < integrity, "External damage must still damage [machine_type]")

/datum/unit_test/classic_fusion/locations/Run()
	var/datum/gas_reaction/fusion/reaction = new
	var/turf/open/floor = run_loc_floor_bottom_left
	TEST_ASSERT_EQUAL(reaction.reaction_turf(floor), floor, "Open-turf location")
	var/obj/machinery/portable_atmospherics/pump/pump = allocate(/obj/machinery/portable_atmospherics/pump, floor)
	TEST_ASSERT_EQUAL(reaction.reaction_turf(pump), floor, "Portable holder location")
	var/datum/pipeline/network = allocate(/datum/pipeline)
	TEST_ASSERT_NULL(reaction.reaction_turf(network), "Empty pipelines must not pick from an empty list")
	var/obj/machinery/atmospherics/pipe/smart/pipe = allocate(/obj/machinery/atmospherics/pipe/smart, floor)
	network.members += pipe
	TEST_ASSERT_EQUAL(reaction.reaction_turf(network), floor, "Pipenet location")
	network.members.Cut()
	var/obj/machinery/atmospherics/components/unary/portables_connector/connector = allocate(/obj/machinery/atmospherics/components/unary/portables_connector, floor)
	network.other_atmos_machines += connector
	TEST_ASSERT_EQUAL(reaction.reaction_turf(network), floor, "Component-only pipenet location")
	network.other_atmos_machines.Cut()
	var/datum/gas_mixture/air = allocate(/datum/gas_mixture, 1000)
	fuel(air)
	TEST_ASSERT(air.react(network) & REACTING, "Fusion chemistry must work even in a temporarily empty pipeline")
	qdel(reaction)

/datum/unit_test/classic_fusion/ordinary_reactions/Run()
	for(var/fuel_type in list(/datum/gas/plasma, /datum/gas/tritium))
		var/datum/gas_mixture/air = allocate(/datum/gas_mixture)
		air.assert_gases(fuel_type, /datum/gas/oxygen)
		air.gases[fuel_type][MOLES] = 10
		air.gases[/datum/gas/oxygen][MOLES] = 100
		air.temperature = 1500
		TEST_ASSERT(air.react(null) & REACTING, "Ordinary [fuel_type] combustion must still run")
		TEST_ASSERT(air.gases[fuel_type][MOLES] < 10, "Ordinary [fuel_type] combustion must consume fuel")
		TEST_ASSERT_NULL(air.analyzer_results, "Ordinary fires must not report fusion")
		var/datum/gas_mixture/receiver = allocate(/datum/gas_mixture)
		var/total_before = air.total_moles()
		receiver.merge(air.remove_ratio(0.5))
		TEST_ASSERT(abs(air.total_moles() + receiver.total_moles() - total_before) < 0.001, "Transfers must conserve moles")
