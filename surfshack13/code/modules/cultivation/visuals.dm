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

/// Spring qi closes wounds (burns, cuts, breaks), worst first, up to a severity. Returns how many were mended.
/proc/cultivation_mend_wounds(mob/living/carbon/patient, max_severity = WOUND_SEVERITY_MODERATE, count = 1)
	if(!iscarbon(patient) || !length(patient.all_wounds))
		return 0
	var/list/wounds = patient.all_wounds.Copy()
	var/mended = 0
	while(mended < count && length(wounds))
		var/datum/wound/worst
		for(var/datum/wound/wound as anything in wounds)
			if(wound.severity > max_severity)
				continue
			if(!worst || wound.severity > worst.severity)
				worst = wound
		if(!worst)
			break
		wounds -= worst
		to_chat(patient, span_nicegreen("Spring qi soothes away your [lowertext(worst.name)]."))
		worst.remove_wound()
		mended++
	return mended

/// A great temple bell struck by a giant: a deep bell, a slow booming gong, the thud of impact, then a ringing overtone
/proc/cultivation_great_bell(atom/source, volume = 80)
	playsound(source, 'sound/runtime/instruments/synthesis_samples/chromatic/fluid_celeste/C2.ogg', volume, TRUE)
	playsound(source, 'sound/effects/gong.ogg', volume, TRUE, frequency = 0.35)
	playsound(source, 'sound/effects/explosion/explosion_distant.ogg', volume * 0.7, TRUE)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(playsound), source, 'sound/runtime/instruments/synthesis_samples/chromatic/fluid_celeste/C4.ogg', volume * 0.5, TRUE), 0.35 SECONDS)

// ===================== Music =====================

/// Gong scale (do re mi sol la), as playback speeds relative to the sample's root note
#define CULTIVATION_PENTATONIC list(1, 1.122, 1.26, 1.498, 1.682, 2)

/// A guqin-like phrase: plucked nylon strings walking up the pentatonic scale. Notes are indexes into CULTIVATION_PENTATONIC.
/proc/cultivation_guqin_phrase(atom/source, list/notes = list(1, 2, 3, 5), gap = 0.18 SECONDS, volume = 45)
	var/list/scale = CULTIVATION_PENTATONIC
	var/delay = 0
	for(var/note in notes)
		var/speed = scale[clamp(note, 1, length(scale))]
		if(delay)
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(playsound), source, 'sound/runtime/instruments/synthesis_samples/guitar/crisis_nylon/c4.ogg', volume, FALSE, 0, SOUND_FALLOFF_EXPONENT, speed), delay)
		else
			playsound(source, 'sound/runtime/instruments/synthesis_samples/guitar/crisis_nylon/c4.ogg', volume, FALSE, frequency = speed)
		delay += gap

#undef CULTIVATION_PENTATONIC

// ===================== Distortion =====================

/// Heat-haze style warp that bends everything behind it
/atom/movable/warp_effect/cultivation
	alpha = 0

/// A ring of bent air rushing outward from something, `radius` tiles across at its widest
/proc/cultivation_distortion_wave(atom/movable/center, radius = 4, time = 0.8 SECONDS, strength = 200)
	if(QDELETED(center))
		return
	var/atom/movable/warp_effect/cultivation/warp = new(center)
	// The warp sprite is 11 tiles across
	var/final_scale = max(radius * 2 / 11, 0.2)
	warp.transform = matrix().Scale(0.05)
	center.vis_contents += warp
	animate(warp, alpha = strength, transform = matrix().Scale(final_scale * 0.5), time = time * 0.3, easing = SINE_EASING | EASE_OUT)
	animate(alpha = 0, transform = matrix().Scale(final_scale), time = time * 0.7, easing = SINE_EASING | EASE_IN)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cultivation_remove_vis), center, warp), time)

// ===================== Small strikes =====================

/// A quick star of qi where fingers or a talisman land
/obj/effect/temp_visual/cultivation_spark
	icon = 'icons/effects/effects.dmi'
	icon_state = "impact_laser_yellow"
	layer = ABOVE_MOB_LAYER
	duration = 0.4 SECONDS
	blend_mode = BLEND_ADD
	randomdir = FALSE

/obj/effect/temp_visual/cultivation_spark/Initialize(mapload, spark_color, offset_x = 0, offset_y = 0)
	. = ..()
	if(spark_color)
		color = spark_color
	pixel_x = offset_x
	pixel_y = offset_y
	transform = matrix().Scale(0.4)
	var/matrix/burst = matrix()
	burst.Scale(1.1)
	burst.Turn(rand(-30, 30))
	animate(src, transform = burst, time = 0.15 SECONDS, easing = SINE_EASING | EASE_OUT)
	animate(alpha = 0, time = 0.25 SECONDS)

// ===================== Breakthrough =====================

/// The name of the new realm, rising in gold above the cultivator
/obj/effect/temp_visual/cultivation_realm_banner
	icon = null
	icon_state = null
	duration = 4 SECONDS
	randomdir = FALSE
	layer = ABOVE_ALL_MOB_LAYER
	plane = ABOVE_GAME_PLANE
	maptext_width = 256
	maptext_height = 64
	maptext_x = -112
	maptext_y = 36
	alpha = 0

/obj/effect/temp_visual/cultivation_realm_banner/Initialize(mapload, realm_text)
	. = ..()
	maptext = MAPTEXT_PIXELLARI("<span style='text-align: center; color: #ffe27a; font-size: 14pt'>[realm_text]</span>")
	animate(src, alpha = 255, maptext_y = 48, time = 0.6 SECONDS, easing = SINE_EASING | EASE_OUT)
	animate(maptext_y = 54, time = 2.4 SECONDS)
	animate(alpha = 0, maptext_y = 62, time = 1 SECONDS, easing = SINE_EASING | EASE_IN)

/// The whole show of a successful breakthrough: lift off, a pillar of light, a crashing wave of qi, the realm's name, and the strings.
/proc/cultivation_breakthrough_sequence(mob/living/user, realm_text)
	var/turf/here = get_turf(user)
	if(!here)
		return
	// Rise on a column of qi
	animate(user, pixel_z = 10, time = 0.8 SECONDS, easing = SINE_EASING | EASE_OUT, flags = ANIMATION_RELATIVE | ANIMATION_PARALLEL)
	animate(time = 1.2 SECONDS)
	animate(pixel_z = -10, time = 0.8 SECONDS, easing = SINE_EASING | EASE_IN, flags = ANIMATION_RELATIVE)
	user.add_filter("breakthrough_radiance", 3, list("type" = "outline", "color" = "#fff3b0", "size" = 3, "alpha" = 0))
	var/radiance = user.get_filter("breakthrough_radiance")
	animate(radiance, alpha = 255, time = 0.4 SECONDS, flags = ANIMATION_PARALLEL)
	animate(alpha = 0, time = 2.4 SECONDS)
	addtimer(CALLBACK(user, TYPE_PROC_REF(/datum, remove_filter), "breakthrough_radiance"), 2.8 SECONDS)
	cultivation_particles(user, /particles/cultivation/gold, 3 SECONDS)
	new /obj/effect/temp_visual/cultivation_ascension_pillar(here)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(here)
	cultivation_distortion_wave(user, 7, 1.2 SECONDS)
	playsound(user, 'sound/effects/magic/charge.ogg', 70, TRUE)
	cultivation_guqin_phrase(user, list(1, 2, 3, 4, 5, 6))
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cultivation_temple_sound), user, 70), 1.1 SECONDS)
	new /obj/effect/temp_visual/cultivation_realm_banner(here, realm_text)
