// Techniques every cultivator learns, by realm.

// ----- Meditate -----

/datum/action/cooldown/spell/cultivation/meditate
	name = "Meditate"
	desc = "Sit still and circulate your qi. Consolidates pending insight into real progress, restores qi and calms instability. \
		Works best on a cultivation mat, in seclusion, surrounded by things that suit your laws."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "telepathy"
	cooldown_time = 5 SECONDS
	/// Sessions spent without a dantian, three regrows one
	var/dantian_regrowth = 0
	var/meditating = FALSE

/datum/action/cooldown/spell/cultivation/meditate/can_cast_spell(feedback = TRUE)
	// Meditating is how you regrow a lost dantian, so skip the usual dantian check
	if(!owner || !IS_CULTIVATOR(owner))
		return FALSE
	if(meditating)
		if(feedback)
			to_chat(owner, span_warning("You are already meditating."))
		return FALSE
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(owner)
	if(cultivator.breakthrough)
		return FALSE
	return TRUE

/datum/action/cooldown/spell/cultivation/meditate/cast(mob/living/cast_on)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(meditate), cast_on)

/datum/action/cooldown/spell/cultivation/meditate/proc/meditate(mob/living/user)
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(user)
	if(!cultivator)
		return
	meditating = TRUE
	var/datum/cultivation_site_report/report = cultivation_evaluate_site(user, cultivator)
	user.visible_message(span_notice("[user] sits cross-legged and begins to breathe slowly and deeply."), span_notice("You begin circulating your qi..."))
	user.add_filter("meditation_glow", 2, list("type" = "outline", "color" = "#9fe3ff", "size" = 1))
	var/success = do_after(user, 15 SECONDS, user, IGNORE_HELD_ITEM)
	user.remove_filter("meditation_glow")
	meditating = FALSE
	if(!success)
		to_chat(user, span_warning("Your meditation is broken!"))
		return
	// Someone wandered into your secluded retreat
	if(report.secluded && !cultivation_evaluate_site(user, cultivator).secluded)
		user.say(pick("WHO DARES DISTURB MY SECLUSION?!", "You! You are courting death!", "Insolent junior, you have ruined my closed-door cultivation!"), forced = "broken seclusion")
		report.multiplier -= 0.25

	var/obj/item/organ/dantian/dantian = cultivator.get_dantian()
	if(!dantian)
		dantian_regrowth++
		if(dantian_regrowth >= 3 && iscarbon(user))
			dantian_regrowth = 0
			var/obj/item/organ/dantian/new_dantian = new()
			new_dantian.Insert(user, special = TRUE)
			new_dantian.set_grade(REALM_QI_CONDENSATION)
			to_chat(user, span_boldnotice("A new dantian has condensed in this body! Break through again to restore it to your true realm."))
		else
			to_chat(user, span_notice("Slowly, a new dantian begins to take shape... ([dantian_regrowth]/3)"))
		return

	var/gained = cultivator.consolidate(report.multiplier)
	cultivator.adjust_qi(cultivator.max_qi() * (report.has_mat ? 0.6 : 0.35))
	cultivator.adjust_instability(report.has_mat ? -20 : -10)
	if(dantian.cracked && report.has_mat)
		if(dantian.mend_step())
			to_chat(user, span_boldnotice("The cracks in your core have sealed!"))
		else
			to_chat(user, span_notice("Your cracked core mends a little. ([dantian.mend_sessions] more sessions on a mat)"))
	to_chat(user, span_notice("You finish meditating. [gained ? "Consolidated [round(gained)] insight (x[round(report.multiplier, 0.01)])." : "You had no new insight to consolidate."]"))
	for(var/line in report.lines)
		to_chat(user, line)

// ----- Breakthrough -----

/datum/action/cooldown/spell/cultivation/breakthrough
	name = "Attempt Breakthrough"
	desc = "Once your foundation is full, attempt to break through to the next realm. Heaven will notice. Prepare well."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "lightning"
	cooldown_time = 30 SECONDS

/datum/action/cooldown/spell/cultivation/breakthrough/can_cast_spell(feedback = TRUE)
	. = ..()
	if(!.)
		return FALSE
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(owner)
	if(cultivator.breakthrough)
		if(feedback)
			to_chat(owner, span_warning("You are already breaking through!"))
		return FALSE
	var/obj/item/organ/dantian/dantian = cultivator.get_dantian()
	if(dantian.grade < cultivator.realm)
		return TRUE
	var/next = cultivator.next_threshold()
	if(!next)
		if(feedback)
			to_chat(owner, span_notice("You stand at the peak of what this world allows. Ascension is a matter for another day."))
		return FALSE
	if(cultivator.progress < next)
		if(feedback)
			to_chat(owner, span_warning("Your foundation isn't ready. ([round(cultivator.progress)]/[next] consolidated insight)"))
		return FALSE
	return TRUE

