/// Charge never hit anything and ran out of steam
#define BULL_CHARGE_MISSED 0
/// Charge ended by goring a mob
#define BULL_CHARGE_HIT_MOB 1
/// Charge ended by slamming into something it couldn't break
#define BULL_CHARGE_HIT_OBSTACLE 2
/// Charge was interrupted (death, stun, deletion)
#define BULL_CHARGE_ABORTED 3

/**
 * Bull rush
 *
 * Paws the ground for a windup, locks onto where the target was standing, then barrels in a straight line
 * through that spot until it hits something or runs out of steam.
 * - Mobs get gored, wounded and thrown, even if they're lying down in our path.
 * - Airlocks, firelocks, windoors and mineral doors get knocked off their frames and sent flying.
 * - Normal walls get smashed through (up to max_walls per charge, the last one only cracks to a girder half the time).
 * - Reinforced/hard walls and anything else it can't break stun the bull instead.
 * - Windows, grilles, tables and the like are just ploughed through.
 * - If nothing gets hit the cooldown is short so the AI simply lines up again.
 * - Anyone wearing or waving red, or covered in blood, makes us see red: a faster dash that goes twice as far.
 */
/datum/action/cooldown/mob_cooldown/bull_charge
	name = "Bull Rush"
	desc = "Paw the ground, then charge in a straight line through wherever your target was standing."
	button_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "sniper_zoom"
	cooldown_time = 4 SECONDS
	melee_cooldown_time = 0
	shared_cooldown = NONE
	/// How long we paw the ground before dashing
	var/windup_time = 1.2 SECONDS
	/// How long before the dash we stop tracking the target and commit to a spot
	var/aim_lock_time = 0.4 SECONDS
	/// Deciseconds per tile while dashing
	var/charge_speed = 0.8
	/// Max tiles travelled in one dash
	var/charge_range = 14
	/// Cooldown used when we didn't hit anything, so we line up again quickly
	var/miss_cooldown = 1.5 SECONDS
	/// Normal walls we can go through per charge
	var/max_walls = 2
	/// Brute damage dealt to gored mobs
	var/gore_damage = 25
	/// How far gored mobs get thrown
	var/throw_range = 6
	/// How long gored mobs stay down
	var/gore_knockdown = 2 SECONDS
	/// Chance a charge tosses its victim high into the air instead of just flinging them
	var/toss_chance = 35
	/// Chance a charge gives its victim a wound
	var/wound_chance = 50
	/// Damage dealt to fragile structures (windows, grilles, tables...) we plough through
	var/fragile_damage = 400
	/// Damage dealt to other dense objects we slam into (airlocks, machines...)
	var/obstacle_damage = 120
	/// How long after a charge before we can attack normally again
	var/post_charge_melee_cooldown = 2 SECONDS
	/// How long we're stunned after hitting something we can't break
	var/recoil_stun = 1 SECONDS
	/// Brute damage we take when slamming into something we can't break
	var/recoil_damage = 5

	/// Seeing red: multiplier on deciseconds per tile (lower is faster)
	var/enraged_speed_mult = 0.5
	/// Seeing red: multiplier on how far we charge
	var/enraged_range_mult = 2

	/// Sound slot: pawing the ground / snorting during the windup
	var/windup_sound = 'sound/mobs/non-humanoids/cow/cow.ogg'
	/// Sound slot: furious bellow when we see red
	var/enraged_sound = 'sound/mobs/non-humanoids/cow/cow.ogg'
	/// Sound slot: hooves thundering as the dash starts
	var/dash_sound = 'sound/effects/meteorimpact.ogg'

	/// Are we currently winding up or dashing
	var/charging = FALSE
	/// Are we currently performing a move from our own loop (anything else gets blocked)
	var/actively_moving = FALSE
	/// Who we're winding up at
	var/datum/weakref/target_ref
	/// The turf we committed to charging through
	var/turf/aim_turf
	/// Our dash move loop
	var/datum/move_loop/charge_loop
	/// Direction we're dashing in, used for throwing
	var/charge_dir
	/// Walls broken this charge
	var/walls_smashed = 0
	/// Timers for windup stages, so we can cancel them
	var/list/windup_timers
	/// Is the current charge a seeing-red one
	var/enraged = FALSE

	/// Things we just smash through without slowing down
	var/static/list/fragile_types = typecacheof(list(
		/obj/structure/window,
		/obj/structure/grille,
		/obj/structure/table,
		/obj/structure/railing,
		/obj/structure/girder,
		/obj/structure/barricade,
		/obj/structure/door_assembly,
		/obj/structure/windoor_assembly,
	))
	/// Doors we knock clean off their frames
	var/static/list/flingable_doors = typecacheof(list(
		/obj/machinery/door/airlock,
		/obj/machinery/door/firedoor,
		/obj/machinery/door/window,
		/obj/structure/mineral_door,
	))

