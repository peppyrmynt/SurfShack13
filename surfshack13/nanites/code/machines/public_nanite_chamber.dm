/obj/machinery/nanite_chamber/public
	name = "public nanite chamber"
	desc = "A device that can scan, reprogram, and inject nanites automatically without outside help."
	circuit = /obj/item/circuitboard/machine/public_nanite_chamber
		///The techweb that hosts the nanites we're injecting into people.
	var/datum/techweb/linked_techweb

/obj/machinery/nanite_chamber/public/post_machine_initialize()
	. = ..()
	if(!CONFIG_GET(flag/no_default_techweb_link) && !linked_techweb)
		CONNECT_TO_RND_SERVER_ROUNDSTART(linked_techweb, src)

/obj/machinery/nanite_chamber/public/Destroy()
	linked_techweb = null
	return ..()

/obj/machinery/nanite_chamber/public/multitool_act(mob/living/user, obj/item/multitool/tool)
	if(!QDELETED(tool.buffer) && istype(tool.buffer, /datum/techweb))
		linked_techweb = tool.buffer
	return TRUE

/obj/machinery/nanite_chamber/public/toggle_open(mob/user)
	..()
	var/mob/living/person_inside = occupant

	if(!person_inside)
		return

	if(!(person_inside.mob_biotypes & (MOB_ORGANIC|MOB_UNDEAD)))
		return

	if(!person_inside.GetComponent(/datum/component/nanites))
		inject_nanites()
		log_combat(usr, person_inside, "injected", null, "with nanites via [src]")
		log_game("[person_inside] was injected with nanites by [key_name(usr)] via [src] at [AREACOORD(src)].")
	else
		remove_nanites()
		log_combat(usr, person_inside, "cleared nanites from", null, "via [src]")
		log_game("[person_inside]'s nanites were cleared by [key_name(usr)] via [src] at [AREACOORD(src)].")

/obj/machinery/nanite_chamber/public/complete_injection(locked_state)
	locked = locked_state
	set_busy(FALSE)
	if(!occupant || !linked_techweb)
		return
	occupant.AddComponent(/datum/component/nanites, linked_techweb)

	var/obj/item/circuitboard/machine/public_nanite_chamber/our_circuit = circuit

	SEND_SIGNAL(occupant, COMSIG_NANITE_SET_CLOUD, our_circuit.cloud_id)
	SEND_SIGNAL(occupant, COMSIG_NANITE_SET_SAFETY, 50)
