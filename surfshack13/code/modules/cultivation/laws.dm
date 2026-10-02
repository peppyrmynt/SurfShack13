/**
 * # Cultivation law
 *
 * A school of cultivation tied to one of the five elements.
 * Grants techniques by realm, a passive at Foundation Establishment, and earns insight from its own kind of work.
 */
/datum/cultivation_law
	var/name = "Law of Nothing"
	var/desc = "You shouldn't see this."
	var/element
	/// technique typepath -> realm required
	var/list/techniques = list()
	/// activity (INSIGHT_SOURCE_*) -> insight earned
	var/list/insight_activities = list()
	/// Learned from a counterfeit manual: techniques of this law cost more qi
	var/counterfeit = FALSE
	/// Is our Foundation passive currently applied
	var/passive_applied = FALSE
	/// The body our passive is applied to
	var/datum/weakref/passive_body_ref

/datum/cultivation_law/Destroy()
	var/mob/living/body = passive_body_ref?.resolve()
	if(body && passive_applied)
		remove_passive(body)
	return ..()

/datum/cultivation_law/proc/on_activity(datum/antagonist/cultivator/cultivator, activity, atom/thing)
	var/amount = insight_activities[activity]
	if(amount)
		cultivator.gain_insight(amount, "[element]_[activity]")

/datum/cultivation_law/proc/on_body_gained(mob/living/body, datum/antagonist/cultivator/cultivator)
	if(cultivator.realm >= REALM_FOUNDATION && !passive_applied)
		passive_applied = TRUE
		passive_body_ref = WEAKREF(body)
		apply_passive(body)

/datum/cultivation_law/proc/on_body_lost(mob/living/body, datum/antagonist/cultivator/cultivator)
	if(passive_applied)
		passive_applied = FALSE
		passive_body_ref = null
		remove_passive(body)

/datum/cultivation_law/proc/on_realm_up(datum/antagonist/cultivator/cultivator)
	on_body_gained(cultivator.owner.current, cultivator)

/// Foundation Establishment passive
/datum/cultivation_law/proc/apply_passive(mob/living/body)
	return

/datum/cultivation_law/proc/remove_passive(mob/living/body)
	return

// ----- Metal -----

/datum/cultivation_law/returning_iron
	name = "Returning Iron Sutra"
	desc = "Metal. Bind a tool or weapon to your soul and send it flying. Insight from crafting, building and welding."
	element = ELEMENT_METAL
	techniques = list(
		/datum/action/cooldown/spell/cultivation/bind_artifact = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/pointed/cultivation/flying_sword = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/pointed/cultivation/sword_qi = REALM_FOUNDATION,
		/datum/action/cooldown/spell/cultivation/sword_riding = REALM_GOLDEN_CORE,
	)
	insight_activities = list(
		INSIGHT_SOURCE_CRAFT = 4,
		INSIGHT_SOURCE_TOOL = 3,
		INSIGHT_SOURCE_WELD = 3,
	)

// ----- Water -----

/datum/cultivation_law/still_water
	name = "Still Water Scripture"
	desc = "Water. Ward allies and calm troubled minds. Foundation passive: you never slip on wet floors. Insight from cleaning, fishing and tending plants."
	element = ELEMENT_WATER
	techniques = list(
		/datum/action/cooldown/spell/pointed/cultivation/still_water_ward = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/pointed/cultivation/calm_heart = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/cultivation/turtle_breathing = REALM_GOLDEN_CORE,
	)
	insight_activities = list(
		INSIGHT_SOURCE_CLEANING = 4,
		INSIGHT_SOURCE_FISHING = 5,
		INSIGHT_SOURCE_HARVEST = 2,
	)

/datum/cultivation_law/still_water/apply_passive(mob/living/body)
	ADD_TRAIT(body, TRAIT_NO_SLIP_WATER, REF(src))

/datum/cultivation_law/still_water/remove_passive(mob/living/body)
	REMOVE_TRAIT(body, TRAIT_NO_SLIP_WATER, REF(src))

// ----- Fire -----

/datum/cultivation_law/furnace_heart
	name = "Furnace Heart Canon"
	desc = "Fire. Kindle flames with a touch and store heat for a devastating burst. Foundation passive: your inner fire keeps the cold away. Insight from cooking and welding."
	element = ELEMENT_FIRE
	techniques = list(
		/datum/action/cooldown/spell/pointed/cultivation/kindle = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/cultivation/furnace_burst = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/cultivation/burning_blood = REALM_GOLDEN_CORE,
	)
	insight_activities = list(
		INSIGHT_SOURCE_COOK = 5,
		INSIGHT_SOURCE_WELD = 3,
	)

