/// Players per extra bull
#define BULL_STAMPEDE_PLAYERS_PER_BULL 10
/// Most bulls a stampede can spawn
#define BULL_STAMPEDE_MAX_BULLS 6

/// Rare event: a pack of bulls stampedes through the station hallways, smashing everything in their way
/datum/round_event_control/bull_stampede
	name = "Bull Stampede"
	typepath = /datum/round_event/bull_stampede
	weight = 3
	min_players = 10
	max_occurrences = 1
	earliest_start = 30 MINUTES
	category = EVENT_CATEGORY_ENTITIES
	description = "The space spaniard lost his bullfight. A pack of bulls (more with higher pop) stampedes through the station hallways."

/datum/round_event/bull_stampede
	announce_when = 1
	/// How many bulls we're letting loose
	var/bull_count = 1
	/// Where they show up
	var/turf/spawn_turf

/datum/round_event/bull_stampede/setup()
	bull_count = clamp(1 + round(length(GLOB.alive_player_list) / BULL_STAMPEDE_PLAYERS_PER_BULL), 1, BULL_STAMPEDE_MAX_BULLS)

	var/list/hallways = list()
	for(var/area_type in GLOB.the_station_areas)
		if(ispath(area_type, /area/station/hallway))
			hallways += area_type
	spawn_turf = get_safe_random_station_turf(length(hallways) ? hallways : GLOB.the_station_areas)

/datum/round_event/bull_stampede/announce(fake)
	var/where = spawn_turf ? get_area_name(spawn_turf, format_text = TRUE) : "the hallways"
	var/bulls = bull_count == 1 ? "One very angry bull is" : "[bull_count] very angry bulls are"
	var/opener = pick(
		"Olé? NO. The space spaniard lost his bullfight.",
		"The space spaniard has lost his bullfight. Badly.",
		"Bullfight's over. The bull won.",
		"Bad news from the arena: the space spaniard lost.",
	)
	var/closer = pick(
		"Get out of the hallways. Do NOT wear red.",
		"Run. Don't wave anything red. Don't be a hero.",
		"Stay off the hallways and take off anything red. Now.",
		"Hide. Ditch the red. Pray.",
	)
	priority_announce(
		"[opener] [bulls] loose in [where]. [closer]",
		"STAMPEDE!",
		'sound/mobs/non-humanoids/cow/cow.ogg',
	)

/datum/round_event/bull_stampede/start()
	if(!spawn_turf)
		return
	var/list/spawn_spots = list()
	for(var/turf/open/spot in range(2, spawn_turf))
		if(!spot.is_blocked_turf(exclude_mobs = TRUE))
			spawn_spots += spot
	if(!length(spawn_spots))
		spawn_spots += spawn_turf

	for(var/i in 1 to bull_count)
		var/turf/spot = pick(spawn_spots)
		var/mob/living/basic/bull/bull = new(spot)
		new /obj/effect/temp_visual/mook_dust(spot)
		bull.visible_message(span_danger("[bull] comes thundering in, snorting with rage!"))
		if(i == 1)
			announce_to_ghosts(bull)

#undef BULL_STAMPEDE_PLAYERS_PER_BULL
#undef BULL_STAMPEDE_MAX_BULLS
