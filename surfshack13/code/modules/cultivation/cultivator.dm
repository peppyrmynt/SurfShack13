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
	/// HUD element showing qi / insight
	var/atom/movable/screen/cultivation_display/qi_display
	/// Next world.time an epiphany can trigger
	COOLDOWN_DECLARE(epiphany_cooldown)
	/// Spam limiter for the instability side effects
	COOLDOWN_DECLARE(instability_cooldown)

	/// Progress needed to reach realm (index = target realm)
	var/static/list/realm_thresholds = list(0, 60, 150, 300)
	/// Max qi per realm (index = realm)
	var/static/list/realm_max_qi = list(50, 100, 175, 275)
	/// Display names per realm (index = realm)
	var/static/list/realm_names = list("Qi Condensation", "Foundation Establishment", "Golden Core", "Nascent Soul")
	/// Techniques everyone gets, by required realm
	var/static/list/universal_techniques = list(
		/datum/action/cooldown/spell/cultivation/meditate = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/cultivation/breakthrough = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/cultivation/spiritual_sense = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/pointed/cultivation/empty_palm = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/pointed/cultivation/qinggong = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/cultivation/write_talisman = REALM_QI_CONDENSATION,
		/datum/action/cooldown/spell/pointed/cultivation/teach = REALM_FOUNDATION,
		/datum/action/cooldown/spell/pointed/cultivation/beast_contract = REALM_FOUNDATION,
		/datum/action/cooldown/spell/pointed/cultivation/acupoint = REALM_FOUNDATION,
		/datum/action/cooldown/spell/cultivation/realm_pressure = REALM_GOLDEN_CORE,
	)

/datum/antagonist/cultivator/on_gain()
	. = ..()
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
	to_chat(owner.current, span_notice("Work at your craft to earn <b>insight</b>, then <b>Meditate</b> to consolidate it. \
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
	if(current.hud_used)
		on_hud_created()
	else
		RegisterSignal(current, COMSIG_MOB_HUD_CREATED, PROC_REF(on_hud_created))
	for(var/datum/cultivation_law/law as anything in laws)
		law.on_body_gained(current, src)

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
	))
	if(current.hud_used && qi_display)
		current.hud_used.infodisplay -= qi_display
	QDEL_NULL(qi_display)
	for(var/datum/cultivation_law/law as anything in laws)
		law.on_body_lost(current, src)

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
	qi_display.maptext = MAPTEXT("<div align='center' valign='middle' style='position:relative; top:0px; left:6px'>\
		<font color='#7fd7ff'>[round(qi)]</font><br><font color='#ffd55a'>[progress_text]</font></div>")
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
	var/room = CULTIVATION_MAX_PENDING_INSIGHT - pending_insight
	var/gained = min(amount * multiplier, room)
	if(gained <= 0)
		if(!silent)
			to_chat(owner.current, span_warning("Your mind is full of unconsolidated insight. You need to meditate!"))
		return 0
	pending_insight += gained
	if(!silent)
		to_chat(owner.current, span_notice("<i>You gain insight into the Dao. ([round(gained)])</i>"))
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
	update_hud()
	return consolidated

// Activity hooks. Each law decides what it cares about in /datum/cultivation_law/proc/on_activity

/datum/antagonist/cultivator/proc/notify_laws(activity, atom/thing)
	for(var/datum/cultivation_law/law as anything in laws)
		law.on_activity(src, activity, thing)

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

/datum/antagonist/cultivator/proc/typecache_of_techniques()
	. = list()
	for(var/datum/action/technique as anything in techniques)
		. += technique.type

/datum/antagonist/cultivator/proc/grant_technique(technique_type)
	for(var/datum/action/technique as anything in techniques)
		if(technique.type == technique_type)
			return technique
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
	update_hud()

// ----- Life -----

/datum/antagonist/cultivator/proc/on_life(mob/living/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER
	if(source.stat == DEAD)
		return
	if(effective_realm() > REALM_MORTAL && qi < max_qi())
		adjust_qi(0.25 * seconds_per_tick)
	if(instability >= 50 && COOLDOWN_FINISHED(src, instability_cooldown) && SPT_PROB(instability / 10, seconds_per_tick))
		COOLDOWN_START(src, instability_cooldown, 20 SECONDS)
		INVOKE_ASYNC(src, PROC_REF(instability_flare), source)
	if(COOLDOWN_FINISHED(src, epiphany_cooldown) && SPT_PROB(1, seconds_per_tick))
		COOLDOWN_START(src, epiphany_cooldown, 30 SECONDS)
		INVOKE_ASYNC(src, PROC_REF(check_epiphany), source)

/// Unstable qi does unpleasant, visible things
/datum/antagonist/cultivator/proc/instability_flare(mob/living/source)
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
	gain_insight(20, INSIGHT_SOURCE_EPIPHANY, cooldown = 10 MINUTES)

/datum/antagonist/cultivator/proc/on_death(mob/living/source, gibbed)
	SIGNAL_HANDLER
	if(breakthrough)
		breakthrough.cancel()

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
	report += "Breakthroughs survived: [breakthroughs_survived]. Failed: [breakthroughs_failed]."
	return report.Join("<br>")

/datum/antagonist/cultivator/get_admin_commands()
	. = ..()
	.["Give 50 Insight (consolidated)"] = CALLBACK(src, PROC_REF(admin_give_progress))
	.["Force Realm Up"] = CALLBACK(src, PROC_REF(advance_realm))
	.["Teach Law"] = CALLBACK(src, PROC_REF(admin_teach_law))
	.["Refill Qi"] = CALLBACK(src, PROC_REF(adjust_qi), 1000)

/datum/antagonist/cultivator/proc/admin_give_progress(mob/admin)
	progress = min(progress + 50, next_threshold() || progress)
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
	to_chat(usr, boxed_message(cultivator.status_report()))

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
	text += "Insight: [round(pending_insight)] pending (cap [CULTIVATION_MAX_PENDING_INSIGHT]), [next ? "[round(progress)] / [next] consolidated" : "at peak"]"
	text += "Instability: [round(instability)][instability >= 50 ? span_warning(" (dangerous)") : ""]"
	var/list/law_names = list()
	for(var/datum/cultivation_law/law as anything in laws)
		law_names += "[law.name] ([law.element])[law.counterfeit ? " <i>(counterfeit?)</i>" : ""]"
	text += "Laws ([length(laws)]/[law_slots()]): [length(law_names) ? english_list(law_names) : "none"]"
	return text.Join("<br>")
