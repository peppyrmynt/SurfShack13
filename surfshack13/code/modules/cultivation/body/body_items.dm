/**
 * Body Molding Art manuals. The primer starts anyone (a mortal) on Copper Skin training; the full art commits you to the path.
 * Qi cultivators can read neither: their meridians are already full of qi.
 */
/obj/item/book/granter/body_manual
	name = "Copper Skin Primer"
	desc = "A grubby, much-thumbed pamphlet of stances, breathing drills and alarming advice about hitting yourself with sticks. Anyone can follow it."
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'
	icon_state = "manual_body_primer"
	remarks = list(
		"Horse stance. Hold it until your legs forget they are legs...",
		"Strike the forearm with a bundle of chopsticks, then a broom handle, then an iron bar...",
		"Eat. Then eat more. Flesh is forged from rice...",
		"Skin like copper, bones like iron, sinew like steel. Start with the skin.",
	)
	pages_to_mastery = 2
	reading_time = 3 SECONDS
	uses = 3
	/// Does reading this commit you to the full path
	var/commits = FALSE

/obj/item/book/granter/body_manual/can_learn(mob/living/user)
	if(!ishuman(user) || !user.mind)
		to_chat(user, span_warning("You can't follow these stances."))
		return FALSE
	if(IS_CULTIVATOR(user))
		to_chat(user, span_warning("Your meridians are already full of qi. The path of the flesh is closed to you."))
		return FALSE
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(user)
	if(body_datum && (body_datum.committed || !commits))
		to_chat(user, span_warning("You already know everything this book can teach you."))
		return FALSE
	return TRUE

/obj/item/book/granter/body_manual/on_reading_finished(mob/living/user)
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(user) || user.mind.add_antag_datum(/datum/antagonist/body_cultivator)
	if(commits)
		body_datum.commit()

/obj/item/book/granter/body_manual/recoil(mob/living/user)
	to_chat(user, span_warning("The pages have been sweated into illegibility."))

/obj/item/book/granter/body_manual/molding_art
	name = "Body Molding Art"
	desc = "A heavy book bound between two bronze plates. Its diagrams show a body being broken down and rebuilt nine times, each time into something harder. \
		Committing to it means never cultivating qi."
	icon_state = "manual_body"
	remarks = list(
		"The first body is born of parents. The other nine are forged...",
		"Iron bone is not the end. Iron bone is where it begins to hurt properly...",
		"Mold the flesh like clay, then fire it like a kiln...",
		"A golden body does not fear the blade. It fears only boredom.",
		"At the end, the flesh remembers the chaos before heaven and earth...",
	)
	pages_to_mastery = 4
	reading_time = 4 SECONDS
	uses = 2
	commits = TRUE

/obj/item/book/granter/body_manual/molding_art/on_reading_finished(mob/living/user)
	if(tgui_alert(user, "Commit to the Body Molding Art? You will never be able to cultivate qi.", "Body Molding Art", list("Commit", "Not yet")) != "Commit")
		return
	return ..()

/// Body Tempering Pills mean something to body cultivators: a burst of tempering and a steadier Tribulation of Flesh
/datum/status_effect/cultivation_pill_buff/body_tempering
	id = "body_tempering_pill"
