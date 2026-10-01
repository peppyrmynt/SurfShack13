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
 *   the fog's conceal range shows as the PR's static-noise figure. It starts at
 *   thickness 3 (4 tiles) and closes in to 3 tiles at 4 and 2 tiles at 5.
 *   Hovering gives "unknown figure", examining fails, and sec/med HUD icons
 *   on them are hidden. Voices still carry, so speech is still attributed.
 *
 * - hallucinations at thickness 4 and 5: players standing in fog see people
 *   that aren't there (a static figure in the fog, see /datum/hallucination/fog_figure)
 *   and get tg's own people hallucinations: fake speech from nearby people,
 *   distant fights and gunfire, stray bullets, someone nearby drawing a weapon.
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
/// How far out to look for people to conceal; anything past this is off screen.
#define STATION_FOG_CONCEAL_SCAN 10

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
	/// player -> world.time their next fog hallucination is due.
	var/list/next_hallucination = list()

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
	reveal_everyone()
	for(var/mob/living/player as anything in fogged_players)
		clear_fog_screens(player)
	fogged_players.Cut()

/datum/weather/station_fog/Destroy()
	if(GLOB.station_fog == src)
		GLOB.station_fog = null
	STOP_PROCESSING(SSprocessing, src)
	reveal_everyone()
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
			still_fogged[player] = TRUE
	for(var/mob/living/player as anything in fogged_players - still_fogged)
		if(!QDELETED(player))
			clear_fog_screens(player)
	fogged_players = still_fogged
	update_concealment()
	roll_hallucinations()

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

/// At thickness 4 and 5, every so often, makes each player in fog see things.
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
		next_hallucination[player] = world.time + (thickness >= 5 ? rand(15 SECONDS, 30 SECONDS) : rand(25 SECONDS, 50 SECONDS))
		fog_hallucinate(player)

/// Gives [player] one fog hallucination, picked from the weighted pool.
/datum/weather/station_fog/proc/fog_hallucinate(mob/living/player, hallucination_type)
	hallucination_type ||= pick_weight(GLOB.station_fog_hallucinations)
	if(hallucination_type == /datum/hallucination/fog_figure)
		return player.cause_hallucination(hallucination_type, "station fog", vanish_range = get_conceal_range() || 2)
	return player.cause_hallucination(hallucination_type, "station fog")

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
	return null

/// Whether a mob is something the fog disguises: people and cyborgs.
/datum/weather/station_fog/proc/can_disguise(mob/living/target)
	return ishuman(target) || iscyborg(target)

/// Re-decides, for every player near the fog, which people they can't make out.
/datum/weather/station_fog/proc/update_concealment()
	var/list/new_concealed = list()
	var/conceal_range = get_conceal_range()
	if(stage == MAIN_STAGE && conceal_range)
		for(var/z_level in impacted_z_levels)
			for(var/mob/living/viewer in SSmobs.clients_by_zlevel[z_level])
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

/// The anonymous figure for [target], made on first use. Same art as
/// tgstation#97041: humans become a static-noise humanoid, cyborgs a stock
/// cyborg chassis filled with static.
/datum/weather/station_fog/proc/get_disguise(mob/living/target)
	var/datum/atom_hud/alternate_appearance/basic/station_fog/disguise = disguises[target]
	if(disguise)
		return disguise
	var/image/figure
	if(iscyborg(target))
		var/image/static_overlay = image('icons/effects/effects.dmi', null, "static_base")
		static_overlay.blend_mode = BLEND_INSET_OVERLAY
		figure = image('icons/mob/silicon/robots.dmi', target, "robot")
		figure.appearance_flags |= KEEP_TOGETHER
		figure.overlays += static_overlay
		figure.name = "unknown cyborg"
	else
		figure = image('icons/effects/effects.dmi', target, "static")
		figure.name = "unknown humanoid"
	figure.override = TRUE
	figure.transform = target.transform
	disguise = target.add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/station_fog, "[REF(target)]_station_fog", figure, NONE)
	disguises[target] = disguise
	RegisterSignal(target, COMSIG_QDELETING, PROC_REF(on_target_deleted), override = TRUE)
	return disguise

