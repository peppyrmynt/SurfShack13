/**
 * # Station fog
 *
 * A random event that rolls a dense fog bank through the station. It starts
 * as a light haze and thickens in steps over the event, closing in on anyone
 * caught in it until they can barely see a few tiles. Maintenance runs on its
 * own scrubbers and stays clear, so it doubles as the place to get your bearings.
 *
 * Two layers of visuals:
 * - an area overlay (weather style) so the fog is visible on every fogged tile,
 *   to everyone, including ghosts and cameras;
 * - a sight cut-off on living players standing in fog: past a radius that
 *   shrinks as the fog thickens the fog is solid, so nothing out there can be
 *   seen, like darkness without a flashlight. Stepping into maintenance clears it.
 *
 * - identity concealment (after tgstation#97041's unconscious obscurity): to a
 *   player in fog, or looking into it, any human or cyborg further away than
 *   the fog's conceal range shows as a flat grey silhouette of themselves. It starts at
 *   thickness 3 (4 tiles) and closes in to 3 tiles at 4 and 2 tiles at 5.
 *   Hovering gives "unknown figure", examining fails, and sec/med HUD icons
 *   on them are hidden. Voices still carry, so speech is still attributed.
 *
 * - hallucinations at thickness 4 and 5: players standing in fog see people
 *   that aren't there (a static figure in the fog, see /datum/hallucination/fog_figure)
 *   and get tg's own people hallucinations: fake speech from nearby people,
 *   distant fights and gunfire, stray bullets, someone nearby drawing a weapon.
 * - at thickness 5, the floor cluwne: one of its sounds (from HippieStation)
 *   plays from a spot in the fog, and every fogged player in earshot hears the
 *   same sound from the same place at the same time.
 *
 * - nightmare fog (admin only, see station_fog_cluwne.dm): climbs on to
 *   thickness 6. At 5 it polls ghosts to play floor cluwnes; at 6 it pours into
 *   maintenance, so nowhere is safe, with an announcement that something is
 *   moving in the fog. About 90 seconds later it dissipates, the cluwnes sink
 *   away, and everyone they dragged under is spat back out.
 *
 * Admins can drive it by hand with the "Debug Station Fog" verb.
 */

/// The fog currently rolling through the station, if any.
GLOBAL_DATUM(station_fog, /datum/weather/station_fog)

/// Thickness steps the fog climbs through, matching the fog1..fog5 icon states.
#define STATION_FOG_MAX_THICKNESS 5
/// The nightmare fog's extra step (fog6), when it reaches into maintenance.
#define STATION_FOG_NIGHTMARE_THICKNESS 6
/// How long the nightmare fog holds at thickness 6 before it dissipates.
#define STATION_FOG_NIGHTMARE_HUNT 90 SECONDS
/// Fullscreen category for the fog vignette.
#define STATION_FOG_SCREEN "station_fog"
/// Fullscreen categories for the solid strips beyond the 15x15 vignette.
#define STATION_FOG_SCREEN_WEST "station_fog_west"
#define STATION_FOG_SCREEN_EAST "station_fog_east"
#define STATION_FOG_SCREEN_NORTH "station_fog_north"
#define STATION_FOG_SCREEN_SOUTH "station_fog_south"
/// How far out to look for people to conceal; anything past this is off screen.
#define STATION_FOG_CONCEAL_SCAN 10

/datum/round_event_control/station_fog
	name = "Station Fog"
	typepath = /datum/round_event/station_fog
	weight = 10
	max_occurrences = 1
	earliest_start = 15 MINUTES
	min_players = 5
	category = EVENT_CATEGORY_SPACE
	description = "A thickening fog fills the station. Maintenance stays clear. A third of the time it's a nightmare fog: it reaches maintenance too, and a ghost plays a floor cluwne."
	min_wizard_trigger_potency = 0
	max_wizard_trigger_potency = 4
	admin_setup = list(/datum/event_admin_setup/listed_options/station_fog)

/datum/round_event/station_fog
	announce_when = 1
	start_when = 2
	end_when = 3
	/// Set by an admin forcing the event: TRUE/FALSE for nightmare or normal, null to roll.
	var/forced_nightmare
	/// How many floor cluwnes a nightmare fog polls for.
	var/cluwne_count = 1

/// Trigger Event: lets the admin pick a normal fog or a nightmare fog and its cluwne count.
/datum/event_admin_setup/listed_options/station_fog
	input_text = "What kind of fog?"
	normal_run_option = "Random (a third of the time it's a nightmare fog with 1 floor cluwne)"

/datum/event_admin_setup/listed_options/station_fog/get_list()
	return list(
		"Normal fog",
		"Nightmare fog, 1 floor cluwne",
		"Nightmare fog, 2 floor cluwnes",
		"Nightmare fog, 3 floor cluwnes",
	)

/datum/event_admin_setup/listed_options/station_fog/apply_to_event(datum/round_event/station_fog/event)
	if(!chosen)
		return
	if(chosen == "Normal fog")
		event.forced_nightmare = FALSE
		return
	event.forced_nightmare = TRUE
	event.cluwne_count = text2num(copytext(chosen, length("Nightmare fog, ") + 1))

/datum/round_event/station_fog/announce(fake)
	priority_announce("A dense vapour bank has been drawn into the station's air handling. Visibility will fall across the station as it thickens. Maintenance runs on independent scrubbers and should remain clear.", "Atmospheric Anomaly")

/// Chance the random event is a nightmare fog: thickness 6, maintenance, and a floor cluwne.
#define STATION_FOG_NIGHTMARE_CHANCE 33

/datum/round_event/station_fog/start()
	var/nightmare = isnull(forced_nightmare) ? prob(STATION_FOG_NIGHTMARE_CHANCE) : forced_nightmare
	start_station_fog(nightmare, cluwne_count)
	if(nightmare)
		message_admins("The station fog event is a NIGHTMARE fog: it will poll ghosts for [cluwne_count] floor cluwne\s at thickness 5.")
		log_game("The station fog event is a nightmare fog ([cluwne_count] floor cluwnes).")

#undef STATION_FOG_NIGHTMARE_CHANCE

/**
 * Starts a station fog, replacing any already running. The one way in for the
 * random event, Trigger Event and the debug verb alike.
 * * nightmare - climbs to 6, into maintenance, with floor cluwnes
 * * cluwne_count - how many floor cluwnes a nightmare fog polls for
 * * auto_thicken - FALSE to drive the thickness by hand (starts at 1, no timers)
 * * announce - send the arrival announcement (the random event sends its own)
 */
