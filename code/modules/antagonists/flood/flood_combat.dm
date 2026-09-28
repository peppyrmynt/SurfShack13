/// The baseline humanoid Flood form. Keeping this subtype explicit mirrors the
/// original implementation and gives infection/evolution code a stable target.
/mob/living/basic/flood/death(gibbed)
	qdel(GetComponent(/datum/component/ghost_direct_control))
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
	. = ..()
	if(. && on_fire && !QDELETED(src))
		// The corpse uses small human flames even if its living body burned brightly.
		update_appearance(UPDATE_OVERLAYS)

/mob/living/basic/flood/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. = ..()
	if(stat != DEAD && body_position == STANDING_UP && !buckled && health < maxHealth && istype(loc, /turf/open/floor/flood_biomass))
		adjust_health(-0.5 * seconds_per_tick)
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
	name = "Flood Combat"
	icon = 'icons/mob/flood/flood_combat_human.dmi'
	icon_state = "nudist"
	icon_living = "nudist"
	icon_dead = "nudist_dead"
	unique_name = TRUE
	maxHealth = 150
	health = 150
	melee_damage_lower = 25
	melee_damage_upper = 35
	/// A reanimated combat form cannot be raised again after its next death.
	var/reanimated = FALSE

/mob/living/basic/flood/combat_form/get_flood_actions()
	. = ..()
	. += /datum/action/cooldown/flood/evolve

/mob/living/basic/flood/combat_form/examine(mob/user)
	. = ..()
	if(stat == DEAD && reanimated)
		. += span_warning("Its biomass has already been reanimated and cannot be raised again.")

/mob/living/basic/flood/combat_form/proc/evolve()
	if(stat == DEAD)
		return
	if(world.time < next_evolution)
		to_chat(src, span_warning("Your biomass is still recovering."))
		return

	var/list/evolution_choices = list(
		"Carrier" = /mob/living/basic/flood/carrier,
		"Constructor" = /mob/living/basic/flood/constructor,
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

/// Ordinary combat forms, including converted hosts, start empty-handed.
/mob/living/basic/flood/combat_form/human
	name = "Flood Combat"
	icon = 'icons/mob/flood/flood_combat_human.dmi'
	icon_state = "nudist"
	icon_living = "nudist"
	icon_dead = "nudist_dead"
	speed = 0.5
	maxHealth = 100
	health = 100
	melee_damage_lower = 25
	melee_damage_upper = 35
	ai_controller = /datum/ai_controller/basic_controller/simple_hostile_obstacles/flood/armed
	var/next_weapon_check = 0
	var/obj/item/recovery_target

/mob/living/basic/flood/combat_form/human/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/dextrous)
	// These sprites draw their bodies in the base icon, so held items go above it.
	AddComponent(/datum/component/basic_inhands, display_layer = 0)
	update_held_items()
	ADD_TRAIT(src, TRAIT_ADVANCEDTOOLUSER, INNATE_TRAIT)

/// An armed variant for admin spawning only; no outbreak or biomass spawn pool uses it.
/mob/living/basic/flood/combat_form/human/armed
	name = "Armed Flood Combat"

/mob/living/basic/flood/combat_form/human/armed/Initialize(mapload)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(equip_spawn_gun))

/mob/living/basic/flood/combat_form/human/armed/proc/equip_spawn_gun()
	if(stat == DEAD)
		return
	var/gun_type = pick(/obj/item/gun/ballistic/automatic/pistol, /obj/item/gun/energy/laser)
	var/obj/item/gun/starter_gun = new gun_type(src)
	if(!put_in_hands(starter_gun))
		starter_gun.forceMove(drop_location())

/// Guns come first; otherwise choose weapons with more than 10 brute or burn
/// damage, including throwable weapons that can deal that damage at range.
/mob/living/basic/flood/combat_form/human/proc/weapon_score(obj/item/weapon)
	if(QDELETED(weapon) || weapon.anchored || (weapon.item_flags & ABSTRACT) || HAS_TRAIT(weapon, TRAIT_NODROP))
		return 0
	if(istype(weapon, /obj/item/gun))
		var/obj/item/gun/gun = weapon
		return gun.can_shoot() ? 100 + gun.force : 0
	if(weapon.damtype != BRUTE && weapon.damtype != BURN)
		return 0
	var/melee_damage = weapon.force > 10 ? weapon.force : 0
	var/ranged_damage = weapon.throw_range >= 3 && weapon.throwforce > 10 ? weapon.throwforce : 0
	return max(melee_damage, ranged_damage)

