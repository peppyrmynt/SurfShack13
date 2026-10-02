/**
 * # The Demonic Path
 *
 * Forbidden arts. Only true antagonists can comprehend the Demonic Scripture (traitors can buy it, and a copy
 * sometimes turns up in maintenance). Anyone else who reads it suffers a qi deviation.
 * A demonic master can transmit the arts to a willing disciple, but disciples can't pass them on: only the master holds the full scripture in their heart.
 *
 * Every art is loud to anyone with spiritual sense, and leaves heaven a little angrier: using them builds instability.
 */

/datum/antagonist/cultivator
	/// How far down the demonic path we've walked, see DEMONIC_* defines
	var/demonic = DEMONIC_NONE

/// Forbidden techniques, by required realm. Transmission is added separately for masters.
GLOBAL_LIST_INIT(cultivation_forbidden_techniques, list(
	/datum/action/cooldown/spell/pointed/cultivation/devouring_art = REALM_QI_CONDENSATION,
	/datum/action/cooldown/spell/pointed/cultivation/gu_worm = REALM_QI_CONDENSATION,
	/datum/action/cooldown/spell/cultivation/stir_gu = REALM_QI_CONDENSATION,
	/datum/action/cooldown/spell/pointed/cultivation/soul_search = REALM_FOUNDATION,
	/datum/action/cooldown/spell/pointed/cultivation/corpse_puppet = REALM_GOLDEN_CORE,
	/datum/action/cooldown/spell/cultivation/blood_escape = REALM_GOLDEN_CORE,
))

/// Is this mind a real antagonist (not just a fake antag datum like cultivator or a sect)?
/proc/cultivation_is_true_antag(datum/mind/mind)
	for(var/datum/antagonist/antag as anything in mind?.antag_datums)
		if(!(antag.antag_flags & FLAG_FAKE_ANTAG))
			return TRUE
	return FALSE

/// Walk the demonic path. Disciples who later become masters are upgraded, never downgraded.
/datum/antagonist/cultivator/proc/become_demonic(level)
	if(level <= demonic)
		return FALSE
	var/was_demonic = demonic
	demonic = level
	var/mob/living/body = owner.current
	if(!was_demonic && body)
		body.playsound_local(get_turf(body), 'sound/effects/magic/curse.ogg', 50, FALSE)
		new /obj/effect/temp_visual/circle_wave/cultivation/blood(get_turf(body))
		cultivation_particles(body, /particles/cultivation/blood, 3 SECONDS)
	if(level == DEMONIC_MASTER)
		to_chat(body, span_boldwarning("The scripture's characters crawl off the page and burrow into your heart. You have comprehended the Demonic Path! \
			You may transmit these arts to others, but they will never be able to pass them on."))
	else
		to_chat(body, span_boldwarning("Demonic qi takes root in your dantian. You have been taught the forbidden arts!"))
		to_chat(body, span_warning("Learning these arts does not make you an antagonist. Use them only as far as your own role and the server rules allow."))
	refresh_techniques()
	return TRUE

/datum/antagonist/cultivator/proc/grant_forbidden_techniques()
	if(!demonic)
		return
	for(var/technique_type in GLOB.cultivation_forbidden_techniques)
		if(realm >= GLOB.cultivation_forbidden_techniques[technique_type])
			grant_technique(technique_type)
	if(demonic >= DEMONIC_MASTER)
		grant_technique(/datum/action/cooldown/spell/pointed/cultivation/transmit_forbidden)

/datum/antagonist/cultivator/proc/admin_grant_forbidden(mob/admin)
	become_demonic(DEMONIC_MASTER)
	message_admins("[key_name_admin(admin)] granted [key_name_admin(owner)] the Demonic Path (master).")
	log_admin("[key_name(admin)] granted [key_name(owner)] the Demonic Path (master).")

/// Every forbidden art taints you a little. Heaven notices, and heart demons grow fat on it.
/proc/cultivation_demonic_taint(mob/living/user, amount = 4)
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(user)
	cultivator?.adjust_instability(amount)

