/obj/item/clothing/shoes/bowling
	name = "bowling shoes"
	desc = "Made for use in only the finest bowling alleys."
	icon_state = "bowling_shoes"
	worn_icon_state = "bowling_shoes"
	inhand_icon_state = "sneakers_back"
	icon = 'surfshack13/icons/obj/clothing/shoes.dmi'
	worn_icon = 'surfshack13/icons/mob/feet.dmi'
	slowdown = -0.3

/obj/item/clothing/under/bowling_jersey
	name = "bowling jersey"
	desc = "The latest in kingpin fashion. \
	Nanites sewn in the sleeve increase bowling power"
	icon_state = "bowling_jersey"
	worn_icon_state = "bowling_jersey"
	inhand_icon_state = "lb_suit"
	icon = 'surfshack13/icons/obj/clothing/uniforms.dmi'
	worn_icon = 'surfshack13/icons/mob/uniform.dmi'

/obj/item/bowling_ball
	name = "bowling ball"
	desc = "A heavy, round device used to knock pins (or people) down."
	icon_state = "bowling_ball"
	inhand_icon_state = "bowling_ball"
	icon = 'surfshack13/icons/obj/bowling.dmi'
	worn_y_offset = 4
	worn_icon = 'surfshack13/icons/mob/head.dmi'
	righthand_file = 'surfshack13/icons/mob/inhands/righthand.dmi'
	lefthand_file = 'surfshack13/icons/mob/inhands/lefthand.dmi'
	force = 6
	w_class = WEIGHT_CLASS_NORMAL
	throwforce = 10
	throw_range = 1
	throw_speed = 1
	var/pro_wielded = FALSE
	body_parts_covered = HEAD
	slot_flags = ITEM_SLOT_HEAD
	/// used for noise check
	var/play_pin_sound_on_hit = FALSE


/obj/item/bowling_ball/Initialize()
	. = ..()
	color = pick("gray", "red", "magenta", "lime", "yellow", "cyan", "blue", "teal")
	ADD_TRAIT(src, TRAIT_UNCATCHABLE, TRAIT_GENERIC)

/obj/item/bowling_ball/throw_at(atom/target, range = 150, speed, mob/thrower, spin, diagonals_first, datum/callback/callback, force, gentle, quickstart)
	if(!iscarbon(thrower))
		return ..()
	icon_state = "bowling_ball_spin"
	playsound(src,'surfshack13/sound/effects/bowl.ogg',40,0)
	var/mob/living/carbon/human/user = thrower
	if(user.w_uniform && istype(user.w_uniform, /obj/item/clothing/under/bowling_jersey))
		pro_wielded = TRUE

	//ball spins in sprite
	spin = FALSE
	target = get_edge_target_turf(target, thrower.dir)
	range = 150
	play_pin_sound_on_hit = TRUE
	return ..()

/obj/item/bowling_ball/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	play_pin_sound_on_hit = FALSE
	icon_state = "bowling_ball"
	if(pro_wielded || prob(10))
		pro_wielded = FALSE
		var/mob/living/carbon/target_mob = hit_atom
		if(iscarbon(hit_atom) && target_mob.body_position == STANDING_UP && throwingdatum.dist_travelled > 1)
			playsound(src, 'surfshack13/sound/effects/bowlhit.ogg', 60, 0)
			target_mob.Knockdown(60)
			target_mob.adjustBruteLoss(15) // + throw damage = 25 hit, ouch!
	return ..()

//so if you hit a line of pins they dont all get spam sound.
/obj/item/bowling_ball/proc/knocked_pin()
	if(!play_pin_sound_on_hit)
		return
	playsound(src, 'surfshack13/sound/effects/bowlhit.ogg', 60, 0)
	play_pin_sound_on_hit = FALSE

/obj/item/bowling_ball/suicide_act(mob/living/user)
	visible_message(span_suicide("[user] throws \the [src] but refuses to let go sending themselves flying!"), span_suicide("you throw \the [src] but dont let go, sending yourself flying."))
	src.forceMove(user)
	var/datum/callback/gib_user = new(src, PROC_REF(on_body_hit), user)
	user.throw_at(target = get_edge_target_turf(user, user.dir), range = 150, speed = 1, thrower = user, spin = TRUE, callback = gib_user)
	playsound(src,'surfshack13/sound/effects/bowl.ogg',40,0)
	return BRUTELOSS

/obj/item/bowling_ball/proc/on_body_hit(mob/living/user)
	playsound(src, 'surfshack13/sound/effects/bowlhit.ogg', 60, 0)
	user.gib(DROP_ITEMS|DROP_ORGANS)

/obj/item/bowling_pins
	name = "bowling pins"
	desc = "A set of four bowling pins, they can be placed."
	icon = 'surfshack13/icons/obj/bowling.dmi'
	icon_state = "bowling_pins"
	inhand_icon_state = "bowling_pins"
	/// if the pins are standing up
	var/standing = FALSE


/obj/item/bowling_pins/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isfloorturf(interacting_with))
		return NONE
	var/turf/T = interacting_with
	for(var/atom/A in interacting_with)
		if(A.density)
			return NONE
	src.forceMove(T)
	toggle_standing(TRUE)
	return ITEM_INTERACT_SUCCESS

/obj/item/bowling_pins/proc/toggle_standing(stand)
	standing = stand
	icon_state = "bowling_pins[standing ? "_standing" : ""]"
	if(standing && isturf(loc))
		playsound(src, 'sound/effects/glass/glassbash.ogg', 30)
		pixel_y = 2
		RegisterSignal(src ,COMSIG_MOVABLE_CROSS, PROC_REF(on_entered))
		RegisterSignal(src ,COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	else if(!standing)
		pixel_y = 0
		UnregisterSignal(src, list(COMSIG_MOVABLE_CROSS, COMSIG_MOVABLE_MOVED))

/obj/item/bowling_pins/proc/on_moved()
	SIGNAL_HANDLER
	toggle_standing(FALSE)

/obj/item/bowling_pins/proc/on_entered(datum/source, atom/movable/AM as mob|obj)
	SIGNAL_HANDLER
	if(ismob(AM))
		var/mob/living/MM = AM
		if(!(MM.movement_type & MOVETYPES_NOT_TOUCHING_GROUND) && MM.mob_size > MOB_SIZE_SMALL)
			toggle_standing(FALSE)
	else if(isobj(AM))
		if(istype(AM, /obj/item/bowling_ball))
			var/obj/item/bowling_ball/ball = AM
			// the sound is handled on the ball so it we can prevent noise spam, it only plays once per throw.
			ball.knocked_pin()
			toggle_standing(FALSE)
		if(AM.density)
			toggle_standing(FALSE)


/datum/supply_pack/imports/bowling_kit
	name = "Bowling Crate"
	desc = "Bowling supplies have been tightly regulated after a classified incident involving several interns, a clown, and a very long hallway. This has allowed smugglers to hike the price."
	cost = CARGO_CRATE_VALUE * 15
	contraband = TRUE
	contains = list(
		/obj/item/bowling_ball = 4,
		/obj/item/bowling_pins = 3,
		/obj/item/pizzabox/margherita = 1)


