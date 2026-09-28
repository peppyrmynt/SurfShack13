/// Flood powers use the same HUD action system as xenomorph powers.
/datum/action/cooldown/flood
	panel = "Flood"
	background_icon_state = "bg_alien"
	overlay_icon_state = "bg_alien_border"
	button_icon = 'icons/obj/flood/flood_bio.dmi'
	button_icon_state = "pulsating"
	check_flags = NONE

/datum/action/cooldown/flood/IsAvailable(feedback = FALSE)
	return ..() && istype(owner, /mob/living/basic/flood) && owner.stat != DEAD

/datum/action/cooldown/flood/chorus
	name = "Flood Chorus"
	desc = "Speak to every active Flood player."
	button_icon = 'icons/mob/flood/flood_constructor_builder.dmi'
	button_icon_state = "designator"

/datum/action/cooldown/flood/chorus/Activate(atom/target)
	var/mob/living/basic/flood/flood_form = owner
	flood_form.flood_chorus()
	return TRUE

/datum/action/cooldown/flood/evolve
	name = "Evolve Flood"
	desc = "Choose a Flood specialization."
	button_icon = 'icons/mob/flood/flood_combat_human.dmi'
	button_icon_state = "nudist"
	cooldown_time = 30 SECONDS

/datum/action/cooldown/flood/evolve/Activate(atom/target)
	var/mob/living/basic/flood/combat_form/combat_form = owner
	combat_form.evolve()
	return TRUE

/datum/action/cooldown/flood/reanimate
	name = "Reanimate Flood Corpse"
	desc = "Reanimate a nearby fallen Flood Combat."
	button_icon = 'icons/mob/flood/flood_infection.dmi'
	button_icon_state = "dead"

/datum/action/cooldown/flood/reanimate/Activate(atom/target)
	var/mob/living/basic/flood/infestor/infestor = owner
	return infestor.reanimate_nearby_flood(TRUE)

/datum/action/cooldown/flood/release_infection_forms
	name = "Release Infectors"
	desc = "Rupture and release a swarm of Flood Infectors."
	button_icon = 'icons/mob/flood/flood_carrier.dmi'
	button_icon_state = "static"

/datum/action/cooldown/flood/release_infection_forms/Activate(atom/target)
	var/mob/living/basic/flood/carrier/carrier = owner
	carrier.release_infection_forms()
	return TRUE

/datum/action/cooldown/flood/grow_biomass
	name = "Grow Biomass"
	desc = "Grow a small biomass spawner on your tile."
	button_icon_state = "biomass1"
	cooldown_time = 60 SECONDS

/datum/action/cooldown/flood/grow_biomass/Activate(atom/target)
	var/mob/living/basic/flood/overseer/overseer = owner
	return overseer.grow_biomass()

/datum/action/cooldown/flood/produce_infestor
	name = "Produce Infector"
	desc = "Produce a single Flood Infector every 45 seconds."
	button_icon = 'icons/mob/flood/flood_infection.dmi'
	button_icon_state = "static"
	cooldown_time = 45 SECONDS

/datum/action/cooldown/flood/produce_infestor/Activate(atom/target)
	var/mob/living/basic/flood/constructor/constructor = owner
	return constructor.produce_infestor()

/datum/action/cooldown/flood/infest_floor
	name = "Infest Floor"
	desc = "Cover the floor under you with Flood biomass."
	button_icon = 'icons/turf/floors/flood_floor.dmi'
	button_icon_state = "floor"
	cooldown_time = 5 SECONDS

/datum/action/cooldown/flood/infest_floor/Activate(atom/target)
	if(istype(owner, /mob/living/basic/flood/overseer))
		var/mob/living/basic/flood/overseer/overseer = owner
		return overseer.infest_floor()
	var/mob/living/basic/flood/constructor/constructor = owner
	return constructor.infest_floor()

/datum/action/cooldown/flood/grow_barrier
	name = "Grow Biomass Wall"
	desc = "Build a solid biomass wall on your tile."
	button_icon = 'icons/obj/flood/Flood_Spore.dmi'
	button_icon_state = "flood wall gif"
	cooldown_time = 15 SECONDS

