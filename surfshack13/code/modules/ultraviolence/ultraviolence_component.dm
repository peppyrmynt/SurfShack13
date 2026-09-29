/// How long each blow of a ground execution takes.
#define ULTRAVIOLENCE_EXECUTION_BLOW_TIME (0.7 SECONDS)
/// How long each stab of a knife execution takes.
#define ULTRAVIOLENCE_EXECUTION_STAB_TIME (0.4 SECONDS)
/// How long a single-swing bladed execution takes.
#define ULTRAVIOLENCE_EXECUTION_SLICE_TIME (1.5 SECONDS)
/// Minimum time between blood sprays from the same victim.
#define ULTRAVIOLENCE_SPRAY_COOLDOWN (0.3 SECONDS)
/// Extra time on top of an execution's expected length before the failsafe forcibly ends it.
#define ULTRAVIOLENCE_EXECUTION_FAILSAFE_GRACE (5 SECONDS)
/// Trait source for holding an execution victim down.
#define ULTRAVIOLENCE_PIN_TRAIT "ultraviolence_pin"
/// Chicken mask executions on targets who are still conscious (stunned or knocked down, not in crit) take this many times longer.
#define ULTRAVIOLENCE_CONSCIOUS_EXECUTION_MULTIPLIER 3
/// Minimum force for an item to be used for an execution.
#define ULTRAVIOLENCE_EXECUTION_MIN_FORCE 10
/// Force a bladed weapon needs to cut someone in half, or a blunt one to cave a chest in.
#define ULTRAVIOLENCE_HEAVY_WEAPON_FORCE 20
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
 * Only granted by the chicken mask traitor item (see chicken_mask.dm). Sourced so admins can also add it for testing.
 */
/datum/component/ultraviolence
	dupe_mode = COMPONENT_DUPE_SOURCES
	/// Are we currently in the middle of executing someone?
	var/executing = FALSE
	/// The last body we gored, so a shotgun blast's pellets only trigger one kill effect.
	var/datum/weakref/last_gored
	/// world.time of the last kill effect.
	var/last_gore_time = 0
	/// The last body we sprayed blood out of, and when, to cap how many splatters rapid hits make.
	var/datum/weakref/last_sprayed
	var/last_spray_time = 0
	/// The victim we're currently holding down for an execution, if any. Chicken mask only.
	var/datum/weakref/pinned_victim
	/// Failsafe timer that ends an execution that somehow never finished, so nobody stays pinned forever.
	var/execution_failsafe_timer
	COOLDOWN_DECLARE(mutilate_cooldown)

/datum/component/ultraviolence/Destroy()
	end_execution()
	return ..()

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

	// Hits during an execution (like the execution gunshot) are handled by the execution itself.
	if(executing || target == source || damagetype != BRUTE || !iscarbon(target))
		return
	var/mob/living/carbon/victim = target
	var/splatter_dir = get_dir(source, victim) || pick(GLOB.alldirs)
	var/zone = check_zone(def_zone)
	var/style = get_style(weapon, sharpness)

	// Spray at most once per victim every ULTRAVIOLENCE_SPRAY_COOLDOWN, so shotgun pellets and automatic fire
	// don't spawn dozens of flying splatters at once.
	var/datum/weakref/victim_ref = WEAKREF(victim)
	var/can_spray = (last_sprayed != victim_ref || world.time >= last_spray_time + ULTRAVIOLENCE_SPRAY_COOLDOWN)
	if(can_spray && victim.can_gore_bleed() && victim.blood_volume)
		last_sprayed = victim_ref
		last_spray_time = world.time
		// Bigger hits throw more blood, further, in a wider fan.
		victim.gore_spray(clamp(round(damage_done / 8), 1, 4), splatter_dir, damage_done >= 20 ? 3 : 1)
		if(prob(damage_done * 2))
			victim.gore_splatter_floor(get_turf(victim), small_drip = TRUE)
	if(victim.can_gore_bleed())
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
					// Knives are a coin flip between taking the head off and stabbing it to pulp.
					if(isitem(weapon) && is_stabbing_weapon(weapon) && prob(50))
						return victim.gore_destroy_head(attacker, splatter_dir, GORE_HEAD_STABBED, delete_head = TRUE)
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

/**
 * Is the target down enough to be executed?
 * Normally that means lying in crit.
 * With TRAIT_RAMPAGE_EXECUTIONER (the chicken mask), anyone prone, stunned, in soft crit or worse, or dead will do.
 */
/datum/component/ultraviolence/proc/is_executable(mob/living/attacker, mob/living/target)
	if(HAS_TRAIT(attacker, TRAIT_RAMPAGE_EXECUTIONER))
		return target.body_position == LYING_DOWN || target.stat >= SOFT_CRIT || HAS_TRAIT(target, TRAIT_INCAPACITATED)
	return target.body_position == LYING_DOWN && target.stat >= SOFT_CRIT && target.stat != DEAD

