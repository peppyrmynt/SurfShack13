#define STAND_ABSOLUTION_TRAIT "stand_absolution"
#define STAND_POCKET_TRAIT "stand_pocket_protection"

GLOBAL_VAR_INIT(stand_pocket_counter, 1)

/area/misc/stand_pocket_dimension
	name = "??? INVALID COORDINATES ???"
	requires_power = FALSE
	area_flags = UNIQUE_AREA

/// Requiem powers are excluded from normal arrow generation and only selected during transformation.
/datum/stand_power/requiem
	name = "Requiem"
	weight = 0

/datum/stand_power/requiem/time_stop
	name = "Time Stop"
	cost = 5

/datum/stand_power/requiem/dimensional_manifestation
	name = "Dimensional Manifestation"
	cost = 5

/datum/stand_power/requiem/absolution
	name = "Absolution"
	cost = 5

/datum/component/arrow_stand
	var/pocket_trait
	var/pocket_z
	var/datum/weakref/pocket_return

/// Called after the normal major has been removed and a Requiem power selected.
/datum/component/arrow_stand/proc/setup_requiem_power()
	var/mob/living/basic/guardian/guardian = parent
	if(istype(power, /datum/stand_power/requiem/time_stop))
		grant_power_action(/datum/action/cooldown/mob_cooldown/stand_requiem_time_stop)
		rebuild_playstyle("Stop time in a localized area. You, your summoner, and allied Stands remain able to move while everyone else is frozen.")
		return
	if(istype(power, /datum/stand_power/requiem/dimensional_manifestation))
		ensure_pocket_dimension()
		grant_power_action(/datum/action/cooldown/mob_cooldown/stand_requiem_dimension)
		rebuild_playstyle("Open your private pocket dimension and move yourself, your summoner, and allied Stands between it and realspace.")
		return
	if(istype(power, /datum/stand_power/requiem/absolution))
		RegisterSignal(guardian, COMSIG_GUARDIAN_MANIFESTED, PROC_REF(absolution_manifested))
		RegisterSignal(guardian, COMSIG_GUARDIAN_RECALLED, PROC_REF(absolution_recalled))
		if(guardian.is_deployed())
			apply_absolution()
		rebuild_playstyle("While manifested, form an absolute shield around your summoner, preventing damage and suffocation until you recall.")

/datum/component/arrow_stand/proc/grant_requiem_minors()
	grant_power_action(/datum/action/cooldown/mob_cooldown/guardian_alarm_snare)
	grant_power_action(/datum/action/cooldown/mob_cooldown/guardian_bluespace_beacon)
	var/mob/living/basic/guardian/guardian = parent
	guardian.playstyle_string += "<br><b>Requiem minors:</b> Surveillance Snares and Teleportation Pad."

/datum/component/arrow_stand/proc/absolution_manifested()
	SIGNAL_HANDLER
	apply_absolution()

/datum/component/arrow_stand/proc/absolution_recalled()
	SIGNAL_HANDLER
	var/mob/living/basic/guardian/guardian = parent
	guardian.summoner?.remove_status_effect(/datum/status_effect/stand_absolution)

/datum/component/arrow_stand/proc/apply_absolution()
	var/mob/living/basic/guardian/guardian = parent
	if(QDELETED(guardian.summoner))
		return
	guardian.summoner.apply_status_effect(/datum/status_effect/stand_absolution, guardian)

/datum/component/arrow_stand/proc/ensure_pocket_dimension()
	if(pocket_z)
		return TRUE
	pocket_trait = "Stand Pocket Dimension [GLOB.stand_pocket_counter++]"
	var/list/default_traits = list()
	default_traits[pocket_trait] = TRUE
	default_traits[ZTRAIT_BOMBCAP_MULTIPLIER] = 0
	default_traits[ZTRAIT_GRAVITY] = STANDARD_GRAVITY
	var/list/errors = list()
	SSmapping.LoadGroup(
		errors,
		pocket_trait,
		"templates",
		"stand_pocket_dimension.dmm",
		default_traits = default_traits,
		silent = TRUE,
	)
	if(length(errors))
		message_admins("A Requiem Stand pocket dimension failed to load: [english_list(errors)].")
		log_game("A Requiem Stand pocket dimension failed to load: [english_list(errors)].")
		return FALSE
	var/list/levels = SSmapping.levels_by_trait(pocket_trait)
	if(!length(levels))
		message_admins("A Requiem Stand pocket dimension loaded without a matching z-trait.")
		return FALSE
	pocket_z = levels[1]
	return TRUE

/datum/action/cooldown/mob_cooldown/stand_requiem_time_stop
	parent_type = /datum/action/cooldown/mob_cooldown/stand_power
	name = "Time Stop"
	desc = "Stop time around yourself while your summoner and allied Stands remain immune."
	cooldown_time = 50 SECONDS
	click_to_activate = FALSE

/datum/action/cooldown/mob_cooldown/stand_requiem_time_stop/Activate()
	var/datum/component/arrow_stand/stand_component = get_stand_component()
	var/mob/living/basic/guardian/guardian = owner
	if(!stand_component?.requiem || !guardian.is_deployed())
		return FALSE
	var/list/immune_atoms = list(guardian)
	if(!QDELETED(guardian.summoner))
		immune_atoms |= guardian.summoner
		for(var/mob/living/basic/guardian/linked as anything in guardian.summoner.get_all_linked_holoparasites())
			immune_atoms |= linked
	new /obj/effect/timestop/magic(get_turf(guardian), 2, 10 SECONDS, immune_atoms)
	guardian.visible_message(span_holoparasite("Time itself freezes around [guardian]!"))
	StartCooldown()
	return TRUE

