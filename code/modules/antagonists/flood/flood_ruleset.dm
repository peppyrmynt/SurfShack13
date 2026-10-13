/datum/dynamic_ruleset/midround/from_ghosts/flood
	name = "Flood Outbreak"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_HEAVY
	antag_datum = /datum/antagonist/flood
	antag_flag = ROLE_FLOOD
	antag_preference = ROLE_FLOOD
	antag_flag_override = ROLE_FLOOD
	required_type = /mob/dead/observer
	required_applicants = 1
	required_candidates = 1
	weight = 2
	cost = 6
	antag_cap = 1
	repeatable = FALSE
	requirements = list(40, 35, 30, 25, 20, 20, 20, 20, 20, 20)
	ruleset_category = parent_type::ruleset_category | RULESET_CATEGORY_NO_WITTING_CREW_ANTAGONISTS
	signup_item_path = /mob/living/basic/flood/overseer

/datum/dynamic_ruleset/midround/from_ghosts/flood/execute()
	if(!can_form_flood_overseer())
		message_admins("Flood Outbreak cannot start: an Overseer exists, one is choosing a spawn, or the hive is still recovering.")
		return FALSE
	// Forced admin rolls can have an empty trimmed candidate list. The ghost poll
	// handles preferences and bans itself, so let it reach the connected observers.
	send_applications(GLOB.current_observers_list.Copy())
	return length(assigned) > 0

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
