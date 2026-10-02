/**
 * # Cultivator
 *
 * Crew who awakened to qi by reading a cultivation manual. Not an antagonist (FLAG_FAKE_ANTAG),
 * the datum is just a convenient mind-bound container: knowledge (laws, realm, insight) lives here and
 * follows the mind, while physical power lives in the dantian organ in the chest.
 *
 * Loop: do department work -> earn pending insight -> meditate to consolidate it -> break through to the next realm.
 */
/datum/antagonist/cultivator
	name = "\improper Cultivator"
	roundend_category = "cultivators"
	antagpanel_category = "Cultivator"
	show_in_antagpanel = TRUE
	prevent_roundtype_conversion = FALSE
	antag_flags = FLAG_FAKE_ANTAG
	count_against_dynamic_roll_chance = FALSE
	ui_name = null
	suicide_cry = "MY DAO IS UNBROKEN!!"
	/// Current realm, see REALM_* defines
	var/realm = REALM_QI_CONDENSATION
	/// Consolidated insight towards the next realm
	var/progress = 0
	/// Insight earned but not yet consolidated through meditation
	var/pending_insight = 0
	/// Current qi
	var/qi = 25
	/// Instability, 0-100. Forcing your cultivation raises it, meditation lowers it.
	var/instability = 0
	/// Laws (/datum/cultivation_law) we know
	var/list/datum/cultivation_law/laws = list()
	/// Techniques we've been granted, so we don't double grant
	var/list/datum/action/techniques = list()
	/// source -> world.time we can next earn insight from it
	var/list/insight_cooldowns = list()
	/// Technique types we've used at least once (first use teaches you something)
	var/list/used_techniques = list()
	/// Multiplier sources for insight gain (source -> multiplier bonus, additive)
	var/list/insight_bonuses = list()
	/// Currently running breakthrough, if any
	var/datum/cultivation_breakthrough/breakthrough
	/// Number of breakthroughs survived, for the roundend report
	var/breakthroughs_survived = 0
	/// Number of breakthroughs failed
	var/breakthroughs_failed = 0
	/// Pill toxicity, decays slowly. Above 30 every pill adds instability.
	var/pill_toxicity = 0
	/// Seconds since the last passive insight tick
	var/passive_timer = 0
	/// Area types we've already found enlightening
	var/list/visited_areas = list()
	/// HUD element showing qi / insight
	var/atom/movable/screen/cultivation_display/qi_display
	/// Next world.time an epiphany can trigger
	COOLDOWN_DECLARE(epiphany_cooldown)
	/// Spam limiter for the instability side effects
	COOLDOWN_DECLARE(instability_cooldown)
	/// Spam limiter for "your mind is full"
	COOLDOWN_DECLARE(full_warning_cooldown)
	/// Nascent Soul revival can only happen this often
	COOLDOWN_DECLARE(nascent_revival_cooldown)
	/// Shattered the void and left for the Immortal Realm
	var/ascended = FALSE
	/// Instability can only birth a heart demon this often
	COOLDOWN_DECLARE(heart_demon_cooldown)
	/// Already told them their core is keeping them alive this crit
	var/core_sustain_announced = FALSE

	/// Progress needed to reach realm (index = target realm)
	var/static/list/realm_thresholds = list(0, 60, 150, 300)
	/// Max qi per realm (index = realm)
	var/static/list/realm_max_qi = list(60, 130, 230, 360)
	/// Display names per realm (index = realm)
	var/static/list/realm_names = list("Qi Condensation", "Foundation Establishment", "Golden Core", "Nascent Soul")
	/// Techniques everyone gets, by required realm
	var/static/list/universal_techniques = list(
		/datum/action/cultivation_panel = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/cultivation/meditate = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/cultivation/breakthrough = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/cultivation/spiritual_sense = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/pointed/cultivation/empty_palm = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/pointed/cultivation/qinggong = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/cultivation/write_talisman = REALM_QI_CONDENSATION,
		/datum/action/cooldown/jianghu_duel = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/cultivation/found_sect = REALM_FOUNDATION,
		/datum/action/cooldown/spell/cultivation/inscribe_formation = REALM_FOUNDATION,
		/datum/action/cooldown/spell/pointed/cultivation/void_step = REALM_GOLDEN_CORE,
		/datum/action/cooldown/spell/pointed/cultivation/teach = REALM_FOUNDATION,
		/datum/action/cooldown/spell/pointed/cultivation/beast_contract = REALM_FOUNDATION,
		/datum/action/cooldown/spell/cultivation/summon_beast = REALM_FOUNDATION,
		/datum/action/cooldown/spell/pointed/cultivation/acupoint = REALM_FOUNDATION,
		/datum/action/cooldown/spell/cultivation/realm_pressure = REALM_FOUNDATION,
		/datum/action/cooldown/spell/cultivation/ascension = REALM_NASCENT_SOUL,
	)

