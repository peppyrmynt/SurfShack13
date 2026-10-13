// Cortical Borer antagonist datum, objective and spawn event.

/datum/antagonist/cortical_borer
	name = "\improper Cortical Borer"
	show_name_in_check_antagonists = TRUE
	show_to_ghosts = TRUE
	show_in_antagpanel = FALSE
	antagpanel_category = ANTAG_GROUP_ABOMINATIONS
	job_rank = ROLE_ALIEN

/datum/antagonist/cortical_borer/on_gain()
	var/datum/objective/cortical_borer_escape/escape = new
	escape.owner = owner
	escape.update_explanation_text()
	objectives += escape
	return ..()

/datum/antagonist/cortical_borer/greet()
	. = ..()
	to_chat(owner.current, span_notice("You are a brain slug that worms its way into the head of its victim. Use stealth, persuasion and your powers of mind control to keep you, your host and your eventual spawn safe and warm."))
	to_chat(owner.current, span_warning("Sugar nullifies your abilities, avoid it at all costs!"))
	to_chat(owner.current, span_notice("Prefix a message with ; to talk to your fellow borers over the cortical link. Your abilities are on your action bar."))
	owner.announce_objectives()

/datum/objective/cortical_borer_escape
	name = "borer escape"
	/// How many borers need to escape inside living hosts
	var/hosts_needed = 1

/datum/objective/cortical_borer_escape/update_explanation_text()
	var/living_humans = 0
	for(var/mob/living/carbon/human/person as anything in GLOB.human_list)
		if(person.stat != DEAD && person.client)
			living_humans++
	hosts_needed = max(1, round(1 + living_humans / 6))
	explanation_text = "Escape on the shuttle with at least [hosts_needed] borer\s living inside hosts."

/datum/objective/cortical_borer_escape/check_completion()
	var/escaped = 0
	for(var/mob/living/basic/cortical_borer/borer as anything in GLOB.cortical_borers)
		if(borer.stat == DEAD || !borer.host || borer.host.stat == DEAD)
			continue
		if(borer.host.onCentCom() || istype(get_area(borer.host), /area/shuttle/escape))
			escaped++
	return escaped >= hosts_needed

/datum/round_event_control/cortical_borer
	name = "Cortical Borers"
	typepath = /datum/round_event/cortical_borer
	weight = 10
	max_occurrences = 1
	min_players = 15
	earliest_start = 10 MINUTES
	category = EVENT_CATEGORY_ENTITIES
	description = "Spawns 2-4 ghost-controlled cortical borers in maintenance."

/datum/round_event/cortical_borer
	announce_when = 300 // borers get a head start before the crew hunts them
	/// How many borers to spawn
	var/spawncount = 2
	/// Whether any spawned
	var/spawned = FALSE

/datum/round_event/cortical_borer/setup()
	spawncount = rand(2, 4)

/datum/round_event/cortical_borer/announce(fake)
	if(spawned || fake)
		priority_announce("Unidentified lifesigns detected coming aboard [station_name()]. Secure any exterior access, including ducting and ventilation.", "Lifesign Alert", ANNOUNCER_ALIENS)

/datum/round_event/cortical_borer/start()
	for(var/i in 1 to spawncount)
		var/turf/spawn_loc = find_maintenance_spawn(atmos_sensitive = FALSE, require_darkness = FALSE)
		if(isnull(spawn_loc))
			return
		new /mob/living/basic/cortical_borer(spawn_loc)
		spawned = TRUE
	log_game("[spawncount] cortical borers were spawned by an event.")
