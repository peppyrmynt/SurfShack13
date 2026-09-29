/// How long each blow of a ground execution takes.
#define ULTRAVIOLENCE_EXECUTION_BLOW_TIME (0.7 SECONDS)
/// How long a single-swing bladed execution takes.
#define ULTRAVIOLENCE_EXECUTION_SLICE_TIME (1.5 SECONDS)
/// Minimum force for an item to be used for an execution.
#define ULTRAVIOLENCE_EXECUTION_MIN_FORCE 10

/// Kill styles, decided by what the killing blow was dealt with.
#define ULTRAVIOLENCE_STYLE_BLUNT "blunt"
#define ULTRAVIOLENCE_STYLE_SHARP "sharp"
#define ULTRAVIOLENCE_STYLE_BALLISTIC "ballistic"

/**
 * Hotline Miami style ultraviolence.
 *
 * Whoever has this component turns their kills into gore: heads pop, guts spill, limbs fly and the floor ends up
 * painted red. They can also execute downed targets in crit by aiming for the head in combat mode.
 * It never changes how much damage anything deals, it only changes what a lethal hit looks like.
 *
 * Sourced so several things (a mask, an admin, a future antag datum) can grant it at once.
 */
/datum/component/ultraviolence
	dupe_mode = COMPONENT_DUPE_SOURCES
	/// Are we currently in the middle of executing someone?
	var/executing = FALSE
	/// The last body we gored, so a shotgun blast's pellets only trigger one kill effect.
	var/datum/weakref/last_gored
	/// world.time of the last kill effect.
	var/last_gore_time = 0

/datum/component/ultraviolence/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/ultraviolence/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOB_ATTACK_LANDED, PROC_REF(on_attack_landed))
	RegisterSignal(parent, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_item_attack))
	RegisterSignal(parent, COMSIG_LIVING_UNARMED_ATTACK, PROC_REF(on_unarmed_attack))

/datum/component/ultraviolence/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_MOB_ATTACK_LANDED, COMSIG_MOB_ITEM_ATTACK, COMSIG_LIVING_UNARMED_ATTACK))

/// Works out the kill style from what we hit them with.
/datum/component/ultraviolence/proc/get_style(atom/weapon, sharpness)
	if(isprojectile(weapon))
		return ULTRAVIOLENCE_STYLE_BALLISTIC
	if(sharpness & (SHARP_EDGED|SHARP_POINTY))
		return ULTRAVIOLENCE_STYLE_SHARP
	return ULTRAVIOLENCE_STYLE_BLUNT

/// Every hit that lands sprays blood, and a hit that kills turns the body into a mess.
/datum/component/ultraviolence/proc/on_attack_landed(mob/living/source, mob/living/target, damage_done, damagetype, def_zone, sharpness, atom/weapon)
	SIGNAL_HANDLER

	if(target == source || damagetype != BRUTE || !iscarbon(target))
		return
	var/mob/living/carbon/victim = target
	var/splatter_dir = get_dir(source, victim)

	if(!HAS_TRAIT(victim, TRAIT_NOBLOOD) && victim.blood_volume)
		victim.spray_blood(splatter_dir || pick(GLOB.alldirs), clamp(round(damage_done / 8), 1, 4))
		if(get_dist(source, victim) <= 1)
			source.add_mob_blood(victim)

	// Only the hit that actually killed them counts, so corpses can't be farmed for gore.
	if(victim.stat != DEAD || victim.timeofdeath != world.time)
		return
	var/datum/weakref/victim_ref = WEAKREF(victim)
	if(last_gored == victim_ref && last_gore_time == world.time)
		return
	last_gored = victim_ref
	last_gore_time = world.time
	INVOKE_ASYNC(src, PROC_REF(kill_gore), source, victim, check_zone(def_zone), get_style(weapon, sharpness), splatter_dir)

/// The killing blow: what happens depends on where they were hit and with what.
/datum/component/ultraviolence/proc/kill_gore(mob/living/attacker, mob/living/carbon/victim, zone, style, splatter_dir)
	if(QDELETED(victim))
		return

	victim.gore_blood_burst(style == ULTRAVIOLENCE_STYLE_BALLISTIC ? 4 : 3, splatter_dir)
	if(!victim.can_be_gored())
		return

	switch(zone)
		if(BODY_ZONE_HEAD)
			if(style == ULTRAVIOLENCE_STYLE_SHARP)
				victim.gore_decapitate(attacker, splatter_dir)
			else
				victim.gore_destroy_head(attacker, splatter_dir, crushed = (style == ULTRAVIOLENCE_STYLE_BLUNT), delete_head = (style == ULTRAVIOLENCE_STYLE_BALLISTIC || prob(50)))
		if(BODY_ZONE_CHEST)
			if(style != ULTRAVIOLENCE_STYLE_BLUNT)
				victim.gore_disembowel(attacker, splatter_dir)
		else
			if(style != ULTRAVIOLENCE_STYLE_BLUNT)
				victim.gore_sever_limb(zone, attacker, splatter_dir)

	// Gunshots knock the body back, leaving a smear behind it.
	if(style == ULTRAVIOLENCE_STYLE_BALLISTIC && splatter_dir && !victim.anchored && !victim.buckled && isturf(victim.loc))
		victim.throw_at(get_ranged_target_turf(victim, splatter_dir, 2), 2, 1, attacker, spin = FALSE)

