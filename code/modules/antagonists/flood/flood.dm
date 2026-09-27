/// SurfShack Flood antagonist
///
/// Adapted from HaloSpaceStation13's Flood gameplay to SurfShack's current
/// antagonist, simple-animal, and dynamic-ruleset architecture.

GLOBAL_VAR_INIT(flood_infections, 0)

#define IS_FLOOD(target_mob) (target_mob?.mind?.has_antag_datum(/datum/antagonist/flood) || istype(target_mob, /mob/living/simple_animal/hostile/flood))
#define FLOOD_INFECTION_COOLDOWN (20 SECONDS)
#define FLOOD_INFESTOR_COOLDOWN (30 SECONDS)
#define FLOOD_EVOLUTION_COOLDOWN (60 SECONDS)

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
	to_chat(owner.current, span_bigdanger("You are part of the Flood."))
	to_chat(owner.current, span_notice("Spread the infestation by weakening and converting human hosts."))
	to_chat(owner.current, span_notice("Combat forms can create infection forms, tear apart welded airlocks, and evolve into specialized Flood forms."))
	to_chat(owner.current, span_notice("Infection forms can convert vulnerable humans and reanimate fallen Flood forms."))

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

/mob/living/simple_animal/hostile/flood
	name = "Flood combat form"
	desc = "A biomass-driven combat form belonging to a parasitic hive mind."
	icon = 'icons/mob/flood/flood_combat_human.dmi'
	icon_state = "static"
	mob_biotypes = MOB_ORGANIC | MOB_HUMANOID
	sentience_type = SENTIENCE_HUMANOID
	faction = list("Flood")
	combat_mode = TRUE
	atmos_requirements = null
	minbodytemp = 0
	maxHealth = 125
	health = 125
	harm_intent_damage = 10
	melee_damage_lower = 20
	melee_damage_upper = 30
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	attack_sound = 'sound/flood/melee.melee1.ogg'
	attacked_sound = 'sound/flood/pain.pain1.ogg'
	del_on_death = FALSE
	icon_dead = "dead"
	death_message = "collapses into a twitching mass of biomass."
	obj_damage = 60
	damage_coeff = list(BRUTE = 1, BURN = 1.5, TOX = 1, STAMINA = 0, OXY = 1)
	var/next_infection = 0
	var/next_evolution = 0

/// The baseline humanoid Flood form. Keeping this subtype explicit mirrors the
/// original implementation and gives infection/evolution code a stable target.
/mob/living/simple_animal/hostile/flood/death(gibbed)
	if(!gibbed)
		var/death_sound
		if(istype(src, /mob/living/simple_animal/hostile/flood/infestor))
			death_sound = pick(
				'sound/flood/infector_die1.ogg',
				'sound/flood/infector_die2.ogg',
				'sound/flood/infector_die3.ogg',
			)
		else if(!istype(src, /mob/living/simple_animal/hostile/flood/carrier))
			death_sound = pick(
				'sound/flood/death.death2.ogg',
				'sound/flood/death.death3.ogg',
				'sound/flood/death.death4.ogg',
				'sound/flood/death.death5.ogg',
			)
		if(death_sound)
			playsound(loc, death_sound, 50, TRUE)
	return ..()

/mob/living/simple_animal/hostile/flood/combat_form
	name = "Flood combat form"
	icon = 'icons/mob/flood/flood_combat_human.dmi'
	icon_state = "marine_infested"
	icon_dead = "marine_dead"
	maxHealth = 150
	health = 150
	melee_damage_lower = 25
	melee_damage_upper = 35

/mob/living/simple_animal/hostile/flood/combat_form/AttackingTarget(atom/attacked_target)
	. = ..()
	if(!. || !ishuman(attacked_target))
		return
	if(world.time < next_infection)
		return
	var/mob/living/carbon/human/victim = attacked_target
	if(victim.stat == DEAD || IS_FLOOD(victim))
		return
	if(prob(35))
		infect_host(victim)

/mob/living/simple_animal/hostile/flood/proc/convert_human(mob/living/carbon/human/victim, infection_message)
	if(!victim || QDELETED(victim) || victim.stat == DEAD || IS_FLOOD(victim))
		return FALSE

	var/turf/conversion_turf = get_turf(victim)
	if(!conversion_turf)
		return FALSE

	var/mob/living/simple_animal/hostile/flood/combat_form/human/new_form = new(conversion_turf)
	new_form.name = victim.real_name

	if(victim.mind)
		var/datum/mind/victim_mind = victim.mind
		victim_mind.transfer_to(new_form)
		if(!victim_mind.has_antag_datum(/datum/antagonist/flood))
			victim_mind.add_antag_datum(/datum/antagonist/flood)
		victim_mind.special_role = ROLE_FLOOD

	GLOB.flood_infections++
	if(infection_message)
		visible_message(span_danger(infection_message))
	qdel(victim)
	return TRUE

