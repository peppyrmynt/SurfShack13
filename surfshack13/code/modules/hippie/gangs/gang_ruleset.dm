// Roundstart dynamic ruleset for Gang War. Each chosen boss founds their own gang.

/datum/dynamic_ruleset/roundstart/gangs
	name = "Gang War"
	antag_flag = ROLE_GANG
	antag_datum = /datum/antagonist/gang/boss
	minimum_required_age = 14
	restricted_roles = list(
		JOB_AI,
		JOB_CAPTAIN,
		JOB_CYBORG,
		JOB_DETECTIVE,
		JOB_HEAD_OF_PERSONNEL,
		JOB_HEAD_OF_SECURITY,
		JOB_PRISONER,
		JOB_SECURITY_OFFICER,
		JOB_WARDEN,
	)
	required_candidates = 2
	weight = 3
	cost = 20
	// population brackets are 6 players wide: rare at low pop like cult and nukies (70 threat at 10-17 players), common at high pop
	requirements = list(101, 70, 70, 60, 40, 30, 20, 10, 10, 10)
	// 2 gangs, plus one more per 25 players, up to Hippie's usual 4
	antag_cap = list("denominator" = 25, "offset" = 1)
	flags = HIGH_IMPACT_RULESET
	minimum_players = 10

/datum/dynamic_ruleset/roundstart/gangs/pre_execute(population)
	. = ..()
	var/gangs_to_create = min(get_antag_cap(population), 4, length(GLOB.possible_gangs))
	for(var/i in 1 to gangs_to_create)
		if(!length(candidates))
			break
		var/mob/boss = pick_n_take(candidates)
		assigned += boss.mind
		boss.mind.restricted_roles = restricted_roles
		boss.mind.special_role = ROLE_GANG
		GLOB.pre_setup_antags += boss.mind
	return length(assigned) > 0

/datum/dynamic_ruleset/roundstart/gangs/execute()
	var/made_gangs = 0
	for(var/datum/mind/boss_mind as anything in assigned)
		GLOB.pre_setup_antags -= boss_mind
		if(!boss_mind.current || !length(GLOB.possible_gangs))
			continue
		var/gang_type = pick(GLOB.possible_gangs)
		var/datum/team/gang/new_gang = new gang_type()
		var/datum/antagonist/gang/boss/boss_datum = new
		boss_mind.add_antag_datum(boss_datum, new_gang)
		boss_datum.equip_gang()
		made_gangs++
	return made_gangs > 0
