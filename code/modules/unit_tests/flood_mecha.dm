/// Infectors damage occupied mechs without latching onto or converting their pilots.
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
	var/initial_integrity = mech.get_integrity()
	TEST_ASSERT(infector.melee_attack(mech), "The Infector failed to attack the occupied mech.")
	TEST_ASSERT(mech.get_integrity() < initial_integrity, "The mech took no damage from the Infector.")
	TEST_ASSERT_EQUAL(pilot.getBruteLoss(), 0, "The pilot was injured through the mech.")
	TEST_ASSERT(!infector.latched_host && !infector.buckled, "The Infector latched onto the mech or pilot.")
	pilot.death()
	TEST_ASSERT(!QDELETED(mech), "The pilot dying destroyed the mech.")
	TEST_ASSERT(!locate(/mob/living/basic/flood/combat_form/human) in get_turf(mech), "The pilot was converted inside the mech.")

/// A second infector can still hurt a host already occupied by another infector.
/datum/unit_test/flood_second_infestor_attack

/datum/unit_test/flood_second_infestor_attack/Run()
	var/mob/living/carbon/human/consistent/host = allocate(/mob/living/carbon/human/consistent)
	var/mob/living/basic/flood/infestor/first = allocate(/mob/living/basic/flood/infestor)
	var/mob/living/basic/flood/infestor/second = allocate(/mob/living/basic/flood/infestor)
	first.forceMove(get_step(host, NORTH))
	second.forceMove(get_step(host, EAST))
	TEST_ASSERT(first.melee_attack(host), "The first Infector could not latch on.")
	var/initial_damage = host.getBruteLoss()
	TEST_ASSERT(second.melee_attack(host), "The second Infector could not attack an occupied host.")
	TEST_ASSERT_EQUAL(host.getBruteLoss() - initial_damage, 5, "The second Infector did not deal 5 brute.")
	TEST_ASSERT(!second.latched_host && !second.buckled, "The second Infector latched on despite an existing Infector.")

/// Destroying a growth removes the floor seed beneath it.
/datum/unit_test/flood_growth_removes_root

/datum/unit_test/flood_growth_removes_root/Run()
	var/turf/site = run_loc_floor_bottom_left
	var/turf/open/floor/flood_biomass/seed = grow_flood_floor(site)
	TEST_ASSERT_NOTNULL(seed, "The Flood floor seed could not grow.")
	var/obj/structure/flood_biomass/tiny/growth = new(seed)
	TEST_ASSERT(seed in growth.owned_seeds, "The growth did not register its floor seed.")
	var/seed_x = seed.x
	var/seed_y = seed.y
	var/seed_z = seed.z
	qdel(growth)
	TEST_ASSERT(!istype(locate(seed_x, seed_y, seed_z), /turf/open/floor/flood_biomass), "The biomass seed persisted after its growth was destroyed.")
