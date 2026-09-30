// Glock 17 - ported from HippieStation, with new sprites.
// Every Glock comes with a "switch" fitted: the fire-mode button flips it between accurate
// semi-auto and very fast full-auto that sprays badly.

/obj/item/gun/ballistic/automatic/pistol/g17
	name = "Glock 17"
	desc = "A classic 9mm handgun with a large magazine capacity. This one has an illegal auto sear, a \"switch\", fitted to the back of the slide."
	icon = 'surfshack13/icons/hippie/glock17.dmi'
	icon_state = "glock17"
	base_icon_state = "glock17"
	accepted_magazine_type = /obj/item/ammo_box/magazine/g17
	show_bolt_icon = FALSE
	mag_display = FALSE
	actions_types = list(/datum/action/item_action/toggle_firemode)
	/// Hippie's two alternating shot sounds
	var/list/glock_fire_sounds = list('surfshack13/sound/hippie/pistol_glock17_1.ogg', 'surfshack13/sound/hippie/pistol_glock17_2.ogg')
	/// Whether the switch is flipped to full-auto
	var/switch_on = FALSE
	/// Time between shots on full-auto (10 rounds a second)
	var/switch_fire_delay = 0.1 SECONDS
	/// Extra spread while on full-auto
	var/switch_spread = 22
	/// Extra recoil while on full-auto
	var/switch_recoil = 0.6

/obj/item/gun/ballistic/automatic/pistol/g17/examine(mob/user)
	. = ..()
	. += span_notice("The switch is set to <b>[switch_on ? "full-auto" : "semi-auto"]</b>. Use the fire-mode button to flip it.")

/obj/item/gun/ballistic/automatic/pistol/g17/burst_select()
	var/mob/user = usr
	switch_on = !switch_on
	if(switch_on)
		AddComponent(/datum/component/automatic_fire, switch_fire_delay)
		spread = initial(spread) + switch_spread
		recoil = initial(recoil) + switch_recoil
		balloon_alert(user, "switch on: full-auto")
	else
		qdel(GetComponent(/datum/component/automatic_fire))
		spread = initial(spread)
		recoil = initial(recoil)
		balloon_alert(user, "switch off: semi-auto")
	playsound(src, 'sound/machines/click.ogg', 60, TRUE)
	update_item_action_buttons()

/obj/item/gun/ballistic/automatic/pistol/g17/update_icon_state()
	. = ..()
	// the slide locks back on an empty magazine
	icon_state = "[base_icon_state][bolt_locked ? "-e" : ""][suppressed ? "-suppressed" : ""]"

// The suppressed sprite is wider than a tile: the end of the suppressor is an overlay one tile to the right.
/obj/item/gun/ballistic/automatic/pistol/g17/update_overlays()
	. = ..()
	if(suppressed)
		var/mutable_appearance/suppressor_end = mutable_appearance(icon, "[icon_state]_overflow")
		suppressor_end.pixel_x = 32
		. += suppressor_end

/obj/item/gun/ballistic/automatic/pistol/g17/fire_sounds()
	if(suppressed)
		return ..()
	playsound(src, pick(glock_fire_sounds), fire_sound_volume, vary_fire_sound)

/obj/item/gun/ballistic/automatic/pistol/g17/no_mag
	spawnwithmagazine = FALSE

/obj/item/ammo_box/magazine/g17
	name = "Glock 17 magazine (9mm)"
	desc = "A 14-round 9mm magazine for the Glock 17."
	icon = 'surfshack13/icons/hippie/glock17.dmi'
	icon_state = "g17-full"
	base_icon_state = "g17"
	ammo_type = /obj/item/ammo_casing/c9mm
	caliber = CALIBER_9MM
	max_ammo = 14
	multiple_sprites = AMMO_BOX_FULL_EMPTY
	multiple_sprite_use_base = TRUE

/obj/item/storage/box/syndie_kit/glock17
	name = "Glock Seventeen with spare ammo"

/obj/item/storage/box/syndie_kit/glock17/PopulateContents()
	new /obj/item/gun/ballistic/automatic/pistol/g17(src)
	for(var/i in 1 to 3)
		new /obj/item/ammo_box/magazine/g17(src)

/datum/uplink_item/dangerous/g17
	name = "Glock 17 Handgun"
	desc = "A simple yet popular handgun chambered in 9mm. Made out of strong but lightweight polymer. \
		Comes loaded with one 14-round magazine; spare magazines are sold separately. Compatible with a universal suppressor. \
		Has a \"switch\" fitted that turns it into a very fast but wildly inaccurate full-auto."
	item = /obj/item/gun/ballistic/automatic/pistol/g17
	cost = 10
	surplus = 15
	purchasable_from = UPLINK_TRAITORS | UPLINK_SERIOUS_OPS

/datum/uplink_item/ammo/g17
	name = "9mm Glock Magazine"
	desc = "An additional 14-round 9mm magazine; compatible with the Glock 17 pistol."
	item = /obj/item/ammo_box/magazine/g17
	cost = 1
	purchasable_from = UPLINK_TRAITORS | UPLINK_SERIOUS_OPS
