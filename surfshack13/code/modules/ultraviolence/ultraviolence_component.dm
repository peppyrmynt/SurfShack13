/// How long each blow of a ground execution takes.
#define ULTRAVIOLENCE_EXECUTION_BLOW_TIME (0.7 SECONDS)
/// How long each stab of a knife execution takes.
#define ULTRAVIOLENCE_EXECUTION_STAB_TIME (0.4 SECONDS)
/// How long a single-swing bladed execution takes.
#define ULTRAVIOLENCE_EXECUTION_SLICE_TIME (1.5 SECONDS)
/// Minimum force for an item to be used for an execution.
#define ULTRAVIOLENCE_EXECUTION_MIN_FORCE 10
/// Force a bladed weapon needs to cut someone in half, or a blunt one to cave a chest in.
#define ULTRAVIOLENCE_HEAVY_WEAPON_FORCE 20
/// A single killing hit this strong blows the whole body apart.
#define ULTRAVIOLENCE_OBLITERATE_DAMAGE 50
/// Cooldown between mutilations of an already dead body.
#define ULTRAVIOLENCE_MUTILATE_COOLDOWN (1 SECONDS)

/// Kill styles, decided by what the killing blow was dealt with.
#define ULTRAVIOLENCE_STYLE_BLUNT "blunt"
#define ULTRAVIOLENCE_STYLE_SHARP "sharp"
#define ULTRAVIOLENCE_STYLE_BALLISTIC "ballistic"

