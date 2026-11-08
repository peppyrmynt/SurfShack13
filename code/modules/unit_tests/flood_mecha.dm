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

/// Heat and burn projectiles remove biomass without destroying the original floor.
/datum/unit_test/flood_floor_burns

/datum/unit_test/flood_floor_burns/Run()
	var/turf/site = run_loc_floor_bottom_left
	var/original_floor_type = site.type
	var/original_baseturfs = json_encode(site.baseturfs)
	var/turf/open/floor/flood_biomass/biomass = grow_flood_floor(site)
	TEST_ASSERT_NOTNULL(biomass, "The biomass floor could not grow.")
	biomass.atmos_expose(biomass.return_air(), 600)
	site = locate(site.x, site.y, site.z)
	TEST_ASSERT_EQUAL(site.type, original_floor_type, "Moderate heat did not restore the original floor.")
	TEST_ASSERT_EQUAL(json_encode(site.baseturfs), original_baseturfs, "Burning biomass damaged the underlying floor layers.")
	biomass = grow_flood_floor(site)
	var/obj/projectile/beam/laser/laser = allocate(/obj/projectile/beam/laser)
	biomass.bullet_act(laser)
	site = locate(site.x, site.y, site.z)
	TEST_ASSERT_EQUAL(site.type, original_floor_type, "A laser hit did not burn away the biomass.")

/// A midround ghost gets a placement view, reserves leadership, and becomes the chosen Overseer.
/datum/unit_test/flood_midround_placement
	var/turf/placed_floor
	var/mob/living/basic/flood/overseer/placed_overseer
	var/list/original_blob_spawns
	var/test_z
	var/original_station_flag
	var/area/test_area
	var/original_area_flags

/datum/unit_test/flood_midround_placement/Destroy()
	placed_overseer?.mind?.remove_antag_datum(/datum/antagonist/flood)
	QDEL_NULL(placed_overseer)
	if(istype(placed_floor, /turf/open/floor/flood_biomass))
		placed_floor.ScrapeAway(flags = CHANGETURF_INHERIT_AIR)
	if(test_z)
		GLOB.station_levels_cache[test_z] = original_station_flag
	if(test_area)
		test_area.area_flags = original_area_flags
	if(original_blob_spawns)
		GLOB.blobstart = original_blob_spawns
	return ..()

/datum/unit_test/flood_midround_placement/Run()
	// Treat the isolated test room as a station and give it a known Blob spawn.
	test_z = run_loc_floor_bottom_left.z
	original_station_flag = is_station_level(test_z)
	GLOB.station_levels_cache[test_z] = TRUE
	test_area = get_area(run_loc_floor_bottom_left)
	original_area_flags = test_area.area_flags
	test_area.area_flags |= BLOBS_ALLOWED
	original_blob_spawns = GLOB.blobstart
	GLOB.blobstart = list(run_loc_floor_bottom_left)
	var/datum/dynamic_ruleset/midround/from_ghosts/flood/ruleset = allocate(/datum/dynamic_ruleset/midround/from_ghosts/flood)
	var/mob/dead/observer/applicant = allocate(/mob/dead/observer)
	var/mob/eye/flood_spawn/placement = ruleset.generate_ruleset_body(applicant)
	TEST_ASSERT(istype(placement), "The Flood midround did not create a placement view for a ghost without a mind.")
	allocated += placement
	TEST_ASSERT_EQUAL(get_turf(placement), run_loc_floor_bottom_left, "The placement view did not start at the existing Blob spawn.")
	TEST_ASSERT(!flood_has_living_overseer(), "The midround spawned an Overseer before the player chose a location.")
	TEST_ASSERT(!can_form_flood_overseer(), "An incoming Overseer did not reserve the leadership slot.")
	TEST_ASSERT(can_form_flood_overseer(placement), "The placement view was blocked by its own leadership reservation.")
	TEST_ASSERT(locate(/datum/action/flood_place_overseer) in placement.actions, "The placement view has no Spawn Overseer action.")
	TEST_ASSERT(placement.placement_error(null), "The placement view accepted an invalid location.")
	GLOB.station_levels_cache[test_z] = FALSE
	TEST_ASSERT(placement.placement_error(run_loc_floor_bottom_left), "The placement view allowed spawning on an off-station level.")
	GLOB.station_levels_cache[test_z] = TRUE
	// Possession normally initializes the fresh mind through Login; there is no client in a unit test.
	placement.mind_initialize()
	ruleset.finish_setup(placement, 1)
	var/datum/mind/selected_mind = placement.mind
	TEST_ASSERT(selected_mind.has_antag_datum(/datum/antagonist/flood), "The chosen ghost did not receive the Flood antagonist.")
	var/turf/valid_floor = get_step(run_loc_floor_bottom_left, EAST)
	TEST_ASSERT(placement.Move(valid_floor, EAST), "The placement view could not scout away from its initial spawn.")
	var/obj/structure/closet/blocker = allocate(/obj/structure/closet, valid_floor)
	TEST_ASSERT(placement.placement_error(valid_floor), "The placement view accepted a blocked tile.")
	qdel(blocker)
	placed_overseer = placement.place_overseer()
	placed_floor = locate(valid_floor.x, valid_floor.y, valid_floor.z)
	TEST_ASSERT_NOTNULL(placed_overseer, "The placement view did not spawn an Overseer on a valid tile.")
	TEST_ASSERT_EQUAL(placed_overseer.mind, selected_mind, "The selected player's mind did not reach the Overseer.")
	TEST_ASSERT(istype(placed_floor, /turf/open/floor/flood_biomass), "The Overseer did not start on biomass.")
	TEST_ASSERT(QDELETED(placement), "The placement view remained after spawning its Overseer.")
	TEST_ASSERT(!can_form_flood_overseer(), "The hive allowed a second Overseer after placement.")

