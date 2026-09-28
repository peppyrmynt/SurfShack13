/// Environmental pieces used by the Flood infestation.
///
/// These are SurfShack-native turfs and structures using the visual assets from the
/// original HaloSpaceStation13 implementation.

GLOBAL_LIST_EMPTY(flood_patrol_targets)
GLOBAL_LIST_EMPTY(flood_assault_targets)

/obj/effect/temp_visual/flood_carrier_burst
	icon = 'icons/mob/flood/flood_carrier_old.dmi'
	icon_state = "burst"
	duration = 0.4 SECONDS

/// A mapper can give a Flood nest its own ambience without changing the
/// station's usual area sounds or broadcasting from every biomass growth.
/area/ruin/unpowered/flood_nest
	name = "Flood nest"
	ambientsounds = list('sound/flood/flood_ambience.ogg')
	ambient_buzz = null
	min_ambience_cooldown = 70 SECONDS
	max_ambience_cooldown = 100 SECONDS

/// Map-placed and spreading Flood growth share a real floor turf. Runtime
/// growth is layered over the existing floor, so scraping restores that tile.
/turf/open/floor/flood_biomass
	name = "Flood biomass"
	desc = "Pulsating biomass writhes beneath your feet."
	icon = 'icons/mob/flood/flood_floor.dmi'
	icon_state = "floor"
	base_icon_state = "floor"
	resistance_flags = ACID_PROOF
	damaged_dmi = null

/turf/open/floor/flood_biomass/Initialize(mapload)
	. = ..()
	if(prob(35))
		var/image/spore = image(icon = 'icons/mob/flood/flood_bio.dmi', icon_state = "animated[rand(1, 6)]")
		spore.pixel_x = rand(-8, 8)
		spore.pixel_y = rand(-8, 8)
		add_overlay(spore)

/turf/open/floor/flood_biomass/break_tile()
	ScrapeAway(flags = CHANGETURF_INHERIT_AIR)

/turf/open/floor/flood_biomass/welder_act(mob/living/user, obj/item/I)
	if(I.use_tool(src, user, 2 SECONDS, volume = 50) && istype(src, /turf/open/floor/flood_biomass))
		visible_message(span_notice("[user] burns the Flood growth away from [src]."))
		ScrapeAway(flags = CHANGETURF_INHERIT_AIR)
	return TRUE

/turf/open/floor/flood_biomass/burn_tile()
	ScrapeAway(flags = CHANGETURF_INHERIT_AIR)

/// Spread biomass over a floor while preserving the previous floor beneath it.
/proc/can_grow_flood_floor(turf/target)
	return isfloorturf(target) && !istype(target, /turf/open/floor/flood_biomass) && !(target.resistance_flags & INDESTRUCTIBLE)

/proc/grow_flood_floor(turf/target)
	if(!can_grow_flood_floor(target))
		return FALSE
	target.place_on_top(/turf/open/floor/flood_biomass, flags = CHANGETURF_INHERIT_AIR)
	return TRUE

/// Source spore props for decorating map-placed Flood terrain.
/obj/effect/flood_spore
	name = "Flood spores"
	desc = "Patches of alien spores cling to the ground."
	icon = 'icons/mob/flood/flood_bio.dmi'
	icon_state = "spore1"
	anchored = TRUE
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
	icon = 'icons/mob/flood/flood_bio.dmi'
	icon_state = "spore1"
	anchored = TRUE
	density = FALSE
	max_integrity = 400
	resistance_flags = ACID_PROOF
	var/next_spawn = 0
	var/spawn_delay = 60 SECONDS
	var/max_nearby_flood = 6
	var/max_nearby_growth = 12
	var/next_spread = 0
	var/spread_delay = 30 SECONDS
	/// Map-placed nests start with a small wave, as in the source spawner.
	var/initial_spawn_count = 2
	var/list/spawn_pool = list(
		/mob/living/basic/flood/carrier,
		/mob/living/basic/flood/combat_form/human,
	)
	/// Tracks this biomass's living offspring even after they leave the area.
	var/list/spawned_flood = list()

