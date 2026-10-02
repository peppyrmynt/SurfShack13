/**
 * # Powers of the Mandate of Heaven
 *
 * Wuxia emperors. On top of the aura and the Imperial Decree, a ruler carries Dragon Qi, Heaven's Protection and Heaven's Fortune,
 * grows stronger the longer the dynasty lasts, commands the weak to kneel, opens the Imperial Treasury, pardons the disgraced,
 * appoints Jinyiwei guards and accepts the fealty of sects. The Son of Heaven also ennobles the crew and can call down Heaven's Punishment.
 * Murder a ruler and heaven marks you as a regicide.
 */

/// Minutes of unbroken rule for each dynasty tier
#define DYNASTY_TIER_1 (15 MINUTES)
#define DYNASTY_TIER_2 (30 MINUTES)
#define DYNASTY_TIER_3 (60 MINUTES)

/datum/component/mandate_of_heaven
	/// world.time this ruler took the Mandate
	var/held_since = 0
	/// 0-3, rises at 15, 30 and 60 minutes of unbroken rule
	var/dynasty_tier = 0
	/// Treasury openings still available (one at the start, one more per dynasty tier)
	var/treasury_charges = 1
	/// Has the Son of Heaven's treasury already given up its artifact
	var/treasury_artifact_given = FALSE
	/// Heaven's Punishment uses left (one, and another at the third dynasty tier)
	var/punishment_charges = 1
	/// Who hit us last, and when (for Heaven's Protection and the regicide curse)
	var/datum/weakref/last_attacker_ref
	var/last_attacked_time = 0
	/// REF(attacker) -> world.time Dragon Qi can rebuke them again
	var/list/rebuke_cooldowns = list()
	/// Weakrefs to nobles and guards we appointed
	var/list/datum/weakref/nobles = list()
	var/list/datum/weakref/guards = list()
	/// The rulers who held this Mandate before, oldest first
	var/list/lineage = list()
	/// The powers we granted
	var/list/datum/action/powers = list()
	/// Golden dragon coiled around the Son of Heaven
	var/obj/effect/abstract/cultivation_vis/dragon
	COOLDOWN_DECLARE(protection_cooldown)

