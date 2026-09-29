/// Map-placed and spreading Flood growth share a real floor turf. Runtime
/// growth is layered over the existing floor, so scraping restores that tile.
/turf/open/floor/flood_biomass
	name = "Flood biomass"
	desc = "Pulsating biomass writhes beneath your feet."
	icon = 'icons/turf/floors/flood_floor.dmi'
	icon_state = "floor"
	base_icon_state = "floor"
	resistance_flags = ACID_PROOF
	damaged_dmi = null
	slowdown = 0.2
	/// Planted floors act like xeno weed nodes; floors they spread stay tied to that node.
	var/turf/open/floor/flood_biomass/parent_seed
	var/spread_range = 3
	var/next_spread = 0

/turf/open/floor/flood_biomass/Initialize(mapload)
	. = ..()
	parent_seed = src
	next_spread = world.time + rand(5 SECONDS, 10 SECONDS)
	START_PROCESSING(SSobj, src)
	if(prob(35))
		var/image/spore = image(icon = 'icons/obj/flood/flood_bio.dmi', icon_state = "animated[rand(1, 6)]")
		spore.pixel_x = rand(-8, 8)
		spore.pixel_y = rand(-8, 8)
		add_overlay(spore)

/turf/open/floor/flood_biomass/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(parent_seed && parent_seed != src)
		UnregisterSignal(parent_seed, COMSIG_QDELETING)
	parent_seed = null
	return ..()

/// A planted tile expands through adjacent, air-connected floors within three tiles.
/turf/open/floor/flood_biomass/process()
	if(parent_seed != src || world.time < next_spread)
		return
	next_spread = world.time + rand(5 SECONDS, 10 SECONDS)
	for(var/turf/open/floor/flood_biomass/growing_floor in range(spread_range, src))
		if(growing_floor.parent_seed != src)
			continue
		for(var/turf/open/floor/neighbor in growing_floor.get_atmos_adjacent_turfs())
			if(neighbor.z != z || get_dist(src, neighbor) > spread_range || !can_grow_flood_floor(neighbor))
				continue
			grow_flood_floor(neighbor, src)

/turf/open/floor/flood_biomass/proc/set_parent_seed(turf/open/floor/flood_biomass/new_seed)
	if(parent_seed == new_seed)
		return
	if(parent_seed && parent_seed != src)
		UnregisterSignal(parent_seed, COMSIG_QDELETING)
	parent_seed = new_seed
	STOP_PROCESSING(SSobj, src)
	RegisterSignal(new_seed, COMSIG_QDELETING, PROC_REF(on_parent_seed_removed))

/turf/open/floor/flood_biomass/proc/on_parent_seed_removed()
	SIGNAL_HANDLER
	var/turf/open/floor/flood_biomass/old_seed = parent_seed
	parent_seed = null
	for(var/turf/open/floor/flood_biomass/new_seed in range(spread_range, src))
		if(new_seed == old_seed || QDELETED(new_seed) || new_seed.parent_seed != new_seed)
			continue
		set_parent_seed(new_seed)
		return
	addtimer(CALLBACK(src, PROC_REF(wither_without_seed)), rand(2 SECONDS, 8 SECONDS))

/turf/open/floor/flood_biomass/proc/wither_without_seed()
	if(!parent_seed && !QDELETED(src))
		ScrapeAway(flags = CHANGETURF_INHERIT_AIR)

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

/proc/grow_flood_floor(turf/target, turf/open/floor/flood_biomass/parent_seed)
	if(!can_grow_flood_floor(target))
		return FALSE
	var/turf/open/floor/flood_biomass/new_floor = target.place_on_top(/turf/open/floor/flood_biomass, flags = CHANGETURF_INHERIT_AIR)
	if(!istype(new_floor))
		return FALSE
	if(parent_seed && !QDELETED(parent_seed))
		new_floor.set_parent_seed(parent_seed)
	return new_floor
