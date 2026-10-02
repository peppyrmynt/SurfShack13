/**
 * # Guqin
 *
 * A seven-string zither. Playing it is cultivation: while a cultivator plays, they and every cultivator listening nearby
 * slowly gain insight and settle their unstable qi, and everyone else just enjoys the music.
 * Water and Wood cultivators learn the most from it.
 */

/// Seconds between each wave of music insight
#define GUQIN_PULSE_INTERVAL 20

/obj/item/instrument/guqin
	name = "guqin"
	desc = "A long, low seven-string zither of lacquered paulownia wood. The sages said a gentleman is never without his qin."
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'
	icon_state = "guqin"
	inhand_icon_state = "guitar"
	w_class = WEIGHT_CLASS_BULKY
	attack_verb_continuous = list("serenades", "strums", "bonks")
	attack_verb_simple = list("serenade", "strum", "bonk")
	hitsound = 'sound/items/weapons/stringsmash.ogg'
	allowed_instrument_ids = list("cnylongt", "ccleangt")
	/// Seconds of continuous playing since the last pulse
	var/play_time = 0

/obj/item/instrument/guqin/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/item/instrument/guqin/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/instrument/guqin/examine(mob/user)
	. = ..()
	if(IS_CULTIVATOR(user))
		. += span_notice("Playing it is a form of cultivation. You and every cultivator listening nearby slowly gain insight and calm your qi.")

/obj/item/instrument/guqin/process(seconds_per_tick)
	var/mob/living/player = loc
	if(!song?.playing || !istype(player) || player.stat != CONSCIOUS)
		play_time = 0
		return
	play_time += seconds_per_tick
	if(play_time < GUQIN_PULSE_INTERVAL)
		return
	play_time = 0
	resonate(player)

/// One wave of music washing over the room
/obj/item/instrument/guqin/proc/resonate(mob/living/player)
	var/datum/antagonist/cultivator/player_cultivator = IS_CULTIVATOR(player)
	var/power = player_cultivator ? 1 + 0.25 * player_cultivator.effective_realm() : 0.5
	var/obj/effect/temp_visual/circle_wave/cultivation/water/ripple = new(get_turf(player))
	ripple.alpha = 140
	cultivation_particles(player, /particles/cultivation/petals, 3 SECONDS)
	if(player_cultivator)
		player_cultivator.notify_laws(INSIGHT_SOURCE_MUSIC, src)
		player_cultivator.gain_insight(2 * power, "music_play", cooldown = 0, silent = TRUE)
		player_cultivator.adjust_instability(-3)
	for(var/mob/living/listener in hearers(6, player))
		if(listener == player || listener.stat != CONSCIOUS || HAS_TRAIT(listener, TRAIT_DEAF))
			continue
		listener.add_mood_event("guqin_music", /datum/mood_event/guqin_music)
		var/datum/antagonist/cultivator/listener_cultivator = IS_CULTIVATOR(listener)
		if(!listener_cultivator)
			continue
		listener_cultivator.gain_insight(2 * power, INSIGHT_SOURCE_MUSIC, cooldown = 40 SECONDS, silent = TRUE)
		listener_cultivator.adjust_instability(-2)

/datum/mood_event/guqin_music
	description = "Someone played the guqin beautifully. I feel at peace."
	mood_change = 3
	timeout = 5 MINUTES

/datum/crafting_recipe/guqin
	name = "Guqin"
	result = /obj/item/instrument/guqin
	reqs = list(/obj/item/stack/sheet/mineral/wood = 8, /obj/item/stack/cable_coil = 7)
	tool_behaviors = list(TOOL_WIRECUTTER)
	time = 10 SECONDS
	category = CAT_ENTERTAINMENT

#undef GUQIN_PULSE_INTERVAL
