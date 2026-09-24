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

/// Exercise Absolution through real damage, recall, power cleanup, and shared-summoner paths.
/datum/unit_test/stand_absolution/Run()
	var/mob/living/carbon/human/summoner = allocate(/mob/living/carbon/human/consistent)
	var/mob/living/basic/guardian/arrow_stand/first = make_absolution(summoner)
	var/datum/component/arrow_stand/first_component = first.GetComponent(/datum/component/arrow_stand)
	TEST_ASSERT(HAS_TRAIT(summoner, TRAIT_HANDS_BLOCKED), "Absolution must block the summoner's item use.")
	TEST_ASSERT(HAS_TRAIT(first, TRAIT_HANDS_BLOCKED), "Absolution must block the Stand's item use.")
	summoner.adjustBruteLoss(10)
	first.adjustBruteLoss(10)
	first.adjustFireLoss(10)
	TEST_ASSERT_EQUAL(summoner.getBruteLoss() + summoner.getFireLoss(), 0, "Direct and life-link damage must not bypass Absolution.")
	TEST_ASSERT(SEND_SIGNAL(summoner, COMSIG_MOB_ITEM_ATTACK, first, summoner, null) & COMPONENT_CANCEL_ATTACK_CHAIN, "Absolution must cancel item attacks.")
	TEST_ASSERT(SEND_SIGNAL(first, COMSIG_MOB_ATTACK_RANGED, summoner, null) & COMPONENT_CANCEL_ATTACK_CHAIN, "Absolution must cancel ranged attacks.")
	var/obj/structure/table/table = allocate(/obj/structure/table)
	var/table_integrity = table.get_integrity()
	first.melee_attack(table, ignore_cooldown = TRUE)
	TEST_ASSERT_EQUAL(table.get_integrity(), table_integrity, "Absolution must also block attacks on objects.")
	TEST_ASSERT(first.recall(TRUE), "Blocked hands must not prevent recall.")
	TEST_ASSERT(!HAS_TRAIT(summoner, TRAIT_GODMODE) && !HAS_TRAIT(first, TRAIT_GODMODE), "Recall must remove both sides of the shield.")
	TEST_ASSERT(!HAS_TRAIT(summoner, TRAIT_HANDS_BLOCKED) && !HAS_TRAIT(first, TRAIT_HANDS_BLOCKED), "Recall must restore item use.")
	first.manifest(TRUE)

	var/mob/living/basic/guardian/arrow_stand/second = make_absolution(summoner)
	first.recall(TRUE)
	TEST_ASSERT(HAS_TRAIT(summoner, TRAIT_GODMODE), "Recalling one Stand must preserve the other Stand's shield.")
	TEST_ASSERT(!HAS_TRAIT(first, TRAIT_HANDS_BLOCKED), "Overlapping shields must not leave the recalled Stand blocked.")
	TEST_ASSERT(HAS_TRAIT(second, TRAIT_HANDS_BLOCKED), "The remaining manifested Stand must still be blocked.")
	ADD_TRAIT(summoner, TRAIT_PACIFISM, TRAIT_SOURCE_UNIT_TESTS)
	qdel(second)
	TEST_ASSERT(!HAS_TRAIT(summoner, TRAIT_GODMODE), "Deleting the last shielding Stand must remove protection.")
	TEST_ASSERT(!HAS_TRAIT(summoner, TRAIT_HANDS_BLOCKED), "Deleting the last shielding Stand must restore hands.")
	TEST_ASSERT(HAS_TRAIT_FROM(summoner, TRAIT_PACIFISM, TRAIT_SOURCE_UNIT_TESTS), "Absolution cleanup must preserve unrelated trait sources.")
	REMOVE_TRAIT(summoner, TRAIT_PACIFISM, TRAIT_SOURCE_UNIT_TESTS)

	first.manifest(TRUE)
	first_component.clear_major_power()
	TEST_ASSERT(!HAS_TRAIT(summoner, TRAIT_GODMODE) && !HAS_TRAIT(first, TRAIT_HANDS_BLOCKED), "Removing Absolution's major power must clean its shield and restrictions.")

/datum/unit_test/stand_absolution/proc/make_absolution(mob/living/summoner)
	var/mob/living/basic/guardian/arrow_stand/guardian = allocate(/mob/living/basic/guardian/arrow_stand)
	guardian.set_summoner(summoner)
	var/obj/item/stand_arrow/arrow = allocate(/obj/item/stand_arrow)
	var/datum/stand_stats/stats = new
	var/datum/stand_power/power = new /datum/stand_power/requiem/absolution
	var/datum/component/arrow_stand/stand_component = guardian.AddComponent(/datum/component/arrow_stand, stats, power, arrow)
	stand_component.requiem = TRUE
	stand_component.setup_requiem_power()
	guardian.manifest(TRUE)
	return guardian

/datum/unit_test/stand_scout_cleanup/Run()
	var/mob/living/carbon/human/summoner = allocate(/mob/living/carbon/human/consistent)
	var/mob/living/basic/guardian/arrow_stand/guardian = allocate(/mob/living/basic/guardian/arrow_stand)
	guardian.set_summoner(summoner)
	var/obj/item/stand_arrow/arrow = allocate(/obj/item/stand_arrow)
	var/datum/stand_stats/stats = new
	var/datum/stand_power/power = new /datum/stand_power/scout
	var/datum/component/arrow_stand/stand_component = guardian.AddComponent(/datum/component/arrow_stand, stats, power, arrow)
	guardian.apply_status_effect(/datum/status_effect/guardian_scout_mode)
	guardian.manifest(TRUE)
	TEST_ASSERT(guardian.incorporeal_move, "The test must start in manifested Scout mode.")
	stand_component.clear_major_power()
	TEST_ASSERT(!guardian.incorporeal_move, "Replacing Scout must not leave Requiem able to move through walls.")
