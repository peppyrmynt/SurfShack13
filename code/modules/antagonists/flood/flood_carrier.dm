/obj/effect/temp_visual/flood_carrier_burst
	icon = 'icons/mob/flood/flood_carrier_old.dmi'
	icon_state = "burst"
	duration = 0.4 SECONDS

/mob/living/basic/flood/carrier
	name = "Flood Carrier"
	desc = "A bloated Flood unit packed with infectors."
	icon = 'icons/mob/flood/flood_carrier.dmi'
	icon_state = "static"
	icon_living = "static"
	speed = 1
	maxHealth = 100
	health = 100
	melee_damage_lower = 10
	melee_damage_upper = 18
	basic_mob_flags = DEL_ON_DEATH | FLAMMABLE_MOB
	icon_dead = "static"

	var/has_released_infection_forms = FALSE

/mob/living/basic/flood/carrier/get_flood_actions()
	. = ..()
	. += /datum/action/cooldown/flood/release_infection_forms

/mob/living/basic/flood/carrier/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. = ..()
	if(!. || stat == DEAD || client || has_released_infection_forms || !ai_controller)
		return
	var/mob/living/target = ai_controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(!istype(target) || QDELETED(target) || target.stat == DEAD || is_flood_target(target) || target.z != z)
		return
	// Burst as the AI approaches its target, before it has to make melee contact.
	if(get_dist(src, target) <= 3 && can_see(src, target, 3))
		release_infection_forms()

/mob/living/basic/flood/carrier/proc/release_swarm()
	if(has_released_infection_forms)
		return
	has_released_infection_forms = TRUE

	var/turf/spawn_turf = get_turf(src)
	if(!spawn_turf)
		return
	new /obj/effect/temp_visual/flood_carrier_burst(spawn_turf)
	playsound(spawn_turf, 'sound/effects/splat.ogg', 70, TRUE)
	do_chem_smoke(range = 0, holder = src, location = spawn_turf, reagent_type = /datum/reagent/blob/reactive_spines, reagent_volume = 3)

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

	var/swarm_size = rand(6, 12)
	var/released = 0
	if(mind)
		// Keep a controlled carrier's player in the swarm even when the AI population is capped.
		var/mob/living/basic/flood/infestor/player_infestor = new(spawn_turf)
		var/datum/mind/carrier_mind = mind
		carrier_mind.transfer_to(player_infestor)
		to_chat(player_infestor, span_notice("You emerge from the carrier as a Flood Infector. Alt-click a vent to crawl through it."))
		released++
	var/ai_forms_to_release = swarm_size - released
	for(var/i in 1 to ai_forms_to_release)
		if(!flood_try_spawn_ai(/mob/living/basic/flood/infestor, pick(spawn_turfs)))
			break
		released++
	visible_message(span_warning("[src] ruptures[released ? ", releasing [released] Flood Infectors!" : "!"]"))

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
