/datum/status_effect/adrenaline_quirk
	id = "adrenaline_quirk"
	alert_type = /atom/movable/screen/alert/status_effect/adrenaline_quirk

/datum/status_effect/adrenaline_quirk/on_apply()
	. = ..()
	if(.)
		owner.add_movespeed_modifier(/datum/movespeed_modifier/status_effect/adrenaline_quirk)

/datum/status_effect/adrenaline_quirk/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/status_effect/adrenaline_quirk)

/atom/movable/screen/alert/status_effect/adrenaline_quirk
	name = "Adrenaline"
	desc = "Your wounds have resulted in your brain releasing a constant stream of adrenaline. You'll move about 20% faster."
	icon = 'icons/hud/implants.dmi'
	icon_state = "adrenal"