/datum/action/cooldown/mob_cooldown/bull_charge/Destroy()
	abort_charge()
	return ..()

/datum/action/cooldown/mob_cooldown/bull_charge/Remove(mob/removed_from)
	abort_charge()
	return ..()

/datum/action/cooldown/mob_cooldown/bull_charge/IsAvailable(feedback = FALSE)
	if(charging)
		return FALSE
	return ..()

/datum/action/cooldown/mob_cooldown/bull_charge/Activate(atom/target)
	return start_charge(target, with_windup = TRUE)

/// Charge right now, no pawing at the ground and no warning
/datum/action/cooldown/mob_cooldown/bull_charge/proc/instant_charge(atom/target)
	return start_charge(target, with_windup = FALSE)

/datum/action/cooldown/mob_cooldown/bull_charge/proc/start_charge(atom/target, with_windup = TRUE)
	if(charging || !isliving(owner))
		return FALSE
	// No charging out of crates, lockers or bellies
	if(!isturf(owner.loc))
		return FALSE
	var/turf/target_turf = get_turf(target)
	if(!target_turf || target_turf.z != owner.z || target_turf == get_turf(owner))
		return FALSE

	var/mob/living/bull = owner
	charging = TRUE
	walls_smashed = 0
	enraged = bull_sees_red(target)
	target_ref = WEAKREF(target)
	aim_turf = target_turf
	// Hold the cooldown (and melee) until the charge is over
	StartCooldown(100 SECONDS, 100 SECONDS)

	RegisterSignal(bull, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(on_pre_move))
	RegisterSignal(bull, COMSIG_LIVING_DEATH, PROC_REF(abort_charge))

	if(!with_windup)
		begin_dash()
		return TRUE

	var/windup = windup_time
	bull.face_atom(target)
	if(enraged)
		bull.visible_message(span_big(span_bolddanger("[bull] SEES RED and bellows with fury!")))
		if(ismob(target))
			to_chat(target, span_big(span_userdanger("[bull] is locked onto all that red on you. RUN!")))
		playsound(bull, enraged_sound, 100, TRUE, frequency = 0.6)
	else
		bull.visible_message(span_danger("[bull] paws at the ground and lowers [bull.p_their()] horns!"))
		playsound(bull, windup_sound, 80, TRUE, frequency = 0.7)
	bull.Shake(enraged ? 3 : 2, 1, windup)
	var/obj/effect/temp_visual/decoy/flash = new(bull.loc, bull)
	animate(flash, alpha = 0, color = COLOR_RED, transform = matrix() * (enraged ? 2 : 1.5), time = windup)

	windup_timers = list(
		addtimer(CALLBACK(src, PROC_REF(lock_aim)), max(windup - aim_lock_time, 0), TIMER_STOPPABLE),
		addtimer(CALLBACK(src, PROC_REF(begin_dash)), windup, TIMER_STOPPABLE),
	)
	return TRUE

/// Stop tracking the target and commit to where they are now
/datum/action/cooldown/mob_cooldown/bull_charge/proc/lock_aim()
	if(!charging)
		return
	var/atom/target = target_ref?.resolve()
	if(target && get_turf(target) && target.z == owner.z && get_turf(target) != get_turf(owner))
		aim_turf = get_turf(target)
	owner.face_atom(aim_turf)
	new /obj/effect/temp_visual/telegraphing/bull_charge(aim_turf)

