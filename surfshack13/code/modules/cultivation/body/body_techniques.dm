// Body Molding Art techniques. They cost stamina and food instead of qi, and ignore antimagic: there's nothing magic about a fist.

/datum/action/cooldown/spell/body_art
	name = "Body Technique"
	desc = "A body cultivation technique."
	button_icon = 'surfshack13/icons/cultivation/cultivation_actions.dmi'
	button_icon_state = "forge_body"
	background_icon_state = "bg_heretic"
	overlay_icon_state = "bg_heretic_border"
	active_overlay_icon_state = "bg_spell_border_active_yellow"
	panel = "Body Molding"
	school = SCHOOL_UNSET
	spell_requirements = NONE
	antimagic_flags = NONE
	spell_max_level = 1
	cooldown_time = 10 SECONDS
	/// Stamina damage it costs to use
	var/stamina_cost = 0

/datum/action/cooldown/spell/body_art/New(Target, original)
	body_setup_technique(src, stamina_cost)
	return ..()

/datum/action/cooldown/spell/body_art/can_cast_spell(feedback = TRUE)
	. = ..()
	if(!.)
		return FALSE
	return body_can_cast(src, stamina_cost, feedback)

/datum/action/cooldown/spell/body_art/cast(atom/cast_on)
	. = ..()
	body_spend(src, stamina_cost)

/datum/action/cooldown/spell/pointed/body_art
	name = "Pointed Body Technique"
	desc = "A body cultivation technique you aim at something."
	button_icon = 'surfshack13/icons/cultivation/cultivation_actions.dmi'
	button_icon_state = "forge_body"
	background_icon_state = "bg_heretic"
	overlay_icon_state = "bg_heretic_border"
	active_overlay_icon_state = "bg_spell_border_active_yellow"
	panel = "Body Molding"
	school = SCHOOL_UNSET
	spell_requirements = NONE
	antimagic_flags = NONE
	spell_max_level = 1
	cooldown_time = 10 SECONDS
	active_msg = "You tense your body..."
	deactive_msg = "You relax."
	var/stamina_cost = 0

/datum/action/cooldown/spell/pointed/body_art/New(Target, original)
	body_setup_technique(src, stamina_cost)
	return ..()

/datum/action/cooldown/spell/pointed/body_art/can_cast_spell(feedback = TRUE)
	. = ..()
	if(!.)
		return FALSE
	return body_can_cast(src, stamina_cost, feedback)

/datum/action/cooldown/spell/pointed/body_art/cast(atom/cast_on)
	. = ..()
	body_spend(src, stamina_cost)

/// Medallion named after the typepath, and the costs in the description
/proc/body_setup_technique(datum/action/cooldown/spell/technique, stamina_cost)
	var/type_text = "[technique.type]"
	technique.button_icon_state = copytext(type_text, findlasttext(type_text, "/") + 1)
	technique.desc = "[technique.desc]<br><i>Stamina: [stamina_cost] | Cooldown: [DisplayTimeText(technique.cooldown_time)]</i>"

/proc/body_can_cast(datum/action/technique, stamina_cost, feedback)
	var/mob/living/caster = technique.owner
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(caster)
	if(!body_datum)
		return FALSE
	if(body_datum.tribulation && !istype(technique, /datum/action/cooldown/spell/body_art/body_breakthrough))
		if(feedback)
			to_chat(caster, span_warning("You can't spare a thought from the Tribulation of Flesh!"))
		return FALSE
	var/required = body_datum.body_techniques[technique.type]
	if(body_datum.stage < required)
		if(feedback)
			to_chat(caster, span_warning("Your body isn't tempered enough for [technique.name]."))
		return FALSE
	if(stamina_cost && caster.getStaminaLoss() + stamina_cost > 90)
		if(feedback)
			to_chat(caster, span_warning("You're too exhausted!"))
		return FALSE
	return TRUE

/proc/body_spend(datum/action/technique, stamina_cost)
	var/mob/living/caster = technique.owner
	if(!caster || !stamina_cost)
		return
	caster.adjustStaminaLoss(stamina_cost)
	caster.adjust_nutrition(-stamina_cost / 2)

// ===================== Forge the Body =====================

/datum/action/cooldown/spell/body_art/forge_body
	name = "Forge the Body"
	desc = "Pour your training into one limb in punishing 10 second cycles until you move: the one you have selected, or the weakest if that one is done. \
		It hurts and makes you hungry. A limb can be forged one level past your stage."
	cooldown_time = 3 SECONDS
	var/forging = FALSE

/datum/action/cooldown/spell/body_art/forge_body/can_cast_spell(feedback = TRUE)
	. = ..()
	if(!.)
		return FALSE
	if(forging)
		if(feedback)
			to_chat(owner, span_warning("You are already forging."))
		return FALSE
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(owner)
	if(body_datum.tempering < 1)
		if(feedback)
			to_chat(owner, span_warning("You have no tempering to forge. Train first: the gym, fighting, mining, punching walls, getting hit."))
		return FALSE
	return TRUE

/datum/action/cooldown/spell/body_art/forge_body/cast(mob/living/cast_on)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(forge), cast_on)

