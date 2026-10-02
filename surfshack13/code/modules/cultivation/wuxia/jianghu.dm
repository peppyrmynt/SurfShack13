/**
 * The jianghu: the martial world. Face (reputation), honor duels, sects, rivalries and hidden weapons.
 * Face is tracked per mind so it survives body swaps, and shows on examine.
 */

// ===================== Face =====================

/// mind -> face
GLOBAL_LIST_EMPTY(jianghu_face)

/// mind -> world.time their disgrace wears off
GLOBAL_LIST_EMPTY(jianghu_dishonor)

/proc/jianghu_is_dishonored(mob/living/target)
	return target?.mind && GLOB.jianghu_dishonor[target.mind] > world.time

/proc/jianghu_face_of(datum/mind/mind)
	return mind ? (GLOB.jianghu_face[mind] || 0) : 0

/proc/jianghu_face_title(face)
	if(face <= -10)
		return "Disgraced"
	if(face < 0)
		return "Shamed"
	if(face >= 30)
		return "Martial Legend"
	if(face >= 15)
		return "Renowned Hero"
	if(face >= 5)
		return "Rising Talent"
	return null

/proc/jianghu_adjust_face(mob/living/target, amount, reason)
	if(!target?.mind || !amount)
		return
	GLOB.jianghu_face[target.mind] = jianghu_face_of(target.mind) + amount
	target.AddElement(/datum/element/jianghu_examine)
	if(amount > 0)
		to_chat(target, span_nicegreen("<b>You gain face!</b> ([reason]) Face: [jianghu_face_of(target.mind)]"))
	else
		to_chat(target, span_warning("<b>You lose face!</b> ([reason]) Face: [jianghu_face_of(target.mind)]"))

/// Shows face, sect rank and dishonour on examine
/datum/element/jianghu_examine

/datum/element/jianghu_examine/Attach(datum/target)
	. = ..()
	if(!ismob(target))
		return ELEMENT_INCOMPATIBLE
	RegisterSignal(target, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))

/datum/element/jianghu_examine/Detach(datum/source, ...)
	UnregisterSignal(source, COMSIG_ATOM_EXAMINE)
	return ..()

