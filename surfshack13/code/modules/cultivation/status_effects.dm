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
	var/obj/effect/abstract/cultivation_vis/bubble

/datum/status_effect/still_water_ward/on_creation(mob/living/new_owner, absorb = 30)
	absorb_left = absorb
	return ..()

/datum/status_effect/still_water_ward/on_apply()
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, PROC_REF(absorb))
	owner.add_filter("still_water_ward", 2, list("type" = "outline", "color" = "#4fb3ff", "size" = 1))
	bubble = cultivation_attach_vis(owner, 'surfshack13/icons/cultivation/cultivation_effects_64.dmi', "water_bubble", null, 64, 0, 150)
	return TRUE

/datum/status_effect/still_water_ward/refresh(effect, absorb = 30)
	absorb_left = max(absorb_left, absorb)
	return ..()

/datum/status_effect/still_water_ward/on_remove()
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS)
	owner.remove_filter("still_water_ward")
	cultivation_detach_vis(owner, bubble)
	bubble = null
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

// ----- Golden Bell: immune to damage and stuns, attackers bounce off -----

/datum/status_effect/golden_bell
	id = "golden_bell"
	alert_type = null
	duration = 5 SECONDS
	COOLDOWN_DECLARE(bounce_cooldown)
	var/obj/effect/abstract/cultivation_vis/bell

/datum/status_effect/golden_bell/on_creation(mob/living/new_owner, duration = 5 SECONDS)
	src.duration = duration
	return ..()

/datum/status_effect/golden_bell/on_apply()
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, PROC_REF(ring))
	if(!HAS_TRAIT(owner, TRAIT_RELAYING_ATTACKER))
		owner.AddElement(/datum/element/relay_attackers)
	RegisterSignal(owner, COMSIG_ATOM_WAS_ATTACKED, PROC_REF(bounce))
	owner.add_traits(list(TRAIT_IMMOBILIZED, TRAIT_PUSHIMMUNE, TRAIT_STUNIMMUNE), TRAIT_STATUS_EFFECT(id))
	owner.add_filter("golden_bell", 2, list("type" = "outline", "color" = "#ffcc33", "size" = 2))
	bell = cultivation_attach_vis(owner, 'surfshack13/icons/cultivation/cultivation_effects_64.dmi', "golden_bell", null, 64, 4, 200)
	// The bell drops from above and lands with a bounce
	bell.pixel_y += 48
	animate(bell, pixel_y = bell.pixel_y - 48, time = 0.35 SECONDS, easing = BOUNCE_EASING | EASE_OUT, flags = ANIMATION_PARALLEL)
	return TRUE

/datum/status_effect/golden_bell/on_remove()
	UnregisterSignal(owner, list(COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, COMSIG_ATOM_WAS_ATTACKED))
	owner.remove_traits(list(TRAIT_IMMOBILIZED, TRAIT_PUSHIMMUNE, TRAIT_STUNIMMUNE), TRAIT_STATUS_EFFECT(id))
	owner.remove_filter("golden_bell")
	cultivation_detach_vis(owner, bell)
	bell = null

/datum/status_effect/golden_bell/proc/ring(mob/living/source, list/damage_mods, damage, damagetype, ...)
	SIGNAL_HANDLER
	if(damagetype in list(BRUTE, BURN, STAMINA))
		damage_mods += 0
		playsound(owner, 'sound/effects/gong.ogg', 25, TRUE)
		if(bell)
			animate(bell, transform = matrix().Scale(1.1), time = 0.08 SECONDS)
			animate(transform = matrix(), time = 0.2 SECONDS, easing = ELASTIC_EASING)

/// Anyone hitting the bell in melee gets knocked back
/datum/status_effect/golden_bell/proc/bounce(atom/source, atom/attacker, attack_flags)
	SIGNAL_HANDLER
	if(!isliving(attacker) || get_dist(owner, attacker) > 1 || !COOLDOWN_FINISHED(src, bounce_cooldown))
		return
	COOLDOWN_START(src, bounce_cooldown, 0.5 SECONDS)
	var/mob/living/fool = attacker
	fool.visible_message(span_warning("[fool] rebounds off [owner]'s golden bell!"), span_userdanger("You bounce off the golden bell!"))
	new /obj/effect/temp_visual/circle_wave/cultivation/gold(get_turf(owner))
	fool.throw_at(get_edge_target_turf(fool, get_dir(owner, fool)), 2, 2, owner, spin = FALSE)

// ----- Rooted Stance -----

