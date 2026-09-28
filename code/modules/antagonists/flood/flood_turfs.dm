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

/turf/open/floor/flood_biomass/Initialize(mapload)
	. = ..()
	if(prob(35))
		var/image/spore = image(icon = 'icons/obj/flood/flood_bio.dmi', icon_state = "animated[rand(1, 6)]")
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

