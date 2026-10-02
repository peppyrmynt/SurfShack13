// Core #undefs these after its own tests, so modular tests bring their own copies
#define TEST_ASSERT(assertion, reason) if (!(assertion)) { return Fail("Assertion failed: [reason || "No reason"]", __FILE__, __LINE__) }
#define TEST_ASSERT_EQUAL(a, b, message) do { 	var/lhs = ##a; 	var/rhs = ##b; 	if (lhs != rhs) { 		return Fail("Expected [isnull(lhs) ? "null" : lhs] to be equal to [isnull(rhs) ? "null" : rhs].[message ? " [message]" : ""]", __FILE__, __LINE__); 	} } while (FALSE)

/// Walks a cultivator through awakening, laws, insight, a realm up and a body swap.
/datum/unit_test/cultivation

/datum/unit_test/cultivation/Run()
	var/mob/living/carbon/human/consistent/disciple = allocate(/mob/living/carbon/human/consistent)
	disciple.mind_initialize()
	var/datum/antagonist/cultivator/cultivator = disciple.mind.add_antag_datum(/datum/antagonist/cultivator)
	TEST_ASSERT_NOTNULL(cultivator, "Failed to awaken a cultivator.")
	TEST_ASSERT_NOTNULL(disciple.get_organ_slot(ORGAN_SLOT_DANTIAN), "Awakening didn't give a dantian.")
	TEST_ASSERT_EQUAL(cultivator.effective_realm(), REALM_QI_CONDENSATION, "New cultivator isn't at Qi Condensation.")
	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/spell/cultivation/meditate) in disciple.actions, "No Meditate technique.")

	// Admin heals and organ regeneration must not delete the dantian
	disciple.fully_heal(HEAL_ALL)
	TEST_ASSERT_NOTNULL(disciple.get_organ_slot(ORGAN_SLOT_DANTIAN), "A full heal deleted the dantian.")

	// Laws and slots
	TEST_ASSERT(cultivator.learn_law(/datum/cultivation_law/returning_iron, feedback = FALSE), "Couldn't learn a first law.")
	TEST_ASSERT(!cultivator.learn_law(/datum/cultivation_law/evergreen_spring, feedback = FALSE), "Learned a second law with only one slot.")
	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/spell/cultivation/bind_artifact) in disciple.actions, "Law didn't grant its techniques.")
	TEST_ASSERT_NULL(locate(/datum/action/cooldown/spell/pointed/cultivation/sword_qi) in disciple.actions, "Foundation technique granted too early.")

	// Insight: per-source cooldowns and consolidation
	TEST_ASSERT_EQUAL(cultivator.gain_insight(10, "test_source", silent = TRUE), 10, "Insight gain failed.")
	TEST_ASSERT_EQUAL(cultivator.gain_insight(10, "test_source", silent = TRUE), 0, "Same insight source paid out twice in a row.")
	cultivator.consolidate(1)
	TEST_ASSERT_EQUAL(cultivator.progress, 10, "Meditation didn't consolidate insight.")

	// Realm up: new techniques, another law slot, combination technique, element clash
	cultivator.advance_realm()
	TEST_ASSERT_EQUAL(cultivator.realm, REALM_FOUNDATION, "Didn't advance realm.")
	var/obj/item/organ/dantian/dantian = disciple.get_organ_slot(ORGAN_SLOT_DANTIAN)
	TEST_ASSERT_EQUAL(dantian.grade, REALM_FOUNDATION, "Dantian grade didn't follow the realm.")
	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/spell/pointed/cultivation/sword_qi) in disciple.actions, "Foundation technique missing after realm up.")
	var/instability_before = cultivator.instability
	TEST_ASSERT(cultivator.learn_law(/datum/cultivation_law/evergreen_spring, feedback = FALSE), "Couldn't learn a second law at Foundation.")
	TEST_ASSERT(cultivator.instability > instability_before, "Metal and wood didn't clash.")
	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/spell/pointed/cultivation/thousand_thorns) in disciple.actions, "Metal + wood combo wasn't granted.")

	// Body swap: knowledge follows the mind, power stays in the body
	var/mob/living/carbon/human/consistent/new_body = allocate(/mob/living/carbon/human/consistent)
	var/obj/item/organ/dantian/old_dantian = new_body.get_organ_slot(ORGAN_SLOT_DANTIAN)
	TEST_ASSERT_NULL(old_dantian, "A fresh body somehow already has a dantian.")
	disciple.mind.transfer_to(new_body)
	TEST_ASSERT_NOTNULL(locate(/datum/action/cooldown/spell/cultivation/meditate) in new_body.actions, "Techniques didn't follow the mind.")
	TEST_ASSERT_EQUAL(cultivator.effective_realm(), REALM_MORTAL, "A body without a dantian can still channel qi.")
	TEST_ASSERT_EQUAL(cultivator.realm, REALM_FOUNDATION, "The mind forgot its realm in a new body.")

	// Removal cleans up techniques
	new_body.mind.remove_antag_datum(/datum/antagonist/cultivator)
	TEST_ASSERT_NULL(locate(/datum/action/cooldown/spell/cultivation/meditate) in new_body.actions, "Techniques survived losing cultivation.")

#undef TEST_ASSERT
#undef TEST_ASSERT_EQUAL
