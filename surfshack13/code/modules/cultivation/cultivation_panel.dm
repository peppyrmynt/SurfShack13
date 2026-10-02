/**
 * The Path of Cultivation panel. Opens from the HUD orb or the Cultivation Panel action.
 * One scrolling page: realm and bars, what to do next, laws (and where their insight comes from), techniques, jianghu standing.
 */

/// Friendly names for insight sources, shown in the panel
GLOBAL_LIST_INIT(cultivation_activity_names, list(
	INSIGHT_SOURCE_CRAFT = "crafting",
	INSIGHT_SOURCE_COOK = "cooking",
	INSIGHT_SOURCE_TOOL = "repairs and construction",
	INSIGHT_SOURCE_WELD = "welding",
	INSIGHT_SOURCE_MINING = "mining",
	INSIGHT_SOURCE_CLEANING = "cleaning",
	INSIGHT_SOURCE_FISHING = "fishing",
	INSIGHT_SOURCE_ATHLETICS = "gym training",
	INSIGHT_SOURCE_HARVEST = "harvesting plants",
	INSIGHT_SOURCE_SURGERY = "surgery and healing others",
	INSIGHT_SOURCE_DRINK_WATER = "drinking water",
))

GLOBAL_LIST_INIT(cultivation_element_colors, list(
	ELEMENT_METAL = "#c8d2e0",
	ELEMENT_WATER = "#4fb3ff",
	ELEMENT_WOOD = "#5fd35f",
	ELEMENT_FIRE = "#ff7a3c",
	ELEMENT_EARTH = "#c79a5a",
))

/datum/action/cultivation_panel
	name = "Path of Cultivation"
	desc = "Open your cultivation panel: realm, progress, laws, techniques and standing in the jianghu."
	button_icon = 'surfshack13/icons/cultivation/cultivation_actions.dmi'
	button_icon_state = "cultivation_panel"
	background_icon_state = "bg_heretic"
	overlay_icon_state = "bg_heretic_border"
	check_flags = NONE

/datum/action/cultivation_panel/Trigger(mob/clicker, trigger_flags)
	. = ..()
	if(!.)
		return
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(owner)
	cultivator?.open_panel(owner)

/datum/antagonist/cultivator/proc/open_panel(mob/user)
	var/datum/browser/popup = new(user, "cultivation_panel", "Path of Cultivation", 560, 720)
	popup.set_content(panel_html())
	popup.open()

/datum/antagonist/cultivator/Topic(href, list/href_list)
	if(href_list["cultivation_refresh"] && usr == owner.current)
		open_panel(usr)
		return
	if(href_list["cultivation_ascend"] && usr == owner.current)
		start_ascension(usr)
		return
	return ..()

