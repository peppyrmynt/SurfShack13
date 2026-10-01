/**
 * # Nightmare fog: the floor cluwne
 *
 * The admin-only nightmare fog (see station_fog.dm) climbs past thickness 5
 * to 6. When it reaches 5 it polls ghosts to play floor cluwnes, which hunt
 * under the floor through the fog until thickness 6 dissipates.
 *
 * Built on HippieStation's floor cluwne, which was AI-only (Yogstation even
 * blocked it from being made sentient, because its abilities all ran on
 * their own). Here every one of its tricks is an ability the player chooses
 * to use: haunting a victim, tripping them, tormenting a room, and the grab
 * that drags someone under the floor.
 *
 * People dragged under aren't killed. They're held in stasis under the floor
 * and spat out somewhere in maintenance when the fog ends, hurt and with a
 * fresh fear of clowns.
 */

/// Invisibility source for a floor cluwne that's under the floor.
#define FLOOR_CLUWNE_SUBMERGED "floor_cluwne_submerged"
/// Status/trait source for everything the cluwne does to its victims.
#define FLOOR_CLUWNE_SOURCE "floor_cluwne"
/// How much damage the cluwne can take mid-grab before it lets go.
#define FLOOR_CLUWNE_GRAB_BREAK_DAMAGE 60

// ---- The fog's side: polling, spawning, victims -----------------------------

/// Asks the dead who wants to be a floor cluwne, and spawns the ones picked.
/// Sleeps for the poll, so call it async.
/datum/weather/station_fog/proc/poll_for_cluwnes()
	if(cluwnes_polled)
		return
	cluwnes_polled = TRUE
	message_admins("Nightmare fog: polling ghosts for [cluwne_count] floor cluwne\s.")
	var/result = SSpolling.poll_ghost_candidates(
		question = "Do you want to play as a floor cluwne, hunting under the station's floors through the fog?",
		role = ROLE_SENTIENCE,
		check_jobban = ROLE_SENTIENCE,
		poll_time = 20 SECONDS,
		alert_pic = /mob/living/basic/floor_cluwne,
		role_name_text = "floor cluwne",
		amount_to_pick = cluwne_count,
	)
	if(QDELETED(src) || stage != MAIN_STAGE)
		return
	var/list/chosen = islist(result) ? result : (result ? list(result) : list())
	if(!length(chosen))
		message_admins("Nightmare fog: nobody signed up to be a floor cluwne.")
		return
	make_gullet()
	for(var/mob/dead/observer/ghost in chosen)
		spawn_cluwne(ghost)

/// Puts [ghost] into a new floor cluwne somewhere in the fog.
/datum/weather/station_fog/proc/spawn_cluwne(mob/dead/observer/ghost)
	var/turf/spot = random_fogged_floor()
	if(!spot)
		message_admins("Nightmare fog: no fogged floor to spawn a floor cluwne on.")
		return
	var/mob/living/basic/floor_cluwne/cluwne = new(spot, src)
	cluwnes += cluwne
	cluwne.PossessByPlayer(ghost.key)
	message_admins("[ADMIN_LOOKUPFLW(cluwne)] has been made into a floor cluwne by the nightmare fog.")
	log_game("[key_name(cluwne)] was spawned as a floor cluwne by the nightmare fog.")

/// A random open, unblocked floor in a fogged area.
/datum/weather/station_fog/proc/random_fogged_floor()
	var/list/fogged_areas = list()
	for(var/area/fogged as anything in fogged_area_set)
		fogged_areas += fogged
	for(var/attempt in 1 to 20)
		if(!length(fogged_areas))
			return null
		var/area/picked = pick(fogged_areas)
		var/list/floors = list()
		for(var/z_level in impacted_z_levels)
			for(var/turf/open/floor/floor in picked.get_turfs_by_zlevel(z_level))
				if(!floor.is_blocked_turf())
					floors += floor
		if(length(floors))
			return pick(floors)
	return null

