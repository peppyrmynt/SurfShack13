// Gang War - ported from HippieStation.
// Gang bosses recruit crew with pens, tag areas with gang spraycans to earn influence, spend it on a
// gangtool shop, and try to win by defending a Dominator until its takeover countdown finishes.

/// Gang team subtypes nobody has picked yet
GLOBAL_LIST_INIT(possible_gangs, subtypesof(/datum/team/gang))
/// Gangs currently in the round
GLOBAL_LIST_EMPTY(gangs)

/// How often gangs earn influence and get a status report
#define GANG_INFLUENCE_INTERVAL (3 MINUTES)
/// How many times a gang can force-recall the shuttle
#define GANG_MAXIMUM_RECALLS 3

/datum/team/gang
	name = "Gang"
	member_name = "gangster"
	/// Bosses and lieutenants
	var/list/datum/mind/leaders = list()
	/// How many leaders a gang can have
	var/max_leaders = GANG_MAX_LEADERS
	/// Area types this gang holds, as type = name
	var/list/territories = list()
	/// Territories lost since the last report
	var/list/lost_territories = list()
	/// Territories gained since the last report
	var/list/new_territories = list()
	/// All registered gangtools
	var/list/obj/item/gangtool/gangtools = list()
	/// world.time the takeover finishes, or GANG_NOT_DOMINATING
	var/domination_time = GANG_NOT_DOMINATING
	/// Dominator activations left
	var/dom_attempts = GANG_INITIAL_DOM_ATTEMPTS
	/// Hex colour used for HUD icons, tags and the dominator
	var/color = COLOR_WHITE
	/// Currency for the gangtool shop
	var/influence = 0
	/// Set once a dominator finishes
	var/winner = FALSE
	/// Uniforms that count as gang colours
	var/list/inner_outfits = list()
	/// Outerwear that counts as gang colours
	var/list/outer_outfits = list()
	/// world.time of the next influence payout
	var/next_point_time
	/// Shuttle recalls left
	var/recalls = GANG_MAXIMUM_RECALLS
	/// Gangmageddon: whether this gang has placed its reinforcements gateway
	var/gateway_built = FALSE
	/// Gangmageddon: mind = list(tags they sprayed), for personal income
	var/list/tags_by_mind = list()

/datum/team/gang/New(starting_members)
	. = ..()
	GLOB.gangs += src
	GLOB.possible_gangs -= type
	next_point_time = world.time + GANG_INFLUENCE_INTERVAL
	addtimer(CALLBACK(src, PROC_REF(handle_territories)), GANG_INFLUENCE_INTERVAL)

/datum/team/gang/Destroy()
	GLOB.gangs -= src
	return ..()

/datum/team/gang/roundend_report()
	var/list/report = list()
	report += "<span class='header'>[name]:</span>"
	if(winner)
		report += span_greentext("The [name] gang was successful!")
	else
		report += span_redtext("The [name] gang has failed!")
	report += "The [name] gang bosses were:"
	report += printplayerlist(leaders)
	report += "The [name] [member_name]s were:"
	report += printplayerlist(members - leaders)
	return "<div class='panel redborder'>[report.Join("<br>")]</div>"

/datum/team/gang/proc/greet_gangster(datum/mind/gangster)
	to_chat(gangster.current, "<font size=3 color=red><b>You are now a member of the [name] Gang!</b></font>")
	to_chat(gangster.current, span_red("Help your bosses take over the station by claiming territory with <b>special spraycans</b> only they can provide. Simply spray on any unclaimed area of the station."))
	to_chat(gangster.current, span_red("Their ultimate objective is to take over the station with a Dominator machine."))
	to_chat(gangster.current, span_red("You can identify your mates by their <b>large, bright \[G\] <font color='[color]'>icon</font></b>."))

