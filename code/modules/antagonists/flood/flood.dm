/// SurfShack Flood antagonist
///
/// Adapted from HaloSpaceStation13's Flood gameplay to SurfShack's current
/// antagonist, simple-animal, and dynamic-ruleset architecture.

GLOBAL_VAR_INIT(flood_infections, 0)

/// Check both infected minds and Flood forms when selecting potential hosts.
/proc/is_flood_target(mob/target_mob)
	return target_mob?.mind?.has_antag_datum(/datum/antagonist/flood) || istype(target_mob, /mob/living/basic/flood)

/// Spoken Flood language is local; the chorus verb below reaches every active Flood player.
/datum/language/flood
	name = "Floodmind"
	desc = "The low, unsettling speech shared by Flood forms."
	key = "f"
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
	to_chat(owner.current, span_notice("Infection forms latch onto living humans before dealing damage."))
	to_chat(owner.current, span_notice("Combat forms can evolve into carrier, constructor, or overseer forms. Constructors produce infection forms."))
	to_chat(owner.current, span_notice("Human combat forms can use ordinary station equipment and guns."))
	to_chat(owner.current, span_notice("While latched to living humans, infection forms deal 10 brute every two seconds. Only dead hosts can be converted, after five seconds attached to the corpse. Living hosts can resist or escape."))
	to_chat(owner.current, span_notice("Standing on Flood-covered floors slowly heals your biomass."))
	to_chat(owner.current, span_notice("Use Flood Chorus to speak to every active Flood player, or :f to speak Floodmind nearby."))

/datum/antagonist/flood/ui_data(mob/user)
	var/list/data = list()
	var/mob/living/basic/flood/current_form = owner?.current
	if(istype(current_form, /mob/living/basic/flood/overseer))
		data["current_form"] = "Overseer"
	else if(istype(current_form, /mob/living/basic/flood/constructor))
		data["current_form"] = "Constructor"
	else if(istype(current_form, /mob/living/basic/flood/carrier))
		data["current_form"] = "Carrier"
	else
		data["current_form"] = "Combat"
	return data

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
