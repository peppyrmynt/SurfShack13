/**
 * Body Molding martial arts: the big, loud, earth-shattering moves. Every one of them is shouted, like in the novels.
 * Anyone of a higher realm braces against the knockdowns (taking half damage), and reinforced walls are always too much.
 */

// ===================== Shared helpers =====================

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

/// Smash windows, grilles, tables, girders and (with enough power) plain walls. Returns TRUE if anything gave way.
/proc/body_art_smash(turf/target, mob/living/user, power, break_walls = FALSE)
	if(!target)
		return FALSE
	. = FALSE
	if(iswallturf(target))
		if(break_walls && !istype(target, /turf/closed/wall/r_wall))
			var/turf/closed/wall/wall = target
			wall.dismantle_wall(devastated = TRUE)
			new /obj/effect/temp_visual/cultivation_rubble(target)
			return TRUE
		return FALSE
	for(var/obj/structure/thing in target)
		if(thing.resistance_flags & INDESTRUCTIBLE)
			continue
		if(istype(thing, /obj/structure/window) || istype(thing, /obj/structure/grille) || istype(thing, /obj/structure/table) || istype(thing, /obj/structure/girder))
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

/// Wuxia heroes announce their moves
/proc/body_art_shout(mob/living/user, technique_name)
	user.say("[uppertext(technique_name)]!!", forced = "body molding art")

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

/obj/effect/temp_visual/cultivation_crater/Initialize(mapload)
	. = ..()
	transform = matrix().Turn(pick(0, 90, 180, 270))
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
	desc = "Drive your heel into the floor. Everyone around you is knocked off their feet and the tiles crack. The radius grows with your stage."
	cooldown_time = 25 SECONDS
	stamina_cost = 20

/datum/action/cooldown/spell/body_art/earth_stomp/cast(mob/living/cast_on)
	. = ..()
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(cast_on)
	var/radius = 1 + round(body_datum.stage / 3)
	var/turf/center = get_turf(cast_on)
	body_art_shout(cast_on, name)
	cast_on.visible_message(span_danger("[cast_on] stamps down and the floor buckles!"))
	playsound(center, 'sound/effects/meteorimpact.ogg', 60, TRUE)
	cast_on.Shake(1, 1, 0.3 SECONDS)
	new /obj/effect/temp_visual/circle_wave/cultivation/earth(center)
	cultivation_distortion_wave(cast_on, radius + 1, 0.6 SECONDS, 180)
	body_art_crack_ground(center, radius, 35)
	for(var/mob/living/victim in range(radius, center))
		if(victim == cast_on)
			continue
		shake_camera(victim, 2, 2)
		body_art_hit(cast_on, victim, 5, 1.5 SECONDS, name)

// ===================== Hundred Fist Barrage =====================

/datum/action/cooldown/spell/pointed/body_art/hundred_fists
	name = "Hundred Fist Barrage"
	desc = "A blur of fists: eight blows in two seconds on someone beside you, the last one sending them flying."
	cast_range = 1
	cooldown_time = 20 SECONDS
	stamina_cost = 25

/datum/action/cooldown/spell/pointed/body_art/hundred_fists/is_valid_target(atom/cast_on)
	return ..() && isliving(cast_on)

/datum/action/cooldown/spell/pointed/body_art/hundred_fists/cast(mob/living/cast_on)
	. = ..()
	body_art_shout(owner, name)
	INVOKE_ASYNC(src, PROC_REF(barrage), owner, cast_on)

/datum/action/cooldown/spell/pointed/body_art/hundred_fists/proc/barrage(mob/living/user, mob/living/victim)
	var/arm_level = max(body_part_level(user, BODY_ZONE_L_ARM), body_part_level(user, BODY_ZONE_R_ARM))
	for(var/i in 1 to 8)
		if(QDELETED(user) || QDELETED(victim) || user.incapacitated || get_dist(user, victim) > 1)
			return
		user.do_attack_animation(victim, ATTACK_EFFECT_PUNCH)
		cultivation_afterimage(user, 0.25 SECONDS)
		playsound(victim, pick('sound/items/weapons/punch1.ogg', 'sound/items/weapons/punch2.ogg', 'sound/items/weapons/punch3.ogg', 'sound/items/weapons/punch4.ogg'), 40, TRUE)
		new /obj/effect/temp_visual/cultivation_spark(get_turf(victim), "#ffd27a", rand(-8, 8), rand(-4, 12))
		victim.apply_damage(2 + round(arm_level / 2), BRUTE, wound_bonus = CANT_WOUND)
		victim.Shake(1, 1, 0.1 SECONDS)
		sleep(0.25 SECONDS)
	if(QDELETED(victim) || get_dist(user, victim) > 1)
		return
	victim.visible_message(span_danger("[user]'s final blow launches [victim] across the room!"), span_userdanger("The last blow sends you flying!"))
	playsound(victim, 'sound/effects/meteorimpact.ogg', 40, TRUE)
	body_art_hit(user, victim, 6, 1.5 SECONDS, name)
	if(!HAS_TRAIT(victim, TRAIT_PUSHIMMUNE))
		victim.throw_at(get_edge_target_turf(victim, get_dir(user, victim)), 4, 2, user)

