// Ported from Merchant Station 13's particle acceleration rifle, modernised onto the scope component
// (the original hold-to-aim mouse code no longer exists in this codebase).

/// How many structures (windows, doors, tables, girders...) a pierce-mode beam can punch through
#define PARTICLE_RIFLE_STRUCTURE_PIERCES 2

/obj/item/stock_parts/power_store/cell/particle_rifle
	name = "particle rifle capacitor"
	desc = "A high powered capacitor that can provide huge amounts of energy in an instant."
	maxcharge = STANDARD_CELL_CHARGE * 5
	chargerate = STANDARD_CELL_RATE * 0.5

/obj/item/gun/energy/particle_rifle
	name = "particle acceleration rifle"
	desc = "An energy-based anti material marksman rifle that uses highly charged particle beams moving at extreme velocities to decimate whatever is unfortunate enough to be targeted by one. \
		Must be scoped (right click) to fire. Use it in hand to switch between piercing and impact mode."
	icon = 'icons/obj/weapons/guns/energy.dmi'
	icon_state = "esniper"
	inhand_icon_state = null
	worn_icon_state = null
	fire_sound = 'sound/items/weapons/beam_sniper.ogg'
	slot_flags = ITEM_SLOT_BACK
	force = 15
	custom_materials = null
	recoil = 3
	ammo_x_offset = 3
	ammo_y_offset = 3
	modifystate = FALSE
	charge_sections = 1
	weapon_weight = WEAPON_HEAVY
	w_class = WEIGHT_CLASS_BULKY
	ammo_type = list(/obj/item/ammo_casing/energy/particle_rifle)
	cell_type = /obj/item/stock_parts/power_store/cell/particle_rifle
	/// Piercing mode punches through up to PARTICLE_RIFLE_STRUCTURE_PIERCES structures, impact mode stops at the first one and hits harder.
	var/pierce_mode = TRUE

/obj/item/gun/energy/particle_rifle/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/scope, range_modifier = 4)

/obj/item/gun/energy/particle_rifle/examine(mob/user)
	. = ..()
	. += span_notice("It is set to <b>[pierce_mode ? "piercing" : "impact"]</b> mode.")

/obj/item/gun/energy/particle_rifle/attack_self(mob/user)
	pierce_mode = !pierce_mode
	balloon_alert(user, "[pierce_mode ? "piercing" : "impact"] mode")
	playsound(src, 'sound/items/weapons/gun/general/slide_lock_1.ogg', 50, TRUE)
	return TRUE

/obj/item/gun/energy/particle_rifle/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0)
	if(!HAS_TRAIT(user, TRAIT_USER_SCOPED))
		balloon_alert(user, "must be scoped!")
		return FALSE
	return ..()

/obj/item/ammo_casing/energy/particle_rifle
	projectile_type = /obj/projectile/beam/particle_rifle
	select_name = "beam"
	e_cost = STANDARD_CELL_CHARGE
	delay = 4 SECONDS
	fire_sound = 'sound/items/weapons/beam_sniper.ogg'

/obj/item/ammo_casing/energy/particle_rifle/ready_proj(atom/target, mob/living/user, quiet, zone_override = "")
	. = ..()
	var/obj/item/gun/energy/particle_rifle/rifle = loc
	var/obj/projectile/beam/particle_rifle/beam = loaded_projectile
	if(istype(rifle) && istype(beam))
		beam.pierce_mode = rifle.pierce_mode

/obj/projectile/beam/particle_rifle
	name = "particle beam"
	icon = null
	hitsound = 'sound/effects/explosion/explosion3.ogg'
	damage = 45
	damage_type = BURN
	armor_flag = ENERGY
	range = 150
	jitter = 10 SECONDS
	hitscan = TRUE
	tracer_type = /obj/effect/projectile/tracer/tracer/beam_rifle
	/// Piercing mode: go through structures. Impact mode: stop at the first thing and damage it harder.
	var/pierce_mode = TRUE
	/// Structures pierced so far
	var/structures_pierced = 0
	/// Fraction of the impact damage a pierced structure takes
	var/structure_bleed_coeff = 0.7
	/// Extra damage dealt to a structure that stops the beam
	var/impact_structure_damage = 60
	/// Damage to mobs and structures near the impact point
	var/aoe_mob_damage = 20
	var/aoe_mob_range = 1
	var/aoe_structure_damage = 50
	var/aoe_structure_range = 1
	var/aoe_fire_range = 2
	var/aoe_fire_chance = 40

/obj/projectile/beam/particle_rifle/proc/get_damage_coeff(atom/target)
	if(istype(target, /obj/machinery/door))
		return 0.4
	if(istype(target, /obj/structure/window))
		return 0.5
	return 1

/obj/projectile/beam/particle_rifle/prehit_pierce(atom/target)
	if(pierce_mode && isobj(target) && !isitem(target) && structures_pierced < PARTICLE_RIFLE_STRUCTURE_PIERCES)
		structures_pierced++
		var/obj/structure_hit = target
		structure_hit.take_damage((impact_structure_damage + aoe_structure_damage) * structure_bleed_coeff * get_damage_coeff(target), BURN, LASER, FALSE)
		return PROJECTILE_PIERCE_PHASE
	return ..()

/obj/projectile/beam/particle_rifle/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	if(pierce_hit)
		return
	if(isobj(target) && !QDELETED(target))
		var/obj/structure_hit = target
		structure_hit.take_damage(impact_structure_damage * get_damage_coeff(target), BURN, LASER, FALSE)
	aoe(get_turf(target) || get_turf(src), target)

/obj/projectile/beam/particle_rifle/proc/aoe(turf/epicenter, atom/direct_target)
	if(!epicenter)
		return
	playsound(epicenter, 'sound/effects/explosion/explosion3.ogg', 100, TRUE)
	new /obj/effect/temp_visual/explosion/fast(epicenter)
	for(var/mob/living/nearby in range(aoe_mob_range, epicenter))
		if(nearby == direct_target)
			continue
		var/armor = nearby.run_armor_check(BODY_ZONE_CHEST, ENERGY)
		nearby.apply_damage(aoe_mob_damage, BURN, BODY_ZONE_CHEST, armor)
		to_chat(nearby, span_userdanger("\The [src] sears you!"))
	for(var/turf/open/fire_turf in RANGE_TURFS(aoe_fire_range, epicenter))
		if(prob(aoe_fire_chance))
			new /obj/effect/hotspot(fire_turf)
	for(var/obj/structure_near in range(aoe_structure_range, epicenter))
		if(isitem(structure_near) || structure_near == direct_target)
			continue
		structure_near.take_damage(aoe_structure_damage * get_damage_coeff(structure_near), BURN, LASER, FALSE)

#undef PARTICLE_RIFLE_STRUCTURE_PIERCES