/// What Spiritual Sense notices about someone's demonic qi
/proc/cultivation_sense_forbidden(mob/living/other)
	. = list()
	var/datum/antagonist/cultivator/other_cultivator = IS_CULTIVATOR(other)
	if(other_cultivator?.demonic)
		. += span_danger("[other] reeks of demonic qi!")
	if(other.has_status_effect(/datum/status_effect/gu_worm))
		. += span_warning("Something small and hungry squirms inside [other].")
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(other)
	if(body_datum?.stage)
		. += span_notice("[other]: a body cultivator at [body_datum.stage_name()]. No qi at all, but that body...")
	if(istype(other, /mob/living/basic/corpse_puppet))
		. += span_danger("[other] is a corpse strung up with demonic qi.")

/particles/cultivation/blood
	icon_state = "ember"
	color = "#b0101a"
	spawning = 5
	velocity = list(0, 0.4)
	position = generator(GEN_CIRCLE, 4, 18, NORMAL_RAND)

// ===================== The scripture =====================

/obj/item/book/granter/demonic_scripture
	name = "Heaven-Devouring Demonic Scripture"
	desc = "A book bound in something that is not quite leather. The characters inside seem to squirm when you aren't looking directly at them."
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'
	icon_state = "manual_demonic"
	remarks = list(
		"The righteous sects call it theft. Heaven itself is the greatest thief...",
		"Flesh is merely qi that has forgotten how to move...",
		"Raise the worm on your own blood for forty-nine days...",
		"A corpse remembers how to walk, if you remind it firmly...",
		"Spit blood, and the blood will carry you away...",
		"Those who hesitate are devoured. Those who devour do not hesitate.",
	)
	pages_to_mastery = 4
	reading_time = 4 SECONDS
	uses = 1

/obj/item/book/granter/demonic_scripture/examine(mob/user)
	. = ..()
	if(IS_CULTIVATOR(user))
		. += span_danger("Your dantian clenches just looking at it. Demonic qi pours off the pages.")

/obj/item/book/granter/demonic_scripture/can_learn(mob/living/user)
	if(!ishuman(user) || !user.mind)
		to_chat(user, span_warning("You can't make sense of the writhing characters."))
		return FALSE
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(user)
	if(cultivator?.demonic >= DEMONIC_MASTER)
		to_chat(user, span_warning("You already hold this scripture in your heart."))
		return FALSE
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(user)
	if(body_datum?.committed)
		to_chat(user, span_warning("The scripture needs qi to take root, and your meridians are sealed into flesh."))
		return FALSE
	if(!cultivation_is_true_antag(user.mind))
		qi_deviation(user, cultivator)
		return FALSE
	return TRUE

/// What happens to the righteous (or merely curious) when they read this
/obj/item/book/granter/demonic_scripture/proc/qi_deviation(mob/living/user, datum/antagonist/cultivator/cultivator)
	user.visible_message(span_danger("[user] stares into [src] and recoils, blood trickling from [user.p_their()] nose!"), span_userdanger("The characters claw at your mind! Your qi deviates!"))
	user.apply_damage(10, BRUTE, BODY_ZONE_HEAD)
	user.adjust_confusion(10 SECONDS)
	user.playsound_local(get_turf(user), 'sound/effects/magic/curse.ogg', 50, FALSE)
	cultivator?.adjust_instability(20)
	user.log_message("tried to read the demonic scripture without being an antagonist", LOG_GAME)

/obj/item/book/granter/demonic_scripture/on_reading_finished(mob/living/user)
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(user)
	if(!cultivator)
		cultivator = user.mind.add_antag_datum(/datum/antagonist/cultivator)
	cultivator.become_demonic(DEMONIC_MASTER)
	user.log_message("comprehended the Demonic Path", LOG_GAME)

/obj/item/book/granter/demonic_scripture/recoil(mob/living/user)
	to_chat(user, span_warning("The pages are blank and grey. Whatever lived in this book has already moved into someone's heart."))

