/// SurfShack Flood antagonist
///
/// Adapted from HaloSpaceStation13's Flood gameplay to SurfShack's current
/// antagonist, simple-animal, and dynamic-ruleset architecture.

GLOBAL_VAR_INIT(flood_infections, 0)

#define IS_FLOOD(mob) (mob?.mind?.has_antag_datum(/datum/antagonist/flood) || istype(mob, /mob/living/simple_animal/hostile/flood))
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
	antag_hud_name = "flood"
	job_rank = ROLE_FLOOD
	show_to_ghosts = TRUE
	show_in_antagpanel = TRUE
	can_assign_self_objectives = TRUE
	default_custom_objective = "Spread the Flood and establish a viable infestation."
	var/datum/team/flood/flood_team

/datum/antagonist/flood/on_gain()
	forge_objectives()
	return ..()

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
	var/next_infection = 0
	var/next_evolution = 0

/// The baseline humanoid Flood form. Keeping this subtype explicit mirrors the
/// original implementation and gives infection/evolution code a stable target.
/mob/living/simple_animal/hostile/flood/death(gibbed)
	if(!gibbed)
		playsound(loc, pick(
			'sound/flood/death.death2.ogg',
			'sound/flood/death.death3.ogg',
			'sound/flood/death.death4.ogg',
			'sound/flood/death.death5.ogg',
		), 50, TRUE)
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

/mob/living/simple_animal/hostile/flood/AttackingTarget(atom/attacked_target)
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

/mob/living/simple_animal/hostile/flood/proc/infect_host(mob/living/carbon/human/victim)
	if(!victim || QDELETED(victim) || victim.stat == DEAD || IS_FLOOD(victim))
		return FALSE
	if(world.time < next_infection)
		return FALSE

	next_infection = world.time + FLOOD_INFECTION_COOLDOWN
	GLOB.flood_infections++
	visible_message(span_danger("[src] tears into [victim], Flood biomass spreading through their body!"))

	var/mob/living/simple_animal/hostile/flood/combat_form/new_form = new(victim.loc)
	new_form.name = victim.real_name

	if(victim.mind)
		var/datum/mind/victim_mind = victim.mind
		victim_mind.transfer_to(new_form)
		if(!victim_mind.has_antag_datum(/datum/antagonist/flood))
			victim_mind.add_antag_datum(/datum/antagonist/flood)
		victim_mind.special_role = ROLE_FLOOD

	qdel(victim)
	return TRUE

/mob/living/simple_animal/hostile/flood/verb/create_infestor()
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

/mob/living/simple_animal/hostile/flood/verb/evolve()
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
		new_form = new /mob/living/simple_animal/hostile/flood/pure(loc)
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
	maxHealth = 100
	health = 100
	melee_damage_lower = 25
	melee_damage_upper = 35

/mob/living/simple_animal/hostile/flood/combat_form/juggernaut
	name = "Flood Juggernaut"
	desc = "A towering mass of hardened Flood biomass."
	icon = 'icons/mob/flood/floodjuggernaut.dmi'
	icon_state = "movement state"
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
	maxHealth = 100
	health = 100
	melee_damage_lower = 10
	melee_damage_upper = 18

/mob/living/simple_animal/hostile/flood/carrier/verb/release_infection_forms()
	set name = "Release Infection Forms"
	set category = "Flood"

	if(stat == DEAD)
		return
	var/count = rand(6, 12)
	for(var/i in 1 to count)
		new /mob/living/simple_animal/hostile/flood/infestor(loc)
	visible_message(span_warning("[src] ruptures, releasing a swarm of Flood infection forms!"))
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
	melee_damage_lower = 1
	melee_damage_upper = 5
	pass_flags = PASSMOB
	del_on_death = TRUE
	mob_size = MOB_SIZE_TINY
	attack_verb_continuous = "leaps at"
	attack_verb_simple = "leap at"
	attack_sound = 'sound/flood/leap.leap1.ogg'

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
	if(prob(70))
		var/mob/living/simple_animal/hostile/flood/combat_form/new_form = new(victim.loc)
		new_form.name = victim.real_name
		GLOB.flood_infections++
		if(victim.mind)
			var/datum/mind/victim_mind = victim.mind
			victim_mind.transfer_to(new_form)
			if(!victim_mind.has_antag_datum(/datum/antagonist/flood))
				victim_mind.add_antag_datum(/datum/antagonist/flood)
			victim_mind.special_role = ROLE_FLOOD
		visible_message(span_danger("[src] burrows into [victim], converting them into a Flood combat form!"))
		qdel(victim)
		qdel(src)

/mob/living/simple_animal/hostile/flood/carrier/death(gibbed)
	if(!QDELETED(src))
		visible_message(span_danger("[src] bursts, propelling Flood infection forms in all directions!"))
		playsound(loc, 'sound/effects/explosion/explosion1.ogg', 50, TRUE)
		var/turf/spawn_turf = get_turf(src)
		if(spawn_turf)
			for(var/i in 1 to rand(6, 12))
				new /mob/living/simple_animal/hostile/flood/infestor(spawn_turf)
	return ..()

/mob/living/simple_animal/hostile/flood/infestor/verb/reanimate_flood()
	set name = "Reanimate Flood Corpse"
	set category = "Flood"

	if(stat == DEAD)
		return

	var/mob/living/simple_animal/hostile/flood/corpse
	for(var/mob/living/simple_animal/hostile/flood/candidate in range(1, src))
		if(candidate == src || candidate.stat != DEAD || istype(candidate, /mob/living/simple_animal/hostile/flood/infestor))
			continue
		corpse = candidate
		break

	if(!corpse)
		to_chat(src, span_warning("There is no viable Flood corpse nearby."))
		return

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

/mob/living/simple_animal/hostile/flood/pure
	name = "Flood pure form"
	desc = "A heavily mutated Flood form built for direct combat."
	icon = 'icons/mob/flood/floodjuggernaut.dmi'
	icon_state = "juggernaut"
	maxHealth = 350
	health = 350
	melee_damage_lower = 35
	melee_damage_upper = 55
	obj_damage = 100

/datum/dynamic_ruleset/midround/from_ghosts/flood
	name = "Flood Outbreak"
	midround_ruleset_style = MIDROUND_RULESET_STYLE_HEAVY
	antag_datum = /datum/antagonist/flood
	antag_flag = ROLE_FLOOD
	antag_preference = ROLE_ALIEN
	antag_flag_override = ROLE_ALIEN
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
