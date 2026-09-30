// Gangmageddon personal gangtools and vigilantes.
// Every gangster carries a gangtool as an action button with their own points, and every other
// crew member is a vigilante with an uplink that pays for keeping the station clean.

/// Set while a Gangmageddon round is running
GLOBAL_VAR_INIT(gangmageddon_active, FALSE)

/// A gangtool that lives in nullspace, bound to one mind and opened from an action button.
/obj/item/gangtool/personal
	name = "personal gangtool"
	mode_flag = GANG_MODE_GANGMAGEDDON
	/// Whose tool this is
	var/datum/mind/bound_mind
	/// Personal currency
	var/points = 0
	/// The button that opens it
	var/datum/action/gangtool/linked_action
	/// Button type to create
	var/action_type = /datum/action/gangtool

/obj/item/gangtool/personal/Initialize(mapload, datum/mind/owner_mind, datum/team/gang/new_gang)
	. = ..()
	if(!owner_mind?.current)
		return INITIALIZE_HINT_QDEL
	bound_mind = owner_mind
	if(new_gang)
		gang = new_gang
		gang.gangtools += src
	linked_action = new action_type(src)
	linked_action.Grant(bound_mind.current)
	RegisterSignal(bound_mind, COMSIG_MIND_TRANSFERRED, PROC_REF(on_mind_transferred))

/obj/item/gangtool/personal/Destroy()
	QDEL_NULL(linked_action)
	if(bound_mind)
		UnregisterSignal(bound_mind, COMSIG_MIND_TRANSFERRED)
	bound_mind = null
	return ..()

/obj/item/gangtool/personal/proc/on_mind_transferred(datum/mind/source, mob/old_current)
	SIGNAL_HANDLER
	if(old_current)
		linked_action.Remove(old_current)
	if(bound_mind.current)
		linked_action.Grant(bound_mind.current)

/obj/item/gangtool/personal/get_points()
	return points

/obj/item/gangtool/personal/spend_points(amount)
	points = max(0, points - amount)

/obj/item/gangtool/personal/get_holder()
	return bound_mind?.current

/obj/item/gangtool/personal/can_use(mob/living/carbon/human/user, silent = FALSE)
	if(!istype(user) || user.incapacitated || user.mind != bound_mind)
		return FALSE
	var/datum/antagonist/gang/member = user.mind.has_antag_datum(/datum/antagonist/gang)
	return member && member.gang == gang

/obj/item/gangtool/personal/ui_data(mob/user)
	var/list/data = ..()
	data["personal"] = TRUE
	return data

/// Pays out Gangmageddon territory income. Called from the gang's status report.
/obj/item/gangtool/personal/proc/pay_income()
	var/mob/living/holder = get_holder()
	if(!holder || !gang)
		return
	var/income
	if(bound_mind.has_antag_datum(/datum/antagonist/gang/boss))
		income = round(max(0, 5 - points / 10) + length(gang.territories) * 0.6)
		to_chat(holder, span_notice("Your influence has increased by [income] from your gang holding [length(gang.territories)] territories!"))
	else
		var/own_tags = gang.get_soldier_territories(bound_mind)
		income = round(max(0, 3 - points / 10) + own_tags * 0.5 + length(gang.territories) * 0.3)
		if(income)
			to_chat(holder, span_notice("You have gained [income] influence from [own_tags] territories you have personally tagged."))
		else
			to_chat(holder, span_warning("You have not gained any influence from territories you personally tagged. Get to work!"))
	points += income

/datum/action/gangtool
	name = "Personal Gang Tool"
	desc = "An implanted gang tool that lets you purchase gear."
	background_icon_state = "bg_demon"
	overlay_icon_state = "bg_demon_border"
	button_icon = 'surfshack13/icons/hippie/gang_items.dmi'
	button_icon_state = "gangtool"
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/gangtool/Trigger(trigger_flags)
	. = ..()
	if(!.)
		return
	var/obj/item/gangtool/personal/tool = target
	if(istype(tool) && tool.can_use(owner))
		tool.show_menu(owner)

// ---- Vigilantes ----

