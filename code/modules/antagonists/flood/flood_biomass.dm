/// A mapper can give a Flood nest its own ambience without changing the
/// station's usual area sounds or broadcasting from every biomass growth.
GLOBAL_LIST_EMPTY(flood_growth_countdowns)
GLOBAL_LIST_EMPTY(flood_mob_growths)

/obj/effect/countdown/flood_growth
	name = "Flood growth countdown"
	color = "#E0CC49"
	pixel_x = 22
	var/image/flood_display

/obj/effect/countdown/flood_growth/Initialize(mapload)
	. = ..()
	flood_display = image(loc = get_turf(src), layer = ABOVE_ALL_MOB_LAYER)
	flood_display.plane = GHOST_PLANE
	flood_display.color = color
	flood_display.pixel_x = pixel_x
	flood_display.maptext_width = 32
	GLOB.flood_growth_countdowns += src
	for(var/mob/living/basic/flood/ally in GLOB.mob_living_list)
		if(ally.client)
			ally.client.images += flood_display

/obj/effect/countdown/flood_growth/get_value()
	var/obj/structure/flood_biomass/growth = attached_to
	if(!istype(growth))
		return
	return round(max(0, (growth.next_spawn - world.time) / 10))

/obj/effect/countdown/flood_growth/process()
	. = ..()
	if(!QDELETED(src) && flood_display)
		flood_display.maptext = maptext

/obj/effect/countdown/flood_growth/Destroy()
	GLOB.flood_growth_countdowns -= src
	for(var/client/viewer as anything in GLOB.clients)
		viewer.images -= flood_display
	flood_display = null
	return ..()

/area/ruin/unpowered/flood_nest
	name = "Flood nest"
	ambientsounds = list('sound/flood/flood_ambience.ogg')
	ambient_buzz = null
	min_ambience_cooldown = 70 SECONDS
	max_ambience_cooldown = 100 SECONDS

/// Source spore props for decorating map-placed Flood terrain.
/obj/effect/flood_spore
	name = "Flood spores"
	desc = "Patches of alien spores cling to the ground."
	icon = 'icons/obj/flood/flood_bio.dmi'
	icon_state = "spore1"
	anchored = TRUE
	layer = MID_TURF_LAYER
	plane = FLOOR_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/spore_prefix = "spore"
	var/spore_variants = 8

/obj/effect/flood_spore/Initialize(mapload)
	. = ..()
	icon_state = "[spore_prefix][rand(1, spore_variants)]"
	pixel_x = rand(-8, 8)
	pixel_y = rand(-8, 8)

/obj/effect/flood_spore/growing
	name = "growing Flood spores"
	icon_state = "animated1"
	spore_prefix = "animated"
	spore_variants = 6

/obj/structure/flood_biomass
	name = "Flood biomass"
	desc = "A pulsating mass of alien flesh."
	icon = 'icons/obj/flood/flood_bio.dmi'
	icon_state = "spore1"
	anchored = TRUE
	density = FALSE
	layer = MID_TURF_LAYER
	plane = FLOOR_PLANE
	max_integrity = 400
	resistance_flags = ACID_PROOF
	var/next_spawn = 0
	var/spawn_delay = 60 SECONDS
	var/max_nearby_flood = 6
	var/max_nearby_growth = 12
	var/next_spread = 0
	var/spread_delay = 30 SECONDS
	/// Visible growths vent miasma and zauker into the surrounding air.
	var/next_miasma = 0
	var/miasma_delay = 10 SECONDS
	var/next_zauker = 0
	var/zauker_delay = 30 SECONDS
	/// A ready growth shudders for three seconds before releasing a unit.
	var/spawn_warning_sent = FALSE
	/// Map-placed nests start with a small wave, as in the source spawner.
	var/initial_spawn_count = 2
	var/list/spawn_pool = list(
		/mob/living/basic/flood/carrier = 80,
		/mob/living/basic/flood/combat_form/human = 20,
	)
	/// Tracks this biomass's living offspring even after they leave the area.
	var/list/spawned_flood = list()
	var/obj/effect/countdown/flood_growth/countdown

/obj/structure/flood_biomass/Initialize(mapload)
	. = ..()
	GLOB.flood_mob_growths += src
	icon_state = "spore[rand(1, 8)]"
	next_spawn = world.time + spawn_delay
	next_spread = world.time + spread_delay
	next_miasma = world.time + rand(1, miasma_delay)
	next_zauker = world.time + rand(1, zauker_delay)
	if(!istype(src, /obj/structure/flood_biomass/hidden))
		countdown = new(src)
		countdown.start()
	START_PROCESSING(SSobj, src)
	if(mapload && initial_spawn_count)
		addtimer(CALLBACK(src, PROC_REF(spawn_initial_wave)), rand(1, 3) SECONDS)

