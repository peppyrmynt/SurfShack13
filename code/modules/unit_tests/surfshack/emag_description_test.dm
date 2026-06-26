/// checks that any atom that returns true on emag_act() has an exisiting and documented emag description.
/datum/unit_test/emag_description

/datum/unit_test/emag_description/Run()
	var/list/all_atoms = subtypesof(/atom)

	var/obj/item/card/emag/emag_card = new()
	for(var/type in all_atoms)
		var/atom/A = allocate(type)
		/// emag act returns true on most emaggable objects with a few exceptions.
		var/emag_act_returned_val = A.emag_act(null, emag_card)
		var/datum/wiki_data/atom_data = A.auto_wiki_datum
		if(!emag_act_returned_val)
			if(atom_data && atom_data.emag_description)
				TEST_FAIL("[type] doesnt appear to be emaggable but has a valid emag description as if it is emaggable {desc: [atom_data.emag_description]}.")
			else
				continue

		// if object was emaggad but no emag description was set, then fail the test
		if(!atom_data || !atom_data.emag_description)
			TEST_FAIL("[type] appears to be emaggable but does not include a emag_description. ensure to attatch a /datum/wiki_data, and write an appropriate emag_description on that datum. \
			See recycler.dm for an example, or _auto_manuel.dm for more info")
