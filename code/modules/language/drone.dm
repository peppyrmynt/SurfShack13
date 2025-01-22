/datum/language/drone
	name = "Drone"
	desc = "A heavily encoded damage control coordination stream, with special flags for hats."
	spans = list(SPAN_ROBOT)
	key = "d"
	flags = NO_STUTTER
	syllables = list(".", "|")
	// ...|..||.||||.|.||.|.|.|||.|||
	space_chance = 0
	sentence_chance = 0
	default_priority = 20

	icon_state = "drone"

/datum/language/drone/get_random_name(
	gender = NEUTER,
	name_count = 2,
	syllable_min = 2,
	syllable_max = 4,
	unique = FALSE,
	force_use_syllables = FALSE,
)
	if(force_use_syllables)
		return ..()
	return "[pick(GLOB.android_names)] Drone"
