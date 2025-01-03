/datum/team/swarmer
	name = "Swarmers"

//Simply lists them.
/datum/team/swarmer/roundend_report()
	var/list/parts = list()
	var/datum/antagonist/swarmer/bestswarmer = null
	parts += "<span class='header'>The [name] were:</span>"
	for(var/datum/antagonist/swarmer/swarmerantag in GLOB.antagonists)
		parts += ""
		parts += printplayer(swarmerantag.owner)
		parts += "<b>Resources Harvested:</b> [swarmerantag.total_gained_resources]"
		if(!bestswarmer || bestswarmer.total_gained_resources < swarmerantag.total_gained_resources)
			bestswarmer = swarmerantag
	parts += ""
	parts += span_greentext("Congratulations to [bestswarmer.owner.key], who proved to be the most obnoxious swarmer with [bestswarmer.total_gained_resources] resources harvested!")
	return "<div class='panel redborder'>[parts.Join("<br>")]</div>"

/datum/antagonist/swarmer
	name = "\improper Swarmer"
	job_rank = ROLE_SWARMER
	show_to_ghosts = TRUE
	show_in_antagpanel = FALSE
	prevent_roundtype_conversion = FALSE
	var/datum/team/swarmer/swarmer_team
	var/total_gained_resources = 0

/datum/antagonist/swarmer/greet()
	. = ..()
	owner.announce_objectives()

/datum/antagonist/swarmer/on_gain()
	forge_objectives()
	. = ..()

/datum/antagonist/swarmer/create_team(datum/team/swarmer/new_team)
	if(!new_team)
		for(var/datum/antagonist/swarmer/swarmerantag in GLOB.antagonists)
			if(!swarmerantag.owner || !swarmerantag.swarmer_team)
				continue
			swarmer_team = swarmerantag.swarmer_team
			return
		swarmer_team = new
	else
		if(!istype(new_team))
			CRASH("Wrong swarmer team type provided to create_team")
		swarmer_team = new_team

/datum/antagonist/swarmer/get_team()
	return swarmer_team

/datum/antagonist/swarmer/get_preview_icon()
	var/icon/swarmer_icon = icon('surfshack13/icons/swarmers/swarmer.dmi', "swarmer")
	swarmer_icon.Shift(NORTH, 8)
	return finish_preview_icon(swarmer_icon)

/datum/objective/swarmer/New()
	explanation_text = "Have the most resources harvested out of any swarmer by the end of the shift."
	..()

/datum/antagonist/swarmer/forge_objectives()
	var/datum/objective/swarmer/objective = new
	objective.owner = owner
	objectives += objective
