/// Reproduce the state seen by the delayed completion callback, without waiting 50 seconds.
/datum/unit_test/stand_requiem/Run()
	var/mob/living/carbon/human/summoner = allocate(/mob/living/carbon/human/consistent)
	var/mob/living/basic/guardian/arrow_stand/guardian = allocate(/mob/living/basic/guardian/arrow_stand)
	guardian.set_summoner(summoner)
	guardian.manifest(TRUE)
	var/datum/client_interface/mock_client = allocate(/datum/client_interface)
	guardian.mock_client = mock_client
	mock_client.mob = guardian
	var/obj/item/stand_arrow/arrow = allocate(/obj/item/stand_arrow)
	var/datum/stand_stats/stats = new
	var/datum/stand_power/power = new /datum/stand_power/hand
	var/datum/component/arrow_stand/stand_component = guardian.AddComponent(/datum/component/arrow_stand, stats, power, arrow)

	TEST_ASSERT(arrow.valid_requiem_target(guardian), "An eligible Stand must be able to start Requiem.")
	TEST_ASSERT(!arrow.valid_requiem_target(guardian, expected_transforming = TRUE), "An idle Stand must not pass completion validation.")
	arrow.used = TRUE
	arrow.target_ref = WEAKREF(guardian)
	arrow.forceMove(guardian)
	stand_component.transforming = TRUE
	TEST_ASSERT(!arrow.valid_requiem_target(guardian), "A transforming Stand must reject a second arrow.")
	TEST_ASSERT(arrow.valid_requiem_target(guardian, expected_transforming = TRUE), "A transforming Stand must pass completion validation.")

	arrow.finish_requiem()
	TEST_ASSERT(stand_component.requiem, "The completion callback must evolve the Stand instead of dropping the arrow.")
	TEST_ASSERT(!stand_component.transforming, "Completion must clear the temporary transformation state.")
	TEST_ASSERT(istype(stand_component.power, /datum/stand_power/requiem), "Completion must replace the normal major with a Requiem power.")
	TEST_ASSERT(QDELETED(arrow), "Successful Requiem must consume the arrow.")
	TEST_ASSERT(findtext(guardian.real_name, " Requiem"), "Completion must rename the Stand.")
	TEST_ASSERT(locate(/datum/action/cooldown/mob_cooldown/guardian_alarm_snare) in guardian.actions, "Requiem must grant Surveillance Snares.")
	TEST_ASSERT(locate(/datum/action/cooldown/mob_cooldown/guardian_bluespace_beacon) in guardian.actions, "Requiem must grant Teleportation Pad.")
	TEST_ASSERT(stats.damage > 1 && stats.defense > 1 && stats.speed > 1 && stats.potential > 1 && stats.range > 1, "Requiem must upgrade every stat.")
	mock_client.mob = null
	guardian.mock_client = null