/datum/antagonist/cultivator/on_gain()
	. = ..()
	// Qi and the flesh don't mix: mortal Copper Skin training is set aside (the limbs keep their mortal tempering)
	var/datum/antagonist/body_cultivator/body_datum = owner.has_antag_datum(/datum/antagonist/body_cultivator)
	if(body_datum)
		to_chat(owner.current, span_notice("You set aside the training of the flesh for the way of qi."))
		owner.remove_antag_datum(/datum/antagonist/body_cultivator)
	var/mob/living/carbon/body = owner.current
	if(iscarbon(body) && !body.get_organ_slot(ORGAN_SLOT_DANTIAN))
		var/obj/item/organ/dantian/dantian = new()
		dantian.Insert(body, special = TRUE)
	refresh_techniques()
	update_hud()

/datum/antagonist/cultivator/on_removal()
	if(breakthrough)
		breakthrough.cancel("Your cultivation is severed!")
	for(var/datum/action/technique as anything in techniques)
		qdel(technique)
	techniques.Cut()
	QDEL_LIST(laws)
	return ..()

/datum/antagonist/cultivator/greet()
	. = ..()
	to_chat(owner.current, span_boldnotice("Qi stirs in your dantian. You have stepped onto the path of cultivation!"))
	to_chat(owner.current, span_notice("Click the yin-yang orb on your screen (or the Path of Cultivation button) to open your cultivation panel. Work at your craft to earn <b>insight</b>, then <b>Meditate</b> to consolidate it. \
		When your foundation is ready, <b>Attempt Breakthrough</b> to reach the next realm. \
		Find more cultivation manuals (or a willing master) to learn more laws."))

/datum/antagonist/cultivator/apply_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = mob_override || owner.current
	RegisterSignal(current, COMSIG_LIVING_LIFE, PROC_REF(on_life))
	RegisterSignal(current, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(current, COMSIG_LIVING_DEATH, PROC_REF(on_death))
	RegisterSignal(current, COMSIG_MOB_CULTIVATION_CRAFTED, PROC_REF(on_crafted))
	RegisterSignal(current, COMSIG_MOB_CULTIVATION_TOOL_USED, PROC_REF(on_tool_used))
	RegisterSignal(current, COMSIG_MOB_CULTIVATION_SKILL_EXP, PROC_REF(on_skill_exp))
	RegisterSignal(current, COMSIG_MOB_CULTIVATION_HARVESTED, PROC_REF(on_harvested))
	RegisterSignal(current, COMSIG_MOB_SURGERY_STEP_SUCCESS, PROC_REF(on_surgery_step))
	RegisterSignal(current, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_item_attack))
	RegisterSignal(current, COMSIG_LIVING_UNARMED_ATTACK, PROC_REF(on_unarmed_attack))
	RegisterSignal(current, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, PROC_REF(qi_body))
	if(current.hud_used)
		on_hud_created()
	else
		RegisterSignal(current, COMSIG_MOB_HUD_CREATED, PROC_REF(on_hud_created))
	for(var/datum/cultivation_law/law as anything in laws)
		law.on_body_gained(current, src)
	update_light_body()

/datum/antagonist/cultivator/remove_innate_effects(mob/living/mob_override)
	. = ..()
	var/mob/living/current = mob_override || owner.current
	UnregisterSignal(current, list(
		COMSIG_LIVING_LIFE,
		COMSIG_ATOM_EXAMINE,
		COMSIG_LIVING_DEATH,
		COMSIG_MOB_HUD_CREATED,
		COMSIG_MOB_CULTIVATION_CRAFTED,
		COMSIG_MOB_CULTIVATION_TOOL_USED,
		COMSIG_MOB_CULTIVATION_SKILL_EXP,
		COMSIG_MOB_CULTIVATION_HARVESTED,
		COMSIG_MOB_SURGERY_STEP_SUCCESS,
		COMSIG_MOB_ITEM_ATTACK,
		COMSIG_LIVING_UNARMED_ATTACK,
		COMSIG_MOB_APPLY_DAMAGE_MODIFIERS,
	))
	if(current.hud_used && qi_display)
		current.hud_used.infodisplay -= qi_display
	QDEL_NULL(qi_display)
	for(var/datum/cultivation_law/law as anything in laws)
		law.on_body_lost(current, src)
	current.remove_movespeed_modifier(/datum/movespeed_modifier/qi_light_body)

/datum/antagonist/cultivator/on_body_transfer(mob/living/old_body, mob/living/new_body)
	if(breakthrough)
		breakthrough.cancel("Your soul is torn from your body mid-breakthrough!")
	return ..()

/datum/antagonist/cultivator/proc/on_hud_created(datum/source)
	SIGNAL_HANDLER
	var/datum/hud/hud = owner.current.hud_used
	if(!hud || qi_display)
		return
	qi_display = new /atom/movable/screen/cultivation_display(null, hud)
	hud.infodisplay += qi_display
	hud.show_hud(hud.hud_version)
	UnregisterSignal(owner.current, COMSIG_MOB_HUD_CREATED)
	update_hud()

