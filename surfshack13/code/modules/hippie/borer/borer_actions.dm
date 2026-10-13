// Cortical Borer abilities. Every action is created with the borer as its target,
// so actions granted to the host still know which borer they belong to.

/datum/action/cooldown/borer
	background_icon_state = "bg_alien"
	overlay_icon_state = "bg_alien_border"
	button_icon = 'icons/mob/actions/actions_xeno.dmi'
	button_icon_state = "alien_whisper"
	check_flags = NONE

/datum/action/cooldown/borer/proc/get_borer()
	var/mob/living/basic/cortical_borer/borer = target
	return istype(borer) && !QDELETED(borer) ? borer : null

// ---- Outside a host ----

/datum/action/cooldown/borer/infest
	name = "Infest"
	desc = "Infest a suitable humanoid host by crawling into their ear."
	button_icon_state = "alien_transfer"

/datum/action/cooldown/borer/infest/Activate(atom/unused)
	var/mob/living/basic/cortical_borer/borer = get_borer()
	if(!borer?.can_use_ability(needs_host = FALSE, needs_awake = FALSE))
		return FALSE
	var/list/choices = list()
	for(var/mob/living/carbon/human/candidate in view(1, borer))
		if(borer.Adjacent(candidate))
			choices += candidate
	if(!length(choices))
		to_chat(borer, span_warning("There is nobody close enough to infest."))
		return FALSE
	var/mob/living/carbon/human/victim = length(choices) > 1 ? tgui_input_list(borer, "Who do you wish to infest?", "Infest", choices) : choices[1]
	if(!victim || !borer.Adjacent(victim) || borer.host || borer.stat != CONSCIOUS)
		return FALSE
	if(victim.get_cortical_borer())
		to_chat(borer, span_warning("[victim] is already infested!"))
		return FALSE
	if(!victim.key || !victim.mind)
		to_chat(borer, span_warning("[victim]'s mind seems unresponsive. Try someone else!"))
		return FALSE
	if(istype(victim.dna?.species, /datum/species/skeleton))
		to_chat(borer, span_warning("[victim] does not possess the vital systems needed to support us."))
		return FALSE
	to_chat(borer, span_warning("You slither up [victim] and begin probing at [victim.p_their()] ear canal..."))
	if(!do_after(borer, 3 SECONDS, victim))
		to_chat(borer, span_warning("As [victim] moves away, you are dislodged and fall to the ground."))
		return FALSE
	if(borer.host || victim.get_cortical_borer())
		return FALSE
	borer.infest(victim)
	return TRUE

/datum/action/cooldown/borer/toggle_hide
	name = "Toggle Hide"
	desc = "Scurry low to the ground so you are harder to spot."
	button_icon_state = "alien_hide"

/datum/action/cooldown/borer/toggle_hide/Activate(atom/unused)
	var/mob/living/basic/cortical_borer/borer = get_borer()
	if(!borer?.can_use_ability(needs_host = FALSE, needs_awake = FALSE))
		return FALSE
	borer.hiding = !borer.hiding
	if(borer.hiding)
		borer.layer = ABOVE_NORMAL_TURF_LAYER
		borer.visible_message(span_name("[borer] scurries to the ground!"), span_noticealien("You are now hiding."))
	else
		borer.layer = initial(borer.layer)
		borer.visible_message("[borer] slowly peeks up from the ground...", span_noticealien("You stop hiding."))
	button_icon_state = borer.hiding ? "alien_sneak_on" : "alien_hide"
	build_all_button_icons(UPDATE_BUTTON_ICON)
	return TRUE

/datum/action/cooldown/borer/paralyze
	name = "Paralyze Victim"
	desc = "Freeze the limbs of a potential host with supernatural fear."
	button_icon = 'icons/mob/actions/actions_changeling.dmi'
	button_icon_state = "sting_cryo"
	cooldown_time = 15 SECONDS

/datum/action/cooldown/borer/paralyze/Activate(atom/unused)
	var/mob/living/basic/cortical_borer/borer = get_borer()
	if(!borer?.can_use_ability(needs_host = FALSE, needs_awake = FALSE))
		return FALSE
	var/list/choices = list()
	for(var/mob/living/carbon/candidate in view(1, borer))
		if(candidate.stat == CONSCIOUS && borer.Adjacent(candidate))
			choices += candidate
	if(!length(choices))
		return FALSE
	var/mob/living/carbon/victim = length(choices) > 1 ? tgui_input_list(borer, "Who do you wish to dominate?", "Paralyze", choices) : choices[1]
	if(!victim || !borer.Adjacent(victim) || borer.host || borer.stat != CONSCIOUS)
		return FALSE
	if(victim.get_cortical_borer())
		to_chat(borer, span_warning("You cannot stun someone who is already infested!"))
		return FALSE
	borer.layer = initial(borer.layer)
	borer.hiding = FALSE
	to_chat(borer, span_warning("You focus your psychic lance on [victim] and freeze [victim.p_their()] limbs with a wave of terrible dread."))
	to_chat(victim, span_userdanger("You feel a creeping, horrible sense of dread come over you, freezing your limbs and setting your heart racing."))
	victim.Stun(6 SECONDS)
	log_combat(borer, victim, "paralyzed")
	StartCooldown()
	return TRUE