/mob/living/basic/flood/combat_form/human/proc/drop_empty_guns()
	for(var/obj/item/gun/gun in held_items)
		if(!gun.can_shoot())
			dropItemToGround(gun, TRUE)
	if(!get_active_held_item() && get_inactive_held_item())
		swap_hand(get_inactive_hand_index())

/mob/living/basic/flood/combat_form/human/proc/find_recovery_weapon(only_adjacent = FALSE)
	var/obj/item/best_weapon
	var/held_score = max(weapon_score(get_active_held_item()), weapon_score(get_inactive_held_item()))
	var/best_score = held_score
	var/best_distance = INFINITY
	var/search_range = only_adjacent ? 1 : 7
	for(var/obj/item/candidate in view(search_range, src))
		if(!isturf(candidate.loc))
			continue
		var/score = weapon_score(candidate)
		var/distance = get_dist(src, candidate)
		if(score <= held_score || score < best_score || (score == best_score && distance >= best_distance))
			continue
		best_weapon = candidate
		best_score = score
		best_distance = distance
	for(var/mob/living/carbon/dead_enemy in view(search_range, src))
		if(dead_enemy.stat != DEAD || is_flood_target(dead_enemy))
			continue
		for(var/obj/item/candidate in dead_enemy.held_items)
			var/score = weapon_score(candidate)
			var/distance = get_dist(src, dead_enemy)
			if(score <= held_score || score < best_score || (score == best_score && distance >= best_distance))
				continue
			best_weapon = candidate
			best_score = score
			best_distance = distance
	return best_weapon

/mob/living/basic/flood/combat_form/human/proc/recover_weapon(obj/item/weapon)
	if(stat == DEAD || client || weapon_score(weapon) <= max(weapon_score(get_active_held_item()), weapon_score(get_inactive_held_item())))
		return FALSE
	var/mob/living/carbon/dead_enemy = weapon.loc
	if(istype(dead_enemy))
		if(dead_enemy.stat != DEAD || is_flood_target(dead_enemy) || !(weapon in dead_enemy.held_items) || !CanReach(dead_enemy) || !dead_enemy.dropItemToGround(weapon))
			return FALSE
	else if(!isturf(weapon.loc) || !CanReach(weapon))
		return FALSE
	var/obj/item/current_weapon = get_active_held_item()
	if(current_weapon && !dropItemToGround(current_weapon))
		return FALSE
	if(istype(weapon, /obj/item/gun))
		var/obj/item/gun/new_gun = weapon
		var/obj/item/inactive_weapon = get_inactive_held_item()
		if(new_gun.weapon_weight == WEAPON_HEAVY && inactive_weapon && !dropItemToGround(inactive_weapon))
			return FALSE
	if(!put_in_active_hand(weapon))
		return FALSE
	visible_message(span_warning("[src] recovers [weapon]."))
	return TRUE

/mob/living/basic/flood/combat_form/human/RangedAttack(atom/target, modifiers)
	if(client)
		return ..()
	var/obj/item/held_weapon = get_active_held_item()
	if(!target || Adjacent(target))
		return FALSE
	if(istype(held_weapon, /obj/item/gun))
		var/obj/item/gun/held_gun = held_weapon
		if(!held_gun.can_shoot())
			return FALSE
		. = held_gun.try_fire_gun(target, src, null)
		if(!held_gun.can_shoot())
			dropItemToGround(held_gun, TRUE)
		return .
	if(weapon_score(held_weapon) <= 0 || held_weapon.throwforce <= 10 || held_weapon.throwforce <= held_weapon.force || get_dist(src, target) > held_weapon.throw_range)
		return FALSE
	if(!dropItemToGround(held_weapon, TRUE))
		return FALSE
	held_weapon.safe_throw_at(target, held_weapon.throw_range, held_weapon.throw_speed, src)
	return TRUE

/mob/living/basic/flood/combat_form/human/death(gibbed)
	// Let survivors recover station weapons from fallen combat forms.
	drop_all_held_items()
	return ..()

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
