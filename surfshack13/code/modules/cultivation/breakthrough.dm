/**
 * # Breakthrough
 *
 * The public event. The cultivator sits, heaven notices, telegraphed lightning falls around them,
 * and at the end preparation decides the outcome. Failures are recoverable complications, not deletions.
 * Engineering can help: lightning that would land near a grounding rod is pulled into the rod instead.
 */
/datum/cultivation_breakthrough
	var/datum/antagonist/cultivator/cultivator
	var/mob/living/body
	/// 0-100ish, higher is safer
	var/readiness = 50
	/// Seconds the breakthrough lasts
	var/duration = 20
	/// Seconds elapsed
	var/elapsed = 0
	/// Elapsed times at which lightning falls
	var/list/strike_times = list()
	/// Damage per lightning strike
	var/strike_damage = 10
	/// Is this just restoring a body's dantian to the mind's realm
	var/restoration = FALSE
	/// Has it begun
	var/started = FALSE
	/// Readiness explanation
	var/list/reasons = list()
	/// Tribulation cloud hanging over the cultivator
	var/obj/effect/abstract/cultivation_vis/storm
	/// Qi swirling around them
	var/obj/effect/abstract/particle_holder/motes
	/// The finale: shatter the void and leave this world for the Immortal Realm
	var/ascension = FALSE
	/// Has the Ascension's heart demon come out yet
	var/demon_summoned = FALSE

/datum/cultivation_breakthrough/New(datum/antagonist/cultivator/cultivator, ascension = FALSE)
	src.cultivator = cultivator
	src.ascension = ascension
	body = cultivator.owner.current
	if(ascension)
		duration = 60
		strike_damage = 14
		for(var/strike in 4 to 56 step 4)
			strike_times += strike
		return
	var/obj/item/organ/dantian/dantian = cultivator.get_dantian()
	restoration = dantian && dantian.grade < cultivator.realm
	var/target_realm = restoration ? dantian.grade + 1 : cultivator.realm + 1
	switch(target_realm)
		if(REALM_FOUNDATION)
			duration = 20
			strike_damage = 6
			strike_times = list(8, 15)
		if(REALM_GOLDEN_CORE)
			duration = 30
			strike_damage = 10
			strike_times = list(6, 11, 16, 21, 26)
		else
			duration = 40
			strike_damage = 12
			strike_times = list(5, 9, 13, 17, 21, 25, 29, 33, 37)

/datum/cultivation_breakthrough/Destroy(force)
	STOP_PROCESSING(SSprocessing, src)
	if(body)
		body.remove_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), REF(src))
		body.remove_filter("breakthrough_glow")
		cultivation_detach_vis(body, storm)
	storm = null
	QDEL_NULL(motes)
	if(cultivator?.breakthrough == src)
		cultivator.breakthrough = null
	cultivator = null
	body = null
	return ..()

/// Work out readiness and why
/datum/cultivation_breakthrough/proc/assess()
	reasons = list(span_boldnotice("Breakthrough readiness"))
	readiness = 50
	if(restoration)
		readiness += 30
		reasons += span_nicegreen("+30: you are only restoring this body to a realm your mind already knows.")
	var/datum/cultivation_site_report/report = cultivation_evaluate_site(body, cultivator)
	readiness += report.readiness_bonus
	reasons += "[report.readiness_bonus >= 0 ? "+" : ""][report.readiness_bonus]: your surroundings."
	reasons += report.lines
	if(cultivator.qi >= cultivator.max_qi() * 0.9)
		readiness += 10
		reasons += span_nicegreen("+10: your qi is full.")
	else
		reasons += span_warning("+0: your qi isn't full.")
	if(cultivator.instability)
		var/penalty = round(cultivator.instability / 2)
		readiness -= penalty
		reasons += span_warning("-[penalty]: instability.")
	var/obj/item/organ/dantian/dantian = cultivator.get_dantian()
	if(dantian?.cracked)
		readiness -= 30
		reasons += span_danger("-30: your core is cracked!")
	for(var/datum/cultivation_law/law as anything in cultivator.laws)
		if(law.counterfeit)
			readiness -= 5
			reasons += span_warning("-5: something about your [law.name] feels off.")
	if(body.has_status_effect(/datum/status_effect/cultivation_pill_buff/foundation))
		readiness += 20
		reasons += span_nicegreen("+20: a Foundation Establishment Pill steadies you.")
	if(body.has_status_effect(/datum/status_effect/cultivation_pill_buff/tribulation))
		reasons += span_nicegreen("A Tribulation Warding Pill will halve heaven's lightning.")
	if(body.has_status_effect(/datum/status_effect/dao_heart_tempered))
		readiness += 15
		reasons += span_nicegreen("+15: you have faced your heart demon. Your Dao heart is tempered.")
	if(locate(/obj/machinery/power/energy_accumulator/grounding_rod) in range(4, body))
		reasons += span_nicegreen("A grounding rod nearby will draw some of heaven's lightning.")
	reasons += span_boldnotice("Total: [readiness] ([readiness_word()]). Stable breakthroughs always succeed if you endure them.")
	return reasons

