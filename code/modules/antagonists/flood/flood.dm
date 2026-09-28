/// SurfShack Flood antagonist
///
/// Adapted from HaloSpaceStation13's Flood gameplay to SurfShack's current
/// antagonist, simple-animal, and dynamic-ruleset architecture.

GLOBAL_VAR_INIT(flood_infections, 0)

#define IS_FLOOD(target_mob) (target_mob?.mind?.has_antag_datum(/datum/antagonist/flood) || istype(target_mob, /mob/living/basic/flood))
#define FLOOD_INFESTOR_COOLDOWN (30 SECONDS)
#define FLOOD_EVOLUTION_COOLDOWN (60 SECONDS)

/// Spoken Flood language is local; the chorus verb below reaches every active Flood player.
/datum/language/flood
	name = "Floodmind"
	desc = "The low, unsettling speech shared by Flood forms."
	key = "f"
	flags = TONGUELESS_SPEECH | NO_STUTTER
	default_priority = -1
	icon_state = "narsie"
	syllables = list("gra", "vrak", "krr", "shaa", "thrum", "rukh", "hss", "vorr")

/datum/language_holder/flood
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/flood = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/flood = list(LANGUAGE_ATOM),
	)

/datum/team/flood
	name = "\improper Flood"

/datum/team/flood/roundend_report()
	var/list/parts = list()
	parts += span_header("The [name] were:")
	parts += printplayerlist(members)
	parts += span_notice("Total infected hosts: [GLOB.flood_infections]")
	return "<div class='panel redborder'>[parts.Join("<br>")]</div>"

/datum/antagonist/flood
	name = "\improper Flood"
	roundend_category = "flood"
	antagpanel_category = "Flood"
	job_rank = ROLE_FLOOD
	show_to_ghosts = TRUE
	show_in_antagpanel = TRUE
	can_assign_self_objectives = TRUE
	default_custom_objective = "Spread the Flood and establish a viable infestation."
	var/datum/team/flood/flood_team

/datum/antagonist/flood/on_gain()
	forge_objectives()
	return ..()

/datum/antagonist/flood/greet()
	to_chat(owner.current, span_danger("You are part of the Flood."))
	to_chat(owner.current, span_notice("Weaken human hosts so infection forms can latch on and convert them."))
	to_chat(owner.current, span_notice("Combat forms can create infection forms, tear apart welded airlocks, and evolve into specialized Flood forms."))
	to_chat(owner.current, span_notice("Human combat forms can use ordinary station equipment and guns."))
	to_chat(owner.current, span_notice("Infection forms must remain latched onto vulnerable or dead humans to convert them. Living hosts can resist or escape."))
	to_chat(owner.current, span_notice("Use Flood Chorus to speak to every active Flood player, or :f to speak Floodmind nearby."))

/datum/antagonist/flood/create_team(datum/team/flood/new_team)
	if(!new_team)
		for(var/datum/antagonist/flood/other_flood in GLOB.antagonists)
			if(other_flood.owner && other_flood.flood_team)
				flood_team = other_flood.flood_team
				return
		flood_team = new
	else
		if(!istype(new_team))
			CRASH("Wrong Flood team type provided to create_team")
		flood_team = new_team

/datum/antagonist/flood/get_team()
	return flood_team

/datum/antagonist/flood/forge_objectives()
	var/datum/objective/flood_spread/objective = new
	objective.owner = owner
	objectives += objective

/datum/objective/flood_spread
	explanation_text = "Spread the Flood by creating infected hosts."

/datum/objective/flood_spread/check_completion()
	return GLOB.flood_infections >= 5

/datum/antagonist/flood/roundend_report()
	if(!owner?.current)
		return
	var/list/report = list()
	report += span_header("The Flood:")
	report += printplayer(owner)
	report += span_notice("Hosts infected by the Flood: [GLOB.flood_infections]")
	return "<div class='panel redborder'>[report.Join("<br>")]</div>"

