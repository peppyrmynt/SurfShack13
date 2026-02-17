/* ui prototype
* uses more modern css stuff,
* more syntax heavy (its just pure html,js,css, so no premade elements)
* doesnt require external tools to load
* each ui type is lazy loaded once, so it gets built per type on request once and then reused next request.
* tried to make ui look and function same as tgui for user
* experimental for now
*/
SUBSYSTEM_DEF(frogui)
	name = "frogui"
	flags = SS_NO_FIRE
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT
	var/client_uis = alist()
	var/ui_clients = alist()

/datum/controller/subsystem/frogui/Initialize()
	. = ..()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/frogui/proc/open_ui(mob/user, atom/source, ui, params)
	var/client/C = user.client
	if(!C)
		return
	if(isnull(client_uis[C]))
		C << browse_rsc('surfshack13/frogui/ui.css', "ui.css")
		client_uis[C] = list()
	if(isnull(ui_clients[source]))
		ui_clients[source] = list()

	var/source_ref = ref(source)
	client_uis[C] += source_ref
	ui_clients[source] += C
	C << browse(replacetextEx(ui,\
		"/* ref insert */", "const ref = [json_encode(source_ref)];"),\
		 "window=[source_ref];[params]")
	winset(C, source_ref, "on-close=\"frogui_close [source_ref]\"")

/datum/controller/subsystem/frogui/proc/close_ui(mob/user, atom/source)
	var/client/C = user.client
	var/source_ref = ref(source)
	if(!C || !source_ref)
		CRASH("no")

	if(client_uis[C].Find(source_ref))
		C  << browse(null, "window=[source_ref]")
		client_uis[C] -= source_ref
		ui_clients[source] -= C

/datum/controller/subsystem/frogui/proc/atom_close_uis(atom/source)
	var/source_ref = ref(source)
	for(var/client/C in ui_clients[source])
		C << browse(null, "window=[source_ref]")
		client_uis[C] -= source_ref
	ui_clients[source] = null

/datum/controller/subsystem/frogui/proc/update_ui(mob/user, atom/source, data, function)
	var/source_ref = ref(source)
	user << output(data, "[source_ref].browser:[function]")

/client/verb/frogui_close(source_ref as text)
	set name = "frogui_close"
	set hidden = TRUE
	var/mob/user = src?.mob
	if(!user)
		return
	SSfrogui.close_ui(user, locate(source_ref))