/datum/action/cooldown/spell/cultivation/breakthrough/cast(mob/living/cast_on)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(prepare), cast_on)

/datum/action/cooldown/spell/cultivation/breakthrough/proc/prepare(mob/living/user)
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(user)
	var/datum/cultivation_breakthrough/attempt = new(cultivator)
	var/list/readiness_lines = attempt.assess()
	to_chat(user, boxed_message(readiness_lines.Join("<br>")))
	var/answer = tgui_alert(user, "Readiness: [attempt.readiness_word()] ([attempt.readiness]). Begin the breakthrough?", "Breakthrough", list("Begin", "Not yet"))
	if(answer != "Begin" || QDELETED(user) || cultivator.breakthrough || !can_cast_spell())
		qdel(attempt)
		return
	attempt.start()

// ----- Spiritual Sense -----

/datum/action/cooldown/spell/cultivation/spiritual_sense
	name = "Spiritual Sense"
	desc = "Pulse your divine sense outward. Reveals nearby cultivators' realms, items steeped in qi, and how the five elements flow around you. \
		From Golden Core onward, you briefly see through walls."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "mindread"
	cooldown_time = 15 SECONDS
	qi_cost = 5

/datum/action/cooldown/spell/cultivation/spiritual_sense/cast(mob/living/cast_on)
	. = ..()
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(cast_on)
	var/list/lines = list(span_boldnotice("You extend your spiritual sense..."))
	for(var/mob/living/other in range(7, cast_on))
		if(other == cast_on)
			continue
		var/datum/antagonist/cultivator/other_cultivator = IS_CULTIVATOR(other)
		if(other_cultivator)
			var/their_realm = other_cultivator.effective_realm()
			if(their_realm > cultivator.effective_realm())
				lines += span_warning("[other]: an unfathomable cultivation base!")
			else
				lines += span_notice("[other]: [other_cultivator.realm_name(their_realm)] cultivator.")
		var/datum/component/spirit_beast/beast = other.GetComponent(/datum/component/spirit_beast)
		if(beast)
			lines += span_notice("[other]: a contracted spirit beast.")
	for(var/obj/item/thing in range(7, cast_on))
		if(thing.GetComponent(/datum/component/cultivation_artifact) || istype(thing, /obj/item/book/granter/cultivation_manual) || istype(thing, /obj/item/cultivation_talisman) || istype(thing, /obj/item/organ/dantian) || istype(thing, /obj/item/ancestral_ring))
			lines += span_notice("[thing] [isturf(thing.loc) ? "" : "(hidden) "]hums with qi.")
	var/datum/cultivation_site_report/report = cultivation_evaluate_site(cast_on, cultivator)
	lines += report.lines
	lines += span_notice("Meditation multiplier here: x[round(report.multiplier, 0.01)]. Breakthrough readiness modifier: [report.readiness_bonus >= 0 ? "+" : ""][report.readiness_bonus].")
	to_chat(cast_on, boxed_message(lines.Join("<br>")))
	if(cultivator.effective_realm() >= REALM_GOLDEN_CORE)
		ADD_TRAIT(cast_on, TRAIT_XRAY_VISION, REF(src))
		cast_on.update_sight()
		addtimer(CALLBACK(src, PROC_REF(end_sight), cast_on), 5 SECONDS)

/datum/action/cooldown/spell/cultivation/spiritual_sense/proc/end_sight(mob/living/user)
	REMOVE_TRAIT(user, TRAIT_XRAY_VISION, REF(src))
	user.update_sight()

// ----- Empty Palm -----

/datum/action/cooldown/spell/pointed/cultivation/empty_palm
	name = "Empty Palm"
	desc = "A palm strike carried by qi rather than muscle. Shoves an adjacent target several tiles away."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "repulse"
	cast_range = 1
	cooldown_time = 15 SECONDS
	qi_cost = 10

/datum/action/cooldown/spell/pointed/cultivation/empty_palm/is_valid_target(atom/cast_on)
	return ..() && ismovable(cast_on) && !isturf(cast_on)

