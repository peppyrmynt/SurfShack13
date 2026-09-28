/// Landmarks and map-placed Flood encounters.

GLOBAL_LIST_EMPTY(flood_patrol_targets)
GLOBAL_LIST_EMPTY(flood_assault_targets)

/// Map-placed counterpart to the original Flood proximity spawner.
/// Mappers can set spawn_spot_x/y to release the swarm somewhere else on this z-level.
/obj/effect/landmark/flood_ambush
	name = "Flood ambush marker"
	var/spawn_spot_x = 0
	var/spawn_spot_y = 0
	var/triggered = FALSE

/obj/effect/landmark/flood_ambush/Initialize(mapload)
	. = ..()
	var/static/list/loc_connections = list(COMSIG_ATOM_ENTERED = PROC_REF(on_entered))
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/effect/landmark/flood_ambush/proc/on_entered(datum/source, atom/movable/crossed_atom)
	SIGNAL_HANDLER
	if(triggered || !ishuman(crossed_atom))
		return
	var/mob/living/carbon/human/host = crossed_atom
	if(host.mind?.has_antag_datum(/datum/antagonist/flood))
		return
	triggered = TRUE
	addtimer(CALLBACK(src, PROC_REF(release_ambush)), rand(10, 30))

/obj/effect/landmark/flood_ambush/proc/release_ambush()
	var/turf/spawn_turf = get_turf(src)
	if(spawn_spot_x && spawn_spot_y)
		var/turf/marked_turf = locate(spawn_spot_x, spawn_spot_y, z)
		if(isopenturf(marked_turf) && !isspaceturf(marked_turf))
			spawn_turf = marked_turf
	if(!isopenturf(spawn_turf) || isspaceturf(spawn_turf))
		qdel(src)
		return
	playsound(spawn_turf, 'sound/effects/grillehit.ogg', 80, TRUE)
	spawn_turf.visible_message(span_danger("Flood infection forms erupt from the surrounding biomass!"))
	for(var/i in 1 to 8)
		new /mob/living/basic/flood/infestor(spawn_turf)
	qdel(src)

/// A mapper can place several of these to give NPC combat and builder forms
/// a route through a nest. Infestors continue seeking human hosts.
/obj/effect/landmark/flood_patrol_target
	name = "Flood patrol target"
	icon = 'icons/mob/flood/flood_combat_human.dmi'
	icon_state = "maptrigger"
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/landmark/flood_patrol_target/Initialize(mapload)
	. = ..()
	GLOB.flood_patrol_targets += src

/obj/effect/landmark/flood_patrol_target/Destroy()
	GLOB.flood_patrol_targets -= src
	return ..()

/// An optional map objective for idle NPC Flood. These take priority over
/// patrol points, but a living target always takes priority over the route.
/obj/effect/landmark/assault_target/flood
	name = "Flood assault target"
	icon = 'icons/mob/flood/flood_combat_human.dmi'
	icon_state = "spawntrigger"
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/landmark/assault_target/flood/Initialize(mapload)
	. = ..()
	GLOB.flood_assault_targets += src

/obj/effect/landmark/assault_target/flood/Destroy()
	GLOB.flood_assault_targets -= src
	return ..()

/// A map-placed ghost entry point for a human Flood combat form.
/obj/effect/mob_spawn/ghost_role/flood
	name = "Flood biomass cocoon"
	desc = "A humanoid shape twists within this pulsating mass."
	icon = 'icons/obj/flood/flood_bio.dmi'
	icon_state = "pulsating"
	density = FALSE
	mob_type = /mob/living/basic/flood/combat_form/human
	role_ban = ROLE_FLOOD
	prompt_name = "Flood combat form"
	you_are_text = "You are a Flood combat form."
	flavour_text = "Spread the infestation with infection forms. Your human hands can use ordinary station equipment and weapons."
	important_text = "Infection forms hurt living hosts. Only forms latched to dead humans for five seconds can convert them."

/obj/effect/mob_spawn/ghost_role/flood/special(mob/living/spawned_mob, mob/mob_possessor)
	. = ..()
	if(spawned_mob.mind)
		if(!spawned_mob.mind.has_antag_datum(/datum/antagonist/flood))
			spawned_mob.mind.add_antag_datum(/datum/antagonist/flood)
		spawned_mob.mind.special_role = ROLE_FLOOD