/datum/antagonist/cultivator/proc/update_hud()
	if(!qi_display)
		return
	var/next = next_threshold()
	var/progress_text = next ? "[round(100 * progress / next)]%" : "MAX"
	var/obj/item/organ/dantian/dantian = get_dantian()
	var/ready = (next && progress >= next) || (dantian && dantian.grade < realm)
	qi_display.icon_state = ready ? "qi_display_ready" : "qi_display"
	var/progress_color = pending_insight >= CULTIVATION_MAX_PENDING_INSIGHT ? "#ff9a3c" : "#ffd55a"
	qi_display.maptext = MAPTEXT("<div align='center' valign='middle' style='position:relative; top:0px; left:6px'>\
		<font color='#7fd7ff'>[round(qi)]</font><br><font color='[progress_color]'>[ready ? "READY" : progress_text]</font></div>")
	qi_display.name = "Cultivation: [realm_name()] | Qi [round(qi)]/[max_qi()] | Insight [round(pending_insight)] pending, [progress_text] | Instability [round(instability)]"

// ----- Basic accessors -----

/datum/antagonist/cultivator/proc/realm_name(realm_to_name = realm)
	if(realm_to_name <= REALM_MORTAL)
		return "Mortal"
	return realm_names[clamp(realm_to_name, 1, length(realm_names))]

/datum/antagonist/cultivator/proc/max_qi()
	var/max = realm_max_qi[clamp(effective_realm(), 1, length(realm_max_qi))]
	var/obj/item/organ/dantian/dantian = get_dantian()
	if(dantian?.cracked)
		max = round(max / 2)
	return max

/// Progress needed for the next realm, or 0 if we're capped
/datum/antagonist/cultivator/proc/next_threshold()
	if(realm >= REALM_MAX)
		return 0
	return realm_thresholds[realm + 1]

/datum/antagonist/cultivator/proc/get_dantian()
	var/mob/living/carbon/body = owner.current
	if(!iscarbon(body))
		return null
	return body.get_organ_slot(ORGAN_SLOT_DANTIAN)

/// The realm our current body can actually wield: knowledge is capped by the dantian's grade.
/datum/antagonist/cultivator/proc/effective_realm()
	var/obj/item/organ/dantian/dantian = get_dantian()
	if(!dantian)
		return REALM_MORTAL
	return min(realm, dantian.grade)

/datum/antagonist/cultivator/proc/law_slots()
	if(realm >= REALM_NASCENT_SOUL)
		return 5
	return max(realm, 1)

/datum/antagonist/cultivator/proc/has_law(law_type)
	for(var/datum/cultivation_law/law as anything in laws)
		if(istype(law, law_type))
			return law
	return null

/datum/antagonist/cultivator/proc/has_element(element)
	for(var/datum/cultivation_law/law as anything in laws)
		if(law.element == element)
			return TRUE
	return FALSE

/datum/antagonist/cultivator/proc/adjust_qi(amount)
	qi = clamp(qi + amount, 0, max_qi())
	update_hud()

/datum/antagonist/cultivator/proc/adjust_instability(amount)
	instability = clamp(instability + amount, 0, 100)
	update_hud()

// ----- Insight -----

/**
 * Earn pending insight from a source. Each source has its own cooldown, so mixing up activities beats grinding one.
 * Returns the amount actually gained.
 */
/datum/antagonist/cultivator/proc/gain_insight(amount, source, cooldown = 30 SECONDS, silent = FALSE)
	if(amount <= 0)
		return 0
	if(source)
		if(world.time < insight_cooldowns[source])
			return 0
		insight_cooldowns[source] = world.time + cooldown
	var/multiplier = 1
	for(var/bonus_source in insight_bonuses)
		multiplier += insight_bonuses[bonus_source]
	// Heaven favours those it has mandated
	var/datum/component/mandate_of_heaven/mandate = owner.current?.GetComponent(/datum/component/mandate_of_heaven)
	if(mandate)
		multiplier += mandate.son_of_heaven ? 0.5 : 0.25
	// Nobles, Jinyiwei and sects sworn to a ruler
	multiplier += mandate_cultivation_bonus(owner.current)
	// Cultivating alongside fellow sect members
	var/datum/jianghu_sect/sect = jianghu_sect_of(owner)
	if(sect && owner.current)
		multiplier += sect.fellowship_bonus(owner.current)
	var/room = CULTIVATION_MAX_PENDING_INSIGHT - pending_insight
	var/gained = min(amount * multiplier, room)
	if(gained <= 0)
		if(!silent && COOLDOWN_FINISHED(src, full_warning_cooldown))
			COOLDOWN_START(src, full_warning_cooldown, 60 SECONDS)
			to_chat(owner.current, span_warning("Your mind is full of unconsolidated insight. Meditate to make room!"))
		return 0
	pending_insight += gained
	owner.current?.balloon_alert(owner.current, "+[round(gained, 0.1)] insight")
	if(pending_insight >= CULTIVATION_MAX_PENDING_INSIGHT)
		to_chat(owner.current, span_notice("Your pending insight is full. Meditate to consolidate it."))
	update_hud()
	return gained