// ===================== Raging Bull Charge =====================

/datum/action/cooldown/spell/pointed/body_art/bull_charge
	name = "Raging Bull Charge"
	desc = "Charge in a straight line, bowling people aside and bursting through windows, grilles and tables. From Vajra Viscera you burst through plain walls too."
	cast_range = 8
	cooldown_time = 30 SECONDS
	stamina_cost = 30
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
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(user)
	var/steps = 4 + round(body_datum.stage / 2)
	var/break_walls = body_datum.stage >= 6
	user.pulledby?.stop_pulling()
	user.add_traits(list(TRAIT_IMMOBILIZED), REF(src))
	user.add_filter("bull_charge", 2, list("type" = "outline", "color" = "#e0a050", "size" = 1))
	for(var/i in 1 to steps)
		if(QDELETED(user) || user.stat != CONSCIOUS)
			break
		var/turf/next = get_step(user, direction)
		if(!next)
			break
		var/smashed = body_art_smash(next, user, 120, break_walls)
		if(smashed)
			playsound(next, 'sound/effects/rock/rock_break.ogg', 60, TRUE)
			new /obj/effect/temp_visual/cultivation_rubble(next)
		for(var/mob/living/victim in next)
			if(body_art_hit(user, victim, 10, 1.5 SECONDS, name) && !HAS_TRAIT(victim, TRAIT_PUSHIMMUNE))
				victim.throw_at(get_edge_target_turf(victim, pick(turn(direction, 90), turn(direction, -90))), 2, 2, user)
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
		sleep(0.1 SECONDS)
	if(!QDELETED(user))
		user.remove_traits(list(TRAIT_IMMOBILIZED), REF(src))
		user.remove_filter("bull_charge")

// ===================== Falling Mountain Descent =====================

