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
 * - a fullscreen vignette on living players standing in fog, whose clear centre
 *   shrinks as the fog thickens. Stepping into maintenance clears it.
 */

/// Thickness steps the fog climbs through, matching the fog1..fog4 icon states.
#define STATION_FOG_MAX_THICKNESS 4
/// Fullscreen category for the fog vignette.
#define STATION_FOG_SCREEN "station_fog"

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
	telegraph_duration = 60 SECONDS
	telegraph_overlay = "fog1"

	weather_message = span_warning("The fog rolls in properly. You can't see far through it.")
	weather_duration_lower = 8 MINUTES
	weather_duration_upper = 12 MINUTES
	weather_overlay = "fog1"

	end_message = span_notice("The fog starts thinning out as the scrubbers catch up.")
	end_duration = 60 SECONDS
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

/datum/weather/station_fog/telegraph()
	. = ..()
	START_PROCESSING(SSprocessing, src)

/datum/weather/station_fog/start()
	. = ..()
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
	STOP_PROCESSING(SSprocessing, src)
	for(var/mob/living/player as anything in fogged_players)
		player.clear_fullscreen(STATION_FOG_SCREEN)
	fogged_players.Cut()

/datum/weather/station_fog/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	for(var/mob/living/player as anything in fogged_players)
		player.clear_fullscreen(STATION_FOG_SCREEN, animated = 0)
	fogged_players.Cut()
	return ..()

/datum/weather/station_fog/proc/set_thickness(new_thickness)
	if(stage != MAIN_STAGE)
		return
	thickness = clamp(new_thickness, 1, STATION_FOG_MAX_THICKNESS)
	update_areas()
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
			player.overlay_fullscreen(STATION_FOG_SCREEN, /atom/movable/screen/fullscreen/station_fog, vignette_level)
			still_fogged += player
	for(var/mob/living/player as anything in fogged_players - still_fogged)
		if(!QDELETED(player))
			player.clear_fullscreen(STATION_FOG_SCREEN)
	fogged_players = still_fogged

/atom/movable/screen/fullscreen/station_fog
	icon = 'surfshack13/icons/effects/station_fog_vignette.dmi'
	icon_state = "fog"
	layer = FULLSCREEN_LAYER

#undef STATION_FOG_MAX_THICKNESS
#undef STATION_FOG_SCREEN
