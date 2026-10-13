// Gang antagonist datums: gangster, boss and lieutenant.

/datum/antagonist/gang
	name = "\improper Gangster"
	roundend_category = "gangsters"
	antagpanel_category = "Gang"
	job_rank = ROLE_GANG
	can_coexist_with_others = FALSE
	hud_icon = 'surfshack13/icons/hippie/gang_hud.dmi'
	antag_hud_name = "gangster"
	preview_outfit = /datum/outfit/gangster_preview
	/// Shown in gang messages
	var/message_name = "Gangster"
	/// Our gang
	var/datum/team/gang/gang
	/// Gangmageddon: the gangtool every gangster gets as an action button
	var/obj/item/gangtool/personal/personal_tool

/datum/antagonist/gang/can_be_owned(datum/mind/new_owner)
	. = ..()
	if(. && HAS_MIND_TRAIT(new_owner.current, TRAIT_UNCONVERTABLE))
		return FALSE

/datum/antagonist/gang/apply_innate_effects(mob/living/mob_override)
	var/mob/living/target = mob_override || owner.current
	add_team_hud(target, /datum/antagonist/gang)
	handle_clown_mutation(target, mob_override ? null : "Your training has allowed you to overcome your clownish nature, allowing you to wield weapons without harming yourself.")
	RegisterSignal(target, SIGNAL_ADDTRAIT(TRAIT_MINDSHIELD), PROC_REF(on_mindshielded))

/datum/antagonist/gang/remove_innate_effects(mob/living/mob_override)
	var/mob/living/target = mob_override || owner.current
	handle_clown_mutation(target, removing = FALSE)
	UnregisterSignal(target, SIGNAL_ADDTRAIT(TRAIT_MINDSHIELD))

// Tint the [G] icon with the gang's colour.
/datum/antagonist/gang/hud_image_on(mob/hud_loc)
	var/image/hud = ..()
	hud.color = gang?.color
	return hud

/datum/antagonist/gang/get_team()
	return gang

/datum/antagonist/gang/create_team(datum/team/gang/new_team)
	if(gang)
		return
	if(istype(new_team))
		gang = new_team
		return
	var/gang_type = pick(GLOB.possible_gangs)
	if(gang_type)
		gang = new gang_type()

/datum/antagonist/gang/on_gain()
	if(!gang)
		create_team()
	gang.add_member(owner)
	owner.current.log_message("has been converted to the [gang.name] gang!", LOG_ATTACK, color = "red")
	. = ..()
	owner.remove_antag_datum(/datum/antagonist/vigilante)
	if(GLOB.gangmageddon_active)
		personal_tool = new(null, owner, gang)

/datum/antagonist/gang/on_removal()
	QDEL_NULL(personal_tool)
	// Deconverted crew go back to hunting gangs. Promotions and demotions are silent and re-add a gang datum.
	if(GLOB.gangmageddon_active && !silent)
		addtimer(CALLBACK(owner, TYPE_PROC_REF(/datum/mind, add_antag_datum), /datum/antagonist/vigilante), 1)
	if(gang)
		gang.remove_member(owner)
		owner.current?.log_message("has been deconverted from the [gang.name] gang!", LOG_ATTACK, color = "red")
	return ..()

/datum/antagonist/gang/greet()
	. = ..()
	gang.greet_gangster(owner)

/datum/antagonist/gang/farewell()
	if(ishuman(owner.current))
		owner.current.visible_message(span_deconversion_message("[owner.current] looks like [owner.current.p_theyve()] just remembered [owner.current.p_their()] real allegiance!"), ignored_mobs = list(owner.current))
		to_chat(owner.current, span_userdanger("You are no longer a gangster!"))

/// Mindshields break a gangster's loyalty, but not a leader's.
/datum/antagonist/gang/proc/on_mindshielded(datum/source)
	SIGNAL_HANDLER
	if(istype(src, /datum/antagonist/gang/boss))
		return
	owner.remove_antag_datum(/datum/antagonist/gang)

/// Bumps a gangster up to lieutenant.
/datum/antagonist/gang/proc/promote()
	var/datum/team/gang/old_gang = gang
	var/datum/mind/old_owner = owner
	silent = TRUE
	old_owner.remove_antag_datum(/datum/antagonist/gang)
	var/datum/antagonist/gang/boss/lieutenant/new_boss = new
	new_boss.silent = TRUE
	old_owner.add_antag_datum(new_boss, old_gang)
	new_boss.silent = FALSE
	log_game("[key_name(old_owner)] has been promoted to Lieutenant in the [old_gang.name] Gang")
	to_chat(old_owner.current, "<font size=3 color=red><b>You have been promoted to Lieutenant!</b></font>")

