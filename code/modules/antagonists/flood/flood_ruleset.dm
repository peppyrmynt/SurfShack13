/datum/dynamic_ruleset/midround/from_ghosts/flood
	name = "Flood Outbreak"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_HEAVY
	antag_datum = /datum/antagonist/flood
	antag_flag = ROLE_FLOOD
	antag_preference = ROLE_FLOOD
	antag_flag_override = ROLE_FLOOD
	required_type = /mob/dead/observer
	minimum_required_age = 0
	restrict_ghost_roles = FALSE
	required_applicants = 1
	required_candidates = 1
	weight = 2
	cost = 6
	antag_cap = 1
	repeatable = FALSE
	requirements = list(40, 35, 30, 25, 20, 20, 20, 20, 20, 20)
	ruleset_category = parent_type::ruleset_category | RULESET_CATEGORY_NO_WITTING_CREW_ANTAGONISTS
	signup_item_path = /mob/living/basic/flood/overseer

/datum/dynamic_ruleset/midround/from_ghosts/flood/proc/available_observers()
	var/list/volunteers = list()
	if(!(GLOB.ghost_role_flags & GHOSTROLE_MIDROUND_EVENT))
		return volunteers
	for(var/mob/dead/observer/ghost in GLOB.current_observers_list)
		if(!ghost.client || HAS_TRAIT(ghost, TRAIT_MIND_TEMPORARILY_GONE) || HAS_TRAIT(ghost, TRAIT_TEMPORARY_BODY))
			continue
		if(!ghost.client.prefs.read_preference(/datum/preference/toggle/ghost_roles))
			continue
		if(ghost.client.holder && !ghost.client.prefs.read_preference(/datum/preference/toggle/ghost_roles_as_admin))
			continue
		if(!SSpolling.is_eligible(ghost, ROLE_FLOOD, ROLE_FLOOD, null))
			continue
		volunteers += ghost
	return volunteers

/datum/dynamic_ruleset/midround/from_ghosts/flood/trim_candidates()
	// Ghosts do not need a former crew job or a mind to volunteer for a new body.
	dead_players = list()
	list_observers = available_observers()

/datum/dynamic_ruleset/midround/from_ghosts/flood/execute()
	if(!can_form_flood_overseer())
		message_admins("Flood Outbreak cannot start: an Overseer exists, one is choosing a spawn, or the hive is still recovering.")
		return FALSE
	// Recheck the live ghost pool for admin-forced rolls as well as normal rolls.
	send_applications(available_observers())
	return length(assigned) > 0

/datum/dynamic_ruleset/midround/from_ghosts/flood/send_applications(list/possible_volunteers = list())
	if(!(GLOB.ghost_role_flags & GHOSTROLE_MIDROUND_EVENT))
		message_admins("Flood Outbreak cannot poll observers while midround ghost roles are disabled.")
		return
	if(!length(possible_volunteers))
		message_admins("Flood Outbreak has no available observers with Flood enabled, ghost-role polls enabled (including the admin setting), and no Flood ban. Living players cannot enter a ghost-spawned Overseer poll.")
		return
	SSdynamic.log_dynamic_and_announce("Polling [length(possible_volunteers)] observers to apply for the [name] ruleset.")
	// The generic ghost helper is gated by STATION_SENTIENCE, which can be off
	// even when MIDROUND_EVENT is on. Poll this ruleset's eligible ghost pool.
	candidates = SSpolling.poll_candidates(
		question = "Looking for volunteers to become [span_notice(antag_flag)] for [span_danger(name)]",
		check_jobban = antag_flag_override,
		role = antag_flag,
		poll_time = 30 SECONDS,
		group = possible_volunteers,
		alert_pic = signup_item_path,
		role_name_text = antag_flag,
	)
	if(!length(candidates))
		SSdynamic.log_dynamic_and_announce("The ruleset [name] received no applications.")
		SSdynamic.executed_rules -= src
		return
	SSdynamic.log_dynamic_and_announce("[length(candidates)] players volunteered for [name].")
	review_applications()

/datum/dynamic_ruleset/midround/from_ghosts/flood/finish_applications()
	// The poll lasts 30 seconds; a constructor may have become overseer meanwhile.
	if(!can_form_flood_overseer())
		SSdynamic.executed_rules -= src
		assigned.Cut()
		return
	for(var/mob/applicant as anything in assigned.Copy())
		if(!applicant.client)
			assigned -= applicant
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/flood/generate_ruleset_body(mob/applicant)
	var/turf/starting_turf = find_flood_scout_spawn()
	if(!starting_turf)
		message_admins("Flood Outbreak could not find a station turf for its placement view.")
		return applicant
	var/mob/eye/flood_spawn/placement = new(starting_turf)
	// Like become_overmind(), give the ghost a fresh mind and explicitly transfer control.
	placement.PossessByPlayer(applicant.key)
	qdel(applicant)
	return placement

/datum/dynamic_ruleset/midround/from_ghosts/flood/finish_setup(mob/new_character, index)
	if(!istype(new_character, /mob/eye/flood_spawn))
		return
	if(!new_character.mind)
		new_character.mind_initialize()
	return ..()
