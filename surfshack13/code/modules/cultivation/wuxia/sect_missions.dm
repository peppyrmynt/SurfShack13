/**
 * Sect missions and martial tournaments.
 *
 * Every sect is handed a mission shortly after it's founded and again after each one ends. Any member's work counts towards it,
 * and completing it rewards every member with insight and face.
 *
 * A Sect Master can proclaim a martial tournament at their plaque: for ten minutes every honor duel on the station counts double face,
 * and whoever wins the most duels is crowned Martial Champion.
 */

/datum/jianghu_sect
	/// Current mission (SECT_MISSION_*), or null between missions
	var/mission_type
	/// How many we need
	var/mission_goal = 0
	/// How many we've done
	var/mission_progress = 0
	/// When the current mission expires
	var/mission_deadline = 0
	/// Missions finished, for the plaque and the roundend
	var/missions_completed = 0

/// mission type -> list(description with %GOAL%, min goal, max goal)
GLOBAL_LIST_INIT(jianghu_mission_table, list(
	SECT_MISSION_PILLS = list("Refine %GOAL% pills (or temper artifacts) in an alchemy cauldron", 2, 5),
	SECT_MISSION_DUEL = list("Win %GOAL% honor duels", 1, 3),
	SECT_MISSION_HARVEST = list("Harvest %GOAL% plants", 3, 8),
	SECT_MISSION_MEDITATE = list("Meditate %GOAL% cycles beside the sect plaque", 6, 12),
	SECT_MISSION_RECRUIT = list("Accept %GOAL% new member\s into the sect", 1, 2),
	SECT_MISSION_HEART_DEMON = list("Defeat %GOAL% heart demon\s", 1, 1),
))

/// Any member's progress on their sect's mission
/proc/jianghu_mission_progress(datum/mind/member, mission, amount = 1)
	var/datum/jianghu_sect/sect = jianghu_sect_of(member)
	sect?.mission_step(mission, amount)

/datum/jianghu_sect/proc/schedule_mission(delay = 2 MINUTES)
	addtimer(CALLBACK(src, PROC_REF(issue_mission)), delay, TIMER_UNIQUE | TIMER_OVERRIDE)

/datum/jianghu_sect/proc/issue_mission()
	if(!(src in GLOB.jianghu_sects) || !length(members))
		return
	mission_type = pick(GLOB.jianghu_mission_table)
	var/list/entry = GLOB.jianghu_mission_table[mission_type]
	mission_goal = rand(entry[2], entry[3])
	mission_progress = 0
	mission_deadline = world.time + 20 MINUTES
	announce("<b>A new sect mission:</b> [mission_text()]. You have twenty minutes.")
	addtimer(CALLBACK(src, PROC_REF(expire_mission), mission_deadline), 20 MINUTES)

/datum/jianghu_sect/proc/mission_text()
	if(!mission_type)
		return "none"
	var/list/entry = GLOB.jianghu_mission_table[mission_type]
	return replacetext(entry[1], "%GOAL%", "[mission_goal]")

/datum/jianghu_sect/proc/mission_step(mission, amount)
	if(mission != mission_type || world.time > mission_deadline)
		return
	mission_progress = min(mission_progress + amount, mission_goal)
	if(mission_progress >= mission_goal)
		complete_mission()
	else
		announce("Mission progress: [mission_progress]/[mission_goal].")

/datum/jianghu_sect/proc/complete_mission()
	mission_type = null
	missions_completed++
	announce("<b>Mission complete!</b> The sect's fortune rises. Every member gains insight and face.")
	for(var/datum/mind/member as anything in members)
		var/mob/living/body = member.current
		if(!body || body.stat == DEAD)
			continue
		var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(body)
		cultivator?.gain_insight(15, "sect_mission", cooldown = 0)
		jianghu_adjust_face(body, 3, "completed a sect mission")
		body.playsound_local(get_turf(body), 'sound/effects/gong.ogg', 30, TRUE, frequency = 1.2)
	var/obj/structure/sect_plaque/plaque = get_plaque()
	if(plaque)
		new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(get_turf(plaque))
		cultivation_guqin_phrase(plaque, list(1, 2, 3, 5, 6))
	schedule_mission(5 MINUTES)

