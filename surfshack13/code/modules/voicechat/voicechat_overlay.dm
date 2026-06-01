/mob/proc/toggle_voice_overlay(on)
	if(on)
		if(!voice_image)
			voice_image = new()
			voice_image.icon = 'surfshack13/icons/mob/effects/voice_overlay.dmi'
			voice_image.icon_state = src.voice_icon_state
			voice_image.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
			voice_image.layer = FLY_LAYER
			voice_image.alpha = 180
			//setting name to empty string prevents it from showing up in menus
			voice_image.name = ""
		if(voice_image.icon_state != voice_icon_state)
			voice_image.icon_state = voice_icon_state
		vis_contents += voice_image
	else
		if(!voice_image)
			return
		vis_contents -= voice_image
