/datum/quirk/item_quirk/weapon_permit
	name = "Weapon Permit"
	desc = "You were previously enlisted into Nanotrasen's security force, but have since moved on to bigger and better things. You got to keep your weapon permit, though."
	icon = FA_ICON_SHIELD
	value = 7
	medical_record_text = "Patient was previously enlisted in the security force, watch for potential PTSD."

/datum/quirk/item_quirk/weapon_permit/add_unique(client/client_source)
	give_item_to_holder(/obj/item/card/weapon_permit, list(LOCATION_BACKPACK, LOCATION_HANDS))