/datum/uplink_item/dangerous/demonic_scripture
	name = "Heaven-Devouring Demonic Scripture"
	desc = "A forbidden cultivation scripture from a sect wiped out for practising it. Reading it awakens you as a cultivator (if you weren't one) \
		and teaches the Demonic Path: devour corpses for insight, plant gu worms you can stir from afar, search souls, puppet the dead and escape in a spray of blood. \
		You can transmit the arts to willing disciples, but they can't pass them on. Anyone with spiritual sense will smell demonic qi on you."
	item = /obj/item/book/granter/demonic_scripture
	cost = 6
	surplus = 10
	purchasable_from = UPLINK_TRAITORS

// ===================== Devouring Art =====================

/datum/action/cooldown/spell/pointed/cultivation/devouring_art
	name = "Devouring Art"
	desc = "Drink the essence of a corpse beside you, leaving a husk. You gain insight and qi and your wounds close; a dead cultivator gives up some of their cultivation. \
		Also drains someone dying in front of you. Taints your qi."
	cast_range = 1
	cooldown_time = 30 SECONDS
	qi_cost = 10

/datum/action/cooldown/spell/pointed/cultivation/devouring_art/is_valid_target(atom/cast_on)
	return ..() && isliving(cast_on)

/datum/action/cooldown/spell/pointed/cultivation/devouring_art/before_cast(mob/living/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	if(cast_on.stat == CONSCIOUS)
		owner.balloon_alert(owner, "too much resistance!")
		return . | SPELL_CANCEL_CAST
	if(cast_on.stat == DEAD && HAS_TRAIT(cast_on, TRAIT_HUSK))
		owner.balloon_alert(owner, "nothing left to devour")
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/pointed/cultivation/devouring_art/cast(mob/living/cast_on)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(devour), owner, cast_on)

