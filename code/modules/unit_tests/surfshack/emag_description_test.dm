// /// checks that any atom that returns true on emag_act() has an exisiting and documented emag description.
// /datum/unit_test/emag_description

// /datum/unit_test/emag_description/Run()
// 	var/obj/item/card/emag/emag_card = allocate(/obj/item/card/emag)
// 	var/mob/living/carbon/user = allocate(/mob/living/carbon)
// 	for(var/type in subtypesof(/atom)
// )
// 		var/atom/A = allocate(type)

// 		/// emag act returns true on most emaggable objects with a few exceptions.
// 		if(!A.emag_act(user, emag_card))
// 			continue

// 		var/datum/wiki_data/atom_data = A.auto_wiki_datum
// 		// if object was emaggad but no emag description was set, then fail the test
// 		if(!atom_data || !atom_data.emag_description)
// 			TEST_FAIL("[type] appears to be emaggable but does not include a emag_description. ensure to attatch a /datum/wiki_data, and write an appropriate emag_description on that datum. \
// 			See recycler.dm for an example, or _auto_manuel.dm for more info")