/datum/action/cooldown/spell/pointed/cultivation/empty_palm/cast(atom/movable/cast_on)
	. = ..()
	var/mob/living/user = owner
	user.do_attack_animation(cast_on)
	playsound(cast_on, 'sound/effects/magic/repulse.ogg', 50, TRUE)
	if(isliving(cast_on))
		var/mob/living/victim = cast_on
		if(HAS_TRAIT(victim, TRAIT_PUSHIMMUNE) || victim.move_resist >= MOVE_FORCE_OVERPOWERING)
			victim.visible_message(span_warning("[user]'s palm strikes [victim], who doesn't budge an inch!"))
			return
		victim.visible_message(span_danger("[user]'s open palm sends [victim] flying!"), span_userdanger("[user]'s palm hits you like a battering ram!"))
		victim.adjust_staggered_up_to(STAGGERED_SLOWDOWN_LENGTH, 10 SECONDS)
	else if(cast_on.anchored)
		return
	var/turf/throw_target = get_edge_target_turf(cast_on, get_dir(user, cast_on))
	cast_on.throw_at(throw_target, 3, 2, user, spin = FALSE, gentle = TRUE)

// ----- Qinggong -----

/datum/action/cooldown/spell/pointed/cultivation/qinggong
	name = "Qinggong"
	desc = "The lightness skill. Dash a short distance, skimming over tables and railings."
	button_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "jetboot"
	cast_range = 4
	cooldown_time = 10 SECONDS
	qi_cost = 10
	aim_assist = FALSE

/datum/action/cooldown/spell/pointed/cultivation/qinggong/is_valid_target(atom/cast_on)
	return TRUE

/datum/action/cooldown/spell/pointed/cultivation/qinggong/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	var/mob/living/user = owner
	if(user.buckled || user.pulledby || HAS_TRAIT(user, TRAIT_RESTRAINED) || user.body_position == LYING_DOWN)
		user.balloon_alert(user, "can't leap now!")
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/pointed/cultivation/qinggong/cast(atom/cast_on)
	. = ..()
	var/mob/living/user = owner
	var/turf/target_turf = get_turf(cast_on)
	user.visible_message(span_notice("[user] springs into the air as light as a feather!"))
	var/old_pass = user.pass_flags
	user.pass_flags |= PASSTABLE
	user.throw_at(target_turf, cast_range, 2, user, spin = FALSE, gentle = TRUE, callback = CALLBACK(src, PROC_REF(land), user, old_pass))

/datum/action/cooldown/spell/pointed/cultivation/qinggong/proc/land(mob/living/user, old_pass)
	user.pass_flags = old_pass

// ----- Write Talisman -----

/datum/action/cooldown/spell/cultivation/write_talisman
	name = "Write Talisman"
	desc = "Inscribe a sheet of paper in your hand with qi, making a one-use talisman that anyone can use."
	button_icon = 'icons/obj/service/bureaucracy.dmi'
	button_icon_state = "paper_talisman"
	cooldown_time = 20 SECONDS
	qi_cost = 20

/datum/action/cooldown/spell/cultivation/write_talisman/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	var/mob/living/user = owner
	var/obj/item/paper/paper = user.is_holding_item_of_type(/obj/item/paper)
	if(!paper)
		to_chat(user, span_warning("You need a blank sheet of paper in hand!"))
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/cultivation/write_talisman/cast(mob/living/cast_on)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(write), cast_on)

/datum/action/cooldown/spell/cultivation/write_talisman/proc/write(mob/living/user)
	var/list/options = list()
	for(var/obj/item/cultivation_talisman/talisman_type as anything in subtypesof(/obj/item/cultivation_talisman))
		options[initial(talisman_type.name)] = talisman_type
	var/choice = tgui_input_list(user, "Which talisman?", "Write Talisman", options)
	var/obj/item/paper/paper = user.is_holding_item_of_type(/obj/item/paper)
	if(!choice || !paper)
		reset_spell_cooldown()
		var/datum/antagonist/cultivator/refund = IS_CULTIVATOR(user)
		refund?.adjust_qi(cultivation_actual_cost(refund, src, qi_cost))
		return
	user.visible_message(span_notice("[user] traces glowing characters across [paper] with a fingertip."))
	if(!do_after(user, 3 SECONDS, paper))
		return
	var/talisman_type = options[choice]
	qdel(paper)
	var/obj/item/cultivation_talisman/talisman = new talisman_type(user.drop_location())
	user.put_in_hands(talisman)
	var/datum/antagonist/cultivator/cultivation_datum = IS_CULTIVATOR(user)
	cultivation_datum?.gain_insight(3, INSIGHT_SOURCE_TALISMAN, cooldown = 60 SECONDS)

