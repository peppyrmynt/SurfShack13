//Chaplain's Null Rod Holopara
/mob/living/basic/guardian/chaplain
	speed = 0
	guardian_type = GUARDIAN_HOLY
	icon_state = "holybase"
	creator_name = ""
	damage_coeff = list(BRUTE = 0.9, BURN = 0.9, TOX = 0.9, STAMINA = 0.0, OXY = 0.9)
	obj_damage = 12
	melee_damage_lower = 12
	melee_damage_upper = 12
	playstyle_string = span_holoparasite("As a <b>Holyparasite</b>, you may right-click to heal targets. Healing targets consumes faith")
	range = 8
	var/healing_amount = 5
	var/max_heal_pool = 25
	var/heal_pool = 25
	var/heal_regen_amount = 0.1
	var/chaplain_focus = TRUE

/mob/living/basic/guardian/chaplain/Initialize()
	. = ..()
	AddComponent(\
		/datum/component/healing_touch,\
		heal_brute = healing_amount,\
		heal_burn = healing_amount,\
		heal_tox = healing_amount,\
		heal_oxy = healing_amount,\
		heal_time = 0,\
		action_text = "",\
		complete_text = "",\
		required_modifier = RIGHT_CLICK,\
		after_healed = CALLBACK(src, PROC_REF(after_healed)),\
	)
	var/datum/atom_hud/medsensor = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
	medsensor.show_to(src)
	ADD_TRAIT(src, TRAIT_HOLY, SPECIES_TRAIT)
	RegisterSignal(src, COMSIG_LIVING_LIFE, PROC_REF(on_life))


/// Called after we heal someone, show some visuals
/mob/living/basic/guardian/chaplain/proc/after_healed(mob/living/healed)
	if(heal_pool >= healing_amount)
		heal_pool = heal_pool-5
	else
		qdel(GetComponent(/datum/component/healing_touch))
		return
	do_attack_animation(healed, ATTACK_EFFECT_PUNCH)
	healed.visible_message(
		message = span_notice("[src] heals [healed]!"),
		self_message = span_userdanger("[src] heals you!"),
		vision_distance = COMBAT_MESSAGE_RANGE,
		ignored_mobs = src,
	)
	to_chat(src, span_notice("You heal [healed]!"))
	playsound(healed, attack_sound, 50, TRUE, TRUE, frequency = -1) // play punch sound in REVERSE


/mob/living/basic/guardian/chaplain/proc/lockdown_para(mob/living/source)
	to_chat(src, span_holoparasite("Your summoner has lost focus, you will no longer be able to manifest untill focus is regained"))
	chaplain_focus = FALSE
	if(src.buckled == null)
		playsound(src, 'sound/effects/glass/glassbr3.ogg', 80, TRUE)
		recall()

/mob/living/basic/guardian/chaplain/set_summoner(mob/living/to_who, different_person = FALSE)
	. = ..()
	RegisterSignal(to_who, COMSIG_LIVING_ENTER_STAMCRIT, PROC_REF(lockdown_para))
	RegisterSignal(to_who, COMSIG_LIVING_STATUS_UNCONSCIOUS, PROC_REF(lockdown_para))
	RegisterSignal(to_who, COMSIG_LIVING_STATUS_PARALYZE, PROC_REF(lockdown_para))

/mob/living/basic/guardian/chaplain/manifest(forced)
	chaplain_focus = check_focus()
	if(chaplain_focus == FALSE)
		to_chat(src, span_holoparasite("Your summoner has no focus"))
		return
	. = ..()

/mob/living/basic/guardian/chaplain/proc/check_focus()
	if(summoner.staminaloss < summoner.crit_threshold)
		return FALSE
	if(summoner.IsUnconscious())
		return FALSE
	if(summoner.IsParalyzed())
		return FALSE
	if(istype(summoner,/mob/living/carbon))
		var/mob/living/carbon/carbon_summoner = summoner
		if(carbon_summoner.handcuffed)
			return FALSE
	return TRUE

/mob/living/basic/guardian/chaplain/set_guardian_colour(colour)
	guardian_colour = colour
	set_light_color(COLOR_YELLOW)

/mob/living/basic/guardian/chaplain/get_status_tab_items()
	. = ..()
	. += "Current faith: [heal_pool >= max_heal_pool ? heal_pool : "[heal_pool] / [max_heal_pool]"]"

/mob/living/basic/guardian/chaplain/proc/on_life(seconds_per_tick = SSMOBS_DT, times_fired)
	SIGNAL_HANDLER
	if(heal_pool < max_heal_pool)
		var/change_in_time = DELTA_WORLD_TIME(SSmobs)
		heal_pool = min(heal_pool + (heal_regen_amount * change_in_time), max_heal_pool)
	if(heal_pool >= healing_amount && GetComponent(/datum/component/healing_touch) == null)
		AddComponent(\
			/datum/component/healing_touch,\
			heal_brute = healing_amount,\
			heal_burn = healing_amount,\
			heal_tox = healing_amount,\
			heal_oxy = healing_amount,\
			heal_time = 0,\
			action_text = "",\
			complete_text = "",\
			required_modifier = RIGHT_CLICK,\
			after_healed = CALLBACK(src, PROC_REF(after_healed)),\
		)
