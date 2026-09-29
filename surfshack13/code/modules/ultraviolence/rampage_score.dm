/// Every chicken mask rampage this round, shown in the round end report.
GLOBAL_LIST_EMPTY(rampage_records)

/**
 * One chicken mask wearer's rampage for the round: their score and stats.
 * Outlives the mask and the body so it can be shown at round end.
 */
/datum/rampage_record
	/// Mind of the wearer, for the round end player line.
	var/datum/mind/mind
	/// Name at the time they put the mask on, in case the mind is gone by round end.
	var/name
	/// ckey of the wearer.
	var/key
	/// Total points.
	var/score = 0
	/// Kills, not counting executions.
	var/kills = 0
	/// Executions finished.
	var/executions = 0
	/// Highest combo reached.
	var/best_combo = 0
	/// Doors kicked off their hinges.
	var/doors_kicked = 0

	/// Body of the wearer, so the same person keeps one record even if their mind gets swapped out.
	var/datum/weakref/body

/datum/rampage_record/New(mob/living/wearer)
	mind = wearer.mind
	body = WEAKREF(wearer)
	name = wearer.real_name
	key = wearer.ckey || wearer.mind?.key
	GLOB.rampage_records += src

/// Finds the record for this wearer (matching their mind or their body), or starts a new one.
/proc/get_rampage_record(mob/living/wearer)
	for(var/datum/rampage_record/record as anything in GLOB.rampage_records)
		if((wearer.mind && record.mind == wearer.mind) || record.body?.resolve() == wearer)
			// Keep it pointing at whoever they are now.
			if(wearer.mind)
				record.mind = wearer.mind
			record.body = WEAKREF(wearer)
			return record
	return new /datum/rampage_record(wearer)

/// Letter grade for a score, Hotline style.
/datum/rampage_record/proc/get_grade()
	switch(score)
		if(100000 to INFINITY)
			return "S+"
		if(40000 to 100000)
			return "S"
		if(15000 to 40000)
			return "A"
		if(5000 to 15000)
			return "B"
		if(1000 to 5000)
			return "C"
		if(1 to 1000)
			return "D"
	return "F"

/// Round end report card for every chicken mask rampage, best score first. Empty if nobody wore the mask.
/datum/controller/subsystem/ticker/proc/rampage_report()
	if(!length(GLOB.rampage_records))
		return
	var/list/records = sortTim(GLOB.rampage_records.Copy(), GLOBAL_PROC_REF(cmp_rampage_records))
	var/list/parts = list()
	parts += "<div class='panel redborder' style='background-color:#1a0710;'>"
	parts += "<span class='header' style='color:#ff1c96; font-style:italic; letter-spacing:2px;'>THE RAMPAGE</span><br>"
	for(var/datum/rampage_record/record as anything in records)
		var/grade = record.get_grade()
		var/grade_color = (grade in list("S+", "S", "A")) ? "#ffd21c" : "#ff1c96"
		var/who = record.mind ? printplayer(record.mind) : "<b>[record.name]</b> ([record.key])"
		parts += "<div style='margin:8px 0; padding:6px 10px; border-left:4px solid #ff1c96;'>"
		parts += "[who]<br>"
		parts += "<span style='font-size:22px; font-weight:bold; font-style:italic; color:#ff1c96; text-shadow:-2px 2px 0 #54020f;'>[record.score] PTS</span>"
		parts += " <span style='font-size:22px; font-weight:bold; color:[grade_color]; text-shadow:-2px 2px 0 #54020f;'>[grade]</span><br>"
		parts += "<span style='color:#ffb3d9;'>Kills: <b>[record.kills]</b> &nbsp;|&nbsp; Executions: <b>[record.executions]</b> &nbsp;|&nbsp; Best combo: <b>[record.best_combo]X</b> &nbsp;|&nbsp; Doors kicked: <b>[record.doors_kicked]</b></span>"
		parts += "</div>"
	parts += "</div>"
	return parts.Join()

/proc/cmp_rampage_records(datum/rampage_record/a, datum/rampage_record/b)
	return b.score - a.score