/obj/structure/flood_biomass/Initialize(mapload)
	. = ..()
	icon_state = "spore[rand(1, 8)]"
	next_spawn = world.time + spawn_delay
	next_spread = world.time + spread_delay
	START_PROCESSING(SSobj, src)
	if(mapload && initial_spawn_count)
		addtimer(CALLBACK(src, PROC_REF(spawn_initial_wave)), rand(1, 3) SECONDS)

/obj/structure/flood_biomass/Destroy()
	STOP_PROCESSING(SSobj, src)
	for(var/mob/living/basic/flood/offspring as anything in spawned_flood)
		UnregisterSignal(offspring, list(COMSIG_LIVING_DEATH, COMSIG_QDELETING))
	spawned_flood = null
	return ..()

/obj/structure/flood_biomass/process()
	if(world.time >= next_spread)
		next_spread = world.time + spread_delay
		spread_growth()

	if(world.time < next_spawn)
		return
	next_spawn = world.time + spawn_delay
	spawn_flood()

/obj/structure/flood_biomass/proc/spawn_initial_wave()
	for(var/i in 1 to initial_spawn_count)
		if(!spawn_flood())
			return

/obj/structure/flood_biomass/proc/spawn_flood()
	if(length(spawned_flood) >= max_nearby_flood)
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

	var/spawn_type = pick(spawn_pool)
	var/mob/living/basic/flood/new_flood = new spawn_type(spawn_turf)
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

/obj/structure/flood_biomass/medium
	name = "large Flood biomass"
	icon = 'icons/mob/flood/flood_bio_med.dmi'
	icon_state = "biomass1"
	max_integrity = 600
	spawn_delay = 50 SECONDS
	max_nearby_flood = 10
	max_nearby_growth = 20
	spread_delay = 20 SECONDS
	initial_spawn_count = 3

/obj/structure/flood_biomass/medium/Initialize(mapload)
	. = ..()
	icon_state = pick(icon_states(icon))

/obj/structure/flood_biomass/large
	name = "massive Flood biomass"
	icon = 'icons/mob/flood/flood_bio_large.dmi'
	icon_state = "biomass1"
	max_integrity = 1500
	spawn_delay = 40 SECONDS
	max_nearby_flood = 15
	max_nearby_growth = 32
	spread_delay = 10 SECONDS
	initial_spawn_count = 4

/obj/structure/flood_biomass/large/Initialize(mapload)
	. = ..()
	icon_state = pick(icon_states(icon))

/obj/structure/flood_biomass/tiny
	name = "Flood growth"
	icon = 'icons/mob/flood/flood_bio.dmi'
	icon_state = "pulsating"
	max_integrity = 250
	spawn_delay = 90 SECONDS
	max_nearby_flood = 3
	initial_spawn_count = 1
	spawn_pool = list(/mob/living/basic/flood/combat_form/human)

/// A mapper-placed prison outbreak uses the source's human prisoner and crew
/// forms without changing the forms grown by constructors elsewhere.
/obj/structure/flood_biomass/tiny/prison
	spawn_pool = list(
		/mob/living/basic/flood/combat_form/human/prisoner,
		/mob/living/basic/flood/combat_form/human/crew,
	)

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
	icon = 'icons/mob/flood/flood_bio.dmi'
	icon_state = "pulsating"
	anchored = TRUE
	density = FALSE
	max_integrity = 80
	layer = ABOVE_OPEN_TURF_LAYER
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
	playsound(spawn_turf, 'sound/effects/splat.ogg', 50, TRUE)
	visible_message(span_warning("[src] bursts, releasing Flood infection forms!"))
	for(var/i in 1 to 4)
		new /mob/living/basic/flood/infestor(spawn_turf)
	qdel(src)

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
/// a route through a nest. Infestors continue seeking vulnerable hosts.
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
	icon = 'icons/mob/flood/flood_bio.dmi'
	icon_state = "pulsating"
	density = FALSE
	mob_type = /mob/living/basic/flood/combat_form/human
	role_ban = ROLE_FLOOD
	prompt_name = "Flood combat form"
	you_are_text = "You are a Flood combat form."
	flavour_text = "Spread the infestation with infection forms. Your human hands can use ordinary station equipment and weapons."
	important_text = "Only infection forms that remain latched to a vulnerable host can convert them."