/// Sends every floor cluwne back where it came from: the fog is going.
/datum/weather/station_fog/proc/remove_cluwnes()
	for(var/mob/living/basic/floor_cluwne/cluwne as anything in cluwnes)
		if(QDELETED(cluwne))
			continue
		cluwne.fog = null
		to_chat(cluwne, span_boldnotice("The fog thins, and you sink back down to wherever it is you came from."))
		cluwne.ghostize(FALSE)
		qdel(cluwne)
	cluwnes.Cut()

/// Makes the place under the floor: a reserved tile off the station map. It
/// has to be a real turf: a mob with a client and no turf gets flagged by
/// Life() and thrown into the error room. Can sleep on the reservation.
/datum/weather/station_fog/proc/make_gullet()
	if(gullet)
		return gullet
	gullet_reservation = SSmapping.request_turf_block_reservation(1, 1)
	var/turf/holding = gullet_reservation?.bottom_left_turfs?[1]
	gullet = new(holding)
	return gullet

/// Takes [victim] under the floor until the fog ends.
/datum/weather/station_fog/proc/take_victim(mob/living/carbon/human/victim)
	make_gullet()
	eaten[victim] = TRUE
	victim.forceMove(gullet)
	victim.apply_status_effect(/datum/status_effect/grouped/stasis, FLOOR_CLUWNE_SOURCE)
	victim.become_blind(FLOOR_CLUWNE_SOURCE)
	to_chat(victim, span_userdanger("You're dragged under the floor. It's cold, and something down here is giggling."))
	log_combat(victim, victim, "was dragged under the floor by a floor cluwne")

/// Spits everyone the cluwnes took back out, into maintenance.
/datum/weather/station_fog/proc/release_victims()
	var/list/maint_floors = list()
	for(var/area/station/maintenance/maint in get_areas(/area/station/maintenance))
		for(var/z_level in impacted_z_levels)
			for(var/turf/open/floor/floor in maint.get_turfs_by_zlevel(z_level))
				if(!floor.is_blocked_turf())
					maint_floors += floor
	for(var/mob/living/carbon/human/victim as anything in eaten)
		if(QDELETED(victim))
			continue
		var/turf/drop = length(maint_floors) ? pick(maint_floors) : random_fogged_floor()
		if(drop)
			victim.forceMove(drop)
		victim.remove_status_effect(/datum/status_effect/grouped/stasis, FLOOR_CLUWNE_SOURCE)
		victim.cure_blind(FLOOR_CLUWNE_SOURCE)
		victim.adjustBruteLoss(60)
		victim.adjustOxyLoss(30)
		victim.adjustStaminaLoss(120)
		victim.Knockdown(10 SECONDS)
		victim.adjust_jitter(45 SECONDS)
		victim.adjust_confusion(20 SECONDS)
		victim.gain_trauma(/datum/brain_trauma/mild/phobia/clowns, TRAUMA_RESILIENCE_BASIC)
		victim.add_mood_event("dragged_under", /datum/mood_event/dragged_under)
		if(drop)
			playsound(drop, 'surfshack13/sound/hippie/bodyscrape1.ogg', 50, TRUE)
			drop.visible_message(span_danger("[victim] is spat up out of the floor!"))
		to_chat(victim, span_userdanger("The floor spits you back out somewhere dark. You can still hear it laughing."))
	eaten.Cut()
	QDEL_NULL(gullet)
	QDEL_NULL(gullet_reservation)

/// Something dragged you under the floor, and you came back.
/datum/mood_event/dragged_under
	description = "Something dragged me under the floor. It was so cold down there, and it never stopped laughing."
	mood_change = -12
	timeout = 15 MINUTES

/// Where people dragged under the floor wait out the fog. Lives in nullspace.
/obj/effect/abstract/floor_cluwne_gullet
	name = "under the floor"

// ---- The floor cluwne -------------------------------------------------------

