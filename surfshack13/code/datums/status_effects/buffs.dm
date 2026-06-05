/datum/status_effect/regenerative_howl
	id = "regenerative_howl"
	duration = 1 MINUTES
	alert_type = /atom/movable/screen/alert/status_effect/regenerative_howl
	/// Whether we healed from our last tick
	var/healed_last_tick = FALSE

/datum/status_effect/regenerative_howl/tick(seconds_between_ticks)
	healed_last_tick = FALSE
	var/need_mob_update = FALSE

	if(owner.getBruteLoss() > 0)
		need_mob_update += owner.adjustBruteLoss(-0.5, updating_health = FALSE)
		healed_last_tick = TRUE

	if(owner.getFireLoss() > 0)
		need_mob_update += owner.adjustFireLoss(-0.5, updating_health = FALSE)
		healed_last_tick = TRUE

	if(owner.getToxLoss() > 0)
		// Forced, so slimepeople are healed as well.
		need_mob_update += owner.adjustToxLoss(-0.25, updating_health = FALSE, forced = TRUE)
		healed_last_tick = TRUE

	if(need_mob_update)
		owner.updatehealth()

	// Technically, "healed this tick" by now.
	if(healed_last_tick)
		new /obj/effect/temp_visual/heal(get_turf(owner), COLOR_RED)

	return ..()

/atom/movable/screen/alert/status_effect/regenerative_howl
	name = "Regenerative Howl"
	desc = "You succeeded in performing a Defensive Howl, and are slowly recouperating from any wounds."
	icon = 'surfshack13/icons/ui_icons/antags/werewolf/werewolf_ui.dmi'
	icon_state = "howl"
