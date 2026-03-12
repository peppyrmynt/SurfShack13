#define EXECUTION_COOLDOWN_TIME 3 MINUTES
#define SOUND_VOLUME 30



/obj/item/melee/execution_sword
	name = "Executioners sword"
	desc = "Not much good in a fight but perfect for making an example of your enemies."
	icon = 'icons/obj/weapons/transforming_energy.dmi'
	icon_state = "e_cutlass_on"
	inhand_icon_state = "e_cutlass_on"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 10
	throwforce = 9
	sharpness = SHARP_EDGED
	attack_verb_continuous = list("slashes", "cuts", "hacks", "bleeds")
	attack_verb_simple = list("slash", "cut", "hack", "bleed")
	hitsound = 'sound/items/weapons/rapierhit.ogg'
	w_class = WEIGHT_CLASS_NORMAL
	STATIC_COOLDOWN_DECLARE(execution_cooldown)
	/// Name of entity execution is being dedicated to.
	var/execution_faction = "Security"
	/// If the sword is currently in use.
	var/executing = FALSE
	/// True we let the user pick the entity.
	var/can_change_faction = FALSE
	var/list/execution_songs
	/// Players currently hearing execution song.
	var/listeners
	/// How long it take execute someone '
	var/execution_time = 15 SECONDS

/obj/item/melee/execution_sword/examine(mob/user)
	. = ..()
	if(can_change_faction)
		. += "Theres see an input on the hilt to name a faction or militant group, use in hand."

/obj/item/melee/execution_sword/interact(mob/user)
	. = ..()
	if(!can_change_faction)
		return

	var/name = tgui_input_text(user, "Enter faction or militant group name", "Enter entity name", execution_faction, max_length = MAX_PLAQUE_LEN)
	if(name)
		message_admins("[ADMIN_LOOKUPFLW(user)] set execution sword faction to [name]")
		execution_faction = name
		can_change_faction = FALSE


/obj/item/melee/execution_sword/attack(mob/living/target_mob, mob/living/user, params)
	if(!ishuman(target_mob) || executing || !target_mob.mind || target_mob == user)
		return ..()
	var/obj/item/bodypart/head/target_head = target_mob.get_bodypart("head")
	if(!target_head || target_mob.stat == DEAD)
		to_chat(user, span_notice("Little late to the execution there brother..."))
		return
	if(!COOLDOWN_FINISHED(src, execution_cooldown))
		var/cooldown_left = COOLDOWN_TIMELEFT(src, execution_cooldown)
		cooldown_left = ceil(cooldown_left / (1 MINUTES))
		to_chat(user, span_notice("The internal transmitters are recharging ([cooldown_left] minute[cooldown_left ? "s" : ""] left)."))
		return

	executing = TRUE
	var/announce_message = "[user] is preparing to execute [target_mob] near [get_area_name(src)] in the name of [execution_faction]!"
	var/announce_sound = 'sound/announcer/notice/notice1.ogg'
	minor_announce(announce_message, "LiveLeak Announcement", sound_override = announce_sound)
	play_execution_music()
	if(do_after(user, execution_time, target = target_mob) && target_head.dismember())
		announce_message = "[user] has executed [target_mob] in the name of [execution_faction]"
	else
		announce_message = "[user] has to failed to execute [target_mob] and has brought shame to [execution_faction]"
		playsound(src, 'sound/machines/compiler/compiler-failure.ogg', SOUND_VOLUME)
	stop_execution_music()
	minor_announce(announce_message, "LiveLeak Announcement", should_play_sound = FALSE)
	executing = FALSE
	COOLDOWN_START(src, execution_cooldown, EXECUTION_COOLDOWN_TIME)


/obj/item/melee/execution_sword/proc/play_execution_music()
	return

/obj/item/melee/execution_sword/proc/stop_execution_music()
	for(var/mob/listener in listeners)
		listener.stop_sound_channel(CHANNEL_EXECUTION_SWORD)
	LAZYNULL(listeners)

/obj/item/melee/execution_sword/suicide_act(mob/living/user)
	user.visible_message(span_suicide("[user] is holding the [src] to [user.p_their()] neck! It looks like [user.p_theyre()] trying to commit suicide!"))
	var/obj/item/bodypart/head/target_head = user.get_bodypart("head")
	if(!target_head)
		return(BRUTELOSS)
	minor_announce("[user] has taken their own life in the name of [execution_faction]", "LiveLeak Announcement", should_play_sound = FALSE)
	target_head.dismember()
	return(BRUTELOSS)


/obj/item/melee/execution_sword/antag
	execution_faction = "The Syndicate"
	can_change_faction = TRUE
	execution_time = 30 SECONDS
	execution_songs = list('surfshack13/sound/misc/nasheed_1.ogg', 'surfshack13/sound/misc/nasheed_2.ogg', 'surfshack13/sound/misc/bosanska.ogg')

/obj/item/melee/execution_sword/antag/play_execution_music()
	var/song = pick(execution_songs)
	listeners = playsound(src, song, SOUND_VOLUME, vary = FALSE, channel = CHANNEL_EXECUTION_SWORD)

/obj/item/melee/execution_sword/admin
	execution_faction = "Centcom"
	can_change_faction = TRUE
	execution_time = 20 SECONDS
	execution_songs = list('sound/misc/highlander.ogg',  'sound/music/lobby_music/title3.ogg')

/obj/item/melee/execution_sword/admin/play_execution_music()
	var/song = pick(execution_songs)
	SEND_SOUND(world, sound(song, repeat = 0, volume = SOUND_VOLUME, channel = CHANNEL_EXECUTION_SWORD))

/obj/item/melee/execution_sword/admin/stop_execution_music()
	SEND_SOUND(world, sound(null, channel = CHANNEL_EXECUTION_SWORD))

#undef EXECUTION_COOLDOWN_TIME
#undef SOUND_VOLUME
