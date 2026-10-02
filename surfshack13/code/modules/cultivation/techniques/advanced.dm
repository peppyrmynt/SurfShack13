// Late realm techniques: Void Step, formation arrays, and each law's Nascent Soul signature move.

// ===================== Void Step =====================

/datum/action/cooldown/spell/pointed/cultivation/void_step
	name = "Void Step"
	desc = "Tear a hole in space and step through it to a spot you can see, up to 6 tiles away. \
		While Spiritual Sense lets you see through walls, you can step through them too. Your spirit beast follows you through the rift."
	cast_range = 6
	cooldown_time = 12 SECONDS
	qi_cost = 25
	aim_assist = FALSE

/datum/action/cooldown/spell/pointed/cultivation/void_step/is_valid_target(atom/cast_on)
	var/turf/destination = get_turf(cast_on)
	if(!isopenturf(destination) || destination.is_blocked_turf(exclude_mobs = TRUE))
		owner.balloon_alert(owner, "no room there!")
		return FALSE
	if(get_dist(owner, destination) > cast_range)
		return FALSE
	// Spiritual Sense lets you step to anywhere you can sense, even through walls
	if(!HAS_TRAIT_FROM(owner, TRAIT_XRAY_VISION, SPIRITUAL_SENSE_TRAIT) && !can_see(owner, destination, cast_range))
		owner.balloon_alert(owner, "can't see it!")
		return FALSE
	return TRUE

/datum/action/cooldown/spell/pointed/cultivation/void_step/cast(atom/cast_on)
	. = ..()
	var/mob/living/user = owner
	var/turf/start = get_turf(user)
	var/turf/destination = get_turf(cast_on)
	new /obj/effect/temp_visual/cultivation_void_rift(start)
	new /obj/effect/temp_visual/cultivation_void_rift(destination)
	playsound(start, 'sound/effects/magic/blink.ogg', 50, TRUE)
	cultivation_afterimage(user, 0.6 SECONDS)
	user.forceMove(destination)
	playsound(destination, 'sound/effects/magic/blink.ogg', 50, TRUE)
	cultivation_beast_follow(user, destination, TRUE)
	cultivation_particles(user, /particles/cultivation/void, 1 SECONDS)

/obj/effect/temp_visual/cultivation_void_rift
	icon = 'surfshack13/icons/cultivation/cultivation_effects_64.dmi'
	icon_state = "void_rift"
	pixel_x = -16
	pixel_y = -8
	duration = 0.8 SECONDS
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/cultivation_void_rift/Initialize(mapload)
	. = ..()
	transform = matrix().Scale(0.2, 1)
	animate(src, transform = matrix(), time = 0.2 SECONDS)
	animate(transform = matrix().Scale(0.1, 1), alpha = 0, time = 0.6 SECONDS)

// ===================== Formation arrays =====================

/datum/action/cooldown/spell/cultivation/inscribe_formation
	name = "Inscribe Formation"
	desc = "Inscribe a formation array on the floor around you. Barrier: a ring of qi walls only you, your sect and your friends can pass, for a minute. \
		Gathering: meditating inside cultivates faster and steadies breakthroughs, for five minutes. Alarm: tells you when a stranger steps inside, for ten minutes."
	cooldown_time = 30 SECONDS
	qi_cost = 30

/datum/action/cooldown/spell/cultivation/inscribe_formation/cast(mob/living/cast_on)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(inscribe), cast_on)

/datum/action/cooldown/spell/cultivation/inscribe_formation/proc/inscribe(mob/living/user)
	var/static/list/options = list(
		"Barrier Array" = /obj/effect/cultivation_formation/barrier,
		"Gathering Array" = /obj/effect/cultivation_formation/gathering,
		"Alarm Array" = /obj/effect/cultivation_formation/alarm,
	)
	var/choice = tgui_input_list(user, "Which formation?", "Inscribe Formation", options)
	if(!choice)
		reset_spell_cooldown()
		var/datum/antagonist/cultivator/refund = IS_CULTIVATOR(user)
		refund?.adjust_qi(qi_cost)
		return
	user.visible_message(span_notice("[user] traces glowing trigrams across the floor."))
	cultivation_particles(user, /particles/cultivation/gold, 3 SECONDS)
	if(!do_after(user, 3 SECONDS, user))
		return
	var/formation_type = options[choice]
	// One of each kind per cultivator
	for(var/obj/effect/cultivation_formation/old as anything in GLOB.cultivation_formations)
		if(old.type == formation_type && old.owner_mind == user.mind)
			qdel(old)
	new formation_type(get_turf(user), user)

