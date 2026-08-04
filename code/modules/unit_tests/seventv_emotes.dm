/datum/unit_test/seventv_emotes

/datum/unit_test/seventv_emotes/Run()
	var/static/list/expected_keys = list(
		"clueless",
		"hmm",
		"lmao",
		"reallymad",
		"zorp",
		"uncanny",
		"xdd",
		"taa",
		"noway",
		"tuh",
		"jokerge",
		"fuckingdies",
	)

	var/mob/living/carbon/human/dummy_human = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	dummy_human.mind = new /datum/mind(null)

	var/mob/living/basic/pet/dog/corgi/dummy_basic = allocate(/mob/living/basic/pet/dog/corgi, run_loc_floor_bottom_left)
	dummy_basic.mind = new /datum/mind(null)

	var/mob/living/silicon/robot/dummy_borg = allocate(/mob/living/silicon/robot, run_loc_floor_bottom_left)
	dummy_borg.mind = new /datum/mind(null)

	var/list/sentient_mobs = list(
		"human" = dummy_human,
		"basic living mob" = dummy_basic,
		"cyborg" = dummy_borg,
	)

	var/mob/living/basic/pet/dog/corgi/non_sentient_basic = allocate(/mob/living/basic/pet/dog/corgi, run_loc_floor_bottom_left)

	for(var/key in expected_keys)
		var/list/key_emotes = GLOB.emote_list[key]
		if(!length(key_emotes))
			Fail("7TV emote key [key] was not registered.")
			continue

		var/datum/emote/living/seventv/seventv_emote
		for(var/datum/emote/emote as anything in key_emotes)
			if(istype(emote, /datum/emote/living/seventv))
				seventv_emote = emote
				break

		if(!seventv_emote)
			Fail("7TV emote key [key] was registered but did not point to a 7TV emote.")
			continue

		for(var/mob_name in sentient_mobs)
			var/mob/living/sentient_mob = sentient_mobs[mob_name]
			if(!seventv_emote.can_run_emote(sentient_mob, status_check = FALSE, intentional = TRUE))
				Fail("7TV emote key [key] was not usable by a sentient [mob_name].")

		if(seventv_emote.can_run_emote(non_sentient_basic, status_check = FALSE, intentional = TRUE))
			Fail("7TV emote key [key] was usable by a non-sentient basic mob.")
