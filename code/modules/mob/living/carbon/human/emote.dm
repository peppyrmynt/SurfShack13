/datum/emote/living/carbon/human
	mob_type_allowed_typecache = list(/mob/living/carbon/human)

/datum/emote/living/carbon/human/dap
	key = "dap"
	key_third_person = "daps"
	message = "sadly can't find anybody to give daps to, and daps themself. Shameful."
	message_param = "gives daps to %t."
	hands_use_check = TRUE

/datum/emote/living/carbon/human/eyebrow
	key = "eyebrow"
	message = "raises an eyebrow."

/datum/emote/living/carbon/human/laugh_king
	key = "laugh_k"
	key_third_person = "laughs like a king!"
	message = "laughs like a king!"
	message_mime = "silently laughs like a king."
	emote_type = EMOTE_VISIBLE | EMOTE_AUDIBLE
	specific_emote_audio_cooldown = 1 MINUTES
	vary = TRUE
	sound = 'sound/mobs/humanoids/human/laugh/laugh_king.ogg'

/datum/emote/living/carbon/human/laugh_king/run_emote(mob/living/carbon/human/H, params, type_override, intentional)
	if(TIMER_COOLDOWN_RUNNING(H, type) || check_cooldown(H, intentional) || HAS_MIND_TRAIT(H, TRAIT_MIMING))
		return ..()
	. = ..()
	var/image/img = image('icons/hud/laugh_king.dmi', loc = H, layer=ABOVE_HUD_PLANE, pixel_x = -32, pixel_y = -32)
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


/datum/emote/living/carbon/human/glasses
	key = "glasses"
	key_third_person = "glasses"
	message = "pushes up their glasses."
	emote_type = EMOTE_VISIBLE

/datum/emote/living/carbon/human/glasses/can_run_emote(mob/user, status_check = TRUE, intentional, params)
	var/obj/eyes_slot = user.get_item_by_slot(ITEM_SLOT_EYES)
	if(istype(eyes_slot, /obj/item/clothing/glasses/regular) || istype(eyes_slot, /obj/item/clothing/glasses/sunglasses))
		return ..()
	return FALSE

/datum/emote/living/carbon/human/glasses/run_emote(mob/user, params, type_override, intentional)
	. = ..()
	var/image/emote_animation = image('icons/mob/human/emote_visuals.dmi', user, "glasses")
	flick_overlay_global(emote_animation, GLOB.clients, 1.6 SECONDS)

/datum/emote/living/carbon/human/grumble
	key = "grumble"
	key_third_person = "grumbles"
	message = "grumbles!"
	message_mime = "grumbles silently!"
	emote_type = EMOTE_AUDIBLE | EMOTE_VISIBLE

/datum/emote/living/carbon/human/handshake
	key = "handshake"
	message = "shakes their own hands."
	message_param = "shakes hands with %t."
	hands_use_check = TRUE
	emote_type = EMOTE_AUDIBLE | EMOTE_VISIBLE

/datum/emote/living/carbon/human/hug
	key = "hug"
	key_third_person = "hugs"
	message = "hugs themself."
	message_param = "hugs %t."
	hands_use_check = TRUE

/datum/emote/living/carbon/human/mumble
	key = "mumble"
	key_third_person = "mumbles"
	message = "mumbles!"
	message_mime = "mumbles silently!"
	emote_type = EMOTE_AUDIBLE | EMOTE_VISIBLE

/datum/emote/living/carbon/human/scream
	key = "scream"
	key_third_person = "screams"
	message = "screams!"
	message_mime = "acts out a scream!"
	emote_type = EMOTE_AUDIBLE | EMOTE_VISIBLE
	specific_emote_audio_cooldown = 10 SECONDS
	vary = TRUE

/datum/emote/living/carbon/human/scream/can_run_emote(mob/user, status_check = TRUE , intentional, params)
	if(!intentional && HAS_TRAIT(user, TRAIT_ANALGESIA))
		return FALSE
	return ..()

/datum/emote/living/carbon/human/scream/get_sound(mob/living/carbon/human/user)
	if(!istype(user))
		return
	return user.dna.species.get_scream_sound(user)