/datum/element/jianghu_examine/proc/on_examine(mob/living/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	var/datum/mind/mind = source.mind
	if(!mind)
		return
	var/title = jianghu_face_title(jianghu_face_of(mind))
	if(title)
		examine_list += span_notice("In the jianghu, [source.p_they()] [source.p_are()] known as a <b>[title]</b>.")
	var/datum/jianghu_sect/sect = jianghu_sect_of(mind)
	if(sect)
		var/datum/jianghu_sect/viewer_sect = jianghu_sect_of(user.mind)
		var/relation = ""
		if(viewer_sect == sect)
			relation = " A fellow member of your sect."
		else if(viewer_sect && (sect in viewer_sect.rivals))
			relation = span_warning(" A member of your RIVAL sect!")
		examine_list += span_notice("[source.p_They()] [source.p_are()] [sect.rank_of(mind)] of the <b>[sect.name]</b>.[relation]")
	if(jianghu_is_dishonored(source))
		examine_list += span_warning("[source.p_They()] recently interfered in an honor duel. Shameful.")

// ===================== Honor duels =====================

/datum/action/cooldown/jianghu_duel
	name = "Challenge to Duel"
	desc = "Formally challenge someone nearby to an honor duel. The winner gains face, the loser loses it, \
		anyone watching learns from it, and anyone who interferes is disgraced. Lasts until someone is beaten, yields, flees, or 3 minutes pass."
	button_icon = 'surfshack13/icons/cultivation/cultivation_actions.dmi'
	button_icon_state = "duel"
	background_icon_state = "bg_heretic"
	overlay_icon_state = "bg_heretic_border"
	check_flags = AB_CHECK_CONSCIOUS|AB_CHECK_INCAPACITATED
	click_to_activate = TRUE
	cooldown_time = 30 SECONDS
	unset_after_click = TRUE

/datum/action/cooldown/jianghu_duel/Activate(atom/target)
	var/mob/living/challenger = owner
	if(!ishuman(target) || target == challenger)
		challenger.balloon_alert(challenger, "challenge a person!")
		return FALSE
	var/mob/living/carbon/human/opponent = target
	if(get_dist(challenger, opponent) > 4 || opponent.stat != CONSCIOUS || !opponent.client)
		challenger.balloon_alert(challenger, "they can't answer!")
		return FALSE
	if(GLOB.jianghu_duels[challenger] || GLOB.jianghu_duels[opponent])
		challenger.balloon_alert(challenger, "already in a duel!")
		return FALSE
	StartCooldown()
	INVOKE_ASYNC(src, PROC_REF(ask), challenger, opponent)
	return TRUE

/datum/action/cooldown/jianghu_duel/proc/ask(mob/living/challenger, mob/living/carbon/human/opponent)
	challenger.visible_message(span_boldnotice("[challenger] bows to [opponent] and challenges [opponent.p_them()] to an honor duel!"))
	challenger.say("I challenge you to an honor duel!", forced = "honor duel")
	var/answer = tgui_alert(opponent, "[challenger] challenges you to an honor duel! Winner gains face, loser loses it. Accept?", "Honor Duel", list("Accept", "Refuse"), 20 SECONDS)
	if(QDELETED(challenger) || QDELETED(opponent))
		return
	if(answer != "Accept")
		opponent.visible_message(span_notice("[opponent] refuses [challenger]'s challenge."))
		return
	if(GLOB.jianghu_duels[challenger] || GLOB.jianghu_duels[opponent] || get_dist(challenger, opponent) > 6)
		return
	new /datum/jianghu_duel(challenger, opponent)

/// mob -> duel
GLOBAL_LIST_EMPTY(jianghu_duels)

/datum/jianghu_duel
	var/mob/living/fighter_one
	var/mob/living/fighter_two
	var/started_at
	var/max_duration = 3 MINUTES
	var/list/datum/action/cooldown/jianghu_yield/yield_actions = list()
	var/ended = FALSE

/datum/jianghu_duel/New(mob/living/one, mob/living/two)
	fighter_one = one
	fighter_two = two
	started_at = world.time
	for(var/mob/living/fighter as anything in list(one, two))
		GLOB.jianghu_duels[fighter] = src
		fighter.add_filter("honor_duel", 3, list("type" = "outline", "color" = "#e03030", "size" = 1))
		if(!HAS_TRAIT(fighter, TRAIT_RELAYING_ATTACKER))
			fighter.AddElement(/datum/element/relay_attackers)
		RegisterSignal(fighter, COMSIG_ATOM_WAS_ATTACKED, PROC_REF(on_attacked))
		RegisterSignal(fighter, COMSIG_QDELETING, PROC_REF(on_fighter_deleted))
		var/datum/action/cooldown/jianghu_yield/yield = new(src)
		yield.Grant(fighter)
		yield_actions += yield
	playsound(one, 'sound/effects/gong.ogg', 60, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/blood(get_turf(one))
	new /obj/effect/temp_visual/circle_wave/cultivation/blood(get_turf(two))
	for(var/mob/viewer in viewers(7, one))
		to_chat(viewer, span_boldwarning("<font color='#e03030'>[one] and [two] bow to each other. An honor duel begins!</font>"))
	START_PROCESSING(SSprocessing, src)

/datum/jianghu_duel/Destroy(force)
	STOP_PROCESSING(SSprocessing, src)
	for(var/mob/living/fighter as anything in list(fighter_one, fighter_two))
		if(!fighter)
			continue
		GLOB.jianghu_duels -= fighter
		fighter.remove_filter("honor_duel")
		UnregisterSignal(fighter, list(COMSIG_ATOM_WAS_ATTACKED, COMSIG_QDELETING))
	QDEL_LIST(yield_actions)
	fighter_one = null
	fighter_two = null
	return ..()

/datum/jianghu_duel/proc/is_beaten(mob/living/fighter)
	return QDELETED(fighter) || fighter.stat != CONSCIOUS || fighter.getStaminaLoss() >= 100 || fighter.health <= fighter.maxHealth * 0.25

/datum/jianghu_duel/process(seconds_per_tick)
	if(ended)
		return PROCESS_KILL
	if(is_beaten(fighter_one))
		finish(fighter_two, fighter_one, "defeated")
		return PROCESS_KILL
	if(is_beaten(fighter_two))
		finish(fighter_one, fighter_two, "defeated")
		return PROCESS_KILL
	if(fighter_one.z != fighter_two.z || get_dist(fighter_one, fighter_two) > 12)
		var/mob/living/fled = get_dist(fighter_one, get_turf(fighter_two)) > 12 ? fighter_one : fighter_two
		finish(fled == fighter_one ? fighter_two : fighter_one, fled, "fled")
		return PROCESS_KILL
	if(world.time - started_at > max_duration)
		finish(null, null, "draw")
		return PROCESS_KILL

/datum/jianghu_duel/proc/yielded(mob/living/quitter)
	if(ended)
		return
	finish(quitter == fighter_one ? fighter_two : fighter_one, quitter, "yielded")

/datum/jianghu_duel/proc/finish(mob/living/winner, mob/living/loser, how)
	if(ended)
		return
	ended = TRUE
	var/turf/center = get_turf(winner || fighter_one)
	if(how == "draw")
		for(var/mob/viewer in viewers(7, center))
			to_chat(viewer, span_boldnotice("The duel between [fighter_one] and [fighter_two] ends in a draw. Both bow with respect."))
		jianghu_adjust_face(fighter_one, 1, "an honorable draw")
		jianghu_adjust_face(fighter_two, 1, "an honorable draw")
	else
		for(var/mob/viewer in viewers(7, center))
			to_chat(viewer, span_boldwarning("<font color='#e03030'>[winner] wins the honor duel! [loser] has [how].</font>"))
		playsound(center, 'sound/effects/gong.ogg', 60, TRUE)
		var/face_gain = 5
		var/datum/jianghu_sect/winner_sect = jianghu_sect_of(winner?.mind)
		var/datum/jianghu_sect/loser_sect = jianghu_sect_of(loser?.mind)
		if(winner_sect && loser_sect && (loser_sect in winner_sect.rivals))
			face_gain += 5
			winner_sect.announce("[winner] has defeated [loser] of our rival, the [loser_sect.name], in an honor duel!")
			loser_sect.announce("[loser] was defeated by [winner] of the [winner_sect.name]. Our sect's face suffers.")
		jianghu_adjust_face(winner, face_gain, "won an honor duel")
		jianghu_adjust_face(loser, how == "fled" ? -5 : -2, how == "fled" ? "fled from a duel" : "lost an honor duel")
		winner?.add_mood_event("honor_duel", /datum/mood_event/duel_won)
		loser?.add_mood_event("honor_duel", /datum/mood_event/duel_lost)
		var/datum/antagonist/cultivator/winner_cultivator = IS_CULTIVATOR(winner)
		winner_cultivator?.gain_insight(10, "duel_win", cooldown = 2 MINUTES)
	// Watching masters fight is educational
	for(var/mob/living/spectator in viewers(7, center))
		if(spectator == fighter_one || spectator == fighter_two || spectator.stat != CONSCIOUS)
			continue
		spectator.add_mood_event("honor_duel_spectator", /datum/mood_event/duel_watched)
		var/datum/antagonist/cultivator/spectator_cultivator = IS_CULTIVATOR(spectator)
		spectator_cultivator?.gain_insight(5, "duel_watch", cooldown = 2 MINUTES)
	qdel(src)

/// Third parties attacking a duelist are disgraced
/datum/jianghu_duel/proc/on_attacked(mob/living/victim, atom/attacker, attack_flags)
	SIGNAL_HANDLER
	if(!isliving(attacker) || attacker == fighter_one || attacker == fighter_two)
		return
	var/mob/living/meddler = attacker
	if(!meddler.mind || jianghu_is_dishonored(meddler))
		return
	GLOB.jianghu_dishonor[meddler.mind] = world.time + 10 MINUTES
	meddler.AddElement(/datum/element/jianghu_examine)
	for(var/mob/viewer in viewers(7, meddler))
		to_chat(viewer, span_boldwarning("[meddler] interferes in an honor duel! Shameful!"))
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(jianghu_adjust_face), meddler, -5, "interfered in an honor duel")

/datum/jianghu_duel/proc/on_fighter_deleted(datum/source)
	SIGNAL_HANDLER
	finish(source == fighter_one ? fighter_two : fighter_one, source, "vanished")

/datum/action/cooldown/jianghu_yield
	name = "Yield"
	desc = "Concede the honor duel. You lose a little face, but keep your teeth."
	button_icon = 'surfshack13/icons/cultivation/cultivation_actions.dmi'
	button_icon_state = "yield"
	background_icon_state = "bg_heretic"
	overlay_icon_state = "bg_heretic_border"
	check_flags = NONE

/datum/action/cooldown/jianghu_yield/Activate(atom/target)
	var/datum/jianghu_duel/duel = src.target
	owner.visible_message(span_notice("[owner] raises a hand and yields."))
	duel.yielded(owner)
	return TRUE

/datum/mood_event/duel_won
	description = "I won an honor duel! My face shines."
	mood_change = 6
	timeout = 10 MINUTES

/datum/mood_event/duel_lost
	description = "I lost face in an honor duel..."
	mood_change = -3
	timeout = 5 MINUTES

/datum/mood_event/duel_watched
	description = "I witnessed a thrilling honor duel."
	mood_change = 2
	timeout = 5 MINUTES

// ===================== Sects =====================

/// mind -> sect
GLOBAL_LIST_EMPTY(jianghu_sect_members)
GLOBAL_LIST_EMPTY(jianghu_sects)

/proc/jianghu_sect_of(datum/mind/mind)
	return mind ? GLOB.jianghu_sect_members[mind] : null

/datum/jianghu_sect
	var/name
	var/datum/mind/master
	/// minds
	var/list/datum/mind/members = list()
	var/list/datum/jianghu_sect/rivals = list()
	var/datum/weakref/plaque_ref

/datum/jianghu_sect/New(name, datum/mind/master)
	src.name = name
	src.master = master
	GLOB.jianghu_sects += src
	add_member(master)

/datum/jianghu_sect/proc/add_member(datum/mind/new_member)
	if(!new_member || (new_member in members))
		return
	var/datum/jianghu_sect/old_sect = jianghu_sect_of(new_member)
	old_sect?.remove_member(new_member)
	members += new_member
	GLOB.jianghu_sect_members[new_member] = src
	var/mob/living/body = new_member.current
	if(body)
		body.AddElement(/datum/element/jianghu_examine)
		var/datum/action/cooldown/sect_transmission/transmission = new(new_member)
		transmission.Grant(body)
	announce("[new_member.name] has joined the sect as [rank_of(new_member)]!")

/datum/jianghu_sect/proc/remove_member(datum/mind/old_member)
	members -= old_member
	GLOB.jianghu_sect_members -= old_member
	for(var/datum/action/cooldown/sect_transmission/transmission in old_member.current?.actions)
		qdel(transmission)

/datum/jianghu_sect/proc/rank_of(datum/mind/member)
	if(member == master)
		return "Sect Master"
	var/realm = member.current ? cultivation_realm_of(member.current) : REALM_MORTAL
	if(realm >= REALM_GOLDEN_CORE)
		return "an Elder"
	if(realm >= REALM_FOUNDATION)
		return "an Inner Disciple"
	return "an Outer Disciple"

/datum/jianghu_sect/proc/announce(message)
	for(var/datum/mind/member as anything in members)
		if(member.current)
			to_chat(member.current, "<span style='color:#c9a227'><b>\[[name]\]</b> [message]</span>")

/datum/jianghu_sect/proc/get_plaque()
	return plaque_ref?.resolve()

/// Insight bonus for cultivating near fellow members
/datum/jianghu_sect/proc/fellowship_bonus(mob/living/cultivator_mob)
	var/count = 0
	for(var/datum/mind/member as anything in members)
		if(member == cultivator_mob.mind || !member.current || member.current.stat == DEAD)
			continue
		if(get_dist(member.current, cultivator_mob) <= 5 && member.current.z == cultivator_mob.z)
			count++
	return min(count * 0.1, 0.3)

/datum/action/cooldown/spell/cultivation/found_sect
	name = "Found Sect"
	desc = "Establish your own sect where you stand. A sect plaque appears; disciples you accept join your sect, members can send telepathic transmissions, \
		cultivate faster together, meditate better near the plaque, and can declare rivalries with other sects."
	cooldown_time = 5 MINUTES
	qi_cost = 50

/datum/action/cooldown/spell/cultivation/found_sect/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	var/datum/jianghu_sect/existing = jianghu_sect_of(owner.mind)
	if(existing?.master == owner.mind)
		to_chat(owner, span_warning("You already lead the [existing.name]."))
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/cultivation/found_sect/cast(mob/living/cast_on)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(found), cast_on)