/proc/start_station_fog(nightmare = FALSE, cluwne_count = 1, auto_thicken = TRUE, announce = FALSE)
	GLOB.station_fog?.end()
	var/datum/weather/station_fog/fog = new(SSmapping.levels_by_trait(ZTRAIT_STATION))
	fog.nightmare = nightmare
	fog.cluwne_count = cluwne_count
	fog.auto_thicken = auto_thicken
	// Nightmare fogs and hand-driven fogs end on their own schedule, not a random duration.
	fog.perpetual = nightmare || !auto_thicken
	if(announce)
		priority_announce("A dense vapour bank has been drawn into the station's air handling. Visibility will fall across the station as it thickens. Maintenance runs on independent scrubbers and should remain clear.", "Atmospheric Anomaly")
	fog.telegraph()
	if(!auto_thicken)
		fog.start()
	return fog

/datum/weather/station_fog
	name = "station fog"
	desc = "A dense fog fills the station, thickening over time. Maintenance stays clear."

	telegraph_message = span_notice("A faint haze starts curling out of the air vents.")
	telegraph_duration = 30 SECONDS
	telegraph_overlay = "fog1"

	weather_message = span_warning("The fog rolls in properly. You can't see far through it.")
	weather_duration_lower = 4 MINUTES
	weather_duration_upper = 6 MINUTES
	weather_overlay = "fog1"

	end_message = span_notice("The fog starts thinning out as the scrubbers catch up.")
	end_duration = 30 SECONDS
	end_overlay = "fog1"

	area_type = /area/station
	protected_areas = list(/area/station/maintenance)
	target_trait = ZTRAIT_STATION
	// Fog only obscures. The vignette is driven from process() below, so the
	// subsystem never needs to call weather_act().
	aesthetic = TRUE
	use_glow = FALSE

	/// Current fog step, 1 to STATION_FOG_MAX_THICKNESS.
	var/thickness = 1
	/// Players currently wearing the fog vignette (assoc, mob -> TRUE), so
	/// leaving the fog clears it.
	var/list/mob/living/fogged_players = list()
	/// impacted_areas as an assoc set, for O(1) "is this area fogged" checks.
	var/list/fogged_area_set = list()
	/// Whether the fog thickens by itself over time. Off for admin test fogs.
	var/auto_thicken = TRUE
	/// target mob -> its anonymous-figure alternate appearance.
	var/list/disguises = list()
	/// viewer mob -> list of target mobs currently concealed from them.
	var/list/concealed_from = list()
	/// target mob -> the appearance its figure was last copied from, so figures
	/// are only repainted when the body's sprite actually changed.
	var/list/disguise_sources = list()
	/// viewer mob -> the client that was given their disguise images. Images
	/// live on the client, not the mob, so if the client moves to another body
	/// (aghost, possession, respawn) they must be taken off that client.
	var/list/viewer_clients = list()
	/// player -> world.time their next fog hallucination is due.
	var/list/next_hallucination = list()
	/// world.time the next shared floor cluwne sound is due, at thickness 5.
	var/next_cluwne_sound = 0
	/// The most recently played cluwne sound groups, newest last.
	var/list/recent_cluwne_groups = list()
	/// Admin-only nightmare fog: goes to thickness 6, maintenance included, with floor cluwnes.
	var/nightmare = FALSE
	/// How many floor cluwnes the nightmare fog polls for.
	var/cluwne_count = 1
	/// Whether the ghost poll for floor cluwnes has run.
	var/cluwnes_polled = FALSE
	/// Whether the fog has poured into maintenance (thickness 6).
	var/maintenance_fogged = FALSE
	/// The floor cluwnes hunting in this fog.
	var/list/mob/living/basic/floor_cluwne/cluwnes = list()
	/// People dragged under the floor (assoc, mob -> TRUE), spat out when it ends.
	var/list/mob/living/eaten = list()
	/// Where the dragged-under wait: a reserved tile off the station map.
	var/obj/effect/abstract/floor_cluwne_gullet/gullet
	/// The reservation that tile comes from.
	var/datum/turf_reservation/gullet_reservation

/datum/weather/station_fog/New(z_levels)
	. = ..()
	if(GLOB.station_fog && GLOB.station_fog != src)
		GLOB.station_fog.end()
	GLOB.station_fog = src

/datum/weather/station_fog/telegraph()
	. = ..()
	fogged_area_set.Cut()
	for(var/area/fogged as anything in impacted_areas)
		fogged_area_set[fogged] = TRUE
	START_PROCESSING(SSprocessing, src)

/datum/weather/station_fog/start()
	. = ..()
	if(!auto_thicken)
		return
	if(nightmare)
		// 40 seconds a step up to 5 (the cluwne poll), a minute of that, then 6.
		for(var/step in 2 to STATION_FOG_MAX_THICKNESS)
			addtimer(CALLBACK(src, PROC_REF(set_thickness), step), 40 SECONDS * (step - 1))
		addtimer(CALLBACK(src, PROC_REF(set_thickness), STATION_FOG_NIGHTMARE_THICKNESS), 40 SECONDS * (STATION_FOG_MAX_THICKNESS - 1) + 60 SECONDS)
		return
	// Thicken in even steps over the first three quarters of the fog, so the
	// last stretch sits at full thickness before it winds down.
	var/step_time = (weather_duration * 0.75) / (STATION_FOG_MAX_THICKNESS - 1)
	for(var/step in 2 to STATION_FOG_MAX_THICKNESS)
		addtimer(CALLBACK(src, PROC_REF(set_thickness), step), step_time * (step - 1))

/datum/weather/station_fog/wind_down()
	thickness = 1
	remove_cluwnes()
	return ..()

/datum/weather/station_fog/end()
	. = ..()
	if(GLOB.station_fog == src)
		GLOB.station_fog = null
	STOP_PROCESSING(SSprocessing, src)
	remove_cluwnes()
	release_victims()
	reveal_everyone()
	for(var/mob/living/player as anything in fogged_players)
		clear_fog_screens(player)
	fogged_players.Cut()

/datum/weather/station_fog/Destroy()
	if(GLOB.station_fog == src)
		GLOB.station_fog = null
	STOP_PROCESSING(SSprocessing, src)
	remove_cluwnes()
	release_victims()
	reveal_everyone()
	for(var/mob/living/player as anything in fogged_players)
		clear_fog_screens(player, animated = 0)
	fogged_players.Cut()
	return ..()

/// The thickest this fog can get: 5, or 6 for the nightmare fog.
/datum/weather/station_fog/proc/max_thickness()
	return nightmare ? STATION_FOG_NIGHTMARE_THICKNESS : STATION_FOG_MAX_THICKNESS

