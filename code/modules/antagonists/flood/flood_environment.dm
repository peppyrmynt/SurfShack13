/// Environmental pieces used by the Flood infestation.
///
/// These are SurfShack-native structures using the visual assets from the
/// original HaloSpaceStation13 implementation.

/obj/structure/flood_biomass
	name = "Flood biomass"
	desc = "A pulsating mass of alien flesh."
	icon = 'icons/mob/flood/flood_bio.dmi'
	icon_state = "spore1"
	anchored = TRUE
	density = FALSE
	max_integrity = 400
	resistance_flags = ACID_PROOF

/obj/structure/flood_biomass/Initialize(mapload)
	. = ..()
	icon_state = "spore[rand(1, 8)]"

/obj/structure/flood_biomass/examine(mob/user)
	. = ..()
	var/health_ratio = get_integrity() / max_integrity
	if(health_ratio > 0.66)
		. += span_info("It looks very healthy.")
	else if(health_ratio > 0.33)
		. += span_notice("It looks damaged.")
	else
		. += span_warning("It is heavily damaged!")

/obj/structure/flood_biomass/medium
	name = "large Flood biomass"
	icon = 'icons/mob/flood/flood_bio_med.dmi'
	icon_state = "1"
	max_integrity = 600

/obj/structure/flood_biomass/medium/Initialize(mapload)
	. = ..()
	icon_state = pick(icon_states(icon))

/obj/structure/flood_biomass/large
	name = "massive Flood biomass"
	icon = 'icons/mob/flood/flood_bio_large.dmi'
	icon_state = "1"
	max_integrity = 1500

/obj/structure/flood_biomass/large/Initialize(mapload)
	. = ..()
	icon_state = pick(icon_states(icon))

/obj/structure/flood_biomass/tiny
	name = "Flood growth"
	icon = 'icons/mob/flood/flood_bio.dmi'
	icon_state = "pulsating"
	max_integrity = 250

/obj/structure/flood_growth
	name = "Flood growth"
	desc = "A thin layer of pulsating Flood biomass."
	icon = 'icons/mob/flood/flood_floor.dmi'
	icon_state = "floor"
	anchored = TRUE
	density = FALSE
	max_integrity = 100
	layer = ABOVE_OPEN_TURF_LAYER

/obj/structure/flood_wall_growth
	name = "Flood wall growth"
	desc = "Thick Flood biomass clings to the surrounding structure."
	icon = 'icons/mob/flood/flood_floor.dmi'
	icon_state = "flood"
	anchored = TRUE
	density = FALSE
	max_integrity = 250

/obj/structure/flood_door
	name = "Flood biomass door"
	desc = "A fleshy membrane capable of sealing an infested passage."
	icon = 'icons/mob/flood/flood_door.dmi'
	icon_state = "flood"
	anchored = TRUE
	density = TRUE
	opacity = TRUE
	max_integrity = 350

/obj/structure/flood_window
	name = "Flood biomass membrane"
	desc = "A translucent sheet of hardened Flood tissue."
	icon = 'icons/mob/flood/flood_window.dmi'
	icon_state = "flood"
	anchored = TRUE
	density = TRUE
	max_integrity = 200

/mob/living/simple_animal/hostile/flood/constructor
	name = "Flood constructor form"
	desc = "A specialized Flood form that converts its surroundings into infestation."
	icon = 'icons/mob/flood/flood_constructor_builder.dmi'
	icon_state = "constructor"
	maxHealth = 175
	health = 175
	melee_damage_lower = 5
	melee_damage_upper = 10

/mob/living/simple_animal/hostile/flood/constructor/verb/grow_biomass()
	set name = "Grow Biomass"
	set category = "Flood"

	if(stat == DEAD)
		return
	var/turf/target_turf = get_turf(src)
	if(locate(/obj/structure/flood_biomass) in target_turf)
		to_chat(src, span_warning("There is already substantial biomass here."))
		return
	new /obj/structure/flood_biomass/tiny(target_turf)
	visible_message(span_warning("Flood biomass spreads outward beneath [src]."))

/mob/living/simple_animal/hostile/flood/constructor/verb/infest_floor()
	set name = "Infest Floor"
	set category = "Flood"

	if(stat == DEAD)
		return
	var/turf/target_turf = get_turf(src)
	if(locate(/obj/structure/flood_growth) in target_turf)
		return
	new /obj/structure/flood_growth(target_turf)
	visible_message(span_warning("Pulsating Flood tissue creeps across the floor."))

/mob/living/simple_animal/hostile/flood/overseer
	name = "Flood overseer form"
	desc = "A specialized Flood form directing the spread of infestation."
	icon = 'icons/mob/flood/flood_constructor_builder.dmi'
	icon_state = "designator"
	maxHealth = 150
	health = 150
	melee_damage_lower = 5
	melee_damage_upper = 10

/mob/living/simple_animal/hostile/flood/overseer/verb/create_constructor()
	set name = "Create Constructor Form"
	set category = "Flood"

	if(stat == DEAD)
		return
	new /mob/living/simple_animal/hostile/flood/constructor(loc)
	visible_message(span_warning("[src] buds off a new Flood constructor form."))