/obj/structure/flood_biomass/Destroy()
	STOP_PROCESSING(SSobj, src)
	GLOB.flood_mob_growths -= src
	QDEL_NULL(countdown)
	for(var/mob/living/basic/flood/offspring as anything in spawned_flood)
		UnregisterSignal(offspring, list(COMSIG_LIVING_DEATH, COMSIG_QDELETING))
	spawned_flood = null
	return ..()

/obj/structure/flood_biomass/process()
	if(world.time >= next_miasma)
		next_miasma = world.time + miasma_delay
		if(invisibility < INVISIBILITY_ABSTRACT)
			var/turf/open/growth_turf = get_turf(src)
			if(istype(growth_turf) && !isspaceturf(growth_turf))
				growth_turf.atmos_spawn_air("[GAS_MIASMA]=1")
	if(world.time >= next_zauker)
		next_zauker = world.time + zauker_delay
		if(invisibility < INVISIBILITY_ABSTRACT)
			var/turf/open/growth_turf = get_turf(src)
			if(istype(growth_turf) && !isspaceturf(growth_turf))
				growth_turf.atmos_spawn_air("[GAS_ZAUKER]=0.5")

	if(world.time >= next_spread)
		next_spread = world.time + spread_delay
		spread_growth()

	if(!spawn_warning_sent && invisibility < INVISIBILITY_ABSTRACT && world.time >= next_spawn - 3 SECONDS && can_spawn_flood())
		spawn_warning_sent = TRUE
		next_spawn = max(next_spawn, world.time + 3 SECONDS)
		show_spawn_warning()
	if(world.time < next_spawn)
		return
	spawn_warning_sent = FALSE
	next_spawn = world.time + spawn_delay
	spawn_flood()

/obj/structure/flood_biomass/proc/show_spawn_warning()
	visible_message(span_warning("[src] swells and shudders, about to release something!"))
	animate(src, pixel_x = 2, time = 0.2 SECONDS, flags = ANIMATION_PARALLEL | ANIMATION_RELATIVE)
	animate(pixel_x = -4, time = 0.2 SECONDS, flags = ANIMATION_RELATIVE)
	animate(pixel_x = 4, time = 0.2 SECONDS, flags = ANIMATION_RELATIVE)
	animate(pixel_x = -2, time = 0.2 SECONDS, flags = ANIMATION_RELATIVE)

/obj/structure/flood_biomass/proc/spawn_initial_wave(warned = FALSE)
	if(!warned && invisibility < INVISIBILITY_ABSTRACT && can_spawn_flood())
		show_spawn_warning()
		addtimer(CALLBACK(src, PROC_REF(spawn_initial_wave), TRUE), 3 SECONDS)
		return
	for(var/i in 1 to initial_spawn_count)
		if(!spawn_flood())
			return

/obj/structure/flood_biomass/proc/can_spawn_flood()
	if(length(spawned_flood) >= max_nearby_flood || flood_ai_population() >= FLOOD_AI_POPULATION_CAP)
		return FALSE

	var/nearby_flood = 0
	for(var/mob/living/basic/flood/flood_form in range(7, src))
		if(flood_form.stat != DEAD)
			nearby_flood++
			if(nearby_flood >= max_nearby_flood)
				return FALSE

	var/turf/spawn_turf = get_turf(src)
	if(!isopenturf(spawn_turf) || isspaceturf(spawn_turf))
		return FALSE
	return TRUE

/obj/structure/flood_biomass/proc/spawn_flood()
	if(!can_spawn_flood())
		return FALSE
	var/turf/spawn_turf = get_turf(src)
	var/spawn_type = pick_weight(spawn_pool)
	var/mob/living/basic/flood/new_flood = flood_try_spawn_ai(spawn_type, spawn_turf)
	if(!new_flood)
		return FALSE
	spawned_flood += new_flood
	RegisterSignals(new_flood, list(COMSIG_LIVING_DEATH, COMSIG_QDELETING), PROC_REF(on_spawned_flood_lost))
	if(invisibility < INVISIBILITY_ABSTRACT)
		visible_message(span_warning("[src] writhes and produces [new_flood]."))
	return TRUE

