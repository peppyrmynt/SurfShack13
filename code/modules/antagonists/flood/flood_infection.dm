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
	melee_damage_lower = 10
	melee_damage_upper = 10
	pass_flags = PASSMOB
	basic_mob_flags = DEL_ON_DEATH
	// Only a forced unbuckle (resist, death, or cleanup) can remove a latched form.
	can_buckle_to = FALSE
	mob_size = MOB_SIZE_TINY
	attack_verb_continuous = "leaps at"
	attack_verb_simple = "leap at"
	attack_sound = 'sound/flood/leap.leap1.ogg'
	var/next_reanimate_check = 0
	var/mob/living/carbon/human/latched_host
	var/latch_generation = 0
	var/swarm_size = 1
	var/max_swarm_size = 6
	var/next_swarm_merge = 0

/mob/living/basic/flood/infestor/Initialize(mapload)
	. = ..()
	pixel_x = rand(-8, 8)
	pixel_y = rand(0, 24)
	// Newly released infection forms spread out before they coalesce into swarms.
	next_swarm_merge = world.time + 3 SECONDS

/mob/living/basic/flood/infestor/get_flood_actions()
	. = ..()
	. += /datum/action/cooldown/flood/reanimate

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
	clear_latch()
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
	drop_infestor_remains(lost_forms)
	update_appearance(UPDATE_OVERLAYS)

/mob/living/basic/flood/infestor/Destroy()
	clear_latch()
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
		swarm_size += added_forms
		name = "Flood infection form swarm"
		qdel(other)
		update_appearance(UPDATE_OVERLAYS)
		return

/mob/living/basic/flood/infestor/melee_attack(atom/attacked_target, list/modifiers, ignore_cooldown)
	if(stat == DEAD || buckled || latched_host || !ishuman(attacked_target))
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
	if(stat == DEAD || QDELETED(host) || !Adjacent(host))
		return FALSE
	// An existing rider must not make its host immune to infection.
	for(var/mob/living/rider as anything in host.buckled_mobs)
		if(istype(rider, /mob/living/basic/flood/infestor))
			return FALSE
		host.unbuckle_mob(rider, force = TRUE)
	forceMove(get_turf(host))
	if(!host.buckle_mob(src, force = TRUE))
		return FALSE
	latched_host = host
	latch_generation++
	RegisterSignal(host, COMSIG_LIVING_RESIST, PROC_REF(on_host_resist))
	RegisterSignal(host, COMSIG_LIVING_DEATH, PROC_REF(on_host_death))
	RegisterSignal(host, COMSIG_LIVING_REVIVE, PROC_REF(on_host_revive))
	RegisterSignal(host, COMSIG_QDELETING, PROC_REF(on_host_deleted))
	RegisterSignal(src, COMSIG_MOB_UNBUCKLED, PROC_REF(on_unbuckled))
	host.visible_message(span_danger("[src] latches onto [host]!"), span_userdanger("[src] latches onto you! Resist or kill it to break its grip!"))
	if(host.stat == DEAD)
		begin_corpse_infection(host)
	else
		addtimer(CALLBACK(src, PROC_REF(latch_hit), host, latch_generation), 2 SECONDS)
	return TRUE

/mob/living/basic/flood/infestor/proc/latch_still_valid(mob/living/carbon/human/host)
	return stat != DEAD && !QDELETED(host) && latched_host == host && buckled == host && !is_flood_target(host)

/mob/living/basic/flood/infestor/proc/convert_human(mob/living/carbon/human/victim, infection_message)
	if(!latch_still_valid(victim) || victim.stat != DEAD)
		return FALSE

	var/turf/conversion_turf = get_turf(victim)
	if(!conversion_turf)
		return FALSE

	var/mob/living/basic/flood/combat_form/human/new_form = new(conversion_turf)
	new_form.name = victim.real_name
	if(locate(/obj/item/clothing/under/color/orange) in victim)
		new_form.icon_state = "prisoner_infected2"
		new_form.icon_living = "prisoner_infected2"
		new_form.icon_dead = "prisoner_infected2_dead"
	SEND_SOUND(victim, sound('sound/flood/flood_infect_gravemind.ogg', volume = 60))

	if(victim.mind)
		// The source gives player-infected forms more staying power than NPC forms.
		new_form.maxHealth = round(new_form.maxHealth * 1.5)
		new_form.health = new_form.maxHealth
		var/datum/mind/victim_mind = victim.mind
		victim_mind.transfer_to(new_form)
		if(!victim_mind.has_antag_datum(/datum/antagonist/flood))
			victim_mind.add_antag_datum(/datum/antagonist/flood)
		victim_mind.special_role = ROLE_FLOOD

	// Leave their station equipment on the floor instead of deleting it with the old body.
	for(var/obj/item/equipped_item in victim.get_equipped_items(INCLUDE_POCKETS | INCLUDE_HELD | INCLUDE_ACCESSORIES))
		victim.dropItemToGround(equipped_item, TRUE)

	GLOB.flood_infections++
	if(infection_message)
		visible_message(span_danger(infection_message))
	new /obj/effect/decal/cleanable/blood/splatter(conversion_turf)
	if(prob(50))
		playsound(conversion_turf, 'sound/flood/flood_join_chorus.ogg', 70, TRUE)
	qdel(victim)
	return TRUE