/datum/action/cooldown/mob_cooldown/bull_charge/proc/begin_dash()
	windup_timers = null
	if(!charging)
		return
	var/mob/living/bull = owner
	if(bull.stat != CONSCIOUS || HAS_TRAIT(bull, TRAIT_INCAPACITATED) || HAS_TRAIT(bull, TRAIT_IMMOBILIZED) || bull.buckled)
		end_charge(BULL_CHARGE_ABORTED)
		return

	charge_dir = get_dir(bull, aim_turf)
	bull.setDir(charge_dir)
	playsound(bull, dash_sound, 60, TRUE)

	var/speed = enraged ? charge_speed * enraged_speed_mult : charge_speed
	var/range = enraged ? charge_range * enraged_range_mult : charge_range
	// Not homing, so it keeps going in a straight line past the aim turf until the timeout
	charge_loop = GLOB.move_manager.move_towards(bull, aim_turf, speed, FALSE, (range + max_walls) * speed, priority = MOVEMENT_ABOVE_SPACE_PRIORITY)
	if(!charge_loop)
		end_charge(BULL_CHARGE_ABORTED)
		return
	RegisterSignal(charge_loop, COMSIG_MOVELOOP_PREPROCESS_CHECK, PROC_REF(pre_loop_move))
	RegisterSignal(charge_loop, COMSIG_MOVELOOP_POSTPROCESS, PROC_REF(post_loop_move))
	RegisterSignal(charge_loop, COMSIG_QDELETING, PROC_REF(on_loop_end))
	RegisterSignal(bull, COMSIG_MOVABLE_BUMP, PROC_REF(on_bump))
	RegisterSignal(bull, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))

/datum/action/cooldown/mob_cooldown/bull_charge/proc/pre_loop_move(datum/source)
	SIGNAL_HANDLER
	actively_moving = TRUE

/datum/action/cooldown/mob_cooldown/bull_charge/proc/post_loop_move(datum/source)
	SIGNAL_HANDLER
	actively_moving = FALSE

/// No wandering off during the windup or veering mid-dash
/datum/action/cooldown/mob_cooldown/bull_charge/proc/on_pre_move(atom/source, atom/new_loc)
	SIGNAL_HANDLER
	if(!actively_moving)
		return COMPONENT_MOVABLE_BLOCK_PRE_MOVE

/// Loop timed out, we went the whole way without hitting anything worth stopping for
/datum/action/cooldown/mob_cooldown/bull_charge/proc/on_loop_end(datum/source)
	SIGNAL_HANDLER
	charge_loop = null
	if(charging)
		end_charge(BULL_CHARGE_MISSED)

/datum/action/cooldown/mob_cooldown/bull_charge/proc/on_moved(atom/source, atom/old_loc, dir, forced)
	SIGNAL_HANDLER
	new /obj/effect/temp_visual/decoy/fading(old_loc, source)
	// Lying down won't save you, we scoop up anyone in our path
	for(var/mob/living/victim in get_turf(source))
		if(victim == source || victim.buckled == source || victim.body_position != LYING_DOWN)
			continue
		INVOKE_ASYNC(src, PROC_REF(gore), victim)
		return

/datum/action/cooldown/mob_cooldown/bull_charge/proc/on_bump(atom/movable/source, atom/bumped)
	SIGNAL_HANDLER
	if(!charging || bumped == source)
		return
	INVOKE_ASYNC(src, PROC_REF(handle_impact), bumped)
	// No swapping places with or pushing what we just rammed
	return COMPONENT_INTERCEPT_BUMPED