/datum/status_effect/rooted_stance
	id = "rooted_stance"
	alert_type = null
	duration = 10 SECONDS
	tick_interval = 1 SECONDS

/datum/status_effect/rooted_stance/on_apply()
	owner.add_traits(list(TRAIT_PUSHIMMUNE, TRAIT_NO_SLIP_ALL, TRAIT_STUNIMMUNE), TRAIT_STATUS_EFFECT(id))
	owner.move_resist = MOVE_FORCE_OVERPOWERING
	owner.add_movespeed_modifier(/datum/movespeed_modifier/status_effect/rooted_stance)
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, PROC_REF(mountain_body))
	owner.add_filter("rooted_stance", 2, list("type" = "outline", "color" = "#8a6b3d", "size" = 1))
	return TRUE

/datum/status_effect/rooted_stance/on_remove()
	owner.remove_traits(list(TRAIT_PUSHIMMUNE, TRAIT_NO_SLIP_ALL, TRAIT_STUNIMMUNE), TRAIT_STATUS_EFFECT(id))
	owner.move_resist = initial(owner.move_resist)
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/status_effect/rooted_stance)
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS)
	owner.remove_filter("rooted_stance")
	to_chat(owner, span_notice("You lift your roots from the ground."))

/datum/status_effect/rooted_stance/tick(seconds_between_ticks)
	owner.heal_overall_damage(brute = 1, burn = 1)

/datum/status_effect/rooted_stance/proc/mountain_body(mob/living/source, list/damage_mods, damage, damagetype, ...)
	SIGNAL_HANDLER
	if(damagetype in list(BRUTE, BURN))
		damage_mods += 0.6

/datum/movespeed_modifier/status_effect/rooted_stance
	multiplicative_slowdown = 0.6

// ----- Sword Riding -----

/// The artifact leaves your hand and becomes a platform under your feet: a glowing jian for blades, a golden cloud for anything else.
/datum/status_effect/sword_riding
	id = "sword_riding"
	alert_type = null
	duration = 8 SECONDS
	tick_interval = 0.5 SECONDS
	/// The artifact we're standing on (held in nullspace while we ride)
	var/obj/item/mount
	/// Platform drawn under our feet
	var/obj/effect/abstract/cultivation_ride_platform/platform
	/// Qi trail
	var/obj/effect/abstract/particle_holder/trail

/datum/status_effect/sword_riding/on_creation(mob/living/new_owner, obj/item/mount)
	src.mount = mount
	return ..()

/datum/status_effect/sword_riding/on_apply()
	if(QDELETED(mount) || !owner.temporarilyRemoveItemFromInventory(mount, force = TRUE))
		return FALSE
	mount.moveToNullspace()
	RegisterSignal(mount, COMSIG_QDELETING, PROC_REF(on_mount_deleted))
	owner.add_traits(list(TRAIT_MOVE_FLYING, TRAIT_NO_SLIP_ALL), TRAIT_STATUS_EFFECT(id))
	owner.add_movespeed_modifier(/datum/movespeed_modifier/status_effect/sword_riding)
	owner.add_offsets(id, y_add = 6)
	platform = new(null, mount)
	owner.vis_contents += platform
	platform.face(owner.dir)
	RegisterSignal(owner, COMSIG_ATOM_DIR_CHANGE, PROC_REF(on_turn))
	trail = cultivation_particles(owner, mount.sharpness ? /particles/cultivation : /particles/cultivation/gold)
	playsound(owner, 'sound/items/unsheath.ogg', 50, TRUE)
	playsound(owner, 'sound/items/weapons/fwoosh.ogg', 50, TRUE)
	owner.visible_message(span_notice("[owner] tosses [mount] into the air, hops onto it and rises up!"))
	return TRUE

/datum/status_effect/sword_riding/tick(seconds_between_ticks)
	if(owner.incapacitated || owner.body_position == LYING_DOWN)
		fall()

/datum/status_effect/sword_riding/on_remove()
	owner.remove_traits(list(TRAIT_MOVE_FLYING, TRAIT_NO_SLIP_ALL), TRAIT_STATUS_EFFECT(id))
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/status_effect/sword_riding)
	owner.remove_offsets(id)
	UnregisterSignal(owner, COMSIG_ATOM_DIR_CHANGE)
	if(platform)
		owner.vis_contents -= platform
		QDEL_NULL(platform)
	QDEL_NULL(trail)
	if(!QDELETED(mount))
		UnregisterSignal(mount, COMSIG_QDELETING)
		mount.forceMove(owner.drop_location())
		if(owner.stat == CONSCIOUS && !owner.incapacitated)
			owner.put_in_hands(mount)
			to_chat(owner, span_notice("You step lightly off [mount] and catch it."))
	mount = null