/datum/action/cooldown/spell/pointed/cultivation/devouring_art/proc/devour(mob/living/user, mob/living/victim)
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(user)
	if(!cultivator)
		return
	user.visible_message(span_danger("[user] clamps a hand over [victim]'s face. Red mist streams out of [victim.p_them()] into [user]!"), span_notice("You begin to devour [victim]'s essence..."))
	var/datum/beam/drain = user.Beam(victim, icon_state = "drain_life", time = 7 SECONDS)
	var/obj/effect/abstract/particle_holder/mist = cultivation_particles(victim, /particles/cultivation/blood)
	playsound(victim, 'sound/effects/magic/demon_consume.ogg', 50, TRUE)
	var/finished = do_after(user, (victim.stat == DEAD ? 6 : 4) SECONDS, victim)
	qdel(drain)
	QDEL_NULL(mist)
	if(!finished || QDELETED(victim))
		return
	var/datum/antagonist/cultivator/victim_cultivator = IS_CULTIVATOR(victim)
	cultivation_demonic_taint(user, 5)
	if(victim.stat != DEAD)
		victim.apply_damage(15, BRUTE)
		victim.apply_damage(15, OXY)
		if(victim_cultivator)
			var/stolen = min(victim_cultivator.qi, 20)
			victim_cultivator.adjust_qi(-stolen)
			cultivator.adjust_qi(stolen)
		cultivator.gain_insight(5, "devour_living", cooldown = 60 SECONDS, silent = TRUE)
		to_chat(victim, span_userdanger("Something tears at the core of you!"))
		log_combat(user, victim, "drained (Devouring Art)")
		return
	// A corpse gives up everything
	victim.become_husk("devouring_art")
	user.heal_overall_damage(brute = 20, burn = 20)
	cultivator.adjust_qi(30)
	var/insight = 15
	if(victim_cultivator)
		var/stolen_progress = round(victim_cultivator.progress / 4)
		victim_cultivator.progress -= stolen_progress
		victim_cultivator.update_hud()
		insight += victim_cultivator.pending_insight + stolen_progress
		victim_cultivator.pending_insight = 0
		to_chat(user, span_boldwarning("You swallow the remnants of [victim]'s cultivation!"))
	cultivator.gain_insight(insight, null, silent = TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/blood(get_turf(user))
	user.visible_message(span_danger("[victim] withers to a dry husk as [user] drinks the last of [victim.p_them()]."), span_notice("Warm, stolen qi floods your meridians."))
	log_combat(user, victim, "devoured the corpse of (Devouring Art)")

// ===================== Gu worms =====================

/datum/action/cooldown/spell/pointed/cultivation/gu_worm
	name = "Plant Gu Worm"
	desc = "Slip a gu worm raised on your own blood into someone beside you. They feel only a sting. While it lives (five minutes) it sips their health into your qi, \
		and you can Stir the Gu to make it writhe from anywhere on the station. Holy water or garlic drives it out."
	cast_range = 1
	cooldown_time = 45 SECONDS
	qi_cost = 20

/datum/action/cooldown/spell/pointed/cultivation/gu_worm/is_valid_target(atom/cast_on)
	return ..() && iscarbon(cast_on)

/datum/action/cooldown/spell/pointed/cultivation/gu_worm/cast(mob/living/carbon/cast_on)
	. = ..()
	var/mob/living/user = owner
	if(cast_on.stat == DEAD)
		to_chat(user, span_warning("The worm won't take to a corpse."))
		return
	if(cast_on.has_status_effect(/datum/status_effect/gu_worm))
		to_chat(user, span_warning("[cast_on] already carries a worm."))
		return
	user.do_attack_animation(cast_on, ATTACK_EFFECT_PUNCH)
	cast_on.apply_status_effect(/datum/status_effect/gu_worm, user.mind)
	to_chat(cast_on, span_warning("You feel a sharp sting."))
	to_chat(user, span_notice("Your gu worm burrows into [cast_on]."))
	cultivation_demonic_taint(user, 3)
	log_combat(user, cast_on, "planted a gu worm in")

/datum/status_effect/gu_worm
	id = "gu_worm"
	alert_type = null
	duration = 5 MINUTES
	tick_interval = 10 SECONDS
	status_type = STATUS_EFFECT_UNIQUE
	/// Who raised the worm
	var/datum/mind/master_mind

/datum/status_effect/gu_worm/on_creation(mob/living/new_owner, datum/mind/master_mind)
	src.master_mind = master_mind
	return ..()

/datum/status_effect/gu_worm/Destroy()
	master_mind = null
	return ..()

/datum/status_effect/gu_worm/tick(seconds_between_ticks)
	if(owner.stat == DEAD)
		qdel(src)
		return
	if(owner.reagents?.has_reagent(/datum/reagent/water/holywater) || owner.reagents?.has_reagent(/datum/reagent/consumable/garlic))
		expel()
		return
	owner.adjustToxLoss(1)
	var/datum/antagonist/cultivator/master = IS_CULTIVATOR(master_mind?.current)
	master?.adjust_qi(2)

/// Something the worm hates drives it out
/datum/status_effect/gu_worm/proc/expel()
	owner.visible_message(span_warning("[owner] retches up a tiny, wriggling black worm, which shrivels on the floor!"), span_notice("You cough up something small and wriggling. You feel much better."))
	playsound(owner, 'sound/effects/splat.ogg', 40, TRUE)
	new /obj/effect/decal/cleanable/vomit(get_turf(owner))
	to_chat(master_mind?.current, span_warning("You feel one of your gu worms die."))
	qdel(src)

/// The master makes it writhe. Spends the worm.
/datum/status_effect/gu_worm/proc/stir()
	owner.visible_message(span_danger("[owner] doubles over, clutching [owner.p_their()] stomach!"), span_userdanger("Something is CHEWING you from the inside!"))
	owner.emote("scream")
	owner.Paralyze(2 SECONDS)
	owner.adjustToxLoss(15)
	owner.apply_damage(30, STAMINA)
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.vomit(VOMIT_CATEGORY_BLOOD, lost_nutrition = 0, distance = 1)
	owner.log_message("had a gu worm stirred by [key_name(master_mind?.current)]", LOG_ATTACK)
	qdel(src)

/datum/action/cooldown/spell/cultivation/stir_gu
	name = "Stir the Gu"
	desc = "Make one of your gu worms writhe inside its host, wherever they are: a few seconds of crippling pain and poison. The worm dies doing it."
	cooldown_time = 10 SECONDS
	qi_cost = 5

/datum/action/cooldown/spell/cultivation/stir_gu/cast(mob/living/cast_on)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(choose), cast_on)