/// Pays out influence and reports territory changes. Runs every GANG_INFLUENCE_INTERVAL.
/datum/team/gang/proc/handle_territories()
	next_point_time = world.time + GANG_INFLUENCE_INTERVAL
	addtimer(CALLBACK(src, PROC_REF(handle_territories)), GANG_INFLUENCE_INTERVAL)
	if(!length(leaders))
		return

	// Territories that were lost and retaken before this report still count
	var/list/reclaimed = new_territories & lost_territories
	territories |= reclaimed
	new_territories -= reclaimed
	lost_territories -= reclaimed

	var/list/lost_names = list()
	for(var/area_type in lost_territories)
		lost_names += "[lost_territories[area_type]]"
		territories -= area_type
	var/list/added_names = list()
	for(var/area_type in new_territories)
		added_names += "[new_territories[area_type]]"
		territories[area_type] = new_territories[area_type]

	var/message = "<b>[src] Gang Status Report:</b><br>*---------*<br>"
	message += "<b>[length(added_names)] new territories:</b><br><i>[added_names.Join(", ")]</i><br>"
	message += "<b>[length(lost_names)] territories lost:</b><br><i>[lost_names.Join(", ")]</i><br>"
	new_territories = list()
	lost_territories = list()

	var/uniformed = check_clothing()
	message += "Your gang now has <b>[station_control_percent()]% control</b> of the station.<br>*---------*<br>"
	if(domination_time != GANG_NOT_DOMINATING)
		var/new_time = max(world.time, domination_time - (uniformed * 4) - (length(territories) * 2))
		if(new_time < domination_time)
			message += "Takeover shortened by [(domination_time - new_time) * 0.1] seconds for defending [length(territories)] territories.<br>"
			domination_time = new_time
		message += "<b>[domination_time_remaining()] seconds remain</b> in hostile takeover.<br>"
	else if(GLOB.gangmageddon_active)
		for(var/obj/item/gangtool/personal/tool in gangtools)
			tool.pay_income()
	else
		var/new_influence = min(999, influence + 15 + (uniformed * 2) + length(territories))
		if(new_influence != influence)
			message += "Gang influence has increased by [new_influence - influence] for defending [length(territories)] territories and [uniformed] uniformed gangsters.<br>"
		influence = new_influence
		message += "Your gang now has <b>[influence] influence</b>.<br>"
	message_gangtools(message)

/// How many distinct station areas can be claimed at all
/datum/team/gang/proc/total_claimable_territories()
	var/list/valid = list()
	for(var/area/station_area as anything in GLOB.areas)
		if(!(station_area.area_flags & VALID_TERRITORY))
			continue
		if(!station_area.z || !is_station_level(station_area.z))
			continue
		valid[station_area.type] = TRUE
	return max(1, length(valid))

/datum/team/gang/proc/station_control_percent()
	return round((length(territories) / total_claimable_territories()) * 100, 1)

/// Counts living gangsters on station wearing gang colours
/datum/team/gang/proc/check_clothing()
	var/uniformed = 0
	for(var/datum/mind/gang_mind as anything in members)
		var/mob/living/carbon/human/gangster = gang_mind.current
		if(!ishuman(gangster) || gangster.stat == DEAD || !is_station_level(gangster.z))
			continue
		var/obj/item/clothing/gang_outfit
		if(gangster.w_uniform && (gangster.w_uniform.type in inner_outfits))
			gang_outfit = gangster.w_uniform
		if(gangster.wear_suit && (gangster.wear_suit.type in outer_outfits))
			gang_outfit = gangster.wear_suit
		if(gang_outfit)
			to_chat(gangster, span_notice("The [src] Gang's influence grows as you wear [gang_outfit]."))
			uniformed++
	return uniformed

/// How many tags this gangster has personally sprayed that still stand
/datum/team/gang/proc/get_soldier_territories(datum/mind/soldier)
	return length(tags_by_mind[soldier])

/datum/team/gang/proc/adjust_influence(value)
	influence = max(0, influence + value)

/// Sends a message to everyone holding one of this gang's gangtools
/datum/team/gang/proc/message_gangtools(message)
	if(!message)
		return
	for(var/obj/item/gangtool/tool as anything in gangtools)
		var/mob/living/holder = tool.get_holder()
		if(!holder?.mind || holder.stat != CONSCIOUS)
			continue
		var/datum/antagonist/gang/gangster = holder.mind.has_antag_datum(/datum/antagonist/gang)
		if(gangster?.gang != src)
			continue
		to_chat(holder, span_warning("[icon2html(tool, holder)] [message]"))
		playsound(holder, 'sound/machines/beep/twobeep.ogg', 50, TRUE)

/// Starts a takeover
/datum/team/gang/proc/start_domination()
	domination_time = world.time + determine_domination_time() SECONDS
	SSsecurity_level.set_level(SEC_LEVEL_DELTA)

/// Initial takeover length in seconds; more territory means a faster takeover
/datum/team/gang/proc/determine_domination_time()
	return max(180, 480 - (station_control_percent() * 9))

/datum/team/gang/proc/domination_time_remaining()
	return round((domination_time - world.time) * 0.1)

// ---- The gangs ----
// Hippie's gang list, with outfits mapped to Surf's current clothing paths.

/datum/team/gang/clandestine
	name = "Clandestine"
	color = "#FF0000"
	inner_outfits = list(/obj/item/clothing/under/syndicate/combat)
	outer_outfits = list(/obj/item/clothing/suit/jacket)

/datum/team/gang/prima
	name = "Prima"
	color = "#FFFF00"
	inner_outfits = list(/obj/item/clothing/under/color/yellow)
	outer_outfits = list(/obj/item/clothing/suit/costume/hastur)

