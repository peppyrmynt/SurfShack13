/datum/controller/subsystem/ticker/proc/calculate_rewards()
	. = list()
	for(var/client/client as anything in GLOB.clients)
		calculate_rewards_for_client(client, .)
	calculate_station_goal_bonus(.)

/datum/controller/subsystem/ticker/proc/calculate_station_goal_bonus(list/rewards)
	var/list/joined_player_list = unique_list(GLOB.joined_player_list)
	var/total_crew = length(joined_player_list)
	if(total_crew < 10) // prevent wrecking the economy on like MRP2
		return
	var/completed = FALSE
	for(var/datum/station_goal/station_goal as anything in SSstation.get_station_goals())
		if(station_goal.check_completion())
			completed = TRUE
			break
	if(!completed)
		return
	var/amount = CEILING(50000 / total_crew, 50) // nice even number
	for(var/ckey in joined_player_list)
		LAZYINITLIST(rewards[ckey])
		rewards[ckey] += list(list(amount, "Station Goal Completion Bonus"))

	message_admins("As a result of the station goal being completed, [total_crew] players were rewarded [amount] credits each.")
	log_game("As a result of the station goal being completed, [total_crew] players were rewarded [amount] credits each.")

/datum/controller/subsystem/ticker/proc/distribute_rewards(list/coin_rewards)
	var/hour = round((world.time - SSticker.round_start_time) / 36000)
	var/minute = round(((world.time - SSticker.round_start_time) - (hour * 36000)) / 600)
	var/added_xp = round(25 + (minute ** 0.85))
	for(var/ckey in coin_rewards)
		distribute_rewards_to_client(ckey, added_xp, coin_rewards[ckey])

/datum/controller/subsystem/ticker/proc/distribute_rewards_to_client(ckey, added_xp, list/rewards)
	var/client/client = GLOB.directory[ckey]
	if(!client)
		return
	var/total_amount = 0
	for(var/reward in rewards)
		var/amount = reward[1]
		var/reason = reward[2]
		total_amount += amount
		to_chat(client, span_rose(span_bold("[abs(amount)] Credits have been [amount >= 0 ? "deposited to" : "withdrawn from"] your account! Reason: [reason]")))
	// don't do separate SQL queries for each reward, just add all the coins at once lol
	if(total_amount)
		client?.prefs?.adjust_metacoins(ckey, total_amount, reason = "roundend rewards", announces = FALSE)

/datum/controller/subsystem/ticker/proc/calculate_rewards_for_client(client/client, list/queue)
	if(!istype(client) || QDELING(client))
		return
	var/ckey = client?.ckey
	if(!ckey)
		return
	var/datum/persistent_client/details = client.persistent_client

	var/round_end_bonus = 100

	LAZYINITLIST(queue[ckey])

	if(isnewplayer(details?.mob)) // Prevent giving lobby afk'ers credits.
		return

	queue[ckey] += list(list(round_end_bonus, "Played a Round"))

	if(details?.mob?.mind?.assigned_role?.departments_bitflags & DEPARTMENT_BITFLAG_COMMAND)
		queue[ckey] += list(list(300, "Head of Staff Bonus"))

	if(details?.mob?.mind?.antag_datums != null)
		for(var/datum/antagonist/antag_datum as anything in details?.mob?.mind?.antag_datums)
			for(var/datum/objective/objective_datum as anything in details.mob.mind.get_all_objectives())
				if(objective_datum.check_completion() && objective_datum.reward_for_completion)
					var/cred_reward = objective_datum.completion_credit_reward
					queue[ckey] += list(list(cred_reward, "Completed Objective Bonus"))

			var/greentexted = TRUE
			for(var/datum/objective/objective_datum as anything in details.mob.mind.get_all_objectives())
				if(!objective_datum.check_completion())
					greentexted = FALSE
					break
			if(greentexted)
				queue[ckey] += list(list(100, "Greentext Bonus"))
				return