/datum/action/cooldown/spell/cultivation/stir_gu/proc/choose(mob/living/user)
	var/list/hosts = list()
	for(var/mob/living/host as anything in GLOB.mob_living_list)
		var/datum/status_effect/gu_worm/worm = host.has_status_effect(/datum/status_effect/gu_worm)
		if(worm?.master_mind == user.mind)
			hosts[host.real_name] = worm
	if(!length(hosts))
		to_chat(user, span_warning("None of your worms are alive."))
		return
	var/choice = tgui_input_list(user, "Whose worm do you stir?", "Stir the Gu", hosts)
	var/datum/status_effect/gu_worm/worm = hosts[choice]
	if(QDELETED(worm))
		return
	to_chat(user, span_notice("You twist your qi, and far away, your worm bites."))
	worm.stir()

// ===================== Soul Search =====================

/datum/action/cooldown/spell/pointed/cultivation/soul_search
	name = "Soul Search"
	desc = "Rip through the memories of someone helpless beside you (restrained, unconscious or in crit). Learn who they really are and what they remember. \
		It bruises their brain."
	cast_range = 1
	cooldown_time = 60 SECONDS
	qi_cost = 35

/datum/action/cooldown/spell/pointed/cultivation/soul_search/is_valid_target(atom/cast_on)
	return ..() && ishuman(cast_on)

/datum/action/cooldown/spell/pointed/cultivation/soul_search/before_cast(mob/living/carbon/human/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	if(cast_on.stat == DEAD || !cast_on.mind)
		owner.balloon_alert(owner, "no soul to search")
		return . | SPELL_CANCEL_CAST
	if(cast_on.stat == CONSCIOUS && !HAS_TRAIT(cast_on, TRAIT_RESTRAINED) && !cast_on.incapacitated)
		owner.balloon_alert(owner, "they must be helpless!")
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/pointed/cultivation/soul_search/cast(mob/living/carbon/human/cast_on)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(search), owner, cast_on)

/datum/action/cooldown/spell/pointed/cultivation/soul_search/proc/search(mob/living/user, mob/living/carbon/human/victim)
	user.visible_message(span_danger("[user] grips [victim]'s skull. [victim.p_Their()] eyes roll back!"), span_notice("You plunge your divine sense into [victim]'s sea of consciousness..."))
	to_chat(victim, span_userdanger("Something is rummaging through your memories!"))
	victim.Shake(2, 2, 8 SECONDS)
	var/obj/effect/abstract/particle_holder/mist = cultivation_particles(victim, /particles/cultivation/void, 8 SECONDS)
	if(!do_after(user, 8 SECONDS, victim))
		qdel(mist)
		return
	var/datum/mind/mind = victim.mind
	if(!mind)
		return
	var/list/lines = list(span_boldnotice("The soul of [victim.real_name]"))
	lines += "Calling: [mind.assigned_role?.title || "none"]"
	var/list/allegiances = list()
	for(var/datum/antagonist/antag as anything in mind.antag_datums)
		if(!(antag.antag_flags & FLAG_FAKE_ANTAG))
			allegiances += antag.name
	lines += allegiances.len ? span_danger("Hidden allegiance: [english_list(allegiances)]") : "No hidden allegiance."
	var/datum/antagonist/cultivator/their_cultivation = IS_CULTIVATOR(victim)
	if(their_cultivation)
		var/list/law_names = list()
		for(var/datum/cultivation_law/law as anything in their_cultivation.laws)
			law_names += law.name
		lines += "Cultivation: [their_cultivation.realm_name()][length(law_names) ? ", [english_list(law_names)]" : ""][their_cultivation.demonic ? span_danger(", demonic path") : ""]"
	var/datum/jianghu_sect/sect = jianghu_sect_of(mind)
	if(sect)
		lines += "Sect: [sect.name] ([sect.rank_of(mind)])"
	var/shown = 0
	for(var/memory_key in mind.memories)
		var/datum/memory/memory = mind.memories[memory_key]
		if(!istype(memory) || !memory.name)
			continue
		lines += "<i>A memory: [memory.name]</i>"
		if(++shown >= 6)
			break
	to_chat(user, boxed_message(lines.Join("<br>")))
	victim.adjustOrganLoss(ORGAN_SLOT_BRAIN, 25)
	victim.adjust_confusion(15 SECONDS)
	to_chat(victim, span_warning("Your head throbs. Someone has seen everything."))
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(user)
	cultivator?.gain_insight(10, "soul_search", cooldown = 5 MINUTES, silent = TRUE)
	cultivation_demonic_taint(user, 5)
	log_combat(user, victim, "soul searched")

