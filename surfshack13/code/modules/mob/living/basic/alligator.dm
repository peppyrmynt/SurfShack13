
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
	melee_damage_upper = 15
	attack_sound = 'sound/items/weapons/bite.ogg'
	attack_vis_effect = ATTACK_EFFECT_BITE
	attack_verb_continuous = "chomps"
	attack_verb_simple = "chomp"
	faction = list(FACTION_LIZARD)
	ai_controller = /datum/ai_controller/basic_controller/alligator
	SET_BASE_PIXEL(-9, -9)
	/// if we are deathrolling this is set to the user
	var/death_rolling_victim
	/// The victims original tranform to restore.
	var/initial_victim_transform

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

	AddElement(/datum/element/basic_eating, food_types = desired_food)
	ai_controller.set_blackboard_key(BB_BASIC_FOODS, typecacheof(desired_food))

/mob/living/basic/alligator/Destroy()
	if(death_rolling_victim)
		reset_victim(death_rolling_victim)
	. = ..()


/mob/living/basic/alligator/UnarmedAttack(mob/living/simple_animal/user, list/modifiers)
	if(death_rolling_victim)
		return

	if(ishuman(user) && prob(40))
		death_roll(user)
	else
		return ..()


/mob/living/basic/alligator/proc/death_roll(mob/living/carbon/human/florida)
	if(death_rolling_victim || !florida || !istype(florida))
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
	death_rolling_victim = florida
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
	ADD_TRAIT(florida, TRAIT_CANNOT_BE_UNBUCKLED, REF(src))
	ADD_TRAIT(florida, TRAIT_RESTRAINED, REF(src))
	initial_victim_transform = florida.transform
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

#define STEP_TIME 2
#define CYCLES 5
#define TIME CYCLES * 4 * STEP_TIME
	//spawn() is fine because lingmox fixed it in 1680, and I need motivation to move the codebase to 1680
	spawn(TIME)
		if(!QDELETED(src) && !stat)
			icon_state = "croc"
			var/obj/item/bodypart/ripped_limb = pick(legs)
			ripped_limb.dismember()
		reset_victim(florida)
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

#undef CYCLES
#undef STEP_TIME
#undef TIME

/mob/living/basic/alligator/proc/reset_victim(mob/living/carbon/human/florida)
	if(florida.buckled)
		unbuckle_mob(florida)
	REMOVE_TRAIT(florida, TRAIT_CANNOT_BE_UNBUCKLED, REF(src))
	REMOVE_TRAIT(florida, TRAIT_RESTRAINED, REF(src))
	UnregisterSignal(florida, COMSIG_ATOM_PRE_DIR_CHANGE)
	florida.transform = initial_victim_transform
	florida.pixel_x = initial(florida.pixel_x)
	florida.pixel_y = initial(florida.pixel_y)
	death_rolling_victim = null
	initial_victim_transform = null


/mob/living/basic/alligator/proc/on_dir_change()
	SIGNAL_HANDLER
	return COMPONENT_ATOM_BLOCK_DIR_CHANGE