/datum/antagonist/gang/get_admin_commands()
	. = ..()
	.["Promote"] = CALLBACK(src, PROC_REF(admin_promote))
	.["Set Influence"] = CALLBACK(src, PROC_REF(admin_adjust_influence))
	if(gang && gang.domination_time != GANG_NOT_DOMINATING)
		.["Set domination time left"] = CALLBACK(src, PROC_REF(admin_set_dom_time))

/datum/antagonist/gang/admin_add(datum/mind/new_owner, mob/admin)
	var/choice = tgui_alert(admin, "Which gang should [new_owner] join?", "Gangs", list("New", "Existing"))
	if(!choice)
		return
	if(choice == "New")
		var/list/options = GLOB.possible_gangs.Copy()
		if(!length(options))
			to_chat(admin, span_danger("Every gang type is already in use."))
			return
		var/new_gang = tgui_input_list(admin, "Select a gang, or cancel for a random one.", "New gang", options)
		new_gang ||= pick(options)
		gang = new new_gang()
	else
		if(!length(GLOB.gangs))
			to_chat(admin, span_danger("No gangs exist, please create a new one instead."))
			return
		gang = tgui_input_list(admin, "Select a gang.", "Existing gang", GLOB.gangs)
		if(!gang)
			return
	new_owner.add_antag_datum(src, gang)
	message_admins("[key_name_admin(admin)] has made [key_name_admin(new_owner)] a [name] of the [gang.name] gang.")
	log_admin("[key_name(admin)] has made [key_name(new_owner)] a [name] of the [gang.name] gang.")

/datum/antagonist/gang/proc/admin_promote(mob/admin)
	message_admins("[key_name_admin(admin)] has promoted [owner] to gang lieutenant.")
	log_admin("[key_name(admin)] has promoted [owner] to gang lieutenant.")
	promote()

/datum/antagonist/gang/proc/admin_adjust_influence(mob/admin)
	var/new_influence = tgui_input_number(admin, "Influence for [gang.name]", "Gang influence", gang.influence, 999, 0)
	if(isnull(new_influence))
		return
	gang.influence = new_influence
	message_admins("[key_name_admin(admin)] changed [gang.name]'s influence to [new_influence].")
	log_admin("[key_name(admin)] changed [gang.name]'s influence to [new_influence].")

/datum/antagonist/gang/proc/admin_set_dom_time(mob/admin)
	if(gang.domination_time == GANG_NOT_DOMINATING)
		return
	var/seconds = tgui_input_number(admin, "Set the time left for the gang to win, in seconds", "Domination time left", gang.domination_time_remaining(), 3600, 1)
	if(!seconds)
		return
	gang.domination_time = world.time + seconds SECONDS
	gang.message_gangtools("Takeover shortened to [gang.domination_time_remaining()] seconds by your Syndicate benefactors.")

// Bosses can use gangtools to buy items, including the dominator, and recruit with pens.
/datum/antagonist/gang/boss
	name = "\improper Gang Boss"
	antag_hud_name = "gang_boss"
	message_name = "Leader"

/datum/antagonist/gang/boss/on_gain()
	. = ..()
	gang.leaders |= owner

/datum/antagonist/gang/boss/on_removal()
	gang?.leaders -= owner
	return ..()

/datum/antagonist/gang/boss/antag_listing_name()
	return ..() + " (Boss)"

/datum/antagonist/gang/boss/admin_add(datum/mind/new_owner, mob/admin)
	. = ..()
	if(new_owner.has_antag_datum(/datum/antagonist/gang/boss))
		equip_gang()

/datum/antagonist/gang/boss/get_admin_commands()
	. = ..()
	. -= "Promote"
	.["Give gangtool"] = CALLBACK(src, PROC_REF(admin_give_gangtool))
	.["Take gangtool"] = CALLBACK(src, PROC_REF(admin_take_gangtool))
	.["Demote"] = CALLBACK(src, PROC_REF(admin_demote))