GLOBAL_LIST_EMPTY(cultivation_formations)

/obj/effect/cultivation_formation
	name = "formation array"
	desc = "A circle of glowing trigrams inscribed on the floor."
	icon = 'surfshack13/icons/cultivation/cultivation_effects_96.dmi'
	icon_state = "sigil_gathering"
	pixel_x = -32
	pixel_y = -32
	layer = BELOW_OBJ_LAYER
	plane = FLOOR_PLANE
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	alpha = 0
	/// Who drew it
	var/datum/mind/owner_mind
	var/lifetime = 5 MINUTES

/obj/effect/cultivation_formation/Initialize(mapload, mob/living/creator)
	. = ..()
	owner_mind = creator?.mind
	GLOB.cultivation_formations += src
	// Activation flare: the array flashes white, overshoots, and settles into its slow glow
	transform = matrix().Scale(0.4)
	color = list(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1, 0.7,0.7,0.7,0)
	animate(src, alpha = 255, transform = matrix().Scale(1.12), time = 0.35 SECONDS, easing = SINE_EASING | EASE_OUT)
	animate(alpha = 200, transform = matrix(), color = COLOR_MATRIX_IDENTITY, time = 0.65 SECONDS, easing = SINE_EASING | EASE_IN)
	animate(alpha = 140, time = 2 SECONDS, loop = -1)
	animate(alpha = 200, time = 2 SECONDS)
	QDEL_IN(src, lifetime)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold(loc)
	playsound(src, 'sound/effects/magic/charge.ogg', 40, TRUE)
	cultivation_guqin_phrase(src, list(5, 3, 1), 0.12 SECONDS, 35)

/obj/effect/cultivation_formation/Destroy()
	GLOB.cultivation_formations -= src
	owner_mind = null
	return ..()

/// Owner, their sect and their friends are allies of the formation
/obj/effect/cultivation_formation/proc/is_ally(mob/living/who)
	if(!who?.mind)
		return FALSE
	if(who.mind == owner_mind)
		return TRUE
	var/datum/jianghu_sect/sect = jianghu_sect_of(owner_mind)
	if(sect && jianghu_sect_of(who.mind) == sect)
		return TRUE
	return owner_mind?.current && (REF(owner_mind.current) in who.faction)

/obj/effect/cultivation_formation/gathering
	name = "gathering array"
	desc = "A circle of trigrams that draws ambient qi inward. Meditating inside it is far more effective."
	icon_state = "sigil_gathering"

/obj/effect/cultivation_formation/barrier
	name = "barrier array"
	desc = "A circle of trigrams holding up a ring of shimmering qi walls."
	icon_state = "sigil_barrier"
	lifetime = 1 MINUTES
	var/list/obj/structure/cultivation_barrier/walls = list()

/obj/effect/cultivation_formation/barrier/Initialize(mapload, mob/living/creator)
	. = ..()
	for(var/turf/open/edge in orange(1, src))
		var/obj/structure/cultivation_barrier/wall = new(edge, src)
		walls += wall

/obj/effect/cultivation_formation/barrier/Destroy()
	QDEL_LIST(walls)
	return ..()

/obj/structure/cultivation_barrier
	name = "qi barrier"
	desc = "A shimmering wall of golden qi. Its maker and their allies pass through it freely."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield-grey"
	color = "#ffd55a"
	alpha = 150
	density = TRUE
	anchored = TRUE
	max_integrity = 60
	var/obj/effect/cultivation_formation/barrier/formation

/obj/structure/cultivation_barrier/Initialize(mapload, obj/effect/cultivation_formation/barrier/formation)
	. = ..()
	src.formation = formation
	alpha = 0
	animate(src, alpha = 255, time = 0.2 SECONDS)
	animate(alpha = 150, time = 0.4 SECONDS)
	flick("shield-flash", src)

/obj/structure/cultivation_barrier/Destroy()
	formation?.walls -= src
	formation = null
	return ..()

/obj/structure/cultivation_barrier/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(isliving(mover) && formation?.is_ally(mover))
		return TRUE

/obj/effect/cultivation_formation/alarm
	name = "alarm array"
	desc = "A circle of trigrams that whispers to its maker whenever a stranger steps inside."
	icon_state = "sigil_alarm"
	lifetime = 10 MINUTES
	/// mob -> next time we'll report them
	var/list/reported = list()

