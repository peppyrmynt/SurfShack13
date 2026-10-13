/// An admin-spawned marine Flood. The marine states are in the existing Halo Flood combat DMI.
/mob/living/basic/flood/combat_form/human/rocket
	name = "Flood Rocket"
	desc = "A Flood-infested marine carrying a rocket launcher."
	icon_state = "marine_infested"
	icon_living = "marine_infested"
	icon_dead = "marine_dead"

/mob/living/basic/flood/combat_form/human/rocket/Initialize(mapload)
	. = ..()
	// This is a special admin spawn, not an ordinary ghost spawner or evolution choice.
	qdel(GetComponent(/datum/component/ghost_direct_control))
	INVOKE_ASYNC(src, PROC_REF(equip_rocket_launcher))

/mob/living/basic/flood/combat_form/human/rocket/get_flood_actions()
	. = ..()
	. -= /datum/action/cooldown/flood/evolve

/mob/living/basic/flood/combat_form/human/rocket/proc/equip_rocket_launcher()
	if(QDELETED(src) || stat == DEAD)
		return
	var/obj/item/gun/ballistic/rocketlauncher/unrestricted/flood/launcher = new(src)
	if(!put_in_hands(launcher))
		launcher.forceMove(drop_location())

/// Its station rocket launcher replenishes one low-yield rocket after each shot.
/obj/item/ammo_box/magazine/internal/rocketlauncher/flood
	ammo_type = /obj/item/ammo_casing/rocket/weak

/obj/item/gun/ballistic/rocketlauncher/unrestricted/flood
	name = "Flood rocket launcher"
	spawn_magazine_type = /obj/item/ammo_box/magazine/internal/rocketlauncher/flood
	backblast = FALSE

/obj/item/gun/ballistic/rocketlauncher/unrestricted/flood/try_fire_gun(atom/target, mob/living/user, params)
	. = ..()
	if(.)
		addtimer(CALLBACK(src, PROC_REF(reload_flood_rocket)), 12 SECONDS, TIMER_UNIQUE)

/obj/item/gun/ballistic/rocketlauncher/unrestricted/flood/proc/reload_flood_rocket()
	var/mob/living/basic/flood/combat_form/human/rocket/owner = loc
	if(!istype(owner) || owner.stat == DEAD)
		return
	instant_reload()
