#define STEP_TIME 2
#define CYCLES 5
#define ANIMATION_TIME (CYCLES * 4 * STEP_TIME)
#define ROLL_COOLDOWN_TIME ANIMATION_TIME + 1.5 SECONDS

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
	butcher_results = list(
		/obj/item/clothing/head/costume/gator_cloak = 1,
		/obj/item/food/meat/slab = 2,
	)
	/// Normal diet
	var/static/list/desired_food = list(
		/obj/item/food/meat/slab,
		/obj/item/food/meat/rawcutlet,
		/obj/item/bodypart/arm,
		/obj/item/bodypart/leg,
		/mob/living/basic/frog,
		/mob/living/basic/axolotl,
		/mob/living/basic/chicken,
		/mob/living/basic/mouse,
	)
	/// Apex predator diet
	var/static/list/desired_food_floppy = list(
		/obj/item/food/meat/slab,
		/obj/item/food/meat/rawcutlet,
		/obj/item/bodypart/arm,
		/obj/item/bodypart/leg,
		/mob/living/basic/frog,
		/mob/living/basic/axolotl,
		/mob/living/basic/chicken,
		/mob/living/basic/mouse,
		/obj/item/disk/nuclear,
	)
	SET_BASE_PIXEL(-9, -9)
	/// cooldowns between deathrolls
	COOLDOWN_DECLARE(roll_cooldown)
	/// If we are deathrolling this is set.
	var/mob/living/carbon/human/eating_victim
	/// if the mouth is visually open
	var/mouth_is_open = FALSE

//for ez badmin spawning
/mob/living/basic/alligator/croc

/mob/living/basic/alligator/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS, INNATE_TRAIT)
	if(prob(1)) //*disk shaped thront... *burps...
		AddElement(/datum/element/basic_eating, food_types = desired_food_floppy)
		ai_controller.set_blackboard_key(BB_BASIC_FOODS, typecacheof(desired_food_floppy))
		desc += " It likes floppy disks."
	else
		AddElement(/datum/element/basic_eating, food_types = desired_food)
		ai_controller.set_blackboard_key(BB_BASIC_FOODS, typecacheof(desired_food))
	RegisterSignal(src, COMSIG_MOB_ATE, PROC_REF(on_mob_ate))
	AddElement(/datum/element/ai_retaliate)
	RegisterSignal(src, COMSIG_LIVING_GIBBED, PROC_REF(on_gibbed))
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))

/mob/living/basic/alligator/Destroy()
	if(eating_victim)
		reset_victim()
	UnregisterSignal(src, list(COMSIG_LIVING_GIBBED, COMSIG_MOB_ATE, COMSIG_MOVABLE_MOVED))
	. = ..()

/mob/living/basic/alligator/notify_ventcrawler_on_login()
	. = ..()
	to_chat(src, span_notice("You can open and close your mouth by switching combat mode."))

/mob/living/basic/alligator/death(gibbed)
	. = ..()
	if(eating_victim)
		reset_victim()

/mob/living/basic/alligator/UnarmedAttack(mob/living/carbon/human/user, proximity_flag, list/modifiers)
	if(eating_victim)
		return TRUE

	if(!istype(user))
		return ..()

	var/can_death_roll = check_death_roll(user)
	if(can_death_roll)
		death_roll(user, can_death_roll)
	else
		//have to hit them 2 times before they are on the ground and then finally we can rip off a leg
		var/stamina_damage
		switch(user.getStaminaLoss())
			if(0 to 5)
				stamina_damage = 5
			if(6 to 8)
				stamina_damage = 3
			else
				user.Knockdown(SHOVE_KNOCKDOWN_SOLID)
		if(stamina_damage)
			user.adjustStaminaLoss(stamina_damage)
		melee_attack(user, modifiers)


/mob/living/basic/alligator/proc/check_death_roll(mob/living/carbon/human/florida)
	if(!florida || !istype(florida) || florida.body_position != LYING_DOWN)
		return FALSE

	if(!src.has_gravity())
		to_chat(src, span_notice("You cant death roll without gravity!"))
		return

	if(!COOLDOWN_FINISHED(src, roll_cooldown))
		to_chat(src, span_notice("Your still dizzy from the last death roll, wait a second."))
		return FALSE

	if(HAS_TRAIT(florida.loc, TRAIT_ELEVATED_TURF) && !HAS_TRAIT(src.loc, TRAIT_ELEVATED_TURF))
		to_chat(src, span_notice("[florida] is too high up to grab and death roll."))
		return FALSE

	var/list/legs = list()
	for(var/obj/item/bodypart/leg/leg in florida.bodyparts)
		legs += leg
	if(!length(legs))
		to_chat(src, span_notice("[florida]\s legs are already gone!"))
		return FALSE

	return legs