/mob/living/basic/flood
	name = "Flood combat form"
	desc = "A biomass-driven combat form belonging to a parasitic hive mind."
	icon = 'icons/mob/flood/flood_combat_human.dmi'
	icon_state = "marine_infested"
	icon_living = "marine_infested"
	mob_biotypes = MOB_ORGANIC | MOB_HUMANOID
	sentience_type = SENTIENCE_HUMANOID
	initial_language_holder = /datum/language_holder/flood
	faction = list("Flood")
	combat_mode = TRUE
	habitable_atmos = null
	unsuitable_atmos_damage = 0
	minimum_survivable_temperature = 0
	maximum_survivable_temperature = INFINITY
	maxHealth = 125
	health = 125
	melee_damage_lower = 20
	melee_damage_upper = 30
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	attack_sound = 'sound/flood/melee.melee1.ogg'
	attacked_sound = 'sound/flood/pain.pain1.ogg'
	icon_dead = "marine_dead"
	death_message = "collapses into a twitching mass of biomass."
	obj_damage = 60
	damage_coeff = list(BRUTE = 1, BURN = 1.5, TOX = 1, STAMINA = 0, OXY = 1)
	ai_controller = /datum/ai_controller/basic_controller/simple_hostile_obstacles/flood
	var/next_evolution = 0
	var/next_idle_sound = 0

/mob/living/basic/flood/Initialize(mapload)
	. = ..()
	attacked_sound = pick(
		'sound/flood/pain.pain1.ogg',
		'sound/flood/pain.pain2.ogg',
		'sound/flood/pain.pain5.ogg',
	)
	next_idle_sound = world.time + rand(300, 600)

/mob/living/basic/flood/melee_attack(atom/target, list/modifiers, ignore_cooldown)
	if(!istype(src, /mob/living/basic/flood/infestor))
		attack_sound = pick(
			'sound/flood/melee.melee1.ogg',
			'sound/flood/melee.melee2.ogg',
			'sound/flood/melee.melee5.ogg',
			'sound/flood/melee.melee7.ogg',
		)
	return ..()

/mob/living/basic/flood/verb/flood_chorus()
	set name = "Flood Chorus"
	set category = "Flood"

	if(stat == DEAD || !mind?.has_antag_datum(/datum/antagonist/flood))
		return
	var/message = tgui_input_text(src, "Speak to the Flood chorus.", "Flood Chorus", max_length = MAX_MESSAGE_LEN)
	if(!message || stat == DEAD || !mind?.has_antag_datum(/datum/antagonist/flood))
		return
	if(client?.prefs.muted & MUTE_IC)
		to_chat(src, span_warning("You cannot send IC messages while muted."))
		return
	if(client?.handle_spam_prevention(message, MUTE_IC))
		return
	var/list/filter_result = CAN_BYPASS_FILTER(src) ? null : is_ic_filtered(message)
	if(filter_result)
		REPORT_CHAT_FILTER_TO_USER(src, filter_result)
		return
	var/list/soft_filter_result = CAN_BYPASS_FILTER(src) ? null : is_soft_ic_filtered(message)
	if(soft_filter_result)
		if(tgui_alert(src, "Your message contains \"[soft_filter_result[CHAT_FILTER_INDEX_WORD]]\". [soft_filter_result[CHAT_FILTER_INDEX_REASON]]", "Soft Blocked Word", list("Yes", "No")) != "Yes")
			return
		message_admins("[ADMIN_LOOKUPFLW(src)] passed the soft filter for Flood Chorus: [html_encode(message)]")
	if(stat == DEAD || !mind?.has_antag_datum(/datum/antagonist/flood))
		return
	message = trim(copytext_char(sanitize(message), 1, MAX_MESSAGE_LEN))
	if(!message)
		return
	var/rendered_message = span_notice("<b>Flood Chorus — [name]:</b> [message]")
	for(var/datum/antagonist/flood/other_flood in GLOB.antagonists)
		var/mob/living/basic/flood/recipient = other_flood.owner?.current
		if(istype(recipient) && recipient.stat != DEAD)
			to_chat(recipient, rendered_message)
	log_talk(message, LOG_SAY, tag = "Flood Chorus")

