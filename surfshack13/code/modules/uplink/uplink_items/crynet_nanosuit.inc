#define CRYNET_MODE_NONE "none"
#define CRYNET_MODE_ARMOR "armor"
#define CRYNET_MODE_CLOAK "cloak"
#define CRYNET_MODE_SPEED "speed"
#define CRYNET_MODE_STRENGTH "strength"

#define CRYNET_RECHARGE_DELAY (3 SECONDS)
#define CRYNET_EMP_RECHARGE_DELAY (9 SECONDS)
#define CRYNET_STRENGTH_JUMP_COST 30
#define CRYNET_POWER_PUNCH_COMBO "QQQ"
#define CRYNET_FINISH_COMBO "SSS"
#define CRYNET_HEAD_STOMP_COMBO "SSSS"

/obj/item/stock_parts/power_store/cell/bluespace/crynet
	name = "nanosuit self-charging battery"
	maxcharge = 100
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF | FREEZE_PROOF

/datum/armor/mod_theme_crynet
	melee = 40
	bullet = 40
	laser = 40
	energy = 45
	bomb = 70
	bio = 100
	fire = 100
	acid = 100

/datum/armor/crynet_armor_mode
	bomb = 20

/datum/armor/crynet_speed_mode
	melee = -15
	bullet = -15
	laser = -15

/datum/mod_theme/elite/crynet
	name = "CryNet nanosuit"
	desc = "An experimental adaptive combat suit manufactured by CryNet Systems for posthuman warfare."
	extended_desc = "CryNet's nanosuit routes its limited power reserve into one of four mutually exclusive configurations: maximum armor, optical camouflage, maximum speed, or maximum strength."
	armor_type = /datum/armor/mod_theme_crynet
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF | FREEZE_PROOF
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	siemens_coefficient = 0
	charge_drain = 0
	slowdown_inactive = 0.5
	slowdown_active = 0.5
	inbuilt_modules = list()

/datum/movespeed_modifier/crynet_speed
	multiplicative_slowdown = -0.25
	movetypes = GROUND

/datum/movespeed_modifier/crynet_speed/hacked
	multiplicative_slowdown = -1

/obj/item/mod/module/crynet_controller
	name = "CryNet nanosuit control system"
	desc = "The central control system for a CryNet nanosuit. It coordinates suit power, combat modes, medical systems, and threat response."
	removable = FALSE
	complexity = 0
	var/mode = CRYNET_MODE_NONE
	var/hacked = FALSE
	var/shutdown = FALSE
	var/upgrade_multiplier = 1
	var/critical_power = FALSE
	var/recharge_until = 0
	var/medical_charges = 3
	var/medical_cooldown = 0
	var/defrost_cooldown = 0
	var/trauma_message_cooldown = 0
	var/announced = FALSE
	var/cloak_suspended = FALSE
	var/datum/martial_art/crynet_strength/strength_style

/obj/item/mod/module/crynet_controller/Destroy()
	if(strength_style)
		QDEL_NULL(strength_style)
	return ..()

/obj/item/mod/module/crynet_controller/on_equip()
	if(!mod?.wearer)
		return
	ADD_TRAIT(mod, TRAIT_NODROP, REF(src))
	ADD_TRAIT(mod.wearer, TRAIT_NODISMEMBER, REF(src))
	ADD_TRAIT(mod.wearer, TRAIT_NO_SLIP_WATER, REF(src))
	if(!announced && is_station_level(mod.wearer.z))
		var/area/current_area = get_area(mod.wearer)
		priority_announce("[mod.wearer] has engaged [mod] at [current_area.name]!", "Message from The Syndicate!")
		mod.wearer.log_message("engaged [mod] at [current_area.name]", LOG_GAME)
		announced = TRUE
	to_chat(mod.wearer, span_notice("CryNet - UEFI v1.32 Syndicate Systems. P.O.S.T. commencing..."))

