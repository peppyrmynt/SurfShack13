/obj/structure/noose
	name = "noose"
	desc = "You briefly wonder what its tied to but your brain starts to ache."
	icon_state = "noose_crafting" //used to display properly in crafting menu
	icon = 'surfshack13/icons/obj/structures/noose.dmi'
	can_buckle = TRUE
	layer = ABOVE_ALL_MOB_LAYER
	anchored = TRUE
	buckle_lying = FALSE
	max_integrity = 200
	var/obj/effect/overlay/vis/overlay
	var/static/grim_text = list("legs flail for anything to stand on", \
	"hands are desperately clutching the noose", \
	"limbs sway back and forth with diminishing strength", \
	"face is turning shades of purple!", \
	"almost finds something to stand on!", \
	"starts violently clawing at their neck!")
	/// The person in the noose
	var/mob/living/damned

/obj/structure/noose/wirecutter_act_secondary(mob/living/user, obj/item/tool)
	deconstruct(TRUE)
	return

/obj/structure/noose/atom_deconstruct(disassembled = FALSE)
	STOP_PROCESSING(SSobj, src)
	new /obj/item/stack/cable_coil(drop_location())
	return ..()

/obj/structure/noose/Initialize(mapload)
	. = ..()
	icon_state = "noose_under"
	// if(prob(1) && !istype(src, /obj/structure/noose/gallows))
	// 	anchored = FALSE
	// 	name = "Walking noose"
	// 	desc = "You swear you see several balloons fixed to the noose, they seem to sit just outside your comprehension. \
	// 	Your brain starts to ache."
	overlay = SSvis_overlays._create_new_vis_overlay(icon, "noose", layer = src.layer, plane = src.plane, dir = src.dir, alpha = src.alpha)
	overlay.loc = src.loc
	overlay.color = color
	overlay.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	pixel_y = 16 //Noose looks like it's "hanging" in the air
	overlay.pixel_y = pixel_y
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(move_overlay))

/obj/structure/noose/proc/move_overlay()
	SIGNAL_HANDLER
	//use src.loc, instead of get_turf() so if its in a crate, it wont render ontop the crate
	overlay.forceMove(src.loc)

/obj/structure/noose/Destroy()
	STOP_PROCESSING(SSobj, src)
	UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
	qdel(overlay)
	return ..()

/obj/structure/noose/user_buckle_mob(mob/living/M, mob/user, check_loc, same_loc_only = TRUE)
	if(!M.get_bodypart("head"))
		return FALSE
	if(same_loc_only && M.loc != src.loc)
		return FALSE

	M.visible_message(span_danger("[user] attempts to put [M]'s into \the [src]"))
	if(!do_after(user, user == M ? 0 : 20 SECONDS, M) )
		return
	if(!is_user_buckle_possible(M, user, check_loc))
		return FALSE
	buckle_mob(M, check_loc = check_loc)
	return FALSE

/obj/structure/noose/user_unbuckle_mob(mob/living/buckled_mob, mob/user)
	if(!has_buckled_mobs())
		return ..()
	if(buckled_mob != user)
		user.visible_message(span_notice("[user] begins to untie the noose over [buckled_mob]'s neck..."), \
		span_notice("You begin to untie the noose over [buckled_mob]'s neck!"))
		if(!do_after(user, 100, buckled_mob))
			return
	else
		buckled_mob.visible_message(span_warning("[buckled_mob] struggles to unti the noose over their neck!"), \
		span_notice("You struggle to untie the noose over your neck..."))
		if(!do_after(buckled_mob, 150, src))
			return
	. = ..()


/obj/structure/noose/post_buckle_mob(mob/living/M)
	if(has_buckled_mobs())
		damned = M
		layer = MOB_LAYER
		overlay.layer = ABOVE_MOB_LAYER
		damned.dir = SOUTH
		damned.layer = NOOSED_MOB_LAYER
		playsound(src, 'surfshack13/sound/effects/noosed.ogg', 40)
		animate(damned, pixel_y = initial(pixel_y) + 8, time = 8, easing = LINEAR_EASING)
		START_PROCESSING(SSobj, src)
	else
		post_unbuckle_mob(M)

/obj/structure/noose/post_unbuckle_mob(mob/living/M)
	STOP_PROCESSING(SSobj, src)
	layer = initial(layer)
	pixel_x = initial(pixel_x)
	pixel_z = initial(pixel_z)
	overlay.layer = ABOVE_ALL_MOB_LAYER
	overlay.pixel_x = initial(pixel_x)
	overlay.pixel_z = initial(pixel_z)
	M.pixel_x = initial(M.pixel_x)
	M.pixel_y = initial(M.pixel_y)
	M.pixel_z = initial(M.pixel_z)
	M.layer = LYING_MOB_LAYER
	M.Knockdown(60)
	M.visible_message(span_warning("[M] drops from the [src]!"))
	damned = null