/mob/living/simple_animal/hostile/flood/proc/infect_host(mob/living/carbon/human/victim)
	if(world.time < next_infection)
		return FALSE
	next_infection = world.time + FLOOD_INFECTION_COOLDOWN
	return convert_human(victim, "[src] tears into [victim], Flood biomass spreading through their body!")

/mob/living/simple_animal/hostile/flood/combat_form/verb/create_infestor()
	set name = "Create Infection Form"
	set category = "Flood"

	if(stat == DEAD)
		return
	if(world.time < next_evolution)
		to_chat(src, span_warning("Your biomass is not ready to produce another infection form."))
		return

	next_evolution = world.time + FLOOD_INFESTOR_COOLDOWN
	new /mob/living/simple_animal/hostile/flood/infestor(loc)
	visible_message(span_warning("[src]'s flesh tears open and produces a Flood infection form."))

/mob/living/simple_animal/hostile/flood/combat_form/verb/destroy_weld()
	set name = "Destroy Weld"
	set category = "Flood"

	if(stat == DEAD)
		return

	var/obj/machinery/door/airlock/target_airlock
	for(var/obj/machinery/door/airlock/candidate in view(1, src))
		if(candidate.welded)
			target_airlock = candidate
			break

	if(!target_airlock)
		to_chat(src, span_warning("There is no welded airlock close enough to tear open."))
		return

	visible_message(span_danger("[src] rakes its mutated limb across [target_airlock], tearing through the weld!"))
	target_airlock.welded = FALSE
	target_airlock.update_appearance()
	playsound(target_airlock, 'sound/effects/grillehit.ogg', 80, TRUE)

/mob/living/simple_animal/hostile/flood/combat_form/verb/evolve()
	set name = "Evolve Flood Form"
	set category = "Flood"

	if(stat == DEAD)
		return
	if(world.time < next_evolution)
		to_chat(src, span_warning("Your biomass is still recovering."))
		return

	next_evolution = world.time + FLOOD_EVOLUTION_COOLDOWN

	var/mob/living/simple_animal/hostile/flood/new_form
	if(prob(50))
		new_form = new /mob/living/simple_animal/hostile/flood/combat_form/juggernaut(loc)
	else
		new_form = new /mob/living/simple_animal/hostile/flood/carrier(loc)

	if(mind)
		var/datum/mind/flood_mind = mind
		flood_mind.transfer_to(new_form)
		if(!flood_mind.has_antag_datum(/datum/antagonist/flood))
			flood_mind.add_antag_datum(/datum/antagonist/flood)
		flood_mind.special_role = ROLE_FLOOD
	qdel(src)

/mob/living/simple_animal/hostile/flood/combat_form/human
	name = "Flood infested human"
	icon = 'icons/mob/flood/flood_combat_human.dmi'
	icon_state = "marine_infested"
	move_to_delay = 6
	maxHealth = 100
	health = 100
	melee_damage_lower = 25
	melee_damage_upper = 35

/mob/living/simple_animal/hostile/flood/combat_form/juggernaut
	name = "Flood Juggernaut"
	desc = "A towering mass of hardened Flood biomass."
	icon = 'icons/mob/flood/floodjuggernaut.dmi'
	icon_state = "movement state"
	icon_dead = "death state"
	move_to_delay = 15
	maxHealth = 500
	health = 500
	melee_damage_lower = 40
	melee_damage_upper = 55
	obj_damage = 120
	mob_size = MOB_SIZE_LARGE

/mob/living/simple_animal/hostile/flood/carrier
	name = "Flood carrier form"
	desc = "A bloated Flood form packed with infection forms."
	icon = 'icons/mob/flood/flood_carrier.dmi'
	icon_state = "static"
	move_to_delay = 7
	maxHealth = 100
	health = 100
	melee_damage_lower = 10
	melee_damage_upper = 18
	del_on_death = TRUE
	icon_dead = ""

	var/has_released_infection_forms = FALSE

