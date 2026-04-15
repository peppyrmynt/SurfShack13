#define STEP_TIME 2
#define CYCLES 5
#define ANIMATION_TIME (CYCLES * 4 * STEP_TIME)
#define ROLL_COOLDOWN_TIME ANIMATION_TIME + 1 SECONDS

//If I have to do another intensive animation, I will make a subsystem for it
/mob/living/basic/alligator
	name = "space alligator"
	desc = "A large and formerly aquatic reptile with a nasty temperment."
	icon = 'surfshack13/icons/mob/maint_croc.dmi'
	icon_state = "croc"
	icon_living = "croc"
	icon_dead = "croc_dead"
	gold_core_spawnable = HOSTILE_SPAWN
	mob_biotypes = MOB_ORGANIC | MOB_BEAST | MOB_AQUATIC
	mob_size = MOB_SIZE_LARGE
	health = 80
	maxHealth = 80
	melee_attack_cooldown = 1.5 SECONDS
	attack_sound = 'sound/items/weapons/bite.ogg'
	combat_mode = TRUE
	obj_damage = 10
	melee_damage_lower = 5
	melee_damage_upper = 10
	attack_sound = 'sound/items/weapons/bite.ogg'
	attack_vis_effect = ATTACK_EFFECT_BITE
	attack_verb_continuous = "chomps"
	attack_verb_simple = "chomp"
	faction = list(FACTION_LIZARD)
	ai_controller = /datum/ai_controller/basic_controller/alligator
	SET_BASE_PIXEL(-9, -9)
	/// if we are deathrolling this is set to the user
	var/mob/living/carbon/human/eating_victim
	/// cooldowns between deathrolls
	COOLDOWN_DECLARE(roll_cooldown)

//for ez badmin spawning
/mob/living/basic/alligator/croc

/mob/living/basic/alligator/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS, INNATE_TRAIT)
	var/list/desired_food = list(
		/obj/item/food/meat/slab,
		/obj/item/food/meat/rawcutlet,
		/obj/item/bodypart/arm,
		/obj/item/bodypart/leg,
		/mob/living/basic/frog,
		/mob/living/basic/axolotl,
		/mob/living/basic/chicken,
		/mob/living/basic/mouse
		)
	if(prob(1)) //*disk shaped thront... *burps...
		desired_food += /obj/item/disk/nuclear
		desc += " It likes floppy disks."
	AddElement(/datum/element/basic_eating, food_types = desired_food)
	ai_controller.set_blackboard_key(BB_BASIC_FOODS, typecacheof(desired_food))

/mob/living/basic/alligator/Destroy()
	if(eating_victim)
		reset_victim()
	. = ..()


/mob/living/basic/alligator/death(gibbed)
	. = ..()
	if(eating_victim)
		reset_victim()

/mob/living/basic/alligator/UnarmedAttack(mob/living/carbon/human/user, list/modifiers)
	if(eating_victim)
		return
	if(!istype(user))
		return ..()

	if(user.body_position == LYING_DOWN && death_roll(user))
		return
	else
		//have to hit them 3 times before they are on the ground and then finally we can rip off a leg
		var/stamina_damage
		switch(user.getStaminaLoss())
			if(0 to 5)
				stamina_damage = 6
			if(6 to 8)
				stamina_damage = 5
			if(9 to 10)
				stamina_damage = 4
			else
				user.Knockdown(SHOVE_KNOCKDOWN_SOLID)
		if(stamina_damage)
			user.adjustStaminaLoss(stamina_damage)
	return ..()