/obj/item/mod/module/crynet_controller/on_unequip()
	if(mod?.wearer)
		clear_mode_effects()
		REMOVE_TRAIT(mod.wearer, TRAIT_NODISMEMBER, REF(src))
		REMOVE_TRAIT(mod.wearer, TRAIT_NO_SLIP_WATER, REF(src))
		UnregisterSignal(mod.wearer, list(
			COMSIG_MOVABLE_MOVED,
			COMSIG_LIVING_CHECK_BLOCK,
			COMSIG_MOB_ITEM_ATTACK,
			COMSIG_LIVING_UNARMED_ATTACK,
			COMSIG_MOB_THROW,
			COMSIG_MOB_FIRED_GUN,
		))
	REMOVE_TRAIT(mod, TRAIT_NODROP, REF(src))
	mode = CRYNET_MODE_NONE

/obj/item/mod/module/crynet_controller/on_part_activation()
	if(!mod?.wearer)
		return
	RegisterSignal(mod.wearer, COMSIG_MOVABLE_MOVED, PROC_REF(on_wearer_moved))
	RegisterSignal(mod.wearer, COMSIG_LIVING_CHECK_BLOCK, PROC_REF(check_block))
	RegisterSignals(mod.wearer, list(
		COMSIG_MOB_ITEM_ATTACK,
		COMSIG_LIVING_UNARMED_ATTACK,
		COMSIG_MOB_THROW,
	), PROC_REF(break_cloak))
	RegisterSignal(mod.wearer, COMSIG_MOB_FIRED_GUN, PROC_REF(on_gun_fired))
	set_mode(CRYNET_MODE_ARMOR, TRUE)
	to_chat(mod.wearer, span_notice("CryNet P.O.S.T. complete. Maximum Armor engaged."))

/obj/item/mod/module/crynet_controller/on_part_deactivation(deleting = FALSE)
	if(mod?.wearer)
		clear_mode_effects()
		UnregisterSignal(mod.wearer, list(
			COMSIG_MOVABLE_MOVED,
			COMSIG_LIVING_CHECK_BLOCK,
			COMSIG_MOB_ITEM_ATTACK,
			COMSIG_LIVING_UNARMED_ATTACK,
			COMSIG_MOB_THROW,
			COMSIG_MOB_FIRED_GUN,
		))
	mode = CRYNET_MODE_NONE

/obj/item/mod/module/crynet_controller/on_process(seconds_per_tick)
	. = ..()
	if(!mod?.active || !mod.wearer || shutdown)
		return

	if(mode == CRYNET_MODE_CLOAK)
		drain_energy((6 / upgrade_multiplier) * seconds_per_tick)
	else if(world.time >= recharge_until && mod.get_charge() < mod.get_max_charge())
		mod.add_charge(20 * seconds_per_tick)
		update_power_state()

	if(mod.wearer.bodytemperature < BODYTEMP_COLD_DAMAGE_LIMIT && world.time >= defrost_cooldown)
		to_chat(mod.wearer, span_notice("CryNet: Activating suit defrosting protocols."))
		mod.wearer.reagents.add_reagent(/datum/reagent/medicine/leporazine, 3)
		defrost_cooldown = world.time + 12 SECONDS

	if(hacked && medical_charges > 0 && mod.wearer.health < HEALTH_THRESHOLD_CRIT + 15 && world.time >= medical_cooldown && prob(20))
		heal_wearer()