/// Gives a starting boss their gangtool, recruitment pen, territory spraycan and chameleon security HUD.
/datum/antagonist/gang/boss/proc/equip_gang(give_gangtool = TRUE, give_pen = TRUE, give_spraycan = TRUE, give_hud = TRUE)
	var/mob/living/carbon/human/boss = owner.current
	if(!istype(boss))
		return
	var/list/slots = list(
		"backpack" = ITEM_SLOT_BACKPACK,
		"left pocket" = ITEM_SLOT_LPOCKET,
		"right pocket" = ITEM_SLOT_RPOCKET,
		"hands" = ITEM_SLOT_HANDS,
	)
	if(give_gangtool)
		var/obj/item/gangtool/tool = new(boss)
		var/where = boss.equip_in_one_of_slots(tool, slots, indirect_action = TRUE)
		if(!where)
			to_chat(boss, "Your Syndicate benefactors were unfortunately unable to get you a Gangtool.")
		else
			tool.register_device(boss)
			to_chat(boss, "The <b>Gangtool</b> in your [where] will allow you to purchase weapons and equipment, send messages to your gang, and recall the emergency shuttle from anywhere on the station.")
			to_chat(boss, "As the gang boss, you can also promote your gang members to <b>lieutenant</b>. Unlike regular gangsters, Lieutenants cannot be deconverted and are able to use recruitment pens and gangtools.")
	if(give_pen)
		var/obj/item/pen/gang/pen = new(boss)
		var/where = boss.equip_in_one_of_slots(pen, slots, indirect_action = TRUE)
		if(where)
			to_chat(boss, "The <b>recruitment pen</b> in your [where] will help you get your gang started. Stab unsuspecting crew members with it to recruit them.")
	if(give_spraycan)
		var/obj/item/toy/crayon/spraycan/gang/can = new(boss, gang)
		var/where = boss.equip_in_one_of_slots(can, slots, indirect_action = TRUE)
		if(where)
			to_chat(boss, "The <b>territory spraycan</b> in your [where] can be used to claim areas of the station for your gang. The more territory your gang controls, the more influence you get. All gangsters can use these, so distribute them to grow your influence faster.")
	if(give_hud)
		var/obj/item/clothing/glasses/hud/security/chameleon/hud = new(boss)
		var/where = boss.equip_in_one_of_slots(hud, slots, indirect_action = TRUE)
		if(where)
			to_chat(boss, "The <b>chameleon security HUD</b> in your [where] will help you keep track of who is mindshield-implanted, and unable to be recruited.")

/datum/antagonist/gang/boss/proc/demote()
	var/datum/team/gang/old_gang = gang
	var/datum/mind/old_owner = owner
	silent = TRUE
	old_owner.remove_antag_datum(/datum/antagonist/gang)
	var/datum/antagonist/gang/new_gangster = new
	new_gangster.silent = TRUE
	old_owner.add_antag_datum(new_gangster, old_gang)
	new_gangster.silent = FALSE
	log_game("[key_name(old_owner)] has been demoted to Gangster in the [old_gang.name] Gang")
	to_chat(old_owner.current, span_userdanger("The gang has been disappointed by your leadership! You are a regular gangster now!"))

/datum/antagonist/gang/boss/proc/admin_give_gangtool(mob/admin)
	equip_gang(TRUE, FALSE, FALSE, FALSE)

/datum/antagonist/gang/boss/proc/admin_take_gangtool(mob/admin)
	var/obj/item/gangtool/tool = locate() in owner.current.get_all_contents()
	if(!tool)
		to_chat(admin, span_danger("Deleting gangtool failed!"))
		return
	qdel(tool)

/datum/antagonist/gang/boss/proc/admin_demote(mob/admin)
	message_admins("[key_name_admin(admin)] has demoted [owner.current] from [name].")
	log_admin("[key_name(admin)] has demoted [owner.current] from [name].")
	admin_take_gangtool(admin)
	demote()

/datum/antagonist/gang/boss/lieutenant
	name = "\improper Gang Lieutenant"
	message_name = "Lieutenant"

/datum/outfit/gangster_preview
	name = "Gangster (Preview only)"
	uniform = /obj/item/clothing/under/syndicate/combat
	suit = /obj/item/clothing/suit/jacket
	mask = /obj/item/clothing/mask/gskull
	shoes = /obj/item/clothing/shoes/gang
	gloves = /obj/item/clothing/gloves/gang
	neck = /obj/item/clothing/neck/necklace/dope
