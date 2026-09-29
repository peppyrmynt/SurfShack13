/// Flood Infectors should target an occupied mech, wound its pilot, and release on resistance.
/datum/unit_test/flood_mecha_pilot

/datum/unit_test/flood_mecha_pilot/Run()
	var/obj/vehicle/sealed/mecha/mech = allocate(/obj/vehicle/sealed/mecha/ripley)
	var/mob/living/basic/flood/infestor/infector = allocate(/mob/living/basic/flood/infestor)
	var/datum/targeting_strategy/basic/flood/infestor/targeting = allocate(/datum/targeting_strategy/basic/flood/infestor)
	infector.forceMove(get_step(mech, EAST))
	TEST_ASSERT(!targeting.can_attack(infector, mech), "The Infector targeted an empty mech.")

	var/mob/living/carbon/human/consistent/pilot = allocate(/mob/living/carbon/human/consistent)
	mech.mob_enter(pilot, silent = TRUE)
	TEST_ASSERT(mech.is_occupant(pilot), "The pilot did not enter the mech.")
	TEST_ASSERT(targeting.can_attack(infector, mech), "The Infector cannot target an occupied mech.")
	TEST_ASSERT(infector.melee_attack(mech), "The Infector failed to latch onto the occupied mech.")
	TEST_ASSERT_EQUAL(infector.latched_host, pilot, "The Infector latched onto the wrong occupant.")
	TEST_ASSERT_EQUAL(infector.buckled, mech, "The Infector did not stay exposed on the mech exterior.")

	infector.latch_hit(pilot, infector.latch_generation)
	TEST_ASSERT(pilot.getBruteLoss() > 0, "The pilot took no damage from the Infector.")
	SEND_SIGNAL(pilot, COMSIG_LIVING_RESIST, pilot)
	TEST_ASSERT(!infector.latched_host && !infector.buckled, "Resisting did not remove the Infector from the mech.")
	TEST_ASSERT(mech.is_occupant(pilot), "The pilot was ejected when resisting the Infector.")
	TEST_ASSERT(infector.melee_attack(mech), "The Infector could not latch again after being shaken off.")
	mech.mob_exit(pilot, silent = TRUE)
	TEST_ASSERT(!infector.latched_host && !infector.buckled, "The Infector remained attached after the pilot exited.")
	TEST_ASSERT(!targeting.can_attack(infector, mech), "The Infector still targeted the empty mech.")

/// Converting a pilot must eject their body and leave the mech for other players to use.
/datum/unit_test/flood_mecha_pilot_infection

/datum/unit_test/flood_mecha_pilot_infection/Run()
	var/obj/vehicle/sealed/mecha/mech = allocate(/obj/vehicle/sealed/mecha/ripley)
	var/mob/living/carbon/human/consistent/pilot = allocate(/mob/living/carbon/human/consistent)
	var/mob/living/basic/flood/infestor/infector = allocate(/mob/living/basic/flood/infestor)
	mech.mob_enter(pilot, silent = TRUE)
	infector.forceMove(get_step(mech, EAST))
	TEST_ASSERT(infector.melee_attack(mech), "The Infector failed to latch onto the pilot's mech.")

	pilot.death()
	infector.finish_latch(pilot, infector.latch_generation)
	TEST_ASSERT(!QDELETED(mech), "Infecting the pilot deleted the mech.")
	TEST_ASSERT(!length(mech.occupants), "The converted pilot is still registered as a mech occupant.")
	var/mob/living/basic/flood/combat_form/human/converted = locate(/mob/living/basic/flood/combat_form/human) in get_turf(mech)
	TEST_ASSERT(converted && converted.loc == get_turf(mech), "The new Flood was not created outside the mech.")
