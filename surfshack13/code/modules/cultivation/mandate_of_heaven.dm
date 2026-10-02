/**
 * # Mandate of Heaven
 *
 * Heads of staff rule their departments with heaven's blessing; the Captain is the Son of Heaven and rules the whole station.
 * Holders get a golden aura, an Imperial Decree that rallies their people, and faster cultivation if they cultivate.
 *
 * Heaven withdraws the Mandate when a ruler dies, is demoted or is kept in chains. A jade seal falls where they stood,
 * an omen announces it, and whoever raises the seal to heaven claims the Mandate for themselves.
 */

/// How long someone can stay restrained before heaven decides they've lost their throne
#define MANDATE_RESTRAINT_LIMIT (3 MINUTES)
/// How long an ID can show the wrong job before heaven notices the demotion
#define MANDATE_DEMOTION_LIMIT (1 MINUTES)

GLOBAL_DATUM_INIT(mandate_controller, /datum/mandate_controller, new)

/// Hands the Mandate to heads of staff when they spawn
/datum/mandate_controller

/datum/mandate_controller/proc/register()
	RegisterSignal(SSdcs, COMSIG_GLOB_JOB_AFTER_SPAWN, PROC_REF(on_job_spawn))

/datum/mandate_controller/proc/on_job_spawn(datum/source, datum/job/job, mob/living/spawned, client/player_client)
	SIGNAL_HANDLER
	if(!ishuman(spawned) || !(job.job_flags & JOB_HEAD_OF_STAFF))
		return
	if(istype(job, /datum/job/captain))
		spawned.AddComponent(/datum/component/mandate_of_heaven, "the Station", null, TRUE, job.title)
		return
	var/datum/job_department/domain
	for(var/department_type in job.departments_list)
		if(department_type == /datum/job_department/command)
			continue
		domain = SSjob.get_department_type(department_type)
		break
	spawned.AddComponent(/datum/component/mandate_of_heaven, domain?.department_name || job.title, domain?.type, FALSE, job.title)

/datum/component/mandate_of_heaven
	/// Name of what we rule
	var/domain_name
	/// Department type we rule, null for the Son of Heaven (rules everyone)
	var/domain_type
	/// Captain's mandate over the whole station
	var/son_of_heaven = FALSE
	/// Job title the mandate was granted with, null if it was seized
	var/granted_title
	/// Time spent restrained
	var/restrained_time = 0
	/// Time spent with an ID that no longer shows our title
	var/demoted_time = 0
	/// Our decree action
	var/datum/action/cooldown/mandate_decree/decree

/datum/component/mandate_of_heaven/Initialize(domain_name, domain_type, son_of_heaven = FALSE, granted_title)
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	src.domain_name = domain_name
	src.domain_type = domain_type
	src.son_of_heaven = son_of_heaven
	src.granted_title = granted_title