/datum/action/cooldown/mob_cooldown/bull_charge/proc/handle_impact(atom/bumped)
	if(!charging)
		return
	var/mob/living/bull = owner
	shake_camera(bull, 2, 2)

	if(isliving(bumped))
		gore(bumped)
		return

	if(iswallturf(bumped))
		var/turf/closed/wall/wall = bumped
		if(wall.hardness < 30 || walls_smashed >= max_walls) // reinforced, plastitanium etc
			recoil(wall)
			return
		walls_smashed++
		playsound(wall, 'sound/effects/meteorimpact.ogg', 100, TRUE)
		if(walls_smashed < max_walls || prob(50))
			bull.visible_message(span_danger("[bull] smashes straight through [wall]!"))
			wall.dismantle_wall(devastated = TRUE)
			if(walls_smashed >= max_walls)
				end_charge(BULL_CHARGE_HIT_OBSTACLE) // out of momentum
			return
		bull.visible_message(span_danger("[bull] slams into [wall], caving it in!"))
		wall.dismantle_wall(devastated = FALSE) // leaves a girder
		recoil(null, recoil_stun * 0.5)
		return

	if(ismineralturf(bumped))
		var/turf/closed/mineral/rock = bumped
		if(walls_smashed >= max_walls)
			recoil(rock)
			return
		walls_smashed++
		bull.visible_message(span_danger("[bull] bursts through [rock]!"))
		rock.gets_drilled(bull)
		return

	if(isturf(bumped)) // indestructible walls and friends
		recoil(bumped)
		return

	if(!isobj(bumped))
		return
	var/obj/thing = bumped
	// Water tanks burst, fuel tanks go up in flames
	if(istype(thing, /obj/structure/reagent_dispensers))
		var/obj/structure/reagent_dispensers/tank = thing
		bull.visible_message(span_danger("[bull] gores [tank] wide open!"))
		log_combat(bull, tank, "gored open")
		tank.boom()
		stagger_from_blast()
		return
	// Gas canisters rupture with a bang and dump everything inside
	if(istype(thing, /obj/machinery/portable_atmospherics/canister) && !(thing.resistance_flags & INDESTRUCTIBLE))
		var/obj/machinery/portable_atmospherics/canister/canister = thing
		bull.visible_message(span_danger("[bull] rams straight through [canister], blowing it apart!"))
		log_combat(bull, canister, "blew apart")
		canister.canister_break()
		explosion(canister, light_impact_range = 1, flash_range = 2, explosion_cause = bull)
		stagger_from_blast()
		return
	if(is_type_in_typecache(thing, flingable_doors) && thing.density && !(thing.resistance_flags & INDESTRUCTIBLE))
		fling_door(thing)
		return
	if(is_type_in_typecache(thing, fragile_types))
		thing.take_damage(fragile_damage, BRUTE, MELEE, TRUE, get_dir(thing, bull))
		if(QDELETED(thing) || !thing.density)
			bull.visible_message(span_danger("[bull] crashes right through [thing]!"))
			return
		recoil(thing)
		return
	if(!thing.anchored)
		bull.visible_message(span_danger("[bull] sends [thing] flying!"))
		thing.throw_at(get_ranged_target_turf(thing, charge_dir, throw_range), throw_range, 3, bull)
		return
	thing.take_damage(obstacle_damage, BRUTE, MELEE, TRUE, get_dir(thing, bull))
	if(QDELETED(thing) || !thing.density)
		bull.visible_message(span_danger("[bull] smashes through [thing]!"))
		return
	recoil(thing)

/// Gore a mob, wound them and send them flying
/datum/action/cooldown/mob_cooldown/bull_charge/proc/gore(mob/living/victim)
	if(!charging)
		return
	var/mob/living/bull = owner
	end_charge(BULL_CHARGE_HIT_MOB)
	if(victim.check_block(bull, gore_damage, "the charging [bull.name]", attack_type = LEAP_ATTACK))
		victim.Knockdown(gore_knockdown * 0.5)
		recoil(null)
		return
	bull_gore(bull, victim, gore_damage, throw_range, charge_dir, WOUND_SEVERITY_SEVERE, gore_knockdown, toss_chance, wound_chance)

/// Knock a door clean off its frame and send it flying ahead of us
/datum/action/cooldown/mob_cooldown/bull_charge/proc/fling_door(obj/door)
	var/mob/living/bull = owner
	var/turf/door_turf = get_turf(door)
	bull.visible_message(
		span_danger("[bull] rams [door] clean off its frame!"),
		blind_message = span_hear("You hear a deafening crash!"),
	)
	playsound(door_turf, 'sound/effects/meteorimpact.ogg', 80, TRUE)
	playsound(door_turf, 'sound/effects/bang.ogg', 80, TRUE)
	log_combat(bull, door, "rammed off its frame")
	var/obj/structure/bull_flung_door/flying_door = new(door_turf, door)
	qdel(door)
	flying_door.launch(charge_dir)

