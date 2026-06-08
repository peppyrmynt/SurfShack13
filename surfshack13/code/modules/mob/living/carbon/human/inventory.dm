//Drop all your shit
/mob/living/carbon/human/proc/drop_all_equipment()
	for(var/slot in get_equipped_items(INCLUDE_POCKETS|INCLUDE_HELD))//order matters, dependant slots go first
		dropItemToGround(slot, TRUE)
	for(var/obj/item/held_item in held_items)
		dropItemToGround(held_item, TRUE)
