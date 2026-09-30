/// The first Overseer chooses its location in an intangible view, like an unplaced Blob.
/proc/find_flood_scout_spawn()
	var/list/blob_spawns = shuffle(GLOB.blobstart)
	for(var/turf/blob_spawn as anything in blob_spawns)
		if(flood_can_scout_turf(blob_spawn))
			return blob_spawn
	// Match Blob's fallback for maps without a usable Blob landmark.
	return get_safe_random_station_turf()

/mob/eye/flood_spawn
	name = "Flood placement view"
	real_name = "Flood Overseer"
	icon = 'icons/mob/eyemob.dmi'
	icon_state = "marker"
	color = "#C99974"
	invisibility = INVISIBILITY_OBSERVER
	see_invisible = SEE_INVISIBLE_LIVING
	layer = FLY_LAYER
	plane = ABOVE_GAME_PLANE
	lighting_cutoff_red = 25
	lighting_cutoff_green = 15
	lighting_cutoff_blue = 35
	/// Prevent repeated placement while the player's mind is moving to its body.
	var/placing = FALSE

/mob/eye/flood_spawn/Initialize(mapload)
	. = ..()
	GLOB.flood_spawn_eyes += src
	var/datum/action/flood_place_overseer/place_action = new(src)
	place_action.Grant(src)
	addtimer(CALLBACK(src, PROC_REF(clean_up_disconnected)), 1 MINUTES, TIMER_DELETE_ME)

/mob/eye/flood_spawn/Destroy()
	GLOB.flood_spawn_eyes -= src
	return ..()

/mob/eye/flood_spawn/Login()
	. = ..()
	if(. && client)
		to_chat(src, span_boldnotice("Choose where the Flood outbreak begins. Move around the station, then press Spawn Overseer to materialize on your current tile."))
		to_chat(src, span_notice("Choose a clear station floor away from living crew. Your starting tile will become Flood biomass."))

/mob/eye/flood_spawn/Logout()
	. = ..()
	// Give reconnecting players a minute, then release an abandoned leadership reservation.
	addtimer(CALLBACK(src, PROC_REF(clean_up_disconnected)), 1 MINUTES, TIMER_DELETE_ME)

/mob/eye/flood_spawn/proc/clean_up_disconnected()
	if(!client)
		qdel(src)

/// Scouting passes through station walls, but cannot leave for space, shuttles, or off-station areas.
/proc/flood_can_scout_turf(turf/location)
	return location && is_station_level(location.z) && !isgroundlessturf(location) && !istype(get_area(location), /area/shuttle)

/mob/eye/flood_spawn/Move(NewLoc, Dir = 0)
	if(!flood_can_scout_turf(NewLoc))
		return FALSE
	return forceMove(NewLoc)

/mob/eye/flood_spawn/can_z_move(direction, turf/start, turf/destination, z_move_flags = NONE, mob/living/rider)
	. = ..()
	if(!. || !flood_can_scout_turf(.))
		return FALSE

/// Return a useful explanation instead of silently failing to place.
/mob/eye/flood_spawn/proc/placement_error(turf/location)
	if(!flood_can_scout_turf(location) || !isfloorturf(location))
		return "Choose a station floor to spawn on."
	var/area/spawn_area = get_area(location)
	if(!(spawn_area.area_flags & BLOBS_ALLOWED) || (location.resistance_flags & INDESTRUCTIBLE))
		return "The Flood cannot start an outbreak in this area."
	for(var/atom/movable/obstacle in location)
		if(obstacle.density)
			return "There is something blocking this tile."
	// Use the same crew visibility distances as Blob's initial placement.
	for(var/mob/living/person in range(7, location))
		if(person.client && person.stat != DEAD && !is_flood_target(person))
			return "There is someone too close to spawn here."
	for(var/mob/living/person in view(13, location))
		if(person.client && person.stat != DEAD && !is_flood_target(person))
			return "Someone could see you spawn here."
	return null

/mob/eye/flood_spawn/proc/place_overseer()
	if(placing || !mind)
		return null
	if(!can_form_flood_overseer(src))
		to_chat(src, span_warning("An Overseer already exists or the hive is still recovering."))
		return null
	var/turf/spawn_turf = get_turf(src)
	var/error_message = placement_error(spawn_turf)
	if(error_message)
		to_chat(src, span_warning(error_message))
		return null
	placing = TRUE
	grow_flood_floor(spawn_turf)
	var/mob/living/basic/flood/overseer/overseer = new(get_turf(src))
	var/datum/mind/flood_mind = mind
	flood_mind.transfer_to(overseer)
	message_admins("[ADMIN_LOOKUPFLW(overseer)] placed the first Flood Overseer at [ADMIN_VERBOSEJMP(overseer)].")
	overseer.log_message("chose the starting location for a Flood outbreak", LOG_GAME)
	qdel(src)
	return overseer

/datum/action/flood_place_overseer
	name = "Spawn Overseer"
	desc = "Begin the Flood outbreak on your current tile. Choose a clear station floor away from crew."
	button_icon = 'icons/mob/flood/flood_constructor_builder.dmi'
	button_icon_state = "designator"
	background_icon_state = "bg_alien"
	overlay_icon_state = "bg_alien_border"

/datum/action/flood_place_overseer/Trigger(trigger_flags)
	if(!..())
		return FALSE
	var/mob/eye/flood_spawn/placement = owner
	if(!istype(placement))
		return FALSE
	return !!placement.place_overseer()
