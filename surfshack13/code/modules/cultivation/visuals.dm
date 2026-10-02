// Visual effects for cultivation techniques. Expanding qi waves in each element's colour, and afterimages.

/obj/effect/temp_visual/circle_wave/cultivation
	color = "#9fe3ff"
	duration = 0.5 SECONDS
	amount_to_scale = 2

/obj/effect/temp_visual/circle_wave/cultivation/gold
	color = "#ffd55a"

/obj/effect/temp_visual/circle_wave/cultivation/gold/big
	duration = 0.8 SECONDS
	amount_to_scale = 6

/obj/effect/temp_visual/circle_wave/cultivation/water
	color = "#4fb3ff"

/obj/effect/temp_visual/circle_wave/cultivation/fire
	color = "#ff6a1f"
	amount_to_scale = 4

/obj/effect/temp_visual/circle_wave/cultivation/earth
	color = "#a07a45"

/obj/effect/temp_visual/circle_wave/cultivation/wood
	color = "#5fd35f"

/obj/effect/temp_visual/circle_wave/cultivation/blood
	color = "#c0201a"

/obj/effect/temp_visual/circle_wave/cultivation/sense
	color = "#d8f4ff"
	duration = 0.8 SECONDS
	amount_to_scale = 8
	max_alpha = 120

/// Leave a fading afterimage of something where it is now
/proc/cultivation_afterimage(atom/movable/thing, fade_time = 0.4 SECONDS)
	var/obj/effect/temp_visual/decoy/fading/image = new(get_turf(thing), thing)
	animate(image, alpha = 0, time = fade_time)
	QDEL_IN(image, fade_time)
	return image

// ===================== Particles =====================

/particles/cultivation
	icon = 'surfshack13/icons/cultivation/cultivation_particles.dmi'
	icon_state = "qi_mote"
	width = 96
	height = 128
	count = 60
	spawning = 2
	lifespan = 1.4 SECONDS
	fade = 0.6 SECONDS
	position = generator(GEN_CIRCLE, 6, 14, NORMAL_RAND)
	velocity = list(0, 0.6)
	drift = generator(GEN_VECTOR, list(-0.15, 0), list(0.15, 0.1))
	scale = generator(GEN_VECTOR, list(0.6, 0.6), list(1.2, 1.2), NORMAL_RAND)

/particles/cultivation/gold
	icon_state = "gold_mote"
	spawning = 3

/particles/cultivation/void
	icon_state = "void_mote"
	spawning = 6
	velocity = list(0, 0)
	position = generator(GEN_CIRCLE, 2, 16, NORMAL_RAND)
	drift = generator(GEN_VECTOR, list(-0.4, -0.4), list(0.4, 0.4))

/particles/cultivation/embers
	icon_state = "ember"
	spawning = 6
	velocity = list(0, 1.2)
	position = generator(GEN_CIRCLE, 4, 24, NORMAL_RAND)

/particles/cultivation/petals
	icon_state = "petal"
	spawning = 3
	velocity = list(0, -0.3)
	position = generator(GEN_BOX, list(-40, 10), list(40, 40), NORMAL_RAND)
	drift = generator(GEN_VECTOR, list(-0.3, -0.05), list(0.3, 0.05))
	spin = generator(GEN_NUM, -15, 15)

/// Attach particles to something for a while (or forever if no duration; then delete the returned holder yourself)
/proc/cultivation_particles(atom/movable/target, particle_type, duration)
	var/obj/effect/abstract/particle_holder/holder = new(target, particle_type)
	if(duration)
		QDEL_IN(holder, duration)
	return holder

// ===================== Attached visuals =====================

/// A big sprite drawn on a mob through vis_contents (bell domes, water bubbles, storm clouds)
/obj/effect/abstract/cultivation_vis
	vis_flags = VIS_INHERIT_PLANE
	appearance_flags = RESET_COLOR | RESET_TRANSFORM | KEEP_APART
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER

/proc/cultivation_attach_vis(atom/movable/target, icon_file, icon_state, color, size = 64, offset_y = 0, alpha = 200)
	var/obj/effect/abstract/cultivation_vis/visual = new()
	visual.icon = icon_file
	visual.icon_state = icon_state
	visual.color = color
	visual.pixel_x = -(size - 32) / 2
	visual.pixel_y = -(size - 32) / 2 + offset_y
	visual.alpha = 0
	target.vis_contents += visual
	animate(visual, alpha = alpha, time = 0.3 SECONDS)
	return visual

/proc/cultivation_detach_vis(atom/movable/target, obj/effect/abstract/cultivation_vis/visual)
	if(!visual)
		return
	target?.vis_contents -= visual
	qdel(visual)

/// A deep temple bell: a low gong under a soft celeste chime, like a struck singing bowl
/proc/cultivation_temple_sound(atom/source, volume = 60)
	playsound(source, 'sound/effects/gong.ogg', volume, TRUE, frequency = 0.6)
	playsound(source, 'sound/runtime/instruments/synthesis_samples/chromatic/fluid_celeste/C3.ogg', volume, TRUE)

/// Remove (and delete) something from a mob's vis_contents, for delayed fade-outs
/proc/cultivation_remove_vis(atom/movable/target, atom/movable/visual)
	if(!QDELETED(target))
		target.vis_contents -= visual
	qdel(visual)