// ----- Teach -----

/datum/action/cooldown/spell/pointed/cultivation/teach
	name = "Accept Disciple"
	desc = "Pass one of your laws to a willing person beside you. A mortal will be awakened. Teaching is its own kind of insight."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "declaration"
	cast_range = 1
	cooldown_time = 60 SECONDS
	qi_cost = 30

/datum/action/cooldown/spell/pointed/cultivation/teach/is_valid_target(atom/cast_on)
	return ..() && ishuman(cast_on)

/datum/action/cooldown/spell/pointed/cultivation/teach/cast(mob/living/carbon/human/cast_on)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(teach), owner, cast_on)

/datum/action/cooldown/spell/pointed/cultivation/teach/proc/teach(mob/living/master, mob/living/carbon/human/disciple)
	var/datum/antagonist/cultivator/master_datum = IS_CULTIVATOR(master)
	if(!disciple.mind || !disciple.client)
		to_chat(master, span_warning("[disciple] has no mind to receive your teachings."))
		return
	var/list/options = list()
	for(var/datum/cultivation_law/law as anything in master_datum.laws)
		options[law.name] = law
	if(!length(options))
		return
	var/choice = tgui_input_list(master, "Teach which law?", "Accept Disciple", options)
	if(!choice)
		return
	var/datum/cultivation_law/law = options[choice]
	var/answer = tgui_alert(disciple, "[master] offers to accept you as a disciple and teach you the [law.name]. Do you accept?", "A Master Appears", list("Kowtow and accept", "Refuse"))
	if(answer != "Kowtow and accept")
		to_chat(master, span_warning("[disciple] refuses your teachings! How ungrateful."))
		return
	master.visible_message(span_notice("[master] places a palm on [disciple]'s forehead and begins to recite in a low voice."))
	if(!do_after(master, 10 SECONDS, disciple))
		return
	var/datum/antagonist/cultivator/disciple_datum = IS_CULTIVATOR(disciple)
	if(!disciple_datum)
		disciple_datum = disciple.mind.add_antag_datum(/datum/antagonist/cultivator)
	if(disciple_datum.has_law(law.type))
		var/datum/cultivation_law/their_law = disciple_datum.has_law(law.type)
		if(their_law.counterfeit && !law.counterfeit)
			their_law.counterfeit = FALSE
			to_chat(disciple, span_boldnotice("Your master corrects the errors in your counterfeit [law.name]!"))
		else
			to_chat(disciple, span_notice("You already know this law."))
		return
	if(disciple_datum.learn_law(law.type, law.counterfeit))
		master_datum.gain_insight(10, INSIGHT_SOURCE_TEACHING, cooldown = 5 MINUTES)
		to_chat(master, span_notice("You have taken [disciple] as a disciple."))

// ----- Acupoint Sealing -----

/datum/action/cooldown/spell/pointed/cultivation/acupoint
	name = "Acupoint Sealing"
	desc = "Jab a pressure point. Aim at the mouth to silence, at an arm to numb it, or at the legs to slow them. Armour can stop your fingers."
	button_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "neckchop"
	cast_range = 1
	cooldown_time = 45 SECONDS
	qi_cost = 25

/datum/action/cooldown/spell/pointed/cultivation/acupoint/is_valid_target(atom/cast_on)
	return ..() && iscarbon(cast_on)

