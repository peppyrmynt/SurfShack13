// Additional Arm - ported from HippieStation.
// Uses Surf's change_number_of_hands(), which attaches a real arm bodypart to humans.

/obj/item/extra_arm
	name = "extra arm installer"
	desc = "Distantly related to the technology of the Man-Machine Interface, this state-of-the-art syndicate device adapts your nervous and circulatory system to the presence of an extra limb..."
	icon = 'surfshack13/icons/hippie/extra_arm.dmi'
	icon_state = "extra_arm"
	w_class = WEIGHT_CLASS_SMALL
	/// Whether the installer has already been used up
	var/used = FALSE

/obj/item/extra_arm/attack_self(mob/user, modifiers)
	. = ..()
	if(.)
		return
	if(used)
		balloon_alert(user, "already used!")
		return TRUE
	if(!ishuman(user))
		balloon_alert(user, "incompatible anatomy!")
		return TRUE
	var/mob/living/carbon/human/human_user = user
	human_user.change_number_of_hands(length(human_user.held_items) + 1)
	used = TRUE
	icon_state = "extra_arm_none"
	desc += " Looks like it's been used up."
	human_user.visible_message(
		span_notice("[human_user] presses a button on [src], and you hear a disgusting noise."),
		span_notice("You feel a sharp sting as [src] plunges into your body."),
	)
	to_chat(human_user, span_notice("You feel more dexterous."))
	playsound(get_turf(human_user), 'sound/misc/splort.ogg', 50, TRUE)
	return TRUE

/datum/uplink_item/device_tools/additional_arm
	name = "Additional Arm"
	desc = "An additional arm harvested from slaves captured by the Syndicate. Comes with an implanter."
	item = /obj/item/extra_arm
	cost = 4
	limited_stock = 2
	purchasable_from = UPLINK_TRAITORS