/datum/ai_controller/basic_controller/simple_hostile_obstacles/flood
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic,
		BB_TARGET_MINIMUM_STAT = HARD_CRIT,
	)

/datum/ai_controller/basic_controller/simple_hostile_obstacles/flood/infestor
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic/flood_infestor,
		BB_TARGET_MINIMUM_STAT = DEAD,
	)

/// Human combat forms can use guns they find on the station. Other Flood forms
/// retain the normal melee controller.
/datum/ai_controller/basic_controller/simple_hostile_obstacles/flood/armed
	planning_subtrees = list(
		/datum/ai_planning_subtree/simple_find_target,
		/datum/ai_planning_subtree/flood_use_gun,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/basic_melee_attack_subtree,
	)

/datum/ai_planning_subtree/flood_use_gun/SelectBehaviors(datum/ai_controller/controller, seconds_per_tick)
	var/mob/living/basic/flood/combat_form/human/armed_form = controller.pawn
	if(!istype(armed_form) || armed_form.client)
		return
	var/obj/item/gun/held_gun = armed_form.get_active_held_item()
	if(!istype(held_gun) || !held_gun.can_shoot())
		return
	var/atom/target = controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET]
	if(QDELETED(target) || armed_form.Adjacent(target))
		return
	controller.queue_behavior(/datum/ai_behavior/basic_ranged_attack/flood_gun, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETING_STRATEGY, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/ai_behavior/basic_ranged_attack/flood_gun
	action_cooldown = 1.5 SECONDS
	required_distance = 5
	avoid_friendly_fire = TRUE

/datum/ai_behavior/basic_ranged_attack/flood_gun/perform(seconds_per_tick, datum/ai_controller/controller, target_key, targeting_strategy_key, hiding_location_key)
	var/mob/living/basic/flood/combat_form/human/armed_form = controller.pawn
	if(!istype(armed_form))
		return AI_BEHAVIOR_INSTANT | AI_BEHAVIOR_FAILED
	var/obj/item/gun/held_gun = armed_form.get_active_held_item()
	if(!istype(held_gun) || !held_gun.can_shoot() || armed_form.Adjacent(controller.blackboard[target_key]))
		return AI_BEHAVIOR_INSTANT | AI_BEHAVIOR_FAILED
	return ..()

/datum/targeting_strategy/basic/flood_infestor/can_attack(mob/living/living_mob, atom/the_target, vision_range)
	if(!ishuman(the_target))
		return FALSE
	var/mob/living/carbon/human/host = the_target
	if(IS_FLOOD(host))
		return FALSE
	var/damage_taken = host.getBruteLoss() + host.getFireLoss()
	if(host.stat == CONSCIOUS && damage_taken <= host.maxHealth * 0.25)
		return FALSE
	return ..()

/// The baseline humanoid Flood form. Keeping this subtype explicit mirrors the
/// original implementation and gives infection/evolution code a stable target.
/mob/living/basic/flood/death(gibbed)
	if(!gibbed)
		var/death_sound
		if(istype(src, /mob/living/basic/flood/infestor))
			death_sound = pick(
				'sound/flood/infector_die1.ogg',
				'sound/flood/infector_die2.ogg',
				'sound/flood/infector_die3.ogg',
			)
		else if(!istype(src, /mob/living/basic/flood/carrier))
			death_sound = pick(
				'sound/flood/death.death2.ogg',
				'sound/flood/death.death3.ogg',
				'sound/flood/death.death4.ogg',
				'sound/flood/death.death5.ogg',
			)
		if(death_sound)
			playsound(loc, death_sound, 50, TRUE)
	return ..()

/mob/living/basic/flood/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. = ..()
	if(stat != DEAD && health < maxHealth)
		adjust_health(-seconds_per_tick)
	if(stat != DEAD && world.time >= next_idle_sound)
		next_idle_sound = world.time + rand(450, 750)
		if(prob(40))
			playsound(loc, pick(
				'sound/flood/flood_idle_noncombat.idle1.ogg',
				'sound/flood/flood_idle_noncombat.idle2.ogg',
				'sound/flood/flood_idle_noncombat.idle3.ogg',
			), 25, TRUE)

/mob/living/basic/flood/combat_form
	name = "Flood combat form"
	icon = 'icons/mob/flood/flood_combat_human.dmi'
	icon_state = "marine_infested"
	icon_living = "marine_infested"
	icon_dead = "marine_dead"
	maxHealth = 150
	health = 150
	melee_damage_lower = 25
	melee_damage_upper = 35
	/// A reanimated combat form cannot be raised again after its next death.
	var/reanimated = FALSE
	var/next_weld_break = 0

/mob/living/basic/flood/combat_form/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. = ..()
	if(!. || stat == DEAD || client || world.time < next_weld_break)
		return
	break_nearby_weld()

/mob/living/basic/flood/combat_form/examine(mob/user)
	. = ..()
	if(stat == DEAD && reanimated)
		. += span_warning("Its biomass has already been reanimated and cannot be raised again.")

/mob/living/basic/flood/proc/convert_human(mob/living/carbon/human/victim, infection_message)
	if(!victim || QDELETED(victim) || IS_FLOOD(victim))
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

/mob/living/basic/flood/combat_form/verb/create_infestor()
	set name = "Create Infection Form"
	set category = "Flood"

	if(stat == DEAD)
		return
	if(world.time < next_evolution)
		to_chat(src, span_warning("Your biomass is not ready to produce another infection form."))
		return

	next_evolution = world.time + FLOOD_INFESTOR_COOLDOWN
	new /mob/living/basic/flood/infestor(loc)
	visible_message(span_warning("[src]'s flesh tears open and produces a Flood infection form."))

/mob/living/basic/flood/combat_form/verb/destroy_weld()
	set name = "Destroy Weld"
	set category = "Flood"

	if(stat == DEAD)
		return
	if(world.time < next_weld_break)
		return
	if(!break_nearby_weld())
		to_chat(src, span_warning("There is no welded airlock close enough to tear open."))

/mob/living/basic/flood/combat_form/proc/break_nearby_weld()

	var/obj/machinery/door/airlock/target_airlock
	for(var/obj/machinery/door/airlock/candidate in view(1, src))
		if(candidate.welded)
			target_airlock = candidate
			break

	if(!target_airlock)
		return FALSE

	next_weld_break = world.time + 5 SECONDS
	visible_message(span_danger("[src] rakes its mutated limb across [target_airlock], tearing through the weld!"))
	target_airlock.welded = FALSE
	target_airlock.update_appearance()
	playsound(target_airlock, 'sound/effects/grillehit.ogg', 80, TRUE)
	return TRUE

/mob/living/basic/flood/combat_form/verb/evolve()
	set name = "Evolve Flood Form"
	set category = "Flood"

	if(stat == DEAD)
		return
	if(world.time < next_evolution)
		to_chat(src, span_warning("Your biomass is still recovering."))
		return

	var/list/evolution_choices = list(
		"Carrier" = /mob/living/basic/flood/carrier,
		"Juggernaut" = /mob/living/basic/flood/combat_form/juggernaut,
		"Constructor" = /mob/living/basic/flood/constructor,
		"Overseer" = /mob/living/basic/flood/overseer,
	)
	var/chosen_form = input(src, "Choose a Flood specialization.", "Flood Evolution") as null|anything in evolution_choices
	if(!chosen_form || stat == DEAD)
		return

	next_evolution = world.time + FLOOD_EVOLUTION_COOLDOWN
	var/form_type = evolution_choices[chosen_form]
	var/mob/living/basic/flood/new_form = new form_type(loc)

	if(mind)
		var/datum/mind/flood_mind = mind
		flood_mind.transfer_to(new_form)
		if(!flood_mind.has_antag_datum(/datum/antagonist/flood))
			flood_mind.add_antag_datum(/datum/antagonist/flood)
		flood_mind.special_role = ROLE_FLOOD
	drop_all_held_items()
	qdel(src)

/mob/living/basic/flood/combat_form/human
	name = "Flood infested human"
	icon = 'icons/mob/flood/flood_combat_human.dmi'
	icon_state = "marine_infested"
	icon_living = "marine_infested"
	speed = 0.5
	maxHealth = 100
	health = 100
	melee_damage_lower = 25
	melee_damage_upper = 35
	ai_controller = /datum/ai_controller/basic_controller/simple_hostile_obstacles/flood/armed
	var/next_gun_check = 0

/mob/living/basic/flood/combat_form/human/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/dextrous)
	AddComponent(/datum/component/basic_inhands)
	ADD_TRAIT(src, TRAIT_ADVANCEDTOOLUSER, INNATE_TRAIT)

