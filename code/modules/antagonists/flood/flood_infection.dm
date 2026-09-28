/mob/living/basic/flood/infestor
	name = "Flood infection form"
	desc = "A small Flood organism seeking a host."
	icon = 'icons/mob/flood/flood_infection.dmi'
	icon_state = "static"
	icon_living = "static"
	icon_dead = "dead"
	mob_biotypes = MOB_ORGANIC
	sentience_type = SENTIENCE_HUMANOID
	faction = list("Flood")
	combat_mode = TRUE
	maxHealth = 5
	ai_controller = /datum/ai_controller/basic_controller/simple_hostile_obstacles/flood/infestor
	health = 5
	speed = -0.5
	melee_damage_lower = 1
	melee_damage_upper = 5
	pass_flags = PASSMOB
	basic_mob_flags = DEL_ON_DEATH
	mob_size = MOB_SIZE_TINY
	attack_verb_continuous = "leaps at"
	attack_verb_simple = "leap at"
	attack_sound = 'sound/flood/leap.leap1.ogg'
	var/next_reanimate_check = 0
	var/mob/living/carbon/human/latched_host
	var/swarm_size = 1
	var/max_swarm_size = 6
	var/next_swarm_merge = 0

/mob/living/basic/flood/infestor/Initialize(mapload)
	. = ..()
	pixel_x = rand(-8, 8)
	pixel_y = rand(0, 24)
	// Newly released infection forms spread out before they coalesce into swarms.
	next_swarm_merge = world.time + 3 SECONDS

/// Infection forms leave small, cleanable remains, as in the original infestation.
/obj/effect/decal/cleanable/flood_infestor
	name = "dead Flood infection form"
	desc = "The husk of a tiny Flood parasite."
	icon = 'icons/mob/flood/flood_infection.dmi'
	icon_state = "dead"

/obj/effect/decal/cleanable/flood_infestor/Initialize(mapload)
	. = ..()
	pixel_x = rand(-8, 8)
	pixel_y = rand(0, 24)

/mob/living/basic/flood/infestor/death(gibbed)
	if(!gibbed)
		drop_infestor_remains(swarm_size)
	return ..()

/mob/living/basic/flood/infestor/proc/drop_infestor_remains(amount)
	var/turf/death_turf = get_turf(src)
	if(!death_turf)
		return
	var/remains = 0
	for(var/obj/effect/decal/cleanable/flood_infestor/existing in death_turf)
		remains++
	if(remains >= 8)
		return
	for(var/i in 1 to min(amount, 8 - remains))
		new /obj/effect/decal/cleanable/flood_infestor(death_turf)

