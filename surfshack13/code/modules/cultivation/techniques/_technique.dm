/**
 * Cultivation techniques. Two base types (self cast and pointed) that share the qi helpers below,
 * since DM has no mixins. Techniques cost qi, need a dantian in the current body, and can be blocked by antimagic
 * (so the chaplain can have strong opinions about your Dao).
 */
/datum/action/cooldown/spell/cultivation
	name = "Cultivation Technique"
	desc = "A cultivation technique."
	background_icon_state = "bg_nature"
	overlay_icon_state = "bg_nature_border"
	active_overlay_icon_state = "bg_spell_border_active_yellow"
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "spell_default"
	panel = "Cultivation"
	school = SCHOOL_UNSET
	spell_requirements = SPELL_REQUIRES_NO_ANTIMAGIC|SPELL_REQUIRES_MIND
	antimagic_flags = MAGIC_RESISTANCE|MAGIC_RESISTANCE_HOLY
	spell_max_level = 1
	cooldown_time = 10 SECONDS
	/// Qi spent per use
	var/qi_cost = 0

/datum/action/cooldown/spell/cultivation/can_cast_spell(feedback = TRUE)
	. = ..()
	if(!.)
		return FALSE
	return cultivation_can_cast(src, qi_cost, feedback)

/datum/action/cooldown/spell/cultivation/cast(atom/cast_on)
	. = ..()
	cultivation_spend(src, qi_cost)

/datum/action/cooldown/spell/pointed/cultivation
	name = "Pointed Cultivation Technique"
	desc = "A cultivation technique you aim at something."
	background_icon_state = "bg_nature"
	overlay_icon_state = "bg_nature_border"
	active_overlay_icon_state = "bg_spell_border_active_yellow"
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "spell_default"
	panel = "Cultivation"
	school = SCHOOL_UNSET
	spell_requirements = SPELL_REQUIRES_NO_ANTIMAGIC|SPELL_REQUIRES_MIND
	antimagic_flags = MAGIC_RESISTANCE|MAGIC_RESISTANCE_HOLY
	spell_max_level = 1
	cooldown_time = 10 SECONDS
	active_msg = "You gather your qi..."
	deactive_msg = "You let your qi settle."
	var/qi_cost = 0

/datum/action/cooldown/spell/pointed/cultivation/can_cast_spell(feedback = TRUE)
	. = ..()
	if(!.)
		return FALSE
	return cultivation_can_cast(src, qi_cost, feedback)

/datum/action/cooldown/spell/pointed/cultivation/cast(atom/cast_on)
	. = ..()
	cultivation_spend(src, qi_cost)

/// Every technique uses its own medallion from cultivation_actions.dmi (named after the last part of its typepath),
/// and its description lists qi cost and cooldown so players don't have to guess.
/proc/cultivation_setup_technique(datum/action/cooldown/spell/technique, qi_cost)
	var/type_text = "[technique.type]"
	technique.button_icon = 'surfshack13/icons/cultivation/cultivation_actions.dmi'
	technique.button_icon_state = copytext(type_text, findlasttext(type_text, "/") + 1)
	technique.background_icon_state = "bg_heretic"
	technique.overlay_icon_state = "bg_heretic_border"
	technique.desc = "[technique.desc]<br><i>Qi: [qi_cost] | Cooldown: [DisplayTimeText(technique.cooldown_time)], 10% shorter per realm above Qi Condensation</i>"

/datum/action/cooldown/spell/cultivation/New(Target, original)
	cultivation_setup_technique(src, qi_cost)
	return ..()

/datum/action/cooldown/spell/pointed/cultivation/New(Target, original)
	cultivation_setup_technique(src, qi_cost)
	return ..()

/// Cooldowns shrink as your cultivation deepens: 100% at Qi Condensation, 90% Foundation, 80% Golden Core, 70% Nascent Soul
/proc/cultivation_cooldown_multiplier(mob/living/caster)
	return 1 - 0.1 * max(cultivation_realm_of(caster) - REALM_QI_CONDENSATION, 0)

/datum/action/cooldown/spell/cultivation/StartCooldownSelf(override_cooldown_time)
	if(!isnum(override_cooldown_time))
		override_cooldown_time = cooldown_time * cultivation_cooldown_multiplier(owner)
	return ..(override_cooldown_time)

/datum/action/cooldown/spell/pointed/cultivation/StartCooldownSelf(override_cooldown_time)
	if(!isnum(override_cooldown_time))
		override_cooldown_time = cooldown_time * cultivation_cooldown_multiplier(owner)
	return ..(override_cooldown_time)

/// Finds the law (if any) a technique belongs to, for counterfeit penalties
/proc/cultivation_law_of(datum/antagonist/cultivator/cultivator, technique_type)
	for(var/datum/cultivation_law/law as anything in cultivator.laws)
		if(technique_type in law.techniques)
			return law
	return null

/proc/cultivation_actual_cost(datum/antagonist/cultivator/cultivator, datum/action/technique, base_cost)
	var/datum/cultivation_law/law = cultivation_law_of(cultivator, technique.type)
	if(law?.counterfeit)
		return round(base_cost * 1.5)
	return base_cost

/proc/cultivation_can_cast(datum/action/technique, base_cost, feedback)
	var/mob/living/caster = technique.owner
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(caster)
	if(!cultivator)
		return FALSE
	if(!cultivator.get_dantian())
		if(feedback)
			to_chat(caster, span_warning("Without a dantian your qi just leaks away!"))
		return FALSE
	if(caster.has_status_effect(/datum/status_effect/bagua_sealed))
		if(feedback)
			to_chat(caster, span_warning("The eight trigrams still seal your meridians!"))
		return FALSE
	if(cultivator.breakthrough && !istype(technique, /datum/action/cooldown/spell/cultivation/breakthrough))
		if(feedback)
			to_chat(caster, span_warning("You can't spare a thought from your breakthrough!"))
		return FALSE
	if(cultivator.effective_realm() < cultivator.required_realm_for(technique.type))
		if(feedback)
			to_chat(caster, span_warning("This body's dantian isn't refined enough to channel [technique.name]. Break through again to restore it."))
		return FALSE
	var/cost = cultivation_actual_cost(cultivator, technique, base_cost)
	if(cultivator.qi < cost)
		if(feedback)
			to_chat(caster, span_warning("You need [cost] qi, but only have [round(cultivator.qi)]!"))
		return FALSE
	return TRUE

/proc/cultivation_spend(datum/action/technique, base_cost)
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(technique.owner)
	if(!cultivator)
		return
	cultivator.adjust_qi(-cultivation_actual_cost(cultivator, technique, base_cost))
	cultivator.on_technique_used(technique)
	// Practice makes perfect, a little
	cultivator.gain_insight(1, "practice_[technique.type]", cooldown = 90 SECONDS, silent = TRUE)
	// Counterfeit manuals teach you to shout the name of every move. Like in the novels.
	var/datum/cultivation_law/law = cultivation_law_of(cultivator, technique.type)
	if(law && technique.owner)
		cultivation_element_cue(technique.owner, law.element)
	if(law?.counterfeit && isliving(technique.owner))
		var/mob/living/shouter = technique.owner
		shouter.say("[uppertext(technique.name)]!!", forced = "counterfeit cultivation manual")

/// Realm of any mob for comparisons. Mortals are realm 0.
/proc/cultivation_realm_of(mob/living/target)
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(target)
	if(cultivator)
		return cultivator.effective_realm()
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(target)
	return body_datum ? body_datum.realm_equivalent() : REALM_MORTAL