/obj/item/mod/module/crynet_controller/proc/set_mode(new_mode, forced = FALSE)
	if(!mod?.wearer || !mod.active || shutdown)
		return FALSE
	if(!forced && mode == new_mode)
		balloon_alert(mod.wearer, "mode already active!")
		return FALSE
	if(!forced && mod.get_charge() <= 0)
		balloon_alert(mod.wearer, "not enough charge!")
		return FALSE

	clear_mode_effects()
	mode = new_mode
	var/mob/living/carbon/human/wearer = mod.wearer

	switch(mode)
		if(CRYNET_MODE_ARMOR)
			apply_armor_modifier(/datum/armor/crynet_armor_mode)
			to_chat(wearer, span_notice("CryNet: Maximum Armor!"))

		if(CRYNET_MODE_CLOAK)
			ADD_TRAIT(wearer, TRAIT_LIGHT_STEP, REF(src))
			wearer.filters = filter(type = "blur", size = 1)
			animate(wearer, alpha = 40, time = 0.5 SECONDS)
			to_chat(wearer, span_notice("CryNet: Cloak Engaged!"))

		if(CRYNET_MODE_SPEED)
			apply_armor_modifier(/datum/armor/crynet_speed_mode)
			ADD_TRAIT(wearer, TRAIT_IGNORESLOWDOWN, REF(src))
			wearer.add_movespeed_modifier(hacked ? /datum/movespeed_modifier/crynet_speed/hacked : /datum/movespeed_modifier/crynet_speed)
			wearer.adjustOxyLoss(-5)
			wearer.adjustStaminaLoss(-20)
			to_chat(wearer, span_notice("CryNet: Maximum Speed!"))

		if(CRYNET_MODE_STRENGTH)
			ADD_TRAIT(wearer, TRAIT_PUSHIMMUNE, REF(src))
			if(!strength_style)
				strength_style = new
			if(!strength_style.teach(wearer, TRUE))
				to_chat(wearer, span_warning("CryNet: Unable to initialize strength combat routines while your current martial art is active."))
			to_chat(wearer, span_notice("CryNet: Maximum Strength!"))

	return TRUE

/obj/item/mod/module/crynet_controller/proc/clear_mode_effects()
	if(!mod?.wearer)
		return
	var/mob/living/carbon/human/wearer = mod.wearer

	switch(mode)
		if(CRYNET_MODE_ARMOR)
			remove_armor_modifier(/datum/armor/crynet_armor_mode)

		if(CRYNET_MODE_CLOAK)
			REMOVE_TRAIT(wearer, TRAIT_LIGHT_STEP, REF(src))
			wearer.filters = null
			animate(wearer, alpha = 255, time = 0.5 SECONDS)
			cloak_suspended = FALSE

		if(CRYNET_MODE_SPEED)
			remove_armor_modifier(/datum/armor/crynet_speed_mode)
			REMOVE_TRAIT(wearer, TRAIT_IGNORESLOWDOWN, REF(src))
			wearer.remove_movespeed_modifier(/datum/movespeed_modifier/crynet_speed)
			wearer.remove_movespeed_modifier(/datum/movespeed_modifier/crynet_speed/hacked)

		if(CRYNET_MODE_STRENGTH)
			REMOVE_TRAIT(wearer, TRAIT_PUSHIMMUNE, REF(src))
			if(strength_style)
				strength_style.fully_remove(wearer)

/obj/item/mod/module/crynet_controller/proc/apply_armor_modifier(datum/armor/armor_modifier)
	for(var/obj/item/part as anything in mod.get_parts(all = TRUE))
		part.set_armor(part.get_armor().add_other_armor(armor_modifier))

/obj/item/mod/module/crynet_controller/proc/remove_armor_modifier(datum/armor/armor_modifier)
	for(var/obj/item/part as anything in mod.get_parts(all = TRUE))
		part.set_armor(part.get_armor().subtract_other_armor(armor_modifier))

/obj/item/mod/module/crynet_controller/proc/drain_energy(amount, recharge_delay = 0)
	if(!mod || amount <= 0)
		return
	if(recharge_delay)
		recharge_until = max(recharge_until, world.time + recharge_delay)
	var/current_charge = mod.get_charge()
	if(current_charge <= 0)
		update_power_state()
		return
	mod.subtract_charge(min(amount, current_charge))
	update_power_state()