/datum/emote/living/carbon/human/scream/screech //If a human tries to screech it'll just scream.
	key = "screech"
	key_third_person = "screeches"
	message = "screeches!"
	message_mime = "screeches silently."
	emote_type = EMOTE_AUDIBLE | EMOTE_VISIBLE
	vary = FALSE

/datum/emote/living/carbon/human/scream/screech/should_play_sound(mob/user, intentional)
	if(ismonkey(user))
		return TRUE
	return ..()

/datum/emote/living/carbon/human/pale
	key = "pale"
	message = "goes pale for a second."

/datum/emote/living/carbon/human/raise
	key = "raise"
	key_third_person = "raises"
	message = "raises a hand."
	hands_use_check = TRUE

/datum/emote/living/carbon/human/salute
	key = "salute"
	key_third_person = "salutes"
	message = "salutes."
	message_param = "salutes to %t."
	hands_use_check = TRUE
	sound = 'sound/mobs/humanoids/human/salute/salute.ogg'

/datum/emote/living/carbon/human/shrug
	key = "shrug"
	key_third_person = "shrugs"
	message = "shrugs."

/datum/emote/living/carbon/human/wag
	key = "wag"
	key_third_person = "wags"
	message = "their tail."

/datum/emote/living/carbon/human/wag/run_emote(mob/user, params, type_override, intentional)
	. = ..()
	var/obj/item/organ/tail/oranges_accessory = user.get_organ_slot(ORGAN_SLOT_EXTERNAL_TAIL)
	//I am so sorry my son
	//We bypass helpers here cause we already have the tail
	if(oranges_accessory.wag_flags & WAG_WAGGING) //We verified the tail exists in can_run_emote()
		oranges_accessory.stop_wag(user)
	else
		oranges_accessory.start_wag(user)

/datum/emote/living/carbon/human/wag/select_message_type(mob/user, intentional)
	. = ..()
	var/obj/item/organ/tail/oranges_accessory = user.get_organ_slot(ORGAN_SLOT_EXTERNAL_TAIL)
	if(oranges_accessory.wag_flags & WAG_WAGGING)
		. = "stops wagging " + message
	else
		. = "wags " + message

/datum/emote/living/carbon/human/wag/can_run_emote(mob/user, status_check, intentional, params)
	var/obj/item/organ/tail/tail = user.get_organ_slot(ORGAN_SLOT_EXTERNAL_TAIL)
	if(tail?.wag_flags & WAG_ABLE)
		return ..()
	return FALSE

/datum/emote/living/carbon/human/wing
	key = "wing"
	key_third_person = "wings"
	message = "their wings."

/datum/emote/living/carbon/human/wing/run_emote(mob/user, params, type_override, intentional)
	. = ..()
	var/obj/item/organ/wings/functional/wings = user.get_organ_slot(ORGAN_SLOT_EXTERNAL_WINGS)
	if(isnull(wings))
		CRASH("[type] ran on a mob that has no wings!")
	if(wings.wings_open)
		wings.close_wings()
	else
		wings.open_wings()

/datum/emote/living/carbon/human/wing/select_message_type(mob/user, intentional)
	var/obj/item/organ/wings/functional/wings = user.get_organ_slot(ORGAN_SLOT_EXTERNAL_WINGS)
	var/emote_verb = wings.wings_open ? "closes" : "opens"
	return "[emote_verb] [message]"

/datum/emote/living/carbon/human/wing/can_run_emote(mob/user, status_check = TRUE, intentional, params)
	if(!istype(user.get_organ_slot(ORGAN_SLOT_EXTERNAL_WINGS), /obj/item/organ/wings/functional))
		return FALSE
	return ..()

/datum/emote/living/carbon/human/clear_throat
	key = "clear"
	key_third_person = "clears throat"
	message = "clears their throat."

///Snowflake emotes only for le epic chimp
/datum/emote/living/carbon/human/monkey

/datum/emote/living/carbon/human/monkey/can_run_emote(mob/user, status_check = TRUE, intentional, params)
	if(ismonkey(user))
		return ..()
	return FALSE

