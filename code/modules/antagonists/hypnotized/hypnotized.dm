/// Antag datum associated with the hypnosis brain trauma, used for displaying objectives and antag hud
/datum/antagonist/hypnotized
	name = "\improper Hypnotized Victim"
	stinger_sound = 'sound/music/antag/hypnotized.ogg'
	job_rank = ROLE_HYPNOTIZED
	roundend_category = "hypnotized victims"
	antag_hud_name = "brainwashed"
	ui_name = "AntagInfoBrainwashed"
	show_in_antagpanel = TRUE
	antagpanel_category = ANTAG_GROUP_CREW
	show_name_in_check_antagonists = TRUE
	count_against_dynamic_roll_chance = FALSE

	/// Brain trauma associated with this antag datum
	var/datum/brain_trauma/hypnosis/trauma

/datum/antagonist/hypnotized/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/hypnotized_mob = mob_override || owner.current
	if(!hypnotized_mob)
		return

	for(var/obj/item/implant/hypno_tracker/tracker in GLOB.tracked_implants)
		tracker.show_hypnotized(hypnotized_mob, src)

/datum/antagonist/hypnotized/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/hypnotized_mob = mob_override || owner.current
	if(!hypnotized_mob)
		return

	for(var/obj/item/implant/hypno_tracker/tracker in GLOB.tracked_implants)
		tracker.hide_hypnotized(hypnotized_mob)
/datum/antagonist/hypnotized/Destroy()
	QDEL_NULL(trauma)
	return ..()