/datum/action/cooldown/spell/cultivation/found_sect/proc/found(mob/living/founder)
	var/sect_name = tgui_input_text(founder, "Name your sect (e.g. Azure Cloud, Iron Toolbox, Seven Mops)", "Found Sect", max_length = 32)
	sect_name = reject_bad_name(sect_name, allow_numbers = TRUE)
	if(!sect_name)
		reset_spell_cooldown()
		var/datum/antagonist/cultivator/refund = IS_CULTIVATOR(founder)
		refund?.adjust_qi(qi_cost)
		return
	if(!findtext(sect_name, "sect") && !findtext(sect_name, "school") && !findtext(sect_name, "palace") && !findtext(sect_name, "pavilion"))
		sect_name = "[sect_name] Sect"
	var/datum/jianghu_sect/sect = new(sect_name, founder.mind)
	var/obj/structure/sect_plaque/plaque = new(get_turf(founder))
	plaque.set_sect(sect)
	founder.visible_message(span_boldnotice("[founder] hangs a gilded plaque and proclaims the founding of the [sect_name]!"))
	playsound(founder, 'sound/effects/gong.ogg', 70, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(get_turf(founder))
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(founder)
	cultivator?.grant_technique(/datum/action/cooldown/spell/cultivation/declare_rivalry)

/obj/structure/sect_plaque
	name = "sect plaque"
	desc = "A gilded plaque proclaiming the gate of a sect."
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'
	icon_state = "sect_plaque"
	anchored = TRUE
	density = FALSE
	max_integrity = 150
	layer = ABOVE_OBJ_LAYER
	var/datum/jianghu_sect/sect

/obj/structure/sect_plaque/proc/set_sect(datum/jianghu_sect/new_sect)
	sect = new_sect
	sect.plaque_ref = WEAKREF(src)
	name = "plaque of the [sect.name]"

/obj/structure/sect_plaque/examine(mob/user)
	. = ..()
	if(!sect)
		return
	. += span_notice("Sect Master: [sect.master?.name || "none"]. Members: [length(sect.members)].")
	if(length(sect.rivals))
		var/list/rival_names = list()
		for(var/datum/jianghu_sect/rival as anything in sect.rivals)
			rival_names += rival.name
		. += span_warning("Sworn rivals: [english_list(rival_names)].")
	. += span_notice("Members meditating near the plaque cultivate faster. Others can click it to ask to join.")

/obj/structure/sect_plaque/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(. || !sect || !user.mind)
		return
	if(jianghu_sect_of(user.mind) == sect)
		to_chat(user, span_notice("You bow to your sect's plaque."))
		return
	INVOKE_ASYNC(src, PROC_REF(request_join), user)
	return TRUE

/obj/structure/sect_plaque/proc/request_join(mob/living/user)
	var/mob/living/master_body = sect.master?.current
	if(!master_body || master_body.stat != CONSCIOUS || !master_body.client)
		to_chat(user, span_warning("The Sect Master is not available to accept you."))
		return
	to_chat(user, span_notice("You ask to join the [sect.name]..."))
	if(tgui_alert(master_body, "[user.real_name] asks to join the [sect.name]. Accept them?", "Sect Petition", list("Accept", "Refuse"), 30 SECONDS) != "Accept")
		to_chat(user, span_warning("The Sect Master refuses you."))
		return
	sect.add_member(user.mind)

/obj/structure/sect_plaque/atom_destruction(damage_flag)
	sect?.announce("Our sect's plaque has been destroyed! Our face is lost!")
	if(sect)
		for(var/datum/mind/member as anything in sect.members)
			jianghu_adjust_face(member.current, -2, "your sect's plaque was destroyed")
	return ..()

/datum/action/cooldown/sect_transmission
	name = "Sect Transmission"
	desc = "Send a telepathic message to every member of your sect."
	button_icon = 'surfshack13/icons/cultivation/cultivation_actions.dmi'
	button_icon_state = "sect_transmission"
	background_icon_state = "bg_heretic"
	overlay_icon_state = "bg_heretic_border"
	check_flags = AB_CHECK_CONSCIOUS
	cooldown_time = 3 SECONDS

/datum/action/cooldown/sect_transmission/Activate(atom/target)
	var/datum/jianghu_sect/sect = jianghu_sect_of(owner.mind)
	if(!sect)
		qdel(src)
		return FALSE
	var/message = tgui_input_text(owner, "Message to your sect", "Sect Transmission", max_length = MAX_MESSAGE_LEN)
	if(!message || QDELETED(src))
		return FALSE
	owner.log_talk(message, LOG_SAY, tag = "sect transmission ([sect.name])")
	sect.announce("<i>[owner.real_name] ([sect.rank_of(owner.mind)]):</i> [html_encode(message)]")
	for(var/mob/dead/observer/ghost in GLOB.dead_mob_list)
		if(ghost.client?.prefs?.chat_toggles & CHAT_GHOSTEARS)
			to_chat(ghost, "[FOLLOW_LINK(ghost, owner)] <span style='color:#c9a227'><b>\[[sect.name]\]</b> [owner.real_name]: [html_encode(message)]</span>")
	StartCooldown()
	return TRUE

/datum/action/cooldown/spell/cultivation/declare_rivalry
	name = "Declare Rivalry"
	desc = "As Sect Master, declare another sect your sworn rival. Duels against rivals are worth double face."
	cooldown_time = 2 MINUTES
	qi_cost = 0

/datum/action/cooldown/spell/cultivation/declare_rivalry/cast(mob/living/cast_on)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(declare), cast_on)