/obj/effect/mob_spawn/ghost_role/flood/special(mob/living/spawned_mob, mob/mob_possessor)
	. = ..()
	if(spawned_mob.mind)
		spawned_mob.mind.add_antag_datum(/datum/antagonist/flood)
		spawned_mob.mind.special_role = ROLE_FLOOD

/// A constructor can build this solid barrier on an open floor tile.
/obj/structure/flood_wall
	name = "Flood biomass wall"
	desc = "A solid barrier of hardened, pulsating Flood tissue."
	icon = 'icons/mob/flood/Flood_Spore.dmi'
	icon_state = "flood wall gif"
	anchored = TRUE
	density = TRUE
	opacity = TRUE
	layer = WALL_OBJ_LAYER
	max_integrity = 300
	can_atmos_pass = ATMOS_PASS_DENSITY

/obj/structure/flood_wall/Initialize(mapload)
	. = ..()
	air_update_turf(TRUE, TRUE)

/obj/structure/flood_wall/Destroy()
	air_update_turf(TRUE, FALSE)
	return ..()

/obj/structure/flood_wall/take_damage(damage_amount, damage_type = BRUTE, damage_flag = "", sound_effect = TRUE, attack_dir, armour_penetration = 0)
	if(damage_type == BURN)
		damage_amount *= 2
	return ..(damage_amount, damage_type, damage_flag, sound_effect, attack_dir, armour_penetration)

/obj/structure/flood_door
	name = "Flood biomass door"
	desc = "A fleshy membrane capable of sealing an infested passage."
	icon = 'icons/mob/flood/flood_door.dmi'
	icon_state = "flood"
	anchored = TRUE
	density = TRUE
	opacity = TRUE
	max_integrity = 350
	layer = CLOSED_DOOR_LAYER
	can_atmos_pass = ATMOS_PASS_DENSITY
	var/door_opened = FALSE
	var/close_delay = 5 SECONDS

/obj/structure/flood_door/Initialize(mapload)
	. = ..()
	air_update_turf(TRUE, TRUE)

/obj/structure/flood_door/Destroy()
	if(!door_opened)
		air_update_turf(TRUE, FALSE)
	return ..()

/obj/structure/flood_door/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	if(damage_type == BRUTE && damage_amount)
		playsound(src, 'sound/flood/flood_hit_sfx.ogg', 50, TRUE)
	else
		return ..()

/obj/structure/flood_door/take_damage(damage_amount, damage_type = BRUTE, damage_flag = "", sound_effect = TRUE, attack_dir, armour_penetration = 0)
	if(damage_type == BURN)
		damage_amount *= 2
	return ..(damage_amount, damage_type, damage_flag, sound_effect, attack_dir, armour_penetration)

/obj/structure/flood_door/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(door_opened)
		close_door()
	else
		open_door()
	return TRUE

/obj/structure/flood_door/attack_paw(mob/user, list/modifiers)
	return attack_hand(user, modifiers)

/obj/structure/flood_door/Bumped(atom/movable/mover)
	. = ..()
	if(istype(mover, /mob/living/basic/flood) && !door_opened)
		open_door()

/obj/structure/flood_door/proc/open_door()
	if(door_opened)
		return
	door_opened = TRUE
	playsound(src, 'sound/flood/flood_open.ogg', 60, TRUE)
	flick("floodopening", src)
	icon_state = "floodopen"
	set_opacity(FALSE)
	set_density(FALSE)
	layer = OPEN_DOOR_LAYER
	air_update_turf(TRUE, FALSE)
	addtimer(CALLBACK(src, PROC_REF(close_door)), close_delay)

/obj/structure/flood_door/proc/close_door()
	if(!door_opened)
		return
	for(var/mob/living/occupant in get_turf(src))
		addtimer(CALLBACK(src, PROC_REF(close_door)), close_delay)
		return
	flick("floodclosing", src)
	icon_state = "flood"
	set_density(TRUE)
	set_opacity(TRUE)
	layer = CLOSED_DOOR_LAYER
	door_opened = FALSE
	air_update_turf(TRUE, TRUE)

/obj/structure/flood_door/CanAllowThrough(atom/movable/mover, border_dir)
	if(istype(mover, /mob/living/basic/flood))
		return TRUE
	return ..()