/datum/action/cooldown/spell/body_art/forge_body/proc/pick_part(mob/living/carbon/user, datum/antagonist/body_cultivator/body_datum)
	var/cap = body_datum.part_cap()
	var/obj/item/bodypart/chosen = user.get_bodypart(check_zone(user.zone_selected))
	if(chosen && body_part_level(user, chosen.body_zone) < cap)
		return chosen
	chosen = null
	var/lowest = cap
	for(var/zone in GLOB.body_tempered_zones)
		var/obj/item/bodypart/part = user.get_bodypart(zone)
		if(!part)
			continue
		var/level = body_part_level(user, zone)
		if(level < lowest)
			lowest = level
			chosen = part
	return chosen

/datum/action/cooldown/spell/body_art/forge_body/proc/forge(mob/living/carbon/user)
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(user)
	if(!body_datum || !iscarbon(user))
		return
	forging = TRUE
	user.visible_message(span_notice("[user] drops into a deep horse stance and begins to strike [user.p_their()] own body, over and over."), span_notice("You begin to forge your body. Move to stop."))
	user.add_filter("forge_body", 2, list("type" = "outline", "color" = "#c98a3c", "size" = 1))
	while(forging)
		if(!do_after(user, 10 SECONDS, user, IGNORE_HELD_ITEM))
			break
		if(!forge_cycle(user, body_datum))
			break
	user.remove_filter("forge_body")
	forging = FALSE

/// One cycle. Returns FALSE when there's nothing more to forge.
/datum/action/cooldown/spell/body_art/forge_body/proc/forge_cycle(mob/living/carbon/user, datum/antagonist/body_cultivator/body_datum)
	if(user.nutrition < NUTRITION_LEVEL_HUNGRY)
		to_chat(user, span_warning("You're too hungry to keep forging. Eat something!"))
		return FALSE
	if(body_datum.tempering < 1)
		to_chat(user, span_notice("You've forged all your training into your body."))
		return FALSE
	var/obj/item/bodypart/part = pick_part(user, body_datum)
	if(!part)
		to_chat(user, span_boldnotice("Every limb is forged as far as your stage allows. [body_datum.can_attempt_tribulation() ? "Endure the Tribulation of Flesh to go further!" : "Commit to the Body Molding Art to go further."]"))
		return FALSE
	var/gained = body_datum.forge_part(part, 10)
	user.adjust_nutrition(-8)
	user.apply_damage(2, BRUTE, part, wound_bonus = CANT_WOUND)
	user.Shake(1, 1, 0.4 SECONDS)
	playsound(user, pick('sound/items/weapons/genhit1.ogg', 'sound/items/weapons/genhit2.ogg', 'sound/items/weapons/genhit3.ogg'), 40, TRUE)
	playsound(user, pick('sound/effects/rock/rocktap1.ogg', 'sound/effects/rock/rocktap2.ogg'), 30, TRUE, frequency = 0.7)
	new /obj/effect/temp_visual/cultivation_spark(get_turf(user), "#e0a050", rand(-6, 6), rand(-4, 8))
	var/datum/component/body_tempering/part_tempering = part.GetComponent(/datum/component/body_tempering)
	if(gained)
		new /obj/effect/temp_visual/circle_wave/cultivation/earth(get_turf(user))
		cultivation_guqin_phrase(user, list(1, 3), 0.15 SECONDS, 35)
		to_chat(user, span_boldnotice("Your [part.plaintext_zone] has been forged to level [part_tempering.level]!"))
		if(body_datum.can_attempt_tribulation())
			to_chat(user, span_boldnotice("Every limb is ready. You can endure the Tribulation of Flesh to reach [body_datum.stage_name(body_datum.stage + 1)]!"))
			user.balloon_alert(user, "ready for tribulation!")
	else
		to_chat(user, span_notice("You drive your training into your [part.plaintext_zone]. ([part_tempering.progress]/[BODY_PART_COST(part_tempering.level + 1)])"))
	return TRUE

// ===================== Tribulation of Flesh =====================

/datum/action/cooldown/spell/body_art/body_breakthrough
	name = "Tribulation of Flesh"
	desc = "Once every limb is forged past your stage, break your whole body down and rebuild it one stage higher. Bones crack and reset for a while; stay conscious. \
		Prepare with a full stomach, a Body Tempering Pill, a gym nearby and a tempered Dao heart."
	cooldown_time = 15 SECONDS

/datum/action/cooldown/spell/body_art/body_breakthrough/can_cast_spell(feedback = TRUE)
	. = ..()
	if(!.)
		return FALSE
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(owner)
	if(body_datum.tribulation)
		return FALSE
	if(body_datum.stage >= body_datum.stage_cap())
		if(feedback)
			to_chat(owner, span_notice(body_datum.committed ? "Your body is the Primordial Chaos Body. There is nothing left to forge." : "Mortal training ends at Copper Skin. Commit to the Body Molding Art to go further."))
		return FALSE
	if(!body_datum.can_attempt_tribulation())
		if(feedback)
			to_chat(owner, span_warning("Every limb must be forged to level [body_datum.stage + 1] first. (weakest: level [body_datum.weakest_part_level()])"))
		return FALSE
	return TRUE