/// Called from RegisterWithParent
/datum/component/mandate_of_heaven/proc/setup_powers()
	var/mob/living/carbon/human/ruler = parent
	held_since = world.time
	if(!HAS_TRAIT(ruler, TRAIT_RELAYING_ATTACKER))
		ruler.AddElement(/datum/element/relay_attackers)
	RegisterSignal(ruler, COMSIG_ATOM_WAS_ATTACKED, PROC_REF(on_attacked))
	RegisterSignal(ruler, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, PROC_REF(heavens_protection))
	RegisterSignal(ruler, COMSIG_MOB_AFTER_APPLY_DAMAGE, PROC_REF(after_damage))
	RegisterSignal(ruler, COMSIG_LIVING_CHECK_BLOCK, PROC_REF(heavens_fortune))
	var/list/power_types = list(
		/datum/action/cooldown/mandate_power/kneel,
		/datum/action/cooldown/mandate_power/treasury,
		/datum/action/cooldown/mandate_power/pardon,
		/datum/action/cooldown/mandate_power/jinyiwei,
		/datum/action/cooldown/mandate_power/fealty,
	)
	if(son_of_heaven)
		power_types += list(/datum/action/cooldown/mandate_power/ennoble, /datum/action/cooldown/mandate_power/punishment)
		dragon = cultivation_attach_vis(ruler, 'surfshack13/icons/cultivation/cultivation_effects_64.dmi', "dragon_aura", null, 64, 0, 110)
		dragon.layer = BELOW_MOB_LAYER
	for(var/power_type in power_types)
		var/datum/action/power = new power_type(src)
		power.Grant(ruler)
		powers += power
	to_chat(ruler, span_notice("Heaven's favour is yours: Dragon Qi rebukes the weak who strike you, Heaven's Protection and Fortune guard you, \
		and your dynasty grows stronger the longer it lasts. Command the weak to <b>Kneel</b>, open the <b>Imperial Treasury</b>, appoint <b>Jinyiwei</b>, \
		<b>Pardon</b> the disgraced and accept the <b>Fealty</b> of sects[son_of_heaven ? ". As the Son of Heaven you may also <b>Ennoble</b> the crew and call down <b>Heaven's Punishment</b>" : ""]."))

/// Called from UnregisterFromParent
/datum/component/mandate_of_heaven/proc/teardown_powers()
	var/mob/living/carbon/human/ruler = parent
	UnregisterSignal(ruler, list(COMSIG_ATOM_WAS_ATTACKED, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, COMSIG_MOB_AFTER_APPLY_DAMAGE, COMSIG_LIVING_CHECK_BLOCK))
	QDEL_LIST(powers)
	cultivation_detach_vis(ruler, dragon)
	dragon = null
	// Titles and offices die with the throne
	for(var/datum/weakref/noble_ref as anything in nobles + guards)
		var/mob/living/appointee = noble_ref.resolve()
		if(!appointee)
			continue
		qdel(appointee.GetComponent(/datum/component/imperial_noble))
		qdel(appointee.GetComponent(/datum/component/imperial_guard))
		to_chat(appointee, span_warning("Your lord has lost the Mandate of Heaven, and your office falls with it."))
	nobles.Cut()
	guards.Cut()
	for(var/datum/jianghu_sect/sect as anything in GLOB.jianghu_sects)
		if(sect.liege == ruler.mind)
			sect.liege = null
			sect.announce("Our liege has lost the Mandate of Heaven. Our oath of fealty is ended.")

/// Sects sworn to us
/datum/component/mandate_of_heaven/proc/sworn_sects()
	var/mob/living/carbon/human/ruler = parent
	. = 0
	for(var/datum/jianghu_sect/sect as anything in GLOB.jianghu_sects)
		if(sect.liege && sect.liege == ruler.mind)
			.++

// ----- Dynasty Age -----

/datum/component/mandate_of_heaven/proc/update_dynasty()
	var/held = world.time - held_since
	var/new_tier = 0
	if(held >= DYNASTY_TIER_3)
		new_tier = 3
	else if(held >= DYNASTY_TIER_2)
		new_tier = 2
	else if(held >= DYNASTY_TIER_1)
		new_tier = 1
	if(new_tier <= dynasty_tier)
		return
	dynasty_tier = new_tier
	treasury_charges++
	if(dynasty_tier >= 3)
		punishment_charges++
	var/mob/living/carbon/human/ruler = parent
	ruler.remove_filter("mandate_of_heaven")
	ruler.add_filter("mandate_of_heaven", 3, list("type" = "outline", "color" = "#ffd55a", "size" = 1, "alpha" = (son_of_heaven ? 110 : 60) + 35 * dynasty_tier))
	if(dragon)
		animate(dragon, alpha = 110 + 45 * dynasty_tier, time = 2 SECONDS)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(get_turf(ruler))
	cultivation_temple_sound(ruler, 50)
	to_chat(ruler, span_boldnotice("Your dynasty endures. Heaven's favour deepens (dynasty age [dynasty_tier]): stronger protection, better fortune, and the Imperial Treasury may be opened again."))

// ----- Dragon Qi -----

/// The weak who strike a ruler are rebuked by the dragon
/datum/component/mandate_of_heaven/proc/on_attacked(mob/living/victim, atom/attacker, attack_flags)
	SIGNAL_HANDLER
	if(!isliving(attacker) || attacker == victim)
		return
	var/mob/living/assailant = attacker
	last_attacker_ref = WEAKREF(assailant)
	last_attacked_time = world.time
	for(var/datum/weakref/guard_ref as anything in guards)
		var/mob/living/guard = guard_ref.resolve()
		if(guard && guard.stat == CONSCIOUS && guard != assailant)
			to_chat(guard, span_userdanger("Your lord [victim.real_name] is under attack by [assailant][guard.z == victim.z ? ", [dir2text(get_dir(guard, victim))] of you, [get_dist(guard, victim)] tiles away" : ""]!"))
	if(world.time < rebuke_cooldowns[REF(assailant)] || assailant.GetComponent(/datum/component/mandate_of_heaven))
		return
	if(cultivation_realm_of(assailant) > cultivation_realm_of(victim) + (son_of_heaven ? 1 : 0))
		return
	rebuke_cooldowns[REF(assailant)] = world.time + 10 SECONDS
	assailant.adjust_staggered_up_to(STAGGERED_SLOWDOWN_LENGTH, 10 SECONDS)
	assailant.Shake(2, 2, 0.4 SECONDS)
	to_chat(assailant, span_warning("Imperial dragon qi recoils against you!"))
	new /obj/effect/temp_visual/cultivation_spark(get_turf(assailant), "#ffd55a")
	if(son_of_heaven || dynasty_tier >= 2 || sworn_sects() >= 2)
		assailant.Knockdown(0.5 SECONDS + 0.25 SECONDS * dynasty_tier)

// ----- Heaven's Protection -----

/datum/component/mandate_of_heaven/proc/heavens_protection(mob/living/source, list/damage_mods, damage, damagetype, ...)
	SIGNAL_HANDLER
	if(damagetype != BRUTE && damagetype != BURN)
		return
	var/reduction = (son_of_heaven ? 0.2 : 0.1) + 0.025 * dynasty_tier + 0.02 * min(sworn_sects(), 3)
	damage_mods += 1 - reduction

/// A blow that would fell the ruler is turned aside, and heaven answers the attacker with lightning
/datum/component/mandate_of_heaven/proc/after_damage(mob/living/source, damage, damagetype, def_zone, blocked, wound_bonus, bare_wound_bonus, sharpness, attack_direction, attacking_item)
	SIGNAL_HANDLER
	if(source.stat == DEAD || source.health > source.crit_threshold || !COOLDOWN_FINISHED(src, protection_cooldown))
		return
	if(damagetype != BRUTE && damagetype != BURN)
		return
	COOLDOWN_START(src, protection_cooldown, son_of_heaven ? 6 MINUTES : 10 MINUTES)
	INVOKE_ASYNC(src, PROC_REF(heaven_intervenes), source, damage, damagetype)

/datum/component/mandate_of_heaven/proc/heaven_intervenes(mob/living/ruler, damage, damagetype)
	ruler.heal_overall_damage(brute = (damagetype == BRUTE ? damage : 0) + 15, burn = (damagetype == BURN ? damage : 0) + 15)
	ruler.visible_message(span_boldwarning("A golden light flares around [ruler] and the fatal blow is turned aside!"), span_boldnotice("Heaven turns aside the blow that would have felled you!"))
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(get_turf(ruler))
	cultivation_great_bell(ruler, 60)
	var/mob/living/assailant = last_attacker_ref?.resolve()
	if(assailant && world.time - last_attacked_time <= 5 SECONDS && assailant.z == ruler.z && get_dist(assailant, ruler) <= 12)
		var/obj/effect/temp_visual/lightning_strike/tribulation/bolt = new(get_turf(assailant))
		bolt.zap_damage = 25
		to_chat(assailant, span_userdanger("The sky darkens over you. Heaven is angry!"))
	minor_announce("Heaven has shielded [ruler.real_name], who bears its Mandate, from a fatal blow.", "Omen of Heaven")

// ----- Heaven's Fortune -----

/datum/component/mandate_of_heaven/proc/heavens_fortune(mob/living/source, atom/hit_by, damage, attack_text, attack_type, armour_penetration, damage_type)
	SIGNAL_HANDLER
	if(!prob((son_of_heaven ? 10 : 5) + 2 * dynasty_tier))
		return NONE
	source.visible_message(span_warning("By heaven's fortune, [attack_text] misses [source] entirely!"), span_notice("Heaven's fortune turns [attack_text] aside!"))
	new /obj/effect/temp_visual/cultivation_spark(get_turf(source), "#ffd55a")
	return SUCCESSFUL_BLOCK

/// Readiness bonus heaven gives its chosen for breakthroughs and tribulations
/proc/mandate_readiness_bonus(mob/living/ruler)
	var/datum/component/mandate_of_heaven/mandate = ruler?.GetComponent(/datum/component/mandate_of_heaven)
	if(!mandate)
		return 0
	return (mandate.son_of_heaven ? 15 : 10) + 5 * mandate.dynasty_tier

/// Extra cultivation speed from titles and fealty (nobles and sworn sects), added to insight and tempering
/proc/mandate_cultivation_bonus(mob/living/who)
	. = 0
	if(who?.GetComponent(/datum/component/imperial_noble))
		. += 0.15
	if(who?.GetComponent(/datum/component/imperial_guard))
		. += 0.1
	var/datum/jianghu_sect/sect = jianghu_sect_of(who?.mind)
	var/mob/living/liege = sect?.liege?.current
	if(liege?.GetComponent(/datum/component/mandate_of_heaven))
		. += 0.1

// ===================== Powers =====================

/datum/action/cooldown/mandate_power
	name = "Imperial Power"
	button_icon = 'surfshack13/icons/cultivation/cultivation_actions.dmi'
	background_icon_state = "bg_heretic"
	overlay_icon_state = "bg_heretic_border"
	check_flags = AB_CHECK_CONSCIOUS
	cooldown_time = 60 SECONDS

/datum/action/cooldown/mandate_power/proc/get_mandate()
	return target

/// Humans the ruler can see, for choosing who a power applies to
/datum/action/cooldown/mandate_power/proc/pick_subject(question, range = 7)
	var/list/options = list()
	for(var/mob/living/carbon/human/subject in view(range, owner))
		if(subject != owner && subject.stat != DEAD)
			options[subject.real_name] = subject
	if(!length(options))
		to_chat(owner, span_warning("There is no one here."))
		return null
	var/choice = tgui_input_list(owner, question, name, options)
	var/mob/living/carbon/human/chosen = options[choice]
	if(QDELETED(chosen) || !(chosen in view(range, owner)))
		return null
	return chosen

// ----- Kneel! -----

/datum/action/cooldown/mandate_power/kneel
	name = "Kneel!"
	desc = "Command everyone around you whose cultivation is no greater than yours to kneel. They are forced to the floor. The Son of Heaven's command reaches further and lasts longer."
	button_icon_state = "mandate_kneel"
	cooldown_time = 60 SECONDS

/datum/action/cooldown/mandate_power/kneel/Activate(atom/target)
	var/datum/component/mandate_of_heaven/mandate = get_mandate()
	var/mob/living/ruler = owner
	var/reach = (mandate.son_of_heaven ? 6 : 4) + mandate.dynasty_tier
	var/my_realm = cultivation_realm_of(ruler)
	ruler.say("KNEEL!", forced = "mandate of heaven")
	playsound(ruler, 'sound/effects/gong.ogg', 70, TRUE, frequency = 0.8)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(get_turf(ruler))
	cultivation_distortion_wave(ruler, reach, 0.6 SECONDS, 200)
	for(var/mob/living/subject in view(reach, ruler))
		if(subject == ruler || subject.stat != CONSCIOUS || subject.GetComponent(/datum/component/mandate_of_heaven))
			continue
		if(cultivation_realm_of(subject) > my_realm)
			to_chat(subject, span_notice("[ruler]'s imperial command washes over you. You stay on your feet."))
			continue
		subject.Knockdown((mandate.son_of_heaven ? 3 : 2) SECONDS)
		subject.visible_message(span_warning("[subject] is forced to [subject.p_their()] knees!"), span_userdanger("Heaven's chosen commands it: you fall to your knees!"))
	StartCooldown()
	return TRUE

// ----- Imperial Treasury -----

/datum/action/cooldown/mandate_power/treasury
	name = "Imperial Treasury"
	desc = "Open the Imperial Treasury: graded pills, talismans, refining metals, a manual, and sometimes a legendary artifact (the Son of Heaven's treasury \
		always holds one once the dynasty has lasted fifteen minutes). You can open it once, and once more for every dynasty age."
	button_icon_state = "mandate_treasury"
	cooldown_time = 10 SECONDS

/datum/action/cooldown/mandate_power/treasury/Activate(atom/target)
	var/datum/component/mandate_of_heaven/mandate = get_mandate()
	if(mandate.treasury_charges <= 0)
		to_chat(owner, span_warning("The treasury is bare for now. It will refill as your dynasty endures."))
		return FALSE
	mandate.treasury_charges--
	var/turf/here = get_turf(owner)
	owner.visible_message(span_boldnotice("[owner] raises a hand and the doors of the Imperial Treasury open in a blaze of gold!"))
	new /obj/effect/temp_visual/cultivation_ascension_pillar(here)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(here)
	cultivation_great_bell(owner, 60)
	cultivation_guqin_phrase(owner, list(1, 2, 3, 5, 6))
	// Pills, all at least high grade
	var/static/list/pill_types = list(
		/obj/item/cultivation_pill/qi_gathering,
		/obj/item/cultivation_pill/foundation,
		/obj/item/cultivation_pill/tribulation,
		/obj/item/cultivation_pill/tempering,
		/obj/item/cultivation_pill/marrow_cleansing,
		/obj/item/cultivation_pill/pure_heart,
		/obj/item/cultivation_pill/spirit_beast,
	)
	for(var/i in 1 to (mandate.son_of_heaven ? 6 : 4) + mandate.dynasty_tier)
		var/pill_type = pick(pill_types)
		var/obj/item/cultivation_pill/pill = new pill_type(here)
		pill.set_grade(prob(35 + 10 * mandate.dynasty_tier) ? PILL_GRADE_SPIRIT : PILL_GRADE_HIGH)
	var/obj/item/cultivation_pill/nine = new /obj/item/cultivation_pill/nine_revolutions(here)
	nine.set_grade(mandate.son_of_heaven ? PILL_GRADE_SPIRIT : PILL_GRADE_HIGH)
	// Talismans
	var/list/talisman_types = subtypesof(/obj/item/cultivation_talisman)
	for(var/i in 1 to 3 + mandate.dynasty_tier)
		var/talisman_type = pick(talisman_types)
		new talisman_type(here)
	// Refining metals for bound artifacts
	new /obj/item/stack/sheet/mineral/gold(here, 10)
	new /obj/item/stack/sheet/mineral/diamond(here, 3 + mandate.dynasty_tier)
	if(mandate.son_of_heaven)
		new /obj/item/stack/sheet/bluespace_crystal(here, 5)
	// A manual: a law or the Body Molding Art
	if(prob(50))
		var/static/list/manual_types = list(
			/obj/item/book/granter/cultivation_manual/returning_iron,
			/obj/item/book/granter/cultivation_manual/still_water,
			/obj/item/book/granter/cultivation_manual/furnace_heart,
			/obj/item/book/granter/cultivation_manual/rooted_mountain,
			/obj/item/book/granter/cultivation_manual/evergreen_spring,
		)
		var/manual_type = pick(manual_types)
		new manual_type(here)
	else
		new /obj/item/book/granter/body_manual/molding_art(here)
	// A legendary artifact
	var/artifact_chance = mandate.son_of_heaven ? (mandate.treasury_artifact_given ? 50 : (mandate.dynasty_tier >= 1 ? 100 : 30)) : (mandate.dynasty_tier >= 2 ? 25 : 5)
	if(prob(artifact_chance))
		mandate.treasury_artifact_given = TRUE
		new /obj/effect/spawner/random/legendary_artifact(here)
		owner.visible_message(span_boldwarning("Among the treasures lies a legendary artifact, humming with ancient power!"))
	owner.log_message("opened the Imperial Treasury", LOG_GAME)
	to_chat(owner, span_notice("Treasury openings left: [mandate.treasury_charges]."))
	StartCooldown()
	return TRUE

// ----- Imperial Pardon -----

/datum/action/cooldown/mandate_power/pardon
	name = "Imperial Pardon"
	desc = "Pardon someone in sight: their disgrace in the jianghu is wiped away and their lost face restored."
	button_icon_state = "mandate_pardon"
	cooldown_time = 5 MINUTES

/datum/action/cooldown/mandate_power/pardon/Activate(atom/target)
	var/mob/living/carbon/human/pardoned = pick_subject("Pardon whom?")
	if(!pardoned?.mind)
		return FALSE
	GLOB.jianghu_dishonor -= pardoned.mind
	var/face = jianghu_face_of(pardoned.mind)
	if(face < 0)
		jianghu_adjust_face(pardoned, -face, "received an imperial pardon")
	jianghu_adjust_face(pardoned, 3, "received an imperial pardon")
	owner.say("By the Mandate of Heaven, [pardoned.real_name] is pardoned!", forced = "mandate of heaven")
	new /obj/effect/temp_visual/circle_wave/cultivation/gold(get_turf(pardoned))
	to_chat(pardoned, span_boldnotice("Heaven's chosen has pardoned you. Your disgrace is forgotten."))
	StartCooldown()
	return TRUE

// ----- Jinyiwei -----

/datum/action/cooldown/mandate_power/jinyiwei
	name = "Appoint Jinyiwei"
	desc = "Appoint someone in sight as your Jinyiwei, an imperial guard (one, two for the Son of Heaven). They are warned whenever you are attacked and told where, \
		and cultivate a little faster. Use it on a guard to dismiss them."
	button_icon_state = "mandate_jinyiwei"
	cooldown_time = 30 SECONDS

/datum/action/cooldown/mandate_power/jinyiwei/Activate(atom/target)
	var/datum/component/mandate_of_heaven/mandate = get_mandate()
	var/mob/living/carbon/human/appointee = pick_subject("Appoint (or dismiss) whom as Jinyiwei?")
	if(!appointee)
		return FALSE
	var/datum/component/imperial_guard/existing = appointee.GetComponent(/datum/component/imperial_guard)
	if(existing)
		qdel(existing)
		owner.say("[appointee.real_name], you are dismissed from the Jinyiwei.", forced = "mandate of heaven")
		StartCooldown()
		return TRUE
	for(var/datum/weakref/guard_ref as anything in mandate.guards.Copy())
		if(!guard_ref.resolve())
			mandate.guards -= guard_ref
	if(length(mandate.guards) >= (mandate.son_of_heaven ? 2 : 1))
		to_chat(owner, span_warning("You already have as many Jinyiwei as heaven allows. Dismiss one first."))
		return FALSE
	if(tgui_alert(appointee, "[owner.real_name] appoints you to the Jinyiwei, the imperial guard. Accept?", "Jinyiwei", list("Accept", "Refuse")) != "Accept")
		to_chat(owner, span_warning("[appointee] declines."))
		return FALSE
	appointee.AddComponent(/datum/component/imperial_guard, owner)
	mandate.guards += WEAKREF(appointee)
	owner.say("[appointee.real_name], you serve the throne as Jinyiwei!", forced = "mandate of heaven")
	StartCooldown()
	return TRUE

// ----- Accept Fealty -----

/datum/action/cooldown/mandate_power/fealty
	name = "Accept Fealty"
	desc = "Accept the fealty of a sect master in sight. Their sect cultivates faster under your rule, and every sworn sect (up to three) strengthens your Heaven's Protection and Dragon Qi."
	button_icon_state = "mandate_fealty"
	cooldown_time = 60 SECONDS

/datum/action/cooldown/mandate_power/fealty/Activate(atom/target)
	var/list/options = list()
	for(var/mob/living/carbon/human/master in view(7, owner))
		var/datum/jianghu_sect/sect = jianghu_sect_of(master.mind)
		if(master != owner && sect && sect.master == master.mind && sect.liege != owner.mind)
			options["[master.real_name] of the [sect.name]"] = master
	if(!length(options))
		to_chat(owner, span_warning("There is no sect master here to swear fealty."))
		return FALSE
	var/choice = tgui_input_list(owner, "Accept whose fealty?", name, options)
	var/mob/living/carbon/human/master = options[choice]
	var/datum/jianghu_sect/sect = jianghu_sect_of(master?.mind)
	if(!sect)
		return FALSE
	if(tgui_alert(master, "[owner.real_name], who holds the Mandate of Heaven, offers to accept the [sect.name]'s fealty. Swear it?", "Fealty", list("Swear fealty", "Refuse")) != "Swear fealty")
		to_chat(owner, span_warning("[master] refuses to bend the knee."))
		return FALSE
	sect.liege = owner.mind
	sect.announce("Our Sect Master has sworn the sect's fealty to [owner.real_name], who holds the Mandate of Heaven. We cultivate under heaven's favour.")
	owner.visible_message(span_boldnotice("[master] bows deeply and swears the [sect.name]'s fealty to [owner]!"))
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(get_turf(owner))
	cultivation_temple_sound(owner, 50)
	StartCooldown()
	return TRUE

/datum/jianghu_sect
	/// The ruler this sect has sworn fealty to
	var/datum/mind/liege

// ----- Ennoble (Son of Heaven) -----

/datum/action/cooldown/mandate_power/ennoble
	name = "Ennoble"
	desc = "Grant a noble title to someone in sight (up to three nobles, one more per dynasty age). Nobles bear a silver aura and their title, and cultivate faster. \
		Use it on a noble to strip their title. Titles fall with the throne."
	button_icon_state = "mandate_ennoble"
	cooldown_time = 30 SECONDS

/datum/action/cooldown/mandate_power/ennoble/Activate(atom/target)
	var/datum/component/mandate_of_heaven/mandate = get_mandate()
	var/mob/living/carbon/human/subject = pick_subject("Ennoble (or strip the title of) whom?")
	if(!subject)
		return FALSE
	var/datum/component/imperial_noble/existing = subject.GetComponent(/datum/component/imperial_noble)
	if(existing)
		owner.say("[subject.real_name] is stripped of the title of [existing.title]!", forced = "mandate of heaven")
		qdel(existing)
		StartCooldown()
		return TRUE
	for(var/datum/weakref/noble_ref as anything in mandate.nobles.Copy())
		if(!noble_ref.resolve())
			mandate.nobles -= noble_ref
	if(length(mandate.nobles) >= 3 + mandate.dynasty_tier)
		to_chat(owner, span_warning("You have ennobled as many as heaven allows for now."))
		return FALSE
	var/title = tgui_input_list(owner, "Which title?", name, list("Duke", "Marquis", "Count", "Viscount", "Baron"))
	if(!title || QDELETED(subject))
		return FALSE
	subject.AddComponent(/datum/component/imperial_noble, title)
	mandate.nobles += WEAKREF(subject)
	owner.say("By the Mandate of Heaven, [subject.real_name] is raised to [title]!", forced = "mandate of heaven")
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(get_turf(subject))
	cultivation_guqin_phrase(subject, list(1, 3, 5))
	StartCooldown()
	return TRUE

// ----- Heaven's Punishment (Son of Heaven) -----

/datum/action/cooldown/mandate_power/punishment
	name = "Heaven's Punishment"
	desc = "Name someone in sight and heaven strikes them with lightning three times. Once per reign, and once more if the dynasty reaches its third age."
	button_icon_state = "mandate_punishment"
	cooldown_time = 30 SECONDS

/datum/action/cooldown/mandate_power/punishment/Activate(atom/target)
	var/datum/component/mandate_of_heaven/mandate = get_mandate()
	if(mandate.punishment_charges <= 0)
		to_chat(owner, span_warning("Heaven will not answer that call again so soon."))
		return FALSE
	var/list/options = list()
	for(var/mob/living/subject in view(9, owner))
		if(subject != owner && subject.stat != DEAD)
			options["[subject]"] = subject
	if(!length(options))
		return FALSE
	var/choice = tgui_input_list(owner, "Who has offended heaven?", name, options)
	var/mob/living/condemned = options[choice]
	if(QDELETED(condemned))
		return FALSE
	mandate.punishment_charges--
	owner.say("HEAVEN, STRIKE DOWN [uppertext(condemned.real_name || condemned.name)]!", forced = "mandate of heaven")
	minor_announce("The Son of Heaven has called down heaven's punishment upon [condemned.real_name || condemned.name].", "Omen of Heaven")
	condemned.log_message("was struck by Heaven's Punishment from [key_name(owner)]", LOG_ATTACK)
	for(var/i in 0 to 2)
		addtimer(CALLBACK(src, PROC_REF(strike), condemned), i * 1.2 SECONDS)
	StartCooldown()
	return TRUE

/datum/action/cooldown/mandate_power/punishment/proc/strike(mob/living/condemned)
	if(QDELETED(condemned))
		return
	var/turf/where = get_turf(condemned)
	var/obj/effect/temp_visual/lightning_strike/tribulation/bolt = new(where)
	bolt.zap_damage = 20
	cultivation_omen_flicker(where, 6)

// ===================== Nobles and guards =====================

/datum/component/imperial_noble
	var/title

/datum/component/imperial_noble/Initialize(title)
	if(!ismob(parent))
		return COMPONENT_INCOMPATIBLE
	src.title = title

/datum/component/imperial_noble/RegisterWithParent()
	var/mob/living/noble = parent
	RegisterSignal(noble, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	noble.add_filter("imperial_noble", 3, list("type" = "outline", "color" = "#d8e4f0", "size" = 1, "alpha" = 70))
	to_chat(noble, span_boldnotice("You have been raised to [title] by the Son of Heaven! You cultivate faster while your title stands."))

/datum/component/imperial_noble/UnregisterFromParent()
	var/mob/living/noble = parent
	UnregisterSignal(noble, COMSIG_ATOM_EXAMINE)
	noble.remove_filter("imperial_noble")

/datum/component/imperial_noble/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	var/mob/living/noble = parent
	examine_list += span_notice("<font color='#c8d4e8'>[noble.p_They()] [noble.p_are()] a [title] of the realm.</font>")

/datum/component/imperial_guard
	var/datum/weakref/lord_ref

/datum/component/imperial_guard/Initialize(mob/living/lord)
	if(!ismob(parent))
		return COMPONENT_INCOMPATIBLE
	lord_ref = WEAKREF(lord)

/datum/component/imperial_guard/RegisterWithParent()
	var/mob/living/guard = parent
	RegisterSignal(guard, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	guard.add_filter("imperial_guard", 3, list("type" = "outline", "color" = "#c03030", "size" = 1, "alpha" = 60))
	var/mob/living/lord = lord_ref?.resolve()
	to_chat(guard, span_boldnotice("You serve [lord?.real_name || "the throne"] as Jinyiwei. You will be told whenever your lord is attacked, and where."))

/datum/component/imperial_guard/UnregisterFromParent()
	var/mob/living/guard = parent
	UnregisterSignal(guard, COMSIG_ATOM_EXAMINE)
	guard.remove_filter("imperial_guard")

/datum/component/imperial_guard/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	var/mob/living/guard = parent
	var/mob/living/lord = lord_ref?.resolve()
	examine_list += span_notice("<font color='#d05050'>[guard.p_They()] wear[guard.p_s()] the flying-fish robe of the Jinyiwei[lord ? ", sworn to [lord.real_name]" : ""].</font>")

// ===================== Heaven's Judgement =====================

/// Murdered a ruler: heaven marks you
/datum/status_effect/regicide_curse
	id = "regicide_curse"
	alert_type = null
	duration = 5 MINUTES
	status_type = STATUS_EFFECT_REFRESH

/datum/status_effect/regicide_curse/on_apply()
	RegisterSignal(owner, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	owner.add_filter("regicide_curse", 3, list("type" = "outline", "color" = "#5a0010", "size" = 2))
	cultivation_particles(owner, /particles/cultivation/void, 5 MINUTES)
	to_chat(owner, span_userdanger("Heaven has marked you as a regicide! Everyone can see the stain on you, and no seal will answer you while it lasts."))
	return TRUE

/datum/status_effect/regicide_curse/on_remove()
	UnregisterSignal(owner, COMSIG_ATOM_EXAMINE)
	owner.remove_filter("regicide_curse")

/datum/status_effect/regicide_curse/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_danger("A dark stain of heaven's wrath clings to [owner.p_them()]. A regicide!")

/// Called when the Mandate is withdrawn: mark a ruler's killer and record the reign
/datum/component/mandate_of_heaven/proc/judgement(reason, obj/item/jade_seal/seal)
	var/mob/living/carbon/human/ruler = parent
	seal.lineage = lineage + "[ruler.real_name] ([granted_title ? "appointed" : "seized the seal"], [reason], dynasty age [dynasty_tier])"
	if(reason != "has died")
		return
	var/mob/living/killer = last_attacker_ref?.resolve()
	if(!killer || killer == ruler || world.time - last_attacked_time > 30 SECONDS)
		return
	killer.apply_status_effect(/datum/status_effect/regicide_curse)
	minor_announce("Heaven names [killer.real_name || killer.name] as the one who slew [ruler.real_name]. The regicide is marked.", "Omen of Heaven")
	killer.log_message("was marked as the regicide of [key_name(ruler)]", LOG_ATTACK)

/obj/item/jade_seal
	/// The rulers who held this Mandate, oldest first
	var/list/lineage = list()

#undef DYNASTY_TIER_1
#undef DYNASTY_TIER_2
#undef DYNASTY_TIER_3