/obj/item/mod/module/crynet_controller/proc/update_power_state()
	if(!mod)
		return
	var/current_charge = mod.get_charge()
	if(current_charge < 20 && !critical_power)
		critical_power = TRUE
		if(mod.wearer)
			to_chat(mod.wearer, span_warning("CryNet: ENERGY CRITICAL!"))
	else if(current_charge >= 20)
		critical_power = FALSE

	if(current_charge <= 0 && mode != CRYNET_MODE_ARMOR && mode != CRYNET_MODE_NONE && mod.wearer)
		set_mode(CRYNET_MODE_ARMOR, TRUE)

/obj/item/mod/module/crynet_controller/proc/on_wearer_moved(datum/source, ...)
	SIGNAL_HANDLER
	if(mode == CRYNET_MODE_CLOAK)
		drain_energy(1.2 / upgrade_multiplier, CRYNET_RECHARGE_DELAY)
	else if(mode == CRYNET_MODE_SPEED)
		drain_energy(2 * upgrade_multiplier, CRYNET_RECHARGE_DELAY)

/obj/item/mod/module/crynet_controller/proc/break_cloak(datum/source, ...)
	SIGNAL_HANDLER
	if(mode != CRYNET_MODE_CLOAK || cloak_suspended)
		return
	reveal_cloak()
	drain_energy(mod.get_charge(), CRYNET_RECHARGE_DELAY)

/obj/item/mod/module/crynet_controller/proc/on_gun_fired(datum/source, obj/item/gun/gun, atom/firing_at, params, zone, bonus_spread_values)
	SIGNAL_HANDLER
	if(mode != CRYNET_MODE_CLOAK || cloak_suspended)
		return
	if(gun?.suppressed && mod.get_charge() > 15)
		cloak_suspended = TRUE
		reveal_cloak()
		drain_energy(15)
		addtimer(CALLBACK(src, PROC_REF(resume_cloak)), 0.6 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)
		return
	break_cloak(source)

/obj/item/mod/module/crynet_controller/proc/reveal_cloak()
	if(!mod?.wearer)
		return
	mod.wearer.filters = null
	animate(mod.wearer, alpha = 255, time = 0.1 SECONDS)

/obj/item/mod/module/crynet_controller/proc/resume_cloak()
	if(mode != CRYNET_MODE_CLOAK || !mod?.wearer || mod.get_charge() <= 0)
		cloak_suspended = FALSE
		return
	mod.wearer.filters = filter(type = "blur", size = 1)
	animate(mod.wearer, alpha = 40, time = 0.2 SECONDS)
	cloak_suspended = FALSE

/obj/item/mod/module/crynet_controller/proc/check_block(
	mob/living/carbon/human/owner,
	atom/movable/hitby,
	damage = 0,
	attack_text = "the attack",
	attack_type = MELEE_ATTACK,
	armour_penetration = 0,
	damage_type = BRUTE,
)
	SIGNAL_HANDLER

	if(mode == CRYNET_MODE_CLOAK)
		break_cloak(owner)

	check_trauma(owner)

	if(mode != CRYNET_MODE_ARMOR || mod.get_charge() <= 0)
		return NONE

	var/block_chance = hacked ? 65 : 50
	if(!prob(block_chance))
		return NONE

	var/power_cost = (5 + max(damage, 0)) * upgrade_multiplier
	if(istype(hitby, /obj/projectile/energy/electrode))
		power_cost = 35 * upgrade_multiplier
	else if(damage_type == STAMINA && attack_type == PROJECTILE_ATTACK)
		power_cost = 20 * upgrade_multiplier

	owner.visible_message(
		span_danger("[owner]'s CryNet armor deflects [attack_text], draining suit energy!"),
		span_userdanger("Your CryNet armor deflects [attack_text], draining suit energy!"),
	)
	drain_energy(power_cost, CRYNET_RECHARGE_DELAY)
	return SUCCESSFUL_BLOCK