/mob/living/basic/floor_cluwne
	name = "???"
	real_name = "floor cluwne"
	desc = "...."
	icon = 'surfshack13/icons/hippie/floor_cluwne.dmi'
	icon_state = "floor_cluwne"
	icon_living = "floor_cluwne"
	base_pixel_y = 8
	pixel_y = 8
	mob_biotypes = MOB_SPIRIT
	maxHealth = 250
	health = 250
	density = FALSE
	// Under the floor it goes through walls, doors and people. It still moves
	// with Move(), unlike incorporeal mobs, so the fog can keep it inside.
	movement_type = PHASING | FLYING
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB | PASSGLASS
	move_resist = MOVE_FORCE_OVERPOWERING
	// Noticeably quicker than a running spaceman (1.5): the hunt is short.
	speed = 0.4
	sight = SEE_SELF | SEE_MOBS
	lighting_cutoff_red = 30
	lighting_cutoff_green = 20
	lighting_cutoff_blue = 25
	status_flags = NONE
	unsuitable_atmos_damage = 0
	habitable_atmos = null
	minimum_survivable_temperature = 0
	maximum_survivable_temperature = INFINITY
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 0, STAMINA = 0, OXY = 0)
	speak_emote = list("honks")
	basic_mob_flags = DEL_ON_DEATH
	faction = list("floor_cluwne")
	unique_name = FALSE
	/// The nightmare fog that brought us here; we can only go where it goes.
	var/datum/weather/station_fog/fog
	/// Whether we're under the floor (invisible, phasing) or up through it.
	var/submerged = TRUE
	/// Who we're currently dragging under, if anyone.
	var/mob/living/carbon/human/eating
	/// Our health when the current grab started, to let go if hurt enough.
	var/grab_start_health
	/// The hole we've opened in the floor while surfaced.
	var/obj/effect/floor_cluwne_hole/hole
	/// Throttle for the "the fog doesn't reach there" message.
	COOLDOWN_DECLARE(edge_message_cooldown)
	/// What we can do.
	var/static/list/cluwne_abilities = list(
		/datum/action/cooldown/floor_cluwne/haunt,
		/datum/action/cooldown/floor_cluwne/trip,
		/datum/action/cooldown/floor_cluwne/torment,
		/datum/action/cooldown/floor_cluwne/grab,
	)

/mob/living/basic/floor_cluwne/Initialize(mapload, datum/weather/station_fog/fog)
	. = ..()
	src.fog = fog
	SetInvisibility(INVISIBILITY_OBSERVER, FLOOR_CLUWNE_SUBMERGED)
	add_traits(list(TRAIT_WEATHER_IMMUNE, TRAIT_SPACEWALK, TRAIT_NO_FLOATING_ANIM, TRAIT_THERMAL_VISION), INNATE_TRAIT)
	update_sight()
	RegisterSignal(src, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(on_pre_move))
	for(var/ability_type in cluwne_abilities)
		var/datum/action/ability = new ability_type(src)
		ability.Grant(src)

/mob/living/basic/floor_cluwne/Destroy()
	if(eating)
		let_go()
	QDEL_NULL(hole)
	if(fog)
		fog.cluwnes -= src
		fog = null
	return ..()

/mob/living/basic/floor_cluwne/Login()
	. = ..()
	if(!. || !client)
		return
	thin_the_fog()
	to_chat(src, boxed_message(jointext(list(
		span_deadsay(span_boldbig("You are a floor cluwne.")),
		span_bold("You move under the station's floors, through walls and doors, unseen by anyone but the dead. You can only go where the fog goes, and you see through it: heat and all."),
		span_bold("Until the fog thickens all the way you can only move and watch. Once it does, Haunt, Trip and Torment scare the crew. Grab drags someone within 3 tiles under the floor: you surface to do it, and while you're up you can be hurt and pulled off them."),
		span_bold("People you drag under aren't killed. They're spat back out when the fog lifts, which will be soon. Make it count."),
	), "<br>")))

/// The fog is home: the haze drawn over the floors is only faint to us.
/mob/living/basic/floor_cluwne/proc/thin_the_fog()
	if(!hud_used)
		return
	for(var/atom/movable/screen/plane_master/weather in hud_used.get_true_plane_masters(WEATHER_PLANE))
		weather.alpha = 50

