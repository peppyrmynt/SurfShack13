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
				'sound/flood/death.ogg',
				'sound/flood/death.death2.ogg',
				'sound/flood/death.death3.ogg',
				'sound/flood/death.death4.ogg',
				'sound/flood/death.death5.ogg',
				'sound/flood/death.death10.ogg',
				'sound/flood/death.death15.ogg',
				'sound/flood/death.death20.ogg',
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
			if(ai_controller?.blackboard_key_exists(BB_BASIC_MOB_CURRENT_TARGET))
				playsound(loc, pick(
					'sound/flood/flood_idle_combat.leap1.ogg',
					'sound/flood/flood_idle_combat.leap2.ogg',
					'sound/flood/flood_idle_combat.leap5.ogg',
					'sound/flood/flood_idle_combat.leap11.ogg',
					'sound/flood/flood_idle_combat.leap15.ogg',
					'sound/flood/flood_idle_combat.melee1.ogg',
					'sound/flood/flood_idle_combat.melee2.ogg',
					'sound/flood/flood_idle_combat.melee5.ogg',
					'sound/flood/flood_idle_combat.melee6.ogg',
					'sound/flood/flood_idle_combat.melee7.ogg',
					'sound/flood/flood_idle_combat.melee8.ogg',
					'sound/flood/flood_idle_combat.melee10.ogg',
					'sound/flood/flood_idle_combat.melee11.ogg',
					'sound/flood/flood_idle_combat.melee15.ogg',
					'sound/flood/flood_idle_combat.melee20.ogg',
				), 25, TRUE)
			else
				playsound(loc, pick(
					'sound/flood/flood_idle_noncombat.idle1.ogg',
					'sound/flood/flood_idle_noncombat.idle2.ogg',
					'sound/flood/flood_idle_noncombat.idle3.ogg',
					'sound/flood/flood_idle_noncombat.idle4.ogg',
					'sound/flood/flood_idle_noncombat.idle5.ogg',
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

/mob/living/basic/flood/combat_form/examine(mob/user)
	. = ..()
	if(stat == DEAD && reanimated)
		. += span_warning("Its biomass has already been reanimated and cannot be raised again.")

/mob/living/basic/flood/proc/convert_human(mob/living/carbon/human/victim, infection_message)
	if(!victim || QDELETED(victim) || is_flood_target(victim))
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

	next_evolution = world.time + 30 SECONDS
	new /mob/living/basic/flood/infestor(loc)
	visible_message(span_warning("[src]'s flesh tears open and produces a Flood infection form."))

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

	next_evolution = world.time + 60 SECONDS
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
	var/spawn_gun_chance = 25

/mob/living/basic/flood/combat_form/human/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/dextrous)
	AddComponent(/datum/component/basic_inhands)
	ADD_TRAIT(src, TRAIT_ADVANCEDTOOLUSER, INNATE_TRAIT)
	// Source human forms occasionally arrive armed. Use ordinary station guns.
	if(prob(spawn_gun_chance))
		INVOKE_ASYNC(src, PROC_REF(equip_spawn_gun))

/mob/living/basic/flood/combat_form/human/proc/equip_spawn_gun()
	if(stat == DEAD)
		return
	var/gun_type = pick(/obj/item/gun/ballistic/automatic/pistol, /obj/item/gun/energy/laser)
	var/obj/item/gun/starter_gun = new gun_type(src)
	if(!put_in_hands(starter_gun))
		starter_gun.forceMove(drop_location())

/mob/living/basic/flood/combat_form/human/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. = ..()
	if(!. || stat == DEAD || client || world.time < next_gun_check)
		return
	next_gun_check = world.time + 2 SECONDS
	INVOKE_ASYNC(src, PROC_REF(scavenge_station_gun))

/mob/living/basic/flood/combat_form/human/proc/scavenge_station_gun()
	if(stat == DEAD || client)
		return
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

/mob/living/basic/flood/combat_form/human/death(gibbed)
	// Let survivors recover station weapons from fallen combat forms.
	drop_all_held_items()
	return ..()

/// Human-only forms from the source's prisoner infestation. These can be
/// placed in maps without introducing its nonhuman or specialist variants.
/mob/living/basic/flood/combat_form/human/prisoner
	name = "infected prisoner"
	desc = "An infected human with the remains of an orange jumpsuit."
	icon_state = "prisoner_infected2"
	icon_living = "prisoner_infected2"
	icon_dead = "prisoner_infected2_dead"
	maxHealth = 50
	health = 50
	melee_damage_lower = 15
	melee_damage_upper = 25
	spawn_gun_chance = 0

/mob/living/basic/flood/combat_form/human/prisoner/mutated
	name = "mutated infected prisoner"
	desc = "A mutated human form with shreds of an orange jumpsuit."
	icon_state = "prisoner_infected1"
	icon_living = "prisoner_infected1"
	icon_dead = "prisoner_infected1_dead"
	maxHealth = 85
	health = 85
	melee_damage_lower = 20
	melee_damage_upper = 30

/mob/living/basic/flood/combat_form/human/prisoner/abomination
	name = "Flood abomination"
	desc = "A heavily mutated human form dragging itself forward on enlarged arms."
	icon_state = "abomination"
	icon_living = "abomination"
	icon_dead = "abomination_dead"
	maxHealth = 250
	health = 250
	melee_damage_lower = 30
	melee_damage_upper = 40
	mob_size = MOB_SIZE_LARGE
	speed = -0.5

/mob/living/basic/flood/combat_form/human/crew
	name = "Flood infected crew member"
	desc = "An infected human stripped of most of its clothing."
	icon_state = "nudist"
	icon_living = "nudist"
	icon_dead = "nudist_dead"
	spawn_gun_chance = 0

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