/obj/item/mod/module/crynet_controller/proc/check_trauma(mob/living/carbon/human/wearer)
	if(world.time < trauma_message_cooldown)
		return
	for(var/obj/item/bodypart/bodypart as anything in wearer.bodyparts)
		if(bodypart.brute_dam <= 30 && bodypart.burn_dam <= 30)
			continue
		var/damage_name = bodypart.brute_dam > bodypart.burn_dam ? "blunt-force trauma" : "heat-shield failure"
		to_chat(wearer, span_warning("CryNet: [damage_name] detected in [bodypart.name]!"))
		trauma_message_cooldown = world.time + 20 SECONDS
		return

/obj/item/mod/module/crynet_controller/proc/heal_wearer()
	if(!mod?.wearer || medical_charges <= 0)
		return FALSE
	to_chat(mod.wearer, span_notice("CryNet: Engaging emergency medical protocols."))
	mod.wearer.reagents.add_reagent(/datum/reagent/medicine/syndicate_nanites, 1)
	medical_charges--
	medical_cooldown = world.time + 20 SECONDS
	return TRUE

/obj/item/mod/module/crynet_controller/proc/strength_jump()
	if(!mod?.wearer || mode != CRYNET_MODE_STRENGTH)
		if(mod?.wearer)
			balloon_alert(mod.wearer, "strength mode required!")
		return FALSE
	if(mod.get_charge() < CRYNET_STRENGTH_JUMP_COST)
		balloon_alert(mod.wearer, "not enough charge!")
		return FALSE

	var/jump_range = hacked ? 3 : 2
	var/atom/target = get_edge_target_turf(mod.wearer, mod.wearer.dir)
	drain_energy(CRYNET_STRENGTH_JUMP_COST, CRYNET_RECHARGE_DELAY)
	mod.wearer.visible_message(
		span_warning("[mod.wearer] launches forward with impossible strength!"),
		span_notice("You launch forward with the nanosuit's strength servos!"),
	)
	mod.wearer.throw_at(target, jump_range, 1, mod.wearer, spin = FALSE)
	return TRUE

/obj/item/mod/module/crynet_controller/proc/upgrade(mob/user)
	if(hacked)
		balloon_alert(user, "already upgraded!")
		return FALSE
	hacked = TRUE
	upgrade_multiplier = 1.5
	to_chat(user, span_warning("CryNet: Safety interlocks bypassed. Maximum performance unlocked."))
	if(mode == CRYNET_MODE_SPEED)
		set_mode(CRYNET_MODE_SPEED, TRUE)
	else if(mode == CRYNET_MODE_ARMOR)
		set_mode(CRYNET_MODE_ARMOR, TRUE)
	return TRUE

/obj/item/mod/module/crynet_controller/proc/handle_emp(severity)
	if(!mod?.wearer || shutdown || !severity)
		return
	drain_energy(mod.get_charge() / severity, CRYNET_EMP_RECHARGE_DELAY)
	if((mode == CRYNET_MODE_ARMOR && mod.get_charge() > 0))
		return
	if(prob(5 / severity))
		emp_assault()
	else if(prob(10 / severity))
		mod.wearer.adjust_confusion(10 SECONDS)

/obj/item/mod/module/crynet_controller/proc/emp_assault()
	if(!mod?.wearer || shutdown)
		return
	to_chat(mod.wearer, span_userdanger("CryNet: EMP ASSAULT! ALL SYSTEMS IMPAIRED!"))
	clear_mode_effects()
	mode = CRYNET_MODE_NONE
	shutdown = TRUE
	mod.wearer.adjust_confusion(5 SECONDS)
	mod.wearer.Paralyze(30 SECONDS)
	mod.wearer.adjust_jitter(12 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(recover_from_emp)), 15 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)

/obj/item/mod/module/crynet_controller/proc/recover_from_emp()
	if(!mod?.wearer)
		shutdown = FALSE
		return
	to_chat(mod.wearer, span_warning("CryNet: CMOS reset complete. Restoring core functions."))
	shutdown = FALSE
	set_mode(CRYNET_MODE_ARMOR, TRUE)