/// Called by meditation: turns pending insight into progress
/datum/antagonist/cultivator/proc/consolidate(multiplier = 1)
	var/consolidated = pending_insight * multiplier
	progress += consolidated
	pending_insight = 0
	var/next = next_threshold()
	if(next && progress >= next)
		progress = next
		to_chat(owner.current, span_boldnotice("Your foundation is full. You are ready to attempt a breakthrough to [realm_name(realm + 1)]!"))
		owner.current?.balloon_alert(owner.current, "ready to break through!")
	update_hud()
	return consolidated

// Activity hooks. Each law decides what it cares about in /datum/cultivation_law/proc/on_activity

/datum/antagonist/cultivator/proc/notify_laws(activity, atom/thing)
	for(var/datum/cultivation_law/law as anything in laws)
		law.on_activity(src, activity, thing)

/// Light Body: qi makes you quicker on your feet, 6% per realm above Qi Condensation
/datum/movespeed_modifier/qi_light_body
	variable = TRUE

/datum/antagonist/cultivator/proc/update_light_body()
	var/mob/living/body = owner.current
	if(!body)
		return
	var/bonus = max(effective_realm() - REALM_QI_CONDENSATION, 0)
	if(bonus)
		body.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/qi_light_body, multiplicative_slowdown = -0.06 * bonus)
	else
		body.remove_movespeed_modifier(/datum/movespeed_modifier/qi_light_body)

/// Qi circulating through the body: 5% less brute and burn at Foundation, 10% at Golden Core, 15% at Nascent Soul
/datum/antagonist/cultivator/proc/qi_body(mob/living/source, list/damage_mods, damage, damagetype, ...)
	SIGNAL_HANDLER
	var/body_realm = effective_realm()
	if(body_realm < REALM_FOUNDATION || (damagetype != BRUTE && damagetype != BURN))
		return
	damage_mods += 1 - 0.05 * (body_realm - REALM_QI_CONDENSATION)

/datum/antagonist/cultivator/proc/on_crafted(mob/living/source, datum/crafting_recipe/recipe, atom/result)
	SIGNAL_HANDLER
	notify_laws(ispath(recipe.result, /obj/item/food) ? INSIGHT_SOURCE_COOK : INSIGHT_SOURCE_CRAFT, null)

/datum/antagonist/cultivator/proc/on_tool_used(mob/living/source, atom/target, obj/item/tool)
	SIGNAL_HANDLER
	notify_laws(tool.tool_behaviour == TOOL_WELDER ? INSIGHT_SOURCE_WELD : INSIGHT_SOURCE_TOOL, target)

/datum/antagonist/cultivator/proc/on_skill_exp(mob/living/source, skill, amount)
	SIGNAL_HANDLER
	if(amount <= 0)
		return
	var/static/list/skill_sources = list(
		/datum/skill/mining = INSIGHT_SOURCE_MINING,
		/datum/skill/cleaning = INSIGHT_SOURCE_CLEANING,
		/datum/skill/fishing = INSIGHT_SOURCE_FISHING,
		/datum/skill/athletics = INSIGHT_SOURCE_ATHLETICS,
	)
	var/activity = skill_sources[skill]
	if(activity)
		notify_laws(activity, null)

/datum/antagonist/cultivator/proc/on_harvested(mob/living/source, obj/machinery/hydroponics/tray)
	SIGNAL_HANDLER
	notify_laws(INSIGHT_SOURCE_HARVEST, tray)
	jianghu_mission_progress(owner, SECT_MISSION_HARVEST, 1)

/// Fighting teaches you too
/datum/antagonist/cultivator/proc/on_item_attack(mob/living/source, mob/living/target, mob/living/user)
	SIGNAL_HANDLER
	combat_insight(source, target)

/datum/antagonist/cultivator/proc/on_unarmed_attack(mob/living/source, atom/target, proximity, modifiers)
	SIGNAL_HANDLER
	if(proximity)
		combat_insight(source, target)

/datum/antagonist/cultivator/proc/combat_insight(mob/living/source, atom/target)
	if(!isliving(target) || target == source)
		return
	var/mob/living/opponent = target
	if(opponent.stat == DEAD)
		return
	gain_insight(3, INSIGHT_SOURCE_COMBAT, cooldown = 60 SECONDS, silent = TRUE)

/datum/antagonist/cultivator/proc/on_surgery_step(mob/living/source, datum/surgery_step/step, mob/living/target, ...)
	SIGNAL_HANDLER
	if(target != source)
		notify_laws(INSIGHT_SOURCE_SURGERY, target)

/// First successful use of each technique teaches you something
/datum/antagonist/cultivator/proc/on_technique_used(datum/action/technique)
	if(technique.type in used_techniques)
		return
	used_techniques += technique.type
	gain_insight(8, null, silent = TRUE)
	to_chat(owner.current, span_notice("<i>Using [technique.name] for the first time deepens your understanding.</i>"))

// ----- Laws and techniques -----