/mob/living/basic/floor_cluwne/med_hud_set_health()
	return

/mob/living/basic/floor_cluwne/med_hud_set_status()
	return

/// Keeps us inside the fog.
/mob/living/basic/floor_cluwne/proc/on_pre_move(datum/source, atom/new_loc)
	SIGNAL_HANDLER
	var/area/destination = get_area(new_loc)
	if(fog?.fogged_area_set[destination])
		return NONE
	if(COOLDOWN_FINISHED(src, edge_message_cooldown))
		COOLDOWN_START(src, edge_message_cooldown, 2 SECONDS)
		balloon_alert(src, "the fog doesn't reach there")
	return COMPONENT_MOVABLE_BLOCK_PRE_MOVE

// Under the floor we don't bump into anything: no opening doors, no shoving.
/mob/living/basic/floor_cluwne/Bump(atom/bumped_atom)
	if(submerged)
		return
	return ..()

/// Comes up through the floor: visible, solid, rooted, and hurtable.
/mob/living/basic/floor_cluwne/proc/surface()
	if(!submerged)
		return
	submerged = FALSE
	RemoveInvisibility(FLOOR_CLUWNE_SUBMERGED)
	movement_type &= ~PHASING
	density = TRUE
	ADD_TRAIT(src, TRAIT_IMMOBILIZED, FLOOR_CLUWNE_SOURCE)
	QDEL_NULL(hole)
	hole = new(get_turf(src))
	playsound(src, 'sound/effects/meteorimpact.ogg', 40, TRUE)

/// Sinks back under the floor.
/mob/living/basic/floor_cluwne/proc/submerge()
	if(submerged)
		return
	submerged = TRUE
	SetInvisibility(INVISIBILITY_OBSERVER, FLOOR_CLUWNE_SUBMERGED)
	movement_type |= PHASING
	density = FALSE
	REMOVE_TRAIT(src, TRAIT_IMMOBILIZED, FLOOR_CLUWNE_SOURCE)
	QDEL_NULL(hole)

/// The grab: surface, drag them to the hole, and pull them under. Sleeps.
/mob/living/basic/floor_cluwne/proc/drag_under(mob/living/carbon/human/victim)
	eating = victim
	grab_start_health = health
	// Walls or doors in the way: come up right under them instead, as Hippie's did.
	for(var/turf/crossed as anything in get_line(src, victim))
		if(crossed.density || (locate(/obj/machinery/door) in crossed) || (locate(/obj/structure/window) in crossed))
			forceMove(get_turf(victim))
			break
	surface()
	to_chat(victim, span_userdanger("You feel the floor closing in on your feet!"))
	victim.emote("scream")
	victim.adjustBruteLoss(10)
	victim.Knockdown(6 SECONDS)
	sleep(1.5 SECONDS)
	if(!still_eating(victim))
		let_go()
		return
	to_chat(victim, span_userdanger("You feel a cold, gloved hand clamp down on your ankle!"))
	var/tries = 0
	while(get_dist(src, victim) > 1 && tries++ < 6)
		if(!do_after(src, 0.5 SECONDS, victim, extra_checks = CALLBACK(src, PROC_REF(still_eating), victim)))
			let_go()
			return
		step_towards(victim, src)
		victim.Knockdown(2 SECONDS)
		playsound(victim, pick('surfshack13/sound/hippie/bodyscrape1.ogg', 'surfshack13/sound/hippie/bodyscrape2.ogg'), 30, TRUE, -4)
		if(prob(40))
			victim.emote("scream")
		else if(prob(25))
			victim.say(pick("HELP ME!!", "IT'S GOT ME!!", "DON'T LET IT TAKE ME!!", ";SOMETHING'S PULLING ME UNDER!!"), forced = "floor cluwne")
	if(get_dist(src, victim) > 1)
		let_go()
		return
	visible_message(span_danger("[src] begins dragging [victim] under the floor!"))
	playsound(src, pick('surfshack13/sound/hippie/cluwnelaugh1.ogg', 'surfshack13/sound/hippie/cluwnelaugh2.ogg', 'surfshack13/sound/hippie/cluwnelaugh3.ogg'), 50, TRUE)
	victim.Paralyze(6 SECONDS)
	if(!do_after(src, 5 SECONDS, victim, extra_checks = CALLBACK(src, PROC_REF(still_eating), victim)))
		let_go()
		return
	swallow(victim)

