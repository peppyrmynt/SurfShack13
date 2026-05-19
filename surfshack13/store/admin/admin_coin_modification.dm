ADMIN_VERB(adjust_players_metacoins, R_FUN, "Adjust Doubloons", "You can modifiy a targets doubloons balance by adding or subtracting.", ADMIN_CATEGORY_FUN)
	var/mob/chosen_player
	chosen_player = tgui_input_list(user, "Choose a Player", "Player List", GLOB.player_list)
	if(!chosen_player)
		return
	var/client/chosen_client = chosen_player.client

	var/adjustment_amount = tgui_input_number(user, "How much should we adjust this users doubloons by?", "Input Value", TRUE, 1000000, -100000)
	if(!adjustment_amount)
		return

	if(adjustment_amount + chosen_client.prefs.metacoins < 0)
		adjustment_amount = -chosen_client.prefs.metacoins
	log_admin("[key_name(user)] adjusted the doubloons of [key_name(chosen_client)] by [adjustment_amount].")
	message_admins("[key_name_admin(user)] adjusted the doubloons of [key_name(chosen_client)] by [adjustment_amount].")
	chosen_client.prefs.adjust_metacoins(chosen_client.ckey, adjustment_amount, "Admin [user.ckey] adjusted doubloons", announces = FALSE)
	BLACKBOX_LOG_ADMIN_VERB("Adjust Doubloons")

ADMIN_VERB(mass_add_metacoins, R_FUN, "Mass Add Doubloons", "You give everyone some doubloons.", ADMIN_CATEGORY_FUN)
	var/adjustment_amount = tgui_input_number(user, "How much should we adjust this users doubloons by?", "Input Value", TRUE, 10000, 0)
	if(!adjustment_amount)
		return

	for(var/mob/player in GLOB.player_list)
		if(!player.client)
			continue
		if(!player.client.prefs)
			continue

		player.client.prefs.adjust_metacoins(player.client.ckey, adjustment_amount, "You have been gifted some doubloons from the staff")
	log_admin("[key_name(user)] has mass adjusted doubloons.")
	message_admins("[key_name_admin(user)] has mass adjusted doubloons.")
	BLACKBOX_LOG_ADMIN_VERB("Mass Add Doubloons")

ADMIN_VERB(check_players_metacoins, R_FUN, "Check Doubloons", "Check a certain players Doubloon balance.", ADMIN_CATEGORY_FUN)
	var/mob/chosen_player
	chosen_player = tgui_input_list(user, "Choose a Player", "Player List", GLOB.player_list)
	if(!chosen_player)
		return
	var/client/chosen_client = chosen_player.client

	var/chosen_player_balance = chosen_client.prefs.metacoins

	log_admin("[key_name(user)] checked the doubloons of [key_name(chosen_client)], they have [chosen_player_balance].")
	message_admins("[key_name_admin(user)] checked the doubloons of [key_name(chosen_client)], they have [chosen_player_balance].")
	BLACKBOX_LOG_ADMIN_VERB("Check Doubloons")
