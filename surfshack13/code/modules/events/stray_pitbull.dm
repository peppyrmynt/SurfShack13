/// Cupcake the pitbull wanders into maintenance, waiting for some brave (or stupid) assistant to tame her
/datum/round_event_control/stray_pitbull
	name = "Stray Pitbull"
	typepath = /datum/round_event/stray_pitbull
	weight = 8
	max_occurrences = 1
	earliest_start = 0
	category = EVENT_CATEGORY_ENTITIES
	description = "Cupcake, a tameable but dangerous pitbull, shows up somewhere in maintenance."

/datum/round_event/stray_pitbull
	announce_chance = 50

/datum/round_event/stray_pitbull/announce(fake)
	priority_announce("Bio-scanners have detected a large, agitated canine in the station's maintenance tunnels. Crew are advised to approach with caution, and possibly with meat.", "Lifesign Alert")

/datum/round_event/stray_pitbull/start()
	var/turf/spawn_turf = find_maintenance_spawn(atmos_sensitive = TRUE, require_darkness = FALSE)
	if(isnull(spawn_turf))
		return
	var/mob/living/basic/pitbull/cupcake = new(spawn_turf)
	announce_to_ghosts(cupcake)
