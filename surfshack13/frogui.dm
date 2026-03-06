/* ui prototype
* uses more modern css stuff,
* more syntax heavy (its just pure html,js,css, so no premade elements)
* doesnt require external tools to load
* each ui type is lazy loaded once, so it gets built per type on request once and then reused next request.
* tried to make ui look and function same as tgui for user
* experimental for now
* per client, you can only have one ui based from an atom.
*/

SUBSYSTEM_DEF(frogui)
	name = "frogui"
	flags = SS_NO_FIRE
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT
	/// list of all the open ui's a client has
	var/alist/client_uis = alist()
	/// all open uis targeting a specific atom.
	var/alist/atom_ui_clients = alist()

/datum/controller/subsystem/frogui/Initialize()
	. = ..()
	return SS_INIT_SUCCESS

///open ui, register it in client and source atoms
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




	C << browse(replacetextEx(ui,\
		"/* ref insert */", "const ref = [json_encode(source_ref)];"),\
		 "window=[source_ref];[params]")
	winset(C, source_ref, "on-close=\"frogui_close [source_ref]\"")

	var/list/client_ui = client_uis[C]
	if(!client_ui.Find(source_ref))
		client_uis[C] += source_ref
		atom_ui_clients[source] += C


///close ui, clean up variables.
/datum/controller/subsystem/frogui/proc/close_ui(mob/user, atom/source)
	var/client/C = user.client
	var/source_ref = ref(source)
	if(!C || !source_ref)
		CRASH("no")

	if(client_uis[C])
		C  << browse(null, "window=[source_ref]")
		client_uis[C] -= source_ref
		atom_ui_clients[source] -= C

/// close all uis tied to a given atom
/datum/controller/subsystem/frogui/proc/atom_close_uis(atom/source)
	var/source_ref = ref(source)
	for(var/client/C in atom_ui_clients[source])
		C << browse(null, "window=[source_ref]")
		client_uis[C] -= source_ref
	atom_ui_clients[source] = null

/// send data to ui
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
	var/mob/user = src?.mob
	if(!user)
		return
	SSfrogui.close_ui(user, locate(source_ref))