/datum/action/cooldown/spell/pointed/body_art/falling_star
	name = "Falling Mountain Descent"
	desc = "Leap high into the air and come down on a spot you can see like a falling mountain. The landing craters the floor, \
		smashes everyone at the centre and knocks down everyone around it."
	cast_range = 7
	cooldown_time = 40 SECONDS
	stamina_cost = 30
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
	user.add_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), REF(src))
	var/turf/start = get_turf(user)
	new /obj/effect/temp_visual/cultivation_rubble(start)
	playsound(start, 'sound/effects/rock/rock_break.ogg', 50, TRUE, frequency = 1.3)
	animate(user, pixel_z = 128, alpha = 0, time = 0.6 SECONDS, easing = SINE_EASING | EASE_IN, flags = ANIMATION_RELATIVE | ANIMATION_PARALLEL)
	var/obj/effect/temp_visual/cultivation_landing_shadow/shadow = new(landing)
	sleep(0.8 SECONDS)
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
	user.visible_message(span_boldwarning("[user] crashes down like a falling mountain!"))
	playsound(landing, 'sound/effects/meteorimpact.ogg', 80, TRUE)
	playsound(landing, 'sound/effects/explosion/explosion_distant.ogg', 50, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/earth(landing)
	cultivation_distortion_wave(user, 5, 0.8 SECONDS, 230)
	body_art_crack_ground(landing, 2, 50)
	for(var/turf/nearby in range(1, landing))
		body_art_smash(nearby, user, 80)
	for(var/mob/living/viewer in range(7, landing))
		shake_camera(viewer, 3, 3)
	for(var/mob/living/victim in range(2, landing))
		if(victim == user)
			continue
		if(get_turf(victim) == landing || get_dist(victim, landing) <= 0)
			body_art_hit(user, victim, 15, 2 SECONDS, name)
		else
			body_art_hit(user, victim, 8, 1 SECONDS, name)

/// Where you're about to land
/obj/effect/temp_visual/cultivation_landing_shadow
	icon = 'icons/effects/effects.dmi'
	icon_state = "shadow_telegraph"
	duration = 1 SECONDS
	randomdir = FALSE
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/cultivation_landing_shadow/Initialize(mapload)
	. = ..()
	transform = matrix().Scale(0.3)
	animate(src, transform = matrix().Scale(1.4), time = 0.8 SECONDS)

// ===================== Mountain-Toppling Throw =====================

/datum/action/cooldown/spell/pointed/body_art/mountain_hurl
	name = "Mountain-Toppling Throw"
	desc = "Grab someone, then use this and click where to throw them: they fly up to seven tiles and crater the floor where they land, knocking down everyone nearby."
	cast_range = 7
	cooldown_time = 30 SECONDS
	stamina_cost = 25
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
	body_art_shout(user, name)
	user.stop_pulling()
	user.do_attack_animation(victim, ATTACK_EFFECT_DISARM)
	user.visible_message(span_danger("[user] hoists [victim] overhead and hurls [victim.p_them()] like a boulder!"))
	playsound(user, 'sound/items/weapons/thudswoosh.ogg', 60, TRUE)
	log_combat(user, victim, "hurled (Mountain-Toppling Throw)")
	victim.throw_at(get_turf(cast_on), 7, 3, user, spin = TRUE, callback = CALLBACK(src, PROC_REF(land), user, victim))

/datum/action/cooldown/spell/pointed/body_art/mountain_hurl/proc/land(mob/living/user, mob/living/victim)
	if(QDELETED(victim))
		return
	var/turf/landing = get_turf(victim)
	playsound(landing, 'sound/effects/meteorimpact.ogg', 60, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/earth(landing)
	body_art_crack_ground(landing, 1, 40)
	body_art_hit(user, victim, 15, 2 SECONDS, name)
	for(var/mob/living/bystander in range(1, landing))
		if(bystander != victim && bystander != user)
			body_art_hit(user, bystander, 5, 1 SECONDS, name)

// ===================== Sky-Splitting Palm =====================

/datum/action/cooldown/spell/pointed/body_art/sky_splitting_palm
	name = "Sky-Splitting Palm"
	desc = "Strike the air so hard it splits: a shockwave tears down a line seven tiles long, hurling people back and shattering windows and tables. Walls stop it."
	cast_range = 7
	cooldown_time = 35 SECONDS
	stamina_cost = 30
	aim_assist = FALSE

/datum/action/cooldown/spell/pointed/body_art/sky_splitting_palm/is_valid_target(atom/cast_on)
	return get_turf(cast_on) != get_turf(owner)

/datum/action/cooldown/spell/pointed/body_art/sky_splitting_palm/cast(atom/cast_on)
	. = ..()
	var/mob/living/user = owner
	var/direction = get_dir(user, cast_on)
	body_art_shout(user, name)
	user.do_attack_animation(get_step(user, direction), ATTACK_EFFECT_SMASH)
	playsound(user, 'sound/effects/magic/repulse.ogg', 70, TRUE, frequency = 0.6)
	cultivation_distortion_wave(user, 2, 0.4 SECONDS, 200)
	var/turf/current = get_turf(user)
	for(var/i in 1 to 7)
		current = get_step(current, direction)
		if(!current || iswallturf(current) || isclosedturf(current))
			break
		addtimer(CALLBACK(src, PROC_REF(wave_hits), user, current, direction), i * 0.6)

/datum/action/cooldown/spell/pointed/body_art/sky_splitting_palm/proc/wave_hits(mob/living/user, turf/where, direction)
	new /obj/effect/temp_visual/kinetic_blast(where)
	new /obj/effect/temp_visual/small_smoke/halfsecond(where)
	if(body_art_smash(where, user, 100))
		playsound(where, 'sound/effects/glass/glassbr3.ogg', 50, TRUE)
	for(var/mob/living/victim in where)
		if(victim == user)
			continue
		if(body_art_hit(user, victim, 10, 1 SECONDS, name) && !HAS_TRAIT(victim, TRAIT_PUSHIMMUNE))
			victim.throw_at(get_edge_target_turf(victim, direction), 3, 2, user)

// ===================== Heaven-Shaking Quake =====================

/datum/action/cooldown/spell/body_art/heaven_quake
	name = "Heaven-Shaking Quake"
	desc = "Pound the ground three times and shake the whole room: every pulse knocks down everyone within five tiles, cracks the floor and rattles windows apart."
	cooldown_time = 90 SECONDS
	stamina_cost = 40

/datum/action/cooldown/spell/body_art/heaven_quake/cast(mob/living/cast_on)
	. = ..()
	body_art_shout(cast_on, name)
	cast_on.visible_message(span_boldwarning("[cast_on] drops to one knee and drives both fists into the floor!"))
	ADD_TRAIT(cast_on, TRAIT_IMMOBILIZED, REF(src))
	for(var/pulse in 0 to 2)
		addtimer(CALLBACK(src, PROC_REF(quake_pulse), cast_on), pulse * 1 SECONDS)
	addtimer(TRAIT_CALLBACK_REMOVE(cast_on, TRAIT_IMMOBILIZED, REF(src)), 2.5 SECONDS)

/datum/action/cooldown/spell/body_art/heaven_quake/proc/quake_pulse(mob/living/user)
	if(QDELETED(user) || user.stat == DEAD)
		return
	var/turf/center = get_turf(user)
	playsound(center, 'sound/effects/meteorimpact.ogg', 70, TRUE)
	playsound(center, 'sound/effects/explosion/explosion_distant.ogg', 60, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/earth(center)
	cultivation_distortion_wave(user, 6, 0.9 SECONDS, 240)
	body_art_crack_ground(center, 5, 15, crater = FALSE)
	for(var/turf/open/nearby in range(5, center))
		if(prob(10))
			new /obj/effect/temp_visual/cultivation_rubble(nearby)
		for(var/obj/structure/window/window in nearby)
			window.take_damage(35, BRUTE, MELEE)
	for(var/mob/living/viewer in range(9, center))
		shake_camera(viewer, 4, 3)
	for(var/mob/living/victim in range(5, center))
		if(victim != user)
			body_art_hit(user, victim, 4, 1.5 SECONDS, name)