/// Something just blew up in our face, that's the end of this charge
/datum/action/cooldown/mob_cooldown/bull_charge/proc/stagger_from_blast()
	if(QDELETED(owner) || owner.stat == DEAD)
		return
	owner.visible_message(span_big(span_bolddanger("[owner] staggers out of the blast, dazed!")))
	recoil(null)

/// We hit something we can't get through, ouch
/datum/action/cooldown/mob_cooldown/bull_charge/proc/recoil(atom/obstacle, stun = recoil_stun)
	var/mob/living/bull = owner
	if(charging)
		end_charge(BULL_CHARGE_HIT_OBSTACLE)
	if(obstacle)
		bull.visible_message(span_big(span_bolddanger("[bull] slams headfirst into [obstacle] and staggers!")))
		playsound(obstacle, 'sound/effects/bang.ogg', 80, TRUE)
		if(iswallturf(obstacle))
			var/turf/closed/wall/wall = obstacle
			wall.add_dent(WALL_DENT_HIT)
	bull.apply_damage(recoil_damage, BRUTE)
	bull.Stun(stun, ignore_canstun = TRUE)
	bull.do_jitter_animation(20)
	// Whoever's riding us keeps going when we stop
	var/datum/component/riding/creature/riding = bull.GetComponent(/datum/component/riding/creature)
	for(var/mob/living/rider in LAZYCOPY(bull.buckled_mobs))
		riding?.force_dismount(rider, throw_range = 3)

/datum/action/cooldown/mob_cooldown/bull_charge/proc/abort_charge(datum/source)
	SIGNAL_HANDLER
	if(charging)
		end_charge(BULL_CHARGE_ABORTED)

/datum/action/cooldown/mob_cooldown/bull_charge/proc/end_charge(result)
	if(!charging)
		return
	charging = FALSE
	actively_moving = FALSE
	for(var/timer in windup_timers)
		deltimer(timer)
	windup_timers = null
	target_ref = null
	aim_turf = null
	if(owner)
		UnregisterSignal(owner, list(COMSIG_MOVABLE_PRE_MOVE, COMSIG_MOVABLE_BUMP, COMSIG_MOVABLE_MOVED, COMSIG_LIVING_DEATH))
	if(charge_loop)
		UnregisterSignal(charge_loop, list(COMSIG_MOVELOOP_PREPROCESS_CHECK, COMSIG_MOVELOOP_POSTPROCESS, COMSIG_QDELETING))
		qdel(charge_loop)
		charge_loop = null
	if(QDELETED(owner))
		return
	if(result == BULL_CHARGE_ABORTED)
		StartCooldown(miss_cooldown, post_charge_melee_cooldown)
	else if(result == BULL_CHARGE_MISSED)
		owner.visible_message(span_notice("[owner] skids to a halt and snorts, looking around."))
		StartCooldown(miss_cooldown, post_charge_melee_cooldown)
	else
		StartCooldown(cooldown_time, post_charge_melee_cooldown)
	SEND_SIGNAL(owner, COMSIG_FINISHED_CHARGE)

/// Is this target wearing or waving anything red, or covered in blood?
/proc/bull_sees_red(atom/target)
	if(!isliving(target))
		return FALSE
	var/mob/living/living_target = target
	if(GET_ATOM_BLOOD_DNA_LENGTH(living_target) || is_bull_red(living_target.color))
		return TRUE
	for(var/obj/item/thing as anything in living_target.get_equipped_items(INCLUDE_HELD))
		if(GET_ATOM_BLOOD_DNA_LENGTH(thing) || is_bull_red(thing.color))
			return TRUE
		if(thing.greyscale_colors)
			for(var/colour in splittext(thing.greyscale_colors, "#"))
				if(colour && is_bull_red("#[colour]"))
					return TRUE
		var/static/regex/red_name = regex(@"\b(red|crimson|scarlet|bloody)\b", "i")
		if(red_name.Find(thing.name))
			return TRUE
	return FALSE

