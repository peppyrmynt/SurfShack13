/// How many random manuals get hidden in maintenance each round
#define CULTIVATION_MAINT_MANUALS 3

/datum/controller/subsystem/ticker/Initialize()
	. = ..()
	OnRoundstart(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(spawn_cultivation_loot)))
	GLOB.mandate_controller.register()

/// Hide a few manuals and an ancestral ring around the station: maintenance and the library
/proc/spawn_cultivation_loot()
	var/list/maint_spots = GLOB.generic_maintenance_landmarks.Copy()
	for(var/i in 1 to CULTIVATION_MAINT_MANUALS)
		if(!length(maint_spots))
			break
		new /obj/effect/spawner/random/cultivation_manual(pick_n_take(maint_spots))
	if(length(maint_spots))
		new /obj/item/ancestral_ring(pick_n_take(maint_spots))
	for(var/i in 1 to 2)
		if(length(maint_spots))
			new /obj/effect/spawner/random/wuxia_manual(pick_n_take(maint_spots))
	if(length(maint_spots))
		new /obj/effect/spawner/random/legendary_artifact(pick_n_take(maint_spots))
	var/list/library_turfs = list()
	for(var/area/station/service/library/library in GLOB.areas)
		for(var/turf/open/floor/library_floor in library.get_turfs_from_all_zlevels())
			if(!library_floor.is_blocked_turf())
				library_turfs += library_floor
	if(length(library_turfs))
		new /obj/effect/spawner/random/cultivation_manual(pick(library_turfs))

#undef CULTIVATION_MAINT_MANUALS
