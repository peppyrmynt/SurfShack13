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
	icon = 'surfshack13/icons/obj/bowling_ball.dmi'
	worn_y_offset = 4
	worn_icon = 'surfshack13/icons/mob/head.dmi'
	righthand_file = 'surfshack13/icons/mob/inhands/lefthand.dmi'
	lefthand_file = 'surfshack13/icons/mob/inhands/lefthand.dmi'
	force = 6
	w_class = WEIGHT_CLASS_NORMAL
	throwforce = 10
	throw_range = 2
	throw_speed = 1
	var/pro_wielded = FALSE
	body_parts_covered = HEAD
	slot_flags = ITEM_SLOT_HEAD


/obj/item/bowling_ball/Initialize()
	. = ..()
	color = pick("gray", "red", "magenta", "lime", "yellow", "cyan", "blue", "teal", "black")
	ADD_TRAIT(src, TRAIT_UNCATCHABLE, TRAIT_GENERIC)

/obj/item/bowling_ball/throw_at(atom/target, range = 150, speed, mob/thrower, spin, diagonals_first, datum/callback/callback, force, gentle, quickstart)
	if(!ishuman(thrower))
		return ..()
	icon_state = "bowling_ball_spin"
	target = get_edge_target_turf(target, thrower.dir)
	spin = FALSE
	range = 150
	playsound(src,'surfshack13/sound/effects/bowl.ogg',40,0)
	var/mob/living/carbon/human/user = thrower
	if(user.w_uniform && istype(user.w_uniform, /obj/item/clothing/under/bowling_jersey))
		pro_wielded = TRUE
	return ..()


/obj/item/bowling_ball/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	icon_state = "bowling_ball"
	if(!iscarbon(hit_atom))
		pro_wielded = FALSE
		return ..()
	var/mob/living/carbon/target_mob = hit_atom
	if(pro_wielded || iscarbon(hit_atom) || !target_mob.body_position == LYING_DOWN)
		playsound(src, 'surfshack13/sound/effects/bowlhit.ogg', 60, 0)
		target_mob.Knockdown(50)
		target_mob.adjustBruteLoss(15) // + throw damage = 25 hit ouch!
	pro_wielded = FALSE
	return ..()