/// Try to learn a law. Returns TRUE on success.
/datum/antagonist/cultivator/proc/learn_law(law_type, counterfeit = FALSE, feedback = TRUE)
	var/mob/living/user = owner.current
	if(has_law(law_type))
		if(feedback)
			to_chat(user, span_warning("You already cultivate this law."))
		return FALSE
	if(length(laws) >= law_slots())
		if(feedback)
			to_chat(user, span_warning("Your meridians cannot hold another law yet! Break through to a higher realm first."))
		return FALSE
	var/datum/cultivation_law/new_law = new law_type()
	new_law.counterfeit = counterfeit
	// Five element interactions with what we already know
	for(var/datum/cultivation_law/known as anything in laws)
		if(GLOB.cultivation_overcomes[known.element] == new_law.element || GLOB.cultivation_overcomes[new_law.element] == known.element)
			adjust_instability(15)
			if(feedback)
				to_chat(user, span_warning("[new_law.name] clashes with [known.name]. Your qi churns uneasily..."))
		else if(GLOB.cultivation_generates[known.element] == new_law.element || GLOB.cultivation_generates[new_law.element] == known.element)
			if(feedback)
				to_chat(user, span_notice("[new_law.name] flows naturally from [known.name]."))
	laws += new_law
	if(counterfeit)
		adjust_instability(10)
	new_law.on_body_gained(user, src)
	if(feedback)
		to_chat(user, span_boldnotice("You have learned [new_law.name]!"))
		to_chat(user, span_notice(new_law.desc))
	refresh_techniques()
	return TRUE

/// Movement techniques reach further as the realm rises: Qinggong 4 tiles plus 2 per realm, Void Step 6 plus 2 per realm past Golden Core
/datum/antagonist/cultivator/proc/refresh_technique_ranges()
	var/bonus = max(realm - REALM_QI_CONDENSATION, 0)
	for(var/datum/action/cooldown/spell/pointed/cultivation/qinggong/qinggong in techniques)
		qinggong.cast_range = 4 + 2 * bonus
	for(var/datum/action/cooldown/spell/pointed/cultivation/void_step/void_step in techniques)
		void_step.cast_range = 6 + 2 * max(realm - REALM_GOLDEN_CORE, 0)

/// Make sure we have every technique our realm and laws allow
/datum/antagonist/cultivator/proc/refresh_techniques()
	for(var/technique_type in universal_techniques)
		if(realm >= universal_techniques[technique_type])
			grant_technique(technique_type)
	for(var/datum/cultivation_law/law as anything in laws)
		for(var/technique_type in law.techniques)
			if(realm >= law.techniques[technique_type])
				grant_technique(technique_type)
	// Combination techniques
	for(var/datum/cultivation_combo/combo as anything in GLOB.cultivation_combos)
		if(has_element(combo.element_one) && has_element(combo.element_two) && realm >= combo.realm_required)
			if(!(combo.technique in typecache_of_techniques()))
				to_chat(owner.current, span_boldnotice("Your [combo.element_one] and [combo.element_two] qi resonate! You have comprehended [initial(combo.technique.name)]!"))
			grant_technique(combo.technique)
	grant_forbidden_techniques()
	refresh_technique_ranges()

/// The realm a technique type was unlocked at
/datum/antagonist/cultivator/proc/required_realm_for(technique_type)
	if(technique_type in universal_techniques)
		return universal_techniques[technique_type]
	for(var/datum/cultivation_law/law as anything in laws)
		if(technique_type in law.techniques)
			return law.techniques[technique_type]
	for(var/datum/cultivation_combo/combo as anything in GLOB.cultivation_combos)
		if(combo.technique == technique_type)
			return combo.realm_required
	if(technique_type in GLOB.cultivation_forbidden_techniques)
		return GLOB.cultivation_forbidden_techniques[technique_type]
	return REALM_QI_CONDENSATION

/datum/antagonist/cultivator/proc/typecache_of_techniques()
	. = list()
	for(var/datum/action/technique as anything in techniques)
		. += technique.type

/datum/antagonist/cultivator/proc/grant_technique(technique_type)
	for(var/datum/action/technique as anything in techniques)
		if(technique.type == technique_type)
			return technique
	if(owner.current && (locate(technique_type) in owner.current.actions))
		return
	var/datum/action/new_technique = new technique_type(owner)
	techniques += new_technique
	RegisterSignal(new_technique, COMSIG_QDELETING, PROC_REF(on_technique_deleted))
	if(owner.current)
		new_technique.Grant(owner.current)
	return new_technique

/datum/antagonist/cultivator/proc/on_technique_deleted(datum/action/source)
	SIGNAL_HANDLER
	techniques -= source

/// Successfully reaching a new realm
/datum/antagonist/cultivator/proc/advance_realm()
	var/obj/item/organ/dantian/dantian = get_dantian()
	if(dantian && dantian.grade < realm)
		// Restoring a damaged foundation in a new body, no new realm
		dantian.set_grade(dantian.grade + 1)
	else
		realm = min(realm + 1, REALM_MAX)
		progress = 0
		dantian?.set_grade(realm)
	breakthroughs_survived++
	qi = max_qi()
	refresh_techniques()
	for(var/datum/cultivation_law/law as anything in laws)
		law.on_realm_up(src)
	SEND_SIGNAL(owner.current, COMSIG_MOB_CULTIVATION_REALM_CHANGED, src)
	update_light_body()
	update_hud()

// ----- Life -----

