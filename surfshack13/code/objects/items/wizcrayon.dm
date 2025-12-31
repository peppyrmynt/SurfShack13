/**
  * inserted into:
  * mining_corpses.dm - legion clowns
  * emergency_clown.dmm
  * lavaland_biodome_clown_planet.dmm
  * crashedclownship.dmm
  * abandonded_crates.dmm
  * job_types/clown.dm - mail goodies
**/

/obj/item/toy/wizcrayon
	name = "wizcrayon"
	desc = "A colorful crayon, it radiates power. (left click crayon to change color)"
	icon = 'icons/obj/art/crayons.dmi'
	icon_state = "crayonrainbow"
	var/paint_color = COLOR_CRAYON_RED
	var/drawtype = "flip"
	var/uses = 15
	var/current_ruin = /obj/effect/decal/cleanable/wizcrayon/flipper

/obj/item/toy/wizcrayon/proc/isValidSurface(surface)
	return (istype(surface, /turf/open/floor) && (!locate(/obj/effect/decal/cleanable/wizcrayon/) in surface))

/obj/item/toy/wizcrayon/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	. = ..()
	if (!check_allowed_items(interacting_with) && !istype(interacting_with, /obj/effect/decal/cleanable) && !isValidSurface(interacting_with))
		return NONE
	use_on(user, interacting_with)

/obj/item/toy/wizcrayon/proc/use_on(mob/user, turf/T)
	if(!do_after(user, 2 SECONDS, T, progress=TRUE))
		return

	var/atom/A = new current_ruin (T)
	A.color = paint_color
	uses --
	if (!uses)
		Destroy()
		return
	to_chat(user, span_notice("[uses] uses left"))

//tgui is an act against god. The two procs below will be updated once I make an alternative.
/obj/item/toy/wizcrayon/attack_self(mob/user)
	var/static/list/ruin_types = subtypesof(/obj/effect/decal/cleanable/wizcrayon)
	var/choice = input("Select drawing") as null|anything in ruin_types
	if(choice)
		current_ruin = choice

/obj/item/toy/wizcrayon/attack_self_secondary(mob/user, modifiers)
	. = ..()
	var/static/list/colors = list("Red" = COLOR_CRAYON_RED, "Orange" = COLOR_CRAYON_ORANGE, "Yellow" = COLOR_CRAYON_YELLOW, "Green" = COLOR_CRAYON_GREEN, "Blue" = COLOR_CRAYON_BLUE, "Purple" = COLOR_CRAYON_PURPLE)
	var/color_choice = input("Pick color") as null|anything in colors
	if(color_choice)
		paint_color = colors[color_choice]
