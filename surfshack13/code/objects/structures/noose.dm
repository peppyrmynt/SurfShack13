/obj/structure/noose
	name = "noose"
	desc = "You briefly wonder what its tied to but your brain starts to ache."
	icon_state = "noose" //used to display properly in crafting menu
	icon = 'surfshack13/icons/obj/structures/noose.dmi'
	can_buckle = TRUE
	layer = ABOVE_ALL_MOB_LAYER
	anchored = TRUE
	buckle_lying = FALSE
	max_integrity = 200
	var/obj/effect/overlay/vis/noose_neck_overlay
	var/static/grim_text = list("legs flail for anything to stand on", \
	"hands are desperately clutching the noose", \
	"limbs sway back and forth with diminishing strength", \
	"face is turning shades of purple!", \
	"almost finds something to stand on!", \
	"starts violently clawing at their neck!")
	/// The person in the noose
	var/mob/living/damned
	/// How much we have to offset the mob to hang
	var/hanging_pixel_y = 9

/obj/structure/noose/wirecutter_act_secondary(mob/living/user, obj/item/tool)
	deconstruct(TRUE)
	return

/obj/structure/noose/atom_deconstruct(disassembled = FALSE)
	STOP_PROCESSING(SSobj, src)
	new /obj/item/stack/cable_coil(drop_location())
	return ..()

/obj/structure/noose/Initialize(mapload)
	. = ..()
	// if(prob(1) && !istype(src, /obj/structure/noose/gallows))
	// 	anchored = FALSE
	// 	name = "Walking noose"
	// 	desc = "You swear you see several balloons fixed to the noose, they seem to sit just outside your comprehension. \
	// 	Your brain starts to ache."
	pixel_y = 16 //Noose looks like it's "hanging" in the air


/obj/structure/noose/proc/create_noose_overlay()
	noose_neck_overlay = SSvis_overlays._create_new_vis_overlay(icon, "noose_overlay", layer = ABOVE_MOB_LAYER, plane = src.plane, alpha = src.alpha)
	noose_neck_overlay.loc = src.loc
	noose_neck_overlay.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	noose_neck_overlay.pixel_y = src.pixel_y
	noose_neck_overlay.atom_colours = src.atom_colours
	noose_neck_overlay.update_atom_colour()
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(move_overlay))

/obj/structure/noose/proc/move_overlay()
	SIGNAL_HANDLER
	noose_neck_overlay.forceMove(src.loc)

/obj/structure/noose/add_atom_colour(coloration, colour_priority)
	. = ..()
	noose_neck_overlay.add_atom_colour(coloration, colour_priority)

/obj/structure/noose/Destroy()
	STOP_PROCESSING(SSobj, src)
	UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
	qdel(noose_neck_overlay)
	return ..()

/obj/structure/noose/user_buckle_mob(mob/living/M, mob/user, check_loc)
	if(!ishuman(M))
		return
	//moths barely fit and look wierd, and golems dont work at all.
	if(isgolem(M) || ismoth(M))
		to_chat(user, span_notice("[M]'s head doesnt fit in the noose!"))
		return
	if(!M.get_bodypart("head") || M.loc != src.loc)
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
		damned.dir = SOUTH
		damned.layer = NOOSED_MOB_LAYER
		if(!noose_neck_overlay)
			create_noose_overlay()
		else
			noose_neck_overlay.alpha = src.alpha
		playsound(src, 'surfshack13/sound/effects/noosed.ogg', 40)
		if(ismonkey(damned))
			hanging_pixel_y = 14
		animate(damned, pixel_y = hanging_pixel_y, time = 8)
		START_PROCESSING(SSobj, src)
	else
		post_unbuckle_mob(M)

/obj/structure/noose/post_unbuckle_mob(mob/living/M)
	STOP_PROCESSING(SSobj, src)
	layer = initial(layer)
	pixel_x = 0
	pixel_z = 0
	noose_neck_overlay.alpha = 0
	noose_neck_overlay.pixel_x = 0
	noose_neck_overlay.pixel_z = 0
	M.pixel_x = initial(M.pixel_x)
	M.pixel_y = initial(M.pixel_y)
	M.pixel_z = initial(M.pixel_z)
	M.layer = LYING_MOB_LAYER
	M.Knockdown(60)
	M.visible_message(span_warning("[M] drops from the [src]!"))
	damned = null
	hanging_pixel_y = 9

/obj/structure/noose/process()
	if(!has_buckled_mobs() || !damned)
		STOP_PROCESSING(SSobj, src)
		return

	if(!damned.has_gravity() || !damned.get_bodypart("head"))
		unbuckle_all_mobs()
		return
	damned.pixel_y = hanging_pixel_y
	if(pixel_x >= 0)
		animate(src, pixel_x = -3, time = 45, easing = ELASTIC_EASING)
		animate(noose_neck_overlay, pixel_x = -3, time = 45, easing = ELASTIC_EASING)
		animate(damned, pixel_x = -3, time = 45, easing = ELASTIC_EASING)
	else
		animate(src, pixel_x = 3, time = 45, easing = ELASTIC_EASING)
		animate(noose_neck_overlay, pixel_x = 3, time = 45, easing = ELASTIC_EASING)
		animate(damned, pixel_x = 3, time = 45, easing = ELASTIC_EASING)

	if(damned.stat != DEAD && !HAS_TRAIT(damned, TRAIT_NOBREATH))
		damned.adjustOxyLoss(5)
		if(prob(30))
			damned.emote("gasp")
		if(prob(20))
			damned.visible_message(span_suicide("[damned] [pick(grim_text)]"))