// ===================== Blood Escape =====================

/datum/action/cooldown/spell/cultivation/blood_escape
	name = "Heavenly Demon Blood Escape"
	desc = "Spit out a quarter of your life as a spray of blood and let it carry you 8 to 15 tiles away in a random direction. Breaks grabs and cuffs can't hold the blood."
	cooldown_time = 2 MINUTES
	qi_cost = 30
	spell_requirements = SPELL_REQUIRES_NO_ANTIMAGIC|SPELL_REQUIRES_MIND

/datum/action/cooldown/spell/cultivation/blood_escape/cast(mob/living/cast_on)
	. = ..()
	var/turf/start = get_turf(cast_on)
	var/turf/destination
	for(var/attempt in 1 to 30)
		var/turf/open/floor/candidate = locate(start.x + rand(-15, 15), start.y + rand(-15, 15), start.z)
		if(!istype(candidate) || get_dist(start, candidate) < 8 || candidate.is_blocked_turf(exclude_mobs = TRUE))
			continue
		destination = candidate
		break
	if(!destination)
		to_chat(cast_on, span_warning("Your blood finds nowhere to carry you!"))
		return
	cast_on.visible_message(span_danger("[cast_on] spits a torrent of blood and dissolves into a red mist!"), span_userdanger("You spit out your own life's blood and let it carry you away!"))
	cast_on.apply_damage(cast_on.maxHealth * 0.25, BRUTE, wound_bonus = CANT_WOUND)
	cast_on.add_splatter_floor(start)
	new /obj/effect/temp_visual/circle_wave/cultivation/blood(start)
	var/obj/effect/temp_visual/decoy/fading/mist = cultivation_afterimage(cast_on, 0.6 SECONDS)
	mist.color = "#b0101a"
	playsound(start, 'sound/effects/magic/exit_blood.ogg', 60, TRUE)
	cast_on.pulledby?.stop_pulling()
	if(iscarbon(cast_on))
		var/mob/living/carbon/carbon_caster = cast_on
		carbon_caster.uncuff()
	if(!do_teleport(cast_on, destination, channel = TELEPORT_CHANNEL_MAGIC))
		return
	cast_on.add_splatter_floor(destination)
	new /obj/effect/temp_visual/circle_wave/cultivation/blood(destination)
	playsound(destination, 'sound/effects/magic/enter_blood.ogg', 60, TRUE)
	cultivation_demonic_taint(cast_on, 4)

// ===================== Transmission =====================

/datum/action/cooldown/spell/pointed/cultivation/transmit_forbidden
	name = "Transmit Demonic Art"
	desc = "Pour the forbidden arts into a willing person beside you. A mortal will be awakened. They gain every art you know (as their realm allows), \
		but the scripture doesn't live in their heart: they can never pass it on."
	cast_range = 1
	cooldown_time = 60 SECONDS
	qi_cost = 40

/datum/action/cooldown/spell/pointed/cultivation/transmit_forbidden/is_valid_target(atom/cast_on)
	return ..() && ishuman(cast_on)

/datum/action/cooldown/spell/pointed/cultivation/transmit_forbidden/cast(mob/living/carbon/human/cast_on)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(transmit), owner, cast_on)

