SUBSYSTEM_DEF(voicechat)
	name = "Voice Chat"
	wait = 3 //300 ms
	flags = SS_KEEP_TIMING
	init_order = INIT_ORDER_VOICECHAT
	runlevels = RUNLEVEL_GAME|RUNLEVEL_POSTGAME

	//life cycle sanity shit, please dont touch
	var/is_node_shutting_down = FALSE
	//life cycle sanity shit, please dont touch
	var/node_PID

	//     --list shit--

	//userCodes associated thats been fully confirmed - browser paired and mic perms on
	var/list/vc_clients = list()
	//userCode to clientRef
	var/list/userCode_client_map = alist()
	var/list/client_userCode_map = alist()

	//a list all currnet rooms
	//change with add_rooms and remove_rooms.
	var/list/current_rooms = alist()
	// usercode to room
	var/list/userCode_room_map = alist()
	// usercode to mob only really used for the overlays
	var/list/userCode_mob_map = alist()
	// used to ensure rooms are always updated
	var/list/userCodes_active = list()
	// each speaker per userCode
	var/list/userCodes_speaking_icon = alist()
	//list of all rooms to add at round start
	var/list/rooms_to_add = list("living", "ghost")
	//holds a normal list of all the ckeys and list of all usercodes that muted that ckey
	var/list/ckey_muted_by = alist()
	//   --subsystem "defines"--

	//node server path
	var/const/node_path = "voicechat/node/server/main.js"
	//library path
	var/lib_path
	var/const/lib_path_unix = "voicechat/pipes/unix/byondsocket"
	var/const/lib_path_win = "voicechat/pipes/windows/byondsocket/Release/byondsocket"
	//if you have a domain, put it here.
	var/const/domain

//  --lifecycle--

/datum/controller/subsystem/voicechat/Initialize()
	. = ..()
	if(world.system_type == MS_WINDOWS)
		lib_path = lib_path_win
	else
		lib_path = lib_path_unix
	if(!CONFIG_GET(flag/enable_voicechat))
		return SS_INIT_NO_NEED
	if(!test_library())
		return SS_INIT_FAILURE
	add_rooms(rooms_to_add)
	start_node()
	initialized = TRUE
	return SS_INIT_SUCCESS


/datum/controller/subsystem/voicechat/proc/start_node()
	var/byond_port = world.port
	var/node_port = CONFIG_GET(number/port_voicechat)
	if(!node_port)
		CRASH("bad port option specified in config {node_port: [node_port || "null"]}")
	var/cmd = "node [src.node_path] --node-port=[node_port] --byond-port=[byond_port] --byond-pid=[world.process] &"
	if(world.system_type == MS_WINDOWS) // ape shit insane but its ok :)
		cmd = "powershell.exe -Command \"Start-Process -FilePath 'node' -ArgumentList '[src.node_path]','--node-port=[node_port]','--byond-port=[byond_port]', '--byond-pid=[world.process]'\""
	var/exit_code = shell(cmd)
	if(exit_code != 0)
		CRASH("launching node failed {exit_code: [exit_code || "null"], cmd: [cmd || "null"]}")



/datum/controller/subsystem/voicechat/Shutdown()
	stop_node()
	. = ..()


/datum/controller/subsystem/voicechat/proc/stop_node()
	send_json(alist(cmd= "stop_node"))
	addtimer(CALLBACK(src, PROC_REF(confirm_node_stopped), 1 SECONDS))


/datum/controller/subsystem/voicechat/proc/confirm_node_stopped()
	if(is_node_shutting_down)
		return

	message_admins("node failed to shutdown, trying forcefully...")

	if(!node_PID)
		message_admins("cant find pid to shutdown node. hard restart required to fix voicechat")
		return
	var/cmd = "kill [node_PID]"
	if(world.system_type == MS_WINDOWS)
		cmd = "taskkill /F /PID [node_PID]"
	var/exit_code = shell(cmd)

	if(exit_code != 0)
		message_admins("killing node failed {exit_code: [exit_code || "null"], cmd: [cmd || "null"]}")
	else
		message_admins("node shutdown")

/datum/controller/subsystem/voicechat/fire()
	send_locations()

/datum/controller/subsystem/voicechat/proc/on_node_start(pid)
	if(!pid || !isnum(pid))
		CRASH("invalid pid {pid: [pid || "null"]}")
	node_PID = pid
	return

