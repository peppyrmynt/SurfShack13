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

	var/mob/living/carbon/human/dummy = allocate(/mob/living/carbon/human/consistent)
	for(var/key in expected_keys)
		var/list/key_emotes = GLOB.emote_list[key]
		if(!length(key_emotes))
			Fail("7TV emote key [key] was not registered.")
			continue

		var/found_usable = FALSE
		for(var/datum/emote/emote as anything in key_emotes)
			if(istype(emote, /datum/emote/living/carbon/human/seventv) && emote.can_run_emote(dummy, status_check = FALSE, intentional = TRUE))
				found_usable = TRUE
				break

		if(!found_usable)
			Fail("7TV emote key [key] was registered but was not usable by humans.")
