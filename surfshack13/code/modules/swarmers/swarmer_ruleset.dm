//It's them.
/datum/dynamic_ruleset/midround/from_ghosts/swarmers
	name = "Swarmers"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_LIGHT
	antag_datum = /datum/antagonist/swarmer
	antag_flag = ROLE_SWARMER
	required_type = /mob/dead/observer
	enemy_roles = list(
		JOB_CAPTAIN,
		JOB_DETECTIVE,
		JOB_HEAD_OF_SECURITY,
		JOB_SECURITY_OFFICER,
	)
	required_candidates = 1
	weight = 1
	cost = 10
	repeatable = FALSE
	signup_item_path = /mob/living/basic/swarmer
	var/spawn_loc = null

/datum/dynamic_ruleset/midround/from_ghosts/swarmers/forget_startup()
	spawn_loc = null
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/swarmers/acceptable(population = 0, threat_level = 0)
	spawn_loc = find_maintenance_spawn(atmos_sensitive = TRUE, require_darkness = TRUE) //Checks if there's a single safe, dark tile on station.
	if(!spawn_loc)
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/swarmers/review_applications()
	// Everyone who signs up for this gets the role.
	required_candidates = candidates.len
	. = ..()
	priority_announce("Long-range sensors indicate [station_name()] has been breached by swarmers. The crew is advised to protect precious material stores and disable the threat.", "Intrusion Alert")

/datum/dynamic_ruleset/midround/from_ghosts/swarmers/generate_ruleset_body(mob/applicant)
	var/mob/living/basic/swarmer/swarmer = new(spawn_loc)
	swarmer.key = applicant.key
	message_admins("[ADMIN_LOOKUPFLW(swarmer)] has been made into a swarmer by the midround ruleset.")
	log_game("[key_name(swarmer)] was spawned as a swarmer by the midround ruleset.")
	return swarmer