/datum/action/cooldown/flood/grow_barrier/Activate(atom/target)
	var/mob/living/basic/flood/constructor/constructor = owner
	return constructor.grow_barrier()

/datum/action/cooldown/flood/grow_door
	name = "Grow Biomass Door"
	desc = "Build a Flood door on your tile."
	button_icon = 'icons/obj/flood/flood_door.dmi'
	button_icon_state = "flood"
	cooldown_time = 15 SECONDS

/datum/action/cooldown/flood/grow_door/Activate(atom/target)
	var/mob/living/basic/flood/constructor/constructor = owner
	return constructor.grow_door()

/datum/action/cooldown/flood/grow_membrane
	name = "Grow Biomass Membrane"
	desc = "Build a translucent Flood membrane on your tile."
	button_icon = 'icons/obj/flood/flood_window.dmi'
	button_icon_state = "flood_window"
	cooldown_time = 15 SECONDS

/datum/action/cooldown/flood/grow_membrane/Activate(atom/target)
	var/mob/living/basic/flood/constructor/constructor = owner
	return constructor.grow_membrane()

/datum/action/cooldown/flood/become_overseer
	name = "Become Overseer"
	desc = "Replace a fallen overseer after the hive recovers. Only one living overseer can exist."
	button_icon = 'icons/mob/flood/flood_constructor_builder.dmi'
	button_icon_state = "designator"

/datum/action/cooldown/flood/become_overseer/Activate(atom/target)
	var/mob/living/basic/flood/constructor/constructor = owner
	return constructor.become_overseer()

/datum/action/cooldown/flood/grow_spores
	name = "Grow Spore Cluster"
	desc = "Place a spore cluster on your tile every 180 seconds."
	button_icon_state = "spore1"
	cooldown_time = 180 SECONDS

/datum/action/cooldown/flood/grow_spores/Activate(atom/target)
	var/mob/living/basic/flood/constructor/constructor = owner
	return constructor.grow_spores()

/datum/action/cooldown/flood/create_constructor
	name = "Create Flood Constructor"
	desc = "Bud off a new Flood constructor."
	button_icon = 'icons/mob/flood/flood_constructor_builder.dmi'
	button_icon_state = "constructor"
	cooldown_time = 30 SECONDS

/datum/action/cooldown/flood/create_constructor/Activate(atom/target)
	var/mob/living/basic/flood/overseer/overseer = owner
	var/previous_cooldown = overseer.next_constructor
	overseer.create_constructor()
	if(overseer.next_constructor <= previous_cooldown)
		return FALSE
	StartCooldownSelf()
	return TRUE

/datum/action/cooldown/flood/create_carrier
	name = "Create Flood Carrier"
	desc = "Bud off a Flood Carrier every 120 seconds."
	button_icon = 'icons/mob/flood/flood_carrier.dmi'
	button_icon_state = "static"
	cooldown_time = 120 SECONDS

/datum/action/cooldown/flood/create_carrier/Activate(atom/target)
	var/mob/living/basic/flood/overseer/overseer = owner
	if(!overseer.create_carrier())
		return FALSE
	StartCooldownSelf()
	return TRUE

/datum/action/cooldown/flood/direct_growth
	name = "Direct Infestation Growth"
	desc = "Spread Flood biomass across nearby floor tiles."
	button_icon_state = "biomass2"
	cooldown_time = 30 SECONDS

/datum/action/cooldown/flood/direct_growth/Activate(atom/target)
	var/mob/living/basic/flood/overseer/overseer = owner
	var/previous_cooldown = overseer.next_direct_growth
	overseer.direct_growth()
	if(overseer.next_direct_growth <= previous_cooldown)
		return FALSE
	StartCooldownSelf()
	return TRUE

/datum/action/cooldown/flood/toggle_overseer_mode
	name = "Toggle Overseer Mode"
	desc = "Survey connected Flood growth and middle-click to direct nearby AI units."
	button_icon = 'icons/mob/flood/flood_constructor_builder.dmi'
	button_icon_state = "designator"

/datum/action/cooldown/flood/toggle_overseer_mode/Activate(atom/target)
	var/mob/living/basic/flood/overseer/overseer = owner
	overseer.toggle_overseer_mode()
	return TRUE