/// Flood midround eligibility must agree with its zero-day preference and ghost-only poll.
/datum/unit_test/flood_midround_eligibility

/datum/unit_test/flood_midround_eligibility/Run()
	var/datum/dynamic_ruleset/midround/from_ghosts/flood/ruleset = allocate(/datum/dynamic_ruleset/midround/from_ghosts/flood)
	TEST_ASSERT_EQUAL(ruleset.minimum_required_age, 0, "Flood incorrectly inherited the seven-day midround age restriction.")
	TEST_ASSERT(!ruleset.restrict_ghost_roles, "Flood requires a previous crew assignment to enter its ghost poll.")
	TEST_ASSERT_EQUAL(ruleset.required_type, /mob/dead/observer, "Flood is no longer a ghost-spawned Overseer ruleset.")

/// The Overseer buds infectors at a separate 30-second rate; constructors can become carriers.
/datum/unit_test/flood_form_creation_actions

/datum/unit_test/flood_form_creation_actions/Run()
	var/mob/living/basic/flood/overseer/overseer = allocate(/mob/living/basic/flood/overseer)
	var/mob/living/basic/flood/constructor/constructor = allocate(/mob/living/basic/flood/constructor)
	var/datum/action/cooldown/flood/create_infestor/infector_action = locate(/datum/action/cooldown/flood/create_infestor) in overseer.actions
	TEST_ASSERT_NOTNULL(infector_action, "The Overseer has no Create Flood Infector action.")
	TEST_ASSERT_EQUAL(infector_action.cooldown_time, 30 SECONDS, "The Overseer's Infector cooldown is not 30 seconds.")
	TEST_ASSERT(locate(/datum/action/cooldown/flood/become_carrier) in constructor.actions, "The Constructor cannot become a Carrier.")
	var/turf/spawn_turf = get_turf(overseer)
	TEST_ASSERT(overseer.create_infestor(), "The Overseer did not create an Infector.")
	var/mob/living/basic/flood/infestor/infector = locate(/mob/living/basic/flood/infestor) in spawn_turf
	TEST_ASSERT_NOTNULL(infector, "Creating an Infector did not produce a Flood unit.")
	TEST_ASSERT_EQUAL(overseer.next_infestor, world.time + 30 SECONDS, "The Overseer did not start its 30-second spawn cooldown.")
	TEST_ASSERT(!overseer.create_infestor(), "The Overseer created another Infector during its cooldown.")
	qdel(infector)

/// Human implants, including their own state and storage, survive corpse conversion.
/datum/unit_test/flood_infection_transfers_implants

/datum/unit_test/flood_infection_transfers_implants/Run()
	var/mob/living/carbon/human/consistent/host = allocate(/mob/living/carbon/human/consistent)
	var/mob/living/basic/flood/infestor/infector = allocate(/mob/living/basic/flood/infestor)
	var/obj/item/implant/tracking/tracker = allocate(/obj/item/implant/tracking)
	var/obj/item/implant/storage/bag = allocate(/obj/item/implant/storage)
	var/obj/item/implant/mindshield/shield = allocate(/obj/item/implant/mindshield)
	TEST_ASSERT(tracker.implant(host, silent = TRUE), "The test host could not receive a tracker implant.")
	TEST_ASSERT(bag.implant(host, silent = TRUE), "The test host could not receive a storage implant.")
	TEST_ASSERT(shield.implant(host, silent = TRUE), "The test host could not receive a mindshield implant.")
	var/datum/storage/original_storage = bag.atom_storage
	var/turf/conversion_turf = get_turf(host)
	host.death()
	infector.forceMove(get_step(host, NORTH))
	TEST_ASSERT(infector.melee_attack(host), "The Infector could not latch onto the implanted corpse.")
	TEST_ASSERT_EQUAL(infector.corpse_infection_time, 12 SECONDS, "Corpse infection does not take twelve seconds.")
	TEST_ASSERT(infector.convert_host(host), "The implanted corpse was not converted.")
	var/mob/living/basic/flood/combat_form/human/converted = locate(/mob/living/basic/flood/combat_form/human) in conversion_turf
	TEST_ASSERT_NOTNULL(converted, "The infection did not create a Flood Combat.")
	allocated += converted
	for(var/obj/item/implant/surviving_implant in list(tracker, bag, shield))
		TEST_ASSERT_EQUAL(surviving_implant.imp_in, converted, "An implant still points at the deleted human.")
		TEST_ASSERT(surviving_implant in converted.implants, "An implant was not retained by Flood Combat.")
		TEST_ASSERT_EQUAL(surviving_implant.loc, converted, "An implant was dropped instead of inherited.")
	TEST_ASSERT_EQUAL(bag.atom_storage, original_storage, "The storage implant lost its existing storage datum.")
	TEST_ASSERT(HAS_TRAIT(converted, TRAIT_MINDSHIELD), "The transferred mindshield no longer protects its host.")
