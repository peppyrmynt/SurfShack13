/**
 * Body Molding martial arts: the big, loud, earth-shattering moves. Every one of them is shouted, like in the novels.
 *
 * Everything scales hard with stage. Around Vajra Viscera (6) plain walls start giving way, from Undying Flesh (8) even
 * reinforced walls do, and a Primordial Chaos Body (9) is a walking disaster that can tear open the station (yes, into space).
 * Anyone of a higher realm braces against the knockdowns, taking half damage.
 */

// ===================== Shared helpers =====================

/// What walls a stage can break: 0 none, 1 plain walls, 2 reinforced walls too
/proc/body_art_wall_tier(stage)
	if(stage >= 8)
		return 2
	if(stage >= 6)
		return 1
	return 0

/// Stage of whoever is using a body art
/proc/body_art_stage(mob/living/user)
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(user)
	return body_datum ? body_datum.stage : 0

/// Hit someone with a body art. Higher-realm cultivators brace: half damage, no knockdown.
/proc/body_art_hit(mob/living/user, mob/living/victim, damage, knockdown = 0, technique_name = "a body art")
	if(QDELETED(victim) || victim == user || victim.stat == DEAD)
		return FALSE
	if(cultivation_realm_of(victim) > cultivation_realm_of(user))
		victim.apply_damage(damage / 2, BRUTE, wound_bonus = CANT_WOUND)
		to_chat(victim, span_warning("You brace against [user]'s [technique_name]."))
		return FALSE
	victim.apply_damage(damage, BRUTE)
	if(knockdown)
		victim.Knockdown(knockdown)
	log_combat(user, victim, "hit with [technique_name]")
	return TRUE

/// Smash windows, grilles, tables, girders, machines and (by wall tier) walls. Returns TRUE if anything gave way.
/proc/body_art_smash(turf/target, mob/living/user, power, wall_tier = 0)
	if(!target)
		return FALSE
	. = FALSE
	if(iswallturf(target))
		var/reinforced = istype(target, /turf/closed/wall/r_wall)
		if(wall_tier >= (reinforced ? 2 : 1))
			var/turf/closed/wall/wall = target
			wall.dismantle_wall(devastated = TRUE)
			new /obj/effect/temp_visual/cultivation_rubble(target)
			return TRUE
		return FALSE
	for(var/obj/thing in target)
		if(!thing.uses_integrity || (thing.resistance_flags & INDESTRUCTIBLE))
			continue
		// Doors: airlocks and windoors give way to anything that breaks walls (or hits hard enough), blast doors only at the reinforced tier
		if(istype(thing, /obj/machinery/door))
			var/blast_door = istype(thing, /obj/machinery/door/poddoor)
			if(blast_door ? wall_tier >= 2 : (wall_tier >= 1 || power >= 150))
				thing.visible_message(span_danger("[thing] is torn out of its frame!"))
				playsound(thing, 'sound/effects/bang.ogg', 70, TRUE)
				thing.take_damage(thing.max_integrity * 3, BRUTE, MELEE, armour_penetration = 100)
				. = TRUE
			else if(power >= 80)
				thing.take_damage(power, BRUTE, MELEE, armour_penetration = 50)
				. = TRUE
			continue
		if(istype(thing, /obj/structure/window) || istype(thing, /obj/structure/grille) || istype(thing, /obj/structure/table) || istype(thing, /obj/structure/girder) \
			|| (power >= 80 && (isstructure(thing) || ismachinery(thing)) && thing.density))
			thing.take_damage(power, BRUTE, MELEE)
			. = TRUE

/// Crack the floor tiles around a point and leave a crater
/proc/body_art_crack_ground(turf/center, radius = 1, chance = 50, crater = TRUE)
	if(!center)
		return
	for(var/turf/open/floor/floor in range(radius, center))
		if(prob(chance))
			floor.break_tile()
	if(crater && isopenturf(center))
		new /obj/effect/temp_visual/cultivation_crater(center)
	new /obj/effect/temp_visual/cultivation_rubble(center)

