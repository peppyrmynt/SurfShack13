// Eruption - ported from HippieStation.
// The caster is rooted in place while rings of fire spread outwards across everything they can see.
// Inner turfs get set alight on every wave, so the fire lasts longest near the centre.

#define ERUPTION_MAX_RANGE 7

/datum/action/cooldown/spell/eruption
	name = "Eruption"
	desc = "Gradually set fire to everything you can see, yourself included. The closer the fire is to the centre, the longer it lasts."
	button_icon = 'surfshack13/icons/hippie/wizard_actions.dmi'
	button_icon_state = "eruption"
	sound = 'sound/effects/magic/fireball.ogg'
	school = SCHOOL_EVOCATION
	cooldown_time = 60 SECONDS
	cooldown_reduction_per_rank = 10 SECONDS
	invocation = "DIE, INSECT!"
	invocation_type = INVOCATION_SHOUT

/datum/action/cooldown/spell/eruption/cast(atom/cast_on)
	. = ..()
	var/mob/living/caster = owner
	caster.SetStun(4 SECONDS, ignore_canstun = TRUE)
	erupt(get_turf(caster), 1)

/// Sets fire to every visible turf within range, then schedules the next, wider wave.
/datum/action/cooldown/spell/eruption/proc/erupt(turf/center, range)
	for(var/turf/open/burning in view(range, center))
		new /obj/effect/hotspot(burning)
	if(range < ERUPTION_MAX_RANGE)
		addtimer(CALLBACK(src, PROC_REF(erupt), center, range + 1), 0.5 SECONDS)

/datum/spellbook_entry/eruption
	name = "Eruption"
	desc = "Gradually set fire to everything you can see, yourself included. The closer the fire is to the centre, the longer it lasts."
	spell_type = /datum/action/cooldown/spell/eruption
	category = "Offensive"
	cost = 1

#undef ERUPTION_MAX_RANGE