/datum/weather/station_fog/proc/set_thickness(new_thickness, silent = FALSE)
	if(stage != MAIN_STAGE)
		return
	var/old_thickness = thickness
	thickness = clamp(new_thickness, 1, max_thickness())
	update_areas()
	if(!silent && thickness > old_thickness)
		send_alert(span_warning("The fog grows thicker."))
	if(!nightmare)
		return
	if(thickness >= STATION_FOG_MAX_THICKNESS && !cluwnes_polled)
		INVOKE_ASYNC(src, PROC_REF(poll_for_cluwnes))
	if(thickness >= STATION_FOG_NIGHTMARE_THICKNESS && !maintenance_fogged)
		spread_to_maintenance()

/// Thickness 6: the fog pours into maintenance, so nowhere is safe, then
/// dissipates after STATION_FOG_NIGHTMARE_HUNT.
/datum/weather/station_fog/proc/spread_to_maintenance()
	maintenance_fogged = TRUE
	for(var/area/station/maintenance/maint in get_areas(/area/station/maintenance))
		for(var/z_level in impacted_z_levels)
			if(length(maint.get_turfs_by_zlevel(z_level)))
				impacted_areas |= maint
				fogged_area_set[maint] = TRUE
				break
	update_areas()
	priority_announce("Something has been detected moving within the fog. The vapour has overrun the maintenance scrubbers: no part of the station is clear. Stay together, and stay off the floor if you can.", "Unknown Lifeform Detected")
	send_alert(span_userdanger("The fog pours into the maintenance tunnels. There is nowhere left that's safe."))
	addtimer(CALLBACK(src, PROC_REF(wind_down)), STATION_FOG_NIGHTMARE_HUNT)

/datum/weather/station_fog/generate_overlay_cache()
	if(stage == END_STAGE)
		return list()
	var/fog_state = "fog[stage == MAIN_STAGE ? thickness : 1]"
	var/list/gen_overlay_cache = list()
	for(var/offset in 0 to SSmapping.max_plane_offset)
		gen_overlay_cache += mutable_appearance('surfshack13/icons/effects/station_fog.dmi', fog_state, overlay_layer, plane = overlay_plane, offset_const = offset)
	return gen_overlay_cache

/// Keeps the vignette on exactly the living players standing in fog.
/datum/weather/station_fog/process(seconds_per_tick)
	// The vignette only appears once the fog has properly rolled in.
	var/vignette_level = stage == MAIN_STAGE ? thickness : 0
	var/list/still_fogged = list()
	for(var/z_level in impacted_z_levels)
		for(var/mob/living/player in SSmobs.clients_by_zlevel[z_level])
			if(!vignette_level || !can_weather_act(player))
				continue
			apply_fog_screens(player, vignette_level)
			still_fogged[player] = TRUE
	for(var/mob/living/player as anything in fogged_players - still_fogged)
		if(!QDELETED(player))
			clear_fog_screens(player)
	fogged_players = still_fogged
	update_concealment()
	roll_hallucinations()
	roll_cluwne_sound()

// ---- Hallucinations ----------------------------------------------------

/// What the fog makes people see, weighted. The figure is the fog's own; the
/// rest are tg's existing people hallucinations.
GLOBAL_LIST_INIT(station_fog_hallucinations, list(
	/datum/hallucination/fog_figure = 40,
	/datum/hallucination/chat = 15,
	/datum/hallucination/battle/gun/disabler = 5,
	/datum/hallucination/battle/gun/laser = 5,
	/datum/hallucination/battle/e_sword = 4,
	/datum/hallucination/battle/harm_baton = 4,
	/datum/hallucination/battle/stun_prod = 3,
	/datum/hallucination/stray_bullet = 6,
	/datum/hallucination/nearby_fake_item/e_sword = 3,
	/datum/hallucination/nearby_fake_item/taser = 3,
	/datum/hallucination/nearby_fake_item/baton = 3,
	/datum/hallucination/nearby_fake_item/armblade = 2,
))

/// From thickness 4, every so often (more often the thicker it is), makes each
/// player in fog see things.
/datum/weather/station_fog/proc/roll_hallucinations()
	if(stage != MAIN_STAGE || thickness < 4)
		return
	for(var/mob/living/player as anything in fogged_players)
		if(player.stat != CONSCIOUS || (player.mob_biotypes & NO_HALLUCINATION_BIOTYPES))
			continue
		var/due = next_hallucination[player]
		if(!due)
			// First one comes a little after the fog gets this thick.
			next_hallucination[player] = world.time + rand(5 SECONDS, 20 SECONDS)
			continue
		if(world.time < due)
			continue
		var/delay
		switch(thickness)
			if(4)
				delay = rand(20 SECONDS, 35 SECONDS)
			if(5)
				delay = rand(12 SECONDS, 25 SECONDS)
			else
				delay = rand(8 SECONDS, 18 SECONDS)
		next_hallucination[player] = world.time + delay
		// Some hallucinations need room or company to start (a figure needs open
		// fog in view, a drawn weapon needs someone nearby). If the one rolled
		// can't happen here, roll another rather than wasting the turn.
		var/list/tried = list()
		for(var/attempt in 1 to 3)
			var/picked = pick_weight(GLOB.station_fog_hallucinations - tried)
			tried += picked
			if(fog_hallucinate(player, picked))
				break
			if(attempt == 3)
				// Distant gunfire can always happen.
				fog_hallucinate(player, /datum/hallucination/battle/gun/disabler)

/// Gives [player] one fog hallucination, picked from the weighted pool.
/datum/weather/station_fog/proc/fog_hallucinate(mob/living/player, hallucination_type)
	hallucination_type ||= pick_weight(GLOB.station_fog_hallucinations)
	if(hallucination_type == /datum/hallucination/fog_figure)
		return player.cause_hallucination(hallucination_type, "station fog", vanish_range = get_conceal_range() || 2)
	return player.cause_hallucination(hallucination_type, "station fog")

// ---- Floor cluwne ------------------------------------------------------

/**
 * What the floor cluwne sounds like, as groups of interchangeable takes
 * (group -> list(weight, files...)). A group heard recently won't come up
 * again (see STATION_FOG_CLUWNE_NO_REPEAT), so it never loops one sound.
 *
 * Laughs, breathing, feast, creepy horn, distant honk and giggle are
 * HippieStation's (surfshack13/sound/hippie); the voice lines are the floor
 * cluwne's own hallucination lines, which Surf already has, plus a few of
 * Surf's clown laughs.
 */