/datum/action/cooldown/mob_cooldown/stand_requiem_dimension
	parent_type = /datum/action/cooldown/mob_cooldown/stand_power
	name = "Dimensional Manifestation"
	desc = "Move yourself, your summoner, and allied Stands into or out of your private pocket dimension."
	cooldown_time = 45 SECONDS
	click_to_activate = FALSE

/datum/action/cooldown/mob_cooldown/stand_requiem_dimension/Activate()
	var/datum/component/arrow_stand/stand_component = get_stand_component()
	var/mob/living/basic/guardian/guardian = owner
	if(!stand_component?.requiem || !guardian.is_deployed())
		return FALSE
	if(!stand_component.ensure_pocket_dimension())
		guardian.balloon_alert(guardian, "pocket dimension unavailable!")
		return FALSE
	var/turf/current = get_turf(guardian)
	if(!current)
		return FALSE
	var/list/mob/living/group = list(guardian)
	if(!QDELETED(guardian.summoner))
		group |= guardian.summoner
		for(var/mob/living/basic/guardian/linked as anything in guardian.summoner.get_all_linked_holoparasites())
			group |= linked
	if(current.z == stand_component.pocket_z)
		var/turf/return_turf = stand_component.pocket_return?.resolve()
		if(!return_turf)
			guardian.balloon_alert(guardian, "realspace anchor lost!")
			return FALSE
		for(var/mob/living/member as anything in group)
			if(QDELETED(member))
				continue
			var/turf/member_turf = get_turf(member)
			if(!member_turf || member_turf.z != stand_component.pocket_z)
				continue
			member.forceMove(return_turf)
			member.remove_status_effect(/datum/status_effect/stand_pocket_protection)
			to_chat(member, span_holoparasite("Reality rushes back into focus."))
		stand_component.pocket_return = null
	else
		var/turf/pocket_center = locate(5, 5, stand_component.pocket_z)
		if(!pocket_center)
			guardian.balloon_alert(guardian, "pocket dimension failed to resolve!")
			return FALSE
		stand_component.pocket_return = WEAKREF(current)
		for(var/mob/living/member as anything in group)
			if(QDELETED(member))
				continue
			member.forceMove(pocket_center)
			member.apply_status_effect(/datum/status_effect/stand_pocket_protection, stand_component.pocket_z)
			to_chat(member, span_holoparasite("All of existence fades out for a moment..."))
	guardian.visible_message(span_holoparasite("Space folds violently around [guardian]."))
	StartCooldown()
	return TRUE

/datum/status_effect/stand_absolution
	id = "stand_absolution"
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	var/datum/weakref/guardian_ref

/datum/status_effect/stand_absolution/on_creation(mob/living/new_owner, mob/living/basic/guardian/guardian)
	guardian_ref = WEAKREF(guardian)
	return ..()

/datum/status_effect/stand_absolution/on_apply()
	ADD_TRAIT(owner, TRAIT_GODMODE, STAND_ABSOLUTION_TRAIT)
	ADD_TRAIT(owner, TRAIT_NOBREATH, STAND_ABSOLUTION_TRAIT)
	var/mob/living/basic/guardian/guardian = guardian_ref?.resolve()
	if(guardian)
		RegisterSignal(guardian, COMSIG_QDELETING, PROC_REF(guardian_deleted))
	to_chat(owner, span_holoparasite("An absolute barrier surrounds you."))
	return TRUE

/datum/status_effect/stand_absolution/on_remove()
	REMOVE_TRAIT(owner, TRAIT_GODMODE, STAND_ABSOLUTION_TRAIT)
	REMOVE_TRAIT(owner, TRAIT_NOBREATH, STAND_ABSOLUTION_TRAIT)
	var/mob/living/basic/guardian/guardian = guardian_ref?.resolve()
	if(guardian)
		UnregisterSignal(guardian, COMSIG_QDELETING)
	to_chat(owner, span_holoparasite("The absolute barrier fades."))

/datum/status_effect/stand_absolution/proc/guardian_deleted()
	SIGNAL_HANDLER
	qdel(src)

/datum/status_effect/stand_pocket_protection
	id = "stand_pocket_protection"
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	var/pocket_z

/datum/status_effect/stand_pocket_protection/on_creation(mob/living/new_owner, pocket_z)
	src.pocket_z = pocket_z
	return ..()

/datum/status_effect/stand_pocket_protection/on_apply()
	ADD_TRAIT(owner, TRAIT_GODMODE, STAND_POCKET_TRAIT)
	ADD_TRAIT(owner, TRAIT_NOHARDCRIT, STAND_POCKET_TRAIT)
	ADD_TRAIT(owner, TRAIT_NOSOFTCRIT, STAND_POCKET_TRAIT)
	ADD_TRAIT(owner, TRAIT_NODEATH, STAND_POCKET_TRAIT)
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(check_dimension))
	return TRUE

/datum/status_effect/stand_pocket_protection/on_remove()
	REMOVE_TRAIT(owner, TRAIT_GODMODE, STAND_POCKET_TRAIT)
	REMOVE_TRAIT(owner, TRAIT_NOHARDCRIT, STAND_POCKET_TRAIT)
	REMOVE_TRAIT(owner, TRAIT_NOSOFTCRIT, STAND_POCKET_TRAIT)
	REMOVE_TRAIT(owner, TRAIT_NODEATH, STAND_POCKET_TRAIT)
	UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)

/datum/status_effect/stand_pocket_protection/proc/check_dimension()
	SIGNAL_HANDLER
	var/turf/owner_turf = get_turf(owner)
	if(!owner_turf || owner_turf.z != pocket_z)
		qdel(src)

#undef STAND_ABSOLUTION_TRAIT
#undef STAND_POCKET_TRAIT
