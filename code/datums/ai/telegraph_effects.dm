/obj/effect/temp_visual/telegraphing
	icon = 'icons/mob/telegraphing/telegraph_holographic.dmi'
	icon_state = "target_box"
	layer = BELOW_MOB_LAYER
	plane = GAME_PLANE
	light_range = 1
	duration = 2 SECONDS

/obj/effect/temp_visual/telegraphing/vending_machine_tilt
	duration = 1 SECONDS

/obj/effect/temp_visual/telegraphing/lift_travel

/obj/effect/temp_visual/telegraphing/lift_travel/Initialize(mapload, duration)
	src.duration = duration
	return ..()

/obj/effect/temp_visual/telegraphing/thunderbolt
	icon = 'icons/mob/telegraphing/telegraph.dmi'
	icon_state = "target_circle"
	duration = 2 SECONDS

// Surf Shack Edit
/obj/effect/temp_visual/telegraphing/exclamation
	icon = 'icons/mob/telegraphing/telegraph.dmi'
	icon_state = "exclamation"
	duration = 1 SECONDS

/obj/effect/temp_visual/telegraphing/exclamation/Initialize(mapload, duration)
	if(!isnull(duration))
		src.duration = duration
	return ..()

/obj/effect/temp_visual/telegraphing/exclamation/following/Initialize(mapload, duration, obj/following)
	. = ..()
	if(isnull(following))
		return INITIALIZE_HINT_QDEL
	glide_size = following.glide_size
	RegisterSignal(following, COMSIG_MOVABLE_MOVED, PROC_REF(follow))

///called when the thing we're following moves
/obj/effect/temp_visual/telegraphing/exclamation/following/proc/follow(datum/source)
	SIGNAL_HANDLER
	forceMove(get_turf(source))
// Surf Shack End
