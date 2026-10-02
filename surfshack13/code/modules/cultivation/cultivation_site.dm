/**
 * Feng shui, station edition.
 *
 * Objects near a cultivation mat count towards one of the five elements. Each element caps out,
 * and identical objects stop counting after two, so a hundred floor tiles do not beat a sacred mountain.
 * The result is always explained in plain words so players know what to change (and saboteurs leave evidence).
 */

/// Max points any one element can contribute
#define SITE_ELEMENT_CAP 4
/// Max objects of one exact type that count
#define SITE_SAME_TYPE_CAP 2

GLOBAL_LIST_INIT(cultivation_element_sources, list(
	ELEMENT_WOOD = typecacheof(list(
		/obj/item/kirbyplants,
		/obj/item/food/grown,
		/obj/item/grown,
		/obj/structure/flora,
		/obj/item/stack/sheet/mineral/wood,
		/obj/item/stack/sheet/mineral/bamboo,
		/obj/structure/table/wood,
		/obj/machinery/hydroponics,
		/obj/structure/chair/wood,
	)),
	ELEMENT_FIRE = typecacheof(list(
		/obj/item/flashlight/flare/candle,
		/obj/structure/fireplace,
		/obj/structure/bonfire,
		/obj/machinery/space_heater,
		/obj/item/lighter,
		/obj/machinery/griddle,
		/obj/machinery/oven,
	)),
	ELEMENT_EARTH = typecacheof(list(
		/obj/item/stack/ore,
		/obj/item/stack/sheet/mineral/sandstone,
		/obj/item/stack/sheet/mineral/diamond,
		/obj/item/stack/sheet/mineral/gold,
		/obj/structure/statue,
		/obj/item/stack/sheet/mineral/sandbags,
		/obj/item/stack/sheet/mineral/coal,
		/obj/structure/table/bronze,
	)),
	ELEMENT_METAL = typecacheof(list(
		/obj/item/stack/sheet/iron,
		/obj/item/stack/rods,
		/obj/item/storage/toolbox,
		/obj/item/claymore,
		/obj/item/katana,
		/obj/item/weldingtool,
		/obj/item/stack/sheet/plasteel,
		/obj/structure/table/reinforced,
	)),
	ELEMENT_WATER = typecacheof(list(
		/obj/structure/sink,
		/obj/structure/aquarium,
		/obj/machinery/shower,
		/obj/item/reagent_containers/cup/bucket,
		/obj/item/reagent_containers/cup/glass/waterbottle,
		/obj/structure/reagent_dispensers/watertank,
		/obj/item/aquarium_kit,
		/obj/structure/water_source,
	)),
))

/// The result of looking at a site for one cultivator
/datum/cultivation_site_report
	/// element -> points
	var/list/element_points = list()
	/// Insight multiplier for meditation
	var/multiplier = 1
	/// Bonus to breakthrough readiness
	var/readiness_bonus = 0
	/// Human readable explanation
	var/list/lines = list()
	/// Did we find a mat
	var/has_mat = FALSE
	/// Is the cultivator alone
	var/secluded = FALSE

/// Count element points around a turf
/proc/cultivation_count_elements(turf/center, radius = 2)
	var/list/points = list()
	var/list/type_counts = list()
	for(var/element in GLOB.cultivation_element_sources)
		points[element] = 0
	for(var/atom/movable/thing in range(radius, center))
		for(var/element in GLOB.cultivation_element_sources)
			if(!is_type_in_typecache(thing, GLOB.cultivation_element_sources[element]))
				continue
			if(type_counts[thing.type] >= SITE_SAME_TYPE_CAP)
				break
			type_counts[thing.type]++
			// Water needs actual water in containers
			if(istype(thing, /obj/item/reagent_containers) && !thing.reagents?.has_reagent(/datum/reagent/water))
				break
			if(istype(thing, /obj/item/lighter))
				var/obj/item/lighter/lighter = thing
				if(!lighter.lit)
					break
			points[element] = min(points[element] + 1, SITE_ELEMENT_CAP)
			break
	return points