// ---- Inside a host ----

/datum/action/cooldown/borer/talk_to_host
	name = "Converse with Host"
	desc = "Send a silent message to your host. You can also just speak normally while inside them."

/datum/action/cooldown/borer/talk_to_host/Activate(atom/unused)
	var/mob/living/basic/cortical_borer/borer = get_borer()
	if(!borer?.can_use_ability(needs_awake = FALSE))
		return FALSE
	var/message = tgui_input_text(borer, "Please enter a message to tell your host.", "Borer", max_length = MAX_MESSAGE_LEN)
	if(message)
		borer.talk_to_host(message)
	return TRUE

/datum/action/cooldown/borer/leave_host
	name = "Release Host"
	desc = "Slither out of your host. Takes 10 seconds; use again to cancel."
	button_icon_state = "alien_barf"

/datum/action/cooldown/borer/leave_host/Activate(atom/unused)
	var/mob/living/basic/cortical_borer/borer = get_borer()
	if(!borer?.can_use_ability(needs_awake = FALSE))
		return FALSE
	if(borer.leaving)
		borer.leaving = FALSE
		to_chat(borer, span_userdanger("You decide against leaving your host."))
		return TRUE
	to_chat(borer, span_userdanger("You begin disconnecting from [borer.host]'s synapses and prodding at [borer.host.p_their()] internal ear canal."))
	if(borer.host.stat != DEAD)
		to_chat(borer.host, span_userdanger("An odd, uncomfortable pressure begins to build inside your skull, behind your ear..."))
	borer.leaving = TRUE
	addtimer(CALLBACK(src, PROC_REF(finish_leaving), borer), 10 SECONDS)
	return TRUE

/datum/action/cooldown/borer/leave_host/proc/finish_leaving(mob/living/basic/cortical_borer/borer)
	if(QDELETED(borer) || !borer.host || !borer.leaving || borer.controlling || borer.stat != CONSCIOUS)
		return
	var/mob/living/carbon/human/old_host = borer.host
	to_chat(borer, span_userdanger("You wiggle out of [old_host]'s ear and plop to the ground."))
	if(old_host.mind)
		to_chat(old_host, span_danger("Something slimy wiggles out of your ear and plops to the ground!"))
		to_chat(old_host, span_danger("As though waking from a dream, you shake off the insidious mind control of the brain worm. Your thoughts are your own again."))
	borer.leave_host()

/datum/action/cooldown/borer/assume_control
	name = "Assume Control"
	desc = "Fully connect to the brain of your host. Takes about 20 seconds, longer if their brain is damaged."
	button_icon = 'icons/mob/actions/actions_changeling.dmi'
	button_icon_state = "hive_head"

/datum/action/cooldown/borer/assume_control/Activate(atom/unused)
	var/mob/living/basic/cortical_borer/borer = get_borer()
	if(!borer?.can_use_ability())
		return FALSE
	if(borer.host.stat == DEAD)
		to_chat(borer, span_warning("This host lacks enough brain function to control."))
		return FALSE
	if(borer.bonding)
		borer.bonding = FALSE
		to_chat(borer, span_userdanger("You stop attempting to take control of your host."))
		return TRUE
	to_chat(borer, span_danger("You begin delicately adjusting your connection to the host brain..."))
	borer.bonding = TRUE
	var/delay = 20 SECONDS + borer.host.get_organ_loss(ORGAN_SLOT_BRAIN) * 0.5 SECONDS
	addtimer(CALLBACK(borer, TYPE_PROC_REF(/mob/living/basic/cortical_borer, assume_control)), delay)
	return TRUE

/datum/action/cooldown/borer/punish
	name = "Punish"
	desc = "Punish your host with blindness, deafness or a collapse. Costs 75 chemicals."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "blind"

/datum/action/cooldown/borer/punish/Activate(atom/unused)
	var/mob/living/basic/cortical_borer/borer = get_borer()
	if(!borer?.can_use_ability(chem_cost = 75))
		return FALSE
	var/punishment = tgui_input_list(borer, "Select a punishment", "Punish", list("Blindness", "Deafness", "Stun"))
	if(!punishment || !borer.can_use_ability(chem_cost = 75))
		return FALSE
	var/mob/living/carbon/human/victim = borer.host
	switch(punishment)
		if("Blindness")
			victim.adjust_temp_blindness(4 SECONDS)
		if("Deafness")
			var/obj/item/organ/ears/ears = victim.get_organ_slot(ORGAN_SLOT_EARS)
			ears?.adjustEarDamage(0, 40)
		if("Stun")
			victim.Knockdown(20 SECONDS)
	borer.chemicals -= 75
	log_combat(borer, victim, "punished", addition = punishment)
	return TRUE

/datum/action/cooldown/borer/secrete_chemicals
	name = "Secrete Chemicals"
	desc = "Push some chemicals into your host's bloodstream."
	button_icon = 'icons/obj/medical/chemical.dmi'
	button_icon_state = "minidispenser"