/// Can we start an execution on this target right now?
/datum/component/ultraviolence/proc/can_execute(mob/living/attacker, mob/living/target, obj/item/weapon)
	if(executing || !attacker.combat_mode || target == attacker || !iscarbon(target))
		return FALSE
	if(check_zone(attacker.zone_selected) != BODY_ZONE_HEAD)
		return FALSE
	if(!is_executable(attacker, target))
		return FALSE
	var/mob/living/carbon/victim = target
	if(!victim.get_bodypart(BODY_ZONE_HEAD) || !victim.can_be_gored())
		return FALSE
	if(isgun(weapon))
		// Guns execute by shooting the head, so they need a round to fire.
		var/obj/item/gun/gun = weapon
		return gun.can_shoot()
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
 * Knives get the frenzied stabbing execution instead of a decapitation, even though most of them count as edged.
 * The butcher's cleaver is a chopper, so it still takes the head off. Anything only pointy (and not edged) stabs too.
 */
/datum/component/ultraviolence/proc/is_stabbing_weapon(obj/item/weapon)
	if(!weapon)
		return FALSE
	if(istype(weapon, /obj/item/knife))
		return !istype(weapon, /obj/item/knife/butcher)
	var/sharpness = weapon.get_sharpness()
	return (sharpness & SHARP_POINTY) && !(sharpness & SHARP_EDGED)

/// Returns the direction of a wall next to the victim, if there is one to slam their head into.
/datum/component/ultraviolence/proc/find_adjacent_wall(mob/living/carbon/victim)
	for(var/direction in GLOB.cardinals)
		if(isclosedturf(get_step(victim, direction)))
			return direction
	return null

/**
 * Ground executions, only possible on downed targets (see is_executable()). The finisher depends on what you're holding:
 * * Knives and other pointy things: frenzied stabbing until the head is pulp.
 * * Other blades (including the butcher's cleaver): one long cut that takes the head off.
 * * Blunt weapons: repeated blows to the head, into a wall if there's one next to them.
 * * Shoes: curbstomp. Bare hands: grab the head and slam it into the floor or a wall.
 */
/datum/component/ultraviolence/proc/execute(mob/living/attacker, mob/living/carbon/victim, obj/item/weapon)
	executing = TRUE
	var/victim_was_alive = victim.stat != DEAD

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
	var/gun_execution = isgun(weapon)
	if(gun_execution)
		blows = 1
		blow_time = ULTRAVIOLENCE_EXECUTION_SLICE_TIME
		start_text = list("[attacker] presses the barrel of [attacker.p_their()] [weapon.name] to [victim]'s head", "You press the barrel of your [weapon.name] to [victim]'s head")
		head_method = GORE_HEAD_BLASTED
	else if(is_stabbing_weapon(weapon))
		blows = 5
		blow_time = ULTRAVIOLENCE_EXECUTION_STAB_TIME
		start_text = list("[attacker] pins [victim] down and raises [attacker.p_their()] [weapon.name]", "You pin [victim] down and raise your [weapon.name]")
		blow_text = list("[attacker] stabs [victim] in the face", "You stab [victim] in the face")
		head_method = GORE_HEAD_STABBED
		blow_sound = 'sound/effects/wounds/pierce1.ogg'
	else if(sharpness & SHARP_EDGED)
		blows = 1
		blow_time = ULTRAVIOLENCE_EXECUTION_SLICE_TIME
		start_text = list("[attacker] presses [attacker.p_their()] [weapon.name] against [victim]'s neck", "You press your [weapon.name] against [victim]'s neck")
		decapitate = TRUE
		blow_sound = 'sound/items/weapons/bladeslice.ogg'
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

	// Chicken mask: someone who's only stunned or knocked down, still conscious and not in crit, takes three times as long to finish.
	if(HAS_TRAIT(attacker, TRAIT_RAMPAGE_EXECUTIONER) && victim.stat == CONSCIOUS)
		blow_time *= ULTRAVIOLENCE_CONSCIOUS_EXECUTION_MULTIPLIER

	attacker.visible_message(span_danger("[start_text[1]]..."), span_danger("[start_text[2]]..."), ignored_mobs = victim)
	to_chat(victim, span_userdanger("[attacker] pins you down!"))
	log_combat(attacker, victim, "started executing (ultraviolence)", weapon)
	pin_victim(attacker, victim)
	// If anything goes wrong mid-execution, this makes sure the victim is let go and we can execute again.
	deltimer(execution_failsafe_timer)
	execution_failsafe_timer = addtimer(CALLBACK(src, PROC_REF(end_execution)), blows * blow_time + ULTRAVIOLENCE_EXECUTION_FAILSAFE_GRACE, TIMER_STOPPABLE)

	for(var/blow in 1 to blows)
		if(!do_after(attacker, blow_time, victim, extra_checks = CALLBACK(src, PROC_REF(execution_still_valid), attacker, victim, weapon)) || QDELETED(src))
			end_execution()
			return
		// A gun execution is one held breath, then the shot below.
		if(gun_execution)
			continue
		attacker.do_attack_animation(victim, weapon ? null : ATTACK_EFFECT_KICK, weapon)
		playsound(victim, blow_sound, 70, TRUE)
		if(!decapitate && head_method == GORE_HEAD_CRUSHED)
			playsound(victim, pick('sound/effects/wounds/crack1.ogg', 'sound/effects/wounds/crack2.ogg'), 60, TRUE)
		if(victim.can_gore_bleed())
			victim.gore_spray(rand(1, 3), wall_dir, 2)
			if(prob(40))
				victim.gore_splatter_floor(get_turf(victim), small_drip = TRUE)
			attacker.add_mob_blood(victim)
			weapon?.add_mob_blood(victim)
		shake_camera(attacker, 1, 1)
		if(blow_text && blow < blows)
			attacker.visible_message(span_danger("[blow_text[1]]!"), span_danger("[blow_text[2]]!"))

	if(gun_execution && !fire_execution_shot(weapon, attacker, victim))
		end_execution()
		return
	if(QDELETED(victim))
		end_execution()
		return

	release_pin()
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
	end_execution()
	SEND_SIGNAL(attacker, COMSIG_MOB_ULTRAVIOLENCE_EXECUTION, victim, victim_was_alive)