/obj/structure/noose/process()
	if(!has_buckled_mobs() || !damned)
		STOP_PROCESSING(SSobj, src)
		return

	if(!damned.has_gravity() || !damned.get_bodypart("head"))
		unbuckle_all_mobs()
		return

	if(pixel_x >= 0)
		animate(src, pixel_x = -3, time = 45, easing = ELASTIC_EASING)
		animate(overlay, pixel_x = -3, time = 45, easing = ELASTIC_EASING)
		animate(damned, pixel_x = -3, time = 45, easing = ELASTIC_EASING)
	else
		animate(src, pixel_x = 3, time = 45, easing = ELASTIC_EASING)
		animate(overlay, pixel_x = 3, time = 45, easing = ELASTIC_EASING)
		animate(damned, pixel_x = 3, time = 45, easing = ELASTIC_EASING)

	if(damned.stat != DEAD && !HAS_TRAIT(damned, TRAIT_NOBREATH))
		damned.adjustOxyLoss(5)
		if(prob(30))
			damned.emote("gasp")
		if(prob(20))
			damned.visible_message(span_suicide("[damned] [pick(grim_text)]"))

/obj/structure/noose/add_atom_colour(coloration, colour_priority)
	. = ..()
	overlay.add_atom_colour(coloration, colour_priority)



/obj/structure/noose/gallows
	name = "\proper Gallows"
	icon = 'surfshack13/icons/obj/structures/gallows.dmi'
	icon_state = "gallows full"
	desc = "A rather ancient execution tool with a noose and a elevated plank that drops when a lever on the side is pulled. Its caked with sand."

	density = TRUE
	/// If the plank is down or it needs to  be reset.
	var/gallows_dropped = FALSE


/obj/structure/noose/gallows/Initialize(mapload)
	. = ..()
	icon_state = "gallows"
	pixel_y = 0
	overlay.pixel_y = pixel_y


/obj/structure/noose/gallows/post_buckle_mob(mob/living/M)
	if(has_buckled_mobs())
		damned = M
		layer = MOB_LAYER
		overlay.layer = ABOVE_MOB_LAYER
		M.dir = SOUTH
		M.layer = NOOSED_MOB_LAYER
		animate(M, pixel_y = initial(pixel_y) + 8, time = 2, easing = LINEAR_EASING)
		playsound(src, 'surfshack13/sound/effects/noosed.ogg', 40)
	else
		post_unbuckle_mob(M)

/obj/structure/noose/gallows/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(gallows_dropped)
		if(!damned && do_after(user, 1 SECONDS, src))
			gallows_dropped = FALSE
			overlay.pixel_y = 0
			icon_state = "gallows"
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	if(user == damned || !damned)
		return

	user.visible_message(span_warning("[user] begins to pull the lever!"),
		span_warning("You begin to the pull the lever."))
	if(do_after(user, 4 SECONDS, src) && damned)
		drop(user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/structure/noose/gallows/post_unbuckle_mob(mob/living/M)
	. = ..()
	overlay.pixel_y = 0

/obj/structure/noose/gallows/user_buckle_mob(mob/living/M, mob/user, check_loc, same_loc_only = FALSE)
	if(gallows_dropped)
		to_chat(user, span_notice("The [src] needs to be reset first"))
		return FALSE
	if(M.stat == DEAD || !anchored)
		return
	return ..(M, user, check_loc, same_loc_only)

/obj/structure/noose/gallows/proc/drop(mob/user)
	if(!damned)
		return
	gallows_dropped = TRUE
	icon_state = "gallows_open"
	playsound(src, 'sound/effects/wounds/crack1.ogg', 70)
	damned.pixel_y -= 1
	overlay.pixel_y -= 1
	damned.apply_damage(100, BRUTE, BODY_ZONE_HEAD, wound_bonus=CANT_WOUND)
	if(!HAS_TRAIT(damned, TRAIT_NODEATH))
		damned.death()
		damned.investigate_log("has been executed with gallows by [user].", INVESTIGATE_DEATHS)

/obj/structure/noose/gallows/can_be_unfasten_wrench(mob/user, silent)
	if (LAZYLEN(buckled_mobs))
		if (!silent)
			to_chat(user, span_warning("Can't unfasten, someone's in \the [src]!"))
		return FAILED_UNFASTEN

	return ..()

/obj/structure/noose/gallows/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	if(default_unfasten_wrench(user, tool))
		return ITEM_INTERACT_SUCCESS


/datum/supply_pack/security/gallows
	name = "Gallows"
	desc = "A preassembled gallows for hanging the condemned."
	cost = CARGO_CRATE_VALUE * 4
	contains = list(
		/obj/structure/noose/gallows = 1,
		/obj/item/wrench = 1
	)
