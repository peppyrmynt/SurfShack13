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

/// A primed grenade must leave the Flood's hand when a target is in throw range.
/datum/unit_test/flood_combat_throws_grenade

/datum/unit_test/flood_combat_throws_grenade/Run()
	var/mob/living/basic/flood/combat_form/human/flood = allocate(/mob/living/basic/flood/combat_form/human)
	var/mob/living/carbon/human/consistent/target = allocate(/mob/living/carbon/human/consistent)
	var/obj/item/grenade/grenade = allocate(/obj/item/grenade)
	grenade.det_time = 30 SECONDS
	target.forceMove(get_step(get_step(flood, EAST), EAST))
	TEST_ASSERT(flood.put_in_hands(grenade), "The Flood could not pick up the grenade.")
	TEST_ASSERT(flood.activate_weapon(target), "The Flood failed to prime the grenade.")
	TEST_ASSERT(grenade.active, "The grenade was not armed.")
	TEST_ASSERT(flood.RangedAttack(target), "The Flood did not throw the primed grenade.")
	TEST_ASSERT(!flood.is_holding(grenade), "The Flood kept holding the primed grenade.")
	TEST_ASSERT_EQUAL(flood.recent_thrown_grenade, grenade, "The Flood did not track the live grenade to flee it.")
	TEST_ASSERT_EQUAL(flood.weapon_score(grenade), 0, "The Flood tried to recover its thrown grenade.")
	TEST_ASSERT(flood.grenade_flee_until > world.time, "The Flood did not begin avoiding its grenade.")

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