/**
 * Fires exactly one round from the gun into the victim's head, point blank. Burst weapons only fire once.
 * Returns TRUE if a round was actually fired; an empty gun just clicks.
 */
/datum/component/ultraviolence/proc/fire_execution_shot(obj/item/gun/gun, mob/living/attacker, mob/living/carbon/victim)
	if(QDELETED(gun) || QDELETED(victim))
		return FALSE
	if(!gun.can_shoot())
		gun.shoot_with_empty_chamber(attacker)
		return FALSE
	var/old_burst_size = gun.burst_size
	gun.burst_size = 1
	var/fired = gun.process_fire(victim, attacker, TRUE, null, BODY_ZONE_HEAD)
	gun.burst_size = old_burst_size
	if(fired)
		shake_camera(attacker, 3, 2)
	return fired

/**
 * Chicken mask only: holds the victim down for the whole execution, so a stun wearing off halfway through
 * doesn't let them get up. Released as soon as the execution ends, however it ends.
 */
/datum/component/ultraviolence/proc/pin_victim(mob/living/attacker, mob/living/carbon/victim)
	if(!HAS_TRAIT(attacker, TRAIT_RAMPAGE_EXECUTIONER))
		return
	release_pin()
	victim.add_traits(list(TRAIT_INCAPACITATED, TRAIT_IMMOBILIZED, TRAIT_FLOORED, TRAIT_HANDS_BLOCKED), ULTRAVIOLENCE_PIN_TRAIT)
	pinned_victim = WEAKREF(victim)

/// Wraps up an execution however it ended: lets the victim go and allows the next execution.
/datum/component/ultraviolence/proc/end_execution()
	deltimer(execution_failsafe_timer)
	execution_failsafe_timer = null
	release_pin()
	executing = FALSE

/// Lets go of whoever we were holding down.
/datum/component/ultraviolence/proc/release_pin()
	var/mob/living/victim = pinned_victim?.resolve()
	pinned_victim = null
	if(victim)
		victim.remove_traits(list(TRAIT_INCAPACITATED, TRAIT_IMMOBILIZED, TRAIT_FLOORED, TRAIT_HANDS_BLOCKED), ULTRAVIOLENCE_PIN_TRAIT)

/// Extra do_after checks for executions, so the victim can't be dragged away or stood back up mid-execution.
/datum/component/ultraviolence/proc/execution_still_valid(mob/living/attacker, mob/living/carbon/victim, obj/item/weapon)
	if(QDELETED(src) || QDELETED(victim) || !is_executable(attacker, victim))
		return FALSE
	if(!victim.get_bodypart(BODY_ZONE_HEAD))
		return FALSE
	if(weapon && attacker.get_active_held_item() != weapon)
		return FALSE
	return TRUE

#undef ULTRAVIOLENCE_PIN_TRAIT
#undef ULTRAVIOLENCE_SPRAY_COOLDOWN
#undef ULTRAVIOLENCE_EXECUTION_FAILSAFE_GRACE
#undef ULTRAVIOLENCE_CONSCIOUS_EXECUTION_MULTIPLIER
#undef ULTRAVIOLENCE_EXECUTION_BLOW_TIME
#undef ULTRAVIOLENCE_EXECUTION_STAB_TIME
#undef ULTRAVIOLENCE_EXECUTION_SLICE_TIME
#undef ULTRAVIOLENCE_EXECUTION_MIN_FORCE
#undef ULTRAVIOLENCE_HEAVY_WEAPON_FORCE
#undef ULTRAVIOLENCE_MUTILATE_COOLDOWN
#undef ULTRAVIOLENCE_STYLE_BLUNT
#undef ULTRAVIOLENCE_STYLE_SHARP
#undef ULTRAVIOLENCE_STYLE_BALLISTIC
