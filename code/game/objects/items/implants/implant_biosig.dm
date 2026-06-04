/obj/item/implant/biosig
	name = "biosignaller implant"
	desc = "Monitors host vital signs and transmits an encrypted radio message upon death."
	actions_types = null
	verb_say = "broadcasts"
	var/obj/item/radio/radio
	var/radio_key
	var/channel = RADIO_CHANNEL_COMMON
	var/subspace_transmission = FALSE

/obj/item/implant/biosig/Initialize(mapload)
	. = ..()
	radio = new(src)
	radio.set_listening(FALSE)
	radio.subspace_transmission = subspace_transmission
	radio.canhear_range = 0
	if(radio_key)
		radio.keyslot = new radio_key
	radio.recalculateChannels()

/obj/item/implant/biosig/activate(cause)
	if(!imp_in)
		return FALSE

	if(!radio)
		return FALSE

	// Location.
	var/area = get_area_name(get_turf(imp_in))
	// Name of implant user.
	var/mobname = imp_in.mind ? imp_in.mind.name : imp_in.real_name
	// What is to be said.
	var/message = "DEATH ALERT: [mobname]'s lifesigns ceased unexpectedly in [area]!" // Default message for unexpected causes.
	if(cause == "death")
		message = "DEATH ALERT: [mobname]'s lifesigns ceased in [area]!"

	radio.talk_into(src, message, channel)

/obj/item/implant/biosig/proc/on_mob_death(mob/living/L, gibbed)
	if(gibbed)
		activate("gibbed") // Will use default message.
	else
		activate("death")

/obj/item/implant/biosig/implant(mob/living/target, mob/user, silent = FALSE, force = FALSE)
	. = ..()
	RegisterSignal(target, COMSIG_LIVING_DEATH, PROC_REF(on_mob_death))

/obj/item/implant/biosig/removed(mob/target, silent = FALSE, special = FALSE)
	. = ..()
	UnregisterSignal(target, COMSIG_LIVING_DEATH)

/obj/item/implant/biosig/Destroy()
	QDEL_NULL(radio)
	return ..()

/obj/item/implant/biosig/get_data()
	return "<b>Implant Specifications:</b><BR> \
		<b>Name:</b>Biosignaller Implant<BR> \
		<b>Life:</b>Until death<BR> \
		<b>Important Notes:</b>Broadcasts a message to radio listeners over an encrypted channel.<BR> \
		<HR> \
		<b>Implant Details:</b><BR> \
		<b>Function:</b>Contains a miniature radio connected to a bioscanner encased in a blue, EMP-resistant shell. Broadcasts the death and last known position of the user over an encrypted radio channel.<BR>"

/obj/item/implanter/biosig
	name = "implanter (biosignaller)"
	imp_type = /obj/item/implant/biosig

/obj/item/implantcase/biosig
	name = "Implant Case - 'Biosignaller'"
	desc = "A glass case containing a biosignaller implant."
	imp_type = /obj/item/implant/biosig


/obj/item/implant/biosig/syndicate
	desc = "But nobody came."
	radio_key = /obj/item/encryptionkey/syndicate
	subspace_transmission = TRUE
	channel = RADIO_CHANNEL_SYNDICATE

/obj/item/implanter/biosig/syndicate
	name = "implanter (biosignaller)"
	imp_type = /obj/item/implant/biosig/syndicate

/obj/item/implantcase/biosig/syndicate
	name = "Implant Case - 'Biosignaller'"
	desc = "A glass case containing a biosignaller implant."
	imp_type = /obj/item/implant/biosig/syndicate


/obj/item/implant/biosig/security
	desc = "Can anyone hear me? Help."
	radio_key = /obj/item/encryptionkey/headset_sec
	subspace_transmission = FALSE
	channel = RADIO_CHANNEL_SECURITY

/obj/item/implanter/biosig/security
	name = "implanter (biosignaller)"
	imp_type = /obj/item/implant/biosig/security

/obj/item/implantcase/biosig/security
	name = "Implant Case - 'Biosignaller'"
	desc = "A glass case containing a biosignaller implant."
	imp_type = /obj/item/implant/biosig/security
