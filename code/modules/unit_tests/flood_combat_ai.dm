/// AI combat forms should wield a scavenged axe and actually strike with it.
/datum/unit_test/flood_combat_uses_axe

/datum/unit_test/flood_combat_uses_axe/Run()
	var/mob/living/basic/flood/combat_form/human/flood = allocate(/mob/living/basic/flood/combat_form/human)
	var/mob/living/carbon/human/consistent/target = allocate(/mob/living/carbon/human/consistent)
	var/obj/item/fireaxe/axe = allocate(/obj/item/fireaxe)
	target.forceMove(get_step(flood, EAST))
	TEST_ASSERT(flood.put_in_hands(axe), "The Flood could not pick up the fire axe.")
	TEST_ASSERT(flood.should_activate_weapon(target), "The Flood did not recognize the axe needed wielding.")
	TEST_ASSERT(flood.activate_weapon(target), "The Flood failed to activate the axe.")
	TEST_ASSERT(HAS_TRAIT(axe, TRAIT_WIELDED), "The axe was not wielded.")
	var/previous_damage = target.getBruteLoss()
	flood.melee_attack(target)
	TEST_ASSERT(target.getBruteLoss() > previous_damage, "The Flood did not attack with the held axe.")

/// An unarmed Flood must scavenge a grenade during combat, then prime and throw it.
/datum/unit_test/flood_combat_throws_grenade

/datum/unit_test/flood_combat_throws_grenade/Run()
	var/mob/living/basic/flood/combat_form/human/flood = allocate(/mob/living/basic/flood/combat_form/human)
	var/mob/living/carbon/human/consistent/target = allocate(/mob/living/carbon/human/consistent)
	var/obj/item/grenade/grenade = allocate(/obj/item/grenade)
	grenade.det_time = 30 SECONDS
	target.forceMove(get_step(get_step(flood, NORTH), NORTH))
	grenade.forceMove(get_step(get_step(flood, EAST), EAST))
	var/datum/ai_controller/controller = flood.ai_controller
	controller.set_ai_status(AI_STATUS_ON)
	controller.can_idle = FALSE
	controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, target)
	controller.SelectBehaviors(1)
	TEST_ASSERT_EQUAL(flood.recovery_target, grenade, "An unarmed Flood ignored a grenade two tiles away while targeting an enemy.")
	TEST_ASSERT_EQUAL(controller.current_movement_target, grenade, "The Flood did not move toward its chosen grenade.")
	flood.forceMove(get_step(grenade, WEST))
	// Target acquisition runs first, followed by the queued weapon recovery.
	controller.process(1)
	controller.process(1)
	TEST_ASSERT(flood.is_holding(grenade), "The Flood AI failed to pick up the grenade after reaching it.")
	TEST_ASSERT(flood.activate_weapon(target), "The Flood failed to prime the grenade.")
	TEST_ASSERT(grenade.active, "The grenade was not armed.")
	TEST_ASSERT(flood.RangedAttack(target), "The Flood did not throw the primed grenade.")
	TEST_ASSERT(!flood.is_holding(grenade), "The Flood kept holding the primed grenade.")
	TEST_ASSERT_EQUAL(flood.recent_thrown_grenade, grenade, "The Flood did not track the live grenade to flee it.")
	TEST_ASSERT_EQUAL(flood.weapon_score(grenade), 0, "The Flood tried to recover its thrown grenade.")
	TEST_ASSERT(flood.grenade_flee_until > world.time, "The Flood did not begin avoiding its grenade.")

/// Scavenging must prefer loaded guns, then grenades, then usable melee weapons.
/datum/unit_test/flood_combat_weapon_priority

/datum/unit_test/flood_combat_weapon_priority/Run()
	var/mob/living/basic/flood/combat_form/human/flood = allocate(/mob/living/basic/flood/combat_form/human)
	var/obj/item/gun/ballistic/automatic/pistol/gun = allocate(/obj/item/gun/ballistic/automatic/pistol)
	var/obj/item/grenade/grenade = allocate(/obj/item/grenade)
	var/obj/item/fireaxe/axe = allocate(/obj/item/fireaxe)
	var/obj/item/crowbar/weak_weapon = allocate(/obj/item/crowbar)
	weak_weapon.force = 15
	weak_weapon.throwforce = 15
	TEST_ASSERT_EQUAL(flood.find_recovery_weapon(), gun, "The Flood did not prioritize the loaded gun.")
	TEST_ASSERT(flood.recover_weapon(gun), "The Flood could not recover its preferred gun.")
	TEST_ASSERT_NULL(flood.find_recovery_weapon(), "A Flood holding a loaded gun tried to downgrade to a grenade or melee weapon.")
	qdel(gun)
	TEST_ASSERT_EQUAL(flood.find_recovery_weapon(), grenade, "The Flood did not prioritize the grenade over melee weapons.")
	// Even an unusually strong melee weapon must not outrank a grenade.
	axe.force = 1000
	TEST_ASSERT_EQUAL(flood.find_recovery_weapon(), grenade, "A high-damage melee weapon incorrectly outranked a grenade.")
	axe.force = initial(axe.force)
	qdel(grenade)
	TEST_ASSERT_EQUAL(flood.find_recovery_weapon(), axe, "The Flood ignored an unwielded axe despite its useful wielded damage.")
	qdel(axe)
	TEST_ASSERT_NULL(flood.find_recovery_weapon(), "The Flood selected a weapon that only deals 15 damage.")

/// A controlled Flood Combat can enable the HUD throw button and throw a held item.
/datum/unit_test/flood_combat_player_throw

/datum/unit_test/flood_combat_player_throw/Run()
	var/mob/living/basic/flood/combat_form/human/flood = allocate(/mob/living/basic/flood/combat_form/human)
	var/obj/item/crowbar/weapon = allocate(/obj/item/crowbar)
	TEST_ASSERT_NOTNULL(flood.hud_used?.throw_icon, "The Flood HUD has no throw button.")
	TEST_ASSERT(flood.put_in_hands(weapon), "The Flood could not hold the throwing weapon.")
	flood.toggle_flood_throw_mode()
	TEST_ASSERT(flood.throw_mode, "The Flood did not enter throw mode.")
	TEST_ASSERT(flood.throw_item(get_step(flood, EAST)), "The Flood could not throw the held weapon.")
	TEST_ASSERT(!flood.throw_mode && !flood.is_holding(weapon), "Throw mode or the held weapon was not cleared.")