/datum/cultivation_law/furnace_heart/apply_passive(mob/living/body)
	ADD_TRAIT(body, TRAIT_RESISTCOLD, REF(src))

/datum/cultivation_law/furnace_heart/remove_passive(mob/living/body)
	REMOVE_TRAIT(body, TRAIT_RESISTCOLD, REF(src))

// ----- Earth -----

/datum/cultivation_law/rooted_mountain
	name = "Rooted Mountain Manual"
	desc = "Earth. Become immovable and wrap yourself in a golden bell. Foundation passive: stone skin reduces brute damage. Insight from mining, building and training your body."
	element = ELEMENT_EARTH
	techniques = list(
		/datum/action/cooldown/spell/cultivation/rooted_stance = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/cultivation/golden_bell = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/cultivation/dharma_idol = REALM_GOLDEN_CORE,
	)
	insight_activities = list(
		INSIGHT_SOURCE_MINING = 4,
		INSIGHT_SOURCE_TOOL = 2,
		INSIGHT_SOURCE_ATHLETICS = 4,
	)

/datum/cultivation_law/rooted_mountain/apply_passive(mob/living/body)
	RegisterSignal(body, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, PROC_REF(stone_skin))

/datum/cultivation_law/rooted_mountain/remove_passive(mob/living/body)
	UnregisterSignal(body, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS)

/datum/cultivation_law/rooted_mountain/proc/stone_skin(mob/living/source, list/damage_mods, damage, damagetype, ...)
	SIGNAL_HANDLER
	if(damagetype == BRUTE)
		damage_mods += 0.85

// ----- Wood -----

/datum/cultivation_law/evergreen_spring
	name = "Evergreen Spring Classic"
	desc = "Wood. Mend wounds and make life flourish. Foundation passive: your body shrugs off some toxins. Insight from botany and from healing others."
	element = ELEMENT_WOOD
	techniques = list(
		/datum/action/cooldown/spell/pointed/cultivation/spring_mending = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/cultivation/verdant_growth = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/pointed/cultivation/binding_vines = REALM_GOLDEN_CORE,
	)
	insight_activities = list(
		INSIGHT_SOURCE_HARVEST = 5,
		INSIGHT_SOURCE_SURGERY = 4,
	)

/datum/cultivation_law/evergreen_spring/apply_passive(mob/living/body)
	RegisterSignal(body, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, PROC_REF(evergreen_body))

/datum/cultivation_law/evergreen_spring/remove_passive(mob/living/body)
	UnregisterSignal(body, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS)

/datum/cultivation_law/evergreen_spring/proc/evergreen_body(mob/living/source, list/damage_mods, damage, damagetype, ...)
	SIGNAL_HANDLER
	if(damagetype == TOX)
		damage_mods += 0.75

// ----- Combinations -----

/// Two elements resonating unlock a hidden technique
/datum/cultivation_combo
	var/element_one
	var/element_two
	var/datum/action/technique
	var/realm_required = REALM_FOUNDATION

GLOBAL_LIST_INIT(cultivation_combos, init_cultivation_combos())

/proc/init_cultivation_combos()
	. = list()
	for(var/combo_type in subtypesof(/datum/cultivation_combo))
		. += new combo_type()

/datum/cultivation_combo/steam_veil
	element_one = ELEMENT_FIRE
	element_two = ELEMENT_WATER
	technique = /datum/action/cooldown/spell/cultivation/steam_veil

/datum/cultivation_combo/thousand_thorns
	element_one = ELEMENT_METAL
	element_two = ELEMENT_WOOD
	technique = /datum/action/cooldown/spell/pointed/cultivation/thousand_thorns

/datum/cultivation_combo/molten_step
	element_one = ELEMENT_EARTH
	element_two = ELEMENT_FIRE
	technique = /datum/action/cooldown/spell/cultivation/molten_step

/datum/cultivation_combo/mud_prison
	element_one = ELEMENT_WATER
	element_two = ELEMENT_EARTH
	technique = /datum/action/cooldown/spell/pointed/cultivation/mud_prison