/datum/cultivation_breakthrough/proc/readiness_word()
	if(readiness >= 70)
		return "Stable"
	if(readiness >= 40)
		return "Risky"
	return "Reckless"

/datum/cultivation_breakthrough/proc/start()
	assess()
	started = TRUE
	cultivator.breakthrough = src
	body.add_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), REF(src))
	body.add_filter("breakthrough_glow", 2, list("type" = "outline", "color" = "#ffe27a", "size" = 2))
	body.visible_message(
		span_boldwarning("[body] sits down and begins to draw in a torrent of qi! The air grows heavy and the lights flicker. Heaven is watching..."),
		span_boldnotice("You begin your breakthrough. Endure for [duration] seconds!"),
	)
	playsound(body, 'sound/effects/magic/lightning_chargeup.ogg', 60, TRUE)
	if(ascension)
		var/area/here = get_area(body)
		minor_announce("A heavenly tribulation of terrifying scale is gathering over [here?.name || "the station"]. [body.real_name] is attempting to ascend!", "Heavenly Omen")
		body.log_message("began an Ascension attempt", LOG_GAME)
	storm = cultivation_attach_vis(body, 'surfshack13/icons/cultivation/cultivation_effects_96.dmi', "storm_cloud", null, 96, 56, 230)
	motes = cultivation_particles(body, /particles/cultivation/gold)
	for(var/mob/living/carbon/human/witness in view(7, body))
		if(witness != body)
			to_chat(witness, span_notice("<i>You get the strong feeling you should not be standing near [body] right now.</i>"))
	START_PROCESSING(SSprocessing, src)

/datum/cultivation_breakthrough/process(seconds_per_tick)
	if(QDELETED(body) || body.stat != CONSCIOUS || body.mind != cultivator?.owner)
		fail(interrupted = TRUE)
		return PROCESS_KILL
	var/before = elapsed
	elapsed += seconds_per_tick
	for(var/strike_time in strike_times)
		if(strike_time > before && strike_time <= elapsed)
			call_lightning()
	// Ascension drags out your last heart demon
	if(ascension && !demon_summoned && elapsed >= 20)
		demon_summoned = TRUE
		cultivation_summon_heart_demon(body, 40 SECONDS)
	if(elapsed >= duration)
		resolve()
		return PROCESS_KILL

/// Heaven strikes. Mostly at the cultivator, sometimes beside them.
/datum/cultivation_breakthrough/proc/call_lightning()
	var/turf/target = get_turf(body)
	if(prob(35))
		var/list/nearby = list()
		for(var/turf/open/candidate in range(2, body))
			nearby += candidate
		if(length(nearby))
			target = pick(nearby)
	var/obj/machinery/power/energy_accumulator/grounding_rod/rod = locate() in range(4, target)
	if(rod && prob(60))
		rod.Beam(body, icon_state = "lightning[rand(1,12)]", time = 0.5 SECONDS)
		rod.visible_message(span_notice("A bolt of tribulation lightning is drawn into [rod]!"))
		playsound(rod, 'sound/effects/magic/lightningbolt.ogg', 50, TRUE)
		return
	var/obj/effect/temp_visual/lightning_strike/tribulation/bolt = new(target)
	bolt.zap_damage = strike_damage
	if(body.has_status_effect(/datum/status_effect/cultivation_pill_buff/tribulation))
		bolt.zap_damage = round(strike_damage / 2)

