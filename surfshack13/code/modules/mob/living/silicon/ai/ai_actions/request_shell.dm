/datum/action/innate/ai/request_shell
	name = "Request Remote Shell"
	desc = "Request a Cyborg Shell to be sent directly to your location straight from CentCom."
	button_icon = 'icons/mob/silicon/robots.dmi'
	button_icon_state = "robot"
	uses = 1

/datum/action/innate/ai/request_shell/Activate()
	to_chat(owner, span_notice("Request received: Operable shell incoming."))
	podspawn(list(
		"target" = get_turf(owner),
		"style" = /datum/pod_style/centcom,
		"spawn" = /mob/living/silicon/robot/shell/with_cell,
	))
