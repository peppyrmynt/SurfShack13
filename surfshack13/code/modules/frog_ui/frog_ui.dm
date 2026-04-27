/* ui prototype
* uses more modern css stuff,
* more syntax heavy (its just pure html,js,css, so no premade elements)
* doesnt require external tools to load
* each ui type is lazy loaded once, so it gets built per type on request once and then reused next request.
* tried to make ui look like tgui for user
* experimental for now
* per client, you can only have one ui based from an atom.
* if you want to have multiple UI's coming from the same atom, you can go fuck yourself.
* ui closes if mob is far enough away from it, unless flag is set
*/



SUBSYSTEM_DEF(frogui)
	name = "FrogUI"
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT | RUNLEVEL_POSTGAME
	flags = SS_NO_INIT
	wait = 1.5 SECONDS
	/// List of all the open ui's a client has. key = client, value = list(ref(atom))
	var/alist/client_uis = alist()
	/// All open uis targeting a specific atom. key = atom, value = list(clients)
	var/alist/atom_ui_clients = alist()
	/// UI flags per atom key = atom, value = flags
	var/alist/atom_ui_flags = alist()

/// Checks if the ui should be closed
/datum/controller/subsystem/frogui/fire(resumed)
	for(var/key,val in atom_ui_clients)
		var/atom/ui_atom = key
		var/list/clients = val
		if(atom_ui_flags[ui_atom] & FROG_UI_IGNORE_PROXIMITY)
			continue
		for(var/client/C in clients)
			var/mob/ui_mob = C.mob
			if(ui_status_user_is_adjacent(ui_mob, ui_atom) <= UI_DISABLED)
				close_ui(ui_mob, ui_atom)

/// Open ui, register it in client list, and the atom list
/datum/controller/subsystem/frogui/proc/open_ui(mob/user, atom/source, ui, params, ui_flags = 0)
	var/client/C = user.client
	if(!C)
		return
	if(isnull(client_uis[C]))
		C << browse_rsc('surfshack13/frogui/ui.css', "ui.css")
		client_uis[C] = list()
	if(isnull(atom_ui_clients[source]))
		atom_ui_clients[source] = list()
	atom_ui_flags[source] = ui_flags

	if(!(ui_flags & FROGUI_NO_TOPIC))
		RegisterSignal(source, COMSIG_TOPIC, PROC_REF(on_topic))

	var/source_ref = ref(source)
	var/replacedtext  = replacetextEx(ui,"/* ref insert */", "const ref = [json_encode(source_ref)];")
	if(replacedtext)
		ui = replacedtext
	C << browse(ui, "window=[source_ref];[params]")
	winset(C, source_ref, "on-close=\"frogui_close [source_ref]\"")

	var/list/client_ui = client_uis[C]
	if(!client_ui.Find(source_ref))
		client_uis[C] += source_ref
		atom_ui_clients[source] += C


/datum/controller/subsystem/frogui/proc/on_topic(datum/source, usr, list/href_list)
	SIGNAL_HANDLER
	var/mob/user = usr

	var/client/C = user.client
	var/list/ui_clients = atom_ui_clients[source]

	//if client is not a ui user bail.
	if(!C || !ui_clients.Find(C))
		close_ui(user, source)
		return

	if(!(atom_ui_flags[source] & FROG_UI_IGNORE_PROXIMITY))
		if(user.default_can_use_topic(source) != UI_INTERACTIVE)
			close_ui(user, source)
			return

	source.frog_ui_topic(source, user, href_list)



/// Checks if the ui should be closed, and then closes the ui. Returns true if the ui was closed.


/// Closes the ui, cleans up list.
/datum/controller/subsystem/frogui/proc/close_ui(mob/user, atom/source)
	var/client/C = user.client
	var/source_ref = ref(source)
	if(!C || !source_ref)
		CRASH("no")

	if(client_uis[C])
		C  << browse(null, "window=[source_ref]")
		client_uis[C] -= source_ref
		atom_ui_clients[source] -= C

	//If no one else is using the ui, stop listening to topic.
	if(!length(atom_ui_clients[source]) && !(atom_ui_flags[source] & FROGUI_NO_TOPIC))
		UnregisterSignal(source, COMSIG_TOPIC)
	atom_ui_flags -= source


/// Close all uis tied to a given atom.
/datum/controller/subsystem/frogui/proc/atom_close_uis(atom/source)
	var/source_ref = ref(source)
	for(var/client/C in atom_ui_clients[source])
		C << browse(null, "window=[source_ref]")
		client_uis[C] -= source_ref

	if(atom_ui_flags[source] & ~FROGUI_NO_TOPIC)
		UnregisterSignal(source, COMSIG_TOPIC)

	atom_ui_clients[source] = null

/// Send data to ui
/datum/controller/subsystem/frogui/proc/update_ui(mob/user, atom/source)
	var/source_ref = ref(source)
	var/data = source.ui_data()
	var/message = url_encode(json_encode(data))
	user << output(message, "[source_ref].browser:update")

// see external.dm`
/// client command to inform server that ui has closed, deletes closed ui variables
/client/verb/frogui_close(source_ref as text)
	set name = "frogui_close"
	set hidden = TRUE
	var/mob/user = mob
	if(!user)
		return
	SSfrogui.close_ui(user, locate(source_ref))

/datum/proc/frog_ui_topic(datum/source, mob/user, list/href_list)
	SHOULD_CALL_PARENT(TRUE)
	if(src != source)
		CRASH("dont call it like that")