/datum/cultivation_breakthrough/proc/resolve()
	var/chance = readiness >= 70 ? 100 : clamp(readiness, 5, 95)
	if(prob(chance))
		succeed()
	else
		fail()

/datum/cultivation_breakthrough/proc/succeed()
	var/mob/living/user = body
	var/datum/antagonist/cultivator/winner = cultivator
	if(ascension)
		qdel(src)
		cultivation_ascend(user, winner)
		return
	qdel(src)
	winner.advance_realm()
	user.visible_message(
		span_boldnotice("A pillar of golden light erupts from [user]! [user.p_They()] [user.p_have()] broken through to [winner.realm_name(winner.effective_realm())]!"),
		span_boldnotice("Your qi surges through every meridian. You have broken through to [winner.realm_name(winner.effective_realm())]!"),
	)
	cultivation_breakthrough_sequence(user, winner.realm_name(winner.effective_realm()))
	// Watching someone else break through is a lesson in itself
	for(var/mob/living/witness in view(7, user))
		if(witness == user)
			continue
		var/datum/antagonist/cultivator/witness_cultivator = IS_CULTIVATOR(witness)
		if(witness_cultivator?.gain_insight(10, INSIGHT_SOURCE_WITNESS, cooldown = 5 MINUTES, silent = TRUE))
			to_chat(witness, span_notice("<i>Watching [user]'s breakthrough, you glimpse something of the Dao.</i>"))

/// Recoverable failures. Interrupted attempts only cost progress.
/datum/cultivation_breakthrough/proc/fail(interrupted = FALSE)
	var/mob/living/user = body
	var/datum/antagonist/cultivator/loser = cultivator
	qdel(src)
	if(!loser)
		return
	loser.breakthroughs_failed++
	if(ascension && !interrupted && !QDELETED(user))
		ascension_rejected(user, loser)
		return
	loser.progress = round(loser.progress * 0.75)
	loser.update_hud()
	if(interrupted || QDELETED(user))
		if(!QDELETED(user))
			to_chat(user, span_warning("Your breakthrough is interrupted! Some of your foundation scatters, but your realm holds."))
		return
	loser.adjust_instability(20)
	var/list/complications = list("crack", "leak", "demon")
	if(cultivation_get_artifact(user))
		complications += "artifact"
	switch(pick(complications))
		if("crack")
			var/obj/item/organ/dantian/dantian = loser.get_dantian()
			dantian?.crack()
			user.visible_message(span_danger("Something inside [user] cracks audibly!"), span_userdanger("Your core cracks! Your qi capacity is halved until you mend it with meditation on a mat."))
			loser.adjust_qi(0)
		if("leak")
			user.apply_status_effect(/datum/status_effect/qi_leak)
			user.visible_message(span_danger("Qi sprays from [user] in crackling sparks!"), span_userdanger("Your qi leaks out of you! Everyone will see you coming for a while."))
		if("artifact")
			var/obj/item/artifact = cultivation_get_artifact(user)
			qdel(artifact.GetComponent(/datum/component/cultivation_artifact))
			to_chat(user, span_userdanger("Your bond with [artifact] snaps! You'll have to bind it again."))
		if("demon")
			cultivation_summon_heart_demon(user)

/datum/cultivation_breakthrough/proc/cancel(message)
	if(message && body)
		to_chat(body, span_warning(message))
	fail(interrupted = TRUE)

/obj/effect/temp_visual/lightning_strike/tribulation
	name = "tribulation lightning"
	desc = "Heaven is about to smite this exact spot."
	duration = 1.5 SECONDS
	// No targeting marker, heaven doesn't warn you
	alpha = 0
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	damage_blacklist_typecache = list()