GLOBAL_LIST_INIT(station_fog_cluwne_sounds, list(
	"breathing" = list(6, 'surfshack13/sound/hippie/cluwne_breathing.ogg'),
	"cluwne laugh" = list(6, 'surfshack13/sound/hippie/cluwnelaugh1.ogg', 'surfshack13/sound/hippie/cluwnelaugh2.ogg', 'surfshack13/sound/hippie/cluwnelaugh3.ogg'),
	"reversed laugh" = list(4, 'surfshack13/sound/hippie/cluwnelaugh2_reversed.ogg'),
	"feast" = list(2, 'surfshack13/sound/hippie/cluwne_feast.ogg'),
	"creepy horn" = list(4, 'surfshack13/sound/hippie/bikehorn_creepy.ogg'),
	"distant honk" = list(4, 'surfshack13/sound/hippie/honk_echo_distant.ogg'),
	"giggle" = list(4, 'surfshack13/sound/hippie/scrake_giggle.ogg'),
	"scary horn" = list(2, 'sound/misc/scary_horn.ogg'),
	"clown laugh" = list(4, 'sound/mobs/non-humanoids/clown/hehe.ogg', 'sound/mobs/non-humanoids/clown/hohoho.ogg'),
	"evil laugh" = list(2, 'sound/mobs/non-humanoids/honkbot/honkbot_evil_laugh.ogg'),
	"low laugh" = list(2, 'sound/misc/insane_low_laugh.ogg'),
	"behind you" = list(2, 'sound/effects/hallucinations/behind_you1.ogg', 'sound/effects/hallucinations/behind_you2.ogg'),
	"im here" = list(1, 'sound/effects/hallucinations/im_here1.ogg', 'sound/effects/hallucinations/im_here2.ogg'),
	"i see you" = list(1, 'sound/effects/hallucinations/i_see_you1.ogg', 'sound/effects/hallucinations/i_see_you2.ogg'),
	"over here" = list(1, 'sound/effects/hallucinations/over_here1.ogg', 'sound/effects/hallucinations/over_here2.ogg', 'sound/effects/hallucinations/over_here3.ogg'),
	"turn around" = list(1, 'sound/effects/hallucinations/turn_around1.ogg', 'sound/effects/hallucinations/turn_around2.ogg'),
	"look up" = list(1, 'sound/effects/hallucinations/look_up1.ogg', 'sound/effects/hallucinations/look_up2.ogg'),
))

/// Cluwne sound groups that are laughter: hearing one sours your mood.
GLOBAL_LIST_INIT(station_fog_cluwne_laughs, list(
	"cluwne laugh",
	"reversed laugh",
	"giggle",
	"clown laugh",
	"evil laugh",
	"low laugh",
))

/// Which group a cluwne sound file belongs to.
/proc/station_fog_cluwne_group(sound_file)
	for(var/group in GLOB.station_fog_cluwne_sounds)
		var/list/entry = GLOB.station_fog_cluwne_sounds[group]
		if(sound_file in entry)
			return group
	return null

/// How many of the most recent cluwne sound groups can't be picked again.
#define STATION_FOG_CLUWNE_NO_REPEAT 5

/// How far a shared cluwne sound carries through the fog.
#define STATION_FOG_CLUWNE_RANGE 18

/**
 * How near the cluwne seems: distance from the chosen player in tiles, base
 * volume, and how muffled (in millibels, negative is more muffled) it is.
 * DirectHF cuts the highs off the sound; Occlusion makes it sound like it's
 * coming through something. Listeners further from the spot also hear it
 * quieter, through playsound_local's own distance falloff.
 */
GLOBAL_LIST_INIT(station_fog_cluwne_distances, list(
	list("name" = "close", "min" = 3, "max" = 5, "volume" = 75, "direct_hf" = 0, "occlusion" = 0, "weight" = 25),
	list("name" = "out there", "min" = 6, "max" = 9, "volume" = 50, "direct_hf" = -1200, "occlusion" = -800, "weight" = 40),
	list("name" = "distant", "min" = 10, "max" = 14, "volume" = 35, "direct_hf" = -3000, "occlusion" = -2500, "weight" = 35),
))

/// Picks a cluwne sound from a group that hasn't played recently.
/datum/weather/station_fog/proc/pick_cluwne_sound()
	var/list/weighted = list()
	for(var/group in GLOB.station_fog_cluwne_sounds)
		if(group in recent_cluwne_groups)
			continue
		var/list/entry = GLOB.station_fog_cluwne_sounds[group]
		weighted[group] = entry[1]
	var/group = pick_weight(weighted)
	recent_cluwne_groups += group
	while(length(recent_cluwne_groups) > STATION_FOG_CLUWNE_NO_REPEAT)
		recent_cluwne_groups.Cut(1, 2)
	var/list/entry = GLOB.station_fog_cluwne_sounds[group]
	return pick(entry.Copy(2))

/// At thickness 5, every so often, the floor cluwne makes itself heard.
/datum/weather/station_fog/proc/roll_cluwne_sound()
	if(stage != MAIN_STAGE || thickness < STATION_FOG_MAX_THICKNESS)
		next_cluwne_sound = 0
		return
	if(!next_cluwne_sound)
		next_cluwne_sound = world.time + rand(10 SECONDS, 25 SECONDS)
		return
	if(world.time < next_cluwne_sound)
		return
	next_cluwne_sound = world.time + rand(40 SECONDS, 90 SECONDS)
	play_cluwne_sound()

/**
 * Plays one floor cluwne sound from a spot in the fog near a random fogged
 * player, to every fogged player in earshot of it, so a group standing
 * together all hear the same thing from the same place. Each one picks how
 * far off it seems (close and clear, out there, or distant and muffled). It's
 * a hallucination: nobody outside the fog hears anything. Returns how many
 * heard it.
 */
/datum/weather/station_fog/proc/play_cluwne_sound(mob/living/near, sound_file)
	var/list/candidates = list()
	for(var/mob/living/player as anything in fogged_players)
		if(player.stat == CONSCIOUS && !(player.mob_biotypes & NO_HALLUCINATION_BIOTYPES))
			candidates += player
	if(!near)
		if(!length(candidates))
			return 0
		near = pick(candidates)

	var/list/weighted = list()
	for(var/list/profile as anything in GLOB.station_fog_cluwne_distances)
		weighted[profile] = profile["weight"]
	var/list/profile = pick_weight(weighted)

	// A fogged spot at that distance; fall back to anywhere fogged nearby.
	var/list/spots = list()
	var/list/fallback = list()
	for(var/turf/open/spot in range(profile["max"], near))
		if(!fogged_area_set[get_area(spot)])
			continue
		var/dist = get_dist(near, spot)
		if(dist >= profile["min"])
			spots += spot
		else if(dist >= 3)
			fallback += spot
	var/turf/origin = length(spots) ? pick(spots) : (length(fallback) ? pick(fallback) : get_turf(near))
	sound_file ||= pick_cluwne_sound()
	var/is_laugh = (station_fog_cluwne_group(sound_file) in GLOB.station_fog_cluwne_laughs)
	// Everyone hears the same pitch, so it reads as one thing out there.
	var/pitch = rand(85, 110) / 100

	var/heard = 0
	for(var/mob/living/listener as anything in candidates | near)
		if(listener.z != origin.z || get_dist(listener, origin) > STATION_FOG_CLUWNE_RANGE)
			continue
		var/sound/cluwne_sound = sound(sound_file)
		cluwne_sound.frequency = pitch
		cluwne_sound.echo[2] = profile["direct_hf"]
		cluwne_sound.echo[7] = profile["occlusion"]
		listener.playsound_local(origin, null, profile["volume"], FALSE, max_distance = STATION_FOG_CLUWNE_RANGE + 4, sound_to_use = cluwne_sound)
		if(is_laugh)
			listener.add_mood_event("station_fog_laugh", /datum/mood_event/station_fog_laugh)
		heard++
	return heard

