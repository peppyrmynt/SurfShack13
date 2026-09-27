/// SurfShack Flood antagonist
///
/// Adapted from the Flood gameplay in HaloSpaceStation13 to SurfShack's
/// current antagonist, simple-mob and dynamic-ruleset architecture.

GLOBAL_VAR_INIT(flood_infections, 0)

#define FLOOD_TRAIT "flood"
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
    icon = 'icons/mob/simple/simple_human.dmi'
    icon_state = "human"
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
    attack_sound = 'sound/effects/hallucinations/growl1.ogg'
    del_on_death = TRUE
    death_message = "collapses into a twitching mass of biomass."
    obj_damage = 60
    environment_smash = ENVIRONMENT_SMASH_STRUCTURES
    var/next_infection = 0
    var/next_evolution = 0

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
    new_form.maxHealth = 150
    new_form.health = 150

    if(victim.mind)
        victim.mind.transfer_to(new_form)
        new_form.mind.add_antag_datum(/datum/antagonist/flood)
        new_form.mind.special_role = ROLE_FLOOD

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
        mind.transfer_to(new_form)
        new_form.mind.add_antag_datum(/datum/antagonist/flood)
        new_form.mind.special_role = ROLE_FLOOD
    qdel(src)

/mob/living/simple_animal/hostile/flood/carrier
    name = "Flood carrier form"
    desc = "A bloated Flood form that produces infection forms."
    maxHealth = 180
    health = 180
    melee_damage_lower = 10
    melee_damage_upper = 18

/mob/living/simple_animal/hostile/flood/carrier/verb/release_infection_forms()
    set name = "Release Infection Forms"
    set category = "Flood"

    var/count = rand(2, 4)
    for(var/i in 1 to count)
        new /mob/living/simple_animal/hostile/flood/infestor(loc)
    visible_message(span_warning("[src] ruptures, releasing a swarm of Flood infection forms!"))

/mob/living/simple_animal/hostile/flood/infestor
    name = "Flood infection form"
    desc = "A small Flood organism seeking a host."
    icon = 'icons/mob/simple/simple_human.dmi'
    icon_state = "human"
    mob_biotypes = MOB_ORGANIC
    sentience_type = SENTIENCE_HUMANOID
    faction = list("Flood")
    combat_mode = TRUE
    atmos_requirements = null
    maxHealth = 15
    health = 15
    melee_damage_lower = 5
    melee_damage_upper = 10
    move_to_delay = 2
    pass_flags = PASSMOB
    del_on_death = TRUE
    attack_verb_continuous = "claws"
    attack_verb_simple = "claw"

/mob/living/simple_animal/hostile/flood/infestor/AttackingTarget(atom/attacked_target)
    . = ..()
    if(!. || !ishuman(attacked_target))
        return
    var/mob/living/carbon/human/victim = attacked_target
    if(victim.stat == DEAD || IS_FLOOD(victim))
        return
    if(prob(70))
        var/mob/living/simple_animal/hostile/flood/combat_form/new_form = new(victim.loc)
        new_form.name = victim.real_name
        GLOB.flood_infections++
        if(victim.mind)
            victim.mind.transfer_to(new_form)
            new_form.mind.add_antag_datum(/datum/antagonist/flood)
            new_form.mind.special_role = ROLE_FLOOD
        visible_message(span_danger("[src] burrows into [victim], converting them into a Flood combat form!"))
        qdel(victim)

/mob/living/simple_animal/hostile/flood/pure
    name = "Flood pure form"
    desc = "A heavily mutated Flood form built for direct combat."
    maxHealth = 350
    health = 350
    melee_damage_lower = 35
    melee_damage_upper = 55
    obj_damage = 100
    resistance = 20

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
    var/mob/living/simple_animal/hostile/flood/combat_form/new_flood = new(spawn_turf)
    if(applicant.mind)
        applicant.mind.transfer_to(new_flood)
    return new_flood

#undef FLOOD_TRAIT
#undef IS_FLOOD
#undef FLOOD_INFECTION_COOLDOWN
#undef FLOOD_INFESTOR_COOLDOWN
#undef FLOOD_EVOLUTION_COOLDOWN
