/proc/ip2country(ipaddr, client/origin)
	if(!origin || origin?.country_flag)
		return //null source, or already has a flag

	var/list/http_response[] = world.Export("http://ip-api.com/json/[ipaddr]")
	if(http_response) //check for a response
		var/page_content = http_response["CONTENT"]
		if(page_content)
			var/list/geodata = json_decode(html_decode(file2text(page_content)))
			if(geodata["countryCode"] == "GB" && ((geodata["regionName"] == "Scotland") || (geodata["regionName"] == "Wales")))
				origin?.country_flag = geodata["regionName"]
			else if(geodata["countryCode"] == "CA" && (geodata["regionName"] == "Quebec"))
				origin?.country_flag = geodata["regionName"]
			else
				origin?.country_flag = geodata["countryCode"]
			return geodata["countryCode"]
	else //null response, ratelimited most likely. Try again in 60s
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(ip2country), ipaddr, origin), 60 SECONDS)

/proc/country2chat_flag(country)
	var/datum/asset/spritesheet/sheet = get_asset_datum(/datum/asset/spritesheet/chat)
	. = sheet.icon_tag("flag-[country]")
	if(!.)
		. = sheet.icon_tag("flag-unknown")
