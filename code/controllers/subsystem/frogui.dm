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



/datum/controller/subsystem/frogui/proc/open_ui(mob/user, atom/source, ui, params)
	var/client/C = user.client
	if(!C)
		return
	if(isnull(client_uis[C]))
		C << browse_rsc('frogui/ui.css', "ui.css")
		client_uis[C] = list()
	var/source_ref = ref(source)
	client_uis[C] += source_ref
	C << browse(replacetextEx(ui, "/* ref insert */", "const ref = [json_encode(source_ref)];"), "window=[source_ref];[params]")