/obj/item/mod/module/crynet_mode
	name = "CryNet mode selector"
	desc = "Routes nanosuit power into one dedicated combat configuration."
	removable = FALSE
	complexity = 0
	module_type = MODULE_USABLE
	var/selected_mode = CRYNET_MODE_NONE

/obj/item/mod/module/crynet_mode/on_use()
	var/obj/item/mod/module/crynet_controller/controller = get_controller()
	if(!controller)
		balloon_alert(mod.wearer, "controller unavailable!")
		return
	controller.set_mode(selected_mode)

/obj/item/mod/module/crynet_mode/proc/get_controller()
	for(var/obj/item/mod/module/crynet_controller/controller as anything in mod.modules)
		return controller
	return null

/obj/item/mod/module/crynet_mode/armor
	name = "CryNet Maximum Armor"
	desc = "Routes suit power into defensive systems. Provides a 50% reactive block chance, increased to 65% when the suit is hacked."
	icon_state = "armor_booster"
	selected_mode = CRYNET_MODE_ARMOR

/obj/item/mod/module/crynet_mode/cloak
	name = "CryNet Cloak"
	desc = "Routes suit power into optical camouflage. Movement and combat actions consume additional suit energy."
	icon_state = "stealth"
	selected_mode = CRYNET_MODE_CLOAK

/obj/item/mod/module/crynet_mode/speed
	name = "CryNet Maximum Speed"
	desc = "Routes suit power into mobility systems, greatly increasing movement speed at the expense of armor and energy."
	icon_state = "status_speed"
	selected_mode = CRYNET_MODE_SPEED

/obj/item/mod/module/crynet_mode/strength
	name = "CryNet Maximum Strength"
	desc = "Routes suit power into strength augmentation, granting enhanced unarmed combat and powered jumping."
	icon_state = "strength"
	selected_mode = CRYNET_MODE_STRENGTH

/obj/item/mod/module/crynet_jump
	name = "CryNet Strength Jump"
	desc = "Launches the wearer across a short gap while Maximum Strength is active."
	icon_state = "jump_jet"
	removable = FALSE
	complexity = 0
	module_type = MODULE_USABLE
	cooldown_time = 1 SECONDS

/obj/item/mod/module/crynet_jump/on_use()
	var/obj/item/mod/module/crynet_controller/controller
	for(var/obj/item/mod/module/crynet_controller/candidate as anything in mod.modules)
		controller = candidate
		break
	if(!controller)
		balloon_alert(mod.wearer, "controller unavailable!")
		return
	controller.strength_jump()

/obj/item/mod/control/pre_equipped/crynet
	name = "CryNet nanosuit"
	desc = "A banned adaptive combat nanosuit. Once worn, it locks to its operator and broadcasts its activation on the station."
	theme = /datum/mod_theme/elite/crynet
	starting_frequency = MODLINK_FREQ_SYNDICATE
	applied_cell = /obj/item/stock_parts/power_store/cell/bluespace/crynet
	applied_modules = list(
		/obj/item/mod/module/crynet_controller,
		/obj/item/mod/module/crynet_mode/armor,
		/obj/item/mod/module/crynet_mode/cloak,
		/obj/item/mod/module/crynet_mode/speed,
		/obj/item/mod/module/crynet_mode/strength,
		/obj/item/mod/module/crynet_jump,
		/obj/item/mod/module/shock_absorber,
		/obj/item/mod/module/rad_protection,
		/obj/item/mod/module/jetpack,
		/obj/item/mod/module/visor/night,
	)
	default_pins = list(
		/obj/item/mod/module/crynet_mode/armor,
		/obj/item/mod/module/crynet_mode/cloak,
		/obj/item/mod/module/crynet_mode/speed,
		/obj/item/mod/module/crynet_mode/strength,
		/obj/item/mod/module/crynet_jump,
		/obj/item/mod/module/jetpack,
		/obj/item/mod/module/visor/night,
	)