/mob/living/basic/flood/combat_form/human/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. = ..()
	if(!. || stat == DEAD || client || world.time < next_gun_check)
		return
	next_gun_check = world.time + 2 SECONDS
	var/obj/item/held = get_active_held_item()
	if(istype(held, /obj/item/gun))
		var/obj/item/gun/held_gun = held
		if(held_gun.can_shoot())
			return
		dropItemToGround(held_gun, TRUE)
	else if(held)
		return
	for(var/obj/item/gun/candidate in range(1, src))
		if(candidate.loc != get_turf(candidate) || !Adjacent(candidate) || candidate.weapon_weight >= WEAPON_HEAVY || !candidate.can_shoot())
			continue
		if(!istype(candidate, /obj/item/gun/ballistic) && !istype(candidate, /obj/item/gun/energy))
			continue
		if(put_in_hands(candidate))
			visible_message(span_warning("[src] picks up [candidate]."))
			return

/mob/living/basic/flood/combat_form/human/RangedAttack(atom/target, modifiers)
	if(client)
		return ..()
	var/obj/item/gun/held_gun = get_active_held_item()
	if(!istype(held_gun) || !held_gun.can_shoot() || !target || Adjacent(target))
		return FALSE
	return held_gun.try_fire_gun(target, src, null)

