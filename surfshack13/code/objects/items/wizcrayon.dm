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
	var/active_color_name = "Red"
	var/active_color = COLOR_CRAYON_RED
	var/static/alist/paint_colors
	var/static/alist/stencil_buttons
	var/static/ui
	var/active_ruin_name = "flip"
	var/active_ruin = /obj/effect/decal/cleanable/wizcrayon/flip
	var/percent = 100

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

	var/atom/A = new active_ruin (T)
	if(!A)
		return
	A.color = active_color
	uses --
	if (!uses)
		Destroy()
		return

	percent = round((uses/TOTAL_USES) * 100)
	SSfrogui.update_ui(user, src)

/obj/item/toy/wizcrayon/ui_interact(mob/user)
	. = ..()
	if(!ui)
		create_ui()
	SSfrogui.open_ui(user, src, ui, "size=315x210;")

/obj/item/toy/wizcrayon/ui_data(mob/user)
	. = ..()
	.["active_color_name"] = active_color_name
	.["active_ruin_name"] = active_ruin_name
	.["percent"] = percent


/obj/item/toy/wizcrayon/proc/create_ui()
	if(ui)
		CRASH("create_ui called with exisiting ui")
	ui = file2text('surfshack13/frogui/wizcrayon.html')
	stencil_buttons = alist()
	for(var/type in subtypesof(/obj/effect/decal/cleanable/wizcrayon))
		type = "[type]"
		var/name = copytext(type, findlasttext(type, "/")+1)
		stencil_buttons[name] = type
	paint_colors = alist("Red" = COLOR_CRAYON_RED, "Orange" = COLOR_CRAYON_ORANGE, "Yellow" = COLOR_CRAYON_YELLOW, "Green" = COLOR_CRAYON_GREEN, "Blue" = COLOR_CRAYON_BLUE, "Purple" = COLOR_CRAYON_PURPLE)

/obj/item/toy/wizcrayon/Topic(href, list/href_list)
	. = ..()

	var/mob/user = usr
	if(SSfrogui.close_topic_check(user, src))
		return
	if(href_list["ready"])
		SSfrogui.update_ui(user, src)
	if(href_list["active_color_name"])
		active_color_name = href_list["active_color_name"]
		active_color = paint_colors[active_color_name]
	if(href_list["active_ruin_name"])
		active_ruin_name = href_list["active_ruin_name"]
		active_ruin = stencil_buttons[active_ruin_name]
#undef TOTAL_USES