/// Knocked out of the sky
/datum/status_effect/sword_riding/proc/fall()
	owner.visible_message(span_danger("[owner] tumbles off [mount] and crashes to the floor!"))
	owner.Knockdown(2 SECONDS)
	qdel(src)

/datum/status_effect/sword_riding/proc/on_turn(atom/source, old_dir, new_dir)
	SIGNAL_HANDLER
	platform?.face(new_dir)

/datum/status_effect/sword_riding/proc/on_mount_deleted(datum/source)
	SIGNAL_HANDLER
	mount = null
	owner.visible_message(span_danger("[owner]'s flying artifact vanishes from under [owner.p_them()]!"))
	owner.Knockdown(2 SECONDS)
	qdel(src)

/datum/movespeed_modifier/status_effect/sword_riding
	multiplicative_slowdown = -0.6

/obj/effect/abstract/cultivation_ride_platform
	icon = 'surfshack13/icons/cultivation/cultivation_riding.dmi'
	icon_state = "sword_ride"
	vis_flags = VIS_INHERIT_PLANE | VIS_UNDERLAY
	appearance_flags = RESET_COLOR | RESET_TRANSFORM | KEEP_TOGETHER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	pixel_x = -16
	pixel_y = -16

/obj/effect/abstract/cultivation_ride_platform/Initialize(mapload, obj/item/mount)
	. = ..()
	if(mount && !mount.sharpness)
		// Anything that isn't a blade rides on an auspicious cloud, with the artifact sitting on top
		icon_state = "qi_cloud"
		var/mutable_appearance/riding_item = mutable_appearance(mount.icon, mount.icon_state)
		riding_item.pixel_x = 16
		riding_item.pixel_y = 14
		add_overlay(riding_item)
	alpha = 0
	animate(src, alpha = 255, time = 0.3 SECONDS)

/// Point the blade the way we're flying
/obj/effect/abstract/cultivation_ride_platform/proc/face(new_dir)
	if(new_dir & WEST)
		transform = matrix(-1, 0, 0, 0, 1, 0)
	else if(new_dir & EAST)
		transform = matrix()

// ----- Dharma Idol: a towering golden Buddha behind you, and palms that send people flying -----

/datum/status_effect/dharma_idol
	id = "dharma_idol"
	alert_type = null
	duration = 15 SECONDS
	/// The statue projected behind us
	var/obj/effect/abstract/dharma_idol/idol
	var/obj/effect/abstract/particle_holder/motes

/datum/status_effect/dharma_idol/on_apply()
	owner.add_traits(list(TRAIT_PUSHIMMUNE), TRAIT_STATUS_EFFECT(id))
	owner.update_transform(1.25)
	owner.add_movespeed_modifier(/datum/movespeed_modifier/status_effect/dharma_idol)
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, PROC_REF(idol_body))
	RegisterSignal(owner, COMSIG_LIVING_UNARMED_ATTACK, PROC_REF(idol_palm))
	owner.add_filter("dharma_idol", 2, list("type" = "outline", "color" = "#ffd27a", "size" = 2))
	idol = new()
	owner.vis_contents += idol
	idol.transform = matrix().Scale(0.4)
	animate(idol, alpha = 230, transform = matrix().Scale(1.6), time = 0.8 SECONDS, easing = BACK_EASING | EASE_OUT, flags = ANIMATION_PARALLEL)
	motes = cultivation_particles(owner, /particles/cultivation/gold)
	owner.visible_message(span_boldwarning("A towering golden dharma idol unfolds behind [owner]!"))
	return TRUE

/datum/status_effect/dharma_idol/on_remove()
	owner.remove_traits(list(TRAIT_PUSHIMMUNE), TRAIT_STATUS_EFFECT(id))
	owner.update_transform(1 / 1.25)
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/status_effect/dharma_idol)
	UnregisterSignal(owner, list(COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, COMSIG_LIVING_UNARMED_ATTACK))
	owner.remove_filter("dharma_idol")
	QDEL_NULL(motes)
	if(idol)
		var/obj/effect/abstract/dharma_idol/fading = idol
		idol = null
		animate(fading, alpha = 0, pixel_y = fading.pixel_y + 16, time = 0.6 SECONDS)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cultivation_remove_vis), owner, fading), 0.6 SECONDS)
	owner.visible_message(span_notice("The golden idol behind [owner] fades away."))

