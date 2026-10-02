/**
 * # Heart Demon
 *
 * Your doubts, given your face. It hunts only you. Beat it yourself (it has to die while you're standing next to it)
 * and your Dao heart is tempered: instability washes away and your next breakthrough is steadier.
 * Let it run out the clock and it climbs back inside you, much heavier than before.
 *
 * Heart demons tear free from failed breakthroughs, from badly unstable cultivators, and during Ascension.
 */

/// host mind -> their current heart demon
GLOBAL_LIST_EMPTY(cultivation_heart_demons)

/// Pull a heart demon out of someone, if they don't already have one loose
/proc/cultivation_summon_heart_demon(mob/living/host, lifetime = 90 SECONDS)
	if(QDELETED(host) || !host.mind)
		return null
	var/mob/living/basic/heart_demon/existing = GLOB.cultivation_heart_demons[host.mind]
	if(!QDELETED(existing))
		return existing
	var/turf/spawn_turf = get_turf(host)
	for(var/turf/open/nearby in orange(2, host))
		if(!nearby.is_blocked_turf(exclude_mobs = TRUE))
			spawn_turf = nearby
			break
	var/mob/living/basic/heart_demon/demon = new(spawn_turf)
	demon.bind_to(host, lifetime)
	return demon

/datum/ai_controller/basic_controller/heart_demon
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic,
	)
	ai_movement = /datum/ai_movement/basic_avoidance
	idle_behavior = null
	planning_subtrees = list(
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

/mob/living/basic/heart_demon
	name = "heart demon"
	desc = "Your own face, twisted by every doubt you ever had."
	icon = 'icons/mob/simple/simple_human.dmi'
	icon_state = ""
	mob_biotypes = MOB_SPIRIT|MOB_HUMANOID
	maxHealth = 80
	health = 80
	speed = 0.8
	melee_damage_lower = 8
	melee_damage_upper = 12
	attack_verb_continuous = "rakes"
	attack_verb_simple = "rake"
	attack_sound = 'sound/effects/magic/demon_attack1.ogg'
	attack_vis_effect = ATTACK_EFFECT_CLAW
	unsuitable_atmos_damage = 0
	unsuitable_cold_damage = 0
	unsuitable_heat_damage = 0
	basic_mob_flags = DEL_ON_DEATH
	death_message = "shatters like a broken mirror!"
	ai_controller = /datum/ai_controller/basic_controller/heart_demon
	/// The mind that spawned us
	var/datum/mind/host_mind
	/// Has the fight been decided
	var/resolved = FALSE
	/// Dark aura hanging around us
	var/obj/effect/abstract/cultivation_vis/aura
	var/obj/effect/abstract/particle_holder/motes
	COOLDOWN_DECLARE(taunt_cooldown)

/mob/living/basic/heart_demon/Destroy()
	if(host_mind && GLOB.cultivation_heart_demons[host_mind] == src)
		GLOB.cultivation_heart_demons -= host_mind
	host_mind = null
	cultivation_detach_vis(src, aura)
	aura = null
	QDEL_NULL(motes)
	return ..()

/mob/living/basic/heart_demon/proc/bind_to(mob/living/host, lifetime)
	host_mind = host.mind
	GLOB.cultivation_heart_demons[host_mind] = src
	appearance = host.appearance
	name = "heart demon of [host.real_name]"
	desc = initial(desc)
	transform = matrix()
	layer = MOB_LAYER
	SET_PLANE_IMPLICIT(src, GAME_PLANE)
	color = "#b585ff"
	alpha = 0
	animate(src, alpha = 215, time = 1 SECONDS)
	faction = list("heart_demon_[REF(host_mind)]")
	var/realm = cultivation_realm_of(host)
	maxHealth = 60 + 25 * realm
	health = maxHealth
	melee_damage_lower = 6 + 2 * realm
	melee_damage_upper = 10 + 2 * realm
	add_filter("heart_demon", 2, list("type" = "outline", "color" = "#2a0a3a", "size" = 1))
	aura = cultivation_attach_vis(src, 'surfshack13/icons/cultivation/cultivation_effects_64.dmi', "heart_demon_aura", null, 64, 0, 200)
	aura.layer = BELOW_MOB_LAYER
	motes = cultivation_particles(src, /particles/cultivation/void)
	ai_controller?.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, host)
	playsound(src, 'sound/effects/magic/demon_dies.ogg', 50, TRUE, frequency = 1.3)
	new /obj/effect/temp_visual/circle_wave/cultivation/blood(get_turf(src))
	host.visible_message(span_danger("A dark copy of [host] peels away from [host.p_them()], grinning!"), span_userdanger("Your heart demon tears itself free! Defeat it yourself, before it climbs back in!"))
	addtimer(CALLBACK(src, PROC_REF(merge_back)), lifetime)

