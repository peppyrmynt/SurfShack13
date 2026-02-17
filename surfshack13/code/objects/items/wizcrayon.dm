/**
  * inserted into:
  * mining_corpses.dm - legion clowns
  * emergency_clown.dmm
  * lavaland_biodome_clown_planet.dmm
  * crashedclownship.dmm
  * wizard_den.dmm
  * abandonded_crates.dm
  * job_types/clown.dm - mail goodies
**/
#define TOTAL_USES 15
/obj/item/toy/wizcrayon
	name = "wizcrayon"
	desc = "A colorful crayon, it radiates power. (left click crayon to change color, right click to set ruin.)"
	icon = 'surfshack13/icons/obj/art/wizcrayon.dmi'
	icon_state = "wizcrayon"
	w_class = WEIGHT_CLASS_TINY
	var/uses = 15
	var/paint_color
	var/static/paint_colors
	var/static/list/stencil_buttons
	var/static/ui
	var/current_ruin = /obj/effect/decal/cleanable/wizcrayon/spore


/obj/item/toy/wizcrayon/Destroy(force)
	SSfrogui.atom_close_uis(src)
	. = ..()

/obj/item/toy/wizcrayon/proc/isValidSurface(atom/surface)
	. = TRUE
	var/is_floor =  istype(surface, /turf/open/floor)
	if(!is_floor)
		return FALSE
	var/has_ruins = locate(/obj/effect/decal/cleanable/wizcrayon) in surface.contents
	if(has_ruins)
		return FALSE

/obj/item/toy/wizcrayon/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	. = ..()
	if(!check_allowed_items(interacting_with))
		return NONE
	if(!isValidSurface(interacting_with))
		return NONE
	use_on(user, interacting_with)

/obj/item/toy/wizcrayon/proc/use_on(mob/user, turf/T)
	if(!do_after(user, 2 SECONDS, T, progress=TRUE))
		return

	var/atom/A = new current_ruin (T)
	if(!A)
		return
	A.color = paint_color
	uses --
	if (!uses)
		Destroy()
		return

	var/percent = round((uses/TOTAL_USES) * 100)
	SSfrogui.update_ui(user, src, data=percent, function="updateCrayonFillWidth")

/obj/item/toy/wizcrayon/attack_self(mob/user)
	if(!ui)
		create_ui()
	winset(user, null, "browser-options=devtools")
	SSfrogui.open_ui(user, src, ui, "size=315x210;")

/obj/item/toy/wizcrayon/proc/create_ui()
	if(ui)
		CRASH("create_ui called with exisiting ui")
	ui = file2text('surfshack13/frogui/wizcrayon.html')
	var/insert = ""
	paint_colors = list("Red" = COLOR_CRAYON_RED, "Orange" = COLOR_CRAYON_ORANGE, "Yellow" = COLOR_CRAYON_YELLOW, "Green" = COLOR_CRAYON_GREEN, "Blue" = COLOR_CRAYON_BLUE, "Purple" = COLOR_CRAYON_PURPLE)
	for(var/color, value in paint_colors)
		insert += "<label class='option color'><input type='radio' name='colorPicker' value='[color]' data-hex='[value]'><span style='--fill:[value];' class='colorBox'></span></label>\n"
	ui = replacetextEx(ui, "<!-- color select insert -->\n", insert)
	insert = ""
	stencil_buttons = list()
	for(var/type in subtypesof(/obj/effect/decal/cleanable/wizcrayon))
		type = "[type]"
		var/name = copytext(type, findlasttext(type, "/")+1)
		stencil_buttons[name] = type
		insert += "<label class='option'><input type='radio' name='ruin' value='[name]'/><span class='btn'>[name]</span></label>"
	ui = replacetextEx(ui, "<!-- ruin select insert -->\n", insert)

/obj/item/toy/wizcrayon/Topic(href, list/href_list)
	. = ..()
	FROGUI_USE_CHECK
	if(href_list["active_color"])
		paint_color = paint_colors[href_list["active_color"]]
	if(href_list["active_ruin"])
		current_ruin = stencil_buttons[href_list["active_ruin"]]
#undef TOTAL_USES