/datum/antagonist/vigilante
	name = "\improper Vigilante"
	roundend_category = "vigilantes"
	antagpanel_category = "Gang"
	job_rank = ROLE_GANG
	show_in_antagpanel = TRUE
	/// Shared team, mostly for the round-end report
	var/datum/team/vigilante/posse
	/// Their uplink
	var/obj/item/gangtool/personal/vigilante/uplink

/datum/antagonist/vigilante/can_be_owned(datum/mind/new_owner)
	. = ..()
	if(. && new_owner.has_antag_datum(/datum/antagonist/gang))
		return FALSE

/datum/antagonist/vigilante/create_team(datum/team/vigilante/new_team)
	if(istype(new_team))
		posse = new_team
		return
	for(var/datum/antagonist/vigilante/other in GLOB.antagonists)
		if(other.posse)
			posse = other.posse
			return
	posse = new()
	var/datum/objective/escape/escape = new
	escape.team = posse
	posse.objectives += escape

/datum/antagonist/vigilante/get_team()
	return posse

/datum/antagonist/vigilante/on_gain()
	objectives |= posse.objectives
	. = ..()
	uplink = new(null, owner)
	var/mob/living/carbon/human/crew = owner.current
	if(istype(crew))
		var/obj/item/soap/nanotrasen/soap = new(crew.drop_location())
		crew.put_in_hands(soap)

/datum/antagonist/vigilante/on_removal()
	QDEL_NULL(uplink)
	return ..()

/datum/antagonist/vigilante/greet()
	. = ..()
	to_chat(owner.current, "<font size=3><u><b>You are a Vigilante!</b></u></font>")
	to_chat(owner.current, "Nanotrasen has given all loyal crew the authority to eliminate gang activity aboard the station.")
	to_chat(owner.current, "Your implanted <b>Vigilante Uplink</b> rewards influence for destroying gangster equipment and for keeping the station free of gang tags.")
	to_chat(owner.current, span_bold("Prevent gangs from taking over the station! Use lethal force against gangsters <i>if they cannot be converted back to Nanotrasen</i>, but do not kill loyal crewmembers!"))
	owner.announce_objectives()

/datum/antagonist/vigilante/farewell()
	to_chat(owner.current, "<font size=3><u><b>You are no longer a Vigilante!</b></u></font>")

/datum/team/vigilante
	name = "Vigilantes"
	member_name = "vigilante"

/// The vigilante uplink: earns steady influence, and pays out for destroying gang gear.
/obj/item/gangtool/personal/vigilante
	name = "vigilante uplink"
	mode_flag = GANG_MODE_VIGILANTE
	action_type = /datum/action/gangtool/vigilante

/obj/item/gangtool/personal/vigilante/Initialize(mapload, datum/mind/owner_mind, datum/team/gang/new_gang)
	. = ..()
	if(. == INITIALIZE_HINT_QDEL)
		return
	addtimer(CALLBACK(src, PROC_REF(earnings)), 2.5 MINUTES, TIMER_LOOP | TIMER_DELETE_ME)

/obj/item/gangtool/personal/vigilante/can_use(mob/living/carbon/human/user, silent = FALSE)
	if(!istype(user) || user.incapacitated || user.mind != bound_mind)
		return FALSE
	return !user.mind.has_antag_datum(/datum/antagonist/gang)

/obj/item/gangtool/personal/vigilante/pay_income()
	return

/// Steady pay for loyal crew, a bonus for mindshields and for how much of the station is tag-free.
/obj/item/gangtool/personal/vigilante/proc/earnings()
	var/mob/living/carbon/human/holder = get_holder()
	if(!istype(holder) || holder.stat == DEAD)
		return
	var/claimed = 0
	var/total = 1
	for(var/datum/team/gang/gang as anything in GLOB.gangs)
		claimed += length(gang.territories)
		total = gang.total_claimable_territories()
	var/clean_bonus = round(max(0, 1 - claimed / total) * 3, 0.5)
	points += 3 + clean_bonus
	to_chat(holder, span_notice("You have received 3 influence for your continued loyalty, [clean_bonus] for keeping the station tag-free."))
	if(HAS_TRAIT(holder, TRAIT_MINDSHIELD))
		points += 3
		to_chat(holder, span_notice("You have also received 3 influence for possessing a mindshield implant."))