/mob/living/simple_animal/hostile/flood/carrier/proc/release_swarm()
	if(has_released_infection_forms)
		return
	has_released_infection_forms = TRUE

	var/turf/spawn_turf = get_turf(src)
	if(!spawn_turf)
		return

	for(var/i in 1 to rand(6, 12))
		new /mob/living/simple_animal/hostile/flood/infestor(spawn_turf)
	visible_message(span_warning("[src] ruptures, releasing a swarm of Flood infection forms!"))

/mob/living/simple_animal/hostile/flood/carrier/AttackingTarget(atom/attacked_target)
	if(!attacked_target || !Adjacent(attacked_target))
		return FALSE
	release_swarm()
	qdel(src)
	return TRUE

/mob/living/simple_animal/hostile/flood/carrier/verb/release_infection_forms()
	set name = "Release Infection Forms"
	set category = "Flood"

	if(stat == DEAD)
		return
	release_swarm()
	qdel(src)

/mob/living/simple_animal/hostile/flood/infestor
	name = "Flood infection form"
	desc = "A small Flood organism seeking a host."
	icon = 'icons/mob/flood/flood_infection.dmi'
	icon_state = "static"
	icon_dead = "dead"
	mob_biotypes = MOB_ORGANIC
	sentience_type = SENTIENCE_HUMANOID
	faction = list("Flood")
	combat_mode = TRUE
	atmos_requirements = null
	maxHealth = 5
	health = 5
	move_to_delay = 5
	melee_damage_lower = 1
	melee_damage_upper = 5
	pass_flags = PASSMOB
	del_on_death = TRUE
	mob_size = MOB_SIZE_TINY
	attack_verb_continuous = "leaps at"
	attack_verb_simple = "leap at"
	attack_sound = 'sound/flood/leap.leap1.ogg'
	var/next_reanimate_check = 0

/mob/living/simple_animal/hostile/flood/infestor/CanAttack(atom/the_target)
	if(ishuman(the_target))
		var/mob/living/carbon/human/potential_host = the_target
		if(QDELETED(potential_host) || potential_host.stat == DEAD || IS_FLOOD(potential_host))
			return FALSE
		var/damage_taken = potential_host.getBruteLoss() + potential_host.getFireLoss()
		return potential_host.stat != CONSCIOUS || damage_taken > potential_host.maxHealth * 0.25
	return ..()

/mob/living/simple_animal/hostile/flood/infestor/AttackingTarget(atom/attacked_target)
	. = ..()
	if(!. || !ishuman(attacked_target))
		return
	var/mob/living/carbon/human/victim = attacked_target
	if(victim.stat == DEAD || IS_FLOOD(victim))
		return
	var/damage_taken = victim.getBruteLoss() + victim.getFireLoss()
	if(victim.stat == CONSCIOUS && damage_taken <= victim.maxHealth * 0.25)
		return
	if(prob(70) && convert_human(victim, "[src] burrows into [victim], converting them into a Flood combat form!"))
		qdel(src)

/mob/living/simple_animal/hostile/flood/carrier/death(gibbed)
	if(!has_released_infection_forms)
		playsound(loc, 'sound/effects/explosion/explosion1.ogg', 50, TRUE)
		release_swarm()
	return ..()

/mob/living/simple_animal/hostile/flood/infestor/proc/reanimate_nearby_flood(show_failure = FALSE)
	var/mob/living/simple_animal/hostile/flood/combat_form/corpse
	for(var/mob/living/simple_animal/hostile/flood/combat_form/candidate in range(2, src))
		if(candidate.stat != DEAD)
			continue
		corpse = candidate
		break

	if(!corpse)
		if(show_failure)
			to_chat(src, span_warning("There is no viable Flood corpse nearby."))
		return FALSE

	var/mob/living/simple_animal/hostile/flood/new_form = new corpse.type(corpse.loc)
	new_form.name = corpse.name
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

/mob/living/simple_animal/hostile/flood/infestor/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. = ..()
	if(!. || stat == DEAD || client || world.time < next_reanimate_check)
		return
	next_reanimate_check = world.time + 2 SECONDS
	reanimate_nearby_flood()

/mob/living/simple_animal/hostile/flood/infestor/verb/reanimate_flood()
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
	var/mob/living/simple_animal/hostile/flood/combat_form/human/new_flood = new(spawn_turf)
	if(applicant.mind)
		applicant.mind.transfer_to(new_flood)
	return new_flood

#undef IS_FLOOD
#undef FLOOD_INFECTION_COOLDOWN
#undef FLOOD_INFESTOR_COOLDOWN
#undef FLOOD_EVOLUTION_COOLDOWN
