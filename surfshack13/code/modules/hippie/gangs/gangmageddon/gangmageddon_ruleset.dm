// Gangmageddon - ported from HippieStation as a safer, admin-forced event round.
//
// Differences from Hippie, on purpose:
// - it is rarer than normal Gang War, but it can roll on its own at 15+ players.
// - Security, command-security and silicon jobs are closed through the job system instead of
//   Hippie's hard-coded area wipes, and nothing on the map is deleted or rewritten.
//   The armory is only bolted shut, which the crew can undo.

/datum/dynamic_ruleset/roundstart/gangmageddon
	name = "Gangmageddon"
	antag_flag = "Gangmageddon"
	antag_flag_override = ROLE_GANG
	antag_preference = ROLE_GANG
	antag_datum = /datum/antagonist/gang/boss
	minimum_required_age = 14
	restricted_roles = list(
		JOB_AI,
		JOB_CAPTAIN,
		JOB_CYBORG,
		JOB_DETECTIVE,
		JOB_HEAD_OF_PERSONNEL,
		JOB_HEAD_OF_SECURITY,
		JOB_LAWYER,
		JOB_PRISONER,
		JOB_SECURITY_OFFICER,
		JOB_WARDEN,
	)
	required_candidates = 3
	weight = 2
	cost = 30
	// population brackets are 6 players wide: 15-17 players need threat 50, big rounds need 20
	requirements = list(101, 101, 50, 40, 35, 30, 25, 20, 20, 20)
	flags = HIGH_IMPACT_RULESET
	minimum_players = 15
	/// How many gangs to make
	var/gangs_to_create = 2
	/// Bosses in each gang
	var/bosses_per_gang = 1

/datum/dynamic_ruleset/roundstart/gangmageddon/pre_execute(population)
	. = ..()
	gangs_to_create = 2
	if(prob(population) && population > 1.5 * minimum_players)
		gangs_to_create++
	if(prob(population) && population > 2 * minimum_players)
		gangs_to_create++
	gangs_to_create = min(gangs_to_create, length(GLOB.possible_gangs))
	bosses_per_gang = clamp(FLOOR(length(candidates) / 3, 1), 1, 3)
	for(var/i in 1 to gangs_to_create * bosses_per_gang)
		if(!length(candidates))
			break
		var/mob/boss = pick_n_take(candidates)
		assigned += boss.mind
		boss.mind.restricted_roles = restricted_roles
		boss.mind.special_role = ROLE_GANG
		GLOB.pre_setup_antags += boss.mind
	if(!length(assigned))
		return FALSE
	// Close the jobs through the job system, before anyone is assigned
	for(var/job_type in list(
		/datum/job/ai,
		/datum/job/captain,
		/datum/job/cyborg,
		/datum/job/detective,
		/datum/job/head_of_personnel,
		/datum/job/head_of_security,
		/datum/job/lawyer,
		/datum/job/security_officer,
		/datum/job/warden,
	))
		var/datum/job/closed_job = SSjob.get_job_type(job_type)
		if(closed_job)
			closed_job.total_positions = 0
			closed_job.spawn_positions = 0
	return TRUE

/datum/dynamic_ruleset/roundstart/gangmageddon/execute()
	GLOB.gangmageddon_active = TRUE
	var/list/bosses = assigned.Copy()
	var/made_gangs = 0
	for(var/i in 1 to gangs_to_create)
		if(!length(bosses) || !length(GLOB.possible_gangs))
			break
		var/gang_type = pick(GLOB.possible_gangs)
		var/datum/team/gang/new_gang = new gang_type()
		for(var/j in 1 to bosses_per_gang)
			if(!length(bosses))
				break
			var/datum/mind/boss_mind = pick_n_take(bosses)
			GLOB.pre_setup_antags -= boss_mind
			if(!boss_mind.current)
				continue
			var/datum/antagonist/gang/boss/boss_datum = new
			boss_mind.add_antag_datum(boss_datum, new_gang)
			// Bosses use their personal gangtool button instead of a held gangtool
			boss_datum.equip_gang(give_gangtool = FALSE)
		made_gangs++
	for(var/datum/mind/leftover as anything in bosses)
		GLOB.pre_setup_antags -= leftover
	if(!made_gangs)
		GLOB.gangmageddon_active = FALSE
		return FALSE
	GLOB.gangmageddon = new /datum/gangmageddon_controller()
	return TRUE

