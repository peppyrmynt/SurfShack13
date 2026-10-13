/obj/item/implant/hypno_tracker
	name = "hypnotic telemetry implant"
	desc = "An implant of syndicate origin allowing an agent to visually identify hypnotised victims with a HUD."
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

	for(var/datum/antagonist/hypnotized/hypnotized_datum in GLOB.antagonists)
		var/mob/living/hypnotized_mob = hypnotized_datum.owner?.current
		if(hypnotized_mob)
			show_hypnotized(hypnotized_mob, hypnotized_datum)

	to_chat(target, span_notice("You feel a faint, cool pulse behind your eyes as your neural pathways align with hypnotic telemetry."))
	return TRUE

/obj/item/implant/hypno_tracker/removed(mob/living/source, silent = FALSE, special = 0)
	for(var/datum/antagonist/hypnotized/hypnotized_datum in GLOB.antagonists)
		var/mob/living/hypnotized_mob = hypnotized_datum.owner?.current
		if(hypnotized_mob)
			hide_hypnotized(hypnotized_mob)

	if(source)
		to_chat(source, span_warning("The faint psychic static behind your eyes fades completely."))
	return ..()

/// Shows one hypnotized victim's antag marker only to this implant's wearer.
/obj/item/implant/hypno_tracker/proc/show_hypnotized(mob/living/hypnotized_mob, datum/antagonist/hypnotized/hypnotized_datum)
	if(!imp_in || !hypnotized_mob || !hypnotized_datum)
		return

	hypnotized_mob.add_alt_appearance(
		/datum/atom_hud/alternate_appearance/basic/one_person,
		"hypno_tracker_[REF(src)]",
		hypnotized_datum.hud_image_on(hypnotized_mob),
		NONE,
		imp_in,
	)

/// Removes this implant's marker from one formerly hypnotized victim.
/obj/item/implant/hypno_tracker/proc/hide_hypnotized(mob/living/hypnotized_mob)
	if(!hypnotized_mob)
		return
	hypnotized_mob.remove_alt_appearance("hypno_tracker_[REF(src)]")

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