/datum/action/cooldown/spell/body_art/body_breakthrough/cast(mob/living/cast_on)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(prepare), cast_on)

/datum/action/cooldown/spell/body_art/body_breakthrough/proc/prepare(mob/living/user)
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(user)
	var/datum/body_tribulation/attempt = new(body_datum)
	var/list/lines = attempt.assess()
	to_chat(user, boxed_message(lines.Join("<br>")))
	if(tgui_alert(user, "Readiness: [attempt.readiness]. Begin the Tribulation of Flesh?", "Tribulation of Flesh", list("Begin", "Not yet")) != "Begin" || QDELETED(user) || body_datum.tribulation)
		qdel(attempt)
		return
	attempt.start()

/datum/body_tribulation
	var/datum/antagonist/body_cultivator/body_datum
	var/mob/living/carbon/body
	var/readiness = 50
	var/duration = 15
	var/elapsed = 0
	var/next_crack = 2
	var/list/reasons = list()

/datum/body_tribulation/New(datum/antagonist/body_cultivator/body_datum)
	src.body_datum = body_datum
	body = body_datum.owner.current
	duration = 15 + 3 * body_datum.stage

/datum/body_tribulation/Destroy(force)
	STOP_PROCESSING(SSprocessing, src)
	if(body)
		body.remove_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), REF(src))
		body.remove_filter("body_tribulation")
	if(body_datum?.tribulation == src)
		body_datum.tribulation = null
	body_datum = null
	body = null
	return ..()

/datum/body_tribulation/proc/assess()
	reasons = list(span_boldnotice("Tribulation of Flesh: [body_datum.stage_name(body_datum.stage + 1)]"))
	readiness = 50
	if(body.has_status_effect(/datum/status_effect/cultivation_pill_buff/body_tempering))
		readiness += 20
		reasons += span_nicegreen("+20: a Body Tempering Pill hardens you.")
	if(body.has_status_effect(/datum/status_effect/dao_heart_tempered))
		readiness += 15
		reasons += span_nicegreen("+15: your Dao heart is tempered.")
	if((locate(/obj/structure/weightmachine) in range(3, body)) || (locate(/obj/structure/punching_bag) in range(3, body)))
		readiness += 10
		reasons += span_nicegreen("+10: the gym around you.")
	if(body.nutrition >= NUTRITION_LEVEL_WELL_FED)
		readiness += 10
		reasons += span_nicegreen("+10: a full stomach.")
	else
		reasons += span_warning("+0: you're not well fed.")
	if(body.health < body.maxHealth * 0.7)
		readiness -= 20
		reasons += span_warning("-20: you're already hurt.")
	reasons += span_boldnotice("Total: [readiness]. 70 or more always succeeds if you stay conscious for [duration] seconds.")
	return reasons

/datum/body_tribulation/proc/start()
	body_datum.tribulation = src
	body.add_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED), REF(src))
	body.add_filter("body_tribulation", 2, list("type" = "outline", "color" = "#c98a3c", "size" = 2))
	body.visible_message(span_boldwarning("[body] sinks to one knee. A sickening chorus of cracks rings out as [body.p_their()] bones begin to break and reset!"), span_boldnotice("Your body breaks itself down. Endure for [duration] seconds!"))
	playsound(body, 'sound/effects/wounds/crack1.ogg', 60, TRUE)
	START_PROCESSING(SSprocessing, src)

/datum/body_tribulation/process(seconds_per_tick)
	if(QDELETED(body) || body.stat != CONSCIOUS || body.mind != body_datum?.owner)
		fail(TRUE)
		return PROCESS_KILL
	elapsed += seconds_per_tick
	if(elapsed >= next_crack)
		next_crack += 3
		crack()
	if(elapsed >= duration)
		var/chance = readiness >= 70 ? 100 : clamp(readiness, 5, 95)
		if(prob(chance))
			succeed()
		else
			fail()
		return PROCESS_KILL

/// Bones snap and reform
/datum/body_tribulation/proc/crack()
	var/zone = pick(GLOB.body_tempered_zones)
	if(!body.get_bodypart(zone))
		zone = BODY_ZONE_CHEST
	body.apply_damage(3 + body_datum.stage, BRUTE, zone, wound_bonus = CANT_WOUND)
	body.adjustStaminaLoss(6)
	body.Shake(2, 2, 0.5 SECONDS)
	playsound(body, pick('sound/effects/wounds/crack1.ogg', 'sound/effects/wounds/crack2.ogg'), 50, TRUE)
	new /obj/effect/temp_visual/cultivation_spark(get_turf(body), "#e0a050", rand(-8, 8), rand(-6, 10))
	to_chat(body, span_warning("Your [parse_zone(zone)] cracks and knits back together!"))

