/obj/item/implant/hypno_tracker
	name = "hypnotic telemetry implant"
	desc = "An implant of syndicate origin allowing an agent visually identify hypnotised victims with a HUD."
	icon = 'icons/hud/implants.dmi'
	icon_state = "generic"
	actions_types = null
	implant_color = "r"
	allow_multiple = FALSE
	implant_flags = NONE

/obj/item/implant/hypno_tracker/implant(mob/living/target, mob/user, silent = FALSE, force = FALSE)
	. = ..()
	if(!.)
		return FALSE

	var/datum/atom_hud/hypno_hud = GLOB.huds["brainwashed"]
	if(hypno_hud)
		hypno_hud.show_to(target)

	to_chat(target, span_notice("You feel a faint, cool pulse behind your eyes as your neural pathways align with hypnotic telemetry."))
	return TRUE

/obj/item/implant/hypno_tracker/removed(mob/living/source, silent = FALSE, special = 0)
	var/datum/atom_hud/hypno_hud = GLOB.huds["brainwashed"]
	if(hypno_hud && source)
		hypno_hud.hide_from(source)

	if(source)
		to_chat(source, span_warning("The faint psychic static behind your eyes fades completely."))
	return ..()

/obj/item/implant/hypno_tracker/is_shown_on_console(obj/machinery/computer/prisoner/management/console)
	return FALSE

/obj/item/implantcase/hypno_tracker
	name = "implant case - 'Hypnotic Telemetry'"
	desc = "A glass case containing a hypnotic telemetry implant."
	imp_type = /obj/item/implant/hypno_tracker

/obj/item/implanter/hypno_tracker
	name = "implanter (hypnotic telemetry)"

/obj/item/implanter/hypno_tracker/Initialize(mapload)
	. = ..()
	imp = new /obj/item/implant/hypno_tracker(src)
	update_appearance()
