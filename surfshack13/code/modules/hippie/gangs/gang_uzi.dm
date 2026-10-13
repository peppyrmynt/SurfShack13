// The gang shop's Uzi: Surf's Type U3 Uzi with an extra full-auto mode.
// The fire-mode button cycles burst -> full-auto -> semi-auto. Full-auto fires slower than a switched
// Glock but keeps much tighter spread.

#define UZI_MODE_BURST 1
#define UZI_MODE_AUTO 2
#define UZI_MODE_SEMI 3

/obj/item/gun/ballistic/automatic/mini_uzi/gang
	desc = "A lightweight submachine gun, for when you really want someone dead. This one has been converted to fire full-auto as well as bursts. Uses 9mm rounds."
	/// Current fire mode
	var/fire_mode = UZI_MODE_BURST
	/// Time between shots on full-auto (about 6.7 rounds a second)
	var/auto_fire_delay = 0.15 SECONDS
	/// Extra spread on full-auto
	var/auto_spread = 8

/obj/item/gun/ballistic/automatic/mini_uzi/gang/examine(mob/user)
	. = ..()
	var/mode_name = list("2-round burst", "full-auto", "semi-auto")[fire_mode]
	. += span_notice("It is set to <b>[mode_name]</b>. Use the fire-mode button to cycle burst, full-auto and semi-auto.")

/obj/item/gun/ballistic/automatic/mini_uzi/gang/burst_select()
	var/mob/user = usr
	fire_mode = fire_mode % 3 + 1
	qdel(GetComponent(/datum/component/automatic_fire))
	spread = initial(spread)
	switch(fire_mode)
		if(UZI_MODE_BURST)
			burst_fire_selection = TRUE
			burst_size = initial(burst_size)
			fire_delay = initial(fire_delay)
			balloon_alert(user, "switched to [burst_size]-round burst")
		if(UZI_MODE_AUTO)
			burst_fire_selection = FALSE
			burst_size = 1
			fire_delay = 0
			spread = initial(spread) + auto_spread
			AddComponent(/datum/component/automatic_fire, auto_fire_delay)
			balloon_alert(user, "switched to full-auto")
		if(UZI_MODE_SEMI)
			burst_fire_selection = FALSE
			burst_size = 1
			fire_delay = 0
			balloon_alert(user, "switched to semi-automatic")
	playsound(user, 'sound/items/weapons/empty.ogg', 100, TRUE)
	update_appearance()
	update_item_action_buttons()

#undef UZI_MODE_BURST
#undef UZI_MODE_AUTO
#undef UZI_MODE_SEMI
