// THE WORLD - ported from HippieStation.
// Stops time across the whole station (every station z-level, or just the caster's z-level off-station)
// for 1 second per spell point, and comes with CHECKMATE, a spread of knives that hang in the air until time resumes.
//
// Hippie overrode /atom/Initialize and several subsystems for this. The port instead reuses Surf's
// timestop field for the actual freezing, and inverts every affected player's screen for the negative-world look.

GLOBAL_DATUM(the_world_timestop, /datum/the_world_timestop)

/datum/action/cooldown/spell/the_world
	name = "THE WORLD (1 second)"
	desc = "Stop time across the entire station."
	button_icon_state = "time"
	school = SCHOOL_FORBIDDEN
	cooldown_time = 2 MINUTES
	invocation = "ZA WARUDO!"
	invocation_type = INVOCATION_SHOUT
	spell_requirements = SPELL_REQUIRES_NO_ANTIMAGIC
	spell_max_level = 20
	/// How long time stays stopped. Every extra purchase adds a second.
	var/freeze_duration = 1 SECONDS

/datum/action/cooldown/spell/the_world/Grant(mob/grant_to)
	. = ..()
	if(isnull(owner))
		return
	ADD_TRAIT(owner, TRAIT_TIME_STOP_IMMUNE, REF(src))
	if(!(locate(/datum/action/cooldown/spell/pointed/projectile/checkmate) in owner.actions))
		var/datum/action/cooldown/spell/pointed/projectile/checkmate/knives = new(owner.mind || owner)
		knives.Grant(owner)

/datum/action/cooldown/spell/the_world/Remove(mob/remove_from)
	REMOVE_TRAIT(remove_from, TRAIT_TIME_STOP_IMMUNE, REF(src))
	return ..()

/datum/action/cooldown/spell/the_world/level_spell(bypass_cap = FALSE)
	. = ..()
	if(!.)
		return
	freeze_duration += 1 SECONDS
	name = "THE WORLD ([freeze_duration / (1 SECONDS)] seconds)"
	build_all_button_icons(UPDATE_BUTTON_NAME)

/datum/action/cooldown/spell/the_world/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	if(GLOB.the_world_timestop)
		to_chat(owner, span_warning("Time is already stopped!"))
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/the_world/cast(atom/cast_on)
	. = ..()
	var/turf/caster_turf = get_turf(owner)
	new /obj/effect/temp_visual/the_world(caster_turf)
	new /datum/the_world_timestop(owner, freeze_duration, antimagic_flags)

/// Handles one station-wide time stop from start to finish.
/datum/the_world_timestop
	/// The wizard who stopped time
	var/mob/living/master
	/// Invisible anchor that owns the timestop field
	var/obj/effect/the_world_anchor/anchor
	/// Surf's timestop field, used for its freeze/unfreeze logic
	var/datum/proximity_monitor/advanced/timestop/the_world/field
	/// z-levels time is stopped on
	var/list/z_levels
	/// Mobs whose screen we inverted
	var/list/mob/tinted_mobs = list()
	var/start_sound = 'surfshack13/sound/hippie/dzw.ogg'
	var/dubstep_sound = 'surfshack13/sound/hippie/unnatural_clock_noises.ogg'
	var/success_sound = 'surfshack13/sound/hippie/dzw-success.ogg'
	var/end_sound = 'surfshack13/sound/hippie/dzw-end.ogg'

/datum/the_world_timestop/New(mob/living/master, duration, antimagic_flags)
	. = ..()
	GLOB.the_world_timestop = src
	src.master = master
	var/turf/master_turf = get_turf(master)
	z_levels = is_station_level(master_turf.z) ? SSmapping.levels_by_trait(ZTRAIT_STATION) : list(master_turf.z)

	var/list/immune = list()
	immune[master] = TRUE
	for(var/mob/living/to_check as anything in GLOB.player_list)
		if(isliving(to_check) && HAS_TRAIT(to_check, TRAIT_TIME_STOP_IMMUNE))
			immune[to_check] = TRUE
	for(var/mob/living/basic/guardian/stand as anything in GLOB.parasites)
		if(stand.summoner && immune[stand.summoner])
			immune[stand] = TRUE

	anchor = new(master_turf)
	field = new(anchor, 0, TRUE, immune, antimagic_flags, FALSE)
	INVOKE_ASYNC(src, PROC_REF(za_warudo), duration)

/datum/the_world_timestop/Destroy()
	QDEL_NULL(anchor) // deleting the anchor deletes the field, which unfreezes everything
	field = null
	for(var/mob/tinted as anything in tinted_mobs)
		tinted.remove_client_colour(/datum/client_colour/the_world)
	tinted_mobs.Cut()
	master = null
	if(GLOB.the_world_timestop == src)
		GLOB.the_world_timestop = null
	return ..()