/// Can we start an execution on this target right now?
/datum/component/ultraviolence/proc/can_execute(mob/living/attacker, mob/living/target, obj/item/weapon)
	if(executing || !attacker.combat_mode || target == attacker || !iscarbon(target))
		return FALSE
	if(check_zone(attacker.zone_selected) != BODY_ZONE_HEAD)
		return FALSE
	if(target.body_position != LYING_DOWN || target.stat < SOFT_CRIT || target.stat == DEAD)
		return FALSE
	var/mob/living/carbon/victim = target
	if(!victim.get_bodypart(BODY_ZONE_HEAD) || !victim.can_be_gored())
		return FALSE
	if(weapon && (weapon.force < ULTRAVIOLENCE_EXECUTION_MIN_FORCE || weapon.damtype != BRUTE))
		return FALSE
	return TRUE

/datum/component/ultraviolence/proc/on_item_attack(mob/living/source, mob/living/target, mob/living/user, params)
	SIGNAL_HANDLER

	var/obj/item/weapon = source.get_active_held_item()
	if(!weapon || !can_execute(source, target, weapon))
		return NONE
	INVOKE_ASYNC(src, PROC_REF(execute), source, target, weapon)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/datum/component/ultraviolence/proc/on_unarmed_attack(mob/living/source, atom/target, proximity, modifiers)
	SIGNAL_HANDLER

	if(!proximity || LAZYACCESS(modifiers, RIGHT_CLICK) || !isliving(target))
		return NONE
	if(!can_execute(source, target))
		return NONE
	INVOKE_ASYNC(src, PROC_REF(execute), source, target)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/**
 * Ground execution. Blunt weapons and bare hands take a few brutal blows to the head, blades take one long cut.
 * Only works on targets already in crit, so it's a finisher rather than an instant kill.
 */
/datum/component/ultraviolence/proc/execute(mob/living/attacker, mob/living/carbon/victim, obj/item/weapon)
	executing = TRUE
	var/style = weapon?.get_sharpness() ? ULTRAVIOLENCE_STYLE_SHARP : ULTRAVIOLENCE_STYLE_BLUNT
	var/method_text = "bare hands"
	if(weapon)
		method_text = "[weapon.name]"
	else if(ishuman(attacker))
		var/mob/living/carbon/human/human_attacker = attacker
		if(human_attacker.shoes)
			method_text = "boot"

	attacker.visible_message(
		span_danger("[attacker] pins [victim] down and raises [attacker.p_their()] [method_text]..."),
		span_danger("You pin [victim] down and raise your [method_text]..."),
		ignored_mobs = victim,
	)
	to_chat(victim, span_userdanger("[attacker] pins you down!"))
	log_combat(attacker, victim, "started executing (ultraviolence)", weapon)

	var/blows = style == ULTRAVIOLENCE_STYLE_SHARP ? 1 : 3
	var/blow_time = style == ULTRAVIOLENCE_STYLE_SHARP ? ULTRAVIOLENCE_EXECUTION_SLICE_TIME : ULTRAVIOLENCE_EXECUTION_BLOW_TIME
	for(var/blow in 1 to blows)
		if(!do_after(attacker, blow_time, victim, extra_checks = CALLBACK(src, PROC_REF(execution_still_valid), attacker, victim, weapon)))
			executing = FALSE
			return
		attacker.do_attack_animation(victim, weapon ? null : ATTACK_EFFECT_KICK, weapon)
		if(style == ULTRAVIOLENCE_STYLE_BLUNT)
			playsound(victim, weapon?.hitsound || 'sound/effects/hit_kick.ogg', 70, TRUE)
			playsound(victim, pick('sound/effects/wounds/crack1.ogg', 'sound/effects/wounds/crack2.ogg'), 60, TRUE)
			if(!HAS_TRAIT(victim, TRAIT_NOBLOOD))
				victim.spray_blood(pick(GLOB.alldirs), 2)
			shake_camera(attacker, 1, 1)
			if(blow < blows)
				attacker.visible_message(span_danger("[attacker] smashes [victim]'s head into the floor!"), span_danger("You smash [victim]'s head into the floor!"))
		else
			playsound(victim, 'sound/items/weapons/bladeslice.ogg', 70, TRUE)

	var/splatter_dir = get_dir(attacker, victim)
	if(style == ULTRAVIOLENCE_STYLE_SHARP)
		victim.gore_decapitate(attacker, splatter_dir)
	else
		victim.gore_destroy_head(attacker, splatter_dir, crushed = TRUE, delete_head = prob(50))
	shake_camera(attacker, 2, 2)

	if(victim.stat != DEAD && !HAS_TRAIT(victim, TRAIT_NODEATH))
		victim.death()
	log_combat(attacker, victim, "executed (ultraviolence)", weapon)
	executing = FALSE

/// Extra do_after checks for executions, so the victim can't be dragged away or stood back up mid-execution.
/datum/component/ultraviolence/proc/execution_still_valid(mob/living/attacker, mob/living/carbon/victim, obj/item/weapon)
	if(QDELETED(victim) || victim.stat == DEAD || victim.body_position != LYING_DOWN)
		return FALSE
	if(!victim.get_bodypart(BODY_ZONE_HEAD))
		return FALSE
	if(weapon && attacker.get_active_held_item() != weapon)
		return FALSE
	return TRUE

#undef ULTRAVIOLENCE_EXECUTION_BLOW_TIME
#undef ULTRAVIOLENCE_EXECUTION_SLICE_TIME
#undef ULTRAVIOLENCE_EXECUTION_MIN_FORCE
#undef ULTRAVIOLENCE_STYLE_BLUNT
#undef ULTRAVIOLENCE_STYLE_SHARP
#undef ULTRAVIOLENCE_STYLE_BALLISTIC
