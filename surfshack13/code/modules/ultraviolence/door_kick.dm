/// How far a kicked door flies.
#define DOOR_KICK_RANGE 10
/// How fast a kicked door flies.
#define DOOR_KICK_SPEED 3
/// Time between door kicks.
#define DOOR_KICK_COOLDOWN (3 SECONDS)
/// Damage a flying door does to whoever it lands on. Same as a vending machine falling on you.
#define KICKED_DOOR_CRUSH_DAMAGE 75
/// Chance a flying door lands on someone in a spectacular way. Same as a vending machine.
#define KICKED_DOOR_CRIT_CHANCE 15
/// How long whoever the door lands on stays down.
#define KICKED_DOOR_PARALYZE (6 SECONDS)

/// Can the chicken mask kick this off its hinges?
/proc/is_kickable_door(atom/target)
	if(!istype(target, /obj/machinery/door/airlock) && !istype(target, /obj/machinery/door/window) && !istype(target, /obj/structure/mineral_door))
		return FALSE
	var/obj/door = target
	if(!door.density || (door.resistance_flags & INDESTRUCTIBLE))
		return FALSE
	return TRUE

/// Right click on a door with an empty hand.
/datum/component/chicken_rampage/proc/on_unarmed_kick(mob/living/source, atom/target, proximity, modifiers)
	SIGNAL_HANDLER

	if(!proximity || !LAZYACCESS(modifiers, RIGHT_CLICK))
		return NONE
	return try_kick_door(source, target) ? COMPONENT_CANCEL_ATTACK_CHAIN : NONE

/// Right click on a door with something in hand.
/datum/component/chicken_rampage/proc/on_item_kick(mob/living/source, atom/target, obj/item/tool, list/modifiers)
	SIGNAL_HANDLER

	return try_kick_door(source, target) ? ITEM_INTERACT_SUCCESS : NONE

/// Returns TRUE if we handled the click (kicked the door or it's on cooldown).
/datum/component/chicken_rampage/proc/try_kick_door(mob/living/kicker, atom/target)
	if(!is_kickable_door(target) || !kicker.Adjacent(target) || HAS_TRAIT(kicker, TRAIT_INCAPACITATED))
		return FALSE
	if(!COOLDOWN_FINISHED(src, door_kick_cooldown))
		kicker.balloon_alert(kicker, "catching your breath!")
		return TRUE
	COOLDOWN_START(src, door_kick_cooldown, DOOR_KICK_COOLDOWN)
	INVOKE_ASYNC(src, PROC_REF(kick_door), kicker, target)
	return TRUE

/// Boots the door off its frame and sends it flying.
/datum/component/chicken_rampage/proc/kick_door(mob/living/kicker, obj/door)
	if(QDELETED(door))
		return
	var/kick_dir = get_dir(kicker, door)
	var/turf/door_turf = get_turf(door)
	kicker.do_attack_animation(door, ATTACK_EFFECT_KICK)
	kicker.visible_message(
		span_danger("[kicker] kicks [door] clean off its frame!"),
		span_danger("You kick [door] clean off its frame!"),
		span_hear("You hear a deafening crash!"),
	)
	playsound(door_turf, 'sound/effects/meteorimpact.ogg', 70, TRUE)
	playsound(door_turf, 'sound/effects/bang.ogg', 70, TRUE)
	shake_camera(kicker, 2, 2)
	log_combat(kicker, door, "kicked down (chicken mask)")

	var/obj/structure/kicked_door/flying_door = new(door_turf, door, kicker)
	qdel(door)
	record?.doors_kicked++
	flying_door.launch(kick_dir)

/**
 * A door that's been kicked off its hinges. Flies through the air, and whoever it hits gets crushed like a vending machine
 * fell on them. Afterwards it stays where it crashed down as a solid obstacle until it's broken apart.
 */
/obj/structure/kicked_door
	name = "kicked-in door"
	desc = "Someone kicked this clean off its frame. It's wedged in the way; you'll have to break it apart to get past."
	density = TRUE
	anchored = FALSE
	max_integrity = 150
	/// Who kicked us, so the crush counts towards their rampage.
	var/datum/weakref/kicker_ref
	/// Direction we were kicked in.
	var/kick_dir
	/// Have we hit someone or landed yet?
	var/landed = FALSE

/obj/structure/kicked_door/Initialize(mapload, obj/door, mob/living/kicker)
	. = ..()
	if(door)
		appearance = door.appearance
		name = "kicked-in [door.name]"
		desc = initial(desc)
		density = TRUE
		layer = ABOVE_MOB_LAYER
		plane = GAME_PLANE
	kicker_ref = WEAKREF(kicker)
	RegisterSignal(src, COMSIG_MOVABLE_THROW_LANDED, PROC_REF(on_landed))

/// Sends the door flying.
/obj/structure/kicked_door/proc/launch(direction)
	kick_dir = direction
	var/turf/target = get_ranged_target_turf(src, direction, DOOR_KICK_RANGE)
	throw_at(target, DOOR_KICK_RANGE, DOOR_KICK_SPEED, kicker_ref?.resolve(), spin = FALSE)

/obj/structure/kicked_door/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(landed || !isliving(hit_atom))
		return
	var/mob/living/victim = hit_atom
	landed = TRUE
	var/health_before = victim.health
	fall_and_crush(get_turf(victim), KICKED_DOOR_CRUSH_DAMAGE, KICKED_DOOR_CRIT_CHANCE, null, KICKED_DOOR_PARALYZE, kick_dir)
	lie_flat(FALSE)

	// Counts as a hit (and possibly a kill) for whoever kicked it.
	var/mob/living/kicker = kicker_ref?.resolve()
	var/damage_done = health_before - victim.health
	if(kicker && damage_done > 0)
		SEND_SIGNAL(kicker, COMSIG_MOB_ATTACK_LANDED, victim, damage_done, BRUTE, BODY_ZONE_CHEST, NONE, src)

/// Flew its full distance, or hit a wall.
/obj/structure/kicked_door/proc/on_landed(datum/source, atom/movable/thrown_object, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER
	if(landed)
		return
	landed = TRUE
	playsound(src, 'sound/effects/bang.ogg', 60, TRUE)
	lie_flat(TRUE)

/// Crashes down where it landed. Still solid: it blocks the way like a barricade until someone breaks it apart.
/obj/structure/kicked_door/proc/lie_flat(rotate = TRUE)
	density = TRUE
	anchored = TRUE
	layer = ABOVE_OBJ_LAYER
	if(rotate)
		transform = turn(transform, pick(90, 270))

/obj/structure/kicked_door/atom_deconstruct(disassembled = TRUE)
	new /obj/item/stack/sheet/iron(drop_location(), 2)

#undef DOOR_KICK_RANGE
#undef DOOR_KICK_SPEED
#undef DOOR_KICK_COOLDOWN
#undef KICKED_DOOR_CRUSH_DAMAGE
#undef KICKED_DOOR_CRIT_CHANCE
#undef KICKED_DOOR_PARALYZE