/// Whether the grab on [victim] still holds.
/mob/living/basic/floor_cluwne/proc/still_eating(mob/living/carbon/human/victim)
	if(QDELETED(victim) || eating != victim || stat != CONSCIOUS)
		return FALSE
	if(health < grab_start_health - FLOOR_CLUWNE_GRAB_BREAK_DAMAGE)
		visible_message(span_warning("[src] recoils, losing its grip!"))
		return FALSE
	return TRUE

/// Lets go of whoever we had, and sinks back down.
/mob/living/basic/floor_cluwne/proc/let_go()
	if(eating && !QDELETED(eating))
		to_chat(eating, span_warning("The grip on your ankle lets go!"))
	eating = null
	submerge()

/// They're ours, until the fog lifts.
/mob/living/basic/floor_cluwne/proc/swallow(mob/living/carbon/human/victim)
	var/turf/here = get_turf(victim)
	visible_message(span_danger("[src] pulls [victim] under!"))
	playsound(here, 'surfshack13/sound/hippie/cluwne_feast.ogg', 70, FALSE, -2)
	for(var/turf/splatter_turf in orange(2, here))
		if(prob(40))
			victim.add_splatter_floor(splatter_turf)
	log_combat(src, victim, "dragged under the floor")
	if(fog)
		fog.take_victim(victim)
		// Everyone in the fog hears it echo, wherever they are.
		for(var/mob/living/listener as anything in fog.fogged_players)
			listener.playsound_local(get_turf(listener), 'surfshack13/sound/hippie/honk_echo_distant.ogg', 50, TRUE, pressure_affected = FALSE)
	eating = null
	submerge()

// ---- The hole in the floor --------------------------------------------------

/obj/effect/floor_cluwne_hole
	name = "hole"
	desc = "There's something down there."
	icon = 'surfshack13/icons/hippie/floor_cluwne.dmi'
	icon_state = "fcluwne_open"
	layer = LOW_FLOOR_LAYER
	plane = FLOOR_PLANE
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/floor_cluwne_hole/Initialize(mapload)
	. = ..()
	flick("fcluwne_manifest", src)

// ---- Abilities ----------------------------------------------------------------

/datum/action/cooldown/floor_cluwne
	button_icon = 'surfshack13/icons/hippie/floor_cluwne.dmi'
	button_icon_state = "floor_cluwne"
	background_icon_state = "bg_spell"
	overlay_icon_state = "bg_spell_border"
	check_flags = AB_CHECK_CONSCIOUS
	/// How far away a target can be, for targeted abilities.
	var/target_range = 9

/datum/action/cooldown/floor_cluwne/IsAvailable(feedback = FALSE)
	. = ..()
	if(!.)
		return
	var/mob/living/basic/floor_cluwne/cluwne = owner
	if(!istype(cluwne) || cluwne.eating)
		return FALSE
	// At thickness 5 it can only stalk: its tricks wake up with the fog at 6.
	if(!cluwne.fog?.maintenance_fogged)
		if(feedback)
			cluwne.balloon_alert(cluwne, "the fog isn't thick enough yet")
		return FALSE

/// Shared targeting check: a living, conscious person in view and in range.
/datum/action/cooldown/floor_cluwne/proc/valid_victim(atom/target)
	var/mob/living/carbon/human/victim = target
	if(!istype(victim) || victim.stat == DEAD)
		owner.balloon_alert(owner, "not a person!")
		return FALSE
	// Range, not view: it reaches up from under the floor, walls and all.
	if(get_dist(owner, victim) > target_range || victim.z != owner.z)
		owner.balloon_alert(owner, "too far!")
		return FALSE
	return TRUE

