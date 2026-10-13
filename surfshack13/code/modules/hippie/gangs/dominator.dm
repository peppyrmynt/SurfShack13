// Dominator: activating it starts a station takeover countdown for your gang.
// If it survives to zero, the gang wins and the round ends.

/obj/machinery/dominator
	name = "dominator"
	desc = "A visibly sinister device. Looks like you can break it if you hit it enough."
	icon = 'icons/obj/machines/dominator.dmi'
	icon_state = "dominator"
	density = TRUE
	anchored = TRUE
	layer = HIGH_OBJ_LAYER
	max_integrity = 300
	integrity_failure = 0.33
	move_resist = INFINITY
	armor_type = /datum/armor/dominator
	use_power = NO_POWER_USE
	/// The gang running a takeover from this dominator
	var/datum/team/gang/gang
	/// Whether a takeover is running
	var/operating = FALSE
	/// Whether the 3 minute warning went out
	var/warned = FALSE
	/// Stops the "too many walls" warning spamming
	var/spam_prevention = GANG_DOM_BLOCKED_SPAM_CAP
	var/datum/effect_system/spark_spread/spark_system
	var/obj/effect/countdown/dominator/countdown

/datum/armor/dominator
	melee = 20
	bullet = 50
	laser = 50
	energy = 50
	bomb = 10
	bio = 100
	fire = 10
	acid = 70

/obj/machinery/dominator/Initialize(mapload)
	. = ..()
	set_light(2)
	SSpoints_of_interest.make_point_of_interest(src)
	spark_system = new
	spark_system.set_up(5, TRUE, src)
	countdown = new(src)
	update_appearance()

/obj/machinery/dominator/Destroy()
	if(!(machine_stat & BROKEN))
		set_broken()
	gang = null
	QDEL_NULL(spark_system)
	QDEL_NULL(countdown)
	STOP_PROCESSING(SSmachines, src)
	return ..()

/obj/machinery/dominator/emp_act(severity)
	. = ..()
	take_damage(100, BURN, ENERGY, FALSE)

/obj/machinery/dominator/zap_act(power, zap_flags)
	. = ..()
	qdel(src)

/obj/machinery/dominator/update_icon_state()
	. = ..()
	if(machine_stat & BROKEN)
		icon_state = "dominator-broken"
	else
		icon_state = operating ? "dominator-active" : "dominator"

/obj/machinery/dominator/update_overlays()
	. = ..()
	if(machine_stat & BROKEN)
		return
	if(operating)
		var/mutable_appearance/glow = mutable_appearance(icon, "dominator-overlay")
		if(gang)
			glow.color = gang.color
		. += glow
	if(atom_integrity / max_integrity < 0.66)
		. += "damage"

/obj/machinery/dominator/examine(mob/user)
	. = ..()
	if(machine_stat & BROKEN)
		return
	if(gang && gang.domination_time != GANG_NOT_DOMINATING)
		if(gang.domination_time > world.time)
			. += span_notice("Hostile Takeover in progress. Estimated [gang.domination_time_remaining()] seconds remain.")
		else
			. += span_notice("Hostile Takeover of [station_name()] successful. Have a great day.")
	else
		. += span_notice("System on standby.")
	. += span_danger("System Integrity: [round((atom_integrity / max_integrity) * 100, 1)]%")

/obj/machinery/dominator/process(seconds_per_tick)
	if(!gang || gang.domination_time == GANG_NOT_DOMINATING)
		return PROCESS_KILL
	var/time_remaining = gang.domination_time_remaining()
	if(time_remaining <= 0)
		takeover_complete()
		return PROCESS_KILL
	if(excessive_walls_check())
		gang.domination_time += seconds_per_tick SECONDS
		playsound(src, 'sound/machines/buzz/buzz-two.ogg', 50, FALSE)
		if(spam_prevention < GANG_DOM_BLOCKED_SPAM_CAP)
			spam_prevention++
		else
			gang.message_gangtools("Warning: There are too many walls around your gang's dominator, its signal is being blocked!")
			say("Error: Takeover signal is currently blocked! There are too many walls within 3 standard units of this device.")
			spam_prevention = 0
		return
	playsound(src, 'sound/items/timer.ogg', 10, FALSE)
	if(!warned && time_remaining < 180)
		warned = TRUE
		var/area/dom_area = get_area(src)
		gang.message_gangtools("Less than 3 minutes remains in hostile takeover. Defend your dominator at [dom_area.name]!")
		for(var/datum/team/gang/other_gang as anything in GLOB.gangs)
			if(other_gang != gang)
				other_gang.message_gangtools("WARNING: [gang.name] Gang takeover imminent. Their dominator at [dom_area.name] must be destroyed!")

/// The gang wins: announce it and end the round.
/obj/machinery/dominator/proc/takeover_complete()
	gang.winner = TRUE
	priority_announce("Station network fully compromised. [station_name()] is now under the control of the [gang.name] Gang.", "Network Alert")
	SSticker.force_ending = FORCE_END_ROUND

/obj/machinery/dominator/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			playsound(src, damage_amount ? 'sound/effects/bang.ogg' : 'sound/items/weapons/tap.ogg', 50, TRUE)
		if(BURN)
			playsound(src, 'sound/items/tools/welder.ogg', 100, TRUE)

