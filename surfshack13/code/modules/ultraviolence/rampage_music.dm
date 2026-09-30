/**
 * # Rampage music
 *
 * Plays a looping song out of an atom to every player within range, straight through walls,
 * so everyone nearby can hear where it's coming from. Changing songs crossfades between two sound channels
 * instead of cutting, and the mob carrying the source hears the song quieter so it can still hear the fight.
 *
 * Listeners are tracked by client rather than mob, so ghosting, body swaps and disconnects can't leave a song stuck playing.
 * Everything stops the moment the source is deleted or ends up in nullspace.
 */
/datum/rampage_music
	/// Where the music is coming from.
	var/atom/source
	/// Tiles away the music can be heard from.
	var/range = 15
	/// Volume for listeners standing right next to the source. Fades down with distance.
	var/volume = 70
	/// Volume for the mob the source is, or is carried by.
	var/self_volume = 30
	/// How long a crossfade between songs takes.
	var/fade_time = 1.5 SECONDS
	/// The two sound channels we crossfade between.
	var/list/channels = list()
	/// The song playing on each channel.
	var/list/channel_songs = list(null, null)
	/// Current loudness of each channel, 0 to 1.
	var/list/channel_gain = list(0, 0)
	/// Loudness each channel is fading towards, 0 to 1.
	var/list/channel_target = list(0, 0)
	/// Index of the channel playing the current song.
	var/active_channel = 1
	/// Assoc list of listening client -> list of the last sound state sent per channel, or null if that channel isn't playing for them.
	var/list/listeners = list()

/datum/rampage_music/New(atom/source, range, volume, self_volume)
	src.source = source
	if(!isnull(range))
		src.range = range
	if(!isnull(volume))
		src.volume = volume
	if(!isnull(self_volume))
		src.self_volume = self_volume
	channels += SSsounds.reserve_sound_channel(src)
	channels += SSsounds.reserve_sound_channel(src)
	RegisterSignal(source, COMSIG_QDELETING, PROC_REF(on_source_deleted))

/datum/rampage_music/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	silence_all()
	SSsounds.free_datum_channels(src)
	source = null
	return ..()

/datum/rampage_music/proc/on_source_deleted(datum/deleted_source)
	SIGNAL_HANDLER
	qdel(src)

/// Fades into the passed song. Does nothing if it's already the song playing.
/datum/rampage_music/proc/play(song)
	if(QDELETED(src) || QDELETED(source))
		return
	if(channel_songs[active_channel] == song && channel_target[active_channel] == 1)
		return
	var/new_channel = active_channel
	// Something is already playing or fading out on our channel, so bring the new song in on the other one.
	if(channel_songs[active_channel])
		new_channel = 3 - active_channel
		channel_target[active_channel] = 0
		reset_channel(new_channel)
	channel_songs[new_channel] = song
	channel_gain[new_channel] = 0
	channel_target[new_channel] = 1
	active_channel = new_channel
	START_PROCESSING(SSfastprocess, src)

/**
 * Stops the music.
 *
 * Arguments:
 * * immediate - cut it off right now instead of fading out.
 */
/datum/rampage_music/proc/stop(immediate = FALSE)
	channel_target[1] = 0
	channel_target[2] = 0
	if(!immediate)
		return
	STOP_PROCESSING(SSfastprocess, src)
	silence_all()

/// Is anything audible or about to be?
/datum/rampage_music/proc/is_playing()
	return channel_target[1] || channel_target[2] || channel_gain[1] || channel_gain[2]

/// Cuts every channel for every listener and forgets all songs.
/datum/rampage_music/proc/silence_all()
	for(var/index in 1 to 2)
		channel_songs[index] = null
		channel_gain[index] = 0
		channel_target[index] = 0
	for(var/client/listener as anything in listeners)
		stop_for(listener)
	listeners.Cut()

/// Stops a channel dead for every listener.
/datum/rampage_music/proc/reset_channel(index)
	channel_songs[index] = null
	channel_gain[index] = 0
	channel_target[index] = 0
	for(var/client/listener as anything in listeners)
		if(!listener)
			continue
		SEND_SOUND(listener, sound(null, channel = channels[index]))
		var/list/sent = listeners[listener]
		sent[index] = null

/// Stops both of our channels for one client.
/datum/rampage_music/proc/stop_for(client/listener)
	if(!listener)
		return
	for(var/channel in channels)
		SEND_SOUND(listener, sound(null, channel = channel))

/datum/rampage_music/process(seconds_per_tick)
	if(QDELETED(source))
		qdel(src)
		return PROCESS_KILL

	var/fade_step = (seconds_per_tick SECONDS) / fade_time
	for(var/index in 1 to 2)
		if(channel_gain[index] < channel_target[index])
			channel_gain[index] = min(channel_gain[index] + fade_step, channel_target[index])
		else if(channel_gain[index] > channel_target[index])
			channel_gain[index] = max(channel_gain[index] - fade_step, channel_target[index])
		if(channel_songs[index] && !channel_gain[index] && !channel_target[index])
			reset_channel(index)

	if(!is_playing())
		silence_all()
		return PROCESS_KILL

	update_listeners()

/**
 * Volume for someone this many tiles away. Drops off quickly: full volume up close, about a third halfway out,
 * and a faint 10% at the edge of the range so it can still be tracked through walls.
 */
/datum/rampage_music/proc/get_distance_volume(distance)
	var/closeness = 1 - clamp(distance / range, 0, 1)
	return volume * (0.1 + 0.9 * closeness * closeness)

/// Works out who should hear us and sends them the song at the right volume and position.
/datum/rampage_music/proc/update_listeners()
	// Disconnected clients leave null keys behind.
	listeners -= null

	var/turf/source_turf = get_turf(source)
	var/mob/carrier = ismob(source) ? source : get(source, /mob)
	var/list/in_range = list()
	if(source_turf)
		for(var/client/player as anything in GLOB.clients)
			var/mob/player_mob = player?.mob
			var/turf/player_turf = get_turf(player_mob)
			if(!player_turf || player_turf.z != source_turf.z || get_dist(player_turf, source_turf) > range)
				continue
			if(HAS_TRAIT(player_mob, TRAIT_DEAF))
				continue
			in_range[player] = player_turf

	for(var/client/listener as anything in listeners)
		if(in_range[listener])
			continue
		stop_for(listener)
		listeners -= listener

	for(var/client/listener as anything in in_range)
		if(!listeners[listener])
			listeners[listener] = list(null, null)
		var/list/sent = listeners[listener]
		var/turf/listener_turf = in_range[listener]
		var/is_self = (carrier && listener.mob == carrier)
		var/base_volume = is_self ? self_volume : get_distance_volume(get_dist(listener_turf, source_turf))
		// Sound space is x/z, world is x/y.
		var/offset_x = is_self ? 0 : source_turf.x - listener_turf.x
		var/offset_z = is_self ? 0 : source_turf.y - listener_turf.y
		for(var/index in 1 to 2)
			if(!channel_songs[index])
				continue
			var/channel_volume = round(base_volume * channel_gain[index])
			var/state = "[channel_volume]|[offset_x]|[offset_z]"
			if(sent[index] == state)
				continue
			var/sound/song = sound(channel_songs[index], repeat = TRUE, wait = FALSE, channel = channels[index], volume = channel_volume)
			song.falloff = range
			song.x = offset_x
			song.y = 1
			song.z = offset_z
			// A sound with SOUND_UPDATE won't start for someone who isn't already hearing it, so only update after the first send.
			if(sent[index])
				song.status = SOUND_UPDATE
			SEND_SOUND(listener, song)
			sent[index] = state