/mob/living/basic/heart_demon/proc/get_host()
	var/mob/living/host = host_mind?.current
	return QDELETED(host) ? null : host

/mob/living/basic/heart_demon/Life(seconds_per_tick, times_fired)
	. = ..()
	if(stat == DEAD || resolved)
		return
	var/mob/living/host = get_host()
	if(!host || host.stat == DEAD || host.z != z)
		fade_away()
		return
	// It only ever wants you
	if(ai_controller && ai_controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET] != host)
		ai_controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, host)
	if(COOLDOWN_FINISHED(src, taunt_cooldown))
		COOLDOWN_START(src, taunt_cooldown, 12 SECONDS)
		to_chat(host, span_warning("<i>Your heart demon whispers: \"[pick(taunts())]\"</i>"))

/mob/living/basic/heart_demon/proc/taunts()
	return list(
		"You'll never reach the next realm. You know it.",
		"Every junior on this station is laughing at you.",
		"Why fight me? I'm the only one who understands you.",
		"Your master never believed in you.",
		"All that meditation, and you're still this weak?",
		"Heaven made you a mortal for a reason.",
	)

/// Anyone can kill it, but only facing it yourself counts
/mob/living/basic/heart_demon/death(gibbed)
	if(!resolved)
		resolved = TRUE
		var/mob/living/host = get_host()
		if(host && host.stat == CONSCIOUS && get_dist(host, src) <= 3)
			INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(cultivation_heart_demon_vanquished), host)
		else if(host)
			to_chat(host, span_warning("Your heart demon dissolves... but you weren't the one who faced it. The doubt lingers."))
	return ..()

/// Time's up: it wins, and climbs back inside
/mob/living/basic/heart_demon/proc/merge_back()
	if(QDELETED(src) || stat == DEAD || resolved)
		return
	resolved = TRUE
	var/mob/living/host = get_host()
	if(host)
		host.visible_message(span_danger("[src] lunges into [host] and vanishes inside [host.p_them()]!"), span_userdanger("Your heart demon sinks back into you, heavier than ever!"))
		var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(host)
		cultivator?.adjust_instability(25)
		host.add_mood_event("heart_demon", /datum/mood_event/heart_demon_lost)
		playsound(host, 'sound/effects/magic/curse.ogg', 50, TRUE)
	qdel(src)

/mob/living/basic/heart_demon/proc/fade_away()
	resolved = TRUE
	visible_message(span_notice("[src] fades like smoke."))
	qdel(src)

/proc/cultivation_heart_demon_vanquished(mob/living/host)
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(host)
	host.visible_message(span_boldnotice("[host] stands over the shattered remains of [host.p_their()] heart demon, eyes clear."), span_boldnotice("You have faced your heart demon and won. Your Dao heart is tempered!"))
	cultivation_temple_sound(host, 60)
	cultivation_guqin_phrase(host, list(1, 3, 5, 6))
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(get_turf(host))
	host.add_mood_event("heart_demon", /datum/mood_event/heart_demon_won)
	host.apply_status_effect(/datum/status_effect/dao_heart_tempered)
	jianghu_mission_progress(host.mind, SECT_MISSION_HEART_DEMON, 1)
	if(cultivator)
		cultivator.adjust_instability(-50)
		cultivator.gain_insight(25, INSIGHT_SOURCE_HEART_DEMON, cooldown = 0)

/// Won against your heart demon: your next breakthrough is steadier
/datum/status_effect/dao_heart_tempered
	id = "dao_heart_tempered"
	alert_type = null
	duration = 20 MINUTES
	status_type = STATUS_EFFECT_REFRESH

/datum/mood_event/heart_demon_won
	description = "I faced my heart demon and won. My mind is clear."
	mood_change = 6
	timeout = 15 MINUTES

/datum/mood_event/heart_demon_lost
	description = "My heart demon got back in. Everything feels heavier."
	mood_change = -5
	timeout = 10 MINUTES