/datum/emote/living/carbon/human/monkey/gnarl
	key = "gnarl"
	key_third_person = "gnarls"
	message = "gnarls and shows its teeth..."
	message_mime = "gnarls silently, baring its teeth..."

/datum/emote/living/carbon/human/monkey/roll
	key = "roll"
	key_third_person = "rolls"
	message = "rolls."
	hands_use_check = TRUE

/datum/emote/living/carbon/human/monkey/scratch
	key = "scratch"
	key_third_person = "scratches"
	message = "scratches."
	hands_use_check = TRUE

/datum/emote/living/carbon/human/monkey/screech/roar
	key = "roar"
	key_third_person = "roars"
	message = "roars!"
	message_mime = "acts out a roar."
	emote_type = EMOTE_AUDIBLE | EMOTE_VISIBLE

/datum/emote/living/carbon/human/monkey/tail
	key = "tail"
	message = "waves their tail."

/datum/emote/living/carbon/human/monkey/sign
	key = "sign"
	key_third_person = "signs"
	message_param = "signs the number %t."
	hands_use_check = TRUE

/// 7TV-inspired image emotes ported from tgstation commit d72fcf2177c44000b350ab4a519b3b937513ff8c.
/datum/emote/living/seventv
	/// Asset and display time can be overridden by emotes with their own animation.
	var/emote_icon = 'icons/mob/human/aprilfools_emotes.dmi'
	var/emote_icon_state
	var/emote_duration = 3 SECONDS
	/// Composited once per emote; retains every animation frame and its timing.
	var/icon/bubble_artwork
	cooldown = 60 SECONDS
	emote_type = EMOTE_VISIBLE

/datum/emote/living/seventv/can_run_emote(mob/user, status_check = TRUE, intentional, params)
	if(!user.client && !user.mind)
		return FALSE
	return ..()

/datum/emote/living/seventv/run_emote(mob/living/user, params, type_override, intentional)
	. = ..()
	if(!emote_icon || !emote_icon_state)
		return

	// Like laugh_k, use one complete animated icon so the frame cannot cover the art.
	// Keep its top at pixel 28, below the overhead runechat text.
	var/image/bubble = image(get_emote_bubble_icon(), loc = user, pixel_x = 24, pixel_y = -8)
	bubble.plane = ABOVE_HUD_PLANE
	bubble.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	bubble.alpha = 255

	var/list/recipients = list()
	for(var/mob/viewer in viewers(world.view, user))
		if(viewer.client && !viewer.is_blind())
			recipients |= viewer.client
	bubble.transform = matrix() * 0
	for(var/client/recipient as anything in recipients)
		recipient.images += bubble
	animate(bubble, transform = matrix(), time = 0.15 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(fade_bubble), bubble, recipients), emote_duration)

/// Compose all DMI frames over the background instead of relying on overlay plane ordering.
/datum/emote/living/seventv/proc/get_emote_bubble_icon()
	if(!bubble_artwork)
		bubble_artwork = icon(emote_icon, emote_icon_state)
		var/artwork_scale = min(32 / bubble_artwork.Width(), 32 / bubble_artwork.Height())
		var/artwork_width = max(1, round(bubble_artwork.Width() * artwork_scale))
		var/artwork_height = max(1, round(bubble_artwork.Height() * artwork_scale))
		bubble_artwork.Scale(artwork_width, artwork_height)
		var/offset_x = 18 + round((32 - artwork_width) / 2)
		var/offset_y = 2 + round((32 - artwork_height) / 2)
		bubble_artwork.Crop(1 - offset_x, 1 - offset_y, 56 - offset_x, 36 - offset_y)
		bubble_artwork.Blend(get_bubble_icon(), ICON_UNDERLAY)
	return bubble_artwork