/datum/action/cooldown/spell/cultivation/declare_rivalry/proc/declare(mob/living/user)
	var/datum/jianghu_sect/sect = jianghu_sect_of(user.mind)
	if(sect?.master != user.mind)
		to_chat(user, span_warning("Only a Sect Master can declare rivalries."))
		return
	var/list/options = list()
	for(var/datum/jianghu_sect/other as anything in GLOB.jianghu_sects)
		if(other != sect && !(other in sect.rivals))
			options[other.name] = other
	if(!length(options))
		to_chat(user, span_warning("There are no other sects worth your contempt."))
		return
	var/choice = tgui_input_list(user, "Declare which sect your rival?", "Declare Rivalry", options)
	var/datum/jianghu_sect/rival = options[choice]
	if(!rival)
		return
	sect.rivals |= rival
	rival.rivals |= sect
	sect.announce("Our Sect Master has declared the [rival.name] our sworn rival!")
	rival.announce("The [sect.name] has declared us their sworn rival! Defeat them in honor duels for double face.")

// ===================== Hidden weapons =====================

/obj/item/throwing_star/cultivation_needle
	name = "plum blossom needle"
	desc = "A slender steel needle for throwing. In a cultivator's hand it can find an acupoint from across the room."
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'
	icon_state = "needles"
	inhand_icon_state = null
	lefthand_file = null
	righthand_file = null
	w_class = WEIGHT_CLASS_TINY
	throwforce = 4
	armour_penetration = 20
	embed_type = /datum/embedding/cultivation_needle
	custom_materials = list(/datum/material/iron = SMALL_MATERIAL_AMOUNT * 2)

