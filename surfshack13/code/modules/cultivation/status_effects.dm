// Status effects used by cultivation techniques. No alerts; the visuals and chat messages say enough.

/datum/status_effect/cultivation_slow
	id = "cultivation_slow"
	alert_type = null
	status_type = STATUS_EFFECT_REFRESH

/datum/status_effect/cultivation_slow/on_creation(mob/living/new_owner, duration = 4 SECONDS)
	src.duration = duration
	return ..()

/datum/status_effect/cultivation_slow/on_apply()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/status_effect/cultivation_slow)
	return TRUE

/datum/status_effect/cultivation_slow/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/status_effect/cultivation_slow)

/datum/movespeed_modifier/status_effect/cultivation_slow
	multiplicative_slowdown = 1.5

// ----- Still Water Ward: absorbs a pool of damage -----

/datum/status_effect/still_water_ward
	id = "still_water_ward"
	alert_type = null
	duration = 20 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	var/absorb_left = 30

/datum/status_effect/still_water_ward/on_apply()
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, PROC_REF(absorb))
	owner.add_filter("still_water_ward", 2, list("type" = "outline", "color" = "#4fb3ff", "size" = 1))
	return TRUE

/datum/status_effect/still_water_ward/refresh(effect, ...)
	absorb_left = initial(absorb_left)
	return ..()

/datum/status_effect/still_water_ward/on_remove()
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS)
	owner.remove_filter("still_water_ward")
	to_chat(owner, span_notice("The still water around you ripples away."))

/datum/status_effect/still_water_ward/proc/absorb(mob/living/source, list/damage_mods, damage, damagetype, ...)
	SIGNAL_HANDLER
	if(damage <= 0 || !(damagetype in list(BRUTE, BURN)))
		return
	var/absorbed = min(absorb_left, damage)
	absorb_left -= absorbed
	damage_mods += (damage - absorbed) / damage
	if(absorb_left <= 0)
		qdel(src)

// ----- Golden Bell: nearly invulnerable, rooted in place -----

/datum/status_effect/golden_bell
	id = "golden_bell"
	alert_type = null
	duration = 5 SECONDS

/datum/status_effect/golden_bell/on_apply()
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, PROC_REF(ring))
	owner.add_traits(list(TRAIT_IMMOBILIZED, TRAIT_PUSHIMMUNE), TRAIT_STATUS_EFFECT(id))
	owner.add_filter("golden_bell", 2, list("type" = "outline", "color" = "#ffcc33", "size" = 2))
	return TRUE

/datum/status_effect/golden_bell/on_remove()
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS)
	owner.remove_traits(list(TRAIT_IMMOBILIZED, TRAIT_PUSHIMMUNE), TRAIT_STATUS_EFFECT(id))
	owner.remove_filter("golden_bell")

/datum/status_effect/golden_bell/proc/ring(mob/living/source, list/damage_mods, damage, damagetype, ...)
	SIGNAL_HANDLER
	if(damagetype in list(BRUTE, BURN))
		damage_mods += 0.2
		playsound(owner, 'sound/effects/gong.ogg', 30, TRUE)

// ----- Rooted Stance -----

/datum/status_effect/rooted_stance
	id = "rooted_stance"
	alert_type = null
	duration = 10 SECONDS

/datum/status_effect/rooted_stance/on_apply()
	owner.add_traits(list(TRAIT_IMMOBILIZED, TRAIT_PUSHIMMUNE, TRAIT_NO_SLIP_ALL), TRAIT_STATUS_EFFECT(id))
	owner.move_resist = MOVE_FORCE_OVERPOWERING
	owner.add_filter("rooted_stance", 2, list("type" = "outline", "color" = "#8a6b3d", "size" = 1))
	return TRUE

/datum/status_effect/rooted_stance/on_remove()
	owner.remove_traits(list(TRAIT_IMMOBILIZED, TRAIT_PUSHIMMUNE, TRAIT_NO_SLIP_ALL), TRAIT_STATUS_EFFECT(id))
	owner.move_resist = initial(owner.move_resist)
	owner.remove_filter("rooted_stance")
	to_chat(owner, span_notice("You lift your roots from the ground."))

// ----- Sword Riding -----

/datum/status_effect/sword_riding
	id = "sword_riding"
	alert_type = null
	duration = 8 SECONDS
	/// The artifact we're standing on
	var/obj/item/mount
	/// The artifact drawn under our feet
	var/mutable_appearance/mount_overlay

/datum/status_effect/sword_riding/on_creation(mob/living/new_owner, obj/item/mount)
	src.mount = mount
	return ..()