/datum/action/cooldown/spell/pointed/cultivation/transmit_forbidden/proc/transmit(mob/living/master, mob/living/carbon/human/disciple)
	if(!disciple.mind || !disciple.client)
		to_chat(master, span_warning("[disciple] has no mind to receive the arts."))
		return
	var/datum/antagonist/body_cultivator/body_disciple = IS_BODY_CULTIVATOR(disciple)
	if(body_disciple?.committed)
		to_chat(master, span_warning("[disciple]'s meridians are sealed into flesh. The arts can't take root."))
		return
	var/datum/antagonist/cultivator/existing = IS_CULTIVATOR(disciple)
	if(existing?.demonic)
		to_chat(master, span_warning("[disciple] already walks the demonic path."))
		return
	var/answer = tgui_alert(disciple, "[master] offers to teach you the forbidden Demonic Path: devouring, gu worms, soul search, corpse puppets, blood escape. \
		Those with spiritual sense will smell it on you forever. Do you accept?", "Forbidden Arts", list("Accept the darkness", "Refuse"))
	if(answer != "Accept the darkness")
		to_chat(master, span_warning("[disciple] refuses the forbidden arts."))
		return
	master.visible_message(span_danger("[master] presses a bloody thumb to [disciple]'s brow and whispers in a language that hurts to hear."))
	var/datum/beam/link = master.Beam(disciple, icon_state = "blood", time = 10 SECONDS)
	if(!do_after(master, 10 SECONDS, disciple))
		qdel(link)
		return
	qdel(link)
	var/datum/antagonist/cultivator/disciple_datum = IS_CULTIVATOR(disciple) || disciple.mind.add_antag_datum(/datum/antagonist/cultivator)
	disciple_datum.become_demonic(DEMONIC_DISCIPLE)
	var/datum/antagonist/cultivator/master_datum = IS_CULTIVATOR(master)
	master_datum?.gain_insight(10, INSIGHT_SOURCE_TEACHING, cooldown = 5 MINUTES)
	to_chat(master, span_notice("You have taken [disciple] as a disciple of the Demonic Path."))
	master.log_message("transmitted the Demonic Path to [key_name(disciple)]", LOG_GAME)

// ===================== Corpse Puppet =====================

/datum/action/cooldown/spell/pointed/cultivation/corpse_puppet
	name = "Corpse Puppet"
	desc = "String a human corpse beside you up with demonic qi. It hops after you as a jiangshi and obeys pet commands (alt-click it) for two minutes, then collapses. \
		A jiangshi-sealing talisman drops it at once."
	cast_range = 1
	cooldown_time = 90 SECONDS
	qi_cost = 50
	/// Our current puppet
	var/datum/weakref/puppet_ref

/datum/action/cooldown/spell/pointed/cultivation/corpse_puppet/is_valid_target(atom/cast_on)
	return ..() && ishuman(cast_on)