/**
 * A shockwave tearing a trench through everything: `length` tiles along `direction`, `half_width` tiles to either side.
 * Breaks walls by tier, smashes structures, cracks the floor, and hurls people along with it.
 */
/proc/body_art_shatter_line(mob/living/user, turf/origin, direction, length, half_width, damage, wall_tier, technique_name, step_delay = 0.5)
	var/turf/center = origin
	for(var/step in 1 to length)
		center = get_step(center, direction)
		if(!center)
			return
		var/list/row = list(center)
		var/turf/left = center
		var/turf/right = center
		for(var/offset in 1 to half_width)
			left = get_step(left, turn(direction, 90))
			right = get_step(right, turn(direction, -90))
			if(left)
				row += left
			if(right)
				row += right
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(body_art_shatter_row), user, row, direction, damage, wall_tier, technique_name), step * step_delay)

/proc/body_art_shatter_row(mob/living/user, list/row, direction, damage, wall_tier, technique_name)
	var/turf/middle = row[1]
	playsound(middle, pick('sound/effects/rock/rock_break.ogg', 'sound/effects/meteorimpact.ogg'), 50, TRUE)
	for(var/turf/where as anything in row)
		new /obj/effect/temp_visual/kinetic_blast(where)
		if(prob(60))
			new /obj/effect/temp_visual/cultivation_rubble(where)
		body_art_smash(where, user, 120, wall_tier)
		if(isfloorturf(where) && prob(50))
			var/turf/open/floor/floor = where
			floor.break_tile()
		for(var/mob/living/victim in where)
			if(victim == user)
				continue
			if(body_art_hit(user, victim, damage, 2 SECONDS, technique_name) && !HAS_TRAIT(victim, TRAIT_PUSHIMMUNE))
				victim.throw_at(get_edge_target_turf(victim, direction), 3, 2, user)
	for(var/mob/living/viewer in range(5, middle))
		shake_camera(viewer, 2, 2)

/// Wuxia heroes announce their moves
/proc/body_art_shout(mob/living/user, technique_name)
	user.say("[uppertext(technique_name)]!!", forced = "body molding art")
	// Lion's Roar: tempered lungs make the shout itself a blow
	if(body_group_level(user, "lungs") < 7)
		return
	for(var/mob/living/listener in range(1, user))
		if(listener != user && listener.stat == CONSCIOUS && cultivation_realm_of(listener) <= cultivation_realm_of(user))
			listener.adjust_staggered_up_to(STAGGERED_SLOWDOWN_LENGTH, 10 SECONDS)
			listener.Shake(1, 1, 0.3 SECONDS)

/// A cracked crater that lingers for a while
/obj/effect/temp_visual/cultivation_crater
	icon = 'surfshack13/icons/cultivation/cultivation_effects_64.dmi'
	icon_state = "crater"
	pixel_x = -16
	pixel_y = -16
	duration = 30 SECONDS
	randomdir = FALSE
	layer = ABOVE_OPEN_TURF_LAYER
	plane = FLOOR_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/temp_visual/cultivation_crater/Initialize(mapload, scale = 1)
	. = ..()
	var/matrix/shape = matrix()
	shape.Scale(scale)
	shape.Turn(pick(0, 90, 180, 270))
	transform = shape
	animate(src, alpha = 255, time = 27 SECONDS)
	animate(alpha = 0, time = 3 SECONDS)

/// A burst of flying rock chips and dust
/obj/effect/temp_visual/cultivation_rubble
	icon = null
	duration = 1.2 SECONDS
	randomdir = FALSE

/obj/effect/temp_visual/cultivation_rubble/Initialize(mapload)
	. = ..()
	cultivation_particles(src, /particles/cultivation/rubble, 0.6 SECONDS)
	new /obj/effect/temp_visual/small_smoke/halfsecond(loc)

