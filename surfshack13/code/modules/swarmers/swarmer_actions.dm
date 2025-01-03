//Swarmer abilities.

/datum/action/innate/swarmer
	button_icon = 'surfshack13/icons/swarmers/swarmer_hud.dmi'
	check_flags = AB_CHECK_CONSCIOUS|AB_CHECK_INCAPACITATED

/datum/action/innate/swarmer/toggle_lights
	name = "Toggle Lights"
	desc = "Toggles your internal light source."
	button_icon_state = "ui_light"

/datum/action/innate/swarmer/toggle_lights/Activate(atom/target)
	if (!owner.light_on)
		to_chat(owner, span_notice("You activate your light."))
		owner.set_light_on(TRUE)
	else
		to_chat(owner, span_notice("You deactivate your light."))
		owner.set_light_on(FALSE)

/datum/action/innate/swarmer/repair
	name = "Repair Self"
	desc = "Fully repairs damage done to our body after a moderate delay."
	button_icon_state = "ui_self_repair"

/datum/action/innate/swarmer/repair/Activate(atom/target)
	if(!isturf(owner.loc) || !isswarmer(owner))
		return
	to_chat(owner, span_info("Attempting to repair damage to our body, stand by..."))
	if(!do_after(owner, 10 SECONDS, owner))
		return
	var/mob/living/basic/swarmer/swarmer = owner
	swarmer.adjust_health(-swarmer.maxHealth)
	to_chat(owner, span_info("We successfully repaired ourselves."))

/datum/action/innate/swarmer/fabricate_trap
	name = "Fabricate Snare"
	desc = "Creates a trap that will nonlethally shock any non-swarmer that attempts to cross it."
	button_icon_state = "ui_trap"
	var/trap_cost = 4

/datum/action/innate/swarmer/fabricate_trap/Activate(atom/target)
	if(!isswarmer(owner))
		return
	var/mob/living/basic/swarmer/swarmer = owner
	if(locate(/obj/structure/swarmer/trap) in swarmer.loc)
		to_chat(swarmer, span_warning("There is already a trap here. Aborting."))
		return
	if(swarmer.resources < trap_cost)
		to_chat(swarmer, span_warning("We do not have the resources for this!"))
		return
	if(!isturf(swarmer.loc))
		to_chat(swarmer, span_warning("This is not a suitable location for fabrication. We need more space."))
		return
	swarmer.update_resource_value(-trap_cost)
	new /obj/structure/swarmer/trap(swarmer.drop_location())

/datum/action/innate/swarmer/fabricate_blockcade
	name = "Fabricate Blockade"
	desc = "Creates a destructible blockcade that will stop any non-swarmer from passing it. Also allows disabler beams to pass through."
	button_icon_state = "ui_barricade"
	var/blockcade_cost = 4

/datum/action/innate/swarmer/fabricate_blockcade/Activate(atom/target)
	if(!isswarmer(owner))
		return
	var/mob/living/basic/swarmer/swarmer = owner
	if(locate(/obj/structure/swarmer/blockade) in swarmer.loc)
		to_chat(swarmer, span_warning("There is already a blockade here. Aborting."))
		return
	if(swarmer.resources < blockcade_cost)
		to_chat(swarmer, span_warning("We do not have the resources for this!"))
		return
	if(!isturf(swarmer.loc))
		to_chat(swarmer, span_warning("This is not a suitable location for fabrication. We need more space."))
		return
	if(!do_after(swarmer, 1 SECONDS, swarmer))
		return
	swarmer.update_resource_value(-blockcade_cost)
	new /obj/structure/swarmer/blockade(swarmer.drop_location())

/datum/action/innate/swarmer/contact_swarmers
	name = "Contact Swarmers"
	desc = "Sends a message to all other swarmers, should they exist."
	button_icon_state = "ui_contact_swarmers"

/datum/action/innate/swarmer/contact_swarmers/Activate()
	var/message = tgui_input_text(owner, "Announce to other swarmers", "Swarmer contact")
	// TODO get swarmers their own colour rather than just boldtext
	if(!message)
		return
	var/rendered = "<B>Swarm communication - [owner]</b> [owner.say_quote(message)]"
	for(var/i in GLOB.mob_list)
		var/mob/listener = i
		if(isswarmer(listener))
			to_chat(listener, rendered)
		else if(isobserver(listener))
			var/link = FOLLOW_LINK(listener, owner)
			to_chat(listener, "[link] [rendered]")
