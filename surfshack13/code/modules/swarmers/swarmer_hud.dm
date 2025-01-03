/atom/movable/screen/swarmer_resource_counter
	icon = 'icons/hud/screen_alien.dmi'
	icon_state = "power_display"
	name = "resources"
	screen_loc = ui_alienplasmadisplay

/datum/hud/living/swarmer/New(mob/living/basic/swarmer/owner)
	..()

	alien_plasma_display = new /atom/movable/screen/swarmer_resource_counter(null, src)
	infodisplay += alien_plasma_display
