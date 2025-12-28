
/datum/emote/living/carbon/human/laugh_king
	key = "laugh_k"
	key_third_person = "laughs like a king!"
	message = "laughs like a king!"
	message_mime = "silently laughs like a king."
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE
	specific_emote_audio_cooldown = 1 MINUTES
	vary = TRUE
	sound = 'surfshack13/sound/mobs/humanoids/laugh/laugh_king.ogg'

/datum/emote/living/carbon/human/laugh_king/run_emote(mob/living/carbon/human/H, params, type_override, intentional)
	if(TIMER_COOLDOWN_RUNNING(H, type) || check_cooldown(H, intentional) || HAS_MIND_TRAIT(H, TRAIT_MIMING))
		return ..()
	. = ..()
	var/image/img = image('surfshack13/icons/hud/laugh_king.dmi', loc = H, layer=ABOVE_HUD_PLANE, pixel_x = -32, pixel_y = -32)
	var/orig_matrix = img.transform * 0.5
	img.plane = ABOVE_HUD_PLANE
	img.mouse_opacity = FALSE //click through it
	img.alpha = 210
	img.transform *= 0
	for (var/mob/M in viewers(world.view, H))
		if (!M.client)
			continue
		M.client.images += img
	animate(img, transform = orig_matrix, time = 1.5)
	addtimer(CALLBACK(src, PROC_REF(fade_out), img), 20)

/datum/emote/living/carbon/human/laugh_king/proc/fade_out(image/img)
	if(QDELETED(img))
		return
	animate(img, transform = matrix() * 0, time = 1.5)
	QDEL_IN(img, 2)
