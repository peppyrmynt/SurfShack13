/datum/experiment/scanning/points/security_paperwork
	var/area/demanded_area
	var/static/list/possible_areas

/datum/experiment/scanning/points/security_paperwork/New(datum/techweb/techweb)
	if(!possible_areas)
		possible_areas = typecacheof(list(\
			/area/station/maintenance,\
			/area/station/commons,\
			/area/station/service,\
			/area/station/hallway/primary,\
			/area/station/security/office,\
			/area/station/security/prison,\
			/area/station/security/range,\
			/area/station/security/checkpoint,\
			/area/station/security/tram,\
			/area/station/security/breakroom,\
			/area/station/security/interrogation))
		for (var/area_type in possible_areas)
			if(GLOB.areas_by_type[area_type])
				continue
			possible_areas -= area_type

	demanded_area = pick(possible_areas)
	name = name + ": [initial(demanded_area.name)]"
	description = initial(description) + " [initial(demanded_area.name)]"

	. = ..()

/datum/experiment/scanning/points/security_paperwork/final_contributing_index_checks(
	datum/component/experiment_handler/experiment_handler,
	atom/target,
	typepath
)
	if(!istype(target, /obj/item/paper/report))
		return FALSE

	var/obj/item/paper/report/report = target

	if(!istype(report.scanned_area, demanded_area))
		experiment_handler.announce_message("This report is not from the required area.")
		return FALSE

	return ..()