/obj/structure/flood_window
	name = "Flood biomass membrane"
	desc = "A translucent mesh of Flood tissue stretched across the passage."
	icon = 'icons/mob/flood/flood_window.dmi'
	icon_state = "flood_window"
	anchored = TRUE
	density = TRUE
	max_integrity = 80
	can_atmos_pass = ATMOS_PASS_YES

/obj/structure/flood_window/CanAllowThrough(atom/movable/mover, border_dir)
	. = ..()
	if(!. && isprojectile(mover))
		return prob(30)

/obj/structure/flood_window/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	if(damage_type == BRUTE && damage_amount)
		playsound(src, 'sound/flood/flood_hit_sfx.ogg', 50, TRUE)
	else
		return ..()

/obj/structure/flood_window/take_damage(damage_amount, damage_type = BRUTE, damage_flag = "", sound_effect = TRUE, attack_dir, armour_penetration = 0)
	if(damage_type == BURN)
		damage_amount *= 2
	return ..(damage_amount, damage_type, damage_flag, sound_effect, attack_dir, armour_penetration)

/mob/living/basic/flood/constructor
	name = "Flood constructor form"
	desc = "A specialized Flood form that converts its surroundings into infestation."
	icon = 'icons/mob/flood/flood_constructor_builder.dmi'
	icon_state = "constructor"
	icon_living = "constructor"
	icon_dead = "constructor_dead"
	maxHealth = 175
	health = 175
	melee_damage_lower = 5
	melee_damage_upper = 10
	var/next_build = 0
	var/next_biomass_upgrade = 0
	var/next_wall_build = 0
	var/next_auto_growth = 0
	var/next_auto_biomass = 0

/mob/living/basic/flood/constructor/Initialize(mapload)
	. = ..()
	next_auto_growth = world.time + rand(10, 20) SECONDS
	next_auto_biomass = world.time + 45 SECONDS

/mob/living/basic/flood/constructor/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. = ..()
	if(!. || stat == DEAD || client || world.time < next_auto_growth)
		return
	next_auto_growth = world.time + 20 SECONDS
	auto_grow()

/// NPC constructors spread floor growth, adding a small spawner only when
/// they have moved away from existing biomass.
/mob/living/basic/flood/constructor/proc/auto_grow()
	var/nearby_growth = 0
	for(var/turf/open/floor/flood_biomass/existing in range(4, src))
		nearby_growth++
	if(nearby_growth >= 10)
		return
	var/list/floor_candidates = list()
	for(var/turf/open/floor/candidate in range(1, src))
		if(candidate == loc || !can_grow_flood_floor(candidate))
			continue
		floor_candidates += candidate
	if(length(floor_candidates))
		var/turf/open/floor/target = pick(floor_candidates)
		if(world.time >= next_auto_biomass)
			var/nearby_biomass = 0
			for(var/obj/structure/flood_biomass/existing_biomass in range(4, src))
				nearby_biomass++
			if(!nearby_biomass && can_build(target, /obj/structure/flood_biomass))
				next_auto_biomass = world.time + 90 SECONDS
				new /obj/structure/flood_biomass/tiny(target)
				visible_message(span_warning("[src] plants a new knot of Flood biomass."))
				return
		if(can_build(target, /turf/open/floor/flood_biomass))
			grow_flood_floor(target)

/mob/living/basic/flood/constructor/proc/can_build(turf/target_turf, structure_type, solid = FALSE)
	if(stat == DEAD)
		return FALSE
	if(!isfloorturf(target_turf) || get_dist(src, target_turf) != 1)
		to_chat(src, span_warning("You need an adjacent floor to grow Flood tissue."))
		return FALSE
	if(structure_type == /turf/open/floor/flood_biomass)
		if(!can_grow_flood_floor(target_turf))
			to_chat(src, span_warning("Flood growth cannot cover that floor."))
			return FALSE
	else if(locate(structure_type) in target_turf)
		to_chat(src, span_warning("That tile already has this kind of Flood growth."))
		return FALSE
	if(structure_type == /obj/structure/flood_biomass)
		var/nearby_biomass = 0
		for(var/obj/structure/flood_biomass/biomass in range(4, target_turf))
			nearby_biomass++
			if(nearby_biomass >= 2)
				to_chat(src, span_warning("This area has enough biomass already."))
				return FALSE
	if(solid)
		if(locate(/obj/structure/flood_door) in target_turf || locate(/obj/structure/flood_window) in target_turf || locate(/obj/structure/flood_wall) in target_turf)
			to_chat(src, span_warning("A Flood structure already occupies that tile."))
			return FALSE
		for(var/atom/movable/obstacle in target_turf)
			if(obstacle.density)
				to_chat(src, span_warning("Something blocks the new Flood structure."))
				return FALSE
	if(world.time < next_build)
		to_chat(src, span_warning("Your biomass is still reshaping itself."))
		return FALSE
	next_build = world.time + 2 SECONDS
	return TRUE

