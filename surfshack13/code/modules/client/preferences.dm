/datum/preferences
	/// Loadout via store prefs. Assoc list of [typepaths] to [associated list of item info].
	var/list/storecart_list

	///list of specially handled loadout items as array indexes for the extra_stat_inventory
	var/list/special_loadout_list = list(
		"unusual" = list(),
		"single-use" = list(),
		"generic" = list(),
	)
	var/needs_update = TRUE

	///list of all items in inventory
	var/list/inventory = list()

	///the amount of metacoins currently possessed
	var/metacoins

	///amount of metacoins you can earn per shift
	var/max_round_coins = 1000