#undef STATION_FOG_CLUWNE_RANGE
#undef STATION_FOG_CLUWNE_NO_REPEAT

// ---- Identity concealment ----------------------------------------------

/// TRUE if the fog is currently hiding who [target] is from [viewer].
/datum/weather/station_fog/proc/is_concealed_from(atom/target, mob/viewer)
	var/list/hidden = concealed_from[viewer]
	return hidden && (target in hidden)

/// How close someone must be to be recognised at the current thickness, or
/// null while the fog is too thin to hide anyone.
/datum/weather/station_fog/proc/get_conceal_range()
	switch(thickness)
		if(3)
			return 4
		if(4)
			return 3
		if(5)
			return 2
		if(6)
			return 1
	return null

/// Whether a mob is something the fog disguises: people and cyborgs.
/datum/weather/station_fog/proc/can_disguise(mob/living/target)
	return ishuman(target) || iscyborg(target)

/// Re-decides, for every player near the fog, which people they can't make out.
/datum/weather/station_fog/proc/update_concealment()
	drop_moved_clients()
	var/list/new_concealed = list()
	/// Every body concealed from at least one viewer this tick.
	var/list/in_use = list()
	var/conceal_range = get_conceal_range()
	if(stage == MAIN_STAGE && conceal_range)
		for(var/z_level in impacted_z_levels)
			for(var/mob/living/viewer in SSmobs.clients_by_zlevel[z_level])
				// Floor cluwnes and the like see straight through the fog, and
				// anyone not actually on the map has nothing to look at.
				if(HAS_TRAIT(viewer, TRAIT_WEATHER_IMMUNE) || !isturf(viewer.loc))
					continue
				var/viewer_fogged = fogged_players[viewer]
				var/list/hide_here = list()
				// The spatial grid hands back only the hearing-sensitive atoms in
				// nearby grid cells, instead of every atom on 400-odd turfs.
				for(var/mob/living/target in SSspatial_grid.orthogonal_range_search(viewer, SPATIAL_GRID_CONTENTS_TYPE_HEARING, STATION_FOG_CONCEAL_SCAN))
					if(target == viewer || !can_disguise(target))
						continue
					if(get_dist(viewer, target) <= conceal_range)
						continue
					// Either side being in the fog is enough: looking out of
					// maintenance into a fogged hall still hides who is in it.
					if(!viewer_fogged && !fogged_area_set[get_area(target)])
						continue
					hide_here += target
					in_use[target] = TRUE
				if(length(hide_here))
					new_concealed[viewer] = hide_here
	for(var/mob/viewer as anything in concealed_from | new_concealed)
		var/list/old_hidden = concealed_from[viewer] || list()
		var/list/new_hidden = new_concealed[viewer] || list()
		for(var/mob/living/target as anything in old_hidden - new_hidden)
			reveal_to(target, viewer)
		for(var/mob/living/target as anything in new_hidden - old_hidden)
			conceal_from(target, viewer)
	concealed_from = new_concealed
	// Keep figures in step with their bodies, but only repaint the ones someone
	// is looking at, and only when the body's sprite actually changed.
	for(var/mob/living/target as anything in in_use)
		if(disguise_sources[target] != target.appearance)
			refresh_disguise(target)
	strip_own_disguises()

/// The anonymous figure for [target], made on first use: their own shape,
/// flattened to fog grey, so you can see someone's there but not who.
/datum/weather/station_fog/proc/get_disguise(mob/living/target)
	var/datum/atom_hud/alternate_appearance/basic/station_fog/disguise = disguises[target]
	if(disguise)
		return disguise
	var/image/figure = image(loc = target)
	disguise = target.add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/station_fog, "[REF(target)]_station_fog", figure, NONE)
	disguises[target] = disguise
	refresh_disguise(target)
	RegisterSignal(target, COMSIG_QDELETING, PROC_REF(on_target_deleted), override = TRUE)
	return disguise

/// Copies the body's current shape onto its figure, flattened to fog grey.
/datum/weather/station_fog/proc/refresh_disguise(mob/living/target)
	var/datum/atom_hud/alternate_appearance/basic/station_fog/disguise = disguises[target]
	if(!disguise)
		return
	var/image/figure = disguise.image
	disguise_sources[target] = target.appearance
	figure.appearance = target.appearance
	figure.appearance_flags |= KEEP_TOGETHER
	figure.color = list(0,0,0, 0,0,0, 0,0,0, 0.48,0.5,0.53)
	figure.override = TRUE
	figure.name = iscyborg(target) ? "unknown cyborg" : "unknown figure"
	figure.desc = "You can't make out who that is through the fog."
	figure.loc = target

/datum/weather/station_fog/proc/conceal_from(mob/living/target, mob/viewer)
	if(target == viewer || !viewer.client)
		return
	var/datum/atom_hud/alternate_appearance/basic/station_fog/disguise = get_disguise(target)
	disguise.show_to(viewer)
	viewer_clients[viewer] = viewer.client
	// Sec and med HUD icons would give the game away: hide this body's.
	for(var/datum/atom_hud/data/human/hud in GLOB.huds)
		hud.hide_single_atomhud_from(viewer, target)

/datum/weather/station_fog/proc/reveal_to(mob/living/target, mob/viewer)
	var/datum/atom_hud/alternate_appearance/basic/station_fog/disguise = disguises[target]
	// Whichever client got the image, take it back off that client directly.
	var/client/given_to = viewer_clients[viewer]
	if(disguise)
		given_to?.images -= disguise.image
		viewer?.client?.images -= disguise.image
	if(QDELETED(target) || QDELETED(viewer))
		return
	disguise?.hide_from(viewer, absolute = TRUE)
	for(var/datum/atom_hud/data/human/hud in GLOB.huds)
		hud.unhide_single_atomhud_from(viewer, target)

/datum/weather/station_fog/proc/on_target_deleted(mob/living/source)
	SIGNAL_HANDLER
	for(var/mob/viewer as anything in concealed_from)
		concealed_from[viewer] -= source
	qdel(disguises[source])
	disguises -= source
	disguise_sources -= source