/mob/living/basic/flood/infestor/adjust_health(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(amount <= 0 || !updating_health || stat == DEAD || swarm_size <= 1)
		return
	var/remaining_forms = max(1, CEILING(health / initial(maxHealth), 1))
	if(remaining_forms >= swarm_size)
		return
	var/lost_forms = swarm_size - remaining_forms
	swarm_size = remaining_forms
	var/current_health = health
	maxHealth -= lost_forms * initial(maxHealth)
	bruteloss = max(0, maxHealth - current_health)
	updatehealth()
	melee_damage_upper = initial(melee_damage_upper) + swarm_size - 1
	drop_infestor_remains(lost_forms)
	update_appearance(UPDATE_OVERLAYS)

/mob/living/basic/flood/infestor/Destroy()
	if(latched_host)
		UnregisterSignal(latched_host, COMSIG_LIVING_RESIST)
	latched_host = null
	return ..()

/mob/living/basic/flood/infestor/examine(mob/user)
	. = ..()
	if(swarm_size > 1)
		. += span_warning("[swarm_size] infection forms are moving together in this swarm.")

/mob/living/basic/flood/infestor/update_overlays()
	. = ..()
	if(stat == DEAD)
		return
	for(var/i in 2 to min(swarm_size, 4))
		var/image/extra_form = image(icon = icon, icon_state = "static")
		extra_form.pixel_x = (i % 2) ? -8 : 8
		extra_form.pixel_y = (i > 3) ? 6 : -6
		. += extra_form

/mob/living/basic/flood/infestor/proc/merge_nearby_infestors()
	if(client || mind || latched_host || swarm_size >= max_swarm_size || world.time < next_swarm_merge)
		return
	for(var/mob/living/basic/flood/infestor/other in range(1, src))
		if(other == src || other.stat == DEAD || other.client || other.mind || other.latched_host || world.time < other.next_swarm_merge || swarm_size + other.swarm_size > max_swarm_size)
			continue
		var/added_forms = other.swarm_size
		var/combined_health = health + other.health
		maxHealth += other.maxHealth
		bruteloss = max(0, maxHealth - combined_health)
		updatehealth()
		melee_damage_upper += added_forms
		swarm_size += added_forms
		name = "Flood infection form swarm"
		qdel(other)
		update_appearance(UPDATE_OVERLAYS)
		return

/mob/living/basic/flood/infestor/melee_attack(atom/attacked_target, list/modifiers, ignore_cooldown)
	if(stat == DEAD || latched_host || !ishuman(attacked_target))
		return FALSE
	var/mob/living/carbon/human/host = attacked_target
	if(is_flood_target(host) || !Adjacent(host))
		return FALSE
	if(host.stat == CONSCIOUS && host.getBruteLoss() + host.getFireLoss() <= host.maxHealth * 0.25)
		return FALSE
	for(var/mob/living/basic/flood/infestor/other in range(1, host))
		if(other != src && other.latched_host == host)
			return FALSE
	if(host.stat != DEAD && !..())
		return FALSE
	latched_host = host
	forceMove(get_turf(host))
	anchored = TRUE
	RegisterSignal(host, COMSIG_LIVING_RESIST, PROC_REF(on_host_resist))
	host.visible_message(span_danger("[src] latches onto [host]!"), span_userdanger("[src] latches onto you! Resist or move away to break its grip!"))
	INVOKE_ASYNC(src, PROC_REF(finish_latch), host)
	return TRUE

/mob/living/basic/flood/infestor/proc/latch_still_valid(mob/living/carbon/human/host)
	if(stat == DEAD || QDELETED(host) || latched_host != host || is_flood_target(host) || !Adjacent(host))
		return FALSE
	if(host.stat == CONSCIOUS && host.getBruteLoss() + host.getFireLoss() <= host.maxHealth * 0.25)
		return FALSE
	return TRUE

/mob/living/basic/flood/infestor/proc/clear_latch()
	if(latched_host)
		UnregisterSignal(latched_host, COMSIG_LIVING_RESIST)
	latched_host = null
	anchored = FALSE

/mob/living/basic/flood/infestor/proc/on_host_resist(mob/living/carbon/human/host)
	SIGNAL_HANDLER
	if(latched_host != host)
		return
	host.visible_message(span_notice("[host] shakes [src] loose!"), span_notice("You shake [src] loose!"))
	clear_latch()

/// The source's infection sensations now describe an active latch rather than
/// a chemical infection. They never convert a host by themselves.
/mob/living/basic/flood/infestor/proc/latch_warning(mob/living/carbon/human/host, stage)
	if(QDELETED(host) || host.stat == DEAD || !latch_still_valid(host))
		return
	if(stage == 1)
		to_chat(host, span_warning(pick(
			"Your skin becomes cold to the touch...",
			"A spasm runs through your body...",
			"Something wriggles underneath your skin...",
		)))
	else
		to_chat(host, span_userdanger(pick(
			"A chorus of voices speaks in riddles...",
			"You feel something digging into your spinal column...",
			"You feel your mind slipping...",
		)))

/mob/living/basic/flood/infestor/proc/finish_latch(mob/living/carbon/human/host)
	if(QDELETED(host))
		if(latched_host == host)
			clear_latch()
		return
	var/latch_time = host.stat == DEAD ? 6 SECONDS : 10 SECONDS
	if(host.stat != DEAD)
		addtimer(CALLBACK(src, PROC_REF(latch_warning), host, 1), 3 SECONDS)
		addtimer(CALLBACK(src, PROC_REF(latch_warning), host, 2), 7 SECONDS)
	if(!do_after(src, latch_time, host, extra_checks = CALLBACK(src, PROC_REF(latch_still_valid), host)) || !latch_still_valid(host))
		if(latched_host == host)
			clear_latch()
		return
	clear_latch()
	if(convert_human(host, "[src] burrows into [host], converting them into a Flood combat form!"))
		qdel(src)

/mob/living/basic/flood/infestor/proc/reanimate_nearby_flood(show_failure = FALSE)
	if(latched_host)
		return FALSE
	var/mob/living/basic/flood/combat_form/corpse
	for(var/mob/living/basic/flood/combat_form/candidate in range(2, src))
		if(candidate.stat != DEAD || candidate.reanimated)
			continue
		corpse = candidate
		break

	if(!corpse)
		if(show_failure)
			to_chat(src, span_warning("There is no viable Flood corpse nearby."))
		return FALSE

	var/mob/living/basic/flood/new_form = new corpse.type(corpse.loc)
	new_form.name = corpse.name
	var/mob/living/basic/flood/combat_form/reanimated_form = new_form
	reanimated_form.icon = corpse.icon
	reanimated_form.icon_living = corpse.icon_living
	reanimated_form.icon_dead = corpse.icon_dead
	reanimated_form.icon_state = corpse.icon_living
	reanimated_form.reanimated = TRUE
	if(corpse.mind)
		var/datum/mind/corpse_mind = corpse.mind
		corpse_mind.transfer_to(new_form)
		if(!corpse_mind.has_antag_datum(/datum/antagonist/flood))
			corpse_mind.add_antag_datum(/datum/antagonist/flood)
		corpse_mind.special_role = ROLE_FLOOD

	visible_message(span_danger("[src] burrows into [corpse], and the corpse lurches back to life!"))
	qdel(corpse)
	qdel(src)
	return TRUE

/mob/living/basic/flood/infestor/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. = ..()
	if(!. || stat == DEAD || client || latched_host || world.time < next_reanimate_check)
		return
	next_reanimate_check = world.time + 2 SECONDS
	merge_nearby_infestors()
	reanimate_nearby_flood()

/mob/living/basic/flood/infestor/verb/reanimate_flood()
	set name = "Reanimate Flood Corpse"
	set category = "Flood"

	if(stat == DEAD)
		return
	reanimate_nearby_flood(TRUE)