/datum/antagonist/cultivator/proc/on_life(mob/living/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER
	if(source.stat == DEAD)
		return
	if(effective_realm() > REALM_MORTAL && qi < max_qi())
		adjust_qi((0.25 + 0.1 * effective_realm()) * seconds_per_tick)
	core_sustain(source, seconds_per_tick)
	if(pill_toxicity > 0)
		pill_toxicity = max(pill_toxicity - 0.1 * seconds_per_tick, 0)
	passive_timer += seconds_per_tick
	if(passive_timer >= CULTIVATION_PASSIVE_INTERVAL)
		passive_timer = 0
		INVOKE_ASYNC(src, PROC_REF(passive_insight), source)
	var/area/here = get_area(source)
	if(here && !(here.type in visited_areas))
		visited_areas += here.type
		if(length(visited_areas) > 1) // the room you awaken in doesn't count
			gain_insight(2, INSIGHT_SOURCE_EXPLORE, cooldown = 15 SECONDS, silent = TRUE)
	if(instability >= 50 && COOLDOWN_FINISHED(src, instability_cooldown) && SPT_PROB(instability / 10, seconds_per_tick))
		COOLDOWN_START(src, instability_cooldown, 20 SECONDS)
		INVOKE_ASYNC(src, PROC_REF(instability_flare), source)
	if(COOLDOWN_FINISHED(src, epiphany_cooldown) && SPT_PROB(source.GetComponent(/datum/component/mandate_of_heaven) ? 2 : 1, seconds_per_tick))
		COOLDOWN_START(src, epiphany_cooldown, 30 SECONDS)
		INVOKE_ASYNC(src, PROC_REF(check_epiphany), source)

/// A Golden Core keeps its owner alive in critical condition, burning qi to do it. Twice as strong at Nascent Soul.
/datum/antagonist/cultivator/proc/core_sustain(mob/living/source, seconds_per_tick)
	var/core_realm = effective_realm()
	if(core_realm < REALM_GOLDEN_CORE || source.stat == DEAD || source.health > source.crit_threshold)
		core_sustain_announced = FALSE
		return
	var/strength = core_realm >= REALM_NASCENT_SOUL ? 2 : 1
	// Qi fuels it, but even an empty core gives a little
	var/fuelled = qi >= 1
	if(fuelled)
		adjust_qi(-1 * seconds_per_tick)
	var/heal = (fuelled ? 1.5 : 0.5) * strength * seconds_per_tick
	source.heal_overall_damage(brute = heal, burn = heal, updating_health = FALSE)
	source.adjustOxyLoss(-2 * strength * seconds_per_tick, updating_health = FALSE)
	source.updatehealth()
	if(!core_sustain_announced)
		core_sustain_announced = TRUE
		to_chat(source, span_boldnotice("Your [core_realm >= REALM_NASCENT_SOUL ? "nascent soul" : "golden core"] blazes inside you, refusing to let you die!"))
		source.add_filter("core_sustain", 2, list("type" = "outline", "color" = "#ffd55a", "size" = 1))
		addtimer(CALLBACK(source, TYPE_PROC_REF(/datum, remove_filter), "core_sustain"), 3 SECONDS)

/// Cultivation never really stops: a trickle of insight just from living, more near your elements
/datum/antagonist/cultivator/proc/passive_insight(mob/living/source)
	if(source.stat != CONSCIOUS || effective_realm() <= REALM_MORTAL)
		return
	var/amount = 1
	var/list/points = cultivation_count_elements(get_turf(source))
	for(var/datum/cultivation_law/law as anything in laws)
		if(points[law.element])
			amount++
			break
	gain_insight(amount, INSIGHT_SOURCE_PASSIVE, cooldown = 0, silent = TRUE)

/// Unstable qi does unpleasant, visible things
/datum/antagonist/cultivator/proc/instability_flare(mob/living/source)
	// Badly deviated qi takes on a face of its own
	if(instability >= 90 && prob(30) && COOLDOWN_FINISHED(src, heart_demon_cooldown))
		COOLDOWN_START(src, heart_demon_cooldown, 10 MINUTES)
		cultivation_summon_heart_demon(source)
		return
	switch(rand(1, 3))
		if(1)
			source.visible_message(span_warning("Sparks of wild qi crackle off [source]!"), span_warning("Your qi flares out of control!"))
			do_sparks(3, FALSE, source)
			adjust_qi(-10)
		if(2)
			to_chat(source, span_warning("Your meridians throb painfully."))
			source.adjustStaminaLoss(20)
		if(3)
			if(instability >= 80)
				source.visible_message(span_danger("[source] coughs up a mouthful of blood!"), span_danger("You cough up blood as your qi deviates!"))
				source.adjustBruteLoss(5)
				if(iscarbon(source))
					var/mob/living/carbon/carbon_source = source
					carbon_source.vomit(VOMIT_CATEGORY_BLOOD, lost_nutrition = 0, distance = 0)
			else
				to_chat(source, span_warning("Your vision swims as your qi churns."))
				source.adjust_dizzy(5 SECONDS)

/// Mundane things around you might suddenly make sense
/datum/antagonist/cultivator/proc/check_epiphany(mob/living/source)
	var/static/list/inspiring = list(
		/obj/machinery/power/supermatter_crystal = "the shimmering supermatter",
		/obj/structure/sink = "water dripping from a sink",
		/obj/machinery/hydroponics = "a plant slowly growing",
		/obj/structure/fireplace = "the dancing flames",
		/obj/machinery/gravity_generator = "the hum of gravity itself",
		/turf/open/space = "the cold, endless stars",
		/obj/machinery/power/solar = "starlight striking a solar panel",
		/obj/structure/aquarium = "fish circling in their tank",
	)
	if(source.incapacitated || breakthrough)
		return
	for(var/atom/thing as anything in view(4, source))
		for(var/inspiring_type in inspiring)
			if(!istype(thing, inspiring_type))
				continue
			source.visible_message(
				span_notice("[source] suddenly freezes, staring at [thing] with wide eyes. A faint glow surrounds [source.p_them()]."),
				span_boldnotice("Watching [inspiring[inspiring_type]], something clicks. An epiphany! Stay where you are for a few seconds and let it sink in..."),
			)
			source.add_filter("epiphany_glow", 2, list("type" = "outline", "color" = "#ffe9a0", "size" = 1))
			addtimer(CALLBACK(src, PROC_REF(finish_epiphany), source, get_turf(source)), 8 SECONDS)
			return

/datum/antagonist/cultivator/proc/finish_epiphany(mob/living/source, turf/epiphany_turf)
	if(QDELETED(source))
		return
	source.remove_filter("epiphany_glow")
	if(source != owner.current || get_turf(source) != epiphany_turf || source.stat != CONSCIOUS)
		to_chat(source, span_warning("The epiphany slips away..."))
		return
	cultivation_wind_chimes(source)
	gain_insight(20, INSIGHT_SOURCE_EPIPHANY, cooldown = 10 MINUTES)

/datum/antagonist/cultivator/proc/on_death(mob/living/source, gibbed)
	SIGNAL_HANDLER
	if(breakthrough)
		breakthrough.cancel()
	if(gibbed || effective_realm() < REALM_NASCENT_SOUL)
		return
	if(!COOLDOWN_FINISHED(src, nascent_revival_cooldown))
		to_chat(source, span_warning("Your nascent soul is still exhausted from its last return. It cannot carry you back this time."))
		return
	COOLDOWN_START(src, nascent_revival_cooldown, 10 MINUTES)
	to_chat(source, span_boldnotice("Your body dies... but your nascent soul stirs. Hold on."))
	addtimer(CALLBACK(src, PROC_REF(nascent_rise), source), 8 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(nascent_revive), source), 12 SECONDS)

