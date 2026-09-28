/// A constructor can build this solid barrier on an open floor tile.
/obj/structure/flood_wall
	name = "Flood biomass wall"
	desc = "A solid barrier of hardened, pulsating Flood tissue."
	icon = 'icons/mob/flood/Flood_Spore.dmi'
	icon_state = "flood wall gif"
	anchored = TRUE
	density = TRUE
	opacity = TRUE
	layer = WALL_OBJ_LAYER
	max_integrity = 300
	can_atmos_pass = ATMOS_PASS_DENSITY

/obj/structure/flood_wall/Initialize(mapload)
	. = ..()
	air_update_turf(TRUE, TRUE)

/obj/structure/flood_wall/Destroy()
	air_update_turf(TRUE, FALSE)
	return ..()

/obj/structure/flood_wall/take_damage(damage_amount, damage_type = BRUTE, damage_flag = "", sound_effect = TRUE, attack_dir, armour_penetration = 0)
	if(damage_type == BURN)
		damage_amount *= 2
	return ..(damage_amount, damage_type, damage_flag, sound_effect, attack_dir, armour_penetration)

/obj/structure/flood_door
	name = "Flood biomass door"
	desc = "A fleshy membrane capable of sealing an infested passage."
	icon = 'icons/mob/flood/flood_door.dmi'
	icon_state = "flood"
	anchored = TRUE
	density = TRUE
	opacity = TRUE
	max_integrity = 350
	layer = CLOSED_DOOR_LAYER
	can_atmos_pass = ATMOS_PASS_DENSITY
	var/door_opened = FALSE
	var/close_delay = 5 SECONDS

/obj/structure/flood_door/Initialize(mapload)
	. = ..()
	air_update_turf(TRUE, TRUE)

/obj/structure/flood_door/Destroy()
	if(!door_opened)
		air_update_turf(TRUE, FALSE)
	return ..()

/obj/structure/flood_door/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	if(damage_type == BRUTE && damage_amount)
		playsound(src, 'sound/flood/flood_hit_sfx.ogg', 50, TRUE)
	else
		return ..()

/obj/structure/flood_door/take_damage(damage_amount, damage_type = BRUTE, damage_flag = "", sound_effect = TRUE, attack_dir, armour_penetration = 0)
	if(damage_type == BURN)
		damage_amount *= 2
	return ..(damage_amount, damage_type, damage_flag, sound_effect, attack_dir, armour_penetration)

/obj/structure/flood_door/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(door_opened)
		close_door()
	else
		open_door()
	return TRUE

/obj/structure/flood_door/attack_paw(mob/user, list/modifiers)
	return attack_hand(user, modifiers)

/obj/structure/flood_door/Bumped(atom/movable/mover)
	. = ..()
	if(istype(mover, /mob/living/basic/flood) && !door_opened)
		open_door()

/obj/structure/flood_door/proc/open_door()
	if(door_opened)
		return
	door_opened = TRUE
	playsound(src, 'sound/flood/flood_open.ogg', 60, TRUE)
	flick("floodopening", src)
	icon_state = "floodopen"
	set_opacity(FALSE)
	set_density(FALSE)
	layer = OPEN_DOOR_LAYER
	air_update_turf(TRUE, FALSE)
	addtimer(CALLBACK(src, PROC_REF(close_door)), close_delay)

/obj/structure/flood_door/proc/close_door()
	if(!door_opened)
		return
	for(var/mob/living/occupant in get_turf(src))
		addtimer(CALLBACK(src, PROC_REF(close_door)), close_delay)
		return
	flick("floodclosing", src)
	icon_state = "flood"
	set_density(TRUE)
	set_opacity(TRUE)
	layer = CLOSED_DOOR_LAYER
	door_opened = FALSE
	air_update_turf(TRUE, TRUE)

/obj/structure/flood_door/CanAllowThrough(atom/movable/mover, border_dir)
	if(istype(mover, /mob/living/basic/flood) && !door_opened)
		open_door()
	return ..()

/obj/structure/flood_window
	name = "Flood biomass membrane"
	desc = "A translucent mesh of Flood tissue stretched across the passage."
	icon = 'icons/mob/flood/flood_window.dmi'
	icon_state = "flood_window"
	anchored = TRUE
	density = TRUE
	max_integrity = 80
	can_atmos_pass = ATMOS_PASS_YES

/obj/structure/flood_window/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(!. && isprojectile(mover))
		return prob(30)

/obj/structure/flood_window/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	if(damage_type == BRUTE && damage_amount)
		playsound(src, 'sound/flood/flood_hit_sfx.ogg', 50, TRUE)
	else
		return ..()

/obj/structure/flood_window/take_damage(damage_amount, damage_type = BRUTE, damage_flag = "", sound_effect = TRUE, attack_dir, armour_penetration = 0)
	if(damage_type == BURN)
		damage_amount *= 2
	return ..(damage_amount, damage_type, damage_flag, sound_effect, attack_dir, armour_penetration)