/datum/body_tribulation/proc/succeed()
	var/mob/living/carbon/user = body
	var/datum/antagonist/body_cultivator/winner = body_datum
	qdel(src)
	winner.advance_stage()
	cultivation_breakthrough_sequence(user, winner.stage_name())
	new /obj/effect/temp_visual/circle_wave/cultivation/earth(get_turf(user))
	user.visible_message(span_boldnotice("[user] rises, steam pouring off a body remade. [user.p_They()] [user.p_have()] reached [winner.stage_name()]!"), span_boldnotice("Your body is remade. You have reached [winner.stage_name()]!"))
	to_chat(user, span_notice(winner.stage_benefits[winner.stage]))

/datum/body_tribulation/proc/fail(interrupted = FALSE)
	var/mob/living/carbon/user = body
	var/datum/antagonist/body_cultivator/loser = body_datum
	qdel(src)
	if(!loser)
		return
	loser.tribulations_failed++
	if(interrupted || QDELETED(user))
		loser.tempering = round(loser.tempering * 0.75)
		if(!QDELETED(user))
			to_chat(user, span_warning("The tribulation breaks off! Your bones set where they are; some of your training is lost."))
		return
	loser.tempering = round(loser.tempering / 2)
	var/obj/item/bodypart/part = user.get_bodypart(pick(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
	part?.force_wound_upwards(/datum/wound/blunt/bone/moderate, wound_source = "a failed Tribulation of Flesh")
	user.visible_message(span_danger("Something in [user] sets wrong with a horrible crunch!"), span_userdanger("Your bones set wrong! The tribulation fails. Rest, heal, and try again."))

/datum/body_tribulation/proc/cancel(message)
	if(message && body)
		to_chat(body, span_warning(message))
	fail(TRUE)

// ===================== Iron Shirt =====================

/datum/action/cooldown/spell/body_art/iron_shirt
	name = "Iron Shirt"
	desc = "Clench every muscle into a shell. For a while brute damage is halved and you can't be shoved."
	cooldown_time = 45 SECONDS
	stamina_cost = 20

/datum/action/cooldown/spell/body_art/iron_shirt/cast(mob/living/cast_on)
	. = ..()
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(cast_on)
	cast_on.apply_status_effect(/datum/status_effect/body_iron_shirt, 10 SECONDS + body_datum.stage * 1 SECONDS)
	cast_on.visible_message(span_warning("[cast_on]'s muscles lock with a sound like a bell!"), span_notice("Your body becomes an iron shirt."))
	playsound(cast_on, 'sound/effects/gong.ogg', 40, TRUE, frequency = 1.6)
	new /obj/effect/temp_visual/circle_wave/cultivation/earth(get_turf(cast_on))

/datum/status_effect/body_iron_shirt
	id = "body_iron_shirt"
	alert_type = null
	status_type = STATUS_EFFECT_REFRESH

/datum/status_effect/body_iron_shirt/on_creation(mob/living/new_owner, duration = 10 SECONDS)
	src.duration = duration
	return ..()

/datum/status_effect/body_iron_shirt/on_apply()
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, PROC_REF(harden))
	ADD_TRAIT(owner, TRAIT_PUSHIMMUNE, id)
	owner.add_filter("iron_shirt", 2, list("type" = "outline", "color" = "#8a8f99", "size" = 1))
	return TRUE

/datum/status_effect/body_iron_shirt/on_remove()
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS)
	REMOVE_TRAIT(owner, TRAIT_PUSHIMMUNE, id)
	owner.remove_filter("iron_shirt")

/datum/status_effect/body_iron_shirt/proc/harden(mob/living/source, list/damage_mods, damage, damagetype, ...)
	SIGNAL_HANDLER
	if(damagetype == BRUTE)
		damage_mods += 0.5

// ===================== Mountain Leap =====================

/datum/action/cooldown/spell/pointed/body_art/mountain_leap
	name = "Mountain Leap"
	desc = "Leap like a falling boulder. From Crimson Blood, your landing knocks down everyone beside you."
	cast_range = 5
	cooldown_time = 10 SECONDS
	stamina_cost = 15
	aim_assist = FALSE

/datum/action/cooldown/spell/pointed/body_art/mountain_leap/is_valid_target(atom/cast_on)
	return TRUE

/datum/action/cooldown/spell/pointed/body_art/mountain_leap/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	var/mob/living/user = owner
	if(user.buckled || user.pulledby || HAS_TRAIT(user, TRAIT_RESTRAINED) || user.body_position == LYING_DOWN)
		user.balloon_alert(user, "can't leap now!")
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/pointed/body_art/mountain_leap/cast(atom/cast_on)
	. = ..()
	var/mob/living/user = owner
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(user)
	var/old_pass = user.pass_flags
	user.pass_flags |= PASSTABLE
	user.visible_message(span_warning("[user] crouches and launches [user.p_them()]self into the air!"))
	playsound(user, 'sound/effects/rock/rock_break.ogg', 40, TRUE, frequency = 1.4)
	new /obj/effect/temp_visual/small_smoke/halfsecond(get_turf(user))
	user.throw_at(get_turf(cast_on), 3 + round(body_datum.stage / 2), 1.5, user, spin = FALSE, gentle = TRUE, callback = CALLBACK(src, PROC_REF(land), user, old_pass))

