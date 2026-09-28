/obj/effect/temp_visual/flood_carrier_burst
	icon = 'icons/mob/flood/flood_carrier_old.dmi'
	icon_state = "burst"
	duration = 0.4 SECONDS

/mob/living/basic/flood/carrier
	name = "Flood carrier form"
	desc = "A bloated Flood form packed with infection forms."
	icon = 'icons/mob/flood/flood_carrier.dmi'
	icon_state = "static"
	icon_living = "static"
	speed = 1
	maxHealth = 100
	health = 100
	melee_damage_lower = 10
	melee_damage_upper = 18
	basic_mob_flags = DEL_ON_DEATH
	icon_dead = "static"

	var/has_released_infection_forms = FALSE

/mob/living/basic/flood/carrier/get_flood_actions()
	. = ..()
	. += /datum/action/cooldown/flood/release_infection_forms

/mob/living/basic/flood/carrier/proc/release_swarm()
	if(has_released_infection_forms)
		return
	has_released_infection_forms = TRUE

	var/turf/spawn_turf = get_turf(src)
	if(!spawn_turf)
		return
	new /obj/effect/temp_visual/flood_carrier_burst(spawn_turf)
	playsound(spawn_turf, 'sound/effects/splat.ogg', 70, TRUE)

	var/list/spawn_turfs = list(spawn_turf)
	for(var/turf/open/candidate in range(2, src))
		if(candidate.density || isspaceturf(candidate))
			continue
		var/blocked = FALSE
		for(var/atom/movable/obstacle in candidate)
			if(obstacle.density)
				blocked = TRUE
				break
		if(!blocked)
			spawn_turfs += candidate

	for(var/i in 1 to rand(6, 12))
		new /mob/living/basic/flood/infestor(pick(spawn_turfs))
	visible_message(span_warning("[src] ruptures, releasing a swarm of Flood infection forms!"))

/mob/living/basic/flood/carrier/melee_attack(atom/attacked_target, list/modifiers, ignore_cooldown)
	if(!attacked_target || !Adjacent(attacked_target))
		return FALSE
	release_swarm()
	qdel(src)
	return TRUE

/mob/living/basic/flood/carrier/proc/release_infection_forms()
	if(stat == DEAD)
		return
	release_swarm()
	qdel(src)

/mob/living/basic/flood/carrier/death(gibbed)
	if(!has_released_infection_forms)
		release_swarm()
	return ..()