/// Is this colour red enough to set a bull off?
/proc/is_bull_red(colour)
	if(!istext(colour) || length(colour) < 7)
		return FALSE
	var/list/hsl = rgb2num(colour, COLORSPACE_HSL)
	if(length(hsl) < 3)
		return FALSE
	var/hue = hsl[1]
	return (hue <= 20 || hue >= 340) && hsl[2] >= 45 && hsl[3] >= 15 && hsl[3] <= 75

/**
 * Gore a mob: brute damage, maybe a wound, and a trip through the air.
 * Shared by the bull's charge and its regular melee attacks.
 */
/proc/bull_gore(mob/living/bull, mob/living/victim, damage, fling_range, fling_dir, max_wound_severity = WOUND_SEVERITY_MODERATE, knockdown = 1 SECONDS, toss_chance = 0, wound_chance = 0)
	victim.visible_message(
		span_danger("[bull] gores [victim] and sends [victim.p_them()] flying!"),
		span_userdanger("[bull] gores you and sends you flying!"),
	)
	playsound(victim, 'sound/effects/meteorimpact.ogg', 100, TRUE)
	shake_camera(victim, 4, 3)

	var/zone = pick(BODY_ZONE_CHEST, BODY_ZONE_CHEST, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM)
	if(damage > 0)
		victim.apply_damage(damage, BRUTE, zone, wound_bonus = 0, bare_wound_bonus = 5, sharpness = SHARP_POINTY)
	if(iscarbon(victim) && prob(wound_chance))
		var/mob/living/carbon/carbon_victim = victim
		var/obj/item/bodypart/limb = carbon_victim.get_bodypart(zone) || carbon_victim.get_bodypart(BODY_ZONE_CHEST)
		if(limb)
			carbon_victim.cause_wound_of_type_and_severity(pick(WOUND_BLUNT, WOUND_PIERCE), limb, WOUND_SEVERITY_MODERATE, max_wound_severity, WOUND_PICK_LOWEST_SEVERITY, bull)

	victim.Knockdown(knockdown)
	if(fling_range <= 0 || victim.anchored)
		return
	if(prob(toss_chance))
		bull_toss(bull, victim, fling_dir, fling_range)
		return
	victim.throw_at(get_ranged_target_turf(victim, fling_dir, fling_range), fling_range, 3, bull, gentle = FALSE)

/// Mobs currently in the air from a bull toss, associated with the pass flags we gave them
GLOBAL_LIST_EMPTY(bull_tossed_mobs)

/// How high (in pixels) a tossed mob goes
#define BULL_TOSS_HEIGHT 28

/**
 * Toss someone high into the air, doing flips the whole way.
 * Half the time they go right over the bull's head and land behind it.
 */
/proc/bull_toss(mob/living/bull, mob/living/victim, fling_dir, fling_range)
	var/toss_dir = prob(50) ? REVERSE_DIR(fling_dir) : fling_dir
	var/toss_range = max(fling_range - 1, 3)
	victim.visible_message(
		span_danger("[bull] tosses [victim] high into the air!"),
		span_userdanger("[bull] tosses you high into the air! WHOA!"),
	)
	// Sail over the bull and any tables on the way
	var/added_pass_flags = (PASSMOB | PASSTABLE) & ~victim.pass_flags
	victim.pass_flags |= added_pass_flags
	victim.SpinAnimation(0.3 SECONDS, rand(2, 4))
	animate(victim, pixel_z = BULL_TOSS_HEIGHT, time = 0.4 SECONDS, easing = SINE_EASING | EASE_OUT, flags = ANIMATION_PARALLEL | ANIMATION_RELATIVE)
	GLOB.bull_tossed_mobs[victim] = added_pass_flags
	var/datum/callback/land = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(bull_toss_land), victim)
	// Backup in case the throw gets cancelled without landing
	addtimer(land, 3 SECONDS)
	victim.throw_at(get_ranged_target_turf(victim, toss_dir, toss_range), toss_range, 1, bull, spin = FALSE, callback = land, gentle = FALSE)