/// The nascent soul climbs out of the corpse
/datum/antagonist/cultivator/proc/nascent_rise(mob/living/body)
	if(QDELETED(body) || body.stat != DEAD || !get_dantian())
		return
	body.visible_message(span_boldwarning("A tiny golden figure, a perfect miniature of [body], sits up out of the corpse and begins to glow!"))
	var/obj/effect/temp_visual/decoy/fading/threesecond/soul = new(get_turf(body), body)
	soul.color = "#ffe27a"
	soul.transform = matrix().Scale(0.4)
	soul.pixel_y = 10
	animate(soul, pixel_y = 16, transform = matrix().Scale(0.6), time = 3 SECONDS)
	cultivation_particles(body, /particles/cultivation/gold, 4 SECONDS)
	cultivation_temple_sound(body, 50)

/// ...and drags it back to life
/datum/antagonist/cultivator/proc/nascent_revive(mob/living/body)
	if(QDELETED(body) || body.stat != DEAD || !get_dantian() || owner.current != body)
		return
	body.revive(HEAL_DAMAGE | HEAL_ORGANS | HEAL_LIMBS | HEAL_BLOOD | HEAL_WOUNDS | HEAL_TEMP, force_grab_ghost = TRUE)
	if(body.stat == DEAD)
		to_chat(body, span_userdanger("Your nascent soul strains, but this body is too broken to return to."))
		return
	adjust_qi(-qi)
	adjust_instability(20)
	new /obj/effect/temp_visual/cultivation_ascension_pillar(get_turf(body))
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(get_turf(body))
	cultivation_great_bell(body, 70)
	body.visible_message(span_boldwarning("[body] gasps and rises again, golden light pouring from [body.p_their()] eyes!"), span_boldnotice("Your nascent soul drags you back from death! It will need ten minutes to recover before it can do so again."))
	body.log_message("was revived by their Nascent Soul", LOG_GAME)
	// Every cultivator on the station feels it
	for(var/datum/antagonist/cultivator/other in GLOB.antagonists)
		var/mob/living/feeler = other.owner?.current
		if(!feeler || feeler == body || feeler.stat == DEAD || feeler.z != body.z)
			continue
		to_chat(feeler, span_boldwarning("<i>A shiver runs down your spine. Somewhere on the station, a vast presence that should be dead has awakened... and it is stronger than you.</i>"))
		feeler.playsound_local(get_turf(feeler), 'sound/effects/gong.ogg', 40, TRUE, frequency = 0.4)

// ----- Examine: the arrogant young master experience -----