/datum/action/cooldown/spell/pointed/body_art/mountain_leap/proc/land(mob/living/user, old_pass)
	user.pass_flags = old_pass
	var/turf/landing = get_turf(user)
	playsound(landing, 'sound/effects/meteorimpact.ogg', 40, TRUE)
	user.Shake(1, 1, 0.3 SECONDS)
	new /obj/effect/temp_visual/circle_wave/cultivation/earth(landing)
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(user)
	if(body_datum?.stage < 5)
		return
	for(var/mob/living/victim in orange(1, landing))
		if(victim.stat == DEAD || victim.body_position == LYING_DOWN)
			continue
		victim.Knockdown(1 SECONDS)
		to_chat(victim, span_userdanger("The floor jumps under you as [user] lands!"))

// ===================== Shattering Fist =====================

/datum/action/cooldown/spell/pointed/body_art/shattering_fist
	name = "Shattering Fist"
	desc = "Put your whole forged body behind one punch. People are hurled away, machines and structures crumple, and a Golden Body can punch through walls."
	cast_range = 1
	cooldown_time = 15 SECONDS
	stamina_cost = 25

/datum/action/cooldown/spell/pointed/body_art/shattering_fist/is_valid_target(atom/cast_on)
	return ..() && (isliving(cast_on) || isclosedturf(cast_on) || isobj(cast_on))

/datum/action/cooldown/spell/pointed/body_art/shattering_fist/cast(atom/cast_on)
	. = ..()
	var/mob/living/user = owner
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(user)
	var/arm_level = body_part_level(user, user.active_hand_index % 2 ? BODY_ZONE_L_ARM : BODY_ZONE_R_ARM)
	user.do_attack_animation(cast_on, ATTACK_EFFECT_SMASH)
	playsound(cast_on, 'sound/effects/meteorimpact.ogg', 50, TRUE)
	new /obj/effect/temp_visual/kinetic_blast(get_turf(cast_on))
	cultivation_distortion_wave(user, 2, 0.4 SECONDS, 160)
	if(isliving(cast_on))
		var/mob/living/victim = cast_on
		victim.visible_message(span_danger("[user]'s fist lands on [victim] like a falling mountain!"), span_userdanger("[user] hits you like a falling mountain!"))
		victim.apply_damage(10 + 2 * arm_level, BRUTE, wound_bonus = 10)
		victim.adjust_staggered_up_to(STAGGERED_SLOWDOWN_LENGTH, 10 SECONDS)
		if(!HAS_TRAIT(victim, TRAIT_PUSHIMMUNE))
			victim.throw_at(get_edge_target_turf(victim, get_dir(user, victim)), 2 + round(body_datum.stage / 3), 2, user)
		log_combat(user, victim, "used Shattering Fist on")
		return
	if(iswallturf(cast_on))
		var/turf/closed/wall/wall = cast_on
		if(body_datum.stage >= 7 && !istype(wall, /turf/closed/wall/r_wall))
			wall.visible_message(span_danger("[user] punches straight through [wall]!"))
			wall.dismantle_wall(devastated = TRUE)
			return
		wall.visible_message(span_warning("[user] punches [wall] hard enough to crack the paint."))
		user.apply_damage(3, BRUTE, user.get_active_hand(), wound_bonus = CANT_WOUND)
		return
	if(isobj(cast_on))
		var/obj/thing = cast_on
		if(!(thing.resistance_flags & INDESTRUCTIBLE))
			thing.take_damage(30 + 5 * body_datum.stage, BRUTE, MELEE)

// ===================== Bone Setting =====================

/datum/action/cooldown/spell/body_art/bone_setting
	name = "Bone Setting"
	desc = "Wrench your own dislocations and fractures back into place. Moderate breaks at first, severe ones from Vajra Viscera."
	cooldown_time = 60 SECONDS
	stamina_cost = 15

/datum/action/cooldown/spell/body_art/bone_setting/cast(mob/living/carbon/cast_on)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(set_bones), cast_on)

/datum/action/cooldown/spell/body_art/bone_setting/proc/set_bones(mob/living/carbon/user)
	if(!iscarbon(user))
		return
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(user)
	var/max_severity = body_datum.stage >= 6 ? WOUND_SEVERITY_SEVERE : WOUND_SEVERITY_MODERATE
	var/list/broken = list()
	for(var/datum/wound/blunt/bone/wound in user.all_wounds)
		if(wound.severity <= max_severity)
			broken += wound
	if(!length(broken))
		to_chat(user, span_notice("You have no bones you can set yourself."))
		return
	user.visible_message(span_warning("[user] grabs [user.p_their()] own limb and wrenches it straight!"))
	if(!do_after(user, 4 SECONDS, user))
		return
	for(var/datum/wound/blunt/bone/wound as anything in broken)
		wound.remove_wound()
	playsound(user, 'sound/effects/wounds/crack2.ogg', 50, TRUE)
	user.heal_overall_damage(brute = 10)
	to_chat(user, span_nicegreen("With a crunch, your bones snap back where they belong."))

// ===================== Body Molding: Remold Limb =====================