/// If a viewer's client has left their body (aghost, possession, respawn),
/// strips every disguise image off the client that had them, before that
/// client ends up looking at one of those bodies from the inside.
/datum/weather/station_fog/proc/drop_moved_clients()
	for(var/mob/viewer as anything in concealed_from.Copy())
		var/client/given_to = viewer_clients[viewer]
		if(!QDELETED(viewer) && viewer.client == given_to)
			continue
		for(var/mob/living/target as anything in concealed_from[viewer])
			reveal_to(target, viewer)
		concealed_from -= viewer
		viewer_clients -= viewer

/// Nobody ever sees their own disguise, however they came by it.
/datum/weather/station_fog/proc/strip_own_disguises()
	for(var/mob/living/target as anything in disguises)
		var/datum/atom_hud/alternate_appearance/basic/station_fog/disguise = disguises[target]
		if(target.client && disguise)
			target.client.images -= disguise.image

/// Lifts every disguise, for when the fog ends.
/datum/weather/station_fog/proc/reveal_everyone()
	for(var/mob/viewer as anything in concealed_from)
		for(var/mob/living/target as anything in concealed_from[viewer])
			reveal_to(target, viewer)
	concealed_from.Cut()
	viewer_clients.Cut()
	for(var/mob/living/target as anything in disguises)
		UnregisterSignal(target, COMSIG_QDELETING)
		qdel(disguises[target])
	disguises.Cut()
	disguise_sources.Cut()

/// The fog's anonymous figure. Shown per viewer by the fog, never generically.
/// Turns with its body (lying down, etc) straight away, rather than waiting
/// for the next repaint.
/datum/atom_hud/alternate_appearance/basic/station_fog

/datum/atom_hud/alternate_appearance/basic/station_fog/New(key, image/shown_image, options)
	. = ..()
	RegisterSignal(target, COMSIG_LIVING_POST_UPDATE_TRANSFORM, PROC_REF(turn_image))

/datum/atom_hud/alternate_appearance/basic/station_fog/proc/turn_image(datum/source, ...)
	SIGNAL_HANDLER
	image.transform = target.transform

/datum/atom_hud/alternate_appearance/basic/station_fog/mobShouldSee(mob/M)
	return FALSE

/**
 * Puts the sight cut-off on a player. The vignette is the standard 15x15
 * fullscreen, drawn unscaled so its clear circle stays round. Any view wider
 * or taller than that gets solid fog strips over the extra rows and columns.
 * Everything stays inside the view, because a screen object outside it makes
 * BYOND zoom the whole map out to fit it.
 */
/datum/weather/station_fog/proc/apply_fog_screens(mob/living/player, level)
	player.overlay_fullscreen(STATION_FOG_SCREEN, /atom/movable/screen/fullscreen/station_fog, level)
	var/list/view_size = getviewsize(player.client?.view || world.view)
	if(view_size[1] > FULLSCREEN_OVERLAY_RESOLUTION_X)
		player.overlay_fullscreen(STATION_FOG_SCREEN_WEST, /atom/movable/screen/fullscreen/station_fog_fill/west, level)
		player.overlay_fullscreen(STATION_FOG_SCREEN_EAST, /atom/movable/screen/fullscreen/station_fog_fill/east, level)
	else
		player.clear_fullscreen(STATION_FOG_SCREEN_WEST, animated = 0)
		player.clear_fullscreen(STATION_FOG_SCREEN_EAST, animated = 0)
	if(view_size[2] > FULLSCREEN_OVERLAY_RESOLUTION_Y)
		player.overlay_fullscreen(STATION_FOG_SCREEN_NORTH, /atom/movable/screen/fullscreen/station_fog_fill/north, level)
		player.overlay_fullscreen(STATION_FOG_SCREEN_SOUTH, /atom/movable/screen/fullscreen/station_fog_fill/south, level)
	else
		player.clear_fullscreen(STATION_FOG_SCREEN_NORTH, animated = 0)
		player.clear_fullscreen(STATION_FOG_SCREEN_SOUTH, animated = 0)

/datum/weather/station_fog/proc/clear_fog_screens(mob/living/player, animated = 10)
	for(var/category in list(STATION_FOG_SCREEN, STATION_FOG_SCREEN_WEST, STATION_FOG_SCREEN_EAST, STATION_FOG_SCREEN_NORTH, STATION_FOG_SCREEN_SOUTH))
		player.clear_fullscreen(category, animated)

/// The 15x15 distance falloff: fog gets denser further out, no hard clear ring.
/atom/movable/screen/fullscreen/station_fog
	icon = 'surfshack13/icons/effects/station_fog_vignette.dmi'
	icon_state = "fog"
	layer = FULLSCREEN_LAYER

// Never stretched to the view width like other fullscreens: that would squash
// the clear circle into an oval. The fill strips cover the extra width instead.
/atom/movable/screen/fullscreen/station_fog/update_for_view(client_view)
	view = client_view

/// Solid fog over whatever the view has beyond the 15x15 vignette.
/atom/movable/screen/fullscreen/station_fog_fill
	icon = 'surfshack13/icons/effects/station_fog_fill.dmi'
	icon_state = "fog"
	layer = FULLSCREEN_LAYER

/atom/movable/screen/fullscreen/station_fog_fill/west
	screen_loc = "WEST,SOUTH to CENTER-8,NORTH"

/atom/movable/screen/fullscreen/station_fog_fill/east
	screen_loc = "CENTER+8,SOUTH to EAST,NORTH"

/atom/movable/screen/fullscreen/station_fog_fill/north
	screen_loc = "CENTER-7,CENTER+8 to CENTER+7,NORTH"

/atom/movable/screen/fullscreen/station_fog_fill/south
	screen_loc = "CENTER-7,SOUTH to CENTER+7,CENTER-8"

// =========================================================================
// ADMIN TESTING
// =========================================================================