/// Cached rounded speech frame inspired by laugh_k, with a thin border and light-grey fill.
/datum/emote/living/seventv/proc/get_bubble_icon()
	var/static/icon/bubble_icon
	if(!bubble_icon)
		bubble_icon = icon('icons/mob/human/aprilfools_emotes.dmi', "clueless")
		bubble_icon.DrawBox(null, 1, 1, 32, 32)
		bubble_icon.Crop(1, 1, 56, 36)
		// Rounded 44-by-36 body. Row insets keep the outline one pixel thick.
		var/list/corner_insets = list(5, 3, 2, 1, 1)
		for(var/row in 1 to 36)
			var/edge_distance = min(row, 37 - row)
			var/inset = edge_distance <= length(corner_insets) ? corner_insets[edge_distance] : 0
			bubble_icon.DrawBox("#303030", 13 + inset, row, 56 - inset, row)
			if(row > 1 && row < 36)
				bubble_icon.DrawBox("#EEEEEE", 14 + inset, row, 55 - inset, row)
		// A longer, shallow pointer, like the king's bubble.
		for(var/column in 1 to 13)
			var/lower_edge = 24 - round((column - 1) * 0.7)
			bubble_icon.DrawBox("#303030", column, lower_edge, column, 24)
			if(lower_edge < 23)
				bubble_icon.DrawBox("#EEEEEE", column, lower_edge + 1, column, 23)
	return bubble_icon

/datum/emote/living/seventv/proc/fade_bubble(image/bubble, list/recipients)
	if(QDELETED(bubble))
		return
	animate(bubble, transform = matrix() * 0, time = 0.15 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(remove_bubble), bubble, recipients), 0.2 SECONDS)

/datum/emote/living/seventv/proc/remove_bubble(image/bubble, list/recipients)
	remove_image_from_clients(bubble, recipients)
	qdel(bubble)

/datum/emote/living/seventv/sigma
	key = "sigma"
	message = "gives a knowing smirk."
	emote_icon = 'icons/mob/human/sigma_emote.dmi'
	emote_icon_state = "sigma"
	emote_duration = 5 SECONDS
	sound = 'sound/effects/aprilfools/sigma.ogg'
	affected_by_pitch = FALSE
	general_emote_audio_cooldown = 5 SECONDS

/datum/emote/living/seventv/clueless
	key = "clueless"
	message = "looks clueless."
	emote_icon_state = "clueless"

/datum/emote/living/seventv/hmm
	key = "hmm"
	message = "squints their eyes."
	emote_icon_state = "hmm"

/datum/emote/living/seventv/lmao
	key = "lmao"
	message = "is laughing their ass off!"
	emote_icon_state = "troll"

/datum/emote/living/seventv/reallymad
	key = "reallymad"
	message = "looks really mad about something!"
	emote_icon_state = "reallymad"
	sound = 'sound/effects/aprilfools/angry.ogg'

/datum/emote/living/seventv/zorp
	key = "zorp"
	message = "feels their impending doom approaching."
	emote_icon_state = "zorp"
	sound = 'sound/effects/aprilfools/bell.ogg'

/datum/emote/living/seventv/uncanny
	key = "uncanny"
	message = "looks really uncanny."
	emote_icon_state = "uncanny"
	sound = 'sound/effects/aprilfools/bell.ogg'

/datum/emote/living/seventv/xdd
	key = "xdd"
	message = "laughs."
	emote_icon_state = "xdd"

/datum/emote/living/seventv/xdd/get_sound(mob/living/user)
	return prob(20) ? 'sound/effects/aprilfools/goofylaugh2.ogg' : 'sound/effects/aprilfools/goofylaugh.ogg'

/datum/emote/living/seventv/taa
	key = "taa"
	message = "smokes an imaginary cigar."
	emote_icon_state = "taa"
	sound = 'sound/effects/aprilfools/rizz.ogg'

/datum/emote/living/seventv/noway
	key = "noway"
	message = "looks shocked!"
	emote_icon_state = "noway"
	sound = 'sound/effects/aprilfools/rizz.ogg'

/datum/emote/living/seventv/tuh
	key = "tuh"
	message = "gasps in shock!"
	emote_icon_state = "tuh"
	sound = 'sound/effects/aprilfools/vineboom.ogg'

/datum/emote/living/seventv/jokerge
	key = "jokerge"
	message = "grins."
	emote_icon_state = "jokerge"

/datum/emote/living/seventv/fuckingdies
	key = "fuckingdies"
	message = "fucking dies."
	emote_icon_state = "die"
	sound = 'sound/effects/aprilfools/rpdeath.ogg'