/datum/antagonist/cultivator/proc/on_examine(mob/living/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	var/datum/antagonist/cultivator/other = IS_CULTIVATOR(user)
	if(!other || other == src)
		return
	var/my_realm = effective_realm()
	var/their_realm = other.effective_realm()
	if(their_realm > my_realm)
		examine_list += span_notice("[source.p_They()] [source.p_are()] a mere [realm_name(my_realm)] cultivator. [pick("An ant.", "Beneath your notice.", "Barely worth the qi to look at.", "You could crush [source.p_them()] with a glance.")]")
	else if(their_realm < my_realm)
		examine_list += span_warning("[source.p_Their()] cultivation is unfathomable. [pick("You feel like a frog at the bottom of a well.", "Your knees feel weak.", "Do NOT offend this senior.")]")
	else
		examine_list += span_notice("[source.p_They()] [source.p_are()] a fellow [realm_name(my_realm)] cultivator.")

// ----- Roundend / admin -----

/datum/antagonist/cultivator/roundend_report()
	var/list/report = list()
	report += printplayer(owner)
	var/list/law_names = list()
	for(var/datum/cultivation_law/law as anything in laws)
		law_names += law.name
	report += "Reached <b>[realm_name()]</b>[length(law_names) ? " cultivating [english_list(law_names)]" : ""]."
	if(ascended)
		report += span_greentext("Shattered the void and ascended to the Immortal Realm!")
	report += "Breakthroughs survived: [breakthroughs_survived]. Failed: [breakthroughs_failed]."
	if(demonic)
		report += span_redtext("Walked the Demonic Path[demonic >= DEMONIC_MASTER ? " as a master" : " as a disciple"].")
	return report.Join("<br>")

/datum/antagonist/cultivator/get_admin_commands()
	. = ..()
	.["Give 50 Insight (consolidated)"] = CALLBACK(src, PROC_REF(admin_give_progress))
	.["Force Realm Up"] = CALLBACK(src, PROC_REF(advance_realm))
	.["Teach Law"] = CALLBACK(src, PROC_REF(admin_teach_law))
	.["Refill Qi"] = CALLBACK(src, PROC_REF(adjust_qi), 1000)
	.["Grant Demonic Path (master)"] = CALLBACK(src, PROC_REF(admin_grant_forbidden))

/datum/antagonist/cultivator/proc/admin_give_progress(mob/admin)
	var/next = next_threshold()
	// At the peak, keep counting towards Ascension
	progress = next ? min(progress + 50, next) : progress + 50
	update_hud()

/datum/antagonist/cultivator/proc/admin_teach_law(mob/admin)
	var/list/options = list()
	for(var/datum/cultivation_law/law_type as anything in subtypesof(/datum/cultivation_law))
		options[initial(law_type.name)] = law_type
	var/choice = tgui_input_list(admin, "Teach which law? (ignores slots)", "Teach Law", options)
	if(!choice)
		return
	var/old_realm = realm
	realm = REALM_MAX // bypass slot cap
	learn_law(options[choice])
	realm = old_realm

/// HUD readout of qi (top number) and progress to the next realm (bottom)
/atom/movable/screen/cultivation_display
	name = "Cultivation"
	icon = 'surfshack13/icons/cultivation/cultivation_hud.dmi'
	icon_state = "qi_display"
	screen_loc = "WEST:6,CENTER+1:5"
	maptext_width = 64
	maptext_height = 32
	maptext_x = -16
	maptext_y = 2

/atom/movable/screen/cultivation_display/Click(location, control, params)
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(usr)
	if(!cultivator)
		return
	cultivator.open_panel(usr)

/datum/antagonist/cultivator/proc/status_report()
	var/list/text = list()
	text += span_boldnotice("Realm: [realm_name()]")
	var/obj/item/organ/dantian/dantian = get_dantian()
	if(!dantian)
		text += span_danger("You have no dantian! Your techniques are useless. Meditate to slowly form a new one.")
	else if(dantian.grade < realm)
		text += span_warning("This body's dantian is only at [realm_name(dantian.grade)]. Breakthroughs will restore it without needing insight.")
	if(dantian?.cracked)
		text += span_warning("Your core is cracked! Max qi is halved. Meditate on a good mat to mend it.")
	text += "Qi: [round(qi)] / [max_qi()]"
	var/next = next_threshold()
	text += "Insight: [round(pending_insight)] pending (cap [CULTIVATION_MAX_PENDING_INSIGHT]), [next ? "[round(progress)] / [next] consolidated" : "at peak, [round(progress)] / [CULTIVATION_ASCENSION_PROGRESS] towards Ascension"]"
	text += "Instability: [round(instability)][instability >= 50 ? span_warning(" (dangerous)") : ""]"
	var/list/law_names = list()
	for(var/datum/cultivation_law/law as anything in laws)
		law_names += "[law.name] ([law.element])[law.counterfeit ? " <i>(counterfeit?)</i>" : ""]"
	text += "Laws ([length(laws)]/[law_slots()]): [length(law_names) ? english_list(law_names) : "none"]"
	return text.Join("<br>")