/datum/action/cooldown/borer/secrete_chemicals/Activate(atom/unused)
	var/mob/living/basic/cortical_borer/borer = get_borer()
	if(!borer?.can_use_ability(needs_awake = FALSE))
		return FALSE
	borer.ui_interact(borer)
	return TRUE

/datum/action/cooldown/borer/jumpstart
	name = "Jumpstart Host"
	desc = "Bring your dead host back to life. Costs 250 chemicals."
	button_icon = 'surfshack13/icons/hippie/cortical_borer.dmi'
	button_icon_state = "jumpstart"

/datum/action/cooldown/borer/jumpstart/Activate(atom/unused)
	var/mob/living/basic/cortical_borer/borer = get_borer()
	if(!borer?.can_use_ability(chem_cost = 250))
		return FALSE
	var/mob/living/carbon/human/victim = borer.host
	if(victim.stat != DEAD)
		to_chat(borer, span_warning("Your host is already alive!"))
		return FALSE
	victim.revive(HEAL_DAMAGE | HEAL_BLOOD | HEAL_ORGANS | HEAL_WOUNDS | HEAL_ALL_REAGENTS | HEAL_TEMP | HEAL_CC_STATUS)
	victim.grab_ghost(force = TRUE)
	borer.chemicals -= 250
	to_chat(borer, span_notice("You send a jolt of energy to your host, reviving them!"))
	to_chat(victim, span_notice("You bolt upright, gasping for breath!"))
	log_combat(borer, victim, "revived")
	return TRUE

// ---- Given to the host ----

/datum/action/cooldown/borer/talk_to_borer
	name = "Converse with Borer"
	desc = "Communicate mentally with the creature in your head."

/datum/action/cooldown/borer/talk_to_borer/Activate(atom/unused)
	var/mob/living/basic/cortical_borer/borer = get_borer()
	if(!borer?.host)
		return FALSE
	var/message = tgui_input_text(owner, "Please enter a message to tell the borer.", "Message", max_length = MAX_MESSAGE_LEN)
	if(!message || QDELETED(borer) || borer.host != owner)
		return FALSE
	log_directed_talk(owner, borer, message, LOG_SAY, "host to borer")
	to_chat(borer, span_changeling("<i>[owner] says:</i> [message]"))
	to_chat(owner, span_changeling("<i>[owner] says:</i> [message]"))
	borer.relay_to_ghosts("Borer Communication from <b>[owner]</b>: [message]")
	return TRUE

// ---- Given to the borer's mind while it pilots the host ----

/datum/action/cooldown/borer/release_control
	name = "Release Control"
	desc = "Give your host their body back."
	button_icon_state = "alien_barf"

/datum/action/cooldown/borer/release_control/Activate(atom/unused)
	var/mob/living/basic/cortical_borer/borer = get_borer()
	if(!borer?.controlling)
		return FALSE
	to_chat(owner, span_danger("You withdraw your probosci, releasing control of [borer.host_brain]."))
	borer.detach()
	return TRUE

/datum/action/cooldown/borer/talk_to_trapped_mind
	name = "Converse with Trapped Mind"
	desc = "Communicate mentally with the trapped mind of your host."

/datum/action/cooldown/borer/talk_to_trapped_mind/Activate(atom/unused)
	var/mob/living/basic/cortical_borer/borer = get_borer()
	if(!borer?.host_brain)
		return FALSE
	var/message = tgui_input_text(owner, "Please enter a message to tell the trapped mind.", "Message", max_length = MAX_MESSAGE_LEN)
	if(!message || QDELETED(borer) || !borer.host_brain)
		return FALSE
	log_directed_talk(owner, borer.host_brain, message, LOG_SAY, "borer to trapped mind")
	to_chat(borer.host_brain, span_changeling("<i>[borer.truename] says:</i> [message]"))
	to_chat(owner, span_changeling("<i>[borer.truename] says:</i> [message]"))
	borer.relay_to_ghosts("Borer Communication from <b>[borer.truename]</b>: [message]")
	return TRUE

/datum/action/cooldown/borer/reproduce
	name = "Reproduce"
	desc = "Vomit up a young borer. Costs 200 chemicals."
	button_icon_state = "alien_egg"

/datum/action/cooldown/borer/reproduce/Activate(atom/unused)
	var/mob/living/basic/cortical_borer/borer = get_borer()
	if(!borer?.controlling || !borer.can_use_ability(chem_cost = 200))
		return FALSE
	var/mob/living/carbon/human/victim = borer.host
	victim.visible_message(span_danger("[victim] heaves violently, expelling a rush of vomit and a wriggling, sluglike creature!"))
	borer.chemicals -= 200
	var/turf/spawn_turf = get_turf(victim)
	new /obj/effect/decal/cleanable/vomit(spawn_turf)
	playsound(spawn_turf, 'sound/effects/splat.ogg', 50, TRUE)
	new /mob/living/basic/cortical_borer(spawn_turf, borer.generation + 1)
	log_game("[key_name(victim)] spawned a new cortical borer by reproducing.")
	return TRUE