/obj/item/gangtool/personal/vigilante/ui_data(mob/user)
	var/list/data = list()
	data["vigilante"] = TRUE
	data["title"] = "Vigilante's Companion v1.2"
	data["registered"] = TRUE
	data["points"] = points
	data["currency"] = currency_name
	var/obj/item/held = user.get_active_held_item()
	data["held_item"] = held?.name
	data["held_value"] = held ? contraband_value(held) : 0
	data["categories"] = shop_data(user)
	return data

/obj/item/gangtool/personal/vigilante/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	var/mob/user = usr
	if(!can_use(user))
		return
	switch(action)
		if("buy")
			var/list/category = buyable_items[params["category"]]
			var/datum/gang_item/item = category?[params["id"]]
			if(item?.can_buy(user, null, src))
				INVOKE_ASYNC(item, TYPE_PROC_REF(/datum/gang_item, purchase), user, null, src)
			return TRUE
		if("destroy")
			INVOKE_ASYNC(src, PROC_REF(destroy_contraband), user)
			return TRUE

/// Gang gear a vigilante can hand in, and what it pays
/obj/item/gangtool/personal/vigilante/proc/contraband_value(obj/item/thing)
	var/static/list/values = list(
		/obj/item/gangtool = 20,
		/obj/item/pen/gang = 17,
		/obj/item/implanter/gang = 12,
		/obj/item/gun/ballistic/automatic/mini_uzi = 30,
		/obj/item/gun/ballistic/automatic/pistol = 20,
		/obj/item/gun/ballistic/shotgun/doublebarrel = 20,
		/obj/item/gun/ballistic/automatic/surplus = 8,
		/obj/item/gun/ballistic/rocketlauncher = 30,
		/obj/item/grenade/frag = 13,
		/obj/item/grenade/c4 = 5,
		/obj/item/reagent_containers/hypospray/medipen/stimulants = 10,
		/obj/item/reviver = 10,
		/obj/item/clothing/shoes/combat/gang = 9,
		/obj/item/clothing/shoes/gang = 14,
		/obj/item/clothing/mask/gskull = 11,
		/obj/item/clothing/head/collectable/petehat/gang = 10,
		/obj/item/storage/belt/military/gang = 8,
		/obj/item/clothing/gloves/gang = 8,
		/obj/item/clothing/neck/necklace/dope = 6,
		/obj/item/clothing/glasses/hud/security/chameleon = 5,
		/obj/item/switchblade = 5,
		/obj/item/throwing_star = 3,
	)
	if(istype(thing, /obj/item/toy/crayon/spraycan/gang))
		var/obj/item/toy/crayon/spraycan/gang/can = thing
		return 1 + round(can.charges / 9)
	for(var/contraband_type in values)
		if(istype(thing, contraband_type))
			return values[contraband_type]
	// Armored gang outerwear bought from a gangtool
	if(istype(thing, /obj/item/clothing) && thing.get_armor_rating(BULLET) >= 35)
		for(var/datum/team/gang/gang as anything in GLOB.gangs)
			if(thing.type in gang.outer_outfits)
				return 5
	return 0

/obj/item/gangtool/personal/vigilante/proc/destroy_contraband(mob/living/user)
	var/obj/item/held = user.get_active_held_item()
	if(QDELETED(held))
		to_chat(user, span_notice("No item detected."))
		return
	var/value = contraband_value(held)
	if(!value)
		to_chat(user, span_notice("No contraband detected!"))
		return
	playsound(user, 'sound/items/poster/poster_being_created.ogg', 75, TRUE)
	if(!do_after(user, 2 SECONDS, held) || user.get_active_held_item() != held)
		return
	points += value
	to_chat(user, span_notice("[held] has been processed for [value] influence."))
	log_game("[key_name(user)] destroyed [held] as gang contraband for [value] vigilante influence.")
	qdel(held)

/datum/action/gangtool/vigilante
	name = "Vigilante Uplink"
	desc = "An implanted vigilante uplink."
	background_icon_state = "bg_default"
	overlay_icon_state = "bg_default_border"