/particles/cultivation/rubble
	icon_state = list("rubble_1" = 1, "rubble_2" = 1, "rubble_3" = 1)
	count = 40
	spawning = 20
	lifespan = 0.8 SECONDS
	fade = 0.3 SECONDS
	position = generator(GEN_CIRCLE, 0, 10, NORMAL_RAND)
	velocity = generator(GEN_CIRCLE, 3, 6, NORMAL_RAND)
	gravity = list(0, -0.8)
	drift = list(0, 0)
	spin = generator(GEN_NUM, -20, 20)
	scale = generator(GEN_VECTOR, list(0.8, 0.8), list(1.4, 1.4), NORMAL_RAND)

// ===================== Earth-Shattering Stomp =====================

/datum/action/cooldown/spell/body_art/earth_stomp
	name = "Earth-Shattering Stomp"
	desc = "Drive your heel into the floor. Everyone around you is knocked flat and the tiles crack. The radius and force grow with your stage: \
		from Vajra Viscera it wrecks furniture and machines, and a Primordial Chaos Body's stomp brings the walls down around it."
	cooldown_time = 25 SECONDS
	exhaustion_cost = 20

/datum/action/cooldown/spell/body_art/earth_stomp/cast(mob/living/cast_on)
	. = ..()
	var/stage = body_art_stage(cast_on)
	var/radius = 1 + round(stage / 2)
	var/turf/center = get_turf(cast_on)
	body_art_shout(cast_on, name)
	cast_on.visible_message(span_danger("[cast_on] stamps down and the floor buckles!"))
	playsound(center, 'sound/effects/meteorimpact.ogg', 60 + 4 * stage, TRUE)
	if(stage >= 7)
		playsound(center, 'sound/effects/explosion/explosion_distant.ogg', 60, TRUE)
	cast_on.Shake(1, 1, 0.3 SECONDS)
	new /obj/effect/temp_visual/circle_wave/cultivation/earth(center)
	new /obj/effect/temp_visual/cultivation_crater(center, 1 + stage / 6)
	cultivation_distortion_wave(cast_on, radius + 1, 0.6 SECONDS, 180 + 6 * stage)
	body_art_crack_ground(center, radius, 30 + 6 * stage, crater = FALSE)
	var/wall_tier = stage >= 9 ? 2 : 0
	for(var/turf/nearby in range(radius, center))
		if(stage >= 6)
			body_art_smash(nearby, cast_on, 40 + 10 * stage, get_dist(nearby, center) <= 2 ? wall_tier : 0)
		if(stage >= 5 && prob(25))
			new /obj/effect/temp_visual/cultivation_rubble(nearby)
	for(var/mob/living/victim in range(radius + 2, center))
		shake_camera(victim, 2 + round(stage / 3), 2)
		if(victim != cast_on && get_dist(victim, center) <= radius)
			body_art_hit(cast_on, victim, 4 + stage, 1 SECONDS + stage * 0.2 SECONDS, name)

// ===================== Hundred Fist Barrage =====================

/datum/action/cooldown/spell/pointed/body_art/hundred_fists
	name = "Hundred Fist Barrage"
	desc = "A blur of fists on someone beside you, more blows the higher your stage, the last one sending them flying. \
		From Golden Body the final blow's shockwave tears on through whatever is behind them."
	cast_range = 1
	cooldown_time = 20 SECONDS
	exhaustion_cost = 25

/datum/action/cooldown/spell/pointed/body_art/hundred_fists/is_valid_target(atom/cast_on)
	return ..() && isliving(cast_on)

/datum/action/cooldown/spell/pointed/body_art/hundred_fists/cast(mob/living/cast_on)
	. = ..()
	body_art_shout(owner, name)
	INVOKE_ASYNC(src, PROC_REF(barrage), owner, cast_on)