/datum/weather/station_fog/proc/conceal_from(mob/living/target, mob/viewer)
	get_disguise(target).show_to(viewer)
	// Sec and med HUD icons would give the game away: hide this body's.
	for(var/datum/atom_hud/data/human/hud in GLOB.huds)
		hud.hide_single_atomhud_from(viewer, target)

/datum/weather/station_fog/proc/reveal_to(mob/living/target, mob/viewer)
	if(QDELETED(target) || QDELETED(viewer))
		return
	var/datum/atom_hud/alternate_appearance/basic/station_fog/disguise = disguises[target]
	disguise?.hide_from(viewer, absolute = TRUE)
	for(var/datum/atom_hud/data/human/hud in GLOB.huds)
		hud.unhide_single_atomhud_from(viewer, target)

/datum/weather/station_fog/proc/on_target_deleted(mob/living/source)
	SIGNAL_HANDLER
	for(var/mob/viewer as anything in concealed_from)
		concealed_from[viewer] -= source
	qdel(disguises[source])
	disguises -= source

/// Lifts every disguise, for when the fog ends.
/datum/weather/station_fog/proc/reveal_everyone()
	for(var/mob/viewer as anything in concealed_from)
		for(var/mob/living/target as anything in concealed_from[viewer])
			reveal_to(target, viewer)
	concealed_from.Cut()
	for(var/mob/living/target as anything in disguises)
		UnregisterSignal(target, COMSIG_QDELETING)
		qdel(disguises[target])
	disguises.Cut()

/// The fog's anonymous figure. Shown per viewer by the fog, never generically.
/// Turns with its body (lying down, etc), as in tgstation#97041.
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
	for(var/level in 1 to STATION_FOG_MAX_THICKNESS)
		options += "Thickness [level][fog?.stage == MAIN_STAGE && fog.thickness == level ? " (current)" : ""]"
	options += "Hallucinate a fog figure (me)"
	options += "Hallucinate something random from the fog pool (me)"
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
	/// Wandering, creeping closer, or standing still.
	var/behaviour
	/// The looping step timer.
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
	behaviour = pick(40; "wander", 35; "approach", 25; "still")
	feedback_details += "Figure: [behaviour]"
	if(prob(30))
		addtimer(CALLBACK(src, PROC_REF(whisper)), rand(2 SECONDS, 5 SECONDS))
	step_timer = addtimer(CALLBACK(src, PROC_REF(figure_step)), 0.8 SECONDS, TIMER_STOPPABLE | TIMER_LOOP)
	addtimer(CALLBACK(src, PROC_REF(vanish)), rand(8 SECONDS, 16 SECONDS))
	return TRUE

/// One beat: dissolve if they got close, otherwise maybe shuffle a tile.
/datum/hallucination/fog_figure/proc/figure_step()
	if(vanishing || QDELETED(hallucinator))
		return
	var/turf/here = figure.loc
	if(!here || here.z != hallucinator.z || get_dist(hallucinator, here) <= vanish_range)
		vanish()
		return
	if(behaviour == "still" || prob(35))
		figure.dir = get_dir(here, hallucinator)
		return
	var/turf/open/next
	if(behaviour == "approach" && get_dist(hallucinator, here) > vanish_range + 1)
		next = get_step_towards(here, hallucinator)
	else
		next = get_step(here, pick(GLOB.cardinals))
	if(!istype(next) || next.is_blocked_turf() || get_dist(hallucinator, next) <= vanish_range)
		return
	// Glide: jump the image to the new tile, offset back, slide the offset out.
	var/step_dir = get_dir(here, next)
	figure.loc = next
	figure.dir = step_dir
	figure.pixel_x = (step_dir & EAST) ? -32 : ((step_dir & WEST) ? 32 : 0)
	figure.pixel_y = (step_dir & NORTH) ? -32 : ((step_dir & SOUTH) ? 32 : 0)
	animate(figure, pixel_x = 0, pixel_y = 0, time = 0.8 SECONDS)

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