/datum/action/cooldown/spell/body_art/remold_limb
	name = "Remold Limb"
	desc = "The Body Molding Art itself. Grow a lost limb back from your own flesh, or remold a limb that isn't yours (a transplant or a fresh regrowth) \
		up to half your stage, closing its wounds."
	cooldown_time = 3 MINUTES
	stamina_cost = 40

/datum/action/cooldown/spell/body_art/remold_limb/cast(mob/living/carbon/cast_on)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(remold), cast_on)

/datum/action/cooldown/spell/body_art/remold_limb/proc/remold(mob/living/carbon/user)
	if(!iscarbon(user))
		return
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(user)
	var/molded_level = round(body_datum.stage / 2)
	var/list/missing = user.get_missing_limbs()
	var/zone
	if(length(missing))
		var/list/options = list()
		for(var/missing_zone in missing)
			options[parse_zone(missing_zone)] = missing_zone
		var/choice = tgui_input_list(user, "Regrow which limb?", "Remold Limb", options)
		if(!choice)
			reset_spell_cooldown()
			return
		zone = options[choice]
	else
		zone = check_zone(user.zone_selected)
	user.visible_message(span_warning("[user]'s flesh begins to crawl and swell, kneading itself like clay!"), span_notice("You begin to mold your [parse_zone(zone)]..."))
	var/obj/effect/abstract/particle_holder/steam = cultivation_particles(user, /particles/cultivation/steam)
	var/finished = do_after(user, 15 SECONDS, user)
	qdel(steam)
	if(!finished)
		return
	if(!user.get_bodypart(zone))
		user.regenerate_limb(zone)
		playsound(user, 'sound/effects/magic/demon_consume.ogg', 40, TRUE, frequency = 1.3)
		user.visible_message(span_warning("A new [parse_zone(zone)] bulges out of [user]'s body and sets with a wet crack!"))
	var/obj/item/bodypart/part = user.get_bodypart(zone)
	if(!part)
		return
	var/datum/component/body_tempering/part_tempering = part.GetComponent(/datum/component/body_tempering) || part.AddComponent(/datum/component/body_tempering)
	if(part_tempering.level < molded_level)
		part_tempering.apply_level(molded_level)
		body_datum.on_limbs_changed()
	for(var/datum/wound/wound as anything in part.wounds)
		wound.remove_wound()
	part.heal_damage(20, 20)
	new /obj/effect/temp_visual/circle_wave/cultivation/earth(get_turf(user))
	to_chat(user, span_boldnotice("Your [part.plaintext_zone] is molded to level [part_tempering.level]."))

// ===================== Blood Boil =====================

/datum/action/cooldown/spell/body_art/blood_boil
	name = "Blood Boil"
	desc = "Set your blood boiling. For fifteen seconds you shrug off exhaustion and slowdowns, then you crash hard."
	cooldown_time = 90 SECONDS

/datum/action/cooldown/spell/body_art/blood_boil/cast(mob/living/cast_on)
	. = ..()
	cast_on.apply_status_effect(/datum/status_effect/body_blood_boil)

/datum/status_effect/body_blood_boil
	id = "body_blood_boil"
	alert_type = null
	duration = 15 SECONDS
	tick_interval = 1 SECONDS
	status_type = STATUS_EFFECT_REFRESH
	var/obj/effect/abstract/particle_holder/steam

/datum/status_effect/body_blood_boil/on_apply()
	ADD_TRAIT(owner, TRAIT_IGNORESLOWDOWN, id)
	owner.add_filter("blood_boil", 2, list("type" = "outline", "color" = "#d0201a", "size" = 1))
	steam = cultivation_particles(owner, /particles/cultivation/blood)
	owner.visible_message(span_danger("[owner]'s veins bulge and glow red as steam rises off [owner.p_them()]!"), span_notice("Your blood boils!"))
	playsound(owner, 'sound/effects/fire_puff.ogg', 50, TRUE, frequency = 0.7)
	return TRUE

/datum/status_effect/body_blood_boil/tick(seconds_between_ticks)
	owner.adjustStaminaLoss(-10)

/datum/status_effect/body_blood_boil/on_remove()
	REMOVE_TRAIT(owner, TRAIT_IGNORESLOWDOWN, id)
	owner.remove_filter("blood_boil")
	QDEL_NULL(steam)
	owner.adjustStaminaLoss(50)
	to_chat(owner, span_warning("Your blood cools, and exhaustion crashes over you."))

// ===================== Vajra Golden Body =====================

/datum/action/cooldown/spell/body_art/vajra_body
	name = "Vajra Golden Body"
	desc = "Turn your skin to temple gold for eight seconds: three quarters less brute and burn damage, and nothing can stun or shove you."
	cooldown_time = 2 MINUTES
	stamina_cost = 30

/datum/action/cooldown/spell/body_art/vajra_body/cast(mob/living/cast_on)
	. = ..()
	cast_on.apply_status_effect(/datum/status_effect/body_vajra)

/datum/status_effect/body_vajra
	id = "body_vajra"
	alert_type = null
	duration = 8 SECONDS
	status_type = STATUS_EFFECT_REFRESH

