/obj/item/gun/ballistic/rifle/sniper_rifle/hristov
	name = "\improper Hristov"
	desc = "A long ranged weapon that does significant damage. Often found in the hands of Nanotrasen's snipers. Has an internal magazine."
	icon = 'surfshack13/icons/obj/weapons/guns/ballistic.dmi'
	icon_state = "Hristov"
	inhand_icon_state = "hristov"
	lefthand_file = 'surfshack13/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'surfshack13/icons/mob/inhands/weapons/guns_righthand.dmi'
	fire_sound_volume = 90
	vary_fire_sound = FALSE
	internal_magazine = TRUE
	recoil = 2
	rack_delay = 1 SECONDS
	weapon_weight = WEAPON_HEAVY
	accepted_magazine_type = /obj/item/ammo_box/magazine/internal/hristov
	spread = 0
	w_class = WEIGHT_CLASS_HUGE
	slot_flags = ITEM_SLOT_BACK
	actions_types = list()
	bolt_type = BOLT_TYPE_LOCKING
	bolt_locked = FALSE
	can_suppress = FALSE
	mag_display = FALSE
	tac_reloads = FALSE
	semi_auto = FALSE
	custom_price = 10000
	worn_icon = 'surfshack13/icons/mob/clothing/back.dmi'
	worn_icon_state = "Hristov"

/obj/item/gun/ballistic/rifle/sniper_rifle/hristov/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_CONTRABAND_EXCEPTION, INNATE_TRAIT)
	AddComponent(/datum/component/scope, range_modifier = 4)

/obj/item/gun/ballistic/rifle/sniper_rifle/hristov/freshprint
	pin = null