/proc/cultivation_evaluate_site(mob/living/user, datum/antagonist/cultivator/cultivator)
	var/datum/cultivation_site_report/report = new()
	var/turf/here = get_turf(user)
	report.has_mat = !!(locate(/obj/structure/cultivation_mat) in here)
	report.element_points = cultivation_count_elements(here)
	report.secluded = TRUE
	for(var/mob/living/other in view(5, user))
		if(other == user || other.stat == DEAD || !other.client)
			continue
		report.secluded = FALSE
		break

	if(!report.has_mat)
		report.lines += span_warning("You aren't sitting on a cultivation mat, so your surroundings barely matter.")
	var/net = 0
	if(report.has_mat)
		for(var/datum/cultivation_law/law as anything in cultivator.laws)
			var/own = report.element_points[law.element]
			var/mother
			for(var/element in GLOB.cultivation_generates)
				if(GLOB.cultivation_generates[element] == law.element)
					mother = element
			var/enemy
			for(var/element in GLOB.cultivation_overcomes)
				if(GLOB.cultivation_overcomes[element] == law.element)
					enemy = element
			var/support = report.element_points[mother]
			var/opposition = report.element_points[enemy]
			if(own >= 3)
				report.lines += span_nicegreen("Strong [law.element] influence nourishes your [law.name].")
			else if(own)
				report.lines += span_notice("Some [law.element] influence. More would help your [law.name].")
			else
				report.lines += span_warning("No [law.element] influence at all for your [law.name].")
			if(support)
				report.lines += span_nicegreen("[capitalize(mother)] feeds [law.element] here.")
			if(opposition >= 2)
				report.lines += span_warning("Heavy [enemy] influence is suppressing your [law.element] qi!")
			net += own + support * 0.5 - opposition
		if(!length(cultivator.laws))
			report.lines += span_notice("You have no law yet. The mat still helps you focus.")
	if(report.secluded)
		report.lines += span_nicegreen("You are secluded. Nobody is here to disturb you.")
	else
		report.lines += span_notice("Others are nearby. Closed-door seclusion would be better.")

	report.multiplier = 1 + (report.has_mat ? 0.1 : 0) + clamp(net * 0.05, -0.2, 0.5) + (report.secluded ? 0.25 : 0)
	report.readiness_bonus = (report.has_mat ? 10 : 0) + clamp(round(net * 3), -20, 25) + (report.secluded ? 5 : 0)
	return report

/**
 * # Cultivation mat
 *
 * Sit here to meditate properly. Examine it (as a cultivator) to read the local feng shui.
 */
/obj/structure/cultivation_mat
	name = "cultivation mat"
	desc = "A round woven mat with the eight trigrams stitched around the edge. Supposedly it helps you focus."
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'
	icon_state = "mat"
	layer = LOW_OBJ_LAYER
	anchored = TRUE
	density = FALSE
	resistance_flags = FLAMMABLE
	max_integrity = 50

/obj/structure/cultivation_mat/examine(mob/user)
	. = ..()
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(user)
	if(!cultivator)
		. += span_notice("It's just a nice mat.")
		return
	var/list/points = cultivation_count_elements(get_turf(src))
	var/list/readout = list()
	for(var/element in points)
		readout += "[element] [points[element]]/[SITE_ELEMENT_CAP]"
	. += span_notice("You sense the flow of the five elements here: [english_list(readout)].")
	. += span_notice("Sit on it and use <b>Spiritual Sense</b> for a full reading.")

/obj/structure/cultivation_mat/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	default_unfasten_wrench(user, tool)
	return ITEM_INTERACT_SUCCESS

/obj/structure/cultivation_mat/atom_deconstruct(disassembled)
	new /obj/item/stack/sheet/cloth(drop_location(), 3)

/datum/crafting_recipe/cultivation_mat
	name = "Cultivation Mat"
	result = /obj/structure/cultivation_mat
	reqs = list(/obj/item/stack/sheet/cloth = 3)
	time = 5 SECONDS
	category = CAT_FURNITURE

#undef SITE_ELEMENT_CAP
#undef SITE_SAME_TYPE_CAP