/datum/status_effect/body_vajra/on_apply()
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, PROC_REF(golden))
	owner.add_traits(list(TRAIT_STUNIMMUNE, TRAIT_PUSHIMMUNE), id)
	owner.add_filter("vajra", 2, list("type" = "outline", "color" = "#ffd55a", "size" = 2))
	owner.add_atom_colour("#ffe08a", TEMPORARY_COLOUR_PRIORITY)
	owner.visible_message(span_boldwarning("[owner]'s skin turns to gleaming gold!"), span_notice("Your body becomes the Vajra Golden Body!"))
	cultivation_great_bell(owner, 50)
	return TRUE

/datum/status_effect/body_vajra/on_remove()
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS)
	owner.remove_traits(list(TRAIT_STUNIMMUNE, TRAIT_PUSHIMMUNE), id)
	owner.remove_filter("vajra")
	owner.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#ffe08a")

/datum/status_effect/body_vajra/proc/golden(mob/living/source, list/damage_mods, damage, damagetype, ...)
	SIGNAL_HANDLER
	if(damagetype == BRUTE || damagetype == BURN)
		damage_mods += 0.25

// ===================== Primordial Roar =====================

/datum/action/cooldown/spell/body_art/primordial_roar
	name = "Primordial Roar"
	desc = "Roar with the voice of the first mountain. Everyone weaker than you within five tiles is knocked flat and deafened."
	cooldown_time = 60 SECONDS
	stamina_cost = 30

/datum/action/cooldown/spell/body_art/primordial_roar/cast(mob/living/cast_on)
	. = ..()
	var/my_realm = cultivation_realm_of(cast_on)
	cast_on.visible_message(span_boldwarning("[cast_on] ROARS, and the whole room shakes!"))
	playsound(cast_on, 'sound/effects/magic/demon_dies.ogg', 80, TRUE, frequency = 0.5)
	playsound(cast_on, 'sound/effects/gong.ogg', 60, TRUE, frequency = 0.35)
	new /obj/effect/temp_visual/circle_wave/cultivation/earth(get_turf(cast_on))
	cultivation_distortion_wave(cast_on, 5, 0.8 SECONDS, 220)
	for(var/mob/living/victim in range(5, cast_on))
		if(victim == cast_on || victim.stat == DEAD)
			continue
		shake_camera(victim, 3, 2)
		if(cultivation_realm_of(victim) >= my_realm)
			to_chat(victim, span_warning("You brace against [cast_on]'s roar."))
			continue
		victim.Knockdown(2 SECONDS)
		victim.adjust_staggered_up_to(STAGGERED_SLOWDOWN_LENGTH, 10 SECONDS)
		if(iscarbon(victim))
			var/mob/living/carbon/carbon_victim = victim
			carbon_victim.soundbang_act(1, 10 SECONDS, 5)

// ===================== Accept Body Disciple =====================

/datum/action/cooldown/spell/pointed/body_art/body_disciple
	name = "Accept Body Disciple"
	desc = "Take a willing person beside you as a disciple of the Body Molding Art. They commit to the path of the flesh and can never cultivate qi."
	cast_range = 1
	cooldown_time = 30 SECONDS

/datum/action/cooldown/spell/pointed/body_art/body_disciple/is_valid_target(atom/cast_on)
	return ..() && ishuman(cast_on)

/datum/action/cooldown/spell/pointed/body_art/body_disciple/cast(mob/living/carbon/human/cast_on)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(teach), owner, cast_on)

/datum/action/cooldown/spell/pointed/body_art/body_disciple/proc/teach(mob/living/master, mob/living/carbon/human/disciple)
	if(!disciple.mind || !disciple.client)
		to_chat(master, span_warning("[disciple] has no mind to receive your teachings."))
		return
	if(IS_CULTIVATOR(disciple))
		to_chat(master, span_warning("[disciple]'s meridians are full of qi. The path of the flesh is closed to [disciple.p_them()]."))
		return
	var/datum/antagonist/body_cultivator/existing = IS_BODY_CULTIVATOR(disciple)
	if(existing?.committed)
		to_chat(master, span_warning("[disciple] already walks the path of the flesh."))
		return
	if(tgui_alert(disciple, "[master] offers to teach you the Body Molding Art. You will never be able to cultivate qi. Do you accept?", "Body Molding Art", list("Accept", "Refuse")) != "Accept")
		to_chat(master, span_warning("[disciple] refuses."))
		return
	master.visible_message(span_notice("[master] slaps [disciple] hard across the back, again and again, reciting the stances."))
	if(!do_after(master, 10 SECONDS, disciple))
		return
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(disciple) || disciple.mind.add_antag_datum(/datum/antagonist/body_cultivator)
	body_datum.commit()
	var/datum/jianghu_sect/sect = jianghu_sect_of(master.mind)
	if(sect && jianghu_sect_of(disciple.mind) != sect)
		sect.add_member(disciple.mind)

// ===================== Panel =====================