/obj/effect/cultivation_formation/alarm/Initialize(mapload, mob/living/creator)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/effect/cultivation_formation/alarm/Destroy()
	STOP_PROCESSING(SSobj, src)
	reported = null
	return ..()

/obj/effect/cultivation_formation/alarm/process(seconds_per_tick)
	var/mob/living/maker = owner_mind?.current
	if(!maker)
		return
	for(var/mob/living/intruder in range(1, src))
		if(intruder.stat == DEAD || is_ally(intruder) || world.time < reported[REF(intruder)])
			continue
		reported[REF(intruder)] = world.time + 30 SECONDS
		to_chat(maker, span_boldwarning("Your alarm array at [get_area_name(src)] trembles: [intruder] has stepped inside!"))
		maker.balloon_alert(maker, "alarm array!")
		new /obj/effect/temp_visual/circle_wave/cultivation/blood(get_turf(src))

// ===================== Nascent Soul: Metal - Sword Formation =====================

/datum/action/cooldown/spell/cultivation/sword_formation
	name = "Sword Formation"
	desc = "Four spectral swords orbit you for 12 seconds, slashing anyone hostile within 2 tiles and batting aside some projectiles."
	cooldown_time = 45 SECONDS
	qi_cost = 60

/datum/action/cooldown/spell/cultivation/sword_formation/cast(mob/living/cast_on)
	. = ..()
	cast_on.visible_message(span_boldwarning("Four shining swords rise from [cast_on]'s qi and begin to circle [cast_on.p_them()]!"))
	playsound(cast_on, 'sound/items/unsheath.ogg', 60, TRUE)
	cast_on.apply_status_effect(/datum/status_effect/sword_formation)

/datum/status_effect/sword_formation
	id = "sword_formation"
	alert_type = null
	duration = 12 SECONDS
	tick_interval = 1 SECONDS
	var/obj/effect/abstract/cultivation_orbit/orbit

/datum/status_effect/sword_formation/on_apply()
	orbit = new()
	for(var/i in 0 to 3)
		var/image/blade = image('surfshack13/icons/cultivation/cultivation_effects.dmi', "orbit_sword")
		var/angle = i * 90
		blade.pixel_x = round(sin(angle) * 40)
		blade.pixel_y = round(cos(angle) * 40)
		blade.transform = matrix().Turn(angle)
		orbit.add_overlay(blade)
	owner.vis_contents += orbit
	RegisterSignal(owner, COMSIG_ATOM_PRE_BULLET_ACT, PROC_REF(parry_bullet))
	return TRUE

/datum/status_effect/sword_formation/on_remove()
	UnregisterSignal(owner, COMSIG_ATOM_PRE_BULLET_ACT)
	owner.vis_contents -= orbit
	QDEL_NULL(orbit)

/datum/status_effect/sword_formation/tick(seconds_between_ticks)
	for(var/mob/living/victim in orange(2, owner))
		if(victim.stat == DEAD || (REF(owner) in victim.faction) || (victim.mind && jianghu_sect_of(victim.mind) && jianghu_sect_of(victim.mind) == jianghu_sect_of(owner.mind)))
			continue
		victim.apply_damage(12, BRUTE, sharpness = SHARP_EDGED, wound_bonus = 10)
		cultivation_sever_limb(victim, 5, REALM_NASCENT_SOUL)
		new /obj/effect/temp_visual/slash(get_turf(victim), victim, rand(10, 22), rand(10, 22), "#cfe2ff")
		playsound(victim, 'sound/items/weapons/bladeslice.ogg', 30, TRUE)

/datum/status_effect/sword_formation/proc/parry_bullet(mob/living/source, obj/projectile/hitting_projectile, def_zone)
	SIGNAL_HANDLER
	if(!prob(50))
		return NONE
	source.visible_message(span_danger("A circling sword knocks [hitting_projectile] out of the air!"))
	playsound(source, 'sound/items/weapons/parry.ogg', 50, TRUE)
	return COMPONENT_BULLET_BLOCKED

/// Holds orbiting images and spins them around its owner
/obj/effect/abstract/cultivation_orbit
	vis_flags = VIS_INHERIT_PLANE
	appearance_flags = KEEP_TOGETHER | RESET_COLOR | RESET_TRANSFORM
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = ABOVE_MOB_LAYER

/obj/effect/abstract/cultivation_orbit/Initialize(mapload)
	. = ..()
	SpinAnimation(1.2 SECONDS)

// ===================== Nascent Soul: Water - Mirror Lake =====================