/obj/machinery/dominator/take_damage(damage_amount, damage_type = BRUTE, damage_flag = "", sound_effect = TRUE, attack_dir, armour_penetration = 0)
	. = ..()
	if(!. || QDELETED(src))
		return
	if(atom_integrity / max_integrity > 0.66)
		if(prob(damage_amount * 2))
			spark_system.start()
	else if(!(machine_stat & BROKEN))
		spark_system.start()
		update_appearance()

/obj/machinery/dominator/atom_break(damage_flag)
	. = ..()
	set_broken()

/obj/machinery/dominator/on_deconstruction(disassembled)
	new /obj/item/stack/sheet/plasteel(drop_location())

/obj/machinery/dominator/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(operating || (machine_stat & BROKEN))
		user.examinate(src)
		return
	var/datum/antagonist/gang/member = user.mind?.has_antag_datum(/datum/antagonist/gang)
	var/datum/team/gang/user_gang = member?.gang
	if(!user_gang)
		user.examinate(src)
		return
	if(user_gang.domination_time != GANG_NOT_DOMINATING)
		to_chat(user, span_warning("Error: Hostile Takeover is already in progress."))
		return
	if(!user_gang.dom_attempts)
		to_chat(user, span_warning("Error: Unable to breach station network. Firewall has logged our signature and is blocking all further attempts."))
		return
	var/time = round(user_gang.determine_domination_time() / 60, 0.1)
	if(tgui_alert(user, "A takeover will require [time] minutes.\nYour gang will be unable to gain influence while it is active.\nThe entire station will likely be alerted to it once it starts.\nYou have [user_gang.dom_attempts] attempt(s) remaining. Are you ready?", "Confirm", list("Ready", "Later")) != "Ready")
		return
	if(operating || user_gang.domination_time != GANG_NOT_DOMINATING || !user_gang.dom_attempts || !in_range(src, user) || !isturf(loc))
		return
	start_takeover(user_gang, user)

/obj/machinery/dominator/proc/start_takeover(datum/team/gang/new_gang, mob/user)
	var/area/dom_area = get_area(src)
	gang = new_gang
	gang.dom_attempts--
	priority_announce("Network breach detected in [dom_area.name]. The [gang.name] Gang is attempting to seize control of the station!", "Network Alert")
	gang.start_domination()
	SSshuttle.registerHostileEnvironment(src)
	name = "[gang.name] Gang [initial(name)]"
	operating = TRUE
	update_appearance()
	countdown.color = gang.color
	countdown.start()
	set_light(3)
	START_PROCESSING(SSmachines, src)
	log_game("[key_name(user)] started a [gang.name] gang dominator in [dom_area].")
	message_admins("[ADMIN_LOOKUPFLW(user)] started a [gang.name] gang dominator at [ADMIN_VERBOSEJMP(src)].")
	var/time = round(gang.determine_domination_time() / 60, 0.1)
	gang.message_gangtools("Hostile takeover in progress: Estimated [time] minutes until victory.[gang.dom_attempts ? "" : " This is your final attempt."]")
	for(var/datum/team/gang/other_gang as anything in GLOB.gangs)
		if(other_gang != gang)
			other_gang.message_gangtools("Enemy takeover attempt detected in [dom_area.name]: Estimated [time] minutes until our defeat.")

/// Takeovers are blocked if the dominator is boxed in by walls
/obj/machinery/dominator/proc/excessive_walls_check()
	if(isclosedturf(loc))
		return TRUE
	var/open = 0
	for(var/turf/nearby in view(3, src))
		if(!isclosedturf(nearby))
			open++
	return open < GANG_DOM_REQUIRED_TURFS

/obj/machinery/dominator/proc/set_broken()
	if(gang)
		gang.domination_time = GANG_NOT_DOMINATING
		var/takeover_in_progress = FALSE
		for(var/datum/team/gang/other_gang as anything in GLOB.gangs)
			if(other_gang.domination_time != GANG_NOT_DOMINATING)
				takeover_in_progress = TRUE
				break
		if(!takeover_in_progress)
			if(SSshuttle.emergency.mode != SHUTTLE_STRANDED)
				priority_announce("All hostile activity within station systems has ceased.", "Network Alert")
			if(SSsecurity_level.get_current_level_as_number() == SEC_LEVEL_DELTA)
				SSsecurity_level.set_level(SEC_LEVEL_RED)
		SSshuttle.clearHostileEnvironment(src)
		gang.message_gangtools("Hostile takeover cancelled: Dominator is no longer operational.[gang.dom_attempts ? " You have [gang.dom_attempts] attempt(s) remaining." : " The station network will have likely blocked any more attempts by us."]")
	countdown?.stop()
	set_light(0)
	operating = FALSE
	update_appearance()
	STOP_PROCESSING(SSmachines, src)

/obj/effect/countdown/dominator
	name = "dominator countdown"
	text_size = 1
	color = "#e5e5e5"

/obj/effect/countdown/dominator/get_value()
	var/obj/machinery/dominator/dominator = attached_to
	if(!istype(dominator) || !dominator.gang)
		return
	if(dominator.gang.domination_time != GANG_NOT_DOMINATING)
		return "<span style='color: [dominator.gang.color]'>[max(dominator.gang.domination_time_remaining(), 0)]</span>"
	return "<span style='color: red'>--</span>"
