/**
  * inserted into:
  * cargo - frog crate
  * maint loot - moisture spawn
  * fishing - hydroponics tray
**/

/mob/living/basic/frog/space
	icon = 'surfshack13/icons/mob/space_frog.dmi'
	icon_state = "frog_white"
	name = "albino frog"

/obj/effect/spawner/random/space_frog
	loot_subtype_path = /mob/living/basic/frog/space

/mob/living/basic/frog/space/green
	name = "glow frog"
	desc = "Algae in the frogs skin provide food for it. The algae causes the frog to glow in the dark. You can see them when you're driving."
	icon_state = "frog_green"
	icon_living  = "frog_green"
	icon_dead = "frog_green_dead"
	poison_type = /datum/reagent/uranium

/mob/living/basic/frog/space/green/Initialize()
	. = ..()
	set_light(2, 4, COLOR_GREEN)

/mob/living/basic/frog/space/red
	name = "plasma frog"
	desc = "This frog eats plasma and it's rather warm. It could probably ignite items on contact. (secondary click to ignite item.)"
	icon_state = "frog_red"
	icon_living  = "frog_red"
	icon_dead = "frog_red_dead"
	poison_type = /datum/reagent/stable_plasma
	maximum_survivable_temperature = INFINITY

/mob/living/basic/frog/space/red/attackby_secondary(obj/item/weapon, mob/living/user, params)
	. = ..()
	if(stat)
		return
	if(weapon.fire_act(500, 10))
		to_chat(user, span_notice("\the [src] heats up briefly after coming into contact with [weapon]"))

/mob/living/basic/frog/space/red/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_LAVA_IMMUNE, INNATE_TRAIT)

/mob/living/basic/frog/space/yellow
	name = "supermatter frog"
	desc = "It shines and crackles like a supermatter. There's a charge port on it. (drag items onto frog to charge)"
	icon_state = "frog_yellow"
	icon_living = "frog_yellow"
	icon_dead = "frog_yellow_dead"
	var/obj/item/charging = null
	var/static/list/allowed_devices = typecacheof(list(
		/obj/item/gun/energy,
		/obj/item/melee/baton/security,
		/obj/item/ammo_box/magazine/recharge,
		/obj/item/modular_computer,
	))
	poison_type = /datum/reagent/teslium

/mob/living/basic/frog/space/yellow/Initialize()
	. = ..()
	RegisterSignal(src, COMSIG_LIVING_DEATH, PROC_REF(drop_charging))
	RegisterSignal(src, COMSIG_MOUSEDROPPED_ONTO, PROC_REF(on_mouse_dropped))

/mob/living/basic/frog/space/yellow/Destroy()
	UnregisterSignal(src, list(COMSIG_LIVING_DEATH, COMSIG_MOUSEDROPPED_ONTO))
	. = ..()

/mob/living/basic/frog/space/yellow/proc/on_mouse_dropped(atom/source, atom/weapon, mob/user)
	SIGNAL_HANDLER
	if(!user.can_perform_action(src, NEED_DEXTERITY|NEED_HANDS|FORBID_TELEKINESIS_REACH))
		return
	if(stat || charging || !is_type_in_typecache(weapon, allowed_devices))
		return
	if (istype(weapon, /obj/item/gun/energy))
		var/obj/item/gun/energy/energy_gun = weapon
		if(!energy_gun.can_charge)
			to_chat(user, span_notice("Your gun has no external power connector."))
			return
	user.transferItemToLoc(weapon, src)
	charging = weapon
	icon_state = "frog_yellow_charging"
	START_PROCESSING(SSmachines, src)

/mob/living/basic/frog/space/yellow/process(seconds_per_tick)
	if(!charging || stat)
		icon_state = "frog_yellow[ stat ? "_dead" : ""]"
		return PROCESS_KILL
	var/obj/item/stock_parts/power_store/charging_cell = charging.get_cell()
	if(charging_cell)
		if(charging_cell.charge < charging_cell.maxcharge)
			charging_cell.give(charging_cell.chargerate)
		else
			drop_charging(FALSE)
	if(istype(charging, /obj/item/ammo_box/magazine/recharge))
		var/obj/item/ammo_box/magazine/recharge/power_pack = charging
		if(power_pack.stored_ammo.len < power_pack.max_ammo)
			power_pack.stored_ammo += new power_pack.ammo_type(power_pack)
		else
			drop_charging(FALSE)

/mob/living/basic/frog/space/yellow/proc/drop_charging(no_ping = TRUE)
	SIGNAL_HANDLER
	if(!charging)
		return
	if(!no_ping)
		playsound(src, 'sound/machines/ping.ogg', 30, TRUE)
	charging.update_icon()
	charging.forceMove(get_turf(src))
	charging = null

/mob/living/basic/frog/space/yellow/attack_hand(mob/living/carbon/human/user, list/modifiers)
	if(charging)
		drop_charging()
	else
		return ..()


/mob/living/basic/frog/space/blue
	name = "dew frog"
	desc = "It has adapted to the dryness of space by secreting proteins that suck water out of the air"
	icon_state = "frog_blue"
	icon_living = "frog_blue"
	icon_dead = "frog_blue_dead"
	poison_type = /datum/reagent/water

/mob/living/basic/frog/space/blue/Initialize()
	. = ..()
	create_reagents(400, REAGENT_HOLDER_ALIVE)
	reagents.add_reagent(/datum/reagent/water, 400)
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(on_move))
	RegisterSignal(src, COMSIG_LIVING_REVIVE, PROC_REF(on_revive))

/mob/living/basic/frog/space/blue/Destroy()
	UnregisterSignal(src, list(COMSIG_MOVABLE_MOVED, COMSIG_LIVING_REVIVE))
	. = ..()

/mob/living/basic/frog/space/blue/proc/on_revive()
	SIGNAL_HANDLER
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(on_move), override=TRUE)

/mob/living/basic/frog/space/blue/Life(seconds_per_tick, times_fired)
	. = ..()
	reagents.add_reagent(/datum/reagent/water, 2)

/mob/living/basic/frog/space/blue/proc/on_move()
	SIGNAL_HANDLER
	if(stat)
		UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
		return
	var/turf/T = get_turf(loc)
	reagents.expose(T, TOUCH, 5)
	reagents.remove_all(5)

/datum/supply_pack/critter/space_frogs
	name = "Exotic Frog Crate"
	desc = "Three exotic frogs harvested from far away astroids! \
		Contains 3 random exotic frogs."
	cost = CARGO_CRATE_VALUE * 2
	contains = list(
		/obj/effect/spawner/random/space_frog = 3
	)
	crate_name = "frog crate"
