/////////////////////////////////////
// WAND OF TWEAKING
/////////////////////////////////////

/obj/item/gun/magic/wand/tweak
	name = "wand of tweaking"
	desc = "shieet"
	fire_sound = 'sound/effects/magic/wandodeath.ogg'
	icon = 'icons/obj/weapons/guns/magic.dmi'
	ammo_type = /obj/item/ammo_casing/magic/tweak
	max_charges = 303 // molar mass of cocaine

/obj/item/gun/magic/wand/tweak/zap_self(mob/living/user)
	. = ..()
	//surfshack
	user.AddComponent(/datum/component/tweak, time= 5 MINUTES)

/obj/item/ammo_casing/magic/tweak
	projectile_type = /obj/projectile/magic/tweak


/obj/projectile/magic/tweak
	name = "bolt of tweaking"
	icon_state = "pulse1_bl"

/obj/projectile/magic/tweak/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	target.AddComponent(/datum/component/tweak, time= 5 MINUTES)

/obj/item/tweak_fragment
	name = "mysterious wand fragment"
	desc = "you swear you can you see it shake. It seems to be one of three"
	icon = 'icons/obj/weapons/guns/magic.dmi'
	icon_state = "fragment"