/datum/action/cooldown/floor_cluwne/haunt
	name = "Haunt"
	desc = "Toy with someone: a laugh only they hear, a horn, a thrown object, or blurry eyes."
	cooldown_time = 3 SECONDS
	click_to_activate = TRUE

/datum/action/cooldown/floor_cluwne/haunt/Activate(atom/target)
	if(!valid_victim(target))
		return FALSE
	var/mob/living/carbon/human/victim = target
	switch(rand(1, 4))
		if(1)
			victim.playsound_local(get_turf(owner), 'surfshack13/sound/hippie/cluwnelaugh2_reversed.ogg', 40, TRUE)
			to_chat(victim, "<i>...edih t'nac uoY...</i>")
		if(2)
			victim.playsound_local(get_turf(owner), 'surfshack13/sound/hippie/bikehorn_creepy.ogg', 40, TRUE)
			to_chat(victim, "<i>knoh</i>")
		if(3)
			var/obj/item/thrown
			for(var/obj/item/candidate in orange(6, victim))
				if(!candidate.anchored)
					thrown = candidate
					break
			if(thrown)
				thrown.throw_at(victim, 4, 3)
				to_chat(victim, span_warning("What threw that?"))
			else
				victim.playsound_local(get_turf(owner), 'surfshack13/sound/hippie/cluwnelaugh1.ogg', 40, TRUE)
		if(4)
			victim.set_eye_blur_if_lower(6 SECONDS)
			to_chat(victim, span_warning("Your eyes sting."))
	StartCooldown()
	return TRUE

/datum/action/cooldown/floor_cluwne/trip
	name = "Trip"
	desc = "The floor shifts under someone, knocking them over."
	cooldown_time = 7 SECONDS
	click_to_activate = TRUE

/datum/action/cooldown/floor_cluwne/trip/Activate(atom/target)
	if(!valid_victim(target))
		return FALSE
	var/mob/living/carbon/human/victim = target
	victim.Knockdown(2 SECONDS)
	playsound(victim, 'sound/misc/slip.ogg', 50, TRUE)
	to_chat(victim, span_warning("The floor shifts underneath you!"))
	StartCooldown()
	return TRUE

/datum/action/cooldown/floor_cluwne/torment
	name = "Torment"
	desc = "Make the lights flicker and the floor go slick around you, with a laugh everyone nearby hears."
	cooldown_time = 15 SECONDS

/datum/action/cooldown/floor_cluwne/torment/Activate(atom/target)
	var/turf/here = get_turf(owner)
	for(var/obj/machinery/light/fixture in range(7, here))
		fixture.flicker()
	for(var/turf/open/floor in range(3, here))
		floor.MakeSlippery(TURF_WET_WATER, min_wet_time = 10 SECONDS)
	playsound(here, 'sound/effects/meteorimpact.ogg', 30, TRUE)
	playsound(here, 'surfshack13/sound/hippie/cluwnelaugh2_reversed.ogg', 40, TRUE)
	StartCooldown()
	return TRUE

/datum/action/cooldown/floor_cluwne/grab
	name = "Grab"
	desc = "Surface and drag someone within 3 tiles under the floor. While you're up you can be hurt, and they can be pulled away from you."
	cooldown_time = 20 SECONDS
	click_to_activate = TRUE
	target_range = 3

/datum/action/cooldown/floor_cluwne/grab/Activate(atom/target)
	if(!valid_victim(target))
		return FALSE
	var/mob/living/basic/floor_cluwne/cluwne = owner
	StartCooldown()
	INVOKE_ASYNC(cluwne, TYPE_PROC_REF(/mob/living/basic/floor_cluwne, drag_under), target)
	return TRUE

#undef FLOOR_CLUWNE_SUBMERGED
#undef FLOOR_CLUWNE_SOURCE
#undef FLOOR_CLUWNE_GRAB_BREAK_DAMAGE
