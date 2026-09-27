
/obj/vehicle/ridden/lawnmower
	name = "lawn mower"
	desc = "Equipped with reliable safeties to prevent <i>accidents</i> in the workplace."
	icon = 'icons/obj/vehicles/lawnmower.dmi'
	icon_state = "lawnmower"
	var/emagged = FALSE
	var/list/drive_sounds = list('sound/vehicles/mowermove1.ogg', 'sound/vehicles/mowermove2.ogg')
	var/list/gib_sounds = list('sound/vehicles/mowermovesquish.ogg')

/obj/vehicle/ridden/lawnmower/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/ridable, /datum/component/riding/vehicle/lawnmower)

/obj/vehicle/ridden/lawnmower/emagged
	emagged = TRUE

/obj/vehicle/ridden/lawnmower/emag_act(mob/user)
	if(emagged)
		to_chat(user, span_warning("The safety mechanisms on [src] are already disabled!"))
		return
	to_chat(user, span_warning("You disable the safety mechanisms on [src]."))
	emagged = TRUE

/obj/vehicle/ridden/lawnmower/Bump(atom/bumped_thing)
	if(emagged && isliving(bumped_thing))
		var/mob/living/victim = bumped_thing
		victim.adjustBruteLoss(25)
		var/atom/new_loc = get_edge_target_turf(victim, get_dir(src, get_step_away(victim, src)))
		victim.throw_at(new_loc, 4, 1)
	return ..()

/obj/vehicle/ridden/lawnmower/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	var/mob/living/carbon/human/rider
	if(has_buckled_mobs())
		rider = buckled_mobs[1]

	var/gibbed = FALSE
	if(emagged)
		for(var/mob/living/carbon/human/victim in loc)
			if(victim == rider)
				continue
			if(victim.body_position == LYING_DOWN)
				visible_message(span_danger("[src] grinds [victim] into a fine paste!"))
				victim.gib()
				shake_camera(victim, 20, 1)
				gibbed = TRUE

	if(gibbed)
		if(rider)
			shake_camera(rider, 10, 1)
		playsound(loc, pick(gib_sounds), 75, TRUE)
	else
		playsound(loc, pick(drive_sounds), 75, TRUE)
