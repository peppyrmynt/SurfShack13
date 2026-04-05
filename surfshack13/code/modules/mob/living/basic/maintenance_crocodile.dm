

/mob/living/basic/crocodile
	name = "maintenance crocodile"
	desc = "A crocodile adapted to life in maintenance tunnels, It has a nice pelt."
	icon = 'surfshack13/icons/mob/maint_croc.dmi'
	icon_state = "croc"
	icon_dead = "croc_dead"
	generic_canpass = FALSE
	mob_size = MOB_SIZE_LARGE
	SET_BASE_PIXEL(-9, -9)
	///if the croc is currently under floor
	var/is_hidden = FALSE
	///If the croc wants to be under floor
	var/should_hide = FALSE

/mob/living/basic/crocodile/proc/toggle_burrowing()
	if(!isturf(loc) || !do_after(src, 0.5 SECONDS, loc))
		return
	var/turf/T = loc
	should_hide = !should_hide
	if(length(T.baseturfs) > 1)
		if(isindestructiblefloor(T))
			return
		T.ScrapeAway(1)
		visible_message(span_notice("\the [src] burrows [should_hide ? "under" : "up from"] the floor."),\
			span_notice("you burrow [should_hide ? "under" : "up from"] the floor."))
	if(should_hide)
		RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
		RegisterSignal(src, COMSIG_MOVABLE_CAN_PASS_THROUGH, PROC_REF(on_try_to_passed))
		layer = ABOVE_NORMAL_TURF_LAYER
	else
		UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
		UnregisterSignal(src, COMSIG_MOVABLE_CAN_PASS_THROUGH)
		layer = initial(layer)
	on_moved()

/mob/living/basic/crocodile/proc/on_try_to_passed(datum/source, atom/blocker, movement_dir)
	SIGNAL_HANDLER
	if(is_type_in_typecache(blocker, GLOB.typecache_machine_or_structure))
		return COMSIG_COMPONENT_PERMIT_PASSAGE


/mob/living/basic/crocodile/proc/on_moved(datum/source, atom/old_loc, dir, forced, list/old_locs)
	SIGNAL_HANDLER
	var/turf/T = loc
	if(old_loc && old_loc.type == T.type)
		return
	var/hide = FALSE
	if(isturf(T))
		if(length(T.baseturfs) > 1)
			hide = TRUE
			if(istype(T, /turf/open/floor/catwalk_floor))
				hide = FALSE
				visible_message(span_notice("\The [src] gets on \the [T] ripping it apart!"),\
					span_notice("You get caught on \the [T], Destroying it and revealing yourself."))
				T.ScrapeAway(1)
		else
			hide = FALSE

	set_hidden(hide)

/mob/living/basic/crocodile/proc/set_hidden(hidden=TRUE)
	if(is_hidden == hidden)
		return
	if(hidden)
		SetInvisibility(INVISIBILITY_MAXIMUM, id=type)
		ADD_TRAIT(src, TRAIT_UNDERFLOOR, REF(src))
		ADD_TRAIT(src, TRAIT_T_RAY_VISIBLE, REF(src))
		SET_PLANE_IMPLICIT(src, FLOOR_PLANE)
		density = FALSE
		mob_size = MOB_SIZE_TINY
	else
		RemoveInvisibility(type)
		REMOVE_TRAIT(src, TRAIT_UNDERFLOOR, REF(src))
		REMOVE_TRAIT(src, TRAIT_T_RAY_VISIBLE, REF(src))
		SET_PLANE_IMPLICIT(src, initial(plane))
		density = TRUE
		mob_size = initial(mob_size)
	is_hidden = hidden

/mob/living/basic/crocodile/proc/t_scanned(mob/scanner)

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

