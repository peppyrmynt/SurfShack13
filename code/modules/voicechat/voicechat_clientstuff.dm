// Connects a client to voice chat via an external browser
/datum/controller/subsystem/voicechat/proc/join_vc(client/C, show_link_only=FALSE)
	var/node_port = CONFIG_GET(number/port_voicechat) // I see no good reasons why admins should be able to modify the port so we check config every time
	if(!C)
		return
	// Disconnect existing session if present
	var/existing_userCode = client_userCode_map[ref(C)]
	if(existing_userCode)
		disconnect(existing_userCode, from_byond = TRUE)

	// Generate unique session and user codes
	var/sessionId = md5("[world.time][rand()][world.realtime][rand(0,9999)][C.address][C.computer_id]")
	var/userCode = generate_userCode(C)
	if(!userCode)
		return

	// Open external browser with voice chat link
	var/address = src.domain || world.internet_address
	var/web_link = "https://[address]:[node_port]?sessionId=[sessionId]"
	if(!show_link_only)
		C << link(web_link)
	else
		C << browse({"
		<html>
			<body>
				<h3>[web_link]</h3>
				<p>copy and paste the link into your web browser of choice, or scan the qr code.</p>
				<img src="https://api.qrserver.com/v1/create-qr-code/?data=${encodeURIComponent([web_link])}&size=150x150">
			</body>
		</html>"}, "window=voicechat_help")


	send_json(alist(
		cmd = "register",
		userCode = userCode,
		sessionId = sessionId
	))

	// Link client to userCode
	userCode_client_map[userCode] = ref(C)
	client_userCode_map[ref(C)] = userCode
	// Confirmation handled in confirm_userCode

// Sets up signals for a confirmed voice chat user
/datum/controller/subsystem/voicechat/proc/post_confirm(userCode)
	var/client/C = locate(userCode_client_map[userCode])
	if(!C || !C.mob)
		disconnect(userCode, from_byond = TRUE)
		return

	var/mob/M = C.mob
	room_update(M)


// Toggles the speaker overlay for a user
/datum/controller/subsystem/voicechat/proc/toggle_active(userCode, is_active)
	if(!userCode || isnull(is_active))
		return
	var/client/C = locate(userCode_client_map[userCode])

	if(!C || !C.mob)
		disconnect(userCode, from_byond= TRUE)
		return
	var/mob/M = C.mob
	if(!userCodes_speaking_icon[userCode])
		var/image/speaker = image('icons/mob/effects/talk.dmi', icon_state = "voice")
		speaker.alpha = 200
		userCodes_speaking_icon[userCode] = speaker

	var/image/speaker = userCodes_speaking_icon[userCode]
	var/mob/old_mob = userCode_mob_map[userCode]
	if(M != old_mob)
		if(old_mob)
			old_mob.overlays -= speaker
		userCode_mob_map[userCode] = M
		room_update(M)
	if(is_active && (isobserver(M) || !M.stat))
		userCodes_active |= userCode
		M.add_overlay(speaker)
	else
		userCodes_active -= userCode
		M.cut_overlay(speaker)


// Mutes or deafens a user's microphone
/datum/controller/subsystem/voicechat/proc/mute_mic(client/C, deafen = FALSE)
	if(!C)
		return
	var/userCode = client_userCode_map[ref(C)]
	if(!userCode)
		return
	send_json(list(
		cmd = deafen ? "deafen" : "mute_mic",
		userCode = userCode
	))


