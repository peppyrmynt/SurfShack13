/// Restored HippieStation acquisition hooks for the Stand Arrow.

/datum/map_template/ruin/lavaland/stand_arrow
	name = "Mysterious Attic"
	id = "guardian-arrow"
	description = "A strange attic surrounded by lava. Something inside radiates an unusually powerful signal."
	suffix = "lavaland_surface_stand.dmm"
	cost = 20
	allow_duplicates = FALSE

/area/ruin/powered/stand_ruin
	name = "Mysterious Attic"
	icon_state = "dk_yellow"

/obj/structure/displaycase/stand_arrow
	start_showpiece_type = /obj/item/stand_arrow

/obj/structure/displaycase/stand_arrow/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/gps, "Powerful Signal")