/datum/action/cooldown/spell/pointed/cultivation/acupoint/cast(mob/living/carbon/cast_on)
	. = ..()
	var/mob/living/user = owner
	var/zone = user.zone_selected
	user.do_attack_animation(cast_on)
	var/armor = cast_on.run_armor_check(check_zone(zone), MELEE, silent = TRUE)
	if(armor >= 40)
		cast_on.visible_message(span_warning("[user] jabs at [cast_on], but [user.p_their()] fingers can't find the acupoint through the armour!"))
		return
	var/realm_gap = cultivation_realm_of(user) - cultivation_realm_of(cast_on)
	var/duration = clamp(4 SECONDS + realm_gap * 1 SECONDS, 2 SECONDS, 7 SECONDS)
	switch(zone)
		if(BODY_ZONE_PRECISE_MOUTH)
			cast_on.visible_message(span_danger("[user] jabs two fingers into [cast_on]'s throat!"), span_userdanger("Your voice is sealed!"))
			ADD_TRAIT(cast_on, TRAIT_MUTE, REF(src))
			addtimer(TRAIT_CALLBACK_REMOVE(cast_on, TRAIT_MUTE, REF(src)), duration)
		if(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND)
			var/left = (zone == BODY_ZONE_L_ARM || zone == BODY_ZONE_PRECISE_L_HAND)
			var/trait = left ? TRAIT_PARALYSIS_L_ARM : TRAIT_PARALYSIS_R_ARM
			cast_on.visible_message(span_danger("[user] jabs a point on [cast_on]'s arm!"), span_userdanger("Your arm goes numb!"))
			var/obj/item/held = cast_on.get_held_items_for_side(left ? LEFT_HANDS : RIGHT_HANDS)
			if(held)
				cast_on.dropItemToGround(held)
			ADD_TRAIT(cast_on, trait, REF(src))
			addtimer(CALLBACK(src, PROC_REF(unseal_arm), cast_on, trait), duration)
		else
			cast_on.visible_message(span_danger("[user] jabs a point on [cast_on]'s leg!"), span_userdanger("Your legs feel like lead!"))
			cast_on.apply_status_effect(/datum/status_effect/cultivation_slow, duration)

/datum/action/cooldown/spell/pointed/cultivation/acupoint/proc/unseal_arm(mob/living/carbon/target, trait)
	REMOVE_TRAIT(target, trait, REF(src))

// ----- Realm Pressure -----

/datum/action/cooldown/spell/cultivation/realm_pressure
	name = "Realm Pressure"
	desc = "Release the full weight of your cultivation. Anyone of a lower realm nearby (mortals included) is slowed and struggles to speak."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "terrify"
	cooldown_time = 90 SECONDS
	qi_cost = 40

/datum/action/cooldown/spell/cultivation/realm_pressure/cast(mob/living/cast_on)
	. = ..()
	var/my_realm = cultivation_realm_of(cast_on)
	cast_on.visible_message(span_boldwarning("The air around [cast_on] becomes crushingly heavy!"), span_boldnotice("You release your aura!"))
	playsound(cast_on, 'sound/effects/magic/repulse.ogg', 60, TRUE, frequency = 0.5)
	for(var/mob/living/victim in view(5, cast_on))
		if(victim == cast_on || victim.stat == DEAD)
			continue
		if(cultivation_realm_of(victim) >= my_realm)
			to_chat(victim, span_notice("You feel [cast_on]'s aura press against you, and push back."))
			continue
		to_chat(victim, span_userdanger("An overwhelming pressure bears down on you! Your knees buckle!"))
		victim.apply_status_effect(/datum/status_effect/cultivation_slow, 4 SECONDS)
		victim.adjust_stutter_up_to(8 SECONDS, 8 SECONDS)

// ----- Spirit Beast Contract -----

/datum/action/cooldown/spell/pointed/cultivation/beast_contract
	name = "Spirit Beast Contract"
	desc = "Bind a station animal as your spirit beast. It grows stronger as your realm rises. You can only hold one contract."
	button_icon = 'icons/mob/actions/actions_minor_antag.dmi'
	button_icon_state = "hoard"
	cast_range = 1
	cooldown_time = 30 SECONDS
	qi_cost = 30

/datum/action/cooldown/spell/pointed/cultivation/beast_contract/is_valid_target(atom/cast_on)
	if(!..())
		return FALSE
	if(!isanimal_or_basicmob(cast_on))
		to_chat(owner, span_warning("Only beasts can form a spirit contract."))
		return FALSE
	var/mob/living/beast = cast_on
	if(beast.stat == DEAD || beast.maxHealth > 200 || beast.mind)
		to_chat(owner, span_warning("[beast] cannot accept a contract."))
		return FALSE
	return TRUE

/datum/action/cooldown/spell/pointed/cultivation/beast_contract/cast(mob/living/cast_on)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(bind), owner, cast_on)

/datum/action/cooldown/spell/pointed/cultivation/beast_contract/proc/bind(mob/living/user, mob/living/beast)
	user.visible_message(span_notice("[user] presses a drop of blood to [beast]'s forehead and speaks softly."))
	if(!do_after(user, 5 SECONDS, beast))
		return
	for(var/mob/living/other_beast as anything in GLOB.mob_living_list)
		var/datum/component/spirit_beast/old = other_beast.GetComponent(/datum/component/spirit_beast)
		if(old?.master_mind == user.mind)
			to_chat(user, span_notice("You release [other_beast] from your old contract."))
			qdel(old)
	beast.AddComponent(/datum/component/spirit_beast, user.mind)
