/mob/living/basic/bot/soda_robot
	icon = 'surfshack13/icons/mob/silicon/aibots.dmi'
	name = "\improper Little Soda Robot"
	desc = "Look at him go!"
	gender = MALE
	icon_state = "soda0"
	base_icon_state = "soda"
	bot_type = HONK_BOT
	ai_controller = /datum/ai_controller/basic_controller/bot/soda_robot
	///the soda can used to build us.
	var/obj/item/reagent_containers/cup/soda_cans/can
	/// the chirp action
	var/datum/action/cooldown/mob_cooldown/bot/chirp/chirping

/mob/living/baisc/bot/soda_robot/examine(mob/user)
	. = ..()
	if(HAS_TRAIT(user, TRAIT_RESEARCH_SCANNER))
		. += span_notice("Reagents can be injected into it")


/mob/living/basic/bot/soda_robot/Initialize(mapload)
	. = ..()
	create_reagents(30)
	chirping = new(src)
	chirping.Grant(src)
	chirping.post_honk_callback = CALLBACK(src, PROC_REF(on_chirped))
	ai_controller.set_blackboard_key(BB_HONK_ABILITY, chirping)

/mob/living/basic/bot/soda_robot/proc/on_chirped()
	visible_message(span_emote("chirps"), visible_message_flags = EMOTE_MESSAGE)
	if(!prob(5))
		return
	to_chat(src, span_notice("Your buzzer gives out!"))
	if(chirping)
		chirping.break_buzzer()

/mob/living/basic/bot/soda_robot/CheckParts(list/parts_list, datum/crafting_recipe/current_recipe)
	. = ..()
	add_soda_overlay()

/mob/living/basic/bot/soda_robot/proc/add_soda_overlay()
	can = locate() in contents
	if(!can)
		can = new /obj/item/reagent_containers/cup/soda_cans(src)
		can.forceMove(src)

	var/mutable_appearance/soda_overlay = mutable_appearance(can.icon, can.icon_state)
	add_overlay(soda_overlay)

/datum/crafting_recipe/sodarobot
	name = "Little Soda Robot"
	result = /mob/living/basic/bot/soda_robot
	reqs = list(
		/obj/item/reagent_containers/cup/soda_cans/ = 1,
		/obj/item/assembly/prox_sensor = 1,
		/obj/item/bodypart/arm/right/robot = 1,
	)
	parts = list(/obj/item/reagent_containers/cup/soda_cans = 1)
	time = 4 SECONDS
	category = CAT_ROBOT

/datum/ai_controller/basic_controller/bot/soda_robot
	planning_subtrees = list(
		/datum/ai_planning_subtree/respond_to_summon,
		/datum/ai_planning_subtree/salute_authority,
 		/datum/ai_planning_subtree/use_mob_ability/random_honk,
		/datum/ai_planning_subtree/find_patrol_beacon,
	)

/datum/action/cooldown/mob_cooldown/bot/chirp
	name = "Chirp"
	desc = "What kind of bird is that?"
	button_icon = 'icons/obj/art/horn.dmi'
	button_icon_state = "bike_horn"
	cooldown_time = 1 MINUTES
	click_to_activate = FALSE
	///callback after we have honked
	var/datum/callback/post_honk_callback
	///If we can no longer chirp
	var/buzzer_broken = FALSE

/datum/action/cooldown/mob_cooldown/bot/chirp/proc/break_buzzer()
	buzzer_broken = TRUE

/datum/action/cooldown/mob_cooldown/bot/chirp/Activate()
	playsound(owner, 'surfshack13/sound/effects/smoke_detector.ogg', 50, FALSE, 3)
	post_honk_callback?.Invoke()
	StartCooldown()
	return TRUE

/datum/action/cooldown/mob_cooldown/bot/chirp/IsAvailable(feedback)
	if(buzzer_broken)
		return FALSE
	return ..()


/datum/action/cooldown/mob_cooldown/bot/chirp/Destroy()
	. = ..()
	post_honk_callback = null