/datum/embedding/cultivation_needle
	pain_mult = 1
	embed_chance = 85
	fall_chance = 2

/obj/item/throwing_star/cultivation_needle/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	var/mob/living/thrower = throwingdatum?.get_thrower()
	if(!isliving(hit_atom) || cultivation_realm_of(thrower) < REALM_QI_CONDENSATION)
		return
	var/mob/living/victim = hit_atom
	if(thrower.zone_selected == BODY_ZONE_PRECISE_MOUTH)
		to_chat(victim, span_userdanger("A needle strikes an acupoint in your throat!"))
		ADD_TRAIT(victim, TRAIT_MUTE, REF(src))
		addtimer(TRAIT_CALLBACK_REMOVE(victim, TRAIT_MUTE, REF(src)), 3 SECONDS)
	else
		to_chat(victim, span_userdanger("A needle strikes an acupoint and your limbs grow heavy!"))
		victim.apply_status_effect(/datum/status_effect/cultivation_slow, 2 SECONDS)

/obj/item/throwing_star/flying_dagger
	name = "willow-leaf flying dagger"
	desc = "A slim, perfectly balanced throwing dagger. Cultivators throw them hard enough to bury them to the hilt."
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'
	icon_state = "flying_dagger"
	inhand_icon_state = "knife"
	lefthand_file = 'icons/mob/inhands/equipment/kitchen_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/kitchen_righthand.dmi'
	force = 8
	throwforce = 12
	armour_penetration = 20
	sharpness = SHARP_EDGED
	embed_type = /datum/embedding/flying_dagger
	custom_materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT)