/mob/living/basic/flood/constructor/proc/get_build_turf()
	return get_step(src, dir)

/mob/living/basic/flood/constructor/verb/grow_biomass()
	set name = "Grow Biomass"
	set category = "Flood"

	var/turf/target_turf = get_build_turf()
	if(!can_build(target_turf, /obj/structure/flood_biomass))
		return
	new /obj/structure/flood_biomass/tiny(target_turf)
	visible_message(span_warning("Flood biomass spreads outward beneath [src]."))

/mob/living/basic/flood/constructor/verb/expand_biomass()
	set name = "Expand Biomass"
	set category = "Flood"

	if(stat == DEAD || world.time < next_biomass_upgrade)
		return
	var/turf/target_turf = get_build_turf()
	if(!isopenturf(target_turf) || isspaceturf(target_turf))
		return
	var/obj/structure/flood_biomass/existing = locate(/obj/structure/flood_biomass) in target_turf
	if(!existing)
		to_chat(src, span_warning("Face an existing biomass growth to expand it."))
		return
	var/new_type
	if(istype(existing, /obj/structure/flood_biomass/tiny))
		new_type = /obj/structure/flood_biomass/medium
	else if(istype(existing, /obj/structure/flood_biomass/medium))
		new_type = /obj/structure/flood_biomass/large
	else
		to_chat(src, span_warning("That biomass cannot grow any larger."))
		return
	if(existing.get_integrity() < existing.max_integrity / 2)
		to_chat(src, span_warning("That biomass is too damaged to expand."))
		return
	next_biomass_upgrade = world.time + 60 SECONDS
	qdel(existing)
	new new_type(target_turf)
	visible_message(span_warning("Flood biomass surges and expands into a larger growth."))

/mob/living/basic/flood/constructor/verb/infest_floor()
	set name = "Infest Floor"
	set category = "Flood"

	var/turf/target_turf = get_build_turf()
	if(!can_build(target_turf, /turf/open/floor/flood_biomass))
		return
	grow_flood_floor(target_turf)
	visible_message(span_warning("Pulsating Flood tissue creeps across the floor."))

/mob/living/basic/flood/constructor/verb/grow_barrier()
	set name = "Grow Biomass Wall"
	set category = "Flood"

	if(world.time < next_wall_build)
		to_chat(src, span_warning("Your biomass is still recovering from growing a wall."))
		return
	var/turf/target_turf = get_build_turf()
	if(!can_build(target_turf, /obj/structure/flood_wall, TRUE))
		return
	next_wall_build = world.time + 15 SECONDS
	new /obj/structure/flood_wall(target_turf)
	visible_message(span_warning("[src] raises a solid wall of Flood biomass."))

/mob/living/basic/flood/constructor/verb/grow_door()
	set name = "Grow Biomass Door"
	set category = "Flood"

	var/turf/target_turf = get_build_turf()
	if(!can_build(target_turf, /obj/structure/flood_door, TRUE))
		return
	new /obj/structure/flood_door(target_turf)
	visible_message(span_warning("Flood tissue swells into a thick membrane."))

/mob/living/basic/flood/constructor/verb/grow_membrane()
	set name = "Grow Biomass Membrane"
	set category = "Flood"

	var/turf/target_turf = get_build_turf()
	if(!can_build(target_turf, /obj/structure/flood_window, TRUE))
		return
	new /obj/structure/flood_window(target_turf)
	visible_message(span_warning("A translucent Flood membrane hardens into place."))