/// A labelled progress bar
/datum/antagonist/cultivator/proc/panel_bar(label, value, maximum, color, text_override)
	var/percent = maximum ? clamp(round(100 * value / maximum), 0, 100) : 100
	return {"<div class='bar-label'>[label] <span class='dim'>[text_override || "[round(value)] / [round(maximum)]"]</span></div>
		<div class='bar'><div class='fill' style='width:[percent]%; background:[color];'></div></div>"}

/datum/antagonist/cultivator/proc/panel_html()
	var/mob/living/body = owner.current
	var/obj/item/organ/dantian/dantian = get_dantian()
	var/next = next_threshold()
	var/list/html = list()
	html += {"<style>
		body { background:#14121c; color:#e8e2d0; font-family:Verdana, sans-serif; font-size:12px; }
		h1 { color:#ffd55a; font-size:20px; margin:4px 0; letter-spacing:1px; }
		h2 { color:#d4a017; font-size:14px; border-bottom:1px solid #4a3d1c; margin:14px 0 6px; padding-bottom:2px; }
		.dim { color:#9a93a8; }
		.bar-label { margin-top:6px; }
		.bar { background:#2a2638; border:1px solid #3d3752; height:12px; border-radius:6px; overflow:hidden; }
		.fill { height:100%; border-radius:6px; }
		.card { background:#1f1b2b; border:1px solid #3a3350; border-radius:6px; padding:6px 8px; margin:4px 0; }
		.chip { display:inline-block; padding:1px 6px; border-radius:8px; font-size:11px; color:#14121c; font-weight:bold; }
		.warn { color:#ff9a3c; } .bad { color:#ff5a5a; } .good { color:#7fe08a; }
		.tech { margin:3px 0; } .tech b { color:#ffe9a0; }
		a.btn { color:#14121c; background:#d4a017; padding:2px 8px; border-radius:4px; text-decoration:none; font-weight:bold; }
	</style>"}
	html += "<div style='float:right'><a class='btn' href='byond://?src=[REF(src)];cultivation_refresh=1'>Refresh</a></div>"
	html += "<h1>[realm_name()]</h1>"
	html += "<div class='dim'>[body?.real_name || owner.name], cultivating [length(laws)] of [law_slots()] possible laws</div>"

	// Bars
	html += panel_bar("Qi", qi, max_qi(), "linear-gradient(90deg,#2b6fd6,#7fd7ff)")
	html += panel_bar("Pending insight", pending_insight, CULTIVATION_MAX_PENDING_INSIGHT, "linear-gradient(90deg,#8a5cd6,#c9a7ff)")
	if(next)
		html += panel_bar("Foundation towards [realm_name(realm + 1)]", progress, next, "linear-gradient(90deg,#b8860b,#ffd55a)")
	else
		html += panel_bar("Foundation towards Ascension", progress, CULTIVATION_ASCENSION_PROGRESS, "linear-gradient(90deg,#b8860b,#fff3b0)")
	html += panel_bar("Instability", instability, 100, "linear-gradient(90deg,#a02020,#ff5a5a)")
	if(pill_toxicity >= 1)
		html += panel_bar("Pill toxicity", pill_toxicity, 60, "linear-gradient(90deg,#3c8a3c,#b8e05a)", "[round(pill_toxicity)] (above 30, pills cause instability)")

	// What to do next
	html += "<h2>The way forward</h2><div class='card'>"
	if(!dantian)
		html += "<span class='bad'>You have no dantian!</span> Meditate three cycles to grow a new one."
	else if(dantian.grade < realm)
		html += "<span class='warn'>This body's dantian is only at [realm_name(dantian.grade)].</span> Attempt Breakthrough to restore it; no insight needed."
	else if(!next && progress >= CULTIVATION_ASCENSION_PROGRESS)
		html += "<span class='good'>You are ready to Ascend.</span> Succeed and you leave this world (the round) forever. \
			<a class='btn' href='byond://?src=[REF(src)];cultivation_ascend=1'>Attempt Ascension</a>"
	else if(!next)
		html += "You stand at the peak of this world. Consolidate [CULTIVATION_ASCENSION_PROGRESS] insight to attempt <b>Ascension</b> (with <b>Attempt Breakthrough</b> or from this panel)."
	else if(next && progress >= next)
		html += "<span class='good'>Your foundation is full!</span> Prepare a mat, fill your qi, find a grounding rod, then <b>Attempt Breakthrough</b>."
	else if(pending_insight >= CULTIVATION_MAX_PENDING_INSIGHT)
		html += "<span class='warn'>Your pending insight is full.</span> <b>Meditate</b> to consolidate it."
	else
		html += "Earn insight by working, exploring, fighting, reading, drinking tea and using your techniques. Then <b>Meditate</b> to consolidate it."
	if(dantian?.cracked)
		html += "<br><span class='bad'>Your core is cracked:</span> max qi halved. Meditate on a mat to mend it ([dantian.mend_sessions] cycles)."
	if(instability >= 50)
		html += "<br><span class='bad'>Your qi is unstable.</span> Meditate to calm it before it hurts you."
	html += "</div>"

	// Laws
	html += "<h2>Laws</h2>"
	if(!length(laws))
		html += "<div class='card dim'>You know no laws yet. Find a cultivation manual, or a master willing to teach you.</div>"
	for(var/datum/cultivation_law/law as anything in laws)
		var/list/sources = list()
		for(var/activity in law.insight_activities)
			sources += GLOB.cultivation_activity_names[activity] || activity
		html += "<div class='card'><span class='chip' style='background:[GLOB.cultivation_element_colors[law.element]]'>[law.element]</span> \
			<b>[law.name]</b>[law.counterfeit ? " <span class='warn'>(counterfeit: +50% qi costs, you shout move names)</span>" : ""]<br>\
			<span class='dim'>[law.desc]</span><br>Insight from: [english_list(sources)]</div>"

	// Techniques
	html += "<h2>Techniques</h2>"
	for(var/datum/action/technique as anything in techniques)
		var/ready_text = ""
		if(istype(technique, /datum/action/cooldown))
			var/datum/action/cooldown/cooldown_action = technique
			if(cooldown_action.next_use_time > world.time)
				ready_text = " <span class='dim'>(ready in [DisplayTimeText(cooldown_action.next_use_time - world.time, 1)])</span>"
		html += "<div class='tech'><b>[technique.name]</b>[ready_text]<br><span class='dim'>[technique.desc]</span></div>"

	// Jianghu
	html += "<h2>The Jianghu</h2><div class='card'>"
	var/face = jianghu_face_of(owner)
	html += "Face: <b>[face]</b>[jianghu_face_title(face) ? " ([jianghu_face_title(face)])" : ""]<br>"
	var/datum/jianghu_sect/sect = jianghu_sect_of(owner)
	if(sect)
		html += "Sect: <b>[sect.name]</b>, you are [sect.rank_of(owner)]. Members: [length(sect.members)]."
		if(length(sect.rivals))
			var/list/rival_names = list()
			for(var/datum/jianghu_sect/rival as anything in sect.rivals)
				rival_names += rival.name
			html += " <span class='bad'>Rivals: [english_list(rival_names)]</span>"
	else
		html += "<span class='dim'>You belong to no sect. Found one at Foundation Establishment, or ask to join at a sect plaque.</span>"
	var/datum/component/mandate_of_heaven/mandate = body?.GetComponent(/datum/component/mandate_of_heaven)
	if(mandate)
		html += "<br><span style='color:#ffd55a'>You bear the Mandate of Heaven as [mandate.title_of()]. Your cultivation is blessed.</span>"
	html += "</div>"
	html += "<div class='dim' style='margin-top:10px; text-align:center;'>学而时习之，不亦说乎</div>"
	return html.Join()