/datum/action/cooldown/spell/cultivation/mirror_lake
	name = "Mirror Lake"
	desc = "Become as still as a mirror lake. For 8 seconds, projectiles fired at you are reflected back at the shooter, 50% stronger."
	cooldown_time = 40 SECONDS
	qi_cost = 50

/datum/action/cooldown/spell/cultivation/mirror_lake/cast(mob/living/cast_on)
	. = ..()
	cast_on.apply_status_effect(/datum/status_effect/mirror_lake)

/datum/status_effect/mirror_lake
	id = "mirror_lake"
	alert_type = null
	duration = 8 SECONDS
	var/obj/effect/abstract/cultivation_vis/bubble

/datum/status_effect/mirror_lake/on_apply()
	RegisterSignal(owner, COMSIG_ATOM_PRE_BULLET_ACT, PROC_REF(reflect))
	bubble = cultivation_attach_vis(owner, 'surfshack13/icons/cultivation/cultivation_effects_64.dmi', "water_bubble", "#d8f4ff")
	owner.visible_message(span_boldwarning("The air around [owner] turns as smooth as a mirror!"))
	playsound(owner, 'sound/effects/splash.ogg', 60, TRUE)
	return TRUE

/datum/status_effect/mirror_lake/on_remove()
	UnregisterSignal(owner, COMSIG_ATOM_PRE_BULLET_ACT)
	cultivation_detach_vis(owner, bubble)
	bubble = null

/datum/status_effect/mirror_lake/proc/reflect(mob/living/source, obj/projectile/hitting_projectile, def_zone)
	SIGNAL_HANDLER
	source.visible_message(span_danger("[hitting_projectile] skips off the mirror lake around [source]!"))
	playsound(source, 'sound/effects/splash.ogg', 40, TRUE)
	if(hitting_projectile.firer && hitting_projectile.firer != source)
		hitting_projectile.set_angle(get_angle(source, hitting_projectile.firer))
	else
		hitting_projectile.set_angle(rand(0, 360))
	hitting_projectile.firer = source
	hitting_projectile.damage *= 1.5
	return COMPONENT_BULLET_PIERCED

// ===================== Nascent Soul: Fire - Sea of Flames =====================

/datum/action/cooldown/spell/cultivation/sea_of_flames
	name = "Sea of Flames"
	desc = "Become the furnace. Three ever-wider waves of fire roll out from you across six tiles, each hotter than the last, \
		and the ground keeps burning for eight seconds after. You stand untouched at the eye of the inferno."
	cooldown_time = 90 SECONDS
	qi_cost = 90
	/// Ring radii hit by each wave
	var/static/list/waves = list(list(1, 2), list(3, 4), list(5, 6))

/datum/action/cooldown/spell/cultivation/sea_of_flames/cast(mob/living/cast_on)
	. = ..()
	cast_on.visible_message(span_boldwarning("[cast_on] rises off the ground, wreathed in roaring flame! The air itself begins to burn!"), span_boldnotice("You become the furnace."))
	cultivation_particles(cast_on, /particles/cultivation/embers, 10 SECONDS)
	playsound(cast_on, 'sound/effects/magic/fireball.ogg', 80, TRUE, frequency = 0.5)
	cast_on.add_traits(list(TRAIT_RESISTHEAT, TRAIT_NOFIRE, TRAIT_RESISTHIGHPRESSURE), REF(src))
	cast_on.add_filter("sea_of_flames", 2, list("type" = "outline", "color" = "#ff5a1f", "size" = 2))
	for(var/mob/living/viewer in view(8, cast_on))
		shake_camera(viewer, 2, 1)
	// Telegraph the whole area so people can run
	for(var/turf/open/warn_turf in range(6, cast_on))
		if(warn_turf != get_turf(cast_on))
			new /obj/effect/temp_visual/cultivation_telegraph/fire(warn_turf)
	for(var/i in 1 to length(waves))
		addtimer(CALLBACK(src, PROC_REF(wave), cast_on, i), 1.2 SECONDS + (i - 1) * 0.7 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(burning_sea), cast_on, 4), 3.5 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(end_inferno), cast_on), 12 SECONDS)

