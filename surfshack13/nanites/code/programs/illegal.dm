/datum/nanite_program/freedom
	name = "Freedom Procedure"
	desc = "The nanites search for restraints upon the host and remove them quickly."
	unique = TRUE
	can_trigger = TRUE
	trigger_cost = 100
	trigger_cooldown = 200
	rogue_types = list(/datum/nanite_program/meltdown)

/datum/nanite_program/freedom/on_trigger()
	. = ..()
	to_chat(host_mob, "You feel a faint click.")
	if(iscarbon(host_mob))
		var/mob/living/carbon/C_host_mob = host_mob
		C_host_mob.uncuff()

/datum/nanite_program/construct_ammo
	name = "Construct Ammunition"
	desc = "The nanites expend a moderate amount of themselves to create a ammo box loaded with a certain kind of ammunition, ready for use."
	unique = FALSE
	can_trigger = TRUE
	trigger_cost = 100
	trigger_cooldown = 30
	rogue_types = list(/datum/nanite_program/meltdown)

/datum/nanite_program/construct_ammo/register_extra_settings()
	extra_settings[NES_AMMO_CHOICE] = new /datum/nanite_extra_setting/type("9mm Bullets", list("9mm Bullets", "10mm Bullets", ".45 Bullets", "Shotgun Shells"))

/datum/nanite_program/construct_ammo/on_trigger(comm_message)
	if(host_mob.stat == DEAD)
		return

	var/datum/nanite_extra_setting/scanned_nanites = extra_settings[NES_AMMO_CHOICE]
	switch(scanned_nanites.get_value())
		if("9mm Bullets")
			var/obj/item/ammo_box/c9mm/Newitem = new
			if(!host_mob.put_in_active_hand(Newitem))
				host_mob.forceMove(host_mob.drop_location())
		if("10mm Bullets")
			var/obj/item/ammo_box/c10mm/Newitem = new
			if(!host_mob.put_in_active_hand(Newitem))
				host_mob.forceMove(host_mob.drop_location())
		if(".45 Bullets")
			var/obj/item/ammo_box/c45/Newitem = new
			if(!host_mob.put_in_active_hand(Newitem))
				host_mob.forceMove(host_mob.drop_location())
		if("Shotgun Shells")
			var/obj/item/storage/box/lethalshot/Newitem = new
			if(!host_mob.put_in_active_hand(Newitem))
				host_mob.forceMove(host_mob.drop_location())


/datum/nanite_program/construct_c4
	name = "Explosives Construction"
	desc = "The nanites expend a large amount of themselves to create a C4 charge."
	unique = TRUE
	can_trigger = TRUE
	trigger_cost = 100
	trigger_cooldown = 60
	rogue_types = list(/datum/nanite_program/meltdown)

/datum/nanite_program/construct_c4/on_trigger()
	var/obj/item/grenade/c4/Newitem = new
	if(!host_mob.put_in_active_hand(Newitem))
		host_mob.forceMove(host_mob.drop_location())


/datum/nanite_program/kravmaga
	name = "Martial Art Imprinting"
	desc = "The nanites imprint the knowledge of krav maga onto the host, allowing them to use the martial art so long as this program exists."
	use_rate = 1
	rogue_types = list(/datum/nanite_program/nerve_decay)
	var/datum/martial_art/krav_maga/style = new

/datum/nanite_program/kravmaga/enable_passive_effect()
	. = ..()
	if(!ishuman(host_mob))
		return
	if(!host_mob.mind)
		return

	style.teach(host_mob,1)

/datum/nanite_program/kravmaga/disable_passive_effect()
	. = ..()
	if(!ishuman(host_mob))
		return
	if(!host_mob.mind)
		return

	style.remove(host_mob)


/datum/nanite_program/suicidal
	name = "Suicide Procedure"
	desc = "The nanites expend a large portion of themselves to synthesize cyanide within the host's blood. Resulting in either a severely damaged liver, or death in the host."
	can_trigger = TRUE
	trigger_cost = 25
	trigger_cooldown = 300
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/suicidal/on_trigger()
	host_mob.reagents.add_reagent(/datum/reagent/toxin/cyanide, 50)
