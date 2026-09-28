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
	signup_item_path = /obj/structure/sign/poster/contraband/syndicate_recruitment
	var/turf/spawn_turf

/datum/dynamic_ruleset/midround/from_ghosts/flood/execute()
	if(!can_form_flood_overseer())
		return FALSE
	spawn_turf = find_maintenance_spawn(atmos_sensitive = TRUE, require_darkness = FALSE)
	if(!spawn_turf)
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/flood/finish_applications()
	// The poll lasts 30 seconds; a constructor may have become overseer meanwhile.
	if(!can_form_flood_overseer())
		SSdynamic.executed_rules -= src
		return
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/flood/generate_ruleset_body(mob/applicant)
	var/mob/living/basic/flood/overseer/new_flood = new(spawn_turf)
	// The new leader can enter overseer mode immediately from its spawn tile.
	grow_flood_floor(spawn_turf)
	if(applicant.mind)
		applicant.mind.transfer_to(new_flood)
	return new_flood

/datum/dynamic_ruleset/midround/from_ghosts/flood/finish_setup(mob/new_character, index)
	// Transferring the mind into a Flood body may already have granted the datum.
	if(new_character.mind?.has_antag_datum(/datum/antagonist/flood))
		new_character.mind.special_role = ROLE_FLOOD
		return
	return ..()
