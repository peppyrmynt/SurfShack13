

/mob/living/basic/crocodile
	name = "maintenance crocodile"
	desc = "A crocodile adapted to life in maintenance tunnels, It has a nice pelt."
	icon = 'surfshack13/icons/mob/maint_croc.dmi'
	icon_state = "croc"
	icon_dead = "croc_dead"
	generic_canpass = FALSE
	mob_size = MOB_SIZE_LARGE
	SET_BASE_PIXEL(-9, -9)

/mob/living/basic/crocodile/UnarmedAttack(mob/living/simple_animal/user, list/modifiers)
	if(user == src)
		toggle_burrowing()
	if(!ishuman(user))
		return ..()
	death_spin(user)


/mob/living/basic/crocodile/proc/death_spin(mob/living/carbon/human/florida)
	var/list/legs = list()
	for(var/obj/item/bodypart/leg/leg in florida.bodyparts)
		legs += leg
	if(!length(legs))
		return

	var/dx = x - florida.x
	var/dy = y - florida.y
	var/degrees = 90
	if(abs(dx) < abs(dy))
		if(dy > 0)
			degrees = 180
		else
			degrees = 0
	else
		if(dx > 0)
			degrees = 270
		else
			degrees = 90

	florida.transform = matrix().Turn(degrees)
	for(var/i in 1 to 24)
		florida.pixel_y = 0
		florida.pixel_x = 0
		if(do_after(src, 2, florida, progress = FALSE))
			switch(florida.dir)
				if(SOUTH)
					florida.dir = EAST
					icon_state = "croc_east"
				if(EAST)
					florida.dir = NORTH
					icon_state = "croc_north"
				if(NORTH)
					florida.dir = WEST
					icon_state = "croc_west"
				if(WEST)
					florida.dir = SOUTH
					icon_state = "croc_south"

	florida.transform = null
	icon_state = "croc"
	var/obj/item/bodypart/ripped_limb = pick(legs)
	ripped_limb.dismember()
	//nomnomnom
	ripped_limb.forceMove(src)

