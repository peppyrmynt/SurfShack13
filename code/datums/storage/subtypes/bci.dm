/datum/storage/bci_gs
	max_specific_storage = WEIGHT_CLASS_SMALL

	max_slots = 1
	max_total_storage = 2

/datum/storage/bci_gs/New(atom/parent, max_slots, max_specific_storage, max_total_storage, rustle_sound, remove_rustle_sound)
	. = ..()
	set_holdable(list(
		/obj/item/grenade/chem_grenade, // certain non-chem grenades do NOT work with this component.
	))
