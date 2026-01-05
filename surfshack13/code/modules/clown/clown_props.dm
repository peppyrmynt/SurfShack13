/obj/item/clown_prop
	// -1 =  infinite uses
	var/uses_left = -1
	// cooldown amount if any, set with prop_cooldown = world.time + amount
	var/prop_cooldown

/obj/item/clown_prop/examine_more(mob/user)
	. = ..()
	to_chat(user, span_info("It has [(uses_left == -1) ? "infinite" : "[uses_left]"] uses left"))

/obj/item/clown_prop/attack_self(mob/living/carbon/human/user, modifiers)
	// we dont want WEIRDOS or NAKED clowns to use this
	if(!is_clown_job(user.mind?.assigned_role) || !istype(user.w_uniform, /obj/item/clothing/under/rank/civilian/clown))
		to_chat(user, span_notice("You are not silly enough to use [src]"))
		return
	if(prop_cooldown && (world.time < prop_cooldown))
		to_chat(user, span_notice("\The [src] is still reseting."))
		return
	if(uses_left > 0)
		uses_left --
	activate(user)
	if(!uses_left)
		Destroy()

/obj/item/clown_prop/proc/activate(mob/user)
	return

/obj/item/clown_prop/spinning_banana
	icon_state = "spinning_banana"
	icon = 'surfshack13/icons/clown_props.dmi'
	name = "banana-copter"
	desc = "A long string fixed to a banana. It's banned intergalactically from use in circuses."
	uses_left = 5


#define STEPTIME 1.5
#define SEQUENCE_LENGTH 4
#define CYCLES 11
#define TIME STEPTIME * SEQUENCE_LENGTH * CYCLES

/obj/item/clown_prop/spinning_banana/activate(mob/living/user)
	user.visible_message(span_suicide("[user] ties the banana to \his waist and starts flailing"), span_suicide("you tie the banana around your waist and flail"))
	var/obj/banana = new /obj/effect/()
	banana.icon = 'surfshack13/icons/clown_props.dmi'
	banana.icon_state = "banana_out"
	banana.pixel_y = -7
	banana.layer = FLY_LAYER
	user.vis_contents += banana
	var/matrix/banana_matrix = matrix()

	lock_dir(user, SOUTH, time = TIME)
	user.Immobilize(TIME)
	QDEL_IN(banana, (TIME)-2)
	prop_cooldown = world.time + (TIME)
	playsound(user, 'surfshack13/sound/banana_spin.ogg', 50, vary=FALSE)
	for(var/i in 1 to CYCLES)

		animate(user, time= STEPTIME, pixel_z =  1, flags = ANIMATION_CONTINUE)
		animate(time= STEPTIME, pixel_z =  0)
		animate(time= STEPTIME, pixel_z = -1)
		animate(time= STEPTIME, pixel_z =  0)

		#define BANANA_SEQUENCE_LENGTH 3
		animate(banana, time = (STEPTIME * SEQUENCE_LENGTH) / BANANA_SEQUENCE_LENGTH, transform = banana_matrix.Turn(360/BANANA_SEQUENCE_LENGTH), flags = ANIMATION_CONTINUE)
		animate(time = (STEPTIME * SEQUENCE_LENGTH) / BANANA_SEQUENCE_LENGTH, transform = banana_matrix.Turn(360/BANANA_SEQUENCE_LENGTH))
		animate(time = (STEPTIME * SEQUENCE_LENGTH) / BANANA_SEQUENCE_LENGTH, transform = banana_matrix.Turn(360/BANANA_SEQUENCE_LENGTH))
		#undef BANANA_SEQUENCE_LENGTH

#undef STEPTIME
#undef SEQUENCE_LENGTH
#undef CYCLES
#undef TIME

/obj/item/clown_prop/proc/lock_dir(mob/user, direction=SOUTH, time)
	user.dir = direction
	RegisterSignal(user, COMSIG_ATOM_PRE_DIR_CHANGE, PROC_REF(user_tried_turn), override =  TRUE)
	addtimer(CALLBACK(src, TYPE_PROC_REF(/datum, UnregisterSignal), user, COMSIG_ATOM_PRE_DIR_CHANGE), time)

/obj/item/clown_prop/proc/user_tried_turn(mob/user)
	SIGNAL_HANDLER
	return COMPONENT_ATOM_BLOCK_DIR_CHANGE