/datum/the_world_timestop/proc/za_warudo(duration)
	playsound(master, start_sound, 100, FALSE)
	var/sound/clock_noises = sound(dubstep_sound)
	for(var/mob/listener as anything in GLOB.player_list)
		if(!covers(listener))
			continue
		SEND_SOUND(listener, clock_noises)
		listener.add_client_colour(/datum/client_colour/the_world)
		tinted_mobs += listener
		if(field.immune[listener])
			to_chat(listener, span_bolddanger("Time has stopped."))

	freeze_everything()

	sleep(min(2 SECONDS, duration))
	if(QDELETED(src))
		return
	playsound(master, success_sound, 100, FALSE)
	if(duration > 2 SECONDS)
		sleep(duration - 2 SECONDS)
		if(QDELETED(src))
			return

	clock_noises.frequency = -1
	for(var/mob/listener as anything in GLOB.player_list)
		if(!covers(listener))
			continue
		SEND_SOUND(listener, clock_noises)
		if(field.immune[listener])
			to_chat(listener, span_bolddanger("Time has begun to move again."))
	if(master)
		playsound(master, end_sound, 100, FALSE)
	qdel(src)

/// Is this atom somewhere time is stopped?
/datum/the_world_timestop/proc/covers(atom/thing)
	var/turf/thing_turf = get_turf(thing)
	return thing_turf && (thing_turf.z in z_levels)

/datum/the_world_timestop/proc/freeze_everything()
	for(var/mob/living/victim as anything in GLOB.mob_living_list)
		if(covers(victim))
			field.freeze_atom(victim)
	for(var/obj/projectile/bullet as anything in SSprojectiles.processing)
		if(covers(bullet))
			field.freeze_atom(bullet)
	for(var/atom/movable/thrown as anything in SSthrowing.processing)
		if(covers(thrown))
			field.freeze_atom(thrown)
	for(var/obj/vehicle/sealed/mecha/mech as anything in GLOB.mechas_list)
		if(covers(mech))
			field.freeze_atom(mech)

/// Freezes something that started moving while time was stopped, like CHECKMATE's knives.
/datum/the_world_timestop/proc/late_freeze(atom/movable/thing)
	if(QDELETED(thing) || !covers(thing))
		return
	field.freeze_atom(thing)

/datum/proximity_monitor/advanced/timestop/the_world

// The whole screen is inverted instead, so frozen things keep their normal colours.
/datum/proximity_monitor/advanced/timestop/the_world/into_the_negative_zone(atom/A)
	return

/datum/proximity_monitor/advanced/timestop/the_world/escape_the_negative_zone(atom/A)
	return

/obj/effect/the_world_anchor
	name = "stopped time"
	anchored = TRUE
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/datum/client_colour/the_world
	colour = COLOR_MATRIX_INVERT
	priority = 10 // PRIORITY_HIGH, which client_colour.dm undefines
	override = TRUE
	fade_in = 5
	fade_out = 5

/obj/effect/temp_visual/the_world
	icon = 'surfshack13/icons/hippie/the_world_96x96.dmi'
	icon_state = "zawarudo"
	duration = 8
	pixel_x = -32
	pixel_y = -32

/obj/effect/temp_visual/the_world/Initialize(mapload)
	. = ..()
	var/matrix/grown = matrix(transform)
	grown.Scale(10)
	animate(src, transform = grown, time = 7.5, easing = EASE_IN|EASE_OUT)

/datum/action/cooldown/spell/pointed/projectile/checkmate
	name = "CHECKMATE"
	desc = "Throw a large amount of knives at your opponent!"
	button_icon = 'surfshack13/icons/hippie/the_world_knife.dmi'
	button_icon_state = "knife"
	school = SCHOOL_FORBIDDEN
	cooldown_time = 50 SECONDS
	invocation = "CHECKMATE!"
	invocation_type = INVOCATION_SHOUT
	spell_requirements = SPELL_REQUIRES_NO_ANTIMAGIC
	spell_max_level = 1
	active_msg = "You ready your knives."
	deactive_msg = "You put your knives away."
	projectile_type = /obj/projectile/the_world_knife
	projectiles_per_fire = 9
	/// Total spread of the knife fan, in degrees
	var/spread = 40

/datum/action/cooldown/spell/pointed/projectile/checkmate/ready_projectile(obj/projectile/to_fire, atom/target, mob/user, iteration)
	to_fire.firer = owner
	to_fire.fired_from = src
	var/step = spread / (projectiles_per_fire - 1)
	to_fire.aim_projectile(target, owner, deviation = -spread / 2 + step * (iteration - 1))

/obj/projectile/the_world_knife
	name = "knife"
	icon = 'surfshack13/icons/hippie/the_world_knife.dmi'
	icon_state = "knife"
	damage = 10
	damage_type = BRUTE
	armour_penetration = 100
	sharpness = SHARP_POINTY
	hitsound = 'sound/items/weapons/bladeslice.ogg'

/obj/projectile/the_world_knife/fire(fire_angle, atom/direct_target)
	. = ..()
	// Knives thrown in stopped time fly a moment, then hang in the air until time resumes
	if(GLOB.the_world_timestop)
		addtimer(CALLBACK(GLOB.the_world_timestop, TYPE_PROC_REF(/datum/the_world_timestop, late_freeze), src), 0.2 SECONDS)

/datum/spellbook_entry/the_world
	name = "THE WORLD"
	desc = "Freeze time across the entire station. 1 second per spellpoint. Comes with the ability to throw a large amount of knives. <b><i>Cannot be refunded.</i></b>"
	spell_type = /datum/action/cooldown/spell/the_world
	category = "Offensive"
	cost = 1
	refundable = FALSE