/datum/jianghu_sect/proc/expire_mission(deadline)
	if(!mission_type || mission_deadline != deadline)
		return
	announce("The sect mission ([mission_text()]) has expired, unfinished.")
	mission_type = null
	schedule_mission(5 MINUTES)

// ===================== Martial tournaments =====================

GLOBAL_DATUM(jianghu_tournament, /datum/jianghu_tournament)
/// The last tournament's champion
GLOBAL_VAR(jianghu_champion)
/// No new tournament until this world.time
GLOBAL_VAR_INIT(jianghu_tournament_cooldown, 0)

/datum/jianghu_tournament
	/// Who proclaimed it
	var/datum/jianghu_sect/host_sect
	/// mind -> duel wins
	var/list/wins = list()
	var/ends_at

/datum/jianghu_tournament/New(datum/jianghu_sect/host_sect)
	src.host_sect = host_sect
	ends_at = world.time + 10 MINUTES
	GLOB.jianghu_tournament = src
	minor_announce("The [host_sect.name] proclaims a Martial Tournament! For the next ten minutes, honor duels (start one from your Honor Duel action) win double face. \
		Whoever wins the most duels will be crowned Martial Champion.", "Martial Tournament")
	addtimer(CALLBACK(src, PROC_REF(conclude)), 10 MINUTES)

/datum/jianghu_tournament/Destroy(force)
	if(GLOB.jianghu_tournament == src)
		GLOB.jianghu_tournament = null
	host_sect = null
	wins = null
	return ..()

/datum/jianghu_tournament/proc/record(mob/living/winner)
	if(!winner?.mind)
		return
	wins[winner.mind] += 1
	for(var/mob/living/viewer in viewers(7, winner))
		to_chat(viewer, span_notice("<i>Tournament: [winner] now has [wins[winner.mind]] win\s.</i>"))

/datum/jianghu_tournament/proc/conclude()
	var/datum/mind/champion
	for(var/datum/mind/fighter as anything in wins)
		if(!champion || wins[fighter] > wins[champion])
			champion = fighter
	if(!champion)
		minor_announce("The Martial Tournament ends without a single duel. How disappointing.", "Martial Tournament")
		qdel(src)
		return
	GLOB.jianghu_champion = champion
	minor_announce("The Martial Tournament is over! [champion.name] is crowned Martial Champion with [wins[champion]] victor[wins[champion] == 1 ? "y" : "ies"]!", "Martial Tournament")
	var/mob/living/body = champion.current
	if(body)
		body.AddElement(/datum/element/jianghu_examine)
		jianghu_adjust_face(body, 10, "crowned Martial Champion")
		var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(body)
		cultivator?.gain_insight(30, "tournament_champion", cooldown = 0)
		body.add_mood_event("martial_champion", /datum/mood_event/martial_champion)
		new /obj/effect/temp_visual/cultivation_realm_banner(get_turf(body), "Martial Champion")
		new /obj/effect/temp_visual/cultivation_ascension_pillar(get_turf(body))
		cultivation_great_bell(body, 60)
	qdel(src)

/// Called whenever an honor duel is won
/proc/jianghu_tournament_record(mob/living/winner, mob/living/loser)
	GLOB.jianghu_tournament?.record(winner)

/// Plaque option for the Sect Master
/obj/structure/sect_plaque/proc/proclaim_tournament(mob/living/user)
	if(GLOB.jianghu_tournament)
		to_chat(user, span_warning("A tournament is already underway."))
		return
	if(world.time < GLOB.jianghu_tournament_cooldown)
		to_chat(user, span_warning("The jianghu is still recovering from the last tournament. ([DisplayTimeText(GLOB.jianghu_tournament_cooldown - world.time)])"))
		return
	if(tgui_alert(user, "Proclaim a station-wide Martial Tournament for ten minutes?", "Martial Tournament", list("Proclaim", "Not now")) != "Proclaim")
		return
	if(GLOB.jianghu_tournament || world.time < GLOB.jianghu_tournament_cooldown)
		return
	GLOB.jianghu_tournament_cooldown = world.time + 30 MINUTES
	new /datum/jianghu_tournament(sect)
	cultivation_great_bell(src, 70)

/datum/mood_event/martial_champion
	description = "I am the Martial Champion! Under heaven, who can match me?"
	mood_change = 8
	timeout = 30 MINUTES