/datum/controller/subsystem/voicechat/proc/add_rooms(list/rooms, zlevel_mode = FALSE)
	if(!islist(rooms))
		rooms = list(rooms)
	rooms.Remove(current_rooms) //remove existing rooms
	for(var/room in rooms)
		if(isnum(room) && !zlevel_mode)
			// CRASH("rooms cannot be numbers {room: [room]}")
			continue
		current_rooms[room] = list()


/datum/controller/subsystem/voicechat/proc/remove_rooms(list/rooms)
	if(!islist(rooms))
		rooms = list(rooms)
	rooms &= current_rooms //remove nonexistant rooms
	for(var/room in rooms)
		for(var/userCode in current_rooms[room])
			userCode_room_map[userCode] = null
		current_rooms.Remove(room)


/datum/controller/subsystem/voicechat/proc/move_userCode_to_room(userCode, room)
	if(!room || !current_rooms.Find(room))
		return

	var/own_room = userCode_room_map[userCode]
	if(own_room)
		current_rooms[own_room] -= userCode

	userCode_room_map[userCode] = room
	current_rooms[room] += userCode


/datum/controller/subsystem/voicechat/proc/link_userCode_client(userCode, client)
	if(!client|| !userCode)
		// CRASH("{userCode: [userCode || "null"], client: [client  || "null"]}")
		return
	var/client_ref = ref(client)
	userCode_client_map[userCode] = client_ref
	client_userCode_map[client_ref] = userCode
	world.log << "registered userCode:[userCode] to client_ref:[client_ref]"


// Confirms userCode when browser and mic access are granted
/datum/controller/subsystem/voicechat/proc/confirm_userCode(userCode)
	if(!userCode || (userCode in vc_clients))
		return
	var/client_ref = userCode_client_map[userCode]
	if(!client_ref)
		return

	vc_clients += userCode
	log_world("Voice chat confirmed for userCode: [userCode]")
	post_confirm(userCode)


// faster the better
/datum/controller/subsystem/voicechat/proc/send_locations()
	var/list/params = list(cmd = "loc")
	var/locs_sent = 0

	for(var/userCode in vc_clients)
		var/client/C = locate(userCode_client_map[userCode])
		var/room =  userCode_room_map[userCode]
		if(!C || !room)
			continue
		var/mob/M = C.mob
		if(!M)
			continue
		var/turf/T = get_turf(M)
		var/localroom = "[T.z]_[room]"
		if(userCode in userCodes_active)
			room_update(M)
		if(!params[localroom])
			params[localroom] = list()
		params[localroom][userCode] = list(T.x, T.y)
		locs_sent ++

	if(!locs_sent) //dont send empty packeys
		return
	send_json(params)


// Disconnects a user from voice chat
/datum/controller/subsystem/voicechat/proc/disconnect(userCode, from_byond = FALSE)
	if(!userCode)
		return

	toggle_active(userCode, FALSE)
	var/room = userCode_room_map[userCode]
	if(room)
		current_rooms[room] -= userCode

	var/client_ref = userCode_client_map[userCode]
	if(client_ref)
		userCode_client_map.Remove(userCode)
		client_userCode_map.Remove(client_ref)
		userCode_room_map.Remove(userCode)
		vc_clients -= userCode


	if(userCodes_speaking_icon[userCode])
		var/client/C = locate(client_ref)
		if(C && C.mob)
			C.mob.cut_overlay(userCodes_speaking_icon[userCode])

	if(from_byond)
		send_json(alist(cmd= "disconnect", userCode= userCode))


/datum/controller/subsystem/voicechat/proc/generate_userCode(client/C)
	if(!C)
		// CRASH("no client or wrong type")
		return
	. = copytext(md5("[C.computer_id][C.address][rand()]"),-4)
	//ensure unique
	while(. in userCode_client_map)
		. = copytext(md5("[C.computer_id][C.address][rand()]"),-4)
	return .


// Updates the voice chat room based on mob status
// this needs to be moved to signals at some point
/datum/controller/subsystem/voicechat/proc/room_update(mob/source)
	var/client/C = source.client
	var/userCode = client_userCode_map[ref(C)]
	if(!C || !userCode)
		return
	var/room
	switch(source.stat)
		if(CONSCIOUS to SOFT_CRIT)
			room = "living"
		if(UNCONSCIOUS to HARD_CRIT)
			room = null
		else
			room = "ghost"
	if(userCode_room_map[userCode] != room)
		move_userCode_to_room(userCode, room)