GLOBAL_DATUM(gangmageddon, /datum/gangmageddon_controller)

/// Runs the round-wide parts of Gangmageddon: vigilantes, the armory lockdown and the posses.
/datum/gangmageddon_controller

/datum/gangmageddon_controller/New()
	. = ..()
	for(var/mob/living/carbon/human/crew in GLOB.player_list)
		make_vigilante(crew)
	lock_armory()
	RegisterSignal(SSdcs, COMSIG_GLOB_CREWMEMBER_JOINED, PROC_REF(on_crew_joined))
	addtimer(CALLBACK(src, PROC_REF(announce)), 8 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(vigilante_vengeance)), rand(12 MINUTES, 17 MINUTES))

/datum/gangmageddon_controller/proc/announce()
	priority_announce("Excessive costs associated with lawsuits from employees injured by Security and Synthetics have compelled us to re-evaluate the personnel budget for new stations. \
		Accordingly, this station will be expected to operate without Security or Synthetic assistance. In the event that criminal enterprises seek to exploit this situation, \
		we have implanted all crew with a device that will assist and incentivize the removal of all contraband and criminals.", "Nanotrasen Board of Directors")

/// Everyone who isn't in a gang hunts them
/datum/gangmageddon_controller/proc/make_vigilante(mob/living/carbon/human/crew)
	if(!istype(crew) || !crew.mind || crew.stat == DEAD)
		return
	if(crew.mind.has_antag_datum(/datum/antagonist/gang) || crew.mind.has_antag_datum(/datum/antagonist/vigilante))
		return
	crew.mind.add_antag_datum(/datum/antagonist/vigilante)

/datum/gangmageddon_controller/proc/on_crew_joined(datum/source, mob/living/new_crewmember, rank)
	SIGNAL_HANDLER
	make_vigilante(new_crewmember)

/// Bolts the armory shut rather than deleting what's inside it
/datum/gangmageddon_controller/proc/lock_armory()
	for(var/area/station/ai_monitored/security/armory/armory in GLOB.areas)
		for(var/turf/armory_turf as anything in armory.get_turfs_from_all_zlevels())
			for(var/obj/machinery/door/airlock/door in armory_turf)
				door.bolt()

/// Every 12-17 minutes a posse of ghosts joins as extra vigilantes
/datum/gangmageddon_controller/proc/vigilante_vengeance()
	var/posse_size = 1 + round(length(GLOB.joined_player_list) * 0.05) + round(world.time / (500 SECONDS))
	var/list/mob/dead/observer/volunteers = SSpolling.poll_ghost_candidates(
		question = "Would you like to be a part of a Vigilante posse?",
		check_jobban = ROLE_GANG,
		poll_time = 10 SECONDS,
		role_name_text = "vigilante posse",
	)
	if(!length(volunteers))
		message_admins("No ghosts were willing to join the Gangmageddon vigilante posse.")
		addtimer(CALLBACK(src, PROC_REF(vigilante_vengeance)), rand(3 MINUTES, 5 MINUTES))
		return
	for(var/i in 1 to min(posse_size, length(volunteers)))
		var/mob/dead/observer/volunteer = pick_n_take(volunteers)
		if(volunteer?.client)
			spawn_posse_member(volunteer)
	addtimer(CALLBACK(src, PROC_REF(vigilante_vengeance)), rand(12 MINUTES, 17 MINUTES))

/datum/gangmageddon_controller/proc/spawn_posse_member(mob/dead/observer/volunteer)
	var/datum/job/assistant/assistant_job = SSjob.get_job_type(/datum/job/assistant)
	var/atom/spawn_point = assistant_job.get_latejoin_spawn_point()
	var/mob/living/carbon/human/member = new(get_turf(spawn_point))
	randomize_human_normie(member)
	member.PossessByPlayer(volunteer.ckey)
	member.mind.set_assigned_role(assistant_job)
	member.equipOutfit(/datum/outfit/job/assistant)
	member.equip_to_slot_or_del(new /obj/item/clothing/suit/armor/vest/alt(member), ITEM_SLOT_OCLOTHING)
	member.put_in_hands(new /obj/item/flashlight/flare/torch(member))
	GLOB.manifest.inject(member)
	member.mind.add_antag_datum(/datum/antagonist/vigilante)
	message_admins("[ADMIN_LOOKUPFLW(member)] joined as a Gangmageddon vigilante posse member.")
	log_game("[key_name(member)] joined as a Gangmageddon vigilante posse member.")