/// Check if the mob can be deathrolled, do the spin animation, and then rip off leg if all is well returns false on fail
/mob/living/basic/alligator/proc/death_roll(mob/living/carbon/human/florida)
	if(!florida || !istype(florida) || florida.body_position == LYING_DOWN)
		return FALSE

	if(!COOLDOWN_FINISHED(src, roll_cooldown))
		to_chat(src, span_notice("Your still dizzy from the last death roll, wait a second."))
		return FALSE
	if(HAS_TRAIT(florida, TRAIT_ON_ELEVATED_SURFACE) && !HAS_TRAIT(src, TRAIT_ON_ELEVATED_SURFACE))
		to_chat(src, "[florida] is too high up to grab and death roll.")
		return FALSE
	var/list/legs = list()
	for(var/obj/item/bodypart/leg/leg in florida.bodyparts)
		legs += leg
	if(!length(legs))
		to_chat(src, "[florida]\s legs are already gone!")
		return FALSE

	eating_victim = florida
	var/dx = x - florida.x
	var/dy = y - florida.y
	var/degrees = 90
	var/pix_x, pix_y
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
	RegisterSignal(florida, COMSIG_ATOM_PRE_DIR_CHANGE, PROC_REF(on_dir_change))
	buckle_mob(florida, force = TRUE, check_loc = FALSE)
	layer = ABOVE_ALL_MOB_LAYER
	florida.add_traits(list(TRAIT_CANNOT_BE_UNBUCKLED, TRAIT_INCAPACITATED, TRAIT_IMMOBILIZED, TRAIT_FLOORED, TRAIT_HANDS_BLOCKED), REF(src))
	florida.transform = matrix().Turn(degrees)
	if(pix_x)
		florida.pixel_x = pix_x
		florida.pixel_y = 0
	else
		florida.pixel_x = 0
		florida.pixel_y = pix_y

	//rip off shoes
	var/obj/shoes = florida.shoes
	if(shoes)
		florida.dropItemToGround(shoes)

	florida.visible_message(span_danger("\the [src] clamps down on your leg and starts death rolling. you feel your leg tearing!"),\
		span_notice("\the [src] clamps down on [florida]\s leg and starts to death roll."))
	COOLDOWN_START(src, roll_cooldown, ROLL_COOLDOWN_TIME)
	//spawn() is fine because lingmox fixed it in 1680, and I need motivation to move the codebase to 1680
	spawn(ANIMATION_TIME)
		if(!QDELETED(src) && !stat)
			icon_state = "croc"
			var/obj/item/bodypart/ripped_limb = pick(legs)
			ripped_limb.dismember()
			if(prob(50)) //nom nom
				ripped_limb.forceMove(src)
		reset_victim()
		layer = initial(layer)
		UnregisterSignal(src, COMSIG_ATOM_PRE_DIR_CHANGE)

	animate(florida, flags = ANIMATION_END_NOW)
	animate(src, flags = ANIMATION_END_NOW)
	for(var/i in 1 to CYCLES)
		animate(florida, time = STEP_TIME, dir = SOUTH, flags = ANIMATION_CONTINUE)
		animate(time = STEP_TIME, dir = EAST)
		animate(time = STEP_TIME, dir = NORTH)
		animate(time = STEP_TIME, dir = WEST)

		animate(src, time = STEP_TIME, icon_state = "croc_south", flags = ANIMATION_CONTINUE)
		animate(time = STEP_TIME, icon_state = "croc_east")
		animate(time = STEP_TIME, icon_state = "croc_north")
		animate(time = STEP_TIME, icon_state = "croc_west")
	return TRUE

/mob/living/basic/alligator/proc/reset_victim()
	if(!eating_victim)
		return

	if(eating_victim.buckled)
		unbuckle_mob(eating_victim)
	UnregisterSignal(eating_victim, COMSIG_ATOM_PRE_DIR_CHANGE)
	eating_victim.remove_traits(list(TRAIT_CANNOT_BE_UNBUCKLED, TRAIT_INCAPACITATED, TRAIT_IMMOBILIZED, TRAIT_FLOORED, TRAIT_HANDS_BLOCKED), REF(src))
	eating_victim.pixel_x = initial(eating_victim.pixel_x)
	if(eating_victim.body_position == LYING_DOWN)
		eating_victim.transform = matrix().Turn(GET_LYING_ANGLE(eating_victim))
		eating_victim.pixel_y = -4
	else
		eating_victim.transform = null
		eating_victim.pixel_y = initial(eating_victim.pixel_y)
	eating_victim = null


/mob/living/basic/alligator/proc/on_dir_change()
	SIGNAL_HANDLER
	return COMPONENT_ATOM_BLOCK_DIR_CHANGE

#undef CYCLES
#undef STEP_TIME
#undef ANIMATION_TIME
#undef ROLL_COOLDOWN_TIME
