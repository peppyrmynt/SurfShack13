/// The Flood hive recoils when its overseer dies. The four-minute penalty also
/// gates promotion of a successor, even for constructors spawned afterward.
/datum/movespeed_modifier/flood_overseer_loss
	multiplicative_slowdown = 0.5

/datum/status_effect/flood_overseer_loss
	id = "flood_overseer_loss"
	tick_interval = STATUS_EFFECT_NO_TICK
	alert_type = /atom/movable/screen/alert/status_effect/flood_overseer_loss
	show_duration = TRUE

/datum/status_effect/flood_overseer_loss/on_creation(mob/living/new_owner, remaining = 4 MINUTES)
	duration = remaining
	return ..()

/datum/status_effect/flood_overseer_loss/on_apply()
	if(owner.stat == DEAD)
		return FALSE
	to_chat(owner, span_userdanger("The overseer has fallen! The hive recoils in pain and the Flood Chorus falls silent."))
	owner.Stun(10 SECONDS)
	owner.add_movespeed_modifier(/datum/movespeed_modifier/flood_overseer_loss)
	return TRUE

/datum/status_effect/flood_overseer_loss/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/flood_overseer_loss)
	if(owner.stat != DEAD)
		to_chat(owner, span_notice("The hive recovers. A constructor may now become the new overseer."))

/atom/movable/screen/alert/status_effect/flood_overseer_loss
	name = "Severed Flood Chorus"
	desc = "The overseer has died. The hive is slowed and cannot appoint another overseer until this fades."
	icon_state = ALERT_XENO_NOQUEEN