/datum/action/body_panel
	name = "Body Molding Art"
	desc = "See your body's stage, each limb's tempering, and what's next."
	button_icon = 'surfshack13/icons/cultivation/cultivation_actions.dmi'
	button_icon_state = "body_panel"
	background_icon_state = "bg_heretic"
	overlay_icon_state = "bg_heretic_border"
	check_flags = NONE

/datum/action/body_panel/Trigger(trigger_flags)
	. = ..()
	if(!.)
		return
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(owner)
	body_datum?.open_panel(owner)

/datum/antagonist/body_cultivator/proc/open_panel(mob/user)
	var/datum/browser/popup = new(user, "body_panel", "Body Molding Art", 520, 680)
	popup.set_content(panel_html())
	popup.open()

/datum/antagonist/body_cultivator/Topic(href, list/href_list)
	if(href_list["body_refresh"] && usr == owner.current)
		open_panel(usr)
		return
	return ..()

/datum/antagonist/body_cultivator/proc/panel_html()
	var/mob/living/carbon/body = owner.current
	var/list/html = list()
	html += {"<style>
		body { background:#1a1410; color:#efe4d0; font-family:Verdana, sans-serif; font-size:12px; }
		h1 { color:#e0a050; font-size:20px; margin:4px 0; }
		h2 { color:#c98a3c; font-size:14px; border-bottom:1px solid #4a3420; margin:14px 0 6px; padding-bottom:2px; }
		.dim { color:#a89a88; } .good { color:#7fe08a; } .warn { color:#ff9a3c; }
		.bar { background:#2e241c; border:1px solid #4a3a2c; height:12px; border-radius:6px; overflow:hidden; }
		.fill { height:100%; border-radius:6px; background:linear-gradient(90deg,#8a5a2a,#e0a050); }
		.card { background:#241c16; border:1px solid #3e3024; border-radius:6px; padding:6px 8px; margin:4px 0; }
		table { width:100%; border-collapse:collapse; } td { padding:2px 4px; }
		a.btn { color:#1a1410; background:#c98a3c; padding:2px 8px; border-radius:4px; text-decoration:none; font-weight:bold; }
	</style>"}
	html += "<div style='float:right'><a class='btn' href='byond://?src=[REF(src)];body_refresh=1'>Refresh</a></div>"
	html += "<h1>[stage_name()]</h1>"
	html += "<div class='dim'>[committed ? "Disciple of the Body Molding Art (stages 1 to [BODY_STAGE_MAX])" : "Mortal training (Copper Skin is as far as you can go without the Body Molding Art)"]</div>"
	html += "<div style='margin-top:6px'>Pending tempering: [round(tempering)] / [BODY_TEMPERING_CAP]</div>"
	html += "<div class='bar'><div class='fill' style='width:[round(100 * tempering / BODY_TEMPERING_CAP)]%'></div></div>"
	html += "<h2>The way forward</h2><div class='card'>"
	if(stage >= stage_cap())
		html += committed ? "<span class='good'>You have the Primordial Chaos Body.</span>" : "Mortal training ends at Copper Skin. Read the <b>Body Molding Art</b> or be accepted as a disciple to go further (this closes the way of qi)."
	else if(can_attempt_tribulation())
		html += "<span class='good'>Every limb is ready.</span> Endure the <b>Tribulation of Flesh</b> to reach [stage_name(stage + 1)]."
	else
		html += "Forge every limb to level [stage + 1]. Earn tempering from the gym, fighting, punching walls or bags, mining and taking hits; then <b>Forge the Body</b> with the limb you want selected."
	html += "</div><h2>Limbs</h2><div class='card'><table>"
	for(var/zone in GLOB.body_tempered_zones)
		var/obj/item/bodypart/part = body?.get_bodypart(zone)
		if(!part)
			html += "<tr><td>[parse_zone(zone)]</td><td class='warn'>missing</td></tr>"
			continue
		var/datum/component/body_tempering/part_tempering = part.GetComponent(/datum/component/body_tempering)
		var/level = part_tempering ? part_tempering.level : 0
		var/progress = part_tempering ? part_tempering.progress : 0
		html += "<tr><td>[part.plaintext_zone]</td><td>level <b>[level]</b> / [part_cap()]</td><td class='dim'>[level < part_cap() ? "[progress]/[BODY_PART_COST(level + 1)]" : "done for now"]</td></tr>"
	html += "</table><div class='dim'>Each level: -3% brute and +3 wound resistance on that limb, +1 unarmed damage on arms and legs. Head 4: night vision, head 6: flash proof. Both legs 4: vault tables.</div></div>"
	html += "<h2>Stages</h2>"
	for(var/i in 1 to BODY_STAGE_MAX)
		var/reached = stage >= i
		var/locked = !committed && i > BODY_STAGE_MORTAL_CAP
		html += "<div class='card' style='[reached ? "border-color:#c98a3c" : "opacity:0.7"]'><b>[i]. [stage_names[i]]</b>[reached ? " <span class='good'>(reached)</span>" : ""][locked ? " <span class='dim'>(needs the Body Molding Art)</span>" : ""]<br><span class='dim'>[stage_benefits[i]]</span></div>"
	return html.Join()