/mob/living/basic/flood/combat_form/juggernaut
	name = "Flood Juggernaut"
	desc = "A towering mass of hardened Flood biomass."
	icon = 'icons/mob/flood/floodjuggernaut.dmi'
	icon_state = "movement state"
	icon_living = "movement state"
	icon_dead = "death state"
	speed = 2
	maxHealth = 500
	health = 500
	melee_damage_lower = 40
	melee_damage_upper = 55
	obj_damage = 120
	mob_size = MOB_SIZE_LARGE

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

/mob/living/basic/flood/carrier/proc/release_swarm()
	if(has_released_infection_forms)
		return
	has_released_infection_forms = TRUE

	var/turf/spawn_turf = get_turf(src)
	if(!spawn_turf)
		return
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

/mob/living/basic/flood/carrier/verb/release_infection_forms()
	set name = "Release Infection Forms"
	set category = "Flood"

	if(stat == DEAD)
		return
	release_swarm()
	qdel(src)

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
	var/next_airlock_infest = 0
	var/mob/living/carbon/human/latched_host
	var/swarm_size = 1
	var/max_swarm_size = 6

/mob/living/basic/flood/infestor/Initialize(mapload)
	. = ..()
	pixel_x = rand(-8, 8)
	pixel_y = rand(0, 24)

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
	if(client || mind || latched_host || swarm_size >= max_swarm_size)
		return
	for(var/mob/living/basic/flood/infestor/other in range(1, src))
		if(other == src || other.stat == DEAD || other.client || other.mind || other.latched_host || swarm_size + other.swarm_size > max_swarm_size)
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
	if(IS_FLOOD(host) || !Adjacent(host))
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
	if(stat == DEAD || QDELETED(host) || latched_host != host || IS_FLOOD(host) || !Adjacent(host))
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