/mob/living/basic/flood/constructor/verb/grow_spores()
	set name = "Grow Spore Cluster"
	set category = "Flood"

	var/turf/target_turf = get_build_turf()
	if(!can_build(target_turf, /obj/structure/flood_spore_trap))
		return
	var/nearby_traps = 0
	for(var/obj/structure/flood_spore_trap/trap in range(3, target_turf))
		nearby_traps++
		if(nearby_traps >= 2)
			to_chat(src, span_warning("This area already has enough spore clusters."))
			return
	new /obj/structure/flood_spore_trap(target_turf)
	visible_message(span_warning("[src] weaves a cluster of Flood spores across the floor."))

/mob/living/basic/flood/overseer
	name = "Flood overseer form"
	desc = "A specialized Flood form directing the spread of infestation."
	icon = 'icons/mob/flood/flood_constructor_builder.dmi'
	icon_state = "designator"
	icon_living = "designator"
	icon_dead = "designator_dead"
	maxHealth = 150
	health = 150
	melee_damage_lower = 5
	melee_damage_upper = 10
	var/next_constructor = 0
	var/next_direct_growth = 0
	var/next_assault = 0
	var/next_auto_direct = 0

/mob/living/basic/flood/overseer/Initialize(mapload)
	. = ..()
	next_auto_direct = world.time + rand(15, 25) SECONDS

/mob/living/basic/flood/overseer/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. = ..()
	if(!. || stat == DEAD || client || world.time < next_auto_direct)
		return
	next_auto_direct = world.time + 20 SECONDS
	direct_growth()
	if(world.time < next_constructor)
		return
	var/nearby_constructors = 0
	for(var/mob/living/basic/flood/constructor/ally in range(5, src))
		if(ally.stat != DEAD)
			nearby_constructors++
	if(nearby_constructors < 2)
		create_constructor()

/mob/living/basic/flood/overseer/verb/direct_assault()
	set name = "Direct Flood Assault"
	set category = "Flood"

	if(stat == DEAD || world.time < next_assault)
		return
	var/list/possible_targets = list()
	for(var/mob/living/carbon/human/candidate in view(7, src))
		if(candidate.stat != DEAD && !candidate.mind?.has_antag_datum(/datum/antagonist/flood))
			possible_targets += candidate
	if(!length(possible_targets))
		to_chat(src, span_warning("There is no human in sight to direct an assault against."))
		return
	var/mob/living/carbon/human/target = input(src, "Choose a human for the Flood to pursue.", "Flood Assault") as null|anything in possible_targets
	if(!target || stat == DEAD || target.stat == DEAD || target.mind?.has_antag_datum(/datum/antagonist/flood) || !(target in view(7, src)))
		return
	var/directed = 0
	for(var/mob/living/basic/flood/ally in range(7, src))
		if(ally == src || ally.client || ally.stat == DEAD || istype(ally, /mob/living/basic/flood/infestor) || !ally.ai_controller)
			continue
		if(!can_see(ally, target, 9))
			continue
		ally.ai_controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, target)
		directed++
	if(!directed)
		to_chat(src, span_warning("No nearby Flood forms can see that target."))
		return
	next_assault = world.time + 30 SECONDS
	visible_message(span_warning("[src] emits a commanding howl, directing the Flood toward [target]!"))

/mob/living/basic/flood/overseer/verb/create_constructor()
	set name = "Create Constructor Form"
	set category = "Flood"

	if(stat == DEAD)
		return
	if(world.time < next_constructor)
		to_chat(src, span_warning("Your biomass is not ready to form another constructor."))
		return
	next_constructor = world.time + 30 SECONDS
	new /mob/living/basic/flood/constructor(loc)
	visible_message(span_warning("[src] buds off a new Flood constructor form."))

/mob/living/basic/flood/overseer/verb/direct_growth()
	set name = "Direct Infestation Growth"
	set category = "Flood"

	if(stat == DEAD)
		return
	if(world.time < next_direct_growth)
		to_chat(src, span_warning("The nearby biomass has not recovered yet."))
		return

	next_direct_growth = world.time + 20 SECONDS
	var/created = 0
	for(var/turf/open/floor/target_turf in range(1, src))
		if(!grow_flood_floor(target_turf))
			continue
		created++
		if(created >= 3)
			break

	if(created)
		visible_message(span_warning("Flood growth surges outward under [src]'s direction."))
	else
		to_chat(src, span_warning("There is nowhere nearby for the infestation to spread."))
