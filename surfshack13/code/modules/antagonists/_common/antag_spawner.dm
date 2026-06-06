/obj/item/antag_maker
	name = "suspicious station bounced radio"
	desc = "A strange device that looks like a basic handheld radio for local telecommunication networks. You get the strangest feeling to put it up to your ear while you're alone..."
	icon = 'icons/obj/devices/voice.dmi'
	icon_state = "walkietalkie"
	lefthand_file = 'icons/mob/inhands/items/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items/devices_righthand.dmi'
	inhand_icon_state = "walkietalkie"
	// What antag does this give our user?
	var/provided_antag_datum = /datum/antagonist/traitor
	// How many credits do we give the player should they already have antagonist status.
	var/refund_amount = 5000
	// Safety check to prevent exploits with lag and such
	var/has_used = FALSE
	// Do we make the user drop all of their shit to make room for new outfits?
	var/force_drop_equipment = FALSE

/obj/item/antag_maker/attack_self(mob/living/carbon/user)
	if(!user)
		return

	var/mob/living/carbon/human/owner = user

	if(owner.mind.antag_datums != null)
		if(!has_used)
			has_used = TRUE
			owner.client.prefs.adjust_metacoins(owner.client.ckey, refund_amount, "You've already become an antagonist. You've been refunded.")
		qdel(src)
		return

	if(!owner.mind.assigned_role.antag_tokenable)
		if(!has_used)
			has_used = TRUE
			owner.client.prefs.adjust_metacoins(owner.client.ckey, refund_amount, "Your role is incompatible with antagonism! You've been refunded.")
		qdel(src)
		return

	if(force_drop_equipment)
		owner.drop_all_equipment()
		/// We're paralyzing you for 30 seconds to ensure you don't just pick your shit back up before you can get teleported.
		owner.Paralyze(30 SECONDS)

	if(!has_used)
		has_used = TRUE
		user.mind?.add_antag_datum(provided_antag_datum)
	qdel(src)

/obj/item/antag_maker/heretic
	provided_antag_datum = /datum/antagonist/heretic
	refund_amount = 5000

/obj/item/antag_maker/brother
	provided_antag_datum = /datum/antagonist/brother
	refund_amount = 4000

/obj/item/antag_maker/changeling
	provided_antag_datum = /datum/antagonist/changeling
	refund_amount = 5000

/obj/item/antag_maker/bloodsucker
	provided_antag_datum = /datum/antagonist/bloodsucker
	refund_amount = 5000

/obj/item/antag_maker/spy
	provided_antag_datum = /datum/antagonist/spy
	refund_amount = 4000

/obj/item/antag_maker/wizard
	provided_antag_datum = /datum/antagonist/wizard
	refund_amount = 8000

/obj/item/antag_maker/nukie
	provided_antag_datum = /datum/antagonist/nukeop
	refund_amount = 7000

/obj/item/antag_maker/clown_op
	provided_antag_datum = /datum/antagonist/nukeop/clownop
	refund_amount = 7000
