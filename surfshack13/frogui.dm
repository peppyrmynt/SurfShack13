/* ui prototype
* uses more modern css stuff,
* more syntax heavy (its just pure html,js,css, so no premade elements)
* doesnt require external tools to load
* each ui type is lazy loaded once, so it gets built per type on request once and then reused next request.
* tried to make ui look like tgui for user
* experimental for now
* per client, you can only have one ui based from an atom.
* ui closes if mob is far enough away from it
*/

SUBSYSTEM_DEF(frogui)
	name = "FrogUI"
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT
	flags = SS_NO_INIT
	wait = 1.5 SECONDS
	/// List of all the open ui's a client has. key = client, value = list(ref(atom))
	var/alist/client_uis = alist()
	/// All open uis targeting a specific atom. key = atom, value = list(clients)
	var/alist/atom_ui_clients = alist()

/// Checks if the ui should be closed
/datum/controller/subsystem/frogui/fire(resumed)
	for(var/key,val in atom_ui_clients)
		var/atom/ui_atom = key
		var/list/clients = val
		for(var/client/C in clients)
			var/mob/ui_mob = C.mob
			if(ui_status_user_is_adjacent(ui_mob, ui_atom) <= UI_DISABLED)
				close_ui(ui_mob, ui_atom)

/// Open ui, register it in client list, and the atom list
/datum/controller/subsystem/frogui/proc/open_ui(mob/user, atom/source, ui, params)
	var/client/C = user.client
	if(!C)
		return
	if(isnull(client_uis[C]))
		C << browse_rsc('surfshack13/frogui/ui.css', "ui.css")
		client_uis[C] = list()
	if(isnull(atom_ui_clients[source]))
		atom_ui_clients[source] = list()
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

/// Checks if the ui should be closed, and then closes the ui. Returns true if the ui was closed.
/datum/controller/subsystem/frogui/proc/close_topic_check(mob/user, atom/source)
	if(!user || !source)
		CRASH("topic checked without user or source user:[user] source:[source]")
	if(user.default_can_use_topic(source) != UI_INTERACTIVE)
		close_ui(user, source)
		return TRUE


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

/// Close all uis tied to a given atom.
/datum/controller/subsystem/frogui/proc/atom_close_uis(atom/source)
	var/source_ref = ref(source)
	for(var/client/C in atom_ui_clients[source])
		C << browse(null, "window=[source_ref]")
		client_uis[C] -= source_ref
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