/**
 * Hotline Miami style ultraviolence.
 *
 * Whoever has this component turns their kills into gore: heads pop, guts spill, limbs fly, bodies get flung into walls
 * and the floor ends up painted red. Corpses can be hacked apart further, and downed targets in crit can be executed
 * by aiming for the head in combat mode.
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
	COOLDOWN_DECLARE(mutilate_cooldown)

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

/// Is this a big enough weapon to do the really nasty stuff?
/datum/component/ultraviolence/proc/is_heavy_weapon(atom/weapon)
	if(!isitem(weapon))
		return FALSE
	var/obj/item/weapon_item = weapon
	return max(weapon_item.force, weapon_item.throwforce) >= ULTRAVIOLENCE_HEAVY_WEAPON_FORCE

/// Every hit that lands sprays blood, a hit that kills turns the body into a mess, and hits on corpses keep taking them apart.
/datum/component/ultraviolence/proc/on_attack_landed(mob/living/source, mob/living/target, damage_done, damagetype, def_zone, sharpness, atom/weapon)
	SIGNAL_HANDLER

	if(target == source || damagetype != BRUTE || !iscarbon(target))
		return
	var/mob/living/carbon/victim = target
	var/splatter_dir = get_dir(source, victim) || pick(GLOB.alldirs)
	var/zone = check_zone(def_zone)
	var/style = get_style(weapon, sharpness)

	if(victim.can_gore_bleed() && victim.blood_volume)
		victim.spray_blood(splatter_dir, clamp(round(damage_done / 8), 1, 4))
		if(get_dist(source, victim) <= 1)
			source.add_mob_blood(victim)
		if(isitem(weapon))
			weapon.add_mob_blood(victim)

	if(victim.stat != DEAD)
		return

	// Already dead before this hit: keep hacking the body apart.
	if(victim.timeofdeath != world.time)
		if(!COOLDOWN_FINISHED(src, mutilate_cooldown) || !prob(clamp(damage_done * 3, 10, 75)))
			return
		COOLDOWN_START(src, mutilate_cooldown, ULTRAVIOLENCE_MUTILATE_COOLDOWN)
		INVOKE_ASYNC(src, PROC_REF(mutilate), source, victim, zone, style, splatter_dir, weapon)
		return

	// Only one kill effect per body per tick, so each pellet of a shotgun blast doesn't trigger its own.
	var/datum/weakref/victim_ref = WEAKREF(victim)
	if(last_gored == victim_ref && last_gore_time == world.time)
		return
	last_gored = victim_ref
	last_gore_time = world.time
	var/point_blank = get_dist(source, victim) <= 1
	INVOKE_ASYNC(src, PROC_REF(kill_gore), source, victim, zone, style, splatter_dir, damage_done, weapon, point_blank)

/// The killing blow: what happens depends on where they were hit, with what and how hard.
/datum/component/ultraviolence/proc/kill_gore(mob/living/attacker, mob/living/carbon/victim, zone, style, splatter_dir, damage_done, atom/weapon, point_blank)
	if(QDELETED(victim))
		return

	victim.gore_witnessed(attacker)

	// Massive overkill, like a sniper round or a point blank slug: nothing recognizable is left.
	var/overkill_damage = damage_done
	if(style == ULTRAVIOLENCE_STYLE_BALLISTIC && point_blank)
		overkill_damage *= 1.5
	if(overkill_damage >= ULTRAVIOLENCE_OBLITERATE_DAMAGE && victim.gore_obliterate(attacker, splatter_dir))
		return

	victim.gore_blood_burst(style == ULTRAVIOLENCE_STYLE_BALLISTIC ? 4 : 3, splatter_dir)
	victim.gore_blood_pool()
	if(victim.can_be_gored())
		dismember_by_style(attacker, victim, zone, style, splatter_dir, weapon, point_blank)

	// Bodies get thrown back by the hit, smearing blood across the floor.
	if(QDELETED(victim))
		return
	var/fling_distance = 0
	if(style == ULTRAVIOLENCE_STYLE_BALLISTIC)
		fling_distance = point_blank ? 3 : 2
	else if(is_heavy_weapon(weapon))
		fling_distance = 1
	victim.gore_fling(splatter_dir, fling_distance, attacker)

/// Picks which body part gets destroyed and how.
/datum/component/ultraviolence/proc/dismember_by_style(mob/living/attacker, mob/living/carbon/victim, zone, style, splatter_dir, atom/weapon, point_blank)
	switch(zone)
		if(BODY_ZONE_HEAD)
			switch(style)
				if(ULTRAVIOLENCE_STYLE_SHARP)
					return victim.gore_decapitate(attacker, splatter_dir)
				if(ULTRAVIOLENCE_STYLE_BALLISTIC)
					return victim.gore_destroy_head(attacker, splatter_dir, GORE_HEAD_BLASTED, delete_head = point_blank || prob(65))
				else
					return victim.gore_destroy_head(attacker, splatter_dir, GORE_HEAD_CRUSHED, delete_head = prob(50))
		if(BODY_ZONE_CHEST)
			if(style == ULTRAVIOLENCE_STYLE_SHARP && is_heavy_weapon(weapon))
				return victim.gore_bisect(attacker, splatter_dir)
			if(style != ULTRAVIOLENCE_STYLE_BLUNT || is_heavy_weapon(weapon))
				return victim.gore_disembowel(attacker, splatter_dir)
		else
			if(style != ULTRAVIOLENCE_STYLE_BLUNT || is_heavy_weapon(weapon))
				return victim.gore_sever_limb(zone, attacker, splatter_dir)
	return FALSE

/// Hitting a body that's already dead. Takes it apart piece by piece, with a smaller mess each time.
/datum/component/ultraviolence/proc/mutilate(mob/living/attacker, mob/living/carbon/victim, zone, style, splatter_dir, atom/weapon)
	if(QDELETED(victim) || !victim.can_be_gored())
		return
	if(!victim.get_bodypart(zone))
		zone = BODY_ZONE_CHEST
	if(dismember_by_style(attacker, victim, zone, style, splatter_dir, weapon, FALSE))
		return
	victim.gore_blood_burst(1, splatter_dir)

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

/// Returns the direction of a wall next to the victim, if there is one to slam their head into.
/datum/component/ultraviolence/proc/find_adjacent_wall(mob/living/carbon/victim)
	for(var/direction in GLOB.cardinals)
		if(isclosedturf(get_step(victim, direction)))
			return direction
	return null

/**
 * Ground executions, only possible on targets already in crit. The finisher depends on what you're holding:
 * * Blades: one long cut that takes the head off.
 * * Knives and other pointy things: frenzied stabbing until the head is pulp.
 * * Blunt weapons: repeated blows to the head, into a wall if there's one next to them.
 * * Shoes: curbstomp. Bare hands: grab the head and slam it into the floor or a wall.
 */
