

/mob/living/basic/crocodile
	name = "maintenance crocodile"
	desc = "A large and formerly aquatic reptile with a nasty temperment"
	icon = 'surfshack13/icons/mob/maint_croc.dmi'
	icon_state = "croc"
	icon_dead = "croc_dead"
	generic_canpass = FALSE
	mob_size = MOB_SIZE_LARGE
	SET_BASE_PIXEL(-9, -9)
	/// if we are deathrolling
	var/is_in_deathroll = FALSE

/mob/living/basic/crocodile/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS, INNATE_TRAIT)

/mob/living/basic/crocodile/attacked_by(obj/item/attacking_item, mob/living/user)
	if(ishuman(user))
		death_spin(user)
	else
		return ..()

/mob/living/basic/crocodile/UnarmedAttack(mob/living/simple_animal/user, list/modifiers)
	if(!ishuman(user))
		return ..()
	is_in_deathroll = TRUE
	death_spin(user)
	is_in_deathroll = FALSE


/mob/living/basic/crocodile/proc/death_spin(mob/living/carbon/human/florida)
	if(!florida || !istype(florida))
		return
	var/dx = x - florida.x
	var/dy = y - florida.y
	//cardinals only
	if(dx && dy)
		return

	var/list/legs = list()
	for(var/obj/item/bodypart/leg/leg in florida.bodyparts)
		legs += leg
	if(!length(legs))
		return


	var/degrees = 90
	var/pix_x
	var/pix_y
	if(abs(dx) < abs(dy))
		if(dy > 0)
			degrees = 180
			dir = SOUTH
			pix_y = -32
		else
			degrees = 0
			dir = NORTH
			pix_y = 32
	else
		if(dx > 0)
			degrees = 270
			dir = WEST
			pix_x = -32
		else
			degrees = 90
			dir = EAST
			pix_x = 32

	RegisterSignal(src, COMSIG_ATOM_PRE_DIR_CHANGE, PROC_REF(on_dir_change))
	buckle_mob(florida, force = TRUE, check_loc = FALSE)
	layer = ABOVE_MOB_LAYER
	ADD_TRAIT(florida, TRAIT_CANNOT_BE_UNBUCKLED, REF(src))
	ADD_TRAIT(florida, TRAIT_RESTRAINED, REF(src))
	florida.transform = matrix().Turn(degrees)
	if(pix_x)
		florida.pixel_x = pix_x
		florida.pixel_y = 0
	if(pix_y)
		florida.pixel_x = 0
		florida.pixel_y = pix_y

	//rip off shoes
	var/obj/shoes = florida.shoes

	if(shoes)
		florida.dropItemToGround(shoes)

	for(var/i in 1 to 24)
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
	unbuckle_mob(florida)
	layer = initial(layer)
	REMOVE_TRAIT(florida, TRAIT_CANNOT_BE_UNBUCKLED, REF(src))
	REMOVE_TRAIT(florida, TRAIT_RESTRAINED, REF(src))
	UnregisterSignal(src, COMSIG_ATOM_PRE_DIR_CHANGE)
	florida.transform = null
	florida.pixel_x = initial(florida.pixel_x)
	florida.pixel_y = initial(florida.pixel_y)
	icon_state = "croc"
	var/obj/item/bodypart/ripped_limb = pick(legs)
	ripped_limb.dismember()
	//nomnomnom
	ripped_limb.forceMove(src)
	return TRUE

/mob/living/basic/crocodile/proc/on_dir_change()
	SIGNAL_HANDLER
	return COMPONENT_ATOM_BLOCK_DIR_CHANGE