/datum/action/cooldown/spell/pointed/body_art/hundred_fists/proc/barrage(mob/living/user, mob/living/victim)
	var/stage = body_art_stage(user)
	var/arm_level = max(body_part_level(user, BODY_ZONE_L_ARM), body_part_level(user, BODY_ZONE_R_ARM))
	var/blows = 8 + stage
	var/gap = max(0.25 SECONDS - stage * 0.02 SECONDS, 0.08 SECONDS)
	for(var/i in 1 to blows)
		if(QDELETED(user) || QDELETED(victim) || user.incapacitated || get_dist(user, victim) > 1)
			return
		user.do_attack_animation(victim, ATTACK_EFFECT_PUNCH)
		cultivation_afterimage(user, 0.25 SECONDS)
		playsound(victim, pick('sound/items/weapons/punch1.ogg', 'sound/items/weapons/punch2.ogg', 'sound/items/weapons/punch3.ogg', 'sound/items/weapons/punch4.ogg'), 40, TRUE)
		new /obj/effect/temp_visual/cultivation_spark(get_turf(victim), "#ffd27a", rand(-8, 8), rand(-4, 12))
		victim.apply_damage(2 + round(arm_level / 2), BRUTE, wound_bonus = CANT_WOUND)
		victim.Shake(1, 1, 0.1 SECONDS)
		sleep(gap)
	if(QDELETED(victim) || get_dist(user, victim) > 1)
		return
	var/direction = get_dir(user, victim)
	victim.visible_message(span_danger("[user]'s final blow launches [victim] across the room!"), span_userdanger("The last blow sends you flying!"))
	playsound(victim, 'sound/effects/meteorimpact.ogg', 60, TRUE)
	cultivation_distortion_wave(victim, 2 + round(stage / 3), 0.5 SECONDS, 200)
	body_art_hit(user, victim, 6 + stage, 1.5 SECONDS, name)
	if(stage >= 7)
		body_art_shatter_line(user, get_turf(victim), direction, (stage - 5) * 2, stage >= 9 ? 1 : 0, 8 + stage, body_art_wall_tier(stage), name)
	if(!HAS_TRAIT(victim, TRAIT_PUSHIMMUNE))
		victim.throw_at(get_edge_target_turf(victim, direction), 4 + round(stage / 2), 2 + round(stage / 3), user)

// ===================== Raging Bull Charge =====================

/datum/action/cooldown/spell/pointed/body_art/bull_charge
	name = "Raging Bull Charge"
	desc = "Charge in a straight line, faster and further the higher your stage (4 plus your stage in tiles), bowling people aside and bursting through windows, grilles and tables. \
		From Vajra Viscera you burst through walls, from Undying Flesh through reinforced walls and your charge carves a three-wide trench."
	cast_range = 9
	cooldown_time = 30 SECONDS
	exhaustion_cost = 30
	aim_assist = FALSE

/datum/action/cooldown/spell/pointed/body_art/bull_charge/is_valid_target(atom/cast_on)
	return get_turf(cast_on) != get_turf(owner)

/datum/action/cooldown/spell/pointed/body_art/bull_charge/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	var/mob/living/user = owner
	if(user.buckled || HAS_TRAIT(user, TRAIT_RESTRAINED) || user.body_position == LYING_DOWN)
		user.balloon_alert(user, "can't charge now!")
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/pointed/body_art/bull_charge/cast(atom/cast_on)
	. = ..()
	body_art_shout(owner, name)
	INVOKE_ASYNC(src, PROC_REF(charge), owner, get_dir(owner, cast_on))

