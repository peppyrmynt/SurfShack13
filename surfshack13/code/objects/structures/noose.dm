//something to note, the noose_under state has pixels with alpha = 1 to catch clicks.

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
	if(prob(1))
		anchored = FALSE
		name = "Walking noose"
		desc = "You swear you see several balloons fixed to the noose, they seem to sit just outside your comprehension. \
		Your brain starts to ache."
	overlay = SSvis_overlays._create_new_vis_overlay(icon, "noose", layer = src.layer, plane = src.plane, dir = src.dir, alpha = src.alpha)
	overlay.loc = get_turf(src)
	overlay.color = color
	overlay.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	pixel_y = 16 //Noose looks like it's "hanging" in the air
	overlay.pixel_y = pixel_y

/obj/structure/noose/Destroy()
	STOP_PROCESSING(SSobj, src)
	qdel(overlay)
	return ..()

/obj/structure/noose/user_buckle_mob(mob/living/M, mob/user, check_loc)
	if(!M.get_bodypart("head") || M.loc != src.loc)
		return FALSE
	M.visible_message(span_danger("[user] attempts to tie the [src] over [M]'s neck!"))
	if(do_after(user, user == M ? 0 : 20 SECONDS, M))
		return ..()
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
		layer = MOB_LAYER
		overlay.layer = ABOVE_MOB_LAYER
		M.dir = SOUTH
		M.layer = NOOSED_MOB_LAYER
		playsound(src, 'surfshack13/sound/effects/noosed.ogg', 40)
		animate(M, pixel_y = initial(pixel_y) + 8, time = 8, easing = LINEAR_EASING)
		START_PROCESSING(SSobj, src)
	else
		post_unbuckle_mob(M)

/obj/structure/noose/post_unbuckle_mob(mob/living/M)
	STOP_PROCESSING(SSobj, src)
	layer = initial(layer)
	overlay.layer = ABOVE_ALL_MOB_LAYER
	pixel_x = initial(pixel_x)
	overlay.pixel_x = initial(pixel_x)
	pixel_z = initial(pixel_z)
	overlay.pixel_z = initial(pixel_z)
	M.pixel_x = initial(M.pixel_x)
	M.pixel_y = initial(M.pixel_y)
	M.pixel_z = initial(M.pixel_z)
	M.Knockdown(60)
	M.layer = LYING_MOB_LAYER
	M.visible_message(span_warning("[M] drops from the [src]!"))

/obj/structure/noose/process()
	if(!has_buckled_mobs())
		STOP_PROCESSING(SSobj, src)
		return
	for(var/m in buckled_mobs)
		var/mob/living/buckled_mob = m
		if(pixel_x >= 0)
			animate(src, pixel_x = -3, time = 45, easing = ELASTIC_EASING)
			animate(overlay, pixel_x = -3, time = 45, easing = ELASTIC_EASING)
			animate(buckled_mob, pixel_x = -3, time = 45, easing = ELASTIC_EASING)
		else
			animate(src, pixel_x = 3, time = 45, easing = ELASTIC_EASING)
			animate(overlay, pixel_x = 3, time = 45, easing = ELASTIC_EASING)
			animate(buckled_mob, pixel_x = 3, time = 45, easing = ELASTIC_EASING)
		if(!buckled_mob.has_gravity() || !buckled_mob.get_bodypart("head"))
			unbuckle_all_mobs()
			return
		if(buckled_mob.stat != DEAD && !HAS_TRAIT(buckled_mob, TRAIT_NOBREATH))
			buckled_mob.adjustOxyLoss(5)
			if(prob(30))
				buckled_mob.emote("gasp")
			if(prob(20))
				buckled_mob.visible_message(span_suicide("[buckled_mob] [pick(grim_text)]"))

/obj/structure/noose/add_atom_colour(coloration, colour_priority)
	. = ..()
	overlay.add_atom_colour(coloration, colour_priority)