/obj/effect/temp_visual/cultivation_ascension_pillar
	icon = 'icons/effects/32x96.dmi'
	icon_state = "thunderbolt"
	color = "#ffe27a"
	duration = 2 SECONDS
	layer = ABOVE_ALL_MOB_LAYER
	blend_mode = BLEND_ADD
	randomdir = FALSE

/obj/effect/temp_visual/cultivation_ascension_pillar/Initialize(mapload)
	. = ..()
	// Bursts open from a thin thread of light, holds, then thins away
	transform = matrix().Scale(0.15, 1)
	alpha = 0
	animate(src, transform = matrix().Scale(1.6, 1), alpha = 255, time = 0.25 SECONDS, easing = SINE_EASING | EASE_OUT)
	animate(transform = matrix().Scale(1.2, 1), time = 1 SECONDS)
	animate(transform = matrix().Scale(0.1, 1), alpha = 0, time = 0.75 SECONDS, easing = SINE_EASING | EASE_IN)

/// Heaven slaps down a failed Ascension. Brutal, but you live to try again.
/datum/cultivation_breakthrough/proc/ascension_rejected(mob/living/user, datum/antagonist/cultivator/loser)
	loser.progress = round(loser.progress / 2)
	loser.adjust_instability(60)
	var/obj/item/organ/dantian/dantian = loser.get_dantian()
	dantian?.crack()
	user.apply_damage(40, BURN)
	user.Knockdown(5 SECONDS)
	new /obj/effect/temp_visual/lightning_strike/tribulation(get_turf(user))
	cultivation_great_bell(user, 70)
	minor_announce("The heavenly tribulation scatters. Heaven has rejected [user.real_name]'s Ascension.", "Heavenly Omen")
	user.visible_message(span_danger("A final, enormous bolt slams [user] into the floor!"), span_userdanger("Heaven rejects you! Your core cracks and half your foundation scatters... but you live."))

/// Shatter the void. The cultivator rises into the sky and leaves the round for the Immortal Realm.
/proc/cultivation_ascend(mob/living/user, datum/antagonist/cultivator/cultivator)
	if(QDELETED(user))
		return
	cultivator.ascended = TRUE
	user.log_message("ascended to the Immortal Realm", LOG_GAME)
	cultivation_breakthrough_sequence(user, "Immortal Ascension")
	cultivation_great_bell(user, 90)
	minor_announce("The void splits open above [user.real_name]. A cultivator has ascended to the Immortal Realm!", "Heavenly Omen")
	user.visible_message(span_boldnotice("[user] rises into a torrent of golden light pouring from a crack in the sky!"), span_boldnotice("The void opens. Immortality welcomes you."))
	user.add_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED, TRAIT_GODMODE), "ascension")
	for(var/i in 0 to 3)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cultivation_ascension_pillar_at), get_turf(user)), i * 1.5 SECONDS)
	animate(user, pixel_z = 192, alpha = 0, time = 6 SECONDS, easing = SINE_EASING | EASE_IN, flags = ANIMATION_RELATIVE | ANIMATION_PARALLEL)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cultivation_finish_ascension), user), 6 SECONDS)
	// Every cultivator on the station feels it
	for(var/datum/antagonist/cultivator/other in GLOB.antagonists)
		var/mob/living/feeler = other.owner?.current
		if(!feeler || feeler == user || feeler.stat == DEAD)
			continue
		to_chat(feeler, span_boldnotice("<i>Somewhere, someone has stepped beyond this world. For a moment, you glimpse the shape of the Dao.</i>"))
		other.gain_insight(15, INSIGHT_SOURCE_WITNESS, cooldown = 0, silent = TRUE)

/proc/cultivation_ascension_pillar_at(turf/where)
	new /obj/effect/temp_visual/cultivation_ascension_pillar(where)

/proc/cultivation_finish_ascension(mob/living/user)
	if(QDELETED(user))
		return
	var/turf/here = get_turf(user)
	user.unequip_everything()
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(here)
	user.ghostize(FALSE)
	qdel(user)