/datum/status_effect/sword_riding/on_apply()
	if(QDELETED(mount))
		return FALSE
	owner.add_traits(list(TRAIT_MOVE_FLYING, TRAIT_NO_SLIP_ALL), TRAIT_STATUS_EFFECT(id))
	owner.add_movespeed_modifier(/datum/movespeed_modifier/status_effect/sword_riding)
	// Same rider offset as a skateboard, with the artifact turned sideways under our feet
	owner.add_offsets(id, y_add = 5)
	mount_overlay = mutable_appearance(mount.icon, mount.icon_state, MOB_LAYER - 0.01)
	mount_overlay.color = mount.color
	var/matrix/sideways = matrix()
	sideways.Turn(90)
	mount_overlay.transform = sideways
	mount_overlay.pixel_y = -9
	owner.add_overlay(mount_overlay)
	RegisterSignals(mount, list(COMSIG_ITEM_DROPPED, COMSIG_QDELETING), PROC_REF(lose_mount))
	owner.visible_message(span_notice("[owner] hops onto [mount] and rises into the air!"))
	return TRUE

/datum/status_effect/sword_riding/on_remove()
	owner.remove_traits(list(TRAIT_MOVE_FLYING, TRAIT_NO_SLIP_ALL), TRAIT_STATUS_EFFECT(id))
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/status_effect/sword_riding)
	owner.remove_offsets(id)
	if(mount_overlay)
		owner.cut_overlay(mount_overlay)
		mount_overlay = null
	if(mount)
		UnregisterSignal(mount, list(COMSIG_ITEM_DROPPED, COMSIG_QDELETING))
	mount = null
	to_chat(owner, span_notice("You step lightly off your flying artifact."))

/datum/status_effect/sword_riding/proc/lose_mount(datum/source)
	SIGNAL_HANDLER
	owner.visible_message(span_danger("[owner] loses [owner.p_their()] footing and tumbles out of the air!"))
	owner.Knockdown(2 SECONDS)
	qdel(src)

/datum/movespeed_modifier/status_effect/sword_riding
	multiplicative_slowdown = -0.6

// ----- Dharma Idol: become a giant -----

/datum/status_effect/dharma_idol
	id = "dharma_idol"
	alert_type = null
	duration = 15 SECONDS

/datum/status_effect/dharma_idol/on_apply()
	owner.add_traits(list(TRAIT_PUSHIMMUNE), TRAIT_STATUS_EFFECT(id))
	owner.update_transform(1.5)
	owner.add_movespeed_modifier(/datum/movespeed_modifier/status_effect/dharma_idol)
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, PROC_REF(idol_body))
	owner.add_filter("dharma_idol", 2, list("type" = "outline", "color" = "#ffd27a", "size" = 2))
	owner.visible_message(span_boldwarning("A towering golden dharma idol unfolds around [owner]!"))
	return TRUE

/datum/status_effect/dharma_idol/on_remove()
	owner.remove_traits(list(TRAIT_PUSHIMMUNE), TRAIT_STATUS_EFFECT(id))
	owner.update_transform(1 / 1.5)
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/status_effect/dharma_idol)
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS)
	owner.remove_filter("dharma_idol")

/datum/status_effect/dharma_idol/proc/idol_body(mob/living/source, list/damage_mods, damage, damagetype, ...)
	SIGNAL_HANDLER
	damage_mods += 0.7

/datum/movespeed_modifier/status_effect/dharma_idol
	multiplicative_slowdown = 0.5

// ----- Burning Blood Essence -----

/datum/status_effect/burning_blood
	id = "burning_blood"
	alert_type = null
	duration = 10 SECONDS

/datum/status_effect/burning_blood/on_apply()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/status_effect/burning_blood)
	owner.add_filter("burning_blood", 2, list("type" = "outline", "color" = "#d0312d", "size" = 1))
	return TRUE

/datum/status_effect/burning_blood/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/status_effect/burning_blood)
	owner.remove_filter("burning_blood")

/datum/movespeed_modifier/status_effect/burning_blood
	multiplicative_slowdown = -0.4

// ----- Qi leak (breakthrough failure) -----

/datum/status_effect/qi_leak
	id = "qi_leak"
	alert_type = null
	duration = 3 MINUTES
	tick_interval = 3 SECONDS

/datum/status_effect/qi_leak/tick(seconds_between_ticks)
	do_sparks(1, TRUE, owner)
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(owner)
	cultivator?.adjust_qi(-2)

// ----- Molten Step: fire trail -----

/datum/status_effect/molten_step
	id = "molten_step"
	alert_type = null
	duration = 6 SECONDS

/datum/status_effect/molten_step/on_apply()
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_move))
	ADD_TRAIT(owner, TRAIT_RESISTHEAT, TRAIT_STATUS_EFFECT(id))
	return TRUE

/datum/status_effect/molten_step/on_remove()
	UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
	REMOVE_TRAIT(owner, TRAIT_RESISTHEAT, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/molten_step/proc/on_move(atom/movable/source, atom/old_loc, dir, forced)
	SIGNAL_HANDLER
	var/turf/open/old_turf = old_loc
	if(istype(old_turf))
		new /obj/effect/hotspot(old_turf)
		old_turf.hotspot_expose(700, 50, 1)
