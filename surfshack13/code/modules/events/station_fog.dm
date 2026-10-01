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
 * Admins can drive it by hand with the "Debug Station Fog" verb.
 */

/// The fog currently rolling through the station, if any.
GLOBAL_DATUM(station_fog, /datum/weather/station_fog)

/// Thickness steps the fog climbs through, matching the fog1..fog5 icon states.
#define STATION_FOG_MAX_THICKNESS 5
/// Fullscreen category for the fog vignette.
#define STATION_FOG_SCREEN "station_fog"
/// Fullscreen categories for the solid strips beyond the 15x15 vignette.
#define STATION_FOG_SCREEN_WEST "station_fog_west"
#define STATION_FOG_SCREEN_EAST "station_fog_east"
#define STATION_FOG_SCREEN_NORTH "station_fog_north"
#define STATION_FOG_SCREEN_SOUTH "station_fog_south"

/datum/round_event_control/station_fog
	name = "Station Fog"
	typepath = /datum/round_event/station_fog
	weight = 10
	max_occurrences = 1
	earliest_start = 20 MINUTES
	min_players = 10
	category = EVENT_CATEGORY_SPACE
	description = "A thickening fog fills the station. Maintenance stays clear."
	min_wizard_trigger_potency = 0
	max_wizard_trigger_potency = 4

/datum/round_event/station_fog
	announce_when = 1
	start_when = 2
	end_when = 3

/datum/round_event/station_fog/announce(fake)
	priority_announce("A dense vapour bank has been drawn into the station's air handling. Visibility will fall across the station as it thickens. Maintenance runs on independent scrubbers and should remain clear.", "Atmospheric Anomaly")

/datum/round_event/station_fog/start()
	SSweather.run_weather(/datum/weather/station_fog)

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
	/// Players currently wearing the fog vignette, so leaving the fog clears it.
	var/list/mob/living/fogged_players = list()
	/// Whether the fog thickens by itself over time. Off for admin test fogs.
	var/auto_thicken = TRUE

/datum/weather/station_fog/New(z_levels)
	. = ..()
	if(GLOB.station_fog && GLOB.station_fog != src)
		GLOB.station_fog.end()
	GLOB.station_fog = src

/datum/weather/station_fog/telegraph()
	. = ..()
	START_PROCESSING(SSprocessing, src)

/datum/weather/station_fog/start()
	. = ..()
	if(!auto_thicken)
		return
	// Thicken in even steps over the first three quarters of the fog, so the
	// last stretch sits at full thickness before it winds down.
	var/step_time = (weather_duration * 0.75) / (STATION_FOG_MAX_THICKNESS - 1)
	for(var/step in 2 to STATION_FOG_MAX_THICKNESS)
		addtimer(CALLBACK(src, PROC_REF(set_thickness), step), step_time * (step - 1))

/datum/weather/station_fog/wind_down()
	thickness = 1
	return ..()

/datum/weather/station_fog/end()
	. = ..()
	if(GLOB.station_fog == src)
		GLOB.station_fog = null
	STOP_PROCESSING(SSprocessing, src)
	for(var/mob/living/player as anything in fogged_players)
		clear_fog_screens(player)
	fogged_players.Cut()

/datum/weather/station_fog/Destroy()
	if(GLOB.station_fog == src)
		GLOB.station_fog = null
	STOP_PROCESSING(SSprocessing, src)
	for(var/mob/living/player as anything in fogged_players)
		clear_fog_screens(player, animated = 0)
	fogged_players.Cut()
	return ..()

/datum/weather/station_fog/proc/set_thickness(new_thickness, silent = FALSE)
	if(stage != MAIN_STAGE)
		return
	var/old_thickness = thickness
	thickness = clamp(new_thickness, 1, STATION_FOG_MAX_THICKNESS)
	update_areas()
	if(!silent && thickness > old_thickness)
		send_alert(span_warning("The fog grows thicker."))

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
			still_fogged += player
	for(var/mob/living/player as anything in fogged_players - still_fogged)
		if(!QDELETED(player))
			clear_fog_screens(player)
	fogged_players = still_fogged

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
	for(var/level in 1 to STATION_FOG_MAX_THICKNESS)
		options += "Thickness [level][fog?.stage == MAIN_STAGE && fog.thickness == level ? " (current)" : ""]"
	options += "Resume automatic thickening"
	options += "Stop fog"
	var/choice = tgui_input_list(user, "Station fog is [fog ? "active" : "not active"]. Picking a thickness starts a test fog instantly (no telegraph, no timer) if none is running.", "Debug Station Fog", options)
	if(!choice)
		return
	fog = GLOB.station_fog
	if(choice == "Stop fog")
		if(!fog)
			to_chat(user, span_warning("There's no station fog running."))
			return
		fog.end()
		message_admins("[key_name_admin(user)] stopped the station fog.")
		log_admin("[key_name(user)] stopped the station fog.")
		return
	if(!fog)
		fog = new /datum/weather/station_fog(SSmapping.levels_by_trait(ZTRAIT_STATION))
		fog.auto_thicken = FALSE
		fog.perpetual = TRUE
		fog.telegraph()
		fog.start()
	if(choice == "Resume automatic thickening")
		fog.auto_thicken = TRUE
		fog.perpetual = FALSE
		var/remaining_steps = STATION_FOG_MAX_THICKNESS - fog.thickness
		for(var/step in 1 to remaining_steps)
			addtimer(CALLBACK(fog, TYPE_PROC_REF(/datum/weather/station_fog, set_thickness), fog.thickness + step), 2 MINUTES * step)
		addtimer(CALLBACK(fog, TYPE_PROC_REF(/datum/weather, wind_down)), 2 MINUTES * (remaining_steps + 1))
		message_admins("[key_name_admin(user)] set the station fog to thicken on its own.")
		log_admin("[key_name(user)] set the station fog to thicken on its own.")
		return
	var/level = text2num(copytext(choice, length("Thickness ") + 1))
	fog.set_thickness(level, silent = TRUE)
	message_admins("[key_name_admin(user)] set the station fog to thickness [level].")
	log_admin("[key_name(user)] set the station fog to thickness [level].")
	BLACKBOX_LOG_ADMIN_VERB("Debug Station Fog")

#undef STATION_FOG_MAX_THICKNESS
#undef STATION_FOG_SCREEN
#undef STATION_FOG_SCREEN_WEST
#undef STATION_FOG_SCREEN_EAST
#undef STATION_FOG_SCREEN_NORTH
#undef STATION_FOG_SCREEN_SOUTH