/datum/component/ultraviolence/proc/execute(mob/living/attacker, mob/living/carbon/victim, obj/item/weapon)
	executing = TRUE

	var/sharpness = weapon?.get_sharpness()
	var/wall_dir = find_adjacent_wall(victim)
	var/wearing_shoes = FALSE
	if(ishuman(attacker))
		var/mob/living/carbon/human/human_attacker = attacker
		wearing_shoes = !!human_attacker.shoes

	var/blows
	var/blow_time
	// Each message comes as list(what onlookers see, what the attacker sees).
	var/list/start_text
	var/list/blow_text
	var/head_method = GORE_HEAD_CRUSHED
	var/decapitate = FALSE
	var/blow_sound = weapon?.hitsound || 'sound/effects/hit_kick.ogg'
	var/surface = wall_dir ? "wall" : "floor"
	if(sharpness & SHARP_EDGED)
		blows = 1
		blow_time = ULTRAVIOLENCE_EXECUTION_SLICE_TIME
		start_text = list("[attacker] presses [attacker.p_their()] [weapon.name] against [victim]'s neck", "You press your [weapon.name] against [victim]'s neck")
		decapitate = TRUE
		blow_sound = 'sound/items/weapons/bladeslice.ogg'
	else if(sharpness & SHARP_POINTY)
		blows = 5
		blow_time = ULTRAVIOLENCE_EXECUTION_STAB_TIME
		start_text = list("[attacker] pins [victim] down and raises [attacker.p_their()] [weapon.name]", "You pin [victim] down and raise your [weapon.name]")
		blow_text = list("[attacker] stabs [victim] in the face", "You stab [victim] in the face")
		head_method = GORE_HEAD_STABBED
		blow_sound = 'sound/effects/wounds/pierce1.ogg'
	else if(weapon)
		blows = 3
		blow_time = ULTRAVIOLENCE_EXECUTION_BLOW_TIME
		start_text = list("[attacker] pins [victim] down and raises [attacker.p_their()] [weapon.name]", "You pin [victim] down and raise your [weapon.name]")
		if(wall_dir)
			blow_text = list("[attacker] smashes [victim]'s head into the wall with [weapon]", "You smash [victim]'s head into the wall with [weapon]")
		else
			blow_text = list("[attacker] brings [weapon] down on [victim]'s head", "You bring [weapon] down on [victim]'s head")
	else if(wearing_shoes && !wall_dir)
		blows = 2
		blow_time = ULTRAVIOLENCE_EXECUTION_BLOW_TIME
		start_text = list("[attacker] lines up a stomp on [victim]'s head", "You line up a stomp on [victim]'s head")
		blow_text = list("[attacker] stomps on [victim]'s head", "You stomp on [victim]'s head")
	else
		blows = 3
		blow_time = ULTRAVIOLENCE_EXECUTION_BLOW_TIME
		start_text = list("[attacker] grabs [victim] by the head", "You grab [victim] by the head")
		blow_text = list("[attacker] slams [victim]'s head into the [surface]", "You slam [victim]'s head into the [surface]")

	attacker.visible_message(span_danger("[start_text[1]]..."), span_danger("[start_text[2]]..."), ignored_mobs = victim)
	to_chat(victim, span_userdanger("[attacker] pins you down!"))
	log_combat(attacker, victim, "started executing (ultraviolence)", weapon)

	for(var/blow in 1 to blows)
		if(!do_after(attacker, blow_time, victim, extra_checks = CALLBACK(src, PROC_REF(execution_still_valid), attacker, victim, weapon)))
			executing = FALSE
			return
		attacker.do_attack_animation(victim, weapon ? null : ATTACK_EFFECT_KICK, weapon)
		playsound(victim, blow_sound, 70, TRUE)
		if(!decapitate && head_method == GORE_HEAD_CRUSHED)
			playsound(victim, pick('sound/effects/wounds/crack1.ogg', 'sound/effects/wounds/crack2.ogg'), 60, TRUE)
		if(victim.can_gore_bleed())
			victim.spray_blood(wall_dir || pick(GLOB.alldirs), 2)
			attacker.add_mob_blood(victim)
			weapon?.add_mob_blood(victim)
		shake_camera(attacker, 1, 1)
		if(blow_text && blow < blows)
			attacker.visible_message(span_danger("[blow_text[1]]!"), span_danger("[blow_text[2]]!"))

	var/splatter_dir = wall_dir || get_dir(attacker, victim)
	victim.gore_witnessed(attacker)
	if(decapitate)
		victim.gore_decapitate(attacker, splatter_dir)
	else
		victim.gore_destroy_head(attacker, splatter_dir, head_method, delete_head = (head_method != GORE_HEAD_CRUSHED || prob(50)))
	victim.gore_blood_pool()
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
#undef ULTRAVIOLENCE_EXECUTION_STAB_TIME
#undef ULTRAVIOLENCE_EXECUTION_SLICE_TIME
#undef ULTRAVIOLENCE_EXECUTION_MIN_FORCE
#undef ULTRAVIOLENCE_HEAVY_WEAPON_FORCE
#undef ULTRAVIOLENCE_OBLITERATE_DAMAGE
#undef ULTRAVIOLENCE_MUTILATE_COOLDOWN
#undef ULTRAVIOLENCE_STYLE_BLUNT
#undef ULTRAVIOLENCE_STYLE_SHARP
#undef ULTRAVIOLENCE_STYLE_BALLISTIC