/obj/item/mod/control/pre_equipped/crynet/emag_act(mob/user, obj/item/card/emag/emag_card)
	for(var/obj/item/mod/module/crynet_controller/controller as anything in modules)
		if(controller.upgrade(user))
			obj_flags |= EMAGGED
			return TRUE
	return FALSE

/obj/item/mod/control/pre_equipped/crynet/emp_act(severity)
	for(var/obj/item/mod/module/crynet_controller/controller as anything in modules)
		controller.handle_emp(severity)
		break
	return EMP_PROTECT_SELF

/datum/martial_art/crynet_strength
	name = "CryNet Strength Mode"
	id = "crynet_strength"
	max_streak_length = 4
	display_combos = TRUE

/datum/martial_art/crynet_strength/proc/check_streak(mob/living/attacker, mob/living/defender)
	if(findtext(streak, CRYNET_HEAD_STOMP_COMBO))
		reset_streak()
		return head_stomp(attacker, defender)
	if(findtext(streak, CRYNET_POWER_PUNCH_COMBO))
		reset_streak()
		return power_punch(attacker, defender)
	if(streak == CRYNET_FINISH_COMBO)
		to_chat(attacker, span_bolddanger("FINISH THEM!"))
	return FALSE

/datum/martial_art/crynet_strength/proc/power_punch(mob/living/attacker, mob/living/defender)
	attacker.do_attack_animation(defender)
	defender.apply_damage(20, BRUTE)
	defender.visible_message(
		span_danger("[attacker] power-punches [defender], sending [defender.p_them()] flying!"),
		span_userdanger("[attacker]'s powered punch sends you flying!"),
	)
	var/atom/throw_target = get_edge_target_turf(defender, get_dir(attacker, defender))
	defender.throw_at(throw_target, rand(1, 2), 7, attacker)
	log_combat(attacker, defender, "power punched (CryNet strength)")
	return TRUE

/datum/martial_art/crynet_strength/proc/head_stomp(mob/living/attacker, mob/living/defender)
	if(!iscarbon(defender) || defender.body_position != LYING_DOWN)
		return FALSE
	var/mob/living/carbon/carbon_defender = defender
	var/obj/item/bodypart/head = carbon_defender.get_bodypart(BODY_ZONE_HEAD)
	if(!head)
		return FALSE
	attacker.do_attack_animation(defender)
	defender.visible_message(
		span_danger("[attacker] brings a nanosuit-assisted stomp down on [defender]'s head!"),
		span_userdanger("[attacker] crushes your head under a powered stomp!"),
	)
	head.dismember()
	defender.apply_damage(40, BRUTE, BODY_ZONE_HEAD, wound_bonus = CANT_WOUND)
	if(!HAS_TRAIT(defender, TRAIT_NODEATH))
		defender.death()
	log_combat(attacker, defender, "performed a CryNet head stomp on")
	return TRUE

/datum/martial_art/crynet_strength/grab_act(mob/living/attacker, mob/living/defender)
	if(attacker == defender)
		return MARTIAL_ATTACK_INVALID
	if(defender.check_block(attacker, 0, attacker.name, UNARMED_ATTACK))
		return MARTIAL_ATTACK_FAIL

	var/old_grab_state = attacker.grab_state
	defender.grabbedby(attacker, TRUE)
	if(old_grab_state == GRAB_PASSIVE)
		attacker.setGrabState(GRAB_AGGRESSIVE)
		log_combat(attacker, defender, "grabbed", addition = "aggressively with CryNet strength")
	return MARTIAL_ATTACK_SUCCESS

/datum/martial_art/crynet_strength/disarm_act(mob/living/attacker, mob/living/defender)
	if(defender.check_block(attacker, 0, attacker.name, UNARMED_ATTACK))
		return MARTIAL_ATTACK_FAIL
	if(!prob(70))
		to_chat(attacker, span_warning("Your powered disarm misses!"))
		return MARTIAL_ATTACK_FAIL

	var/obj/item/held_item = defender.get_active_held_item()
	if(held_item && defender.temporarilyRemoveItemFromInventory(held_item))
		attacker.put_in_hands(held_item)
	defender.Paralyze(4 SECONDS)
	defender.visible_message(
		span_danger("[attacker] violently knocks [defender] off balance with the nanosuit!"),
		span_userdanger("[attacker]'s powered shove sends you reeling!"),
	)
	log_combat(attacker, defender, "power disarmed (CryNet strength)")
	return MARTIAL_ATTACK_SUCCESS