/datum/embedding/flying_dagger
	pain_mult = 2
	embed_chance = 60
	fall_chance = 5

/obj/item/throwing_star/flying_dagger/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	var/mob/living/thrower = throwingdatum?.get_thrower()
	var/realm = cultivation_realm_of(thrower)
	if(realm && isliving(hit_atom))
		var/mob/living/victim = hit_atom
		victim.apply_damage(3 * realm, BRUTE, sharpness = SHARP_EDGED)
	return ..()

/obj/item/smoke_pellet
	name = "smoke pellet"
	desc = "A paper twist packed with powder. Throw it, or crush it at your feet, to vanish in a cloud of smoke."
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'
	icon_state = "smoke_pellet"
	w_class = WEIGHT_CLASS_TINY
	throwforce = 0

/obj/item/smoke_pellet/attack_self(mob/user)
	user.visible_message(span_warning("[user] crushes something underfoot and vanishes into a cloud of smoke!"))
	pop(get_turf(user))

/obj/item/smoke_pellet/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	pop(get_turf(src))

/obj/item/smoke_pellet/proc/pop(turf/where)
	playsound(where, 'sound/effects/smoke.ogg', 50, TRUE)
	do_smoke(2, holder = src, location = where)
	qdel(src)

/datum/crafting_recipe/cultivation_needles
	name = "Plum Blossom Needles (x3)"
	result = /obj/item/throwing_star/cultivation_needle
	result_amount = 3
	reqs = list(/obj/item/stack/rods = 1)
	tool_behaviors = list(TOOL_WIRECUTTER)
	time = 3 SECONDS
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/flying_dagger
	name = "Willow-leaf Flying Dagger"
	result = /obj/item/throwing_star/flying_dagger
	reqs = list(/obj/item/stack/sheet/iron = 2, /obj/item/stack/sheet/cloth = 1)
	tool_behaviors = list(TOOL_WELDER)
	time = 5 SECONDS
	category = CAT_WEAPON_RANGED

/datum/crafting_recipe/smoke_pellet
	name = "Smoke Pellets (x2)"
	result = /obj/item/smoke_pellet
	result_amount = 2
	reqs = list(/obj/item/paper = 1, /obj/item/match = 1)
	time = 3 SECONDS
	category = CAT_WEAPON_RANGED