/mob/living/basic/flood/carrier/death(gibbed)
	if(!has_released_infection_forms)
		release_swarm()
	return ..()

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

/mob/living/basic/flood/infestor/proc/infest_nearby_airlock(show_failure = FALSE)
	if(latched_host)
		return FALSE
	if(world.time < next_airlock_infest)
		return FALSE

	var/obj/machinery/door/airlock/target_airlock
	for(var/obj/machinery/door/airlock/candidate in view(2, src))
		if(candidate.welded || candidate.seal || (candidate.machine_stat & BROKEN))
			continue
		target_airlock = candidate
		break

	if(!target_airlock)
		if(show_failure)
			to_chat(src, span_warning("There is no vulnerable airlock nearby."))
		return FALSE

	next_airlock_infest = world.time + 10 SECONDS
	visible_message(span_danger("[src] leaps onto [target_airlock] and burrows into its control mechanisms!"))
	target_airlock.locked = FALSE
	target_airlock.set_machine_stat(target_airlock.machine_stat | BROKEN)
	INVOKE_ASYNC(target_airlock, TYPE_PROC_REF(/obj/machinery/door/airlock, open), BYPASS_DOOR_CHECKS)
	qdel(src)
	return TRUE

/mob/living/basic/flood/infestor/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. = ..()
	if(!. || stat == DEAD || client || latched_host || world.time < next_reanimate_check)
		return
	next_reanimate_check = world.time + 2 SECONDS
	merge_nearby_infestors()
	if(reanimate_nearby_flood())
		return
	infest_nearby_airlock()

/mob/living/basic/flood/infestor/verb/infest_airlock()
	set name = "Infest Airlock"
	set category = "Flood"

	if(stat == DEAD)
		return
	infest_nearby_airlock(TRUE)

/mob/living/basic/flood/infestor/verb/reanimate_flood()
	set name = "Reanimate Flood Corpse"
	set category = "Flood"

	if(stat == DEAD)
		return
	reanimate_nearby_flood(TRUE)

/datum/dynamic_ruleset/midround/from_ghosts/flood
	name = "Flood Outbreak"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_HEAVY
	antag_datum = /datum/antagonist/flood
	antag_flag = ROLE_FLOOD
	antag_preference = ROLE_FLOOD
	antag_flag_override = ROLE_FLOOD
	required_type = /mob/dead/observer
	required_applicants = 1
	required_candidates = 1
	weight = 2
	cost = 6
	antag_cap = 1
	repeatable = FALSE
	requirements = list(40, 35, 30, 25, 20, 20, 20, 20, 20, 20)
	ruleset_category = parent_type::ruleset_category | RULESET_CATEGORY_NO_WITTING_CREW_ANTAGONISTS
	signup_item_path = /obj/structure/sign/poster/contraband/syndicate_recruitment
	var/turf/spawn_turf

/datum/dynamic_ruleset/midround/from_ghosts/flood/execute()
	spawn_turf = find_maintenance_spawn(atmos_sensitive = TRUE, require_darkness = FALSE)
	if(!spawn_turf)
		return FALSE
	return ..()

/datum/dynamic_ruleset/midround/from_ghosts/flood/generate_ruleset_body(mob/applicant)
	var/mob/living/basic/flood/combat_form/human/new_flood = new(spawn_turf)
	if(applicant.mind)
		applicant.mind.transfer_to(new_flood)
	return new_flood

#undef IS_FLOOD
#undef FLOOD_INFESTOR_COOLDOWN
#undef FLOOD_EVOLUTION_COOLDOWN
