/// Flood powers use the same HUD action system as xenomorph powers.
/datum/action/cooldown/flood
	panel = "Flood"
	background_icon_state = "bg_alien"
	overlay_icon_state = "bg_alien_border"
	button_icon = 'icons/mob/flood/flood_bio.dmi'
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

/datum/action/cooldown/flood/create_infestor
	name = "Create Infection Form"
	desc = "Bud off an infection form. Shares a recovery period with evolution."
	button_icon = 'icons/mob/flood/flood_infection.dmi'
	button_icon_state = "static"
	cooldown_time = 30 SECONDS

/datum/action/cooldown/flood/create_infestor/Activate(atom/target)
	var/mob/living/basic/flood/combat_form/combat_form = owner
	var/previous_cooldown = combat_form.next_evolution
	combat_form.create_infestor()
	if(combat_form.next_evolution <= previous_cooldown)
		return FALSE
	StartCooldownSelf()
	for(var/datum/action/cooldown/flood/evolve/evolution_action in combat_form.actions)
		evolution_action.StartCooldownSelf(cooldown_time)
	return TRUE

/datum/action/cooldown/flood/evolve
	name = "Evolve Flood Form"
	desc = "Choose a specialized Flood form."
	button_icon = 'icons/mob/flood/flood_combat_human.dmi'
	button_icon_state = "marine_infested"
	cooldown_time = 30 SECONDS

/datum/action/cooldown/flood/evolve/Activate(atom/target)
	var/mob/living/basic/flood/combat_form/combat_form = owner
	combat_form.evolve()
	return TRUE

/datum/action/cooldown/flood/reanimate
	name = "Reanimate Flood Corpse"
	desc = "Reanimate a nearby fallen Flood combat form."
	button_icon = 'icons/mob/flood/flood_infection.dmi'
	button_icon_state = "dead"

/datum/action/cooldown/flood/reanimate/Activate(atom/target)
	var/mob/living/basic/flood/infestor/infestor = owner
	return infestor.reanimate_nearby_flood(TRUE)

/datum/action/cooldown/flood/release_infection_forms
	name = "Release Infection Forms"
	desc = "Rupture and release a swarm of infection forms."
	button_icon = 'icons/mob/flood/flood_carrier.dmi'
	button_icon_state = "static"

/datum/action/cooldown/flood/release_infection_forms/Activate(atom/target)
	var/mob/living/basic/flood/carrier/carrier = owner
	carrier.release_infection_forms()
	return TRUE

/datum/action/cooldown/flood/grow_biomass
	name = "Grow Biomass"
	desc = "Grow a small biomass spawner on the floor ahead."
	button_icon_state = "biomass1"

/datum/action/cooldown/flood/grow_biomass/Activate(atom/target)
	var/mob/living/basic/flood/constructor/constructor = owner
	constructor.grow_biomass()
	return TRUE

/datum/action/cooldown/flood/infest_floor
	name = "Infest Floor"
	desc = "Cover the floor ahead with Flood biomass."
	button_icon = 'icons/mob/flood/flood_floor.dmi'
	button_icon_state = "floor"

/datum/action/cooldown/flood/infest_floor/Activate(atom/target)
	var/mob/living/basic/flood/constructor/constructor = owner
	constructor.infest_floor()
	return TRUE

/datum/action/cooldown/flood/grow_barrier
	name = "Grow Biomass Wall"
	desc = "Build a solid biomass wall on the floor ahead."
	button_icon = 'icons/mob/flood/Flood_Spore.dmi'
	button_icon_state = "flood wall gif"
	cooldown_time = 15 SECONDS

/datum/action/cooldown/flood/grow_barrier/Activate(atom/target)
	var/mob/living/basic/flood/constructor/constructor = owner
	var/previous_cooldown = constructor.next_wall_build
	constructor.grow_barrier()
	if(constructor.next_wall_build <= previous_cooldown)
		return FALSE
	StartCooldownSelf()
	return TRUE

/datum/action/cooldown/flood/grow_door
	name = "Grow Biomass Door"
	desc = "Build a Flood door on the floor ahead."
	button_icon = 'icons/mob/flood/flood_door.dmi'
	button_icon_state = "flood"

/datum/action/cooldown/flood/grow_door/Activate(atom/target)
	var/mob/living/basic/flood/constructor/constructor = owner
	constructor.grow_door()
	return TRUE

/datum/action/cooldown/flood/grow_membrane
	name = "Grow Biomass Membrane"
	desc = "Build a translucent Flood membrane on the floor ahead."
	button_icon = 'icons/mob/flood/flood_window.dmi'
	button_icon_state = "flood_window"

/datum/action/cooldown/flood/grow_membrane/Activate(atom/target)
	var/mob/living/basic/flood/constructor/constructor = owner
	constructor.grow_membrane()
	return TRUE

/datum/action/cooldown/flood/grow_spores
	name = "Grow Spore Cluster"
	desc = "Place a spore cluster on the floor ahead."
	button_icon_state = "spore1"

/datum/action/cooldown/flood/grow_spores/Activate(atom/target)
	var/mob/living/basic/flood/constructor/constructor = owner
	constructor.grow_spores()
	return TRUE

/datum/action/cooldown/flood/direct_assault
	name = "Direct Flood Assault"
	desc = "Command nearby Flood forms to pursue a human in sight."
	button_icon = 'icons/mob/flood/flood_combat_human.dmi'
	button_icon_state = "marine_infested"
	cooldown_time = 30 SECONDS

/datum/action/cooldown/flood/direct_assault/Activate(atom/target)
	var/mob/living/basic/flood/overseer/overseer = owner
	var/previous_cooldown = overseer.next_assault
	overseer.direct_assault()
	if(QDELETED(src) || QDELETED(overseer))
		return FALSE
	if(overseer.next_assault <= previous_cooldown)
		return FALSE
	StartCooldownSelf()
	return TRUE

/datum/action/cooldown/flood/create_constructor
	name = "Create Constructor Form"
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

/datum/action/cooldown/flood/direct_growth
	name = "Direct Infestation Growth"
	desc = "Spread Flood biomass across nearby floor tiles."
	button_icon_state = "biomass2"
	cooldown_time = 20 SECONDS

/datum/action/cooldown/flood/direct_growth/Activate(atom/target)
	var/mob/living/basic/flood/overseer/overseer = owner
	var/previous_cooldown = overseer.next_direct_growth
	overseer.direct_growth()
	if(overseer.next_direct_growth <= previous_cooldown)
		return FALSE
	StartCooldownSelf()
	return TRUE
