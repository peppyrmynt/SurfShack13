/// A finite, non-regenerating shield pool, attached to the body rather than the mind.
/datum/status_effect/potion_shield
	id = "potion_shield"
	tick_interval = STATUS_EFFECT_NO_TICK
	alert_type = /atom/movable/screen/alert/status_effect/potion_shield
	remove_on_fullheal = TRUE
	var/shield = 0
	/// Rate-limit feedback from spread damage and pellets, without dropping absorption.
	var/next_hit_feedback = 0
	var/hit_sound = 'sound/effects/shield_potion/hit.ogg'
	var/break_sound = 'sound/effects/shield_potion/break.ogg'

/datum/status_effect/potion_shield/on_apply()
	if(!iscarbon(owner) || owner.stat == DEAD)
		return FALSE
	RegisterSignal(owner, COMSIG_CARBON_PRE_WOUND_DAMAGE, PROC_REF(absorb_damage))
	RegisterSignal(owner, COMSIG_LIVING_DEATH, PROC_REF(on_death))
	return TRUE

/datum/status_effect/potion_shield/on_remove()
	UnregisterSignal(owner, list(COMSIG_CARBON_PRE_WOUND_DAMAGE, COMSIG_LIVING_DEATH))

/datum/status_effect/potion_shield/proc/on_death(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/// The mutable damage packet has already passed armor and limb/species modifiers.
/// Consume both types proportionally so neither wins solely because of processing order.
/datum/status_effect/potion_shield/proc/absorb_damage(datum/source, list/damage_packet)
	SIGNAL_HANDLER
	var/total = damage_packet[BRUTE] + damage_packet[BURN]
	if(total <= 0 || shield <= 0)
		return
	var/absorbed = min(shield, total)
	var/remainder = (total - absorbed) / total
	damage_packet[BRUTE] *= remainder
	damage_packet[BURN] *= remainder
	shield = max(0, shield - absorbed)
	if(shield <= 0)
		new /obj/effect/temp_visual/potion_shield/breaking(get_turf(owner))
		playsound(owner, break_sound, 55, FALSE)
		to_chat(owner, span_warning("Your shield breaks!"))
		qdel(src)
		return
	if(world.time >= next_hit_feedback)
		new /obj/effect/temp_visual/potion_shield(get_turf(owner))
		playsound(owner, hit_sound, 35, FALSE)
		next_hit_feedback = world.time + 0.15 SECONDS
	update_counter()

/datum/status_effect/potion_shield/proc/update_counter()
	if(linked_alert)
		linked_alert.desc = "[round(shield, 0.1)]/100 shield. Absorbs brute and burn damage; does not regenerate."
		linked_alert.maptext = MAPTEXT_TINY_UNICODE("<span style='text-align:center;color:#66ddff'>[ceil(shield)]</span>")

/mob/living/carbon/proc/get_potion_shield()
	var/datum/status_effect/potion_shield/shield_effect = has_status_effect(/datum/status_effect/potion_shield)
	return shield_effect?.shield || 0

/// Returns shield actually added. A mini never reduces an existing pool above 50.
/mob/living/carbon/proc/add_potion_shield(amount, cap = 100)
	if(stat == DEAD || amount <= 0)
		return 0
	cap = clamp(cap, 0, 100)
	var/old_shield = get_potion_shield()
	if(old_shield >= cap)
		return 0
	var/datum/status_effect/potion_shield/shield_effect = has_status_effect(/datum/status_effect/potion_shield)
	if(!shield_effect)
		shield_effect = apply_status_effect(/datum/status_effect/potion_shield)
	if(!shield_effect)
		return 0
	shield_effect.shield = min(cap, old_shield + amount)
	shield_effect.update_counter()
	return shield_effect.shield - old_shield

/atom/movable/screen/alert/status_effect/potion_shield
	name = "Shield"
	desc = "A finite shield against brute and burn damage."
	icon = 'icons/effects/effects.dmi'
	icon_state = "m_shield"

/// Visible to everyone at the impact, never present while merely shielded.
/obj/effect/temp_visual/potion_shield
	icon = 'icons/effects/effects.dmi'
	icon_state = "m_shield"
	randomdir = FALSE
	duration = 0.4 SECONDS

/obj/effect/temp_visual/potion_shield/Initialize(mapload)
	. = ..()
	animate(src, alpha = 0, time = duration)

/obj/effect/temp_visual/potion_shield/breaking
	icon_state = "shield-greyscale"
	color = "#55DFFF"
	duration = 0.6 SECONDS

/obj/effect/temp_visual/potion_shield/breaking/Initialize(mapload)
	. = ..()
	add_overlay(mutable_appearance(icon, "shieldsparkles"))
	animate(src, transform = matrix() * 1.4, alpha = 0, time = duration)