/datum/team/gang/zerog
	name = "Zero-G"
	color = "#C0C0C0"
	inner_outfits = list(/obj/item/clothing/under/suit/white)
	outer_outfits = list(/obj/item/clothing/suit/hooded/wintercoat)

/datum/team/gang/max
	name = "Max"
	color = "#800000"
	inner_outfits = list(/obj/item/clothing/under/color/maroon)
	outer_outfits = list(/obj/item/clothing/suit/costume/poncho/red)

/datum/team/gang/blasto
	name = "Blasto"
	color = "#000080"
	inner_outfits = list(/obj/item/clothing/under/suit/navy)
	outer_outfits = list(/obj/item/clothing/suit/jacket/miljacket)

/datum/team/gang/waffle
	name = "Waffle"
	color = "#808000"
	inner_outfits = list(/obj/item/clothing/under/suit/green)
	outer_outfits = list(/obj/item/clothing/suit/costume/poncho)

/datum/team/gang/north
	name = "North"
	color = "#00FF00"
	inner_outfits = list(/obj/item/clothing/under/color/green)
	outer_outfits = list(/obj/item/clothing/suit/costume/poncho/green)

/datum/team/gang/omni
	name = "Omni"
	color = "#008080"
	inner_outfits = list(/obj/item/clothing/under/color/teal)
	outer_outfits = list(/obj/item/clothing/suit/chaplainsuit/armor/studentuni)

/datum/team/gang/newton
	name = "Newton"
	color = "#A52A2A"
	inner_outfits = list(/obj/item/clothing/under/color/brown)
	outer_outfits = list(/obj/item/clothing/suit/toggle/owlwings)

/datum/team/gang/cyber
	name = "Cyber"
	color = "#808000"
	inner_outfits = list(/obj/item/clothing/under/color/lightbrown)
	outer_outfits = list(/obj/item/clothing/suit/costume/nemes)

/datum/team/gang/donk
	name = "Donk"
	color = "#0000FF"
	inner_outfits = list(/obj/item/clothing/under/color/darkblue)
	outer_outfits = list(/obj/item/clothing/suit/apron/overalls)

/datum/team/gang/gene
	name = "Gene"
	color = "#00FFFF"
	inner_outfits = list(/obj/item/clothing/under/color/blue)
	outer_outfits = list(/obj/item/clothing/suit/apron)

/datum/team/gang/gib
	name = "Gib"
	color = "#000000"
	inner_outfits = list(/obj/item/clothing/under/color/black)
	outer_outfits = list(/obj/item/clothing/suit/jacket/leather/biker)

/datum/team/gang/tunnel
	name = "Tunnel"
	color = "#FF00FF"
	inner_outfits = list(/obj/item/clothing/under/color/rainbow)
	outer_outfits = list(/obj/item/clothing/suit/costume/poncho/ponchoshame)

/datum/team/gang/diablo
	name = "Diablo"
	color = "#FF0000"
	inner_outfits = list(/obj/item/clothing/under/color/red)
	outer_outfits = list(/obj/item/clothing/suit/jacket/leather)

/datum/team/gang/psyke
	name = "Psyke"
	color = "#808080"
	inner_outfits = list(/obj/item/clothing/under/color/grey)
	outer_outfits = list(/obj/item/clothing/suit/toggle/owlwings/griffinwings)

/datum/team/gang/osiron
	name = "Osiron"
	color = "#FFFFFF"
	inner_outfits = list(/obj/item/clothing/under/color/white)
	outer_outfits = list(/obj/item/clothing/suit/toggle/labcoat)

/datum/team/gang/sirius
	name = "Sirius"
	color = "#FFC0CB"
	inner_outfits = list(/obj/item/clothing/under/color/pink)

/datum/team/gang/sleepingcarp
	name = "Sleeping Carp"
	color = "#800080"
	inner_outfits = list(/obj/item/clothing/under/color/lightpurple)
	outer_outfits = list(/obj/item/clothing/suit/hooded/carp_costume)

/datum/team/gang/h
	name = "H"
	color = "#993333"
	inner_outfits = list(/obj/item/clothing/under/misc/psyche)
	outer_outfits = list(/obj/item/clothing/suit/chaplainsuit/whiterobe)

/datum/team/gang/rigatonifamily
	name = "Rigatoni family"
	color = "#CC9900"
	inner_outfits = list(/obj/item/clothing/under/costume/buttondown/slacks/service)
	outer_outfits = list(/obj/item/clothing/suit/apron/chef)

/datum/team/gang/weed
	name = "Weed"
	color = "#66FF33"
	inner_outfits = list(/obj/item/clothing/under/color/darkgreen)
	outer_outfits = list(/obj/item/clothing/suit/hooded/wintercoat/hydro)

#undef GANG_INFLUENCE_INTERVAL
#undef GANG_MAXIMUM_RECALLS