/datum/action/cooldown/spell/cultivation/sea_of_flames/proc/wave(mob/living/user, wave_index)
	if(QDELETED(user) || user.stat == DEAD)
		return
	var/list/radii = waves[wave_index]
	var/turf/center = get_turf(user)
	var/obj/effect/temp_visual/circle_wave/cultivation/fire/ring = new(center)
	animate(ring, transform = matrix().Scale(radii[2] * 2 + 1), time = 0.5 SECONDS, flags = ANIMATION_PARALLEL)
	playsound(center, 'sound/effects/magic/fireball.ogg', 60 + wave_index * 10, TRUE, frequency = 1.2 - wave_index * 0.2)
	for(var/mob/living/viewer in view(8, user))
		shake_camera(viewer, 1 + wave_index, 1)
	var/damage = 14 + wave_index * 8
	for(var/turf/open/target_turf in range(radii[2], center))
		if(get_dist(center, target_turf) < radii[1])
			continue
		new /obj/effect/hotspot(target_turf)
		target_turf.hotspot_expose(1000, 100, 1)
		for(var/mob/living/victim in target_turf)
			if(victim == user)
				continue
			victim.apply_damage(damage, BURN)
			victim.adjust_fire_stacks(3 + wave_index)
			victim.ignite_mob()
			to_chat(victim, span_userdanger("A wave of fire engulfs you!"))

/// The sea keeps burning in random spots for a while
/datum/action/cooldown/spell/cultivation/sea_of_flames/proc/burning_sea(mob/living/user, pulses_left)
	if(QDELETED(user) || user.stat == DEAD || pulses_left <= 0)
		return
	var/turf/center = get_turf(user)
	var/list/candidates = list()
	for(var/turf/open/burn_turf in range(6, center))
		if(burn_turf != center)
			candidates += burn_turf
	for(var/i in 1 to min(12, length(candidates)))
		var/turf/open/burn_turf = pick_n_take(candidates)
		new /obj/effect/hotspot(burn_turf)
		burn_turf.hotspot_expose(800, 60, 1)
		for(var/mob/living/victim in burn_turf)
			if(victim != user)
				victim.apply_damage(6, BURN)
				victim.adjust_fire_stacks(2)
				victim.ignite_mob()
	addtimer(CALLBACK(src, PROC_REF(burning_sea), user, pulses_left - 1), 2 SECONDS)

/datum/action/cooldown/spell/cultivation/sea_of_flames/proc/end_inferno(mob/living/user)
	if(QDELETED(user))
		return
	user.remove_traits(list(TRAIT_RESISTHEAT, TRAIT_NOFIRE, TRAIT_RESISTHIGHPRESSURE), REF(src))
	user.remove_filter("sea_of_flames")
	user.visible_message(span_notice("The flames around [user] gutter and die down."))

// ===================== Nascent Soul: Earth - Buddha's Palm =====================

/datum/action/cooldown/spell/pointed/cultivation/buddha_palm
	name = "Buddha's Palm"
	desc = "Call down a colossal golden palm from the heavens. Its shadow appears first; a moment later it slams the 3x3 area flat (45 damage, long knockdown, \
		smashes structures) and a shockwave hurls back everyone within 2 tiles."
	cast_range = 7
	cooldown_time = 45 SECONDS
	qi_cost = 60
	aim_assist = FALSE

/datum/action/cooldown/spell/pointed/cultivation/buddha_palm/is_valid_target(atom/cast_on)
	return TRUE

/datum/action/cooldown/spell/pointed/cultivation/buddha_palm/cast(atom/cast_on)
	. = ..()
	var/turf/center = get_turf(cast_on)
	owner.say("Buddha's Palm!", forced = "buddha's palm")
	cultivation_temple_sound(owner, 50)
	var/obj/effect/temp_visual/cultivation_buddha_palm/palm = new(center)
	palm.owner_ref = WEAKREF(owner)

/obj/effect/temp_visual/cultivation_buddha_palm
	icon = 'surfshack13/icons/cultivation/cultivation_effects_64.dmi'
	icon_state = "buddha_palm"
	pixel_x = -16
	pixel_y = 240
	alpha = 0
	duration = 2.2 SECONDS
	layer = ABOVE_ALL_MOB_LAYER
	var/datum/weakref/owner_ref
	var/obj/effect/temp_visual/cultivation_palm_shadow/shadow

/obj/effect/temp_visual/cultivation_buddha_palm/Initialize(mapload)
	. = ..()
	shadow = new(loc)
	transform = matrix().Scale(1.6)
	animate(src, alpha = 255, time = 0.4 SECONDS)
	animate(pixel_y = 0, time = 0.8 SECONDS, easing = QUAD_EASING | EASE_IN)
	addtimer(CALLBACK(src, PROC_REF(slam)), 1.2 SECONDS)