/datum/component/mandate_of_heaven/RegisterWithParent()
	var/mob/living/carbon/human/ruler = parent
	RegisterSignal(ruler, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(ruler, COMSIG_LIVING_DEATH, PROC_REF(on_death))
	RegisterSignal(ruler, COMSIG_LIVING_LIFE, PROC_REF(on_life))
	ruler.add_filter("mandate_of_heaven", 3, list("type" = "outline", "color" = "#ffd55a", "size" = 1, "alpha" = son_of_heaven ? 110 : 60))
	decree = new(src)
	decree.Grant(ruler)
	to_chat(ruler, span_boldnotice("You hold the Mandate of Heaven over [domain_name]. Rule justly: if you die, are demoted, or are kept in chains, heaven will withdraw it, \
		and a jade seal will fall for others to claim."))

/datum/component/mandate_of_heaven/UnregisterFromParent()
	var/mob/living/carbon/human/ruler = parent
	UnregisterSignal(ruler, list(COMSIG_ATOM_EXAMINE, COMSIG_LIVING_DEATH, COMSIG_LIVING_LIFE))
	ruler.remove_filter("mandate_of_heaven")
	QDEL_NULL(decree)

/datum/component/mandate_of_heaven/proc/title_of()
	return son_of_heaven ? "Son of Heaven" : "Mandated Lord of [domain_name]"

/datum/component/mandate_of_heaven/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	var/mob/living/carbon/human/ruler = parent
	examine_list += span_notice("<font color='#d4a017'><b>[ruler.p_They()] bear[ruler.p_s()] the Mandate of Heaven as [title_of()].</b></font>[granted_title ? "" : " Heaven granted it when [ruler.p_they()] seized the seal."]")

/datum/component/mandate_of_heaven/proc/on_death(datum/source)
	SIGNAL_HANDLER
	withdraw("has died")

/datum/component/mandate_of_heaven/proc/on_life(datum/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER
	var/mob/living/carbon/human/ruler = parent
	// Kept in chains
	if(HAS_TRAIT(ruler, TRAIT_RESTRAINED))
		restrained_time += seconds_per_tick SECONDS
		if(restrained_time >= MANDATE_RESTRAINT_LIMIT)
			withdraw("has been kept in chains")
			return
	else
		restrained_time = max(restrained_time - seconds_per_tick SECONDS, 0)
	// Demoted (only for mandates granted by a job, seized ones don't care about paperwork)
	if(granted_title)
		var/obj/item/card/id/id_card = ruler.get_idcard(hand_first = FALSE)
		if(id_card && id_card.assignment != granted_title)
			demoted_time += seconds_per_tick SECONDS
			if(demoted_time >= MANDATE_DEMOTION_LIMIT)
				withdraw("has been stripped of [ruler.p_their()] rank")
				return
		else
			demoted_time = 0

/// Heaven withdraws its favour. Drops a seal and announces an omen.
/datum/component/mandate_of_heaven/proc/withdraw(reason)
	var/mob/living/carbon/human/ruler = parent
	var/turf/fall_turf = get_turf(ruler)
	var/obj/item/jade_seal/seal = new(fall_turf)
	seal.set_domain(domain_name, domain_type, son_of_heaven)
	to_chat(ruler, span_userdanger("Heaven withdraws its Mandate from you!"))
	if(son_of_heaven)
		priority_announce("The heavens darken and thunder rolls across the station. The Mandate of Heaven has been withdrawn from [ruler.real_name], who [reason]. \
			The Heirloom Seal of the Realm lies where they fell. Whoever raises it to heaven shall rule.", "Omen of Heaven", 'sound/effects/magic/lightningbolt.ogg')
		cultivation_omen_flicker(get_turf(ruler), 60)
	else
		minor_announce("An ill omen: heaven withdraws its Mandate over [domain_name] from [ruler.real_name], who [reason]. A jade seal lies where they fell.", "Omen of Heaven")
		cultivation_omen_flicker(fall_turf, 12)
	ruler.log_message("lost the Mandate of Heaven over [domain_name] ([reason])", LOG_GAME)
	qdel(src)

/// Lights flicker across the station (or near a spot) when heaven is displeased
/proc/cultivation_omen_flicker(turf/center, amount)
	var/list/lights = list()
	for(var/obj/machinery/light/light as anything in SSmachines.get_machines_by_type_and_subtypes(/obj/machinery/light))
		if(light.z == center?.z)
			lights += light
	for(var/i in 1 to min(amount, length(lights)))
		var/obj/machinery/light/light = pick_n_take(lights)
		INVOKE_ASYNC(light, TYPE_PROC_REF(/obj/machinery/light, flicker), rand(3, 8))

// ----- The seal -----

/obj/item/jade_seal
	name = "jade seal"
	desc = "A heavy seal of green jade topped with a coiled dragon. The characters on its face read: \"Having received the Mandate from Heaven, may the reign be long and prosperous.\""
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'
	icon_state = "jade_seal"
	w_class = WEIGHT_CLASS_SMALL
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	light_range = 2
	light_color = "#ffd55a"
	var/domain_name = "the Station"
	var/domain_type
	var/son_of_heaven = FALSE

/obj/item/jade_seal/proc/set_domain(domain_name, domain_type, son_of_heaven)
	src.domain_name = domain_name
	src.domain_type = domain_type
	src.son_of_heaven = son_of_heaven
	if(son_of_heaven)
		name = "Heirloom Seal of the Realm"
	else
		name = "jade seal of [domain_name]"

/obj/item/jade_seal/examine(mob/user)
	. = ..()
	. += span_notice("Use it in hand to raise it to heaven and claim the Mandate over [domain_name].")

/obj/item/jade_seal/attack_self(mob/living/carbon/human/user)
	if(!ishuman(user))
		return
	if(user.GetComponent(/datum/component/mandate_of_heaven))
		to_chat(user, span_warning("You already bear a Mandate. Heaven does not grant two."))
		return
	if(tgui_alert(user, "Raise the seal to heaven and claim the Mandate over [domain_name]?", "Mandate of Heaven", list("Claim it", "Not yet")) != "Claim it")
		return
	user.visible_message(span_boldwarning("[user] raises [src] towards the heavens!"), span_boldnotice("You raise the seal towards the heavens..."))
	cultivation_temple_sound(user, 60)
	if(!do_after(user, 8 SECONDS, src))
		return
	if(QDELETED(src) || user.GetComponent(/datum/component/mandate_of_heaven))
		return
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(get_turf(user))
	new /obj/effect/temp_visual/cultivation_ascension_pillar(get_turf(user))
	if(son_of_heaven)
		priority_announce("A new dynasty! [user.real_name] has raised the Heirloom Seal of the Realm and claimed the Mandate of Heaven.", "Omen of Heaven", 'sound/effects/gong.ogg')
	else
		minor_announce("[user.real_name] has claimed the Mandate of Heaven over [domain_name].", "Omen of Heaven")
	user.AddComponent(/datum/component/mandate_of_heaven, domain_name, domain_type, son_of_heaven, null)
	user.log_message("claimed the Mandate of Heaven over [domain_name]", LOG_GAME)
	qdel(src)

// ----- Imperial Decree -----

/datum/action/cooldown/mandate_decree
	name = "Imperial Decree"
	desc = "Proclaim a decree with heaven's authority. Your people nearby are rallied: faster, steadier and in better spirits. \
		The Son of Heaven's decrees reach the whole station."
	button_icon = 'surfshack13/icons/cultivation/cultivation_actions.dmi'
	button_icon_state = "imperial_decree"
	background_icon_state = "bg_heretic"
	overlay_icon_state = "bg_heretic_border"
	check_flags = AB_CHECK_CONSCIOUS
	cooldown_time = 90 SECONDS

/datum/action/cooldown/mandate_decree/Activate(atom/target)
	var/datum/component/mandate_of_heaven/mandate = src.target
	var/mob/living/carbon/human/ruler = owner
	var/decree_text = tgui_input_text(ruler, "What is your decree?", "Imperial Decree", max_length = 200)
	if(!decree_text || QDELETED(src) || !IsAvailable())
		return FALSE
	decree_text = trim(decree_text)
	ruler.log_talk(decree_text, LOG_SAY, tag = "imperial decree")
	playsound(ruler, 'sound/effects/gong.ogg', 70, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(get_turf(ruler))
	var/title = mandate.title_of()
	var/formatted = "<span style='color:#d4a017; font-size:140%;'><b>Imperial Decree of [ruler.real_name], [title]:</b></span> <span style='color:#d4a017;'>[html_encode(decree_text)]</span>"
	if(mandate.son_of_heaven)
		priority_announce(html_encode(decree_text), "Imperial Decree of the Son of Heaven", 'sound/effects/gong.ogg', sender_override = ruler.real_name)
	else
		for(var/mob/listener in hearers(9, ruler))
			to_chat(listener, formatted)
	for(var/mob/living/carbon/human/subject in view(9, ruler))
		if(subject.stat != CONSCIOUS)
			continue
		if(subject != ruler && mandate.domain_type && !(mandate.domain_type in subject.mind?.assigned_role?.departments_list))
			continue
		subject.apply_status_effect(/datum/status_effect/rallied_by_decree)
	StartCooldown()
	return TRUE

/datum/status_effect/rallied_by_decree
	id = "rallied_by_decree"
	alert_type = null
	duration = 20 SECONDS

/datum/status_effect/rallied_by_decree/on_apply()
	owner.add_movespeed_modifier(/datum/movespeed_modifier/status_effect/rallied_by_decree)
	owner.adjustStaminaLoss(-30)
	owner.add_mood_event("rallied_by_decree", /datum/mood_event/rallied_by_decree)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold(get_turf(owner))
	return TRUE

/datum/status_effect/rallied_by_decree/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/status_effect/rallied_by_decree)

/datum/movespeed_modifier/status_effect/rallied_by_decree
	multiplicative_slowdown = -0.25

/datum/mood_event/rallied_by_decree
	description = "Heaven's chosen has spoken. I am inspired!"
	mood_change = 4
	timeout = 5 MINUTES

#undef MANDATE_RESTRAINT_LIMIT
#undef MANDATE_DEMOTION_LIMIT