/datum/action/cooldown/spell/pointed/cultivation/corpse_puppet/before_cast(mob/living/carbon/human/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	if(cast_on.stat != DEAD)
		owner.balloon_alert(owner, "not dead yet!")
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/pointed/cultivation/corpse_puppet/cast(mob/living/carbon/human/cast_on)
	. = ..()
	var/mob/living/user = owner
	var/mob/living/basic/corpse_puppet/old_puppet = puppet_ref?.resolve()
	if(!QDELETED(old_puppet))
		old_puppet.collapse()
	var/realm = cultivation_realm_of(user)
	var/mob/living/basic/corpse_puppet/puppet = new(get_turf(cast_on))
	puppet.take_corpse(cast_on, user, 2 MINUTES + max(realm - REALM_GOLDEN_CORE, 0) * 1 MINUTES)
	puppet_ref = WEAKREF(puppet)
	user.visible_message(span_danger("[user] stabs two fingers into [cast_on]'s neck. The corpse jerks upright, arms outstretched!"), span_notice("You string the corpse up with your qi."))
	playsound(puppet, 'sound/effects/magic/castsummon.ogg', 50, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/blood(get_turf(puppet))
	cultivation_demonic_taint(user, 5)
	log_combat(user, cast_on, "raised as a corpse puppet")

/datum/ai_controller/basic_controller/corpse_puppet
	blackboard = list(
		BB_TARGETING_STRATEGY = /datum/targeting_strategy/basic/not_friends,
		BB_PET_TARGETING_STRATEGY = /datum/targeting_strategy/basic/not_friends,
		BB_TARGET_MINIMUM_STAT = HARD_CRIT,
	)
	ai_movement = /datum/ai_movement/basic_avoidance
	idle_behavior = null
	planning_subtrees = list(
		/datum/ai_planning_subtree/pet_planning,
	)

/// A hopping corpse. The real body rides inside it and drops out again when the qi runs out.
/mob/living/basic/corpse_puppet
	name = "jiangshi"
	desc = "A stiff corpse hopping about with its arms held straight out. Its eyes are empty."
	icon = 'icons/mob/simple/simple_human.dmi'
	icon_state = ""
	mob_biotypes = MOB_UNDEAD|MOB_HUMANOID
	maxHealth = 90
	health = 90
	speed = 1.3
	melee_damage_lower = 10
	melee_damage_upper = 15
	obj_damage = 20
	attack_verb_continuous = "claws"
	attack_verb_simple = "claw"
	attack_sound = 'sound/items/weapons/slash.ogg'
	attack_vis_effect = ATTACK_EFFECT_CLAW
	unsuitable_atmos_damage = 0
	unsuitable_cold_damage = 0
	unsuitable_heat_damage = 0
	basic_mob_flags = DEL_ON_DEATH
	death_message = "collapses as the qi holding it together unravels!"
	ai_controller = /datum/ai_controller/basic_controller/corpse_puppet
	/// The real corpse inside
	var/mob/living/carbon/human/corpse
	/// Who pulls the strings
	var/datum/weakref/master_ref
	/// Pet commands it understands
	var/static/list/puppet_commands = list(
		/datum/pet_command/idle,
		/datum/pet_command/free,
		/datum/pet_command/follow,
		/datum/pet_command/point_targeting/attack,
		/datum/pet_command/protect_owner,
	)

/mob/living/basic/corpse_puppet/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/obeys_commands, puppet_commands)
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(hop))

/mob/living/basic/corpse_puppet/Destroy()
	drop_corpse()
	master_ref = null
	return ..()

/// Take over a corpse: it rides inside us and we wear its face
/mob/living/basic/corpse_puppet/proc/take_corpse(mob/living/carbon/human/body, mob/living/master, lifetime)
	corpse = body
	appearance = body.appearance
	name = "jiangshi of [body.real_name]"
	transform = matrix()
	color = "#a9b8a4"
	layer = MOB_LAYER
	SET_PLANE_IMPLICIT(src, GAME_PLANE)
	body.forceMove(src)
	master_ref = WEAKREF(master)
	maxHealth = 60 + 30 * cultivation_realm_of(master)
	health = maxHealth
	befriend(master)
	faction = list(REF(master))
	add_filter("puppet_qi", 2, list("type" = "outline", "color" = "#b0101a", "size" = 1, "alpha" = 140))
	var/datum/component/obeys_commands/obedience = GetComponent(/datum/component/obeys_commands)
	for(var/command_name in obedience?.available_commands)
		var/datum/pet_command/command = obedience.available_commands[command_name]
		if(istype(command, /datum/pet_command/follow))
			command.try_activate_command(master)
			break
	addtimer(CALLBACK(src, PROC_REF(collapse)), lifetime)

/mob/living/basic/corpse_puppet/proc/hop(datum/source)
	SIGNAL_HANDLER
	animate(src, pixel_z = 6, time = 0.1 SECONDS, easing = SINE_EASING | EASE_OUT, flags = ANIMATION_RELATIVE | ANIMATION_PARALLEL)
	animate(pixel_z = -6, time = 0.1 SECONDS, easing = SINE_EASING | EASE_IN, flags = ANIMATION_RELATIVE)

/mob/living/basic/corpse_puppet/proc/drop_corpse()
	if(!corpse)
		return
	if(corpse.loc == src)
		corpse.forceMove(drop_location())
	corpse = null

/// The qi runs out (or a talisman seals it) and the body drops
/mob/living/basic/corpse_puppet/proc/collapse()
	if(QDELETED(src))
		return
	visible_message(span_warning("[src] goes rigid and topples over, just a corpse again."))
	playsound(src, 'sound/effects/bodyfall/bodyfall1.ogg', 50, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/blood(get_turf(src))
	qdel(src)

