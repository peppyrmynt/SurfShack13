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

/datum/cultivation_breakthrough/New(datum/antagonist/cultivator/cultivator)
	src.cultivator = cultivator
	body = cultivator.owner.current
	var/obj/item/organ/dantian/dantian = cultivator.get_dantian()
	restoration = dantian && dantian.grade < cultivator.realm
	var/target_realm = restoration ? dantian.grade + 1 : cultivator.realm + 1
	switch(target_realm)
		if(REALM_FOUNDATION)
			duration = 20
			strike_damage = 8
			strike_times = list(8, 15)
		if(REALM_GOLDEN_CORE)
			duration = 30
			strike_damage = 14
			strike_times = list(6, 11, 16, 21, 26)
		else
			duration = 40
			strike_damage = 18
			strike_times = list(5, 9, 13, 17, 21, 25, 29, 33, 37)

/datum/cultivation_breakthrough/Destroy(force)
	STOP_PROCESSING(SSprocessing, src)
	if(body)
		body.remove_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), REF(src))
		body.remove_filter("breakthrough_glow")
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

/datum/cultivation_breakthrough/proc/resolve()
	var/chance = readiness >= 70 ? 100 : clamp(readiness, 5, 95)
	if(prob(chance))
		succeed()
	else
		fail()

/datum/cultivation_breakthrough/proc/succeed()
	var/mob/living/user = body
	var/datum/antagonist/cultivator/winner = cultivator
	qdel(src)
	winner.advance_realm()
	user.visible_message(
		span_boldnotice("A pillar of golden light erupts from [user]! [user.p_They()] [user.p_have()] broken through to [winner.realm_name(winner.effective_realm())]!"),
		span_boldnotice("Your qi surges through every meridian. You have broken through to [winner.realm_name(winner.effective_realm())]!"),
	)
	playsound(user, 'sound/effects/magic/charge.ogg', 70, TRUE)
	new /obj/effect/temp_visual/cultivation_ascension_pillar(get_turf(user))

/// Recoverable failures. Interrupted attempts only cost progress.
/datum/cultivation_breakthrough/proc/fail(interrupted = FALSE)
	var/mob/living/user = body
	var/datum/antagonist/cultivator/loser = cultivator
	qdel(src)
	if(!loser)
		return
	loser.breakthroughs_failed++
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
			to_chat(user, span_userdanger("Your heart demon tears itself free!"))
			var/mob/living/simple_animal/hostile/illusion/heart_demon/demon = new(get_turf(user))
			demon.Copy_Parent(user, 60 SECONDS, 60, 8)
			demon.name = "heart demon of [user.real_name]"
			demon.GiveTarget(user)

/datum/cultivation_breakthrough/proc/cancel(message)
	if(message && body)
		to_chat(body, span_warning(message))
	fail(interrupted = TRUE)

/obj/effect/temp_visual/lightning_strike/tribulation
	name = "tribulation lightning"
	desc = "Heaven is about to smite this exact spot. Move."
	duration = 1.5 SECONDS
	color = "#ffe27a"
	damage_blacklist_typecache = list()

/mob/living/simple_animal/hostile/illusion/heart_demon
	desc = "Your own face, twisted by every doubt you ever had."
	color = "#c070ff"

/obj/effect/temp_visual/cultivation_ascension_pillar
	icon = 'icons/effects/32x96.dmi'
	icon_state = "thunderbolt"
	color = "#ffe27a"
	duration = 1.5 SECONDS