/obj/effect/temp_visual/cultivation_buddha_palm/proc/slam()
	var/mob/living/caster = owner_ref?.resolve()
	cultivation_great_bell(src, 80)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(loc)
	var/obj/effect/temp_visual/circle_wave/cultivation/earth/dust = new(loc)
	dust.transform = matrix().Scale(0.1)
	animate(dust, transform = matrix().Scale(5), time = 0.6 SECONDS, flags = ANIMATION_PARALLEL)
	// The palm squashes into the floor
	animate(src, transform = matrix().Scale(2, 1.2), time = 0.08 SECONDS)
	animate(transform = matrix().Scale(1.6), time = 0.25 SECONDS, easing = ELASTIC_EASING)
	for(var/mob/living/viewer in range(7, src))
		shake_camera(viewer, 4, 3)
	var/turf/center = get_turf(src)
	for(var/turf/hit_turf in range(2, center))
		var/inner = get_dist(center, hit_turf) <= 1
		new /obj/effect/temp_visual/mook_dust(hit_turf)
		for(var/mob/living/victim in hit_turf)
			if(victim == caster)
				continue
			if(inner)
				victim.apply_damage(45, BRUTE, wound_bonus = 10)
				victim.Knockdown(3 SECONDS)
				to_chat(victim, span_userdanger("A colossal golden palm crushes you into the floor!"))
			else
				victim.apply_damage(20, BRUTE)
				victim.Knockdown(1 SECONDS)
				if(!HAS_TRAIT(victim, TRAIT_PUSHIMMUNE))
					victim.throw_at(get_edge_target_turf(victim, get_dir(center, victim)), 3, 2, caster)
				to_chat(victim, span_userdanger("The shockwave of a giant palm hurls you back!"))
		for(var/obj/structure/smashed in hit_turf)
			if(smashed.uses_integrity && !(smashed.resistance_flags & INDESTRUCTIBLE))
				smashed.take_damage(inner ? 120 : 40, BRUTE, MELEE)
	animate(alpha = 0, time = 0.6 SECONDS)

/obj/effect/temp_visual/cultivation_buddha_palm/Destroy()
	QDEL_NULL(shadow)
	return ..()

/obj/effect/temp_visual/cultivation_palm_shadow
	icon = 'surfshack13/icons/cultivation/cultivation_effects_64.dmi'
	icon_state = "buddha_palm_shadow"
	pixel_x = -16
	pixel_y = -16
	alpha = 0
	duration = 1.4 SECONDS
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/cultivation_palm_shadow/Initialize(mapload)
	. = ..()
	transform = matrix().Scale(0.4)
	animate(src, alpha = 120, transform = matrix().Scale(1.6), time = 1.2 SECONDS, easing = QUAD_EASING | EASE_IN)

// ===================== Nascent Soul: Wood - Myriad Spring Revival =====================

/datum/action/cooldown/spell/cultivation/spring_revival
	name = "Myriad Spring Revival"
	desc = "Release a wave of spring qi. Everyone friendly within 5 tiles is healed (brute, burn and toxins), has their two worst wounds closed, \
		and shakes off stuns. The plants around you bloom."
	cooldown_time = 60 SECONDS
	qi_cost = 70

/datum/action/cooldown/spell/cultivation/spring_revival/cast(mob/living/cast_on)
	. = ..()
	cast_on.visible_message(span_boldnotice("A warm spring wind blows out from [cast_on], carrying blossoms!"))
	new /obj/effect/temp_visual/circle_wave/tree/healer(get_turf(cast_on))
	cultivation_particles(cast_on, /particles/cultivation/petals, 3 SECONDS)
	playsound(cast_on, 'sound/effects/magic/charge.ogg', 50, TRUE)
	for(var/mob/living/friend in view(5, cast_on))
		// People, and your own spirit beast or pets
		if(friend.stat == DEAD || (!ishuman(friend) && !(REF(cast_on) in friend.faction)))
			continue
		friend.heal_overall_damage(brute = 40, burn = 50)
		friend.adjustToxLoss(-15)
		cultivation_mend_wounds(friend, WOUND_SEVERITY_CRITICAL, 2)
		friend.AdjustAllImmobility(-5 SECONDS)
		new /obj/effect/temp_visual/heal(get_turf(friend), "#5fd35f")
	for(var/obj/machinery/hydroponics/tray in view(5, cast_on))
		if(tray.myseed)
			tray.set_plant_health(tray.myseed.endurance)
			tray.set_weedlevel(0)
			tray.set_pestlevel(0)