/datum/action/cooldown/spell/pointed/body_art/bull_charge/proc/charge(mob/living/user, direction)
	var/stage = body_art_stage(user)
	var/steps = 4 + stage
	var/wall_tier = body_art_wall_tier(stage)
	var/step_delay = stage >= 8 ? world.tick_lag : (stage >= 6 ? 0.05 SECONDS : 0.1 SECONDS)
	var/wide = stage >= 8
	user.pulledby?.stop_pulling()
	user.add_traits(list(TRAIT_IMMOBILIZED), REF(src))
	user.add_filter("bull_charge", 2, list("type" = "outline", "color" = "#e0a050", "size" = 1))
	for(var/i in 1 to steps)
		if(QDELETED(user) || user.stat != CONSCIOUS)
			break
		var/turf/next = get_step(user, direction)
		if(!next)
			break
		var/list/swath = list(next)
		if(wide)
			swath += get_step(next, turn(direction, 90))
			swath += get_step(next, turn(direction, -90))
		for(var/turf/hit_turf as anything in swath)
			if(!hit_turf)
				continue
			if(body_art_smash(hit_turf, user, 120 + 10 * stage, wall_tier))
				playsound(hit_turf, 'sound/effects/rock/rock_break.ogg', 60, TRUE)
				new /obj/effect/temp_visual/cultivation_rubble(hit_turf)
			if(stage >= 5 && isfloorturf(hit_turf) && prob(30 + 5 * stage))
				var/turf/open/floor/floor = hit_turf
				floor.break_tile()
			for(var/mob/living/victim in hit_turf)
				if(victim == user)
					continue
				if(body_art_hit(user, victim, 8 + 2 * stage, 1.5 SECONDS, name) && !HAS_TRAIT(victim, TRAIT_PUSHIMMUNE))
					victim.throw_at(get_edge_target_turf(victim, pick(turn(direction, 90), turn(direction, -90))), 2 + round(stage / 3), 2, user)
					playsound(victim, 'sound/effects/meteorimpact.ogg', 40, TRUE)
		if(next.is_blocked_turf(exclude_mobs = FALSE))
			user.visible_message(span_danger("[user] slams into [next] and stops dead!"), span_warning("You slam into something that won't give!"))
			playsound(user, 'sound/effects/bang.ogg', 50, TRUE)
			user.Shake(2, 2, 0.4 SECONDS)
			break
		cultivation_afterimage(user, 0.4 SECONDS)
		user.forceMove(next)
		user.setDir(direction)
		new /obj/effect/temp_visual/small_smoke/halfsecond(get_turf(user))
		playsound(user, 'sound/effects/footstep/heavy1.ogg', 50, TRUE)
		for(var/mob/living/viewer in range(4, user))
			shake_camera(viewer, 1, 1)
		sleep(step_delay)
	if(!QDELETED(user))
		user.remove_traits(list(TRAIT_IMMOBILIZED), REF(src))
		user.remove_filter("bull_charge")

// ===================== Falling Mountain Descent =====================

/datum/action/cooldown/spell/pointed/body_art/falling_star
	name = "Falling Mountain Descent"
	desc = "Leap high into the air and come down on a spot you can see like a falling mountain. The landing craters the floor, smashes everyone at the centre \
		and flattens everyone around it. The blast grows with your stage; a Golden Body's landing brings down walls, and a Primordial Chaos Body's levels the room."
	cast_range = 9
	cooldown_time = 40 SECONDS
	exhaustion_cost = 30
	aim_assist = FALSE

/datum/action/cooldown/spell/pointed/body_art/falling_star/is_valid_target(atom/cast_on)
	var/turf/landing = get_turf(cast_on)
	if(!isopenturf(landing) || landing.is_blocked_turf(exclude_mobs = TRUE) || !can_see(owner, landing, cast_range))
		owner.balloon_alert(owner, "can't land there!")
		return FALSE
	return TRUE

/datum/action/cooldown/spell/pointed/body_art/falling_star/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	var/mob/living/user = owner
	if(user.buckled || user.pulledby || HAS_TRAIT(user, TRAIT_RESTRAINED) || user.body_position == LYING_DOWN)
		user.balloon_alert(user, "can't leap now!")
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/pointed/body_art/falling_star/cast(atom/cast_on)
	. = ..()
	body_art_shout(owner, name)
	INVOKE_ASYNC(src, PROC_REF(descend), owner, get_turf(cast_on))