/mob/living/basic/flood/infestor/proc/clear_latch()
	var/mob/living/carbon/human/old_host = latched_host
	latched_host = null
	latch_generation++
	if(old_host)
		UnregisterSignal(old_host, list(COMSIG_LIVING_RESIST, COMSIG_LIVING_DEATH, COMSIG_LIVING_REVIVE, COMSIG_QDELETING))
	UnregisterSignal(src, COMSIG_MOB_UNBUCKLED)
	if(old_host && buckled == old_host)
		old_host.unbuckle_mob(src, force = TRUE)

/mob/living/basic/flood/infestor/proc/on_unbuckled(mob/living/source, atom/movable/old_buckle)
	SIGNAL_HANDLER
	if(old_buckle == latched_host)
		clear_latch()

/mob/living/basic/flood/infestor/proc/on_host_resist(mob/living/carbon/human/host)
	SIGNAL_HANDLER
	if(latched_host != host)
		return
	host.visible_message(span_notice("[host] shakes [src] loose!"), span_notice("You shake [src] loose!"))
	clear_latch()

/mob/living/basic/flood/infestor/proc/on_host_death(mob/living/carbon/human/host, gibbed)
	SIGNAL_HANDLER
	if(host != latched_host)
		return
	if(gibbed)
		clear_latch()
		return
	begin_corpse_infection(host)

/mob/living/basic/flood/infestor/proc/on_host_revive(mob/living/carbon/human/host)
	SIGNAL_HANDLER
	if(host != latched_host || host.stat == DEAD)
		return
	// Invalidate the old corpse timer before resuming damage.
	latch_generation++
	addtimer(CALLBACK(src, PROC_REF(latch_hit), host, latch_generation), 2 SECONDS)

/mob/living/basic/flood/infestor/proc/on_host_deleted(mob/living/carbon/human/host)
	SIGNAL_HANDLER
	if(host == latched_host)
		clear_latch()

/mob/living/basic/flood/infestor/proc/latch_hit(mob/living/carbon/human/host, expected_generation)
	if(expected_generation != latch_generation)
		return
	if(!latch_still_valid(host))
		clear_latch()
		return
	if(host.stat == DEAD)
		begin_corpse_infection(host)
		return
	host.visible_message(span_danger("[src] tears into [host]!"), span_userdanger("[src] tears into you!"))
	host.apply_damage(10, BRUTE, BODY_ZONE_CHEST)
	if(expected_generation == latch_generation && latch_still_valid(host))
		if(host.stat == DEAD)
			begin_corpse_infection(host)
		else
			addtimer(CALLBACK(src, PROC_REF(latch_hit), host, expected_generation), 2 SECONDS)

/mob/living/basic/flood/infestor/proc/begin_corpse_infection(mob/living/carbon/human/host)
	if(!latch_still_valid(host) || host.stat != DEAD)
		return
	// A new generation prevents an earlier damage hit or corpse timer from firing.
	latch_generation++
	addtimer(CALLBACK(src, PROC_REF(finish_latch), host, latch_generation), 5 SECONDS)

/mob/living/basic/flood/infestor/proc/finish_latch(mob/living/carbon/human/host, expected_generation)
	if(expected_generation != latch_generation)
		return
	if(!latch_still_valid(host))
		clear_latch()
		return
	if(host.stat != DEAD)
		// A revived host cannot be infected; resume damage while attached.
		latch_generation++
		addtimer(CALLBACK(src, PROC_REF(latch_hit), host, latch_generation), 2 SECONDS)
		return
	var/infected = convert_human(host, "[src] burrows into [host], converting them into a Flood combat form!")
	clear_latch()
	if(infected)
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