ADMIN_VERB(debug_station_fog, R_FUN, "Debug Station Fog", "Start, stop or set the thickness of the station fog to test how each stage looks.", ADMIN_CATEGORY_EVENTS)
	var/datum/weather/station_fog/fog = GLOB.station_fog
	var/list/options = list()
	for(var/level in 1 to (fog ? fog.max_thickness() : STATION_FOG_MAX_THICKNESS))
		options += "Thickness [level][fog?.stage == MAIN_STAGE && fog.thickness == level ? " (current)" : ""]"
	options += "Start NIGHTMARE fog (level 6, maintenance, floor cluwnes)"
	if(fog?.nightmare)
		options += "Repoll ghosts for floor cluwnes"
		options += "Make a player a floor cluwne"
		options += "Send the floor cluwnes away"
	options += "Hallucinate a fog figure (me)"
	options += "Hallucinate something random from the fog pool (me)"
	options += "Play a shared floor cluwne sound (near me)"
	options += "Resume automatic thickening"
	options += "Stop fog"
	var/choice = tgui_input_list(user, "Station fog is [fog ? "active" : "not active"]. Picking a thickness starts a test fog instantly (no telegraph, no timer) if none is running.", "Debug Station Fog", options)
	if(!choice)
		return
	fog = GLOB.station_fog
	if(findtext(choice, "Start NIGHTMARE") == 1)
		if(fog && tgui_alert(user, "A fog is already running. End it and start the nightmare fog?", "Nightmare fog", list("Yes", "No")) != "Yes")
			return
		var/count = tgui_input_number(user, "How many floor cluwnes should it poll ghosts for?", "Nightmare fog", 1, 3, 1)
		if(!count)
			return
		var/timeline = tgui_alert(user, "Run it automatically (thickens to 5 over ~3 minutes, polls for cluwnes, 6 a minute later, then 90 seconds of hunting), or drive it by hand with the thickness options (5 polls, 6 spreads into maintenance and starts the 90 second clock)?", "Nightmare fog", list("Automatic", "By hand"))
		if(!timeline)
			return
		fog = start_station_fog(TRUE, count, timeline == "Automatic", announce = TRUE)
		message_admins("[key_name_admin(user)] started a NIGHTMARE station fog with [count] floor cluwne\s ([timeline]).")
		log_admin("[key_name(user)] started a nightmare station fog with [count] floor cluwnes ([timeline]).")
		BLACKBOX_LOG_ADMIN_VERB("Debug Station Fog")
		return
	if(choice == "Repoll ghosts for floor cluwnes")
		if(fog.stage != MAIN_STAGE || fog.thickness < STATION_FOG_MAX_THICKNESS)
			to_chat(user, span_warning("Floor cluwnes come at thickness 5 or 6. Set the fog to 5 first."))
			return
		var/count = tgui_input_number(user, "Poll for how many more floor cluwnes? ([length(fog.cluwnes)] hunting now.)", "Repoll floor cluwnes", 1, 3, 1)
		if(!count)
			return
		fog.repoll_cluwnes(count)
		message_admins("[key_name_admin(user)] repolled ghosts for [count] floor cluwne\s.")
		log_admin("[key_name(user)] repolled ghosts for [count] floor cluwnes.")
		return
	if(choice == "Make a player a floor cluwne")
		var/list/candidates = list()
		for(var/mob/player as anything in GLOB.player_list)
			if(player.client && !istype(player, /mob/living/basic/floor_cluwne) && !isnewplayer(player))
				candidates["[player.real_name] ([player.ckey])[isobserver(player) ? " - ghost" : ""]"] = player
		var/picked = tgui_input_list(user, "Who becomes a floor cluwne? A living player leaves their body behind.", "Make a floor cluwne", sort_list(candidates))
		if(!picked)
			return
		var/mob/target = candidates[picked]
		if(!isobserver(target) && tgui_alert(user, "[target] is alive. They'll leave their body to become the cluwne, and come back as a ghost. Continue?", "Make a floor cluwne", list("Yes", "No")) != "Yes")
			return
		var/mob/living/basic/floor_cluwne/cluwne = fog.make_player_cluwne(target)
		if(cluwne)
			message_admins("[key_name_admin(user)] made [key_name_admin(cluwne)] a floor cluwne.")
			log_admin("[key_name(user)] made [key_name(cluwne)] a floor cluwne.")
		else
			to_chat(user, span_warning("Couldn't find fogged floor to put a cluwne on."))
		return
	if(choice == "Send the floor cluwnes away")
		fog.remove_cluwnes()
		message_admins("[key_name_admin(user)] sent the floor cluwnes away.")
		log_admin("[key_name(user)] sent the floor cluwnes away.")
		return
	if(choice == "Stop fog")
		if(!fog)
			to_chat(user, span_warning("There's no station fog running."))
			return
		fog.end()
		message_admins("[key_name_admin(user)] stopped the station fog.")
		log_admin("[key_name(user)] stopped the station fog.")
		return
	if(findtext(choice, "Play a shared floor cluwne") == 1)
		if(!fog || !isliving(user.mob))
			to_chat(user, span_warning("Start a fog and be in a living body first."))
			return
		var/heard = fog.play_cluwne_sound(user.mob)
		to_chat(user, span_notice("[heard] player\s in the fog heard it."))
		return
	if(findtext(choice, "Hallucinate") == 1)
		if(!fog)
			to_chat(user, span_warning("Start a fog first, the figure only appears inside it."))
			return
		if(!isliving(user.mob))
			to_chat(user, span_warning("You need to be in a living body for that."))
			return
		var/datum/hallucination/caused = fog.fog_hallucinate(user.mob, findtext(choice, "figure") ? /datum/hallucination/fog_figure : null)
		if(!caused)
			to_chat(user, span_warning("That hallucination couldn't start here (for the figure: you need fogged floor 4-7 tiles away in view)."))
		return
	if(!fog)
		fog = new /datum/weather/station_fog(SSmapping.levels_by_trait(ZTRAIT_STATION))
		fog.auto_thicken = FALSE
		fog.perpetual = TRUE
		fog.telegraph()
		fog.start()
	if(choice == "Resume automatic thickening")
		fog.auto_thicken = TRUE
		var/remaining_steps = fog.max_thickness() - fog.thickness
		var/step_time = fog.nightmare ? 40 SECONDS : 2 MINUTES
		for(var/step in 1 to remaining_steps)
			addtimer(CALLBACK(fog, TYPE_PROC_REF(/datum/weather/station_fog, set_thickness), fog.thickness + step), step_time * step)
		// A nightmare fog winds itself down 90 seconds after reaching 6.
		if(!fog.nightmare)
			fog.perpetual = FALSE
			addtimer(CALLBACK(fog, TYPE_PROC_REF(/datum/weather, wind_down)), step_time * (remaining_steps + 1))
		message_admins("[key_name_admin(user)] set the station fog to thicken on its own.")
		log_admin("[key_name(user)] set the station fog to thicken on its own.")
		return
	var/level = text2num(copytext(choice, length("Thickness ") + 1))
	fog.set_thickness(level, silent = TRUE)
	message_admins("[key_name_admin(user)] set the station fog to thickness [level].")
	log_admin("[key_name(user)] set the station fog to thickness [level].")
	BLACKBOX_LOG_ADMIN_VERB("Debug Station Fog")