/datum/action/cooldown/spell/pointed/body_art/falling_star/proc/descend(mob/living/user, turf/landing)
	var/stage = body_art_stage(user)
	var/hang_time = max(0.8 SECONDS - stage * 0.05 SECONDS, 0.4 SECONDS)
	user.add_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), REF(src))
	var/turf/start = get_turf(user)
	new /obj/effect/temp_visual/cultivation_rubble(start)
	body_art_crack_ground(start, stage >= 6 ? 1 : 0, 40, crater = stage >= 6)
	playsound(start, 'sound/effects/rock/rock_break.ogg', 50, TRUE, frequency = 1.3)
	animate(user, pixel_z = 128, alpha = 0, time = hang_time * 0.75, easing = SINE_EASING | EASE_IN, flags = ANIMATION_RELATIVE | ANIMATION_PARALLEL)
	var/obj/effect/temp_visual/cultivation_landing_shadow/shadow = new(landing, 1 + stage / 4)
	sleep(hang_time)
	qdel(shadow)
	if(QDELETED(user))
		return
	user.forceMove(landing)
	animate(user, pixel_z = -128, alpha = 255, time = 0.2 SECONDS, easing = SINE_EASING | EASE_IN, flags = ANIMATION_RELATIVE | ANIMATION_PARALLEL)
	sleep(0.2 SECONDS)
	user.remove_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), REF(src))
	if(QDELETED(user))
		return
	// Impact
	var/blast_radius = 2 + round(stage / 3)
	var/wall_radius = stage >= 9 ? 3 : (stage >= 7 ? 1 : 0)
	user.visible_message(span_boldwarning("[user] crashes down like a falling mountain!"))
	playsound(landing, 'sound/effects/meteorimpact.ogg', 90, TRUE)
	playsound(landing, 'sound/effects/explosion/explosion_distant.ogg', 60 + 4 * stage, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/earth(landing)
	new /obj/effect/temp_visual/cultivation_crater(landing, 1 + stage / 4)
	cultivation_distortion_wave(user, blast_radius + 3, 0.8 SECONDS, 230 + 2 * stage)
	body_art_crack_ground(landing, blast_radius, 40 + 5 * stage, crater = FALSE)
	for(var/turf/nearby in range(blast_radius, landing))
		var/distance = get_dist(nearby, landing)
		body_art_smash(nearby, user, max(140 - 20 * distance, 40) + 5 * stage, distance <= wall_radius ? body_art_wall_tier(stage) : 0)
		if(prob(30))
			new /obj/effect/temp_visual/cultivation_rubble(nearby)
	for(var/mob/living/viewer in range(blast_radius + 5, landing))
		shake_camera(viewer, 3 + round(stage / 2), 3)
	for(var/mob/living/victim in range(blast_radius, landing))
		if(victim == user)
			continue
		var/distance = get_dist(victim, landing)
		if(distance <= 0)
			body_art_hit(user, victim, 15 + 2 * stage, 2 SECONDS + stage * 0.2 SECONDS, name)
		else if(body_art_hit(user, victim, 6 + stage - distance, 1 SECONDS + stage * 0.1 SECONDS, name) && stage >= 5 && !HAS_TRAIT(victim, TRAIT_PUSHIMMUNE))
			victim.throw_at(get_edge_target_turf(victim, get_dir(landing, victim)), 1 + round(stage / 3), 2, user)

/// Where you're about to land
/obj/effect/temp_visual/cultivation_landing_shadow
	icon = 'icons/effects/effects.dmi'
	icon_state = "shadow_telegraph"
	duration = 1 SECONDS
	randomdir = FALSE
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/cultivation_landing_shadow/Initialize(mapload, scale = 1)
	. = ..()
	transform = matrix().Scale(0.3)
	animate(src, transform = matrix().Scale(1.4 * scale), time = 0.8 SECONDS)

// ===================== Mountain-Toppling Throw =====================

/datum/action/cooldown/spell/pointed/body_art/mountain_hurl
	name = "Mountain-Toppling Throw"
	desc = "Grab someone, then use this and click where to throw them: they fly further the higher your stage and crater the floor where they land, \
		knocking down everyone nearby. From Undying Flesh the impact brings down the walls around it."
	cast_range = 9
	cooldown_time = 30 SECONDS
	exhaustion_cost = 25
	aim_assist = FALSE

/datum/action/cooldown/spell/pointed/body_art/mountain_hurl/is_valid_target(atom/cast_on)
	return TRUE

/datum/action/cooldown/spell/pointed/body_art/mountain_hurl/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	if(!isliving(owner.pulling))
		owner.balloon_alert(owner, "grab someone first!")
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/pointed/body_art/mountain_hurl/cast(atom/cast_on)
	. = ..()
	var/mob/living/user = owner
	var/mob/living/victim = user.pulling
	if(!istype(victim))
		return
	var/stage = body_art_stage(user)
	body_art_shout(user, name)
	user.stop_pulling()
	user.do_attack_animation(victim, ATTACK_EFFECT_DISARM)
	user.visible_message(span_danger("[user] hoists [victim] overhead and hurls [victim.p_them()] like a boulder!"))
	playsound(user, 'sound/items/weapons/thudswoosh.ogg', 60, TRUE)
	log_combat(user, victim, "hurled (Mountain-Toppling Throw)")
	victim.throw_at(get_turf(cast_on), 7 + round(stage / 2), 3 + round(stage / 3), user, spin = TRUE, callback = CALLBACK(src, PROC_REF(land), user, victim, stage))

/datum/action/cooldown/spell/pointed/body_art/mountain_hurl/proc/land(mob/living/user, mob/living/victim, stage)
	if(QDELETED(victim))
		return
	var/turf/landing = get_turf(victim)
	var/radius = 1 + round(stage / 3)
	playsound(landing, 'sound/effects/meteorimpact.ogg', 70, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/earth(landing)
	new /obj/effect/temp_visual/cultivation_crater(landing, 1 + stage / 6)
	cultivation_distortion_wave(victim, radius + 2, 0.6 SECONDS, 200)
	body_art_crack_ground(landing, radius, 40 + 5 * stage, crater = FALSE)
	for(var/turf/nearby in range(1, landing))
		body_art_smash(nearby, user, 80 + 10 * stage, stage >= 8 ? body_art_wall_tier(stage) : 0)
	body_art_hit(user, victim, 15 + 2 * stage, 2 SECONDS, name)
	for(var/mob/living/bystander in range(radius, landing))
		if(bystander != victim && bystander != user)
			body_art_hit(user, bystander, 5 + stage, 1 SECONDS, name)
	for(var/mob/living/viewer in range(radius + 4, landing))
		shake_camera(viewer, 2 + round(stage / 3), 2)

// ===================== Sky-Splitting Palm =====================

/datum/action/cooldown/spell/pointed/body_art/sky_splitting_palm
	name = "Sky-Splitting Palm"
	desc = "Strike the air so hard it splits: a shockwave tears down a line (7 tiles plus your stage), hurling people back and shattering everything in its path. \
		It widens from Golden Body, rips through walls from Undying Flesh, and at the peak it cuts a five-wide canyon through the station."
	cast_range = 9
	cooldown_time = 35 SECONDS
	exhaustion_cost = 30
	aim_assist = FALSE

/datum/action/cooldown/spell/pointed/body_art/sky_splitting_palm/is_valid_target(atom/cast_on)
	return get_turf(cast_on) != get_turf(owner)

/datum/action/cooldown/spell/pointed/body_art/sky_splitting_palm/cast(atom/cast_on)
	. = ..()
	var/mob/living/user = owner
	var/stage = body_art_stage(user)
	var/direction = get_dir(user, cast_on)
	body_art_shout(user, name)
	user.do_attack_animation(get_step(user, direction), ATTACK_EFFECT_SMASH)
	playsound(user, 'sound/effects/magic/repulse.ogg', 80, TRUE, frequency = 0.6)
	cultivation_distortion_wave(user, 3, 0.4 SECONDS, 220)
	var/half_width = stage >= 9 ? 2 : (stage >= 7 ? 1 : 0)
	var/wall_tier = stage >= 8 ? body_art_wall_tier(stage) : 0
	var/length = 7 + stage
	// Without the strength to break walls, the wave stops at the first one
	if(!wall_tier)
		var/turf/probe = get_turf(user)
		for(var/i in 1 to length)
			probe = get_step(probe, direction)
			if(!probe || isclosedturf(probe))
				length = i - 1
				break
	body_art_shatter_line(user, get_turf(user), direction, length, half_width, 10 + 2 * stage, wall_tier, name, 0.6)

// ===================== Heaven-Shaking Quake =====================

/datum/action/cooldown/spell/body_art/heaven_quake
	name = "Heaven-Shaking Quake"
	desc = "Pound the ground and shake the whole area: every pulse knocks down everyone nearby, cracks the floor and rattles windows apart. \
		A Primordial Chaos Body's quake lasts longer, reaches further and brings walls crashing down all around."
	cooldown_time = 90 SECONDS
	exhaustion_cost = 40

/datum/action/cooldown/spell/body_art/heaven_quake/cast(mob/living/cast_on)
	. = ..()
	var/stage = body_art_stage(cast_on)
	var/pulses = stage >= 9 ? 5 : 3
	body_art_shout(cast_on, name)
	cast_on.visible_message(span_boldwarning("[cast_on] drops to one knee and drives both fists into the floor!"))
	ADD_TRAIT(cast_on, TRAIT_IMMOBILIZED, REF(src))
	for(var/pulse in 0 to pulses - 1)
		addtimer(CALLBACK(src, PROC_REF(quake_pulse), cast_on, stage), pulse * 1 SECONDS)
	addtimer(TRAIT_CALLBACK_REMOVE(cast_on, TRAIT_IMMOBILIZED, REF(src)), pulses * 1 SECONDS - 0.5 SECONDS)

/datum/action/cooldown/spell/body_art/heaven_quake/proc/quake_pulse(mob/living/user, stage)
	if(QDELETED(user) || user.stat == DEAD)
		return
	var/turf/center = get_turf(user)
	var/radius = 5 + round(stage / 2)
	playsound(center, 'sound/effects/meteorimpact.ogg', 80, TRUE)
	playsound(center, 'sound/effects/explosion/explosion_distant.ogg', 70, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/earth(center)
	cultivation_distortion_wave(user, radius + 1, 0.9 SECONDS, 255)
	body_art_crack_ground(center, radius, 10 + 3 * stage, crater = FALSE)
	for(var/turf/nearby in range(radius, center))
		if(prob(10))
			new /obj/effect/temp_visual/cultivation_rubble(nearby)
		for(var/obj/structure/window/window in nearby)
			window.take_damage(35 + 5 * stage, BRUTE, MELEE)
		// The peak: the station itself starts coming apart
		if(stage >= 9 && iswallturf(nearby) && prob(get_dist(nearby, center) <= 3 ? 35 : 12))
			body_art_smash(nearby, user, 0, 2)
	for(var/mob/living/viewer in range(radius + 4, center))
		shake_camera(viewer, 4 + round(stage / 2), 3)
	for(var/mob/living/victim in range(radius, center))
		if(victim != user)
			body_art_hit(user, victim, 4 + round(stage / 2), 1.5 SECONDS, name)