/datum/status_effect/dharma_idol/proc/idol_body(mob/living/source, list/damage_mods, damage, damagetype, ...)
	SIGNAL_HANDLER
	damage_mods += 0.6

/// Combat-mode punches become giant golden palms
/datum/status_effect/dharma_idol/proc/idol_palm(mob/living/source, atom/target, proximity, modifiers)
	SIGNAL_HANDLER
	if(!proximity || target == owner || !owner.combat_mode)
		return
	if(isliving(target))
		INVOKE_ASYNC(src, PROC_REF(palm_living), target)
	else if(isstructure(target) || ismachinery(target))
		var/obj/smashed = target
		if(smashed.uses_integrity && !(smashed.resistance_flags & INDESTRUCTIBLE))
			smashed.take_damage(40, BRUTE, MELEE)
		playsound(smashed, 'sound/effects/meteorimpact.ogg', 50, TRUE)
		new /obj/effect/temp_visual/kinetic_blast(get_turf(smashed))

/datum/status_effect/dharma_idol/proc/palm_living(mob/living/victim)
	if(idol)
		animate(idol, color = "#fff4c4", time = 0.05 SECONDS)
		animate(color = null, time = 0.3 SECONDS)
	victim.visible_message(span_danger("A giant golden palm slams into [victim]!"), span_userdanger("A colossal golden palm crashes into you!"))
	playsound(victim, 'sound/effects/meteorimpact.ogg', 60, TRUE)
	new /obj/effect/temp_visual/kinetic_blast(get_turf(victim))
	new /obj/effect/temp_visual/circle_wave/cultivation/gold(get_turf(victim))
	victim.apply_damage(25, BRUTE, BODY_ZONE_CHEST, wound_bonus = 10)
	victim.Shake(3, 3, 0.5 SECONDS)
	if(!HAS_TRAIT(victim, TRAIT_PUSHIMMUNE) && victim.move_resist < MOVE_FORCE_OVERPOWERING)
		victim.Knockdown(1 SECONDS)
		victim.throw_at(get_edge_target_turf(victim, get_dir(owner, victim)), 4, 2, owner, spin = TRUE)

/datum/movespeed_modifier/status_effect/dharma_idol
	multiplicative_slowdown = 0.3

/// The statue itself, drawn behind its owner
/obj/effect/abstract/dharma_idol
	name = "dharma idol"
	icon = 'surfshack13/icons/cultivation/dharma_idol.dmi'
	icon_state = "dharma_idol"
	vis_flags = VIS_INHERIT_PLANE | VIS_UNDERLAY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	appearance_flags = RESET_COLOR | KEEP_APART
	alpha = 0
	pixel_x = -16
	pixel_y = 14

/obj/effect/abstract/dharma_idol/Initialize(mapload)
	. = ..()
	animate(src, pixel_y = 18, time = 1.5 SECONDS, loop = -1, easing = SINE_EASING, flags = ANIMATION_PARALLEL)
	animate(pixel_y = 14, time = 1.5 SECONDS, easing = SINE_EASING)

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

// ----- Molten Step: a trail of glowing magma footprints -----

/datum/status_effect/molten_step
	id = "molten_step"
	alert_type = null
	duration = 8 SECONDS
	var/obj/effect/abstract/particle_holder/embers

/datum/status_effect/molten_step/on_apply()
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(on_move))
	ADD_TRAIT(owner, TRAIT_RESISTHEAT, TRAIT_STATUS_EFFECT(id))
	owner.add_filter("molten_step", 2, list("type" = "outline", "color" = "#ff7a2c", "size" = 1))
	embers = cultivation_particles(owner, /particles/cultivation/embers)
	return TRUE

/datum/status_effect/molten_step/on_remove()
	UnregisterSignal(owner, COMSIG_MOVABLE_MOVED)
	REMOVE_TRAIT(owner, TRAIT_RESISTHEAT, TRAIT_STATUS_EFFECT(id))
	owner.remove_filter("molten_step")
	QDEL_NULL(embers)

/datum/status_effect/molten_step/proc/on_move(atom/movable/source, atom/old_loc, dir, forced)
	SIGNAL_HANDLER
	var/turf/open/old_turf = old_loc
	if(!istype(old_turf) || (locate(/obj/effect/cultivation_molten_step) in old_turf))
		return
	var/obj/effect/cultivation_molten_step/steps = new(old_turf, owner)
	steps.dir = dir
	playsound(old_turf, 'sound/effects/wounds/sizzle1.ogg', 15, TRUE)