/datum/martial_art/crynet_strength/harm_act(mob/living/attacker, mob/living/defender)
	if(defender.check_block(attacker, 10, attacker.name, UNARMED_ATTACK))
		return MARTIAL_ATTACK_FAIL

	var/bonus_damage = 10

	if(attacker.resting && defender.body_position == STANDING_UP)
		attacker.do_attack_animation(defender)
		defender.apply_damage(15, BRUTE)
		defender.Paralyze(6 SECONDS)
		defender.visible_message(
			span_danger("[attacker] sweeps [defender]'s legs with powered force!"),
			span_userdanger("[attacker] sweeps your legs out from under you!"),
		)
		log_combat(attacker, defender, "leg swept (CryNet strength)")
		reset_streak()
		return MARTIAL_ATTACK_SUCCESS

	if(defender.body_position == LYING_DOWN)
		bonus_damage += 5
		if(attacker.zone_selected == BODY_ZONE_HEAD && iscarbon(defender))
			var/mob/living/carbon/carbon_defender = defender
			if(carbon_defender.get_bodypart(BODY_ZONE_HEAD))
				bonus_damage += 5
				carbon_defender.adjustOrganLoss(ORGAN_SLOT_BRAIN, 10)
				if(defender.health <= 40)
					add_to_streak("S", defender)
					if(check_streak(attacker, defender))
						return MARTIAL_ATTACK_SUCCESS

	if(attacker.pulling == defender)
		if(attacker.grab_state >= GRAB_KILL)
			bonus_damage += 10
			defender.Paralyze(6 SECONDS)
			var/atom/throw_target = get_edge_target_turf(defender, get_dir(attacker, defender))
			defender.throw_at(throw_target, 1, 7, attacker)
		else if(attacker.grab_state >= GRAB_AGGRESSIVE)
			bonus_damage += 5
			defender.Paralyze(1.5 SECONDS)

	attacker.do_attack_animation(defender)
	defender.apply_damage(bonus_damage, BRUTE)
	playsound(defender, 'sound/effects/hit_punch.ogg', 50, TRUE)

	if(prob(30))
		attacker.changeNext_move(CLICK_CD_RAPID)
		add_to_streak("Q", defender)
		if(check_streak(attacker, defender))
			return MARTIAL_ATTACK_SUCCESS
	else if(prob(35))
		cleave(attacker, defender)

	log_combat(attacker, defender, "punched (CryNet strength)")
	return MARTIAL_ATTACK_SUCCESS

/datum/martial_art/crynet_strength/proc/cleave(mob/living/attacker, mob/living/primary_target)
	for(var/mob/living/nearby in orange(1, attacker))
		if(nearby == attacker || nearby == primary_target || nearby.stat == DEAD)
			continue
		if(get_dir(attacker, nearby) != attacker.dir)
			continue
		nearby.apply_damage(10, BRUTE)
		nearby.visible_message(span_danger("[attacker]'s powered swing catches [nearby] as well!"))

#undef CRYNET_MODE_NONE
#undef CRYNET_MODE_ARMOR
#undef CRYNET_MODE_CLOAK
#undef CRYNET_MODE_SPEED
#undef CRYNET_MODE_STRENGTH
#undef CRYNET_RECHARGE_DELAY
#undef CRYNET_EMP_RECHARGE_DELAY
#undef CRYNET_STRENGTH_JUMP_COST
#undef CRYNET_POWER_PUNCH_COMBO
#undef CRYNET_FINISH_COMBO
#undef CRYNET_HEAD_STOMP_COMBO
