/// The overseer's body remains vulnerable while its viewpoint moves across the infestation.
GLOBAL_LIST_EMPTY(flood_overseer_eyes)

/mob/eye/flood_overseer
	name = "Flood overseer view"
	icon = 'icons/mob/eyemob.dmi'
	icon_state = "marker"
	invisibility = INVISIBILITY_ABSTRACT
	var/mob/living/basic/flood/overseer/controller
	/// A client-side marker seen only by Flood players, including the overseer.
	var/image/flood_marker
	/// The last attack or rally order, briefly visible to Flood players.
	var/image/order_marker

/mob/eye/flood_overseer/Initialize(mapload)
	. = ..()
	flood_marker = image(icon = 'icons/mob/eyemob.dmi', loc = get_turf(src), icon_state = "marker", layer = ABOVE_ALL_MOB_LAYER)
	flood_marker.plane = ABOVE_GAME_PLANE
	flood_marker.color = "#C99974"
	flood_marker.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	GLOB.flood_overseer_eyes += src
	for(var/mob/living/basic/flood/ally in GLOB.mob_living_list)
		if(ally.client)
			ally.client.images += flood_marker

/mob/eye/flood_overseer/relaymove(mob/living/user, direction)
	if(user != controller || controller.stat == DEAD)
		return FALSE
	var/turf/next_tile = get_step(src, direction)
	if(!istype(next_tile, /turf/open/floor/flood_biomass))
		return FALSE
	forceMove(next_tile)
	flood_marker.loc = next_tile
	return TRUE

/mob/eye/flood_overseer/proc/show_order_marker(atom/target, attacking)
	clear_order_marker(order_marker)
	order_marker = image(icon = 'icons/effects/effects.dmi', loc = target, icon_state = "target_tile", layer = ABOVE_ALL_MOB_LAYER)
	order_marker.plane = ABOVE_GAME_PLANE
	order_marker.color = attacking ? "#E56159" : "#E0CC49"
	order_marker.alpha = 220
	order_marker.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	for(var/mob/living/basic/flood/ally in GLOB.mob_living_list)
		if(ally.client)
			ally.client.images += order_marker
	addtimer(CALLBACK(src, PROC_REF(clear_order_marker), order_marker), 5 SECONDS)

/mob/eye/flood_overseer/proc/clear_order_marker(image/old_marker)
	if(old_marker != order_marker || !order_marker)
		return
	for(var/client/viewer as anything in GLOB.clients)
		viewer.images -= order_marker
	QDEL_NULL(order_marker)

/mob/eye/flood_overseer/Destroy()
	GLOB.flood_overseer_eyes -= src
	clear_order_marker(order_marker)
	for(var/client/viewer as anything in GLOB.clients)
		viewer.images -= flood_marker
	QDEL_NULL(flood_marker)
	if(controller?.overseer_eye == src)
		controller.overseer_eye = null
		controller.remote_control = null
		controller.reset_perspective(null)
	controller = null
	return ..()

/mob/living/basic/flood/overseer/proc/toggle_overseer_mode()
	if(overseer_eye)
		QDEL_NULL(overseer_eye)
		to_chat(src, span_notice("You return your awareness to your body."))
		return
	if(stat == DEAD || !client || !istype(get_turf(src), /turf/open/floor/flood_biomass))
		to_chat(src, span_warning("Stand on Flood biomass to enter overseer mode."))
		return
	overseer_eye = new(get_turf(src))
	overseer_eye.controller = src
	remote_control = overseer_eye
	reset_perspective(overseer_eye)
	to_chat(src, span_notice("Move across Flood biomass; middle-click a human to attack or a tile to rally nearby Flood AI."))

/mob/living/basic/flood/overseer/death(gibbed)
	if(stat == DEAD)
		return ..()
	QDEL_NULL(overseer_eye)
	. = ..()
	if(stat != DEAD)
		return
	GLOB.flood_overseer_replacement_at = world.time + 4 MINUTES
	for(var/mob/living/basic/flood/ally in GLOB.mob_living_list)
		if(ally != src && ally.stat != DEAD)
			ally.apply_status_effect(/datum/status_effect/flood_overseer_loss, 4 MINUTES)

/mob/living/basic/flood/overseer/Destroy()
	QDEL_NULL(overseer_eye)
	return ..()

/mob/living/basic/flood/overseer/Logout()
	QDEL_NULL(overseer_eye)
	return ..()

/mob/living/basic/flood/overseer/MiddleClickOn(atom/clicked, params)
	if(!overseer_eye || stat == DEAD)
		return ..()
	var/turf/order_location = get_turf(clicked)
	if(!order_location || order_location.z != overseer_eye.z || get_dist(overseer_eye, order_location) > 15)
		return
	var/mob/living/carbon/human/target
	if(ishuman(clicked))
		var/mob/living/carbon/human/candidate = clicked
		if(candidate.stat != DEAD && !is_flood_target(candidate))
			target = candidate
	if(!target && !isfloorturf(order_location))
		return
	var/directed = 0
	for(var/mob/living/basic/flood/ally in range(35, overseer_eye))
		if(ally == src || ally.client || ally.stat == DEAD || ally.buckled || !ally.ai_controller || ally.z != order_location.z)
			continue
		if(target)
			ally.ai_controller.clear_blackboard_key("flood_rally_destination")
			ally.ai_controller.clear_blackboard_key(BB_TRAVEL_DESTINATION)
			ally.ai_controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, target)
		else
			ally.ai_controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
			ally.ai_controller.set_blackboard_key("flood_rally_destination", order_location)
		directed++
	if(directed)
		overseer_eye.show_order_marker(target ? target : order_location, !!target)
	to_chat(src, span_notice("You [target ? "direct" : "rally"] [directed] Flood units [target ? "against [target]" : "toward [order_location]"]."))
