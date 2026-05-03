/mob/living/basic/bot/soda_robot
	icon = 'surfshack13/icons/mob/silicon/aibots.dmi'
	name = "\improper Little Soda Robot"
	desc = "Look at him go!"
	gender = MALE
	icon_state = "soda0"
	base_icon_state = "soda"
	bot_type = HONK_BOT
	///the soda can used to build us.
	var/obj/item/reagent_containers/cup/soda_cans/can

/mob/living/basic/bot/soda_robot/CheckParts(list/parts_list, datum/crafting_recipe/current_recipe)
	. = ..()
	add_soda_overlay()

/mob/living/basic/bot/soda_robot/proc/add_soda_overlay()
	can = locate() in contents
	if(!can)
		can = new /obj/item/reagent_containers/cup/soda_cans/cola(src)
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

/datum/emote/living/basic/bot/soda_robot/chirp
	key = "chirp"
	key_third_person = "chirps"
	message = "chirps"
	emote_type = EMOTE_AUDIBLE
	sound = 'surfshack13/sound/effects/smoke_detector.ogg'
	cooldown = 30 SECONDS