/obj/structure/flood_biomass/proc/on_spawned_flood_lost(mob/living/basic/flood/offspring)
	SIGNAL_HANDLER
	if(!(offspring in spawned_flood))
		return
	spawned_flood -= offspring
	UnregisterSignal(offspring, list(COMSIG_LIVING_DEATH, COMSIG_QDELETING))
	next_spawn = world.time + spawn_delay
	spawn_warning_sent = FALSE

/obj/structure/flood_biomass/proc/spread_growth()
	var/nearby_growth = 0
	for(var/turf/open/floor/flood_biomass/existing_growth in range(4, src))
		nearby_growth++
		if(nearby_growth >= max_nearby_growth)
			return

	var/list/valid_turfs = list()
	for(var/turf/open/floor/candidate in range(1, src))
		if(candidate == loc || !can_grow_flood_floor(candidate))
			continue
		valid_turfs += candidate

	if(!length(valid_turfs))
		return

	grow_flood_floor(pick(valid_turfs))

/obj/structure/flood_biomass/take_damage(damage_amount, damage_type = BRUTE, damage_flag = "", sound_effect = TRUE, attack_dir, armour_penetration = 0)
	if(damage_type == BURN)
		damage_amount *= 2
	return ..(damage_amount, damage_type, damage_flag, sound_effect, attack_dir, armour_penetration)

/obj/structure/flood_biomass/examine(mob/user)
	. = ..()
	var/health_ratio = get_integrity() / max_integrity
	if(health_ratio > 0.66)
		. += span_notice("It looks very healthy.")
	else if(health_ratio > 0.33)
		. += span_notice("It looks damaged.")
	else
		. += span_warning("It is heavily damaged!")

/obj/structure/flood_biomass/tiny
	name = "Flood growth"
	icon = 'icons/obj/flood/flood_bio.dmi'
	icon_state = "pulsating"
	max_integrity = 250
	spawn_delay = 90 SECONDS
	max_nearby_flood = 3
	initial_spawn_count = 1

/// Invisible map spawner adapted from the original Flood spawn landmark.
/obj/structure/flood_biomass/hidden
	name = "hidden Flood spawn marker"
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	resistance_flags = INDESTRUCTIBLE
	max_nearby_flood = 10
	var/disable_when_explored = FALSE

/obj/structure/flood_biomass/hidden/process()
	if(disable_when_explored)
		for(var/mob/living/carbon/human/explorer in range(6, src))
			if(explorer.stat != DEAD && !explorer.mind?.has_antag_datum(/datum/antagonist/flood))
				qdel(src)
				return
	return ..()

/obj/structure/flood_biomass/hidden/spread_growth()
	return

/obj/structure/flood_biomass/hidden/explorable
	disable_when_explored = TRUE

/// A visible patch of spores that releases infection forms when a human walks through it.
/obj/structure/flood_spore_trap
	name = "Flood spore cluster"
	desc = "A tense knot of spores woven into the floor growth."
	icon = 'icons/obj/flood/flood_bio.dmi'
	icon_state = "pulsating"
	anchored = TRUE
	density = FALSE
	max_integrity = 80
	layer = ABOVE_OPEN_TURF_LAYER
	plane = FLOOR_PLANE
	var/triggered = FALSE

/obj/structure/flood_spore_trap/Initialize(mapload)
	. = ..()
	var/static/list/loc_connections = list(COMSIG_ATOM_ENTERED = PROC_REF(on_entered))
	AddElement(/datum/element/connect_loc, loc_connections)

/obj/structure/flood_spore_trap/proc/on_entered(datum/source, atom/movable/crossed_atom)
	SIGNAL_HANDLER
	if(triggered || !ishuman(crossed_atom))
		return
	var/mob/living/carbon/human/host = crossed_atom
	if(host.mind?.has_antag_datum(/datum/antagonist/flood))
		return
	triggered = TRUE
	visible_message(span_danger("[src] swells as [host] steps into it!"))
	addtimer(CALLBACK(src, PROC_REF(release_spores)), 2 SECONDS)

/obj/structure/flood_spore_trap/proc/release_spores()
	var/turf/spawn_turf = get_turf(src)
	if(!spawn_turf)
		return
	if(flood_ai_population() >= FLOOD_AI_POPULATION_CAP)
		triggered = FALSE
		return
	playsound(spawn_turf, 'sound/effects/splat.ogg', 50, TRUE)
	var/released = 0
	for(var/i in 1 to 4)
		if(!flood_try_spawn_ai(/mob/living/basic/flood/infestor, spawn_turf))
			break
		released++
	visible_message(span_warning("[src] bursts, releasing [released] Flood Infectors!"))
	qdel(src)
