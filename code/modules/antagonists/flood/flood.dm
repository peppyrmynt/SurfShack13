/// SurfShack Flood antagonist
///
/// Adapted from HaloSpaceStation13's Flood gameplay to SurfShack's current
/// antagonist, simple-animal, and dynamic-ruleset architecture.

GLOBAL_VAR_INIT(flood_infections, 0)
/// Time when the hive can appoint a new overseer after its leader dies.
GLOBAL_VAR_INIT(flood_overseer_replacement_at, 0)

/proc/flood_has_living_overseer()
	for(var/mob/living/basic/flood/overseer/leader in GLOB.mob_living_list)
		if(!QDELETED(leader) && leader.stat != DEAD)
			return TRUE
	return FALSE

/proc/can_form_flood_overseer()
	return world.time >= GLOB.flood_overseer_replacement_at && !flood_has_living_overseer()

/// Check both infected minds and Flood forms when selecting potential hosts.
/proc/is_flood_target(mob/target_mob)
	return target_mob?.mind?.has_antag_datum(/datum/antagonist/flood) || istype(target_mob, /mob/living/basic/flood)

/// Infection forms can latch onto people, monkeys, and organic animals.
/proc/is_flood_infectable(mob/living/host)
	if(is_flood_target(host))
		return FALSE
	if(ishuman(host))
		return TRUE
	return isanimal_or_basicmob(host) && (host.mob_biotypes & MOB_ORGANIC) && !(host.mob_biotypes & MOB_ROBOTIC)

/// Spoken Flood language is local; the chorus verb below reaches every active Flood player.
/datum/language/flood
	name = "Floodmind"
	desc = "The low, unsettling speech shared by Flood units."
	// :f is handled by Flood speech; ,f belongs to Nekomimetic.
	key = "q"
	flags = TONGUELESS_SPEECH | NO_STUTTER
	default_priority = -1
	icon_state = "narsie"
	syllables = list("gra", "vrak", "krr", "shaa", "thrum", "rukh", "hss", "vorr")

/datum/language_holder/flood
	understood_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/flood = list(LANGUAGE_ATOM),
	)
	spoken_languages = list(
		/datum/language/common = list(LANGUAGE_ATOM),
		/datum/language/flood = list(LANGUAGE_ATOM),
	)

/datum/team/flood
	name = "\improper Flood"

/datum/team/flood/roundend_report()
	var/list/parts = list()
	parts += span_header("The [name] were:")
	parts += printplayerlist(members)
	parts += span_notice("Total infected hosts: [GLOB.flood_infections]")
	return "<div class='panel redborder'>[parts.Join("<br>")]</div>"

/datum/antagonist/flood
	name = "\improper Flood"
	ui_name = "AntagInfoFlood"
	roundend_category = "flood"
	antagpanel_category = "Flood"
	job_rank = ROLE_FLOOD
	show_to_ghosts = TRUE
	show_in_antagpanel = TRUE
	can_assign_self_objectives = TRUE
	default_custom_objective = "Spread the Flood and establish a viable infestation."
	var/datum/team/flood/flood_team

/datum/antagonist/flood/on_gain()
	forge_objectives()
	. = ..()
	SEND_SOUND(owner.current, sound('sound/flood/flood_infect_gravemind.ogg', volume = 60))

/datum/antagonist/flood/greet()
	to_chat(owner.current, span_danger("You are part of the Flood."))
	to_chat(owner.current, span_notice("Open your Flood antagonist information for your abilities, objectives, and guide."))

/datum/antagonist/flood/ui_data(mob/user)
	var/list/data = list()
	var/mob/living/basic/flood/current_form = owner?.current
	data["can_change_objective"] = can_assign_self_objectives && istype(current_form, /mob/living/basic/flood/overseer) && user == current_form && current_form.stat != DEAD
	if(istype(current_form, /mob/living/basic/flood/overseer))
		data["current_form"] = "Overseer"
	else if(istype(current_form, /mob/living/basic/flood/constructor))
		data["current_form"] = "Constructor"
	else if(istype(current_form, /mob/living/basic/flood/carrier))
		data["current_form"] = "Carrier"
	else
		data["current_form"] = "Combat"
	return data

/datum/antagonist/flood/ui_static_data(mob/user)
	. = ..()
	.["can_change_objective"] = can_assign_self_objectives && istype(owner?.current, /mob/living/basic/flood/overseer) && user == owner.current && owner.current.stat != DEAD

/datum/antagonist/flood/submit_player_objective(retain_existing = FALSE, retain_escape = TRUE, force = FALSE)
	if(!force && (!istype(owner?.current, /mob/living/basic/flood/overseer) || owner.current.stat == DEAD))
		return
	return ..()

/datum/antagonist/flood/create_team(datum/team/flood/new_team)
	if(!new_team)
		for(var/datum/antagonist/flood/other_flood in GLOB.antagonists)
			if(other_flood.owner && other_flood.flood_team)
				flood_team = other_flood.flood_team
				return
		flood_team = new
	else
		if(!istype(new_team))
			CRASH("Wrong Flood team type provided to create_team")
		flood_team = new_team

/datum/antagonist/flood/get_team()
	return flood_team

/datum/antagonist/flood/forge_objectives()
	var/datum/objective/flood_spread/objective = new
	objective.owner = owner
	objectives += objective

/datum/objective/flood_spread
	explanation_text = "Spread the Flood by creating infected hosts."

/datum/objective/flood_spread/check_completion()
	return GLOB.flood_infections >= 5

/datum/antagonist/flood/roundend_report()
	if(!owner?.current)
		return
	var/list/report = list()
	report += span_header("The Flood:")
	report += printplayer(owner)
	report += span_notice("Hosts infected by the Flood: [GLOB.flood_infections]")
	return "<div class='panel redborder'>[report.Join("<br>")]</div>"
