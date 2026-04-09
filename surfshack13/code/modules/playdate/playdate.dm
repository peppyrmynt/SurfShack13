GLOBAL_VAR(playdate_time)

// https://www.byond.com/forum/post/2986517 I hope and pray
/world/proc/add_playdate()
	var/date = GLOB.playdate_time
	if(!date)
		return
	var/year = text2num(copytext(date, 1, 5))
	var/month = text2num(copytext(date, 6, 8))
	var/day = text2num(copytext(date, 9, 11))
	var/weekday = iso_to_weekday(day_of_month(year, month, day))

	var/hour = text2num(copytext(date, 12, 14))
	var/min = copytext(date, 15, 17)
	var/day_half = "AM"
	if((hour / 12) >= 1)
		day_half = "PM"
		if((hour/12) > 1)
			hour -= 12

	return  "<br>Scheduled playtime on <b>[weekday]. [month]/[day] at [hour]:[min] [day_half] UTC</b> - \
	<a href='https://forgman6.github.io/?isoString=[date]'>View In Localtime</a>"



ADMIN_VERB(schedule_playtime, R_FUN, "Schedule Playtime", "Schedule the playtime to display on byond hub", ADMIN_CATEGORY_SERVER)
	. = TRUE
	RegisterSignal(src, COMSIG_TOPIC, PROC_REF(on_topic))
	SSfrogui.open_ui(user.mob, src, file2text('surfshack13/frogui/datepicker.html'))

/datum/admin_verb/schedule_playtime/proc/on_topic(datum/source, usr, list/href_list)
	SIGNAL_HANDLER
	if(href_list["datetime"])
		GLOB.playdate_time = href_list["datetime"]
		world.update_status()
		UnregisterSignal(src, COMSIG_TOPIC)
		SSfrogui.close_ui(usr, src)