/// Check if the mob can be deathrolled, do the spin animation, and then rip off leg if all is well returns false on fail
/mob/living/basic/alligator/proc/death_roll(mob/living/carbon/human/florida, list/legs)
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
	RegisterSignal(florida, COMSIG_PRE_LYING_ANGLE_CHANGE, PROC_REF(on_lying_angle_change))
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

	florida.visible_message(span_warning("\The [src] clamps down on [florida]\s leg and  death-rolls."),\
		span_userdanger("\The [src] clamps down on your leg and death-rolls. Your leg is rippig!"))
	COOLDOWN_START(src, roll_cooldown, ROLL_COOLDOWN_TIME)
	//spawn() is fine because lingmox fixed it in 1680, and I need motivation to move the codebase to 1680
	spawn(ANIMATION_TIME)
		mouth_is_open = FALSE
		if(!QDELETED(src) && !stat)
			icon_state = "croc"
			var/obj/item/bodypart/ripped_limb = pick(legs)
			ripped_limb.dismember()
			if(prob(80)) //nom nom, probablity that limbs can be recovered apon gibbing gator
				ripped_limb.forceMove(src)
				on_mob_ate()
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
	UnregisterSignal(eating_victim, list(COMSIG_ATOM_PRE_DIR_CHANGE, COMSIG_PRE_LYING_ANGLE_CHANGE))
	eating_victim.remove_traits(list(TRAIT_CANNOT_BE_UNBUCKLED, TRAIT_INCAPACITATED, TRAIT_IMMOBILIZED, TRAIT_FLOORED, TRAIT_HANDS_BLOCKED), REF(src))
	eating_victim.pixel_x = initial(eating_victim.pixel_x)
	if(eating_victim.body_position == LYING_DOWN)
		eating_victim.transform = matrix().Turn(GET_LYING_ANGLE(eating_victim))
		eating_victim.pixel_y = -4
	else
		eating_victim.transform = null
		eating_victim.pixel_y = initial(eating_victim.pixel_y)
	eating_victim.update_overlays()
	eating_victim = null

/mob/living/basic/alligator/proc/on_mob_ate(datum/source, atom/final_target, mob/living/feeder)
	SIGNAL_HANDLER
	if(!ai_controller || !istype(ai_controller, /datum/ai_controller/basic_controller/alligator))
		return
	var/datum/ai_controller/basic_controller/alligator/controller = ai_controller
	controller.on_ate_food()

/mob/living/basic/alligator/proc/on_dir_change()
	SIGNAL_HANDLER
	return COMPONENT_ATOM_BLOCK_DIR_CHANGE

/mob/living/basic/alligator/proc/on_lying_angle_change(datum/source, var/direct)
	SIGNAL_HANDLER
	return COMPONENT_LYING_BLOCK_ANGLE_CHANGE

/mob/living/basic/alligator/proc/on_gibbed(datum/source, var/drop_bitflags)
	SIGNAL_HANDLER
	var/drop_loc = drop_location()
	var/thrown
	for(var/atom/movable/eaten_thing in src)
		eaten_thing.forceMove(drop_loc)
		if(thrown < 5)
			eaten_thing.throw_at(get_edge_target_turf(src, pick(GLOB.alldirs)), rand(1,3), 5)
			thrown ++

/mob/living/basic/alligator/proc/on_moved()
	SIGNAL_HANDLER
	if(eating_victim || stat)
		return
	var/set_mouth_open = FALSE
	if(src.mind)
		set_mouth_open = combat_mode
	else
		set_mouth_open = ai_controller?.blackboard_key_exists(BB_BASIC_MOB_CURRENT_TARGET)
	if(set_mouth_open == mouth_is_open)
		return

	if(set_mouth_open)
		icon_state = "croc_open"
	else
		icon_state = "croc"
	mouth_is_open = set_mouth_open

#undef CYCLES
#undef STEP_TIME
#undef ANIMATION_TIME
#undef ROLL_COOLDOWN_TIME