#undef STATION_FOG_MAX_THICKNESS
#undef STATION_FOG_NIGHTMARE_THICKNESS
#undef STATION_FOG_NIGHTMARE_HUNT
#undef STATION_FOG_SCREEN
#undef STATION_FOG_SCREEN_WEST
#undef STATION_FOG_SCREEN_EAST
#undef STATION_FOG_SCREEN_NORTH
#undef STATION_FOG_SCREEN_SOUTH
#undef STATION_FOG_CONCEAL_SCAN

/**
 * # Fog figure
 *
 * Someone standing in the fog who isn't there. Shown only to the hallucinator,
 * as the same static figure the fog uses for real people it conceals, so the
 * two can't be told apart from a distance. It fades in on fogged floor just
 * past recognition range, may drift around or creep closer, may whisper, and
 * dissolves the moment you get close enough to see who it would be.
 */
/datum/hallucination/fog_figure
	random_hallucination_weight = 0 // fog only
	/// Get this close and the figure dissolves.
	var/vanish_range = 2
	/// The figure, as shown to the hallucinator.
	var/image/figure
	/// "wander" (walks, with pauses), "approach" (runs at you), "run_past"
	/// (runs across the fog in one direction) or "still".
	var/behaviour
	/// For run_past: the direction it is running.
	var/run_dir
	/// The pending step timer.
	var/step_timer
	/// Whether it's already dissolving.
	var/vanishing = FALSE

/datum/hallucination/fog_figure/New(mob/living/hallucinator, vanish_range = 2)
	src.vanish_range = vanish_range
	return ..()

/datum/hallucination/fog_figure/start()
	if(!hallucinator.client)
		return FALSE
	var/datum/weather/station_fog/fog = GLOB.station_fog
	var/list/spots = list()
	for(var/turf/open/spot in view(7, hallucinator))
		if(get_dist(hallucinator, spot) <= vanish_range + 1 || spot.is_blocked_turf())
			continue
		if(fog && !fog.fogged_area_set[get_area(spot)])
			continue
		spots += spot
	if(!length(spots))
		return FALSE
	var/turf/spot = pick(spots)
	figure = image('icons/effects/effects.dmi', spot, "static", MOB_LAYER)
	SET_PLANE_EXPLICIT(figure, GAME_PLANE, spot)
	figure.name = "unknown humanoid"
	figure.dir = get_dir(spot, hallucinator)
	figure.alpha = 0
	hallucinator.client.images |= figure
	animate(figure, alpha = 255, time = 1.5 SECONDS)
	behaviour = pick(30; "wander", 30; "approach", 20; "run_past", 20; "still")
	if(behaviour == "run_past")
		// Across the player's line of sight, not straight at or away from them.
		var/toward = get_dir(spot, hallucinator)
		run_dir = pick(turn(toward, 90), turn(toward, -90))
		if(!(run_dir in GLOB.cardinals))
			run_dir = pick(GLOB.cardinals)
	feedback_details += "Figure: [behaviour]"
	if(prob(30))
		addtimer(CALLBACK(src, PROC_REF(whisper)), rand(2 SECONDS, 5 SECONDS))
	// Let it fade in before it starts moving.
	queue_step(1 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(vanish)), rand(8 SECONDS, 16 SECONDS))
	return TRUE

/// Movement speed per tile, matched to real spacemen from the server config.
/datum/hallucination/fog_figure/proc/step_delay()
	if(behaviour == "wander")
		return CONFIG_GET(number/movedelay/walk_delay)
	return CONFIG_GET(number/movedelay/run_delay)

/datum/hallucination/fog_figure/proc/queue_step(delay)
	step_timer = addtimer(CALLBACK(src, PROC_REF(figure_step)), max(delay, world.tick_lag), TIMER_STOPPABLE)

/// One beat: dissolve if they got close, otherwise take a step at walk or run speed.
/datum/hallucination/fog_figure/proc/figure_step()
	step_timer = null
	if(vanishing || QDELETED(hallucinator))
		return
	var/turf/here = figure.loc
	if(!here || here.z != hallucinator.z || get_dist(hallucinator, here) <= vanish_range)
		vanish()
		return
	var/delay = step_delay()
	switch(behaviour)
		if("still")
			figure.dir = get_dir(here, hallucinator)
			queue_step(0.5 SECONDS)
			return
		if("wander")
			// Walkers stop and look around now and then.
			if(prob(35))
				figure.dir = get_dir(here, hallucinator)
				queue_step(rand(5, 15))
				return
	var/turf/open/next
	switch(behaviour)
		if("approach")
			next = get_step_towards(here, hallucinator)
		if("run_past")
			next = get_step(here, run_dir)
		else
			next = get_step(here, pick(GLOB.cardinals))
	if(!istype(next) || next.is_blocked_turf() || get_dist(hallucinator, next) <= vanish_range)
		// A runner that hits a wall or the edge of the fog just isn't there any more.
		if(behaviour == "run_past" || behaviour == "approach")
			if(get_dist(hallucinator, next) <= vanish_range || behaviour == "run_past")
				vanish()
				return
		queue_step(delay)
		return
	// Glide: jump the image to the new tile, offset back, slide the offset out
	// over exactly one step, so it moves as smoothly as a real spaceman.
	var/step_dir = get_dir(here, next)
	figure.loc = next
	figure.dir = step_dir
	figure.pixel_x = (step_dir & EAST) ? -32 : ((step_dir & WEST) ? 32 : 0)
	figure.pixel_y = (step_dir & NORTH) ? -32 : ((step_dir & SOUTH) ? 32 : 0)
	animate(figure, pixel_x = 0, pixel_y = 0, time = delay)
	queue_step(delay)

/// The figure says something, quietly, as an unknown voice.
/datum/hallucination/fog_figure/proc/whisper()
	if(vanishing || QDELETED(hallucinator))
		return
	var/line = pick(
		"[hallucinator.first_name()]?",
		"Over here...",
		"Who's there?",
		"Help me.",
		"I can see you.",
		"Don't come closer.",
	)
	to_chat(hallucinator, "<span class='game say'><span class='name'>Unknown</span> <span class='message'>whispers, \"<i>[line]</i>\"</span></span>")

/datum/hallucination/fog_figure/proc/vanish()
	if(vanishing)
		return
	vanishing = TRUE
	if(step_timer)
		deltimer(step_timer)
		step_timer = null
	animate(figure, alpha = 0, time = 0.6 SECONDS)
	QDEL_IN(src, 0.6 SECONDS)

/datum/hallucination/fog_figure/Destroy()
	if(step_timer)
		deltimer(step_timer)
		step_timer = null
	hallucinator?.client?.images -= figure
	figure = null
	return ..()

/// Heard something laughing out in the fog.
/datum/mood_event/station_fog_laugh
	description = "Something out in the fog was laughing. At me?"
	mood_change = -3
	timeout = 3 MINUTES