/// Coming back down from a toss
/proc/bull_toss_land(mob/living/victim)
	if(!(victim in GLOB.bull_tossed_mobs))
		return
	var/added_pass_flags = GLOB.bull_tossed_mobs[victim]
	GLOB.bull_tossed_mobs -= victim
	if(QDELETED(victim))
		return
	victim.pass_flags &= ~added_pass_flags
	animate(victim, pixel_z = -BULL_TOSS_HEIGHT, time = 0.15 SECONDS, easing = SINE_EASING | EASE_IN, flags = ANIMATION_PARALLEL | ANIMATION_RELATIVE)
	victim.visible_message(span_danger("[victim] crashes back down!"), span_userdanger("You crash back down!"))
	playsound(victim, 'sound/effects/hit_kick.ogg', 60, TRUE)
	victim.apply_damage(5, BRUTE)
	victim.Knockdown(1 SECONDS)

#undef BULL_TOSS_HEIGHT

/// How far a door rammed by a bull flies
#define BULL_DOOR_FLING_RANGE 8
/// Damage a flying door does to whoever it lands on
#define BULL_DOOR_CRUSH_DAMAGE 40
/// Chance the flying door crits whoever it lands on
#define BULL_DOOR_CRIT_CHANCE 10
/// How long whoever the door lands on stays down
#define BULL_DOOR_PARALYZE (3 SECONDS)

/**
 * A door a bull rammed off its frame. Flies through the air and crushes whoever it hits like a falling vending machine,
 * then stays where it crashed down as a solid obstacle until it's broken apart.
 * Same idea as the chicken mask's door kick.
 */
/obj/structure/bull_flung_door
	name = "rammed-in door"
	desc = "Something big rammed this clean off its frame. It's wedged in the way; you'll have to break it apart to get past."
	density = TRUE
	anchored = FALSE
	max_integrity = 150
	/// Direction we were flung in
	var/fling_dir
	/// Have we hit someone or landed yet?
	var/landed = FALSE

/obj/structure/bull_flung_door/Initialize(mapload, obj/door)
	. = ..()
	if(door)
		appearance = door.appearance
		name = "rammed-in [door.name]"
		desc = initial(desc)
		density = TRUE
		layer = ABOVE_MOB_LAYER
	RegisterSignal(src, COMSIG_MOVABLE_THROW_LANDED, PROC_REF(on_landed))

/obj/structure/bull_flung_door/proc/launch(direction)
	fling_dir = direction
	var/turf/target = get_ranged_target_turf(src, direction, BULL_DOOR_FLING_RANGE)
	throw_at(target, BULL_DOOR_FLING_RANGE, 3, spin = FALSE)

/obj/structure/bull_flung_door/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(landed || !isliving(hit_atom))
		return
	landed = TRUE
	fall_and_crush(get_turf(hit_atom), BULL_DOOR_CRUSH_DAMAGE, BULL_DOOR_CRIT_CHANCE, null, BULL_DOOR_PARALYZE, fling_dir)
	lie_flat(FALSE)

/// Flew its full distance, or hit a wall
/obj/structure/bull_flung_door/proc/on_landed(datum/source, atom/movable/thrown_object, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER
	if(landed)
		return
	landed = TRUE
	playsound(src, 'sound/effects/bang.ogg', 60, TRUE)
	lie_flat(TRUE)

/// Crashes down where it landed, still blocking the way until someone breaks it apart
/obj/structure/bull_flung_door/proc/lie_flat(rotate = TRUE)
	density = TRUE
	anchored = TRUE
	layer = ABOVE_OBJ_LAYER
	if(rotate)
		transform = turn(transform, pick(90, 270))

/obj/structure/bull_flung_door/atom_deconstruct(disassembled = TRUE)
	new /obj/item/stack/sheet/iron(drop_location(), 2)

#undef BULL_DOOR_FLING_RANGE
#undef BULL_DOOR_CRUSH_DAMAGE
#undef BULL_DOOR_CRIT_CHANCE
#undef BULL_DOOR_PARALYZE

/obj/effect/temp_visual/telegraphing/bull_charge
	icon = 'icons/mob/telegraphing/telegraph.dmi'
	icon_state = "target_circle"
	color = COLOR_RED
	duration = 0.6 SECONDS

#undef BULL_CHARGE_MISSED
#undef BULL_CHARGE_HIT_MOB
#undef BULL_CHARGE_HIT_OBSTACLE
#undef BULL_CHARGE_ABORTED
