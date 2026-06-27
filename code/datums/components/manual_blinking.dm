/datum/component/manual_blinking
	dupe_mode = COMPONENT_DUPE_UNIQUE

	var/obj/item/organ/eyes/E
	var/warn_grace = FALSE
	var/warn_dying = FALSE
	var/last_blink
	var/check_every = 20 SECONDS
	var/grace_period = 6 SECONDS
	var/damage_rate = 1 // organ damage taken per tick
	var/list/valid_emotes = list(/datum/emote/living/carbon/blink, /datum/emote/living/carbon/blink_r)

/datum/component/manual_blinking/Initialize()
	if(!iscarbon(parent))
		return COMPONENT_INCOMPATIBLE

	var/mob/living/carbon/C = parent
	E = C.get_organ_slot(ORGAN_SLOT_EYES)

	if(E)
		START_PROCESSING(SSdcs, src)
		last_blink = world.time
		to_chat(C, span_notice("You suddenly realize you're blinking manually."))

/datum/component/manual_blinking/Destroy(force)
	E = null
	STOP_PROCESSING(SSdcs, src)
	to_chat(parent, span_notice("You revert back to automatic blinking."))
	return ..()

/datum/component/manual_blinking/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOB_EMOTE, PROC_REF(check_emote))
	RegisterSignal(parent, COMSIG_CARBON_GAIN_ORGAN, PROC_REF(check_added_organ))
	RegisterSignal(parent, COMSIG_CARBON_LOSE_ORGAN, PROC_REF(check_removed_organ))
	RegisterSignal(parent, COMSIG_LIVING_REVIVE, PROC_REF(restart))
	RegisterSignal(parent, COMSIG_LIVING_DEATH, PROC_REF(pause))

/datum/component/manual_blinking/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_EMOTE)
	UnregisterSignal(parent, COMSIG_CARBON_GAIN_ORGAN)
	UnregisterSignal(parent, COMSIG_CARBON_LOSE_ORGAN)
	UnregisterSignal(parent, COMSIG_LIVING_REVIVE)
	UnregisterSignal(parent, COMSIG_LIVING_DEATH)

/datum/component/manual_blinking/proc/restart()
	SIGNAL_HANDLER

	START_PROCESSING(SSdcs, src)

/datum/component/manual_blinking/proc/pause()
	SIGNAL_HANDLER

	STOP_PROCESSING(SSdcs, src)

/datum/component/manual_blinking/process()
	var/mob/living/carbon/C = parent

	if(world.time > (last_blink + check_every + grace_period))
		if(!warn_dying)
			to_chat(C, span_userdanger("Your eyes begin to wither, you need to blink!"))
			warn_dying = TRUE

		E.apply_organ_damage(damage_rate)
	else if(world.time > (last_blink + check_every))
		if(!warn_grace)
			to_chat(C, span_danger("You feel a need to blink!"))
			warn_grace = TRUE

/datum/component/manual_blinking/proc/check_added_organ(mob/who_cares, obj/item/organ/O)
	SIGNAL_HANDLER

	var/obj/item/organ/eyes/new_eyes = O

	if(istype(new_eyes,/obj/item/organ/eyes))
		E = new_eyes
		START_PROCESSING(SSdcs, src)

/datum/component/manual_blinking/proc/check_removed_organ(mob/who_cares, obj/item/organ/O)
	SIGNAL_HANDLER

	var/obj/item/organ/eyes/bye_beyes = O // oh come on, that's pretty good

	if(istype(bye_beyes, /obj/item/organ/eyes))
		E = null
		STOP_PROCESSING(SSdcs, src)

/datum/component/manual_blinking/proc/check_emote(mob/living/carbon/user, datum/emote/emote)
	SIGNAL_HANDLER

	if(emote.type in valid_emotes)
		warn_grace = FALSE
		warn_dying = FALSE
		last_blink = world.time

//This is used for aivime, the inverse of aiuri.
/datum/component/manual_blinking/overdrive
	dupe_mode = COMPONENT_DUPE_UNIQUE
	warn_grace = FALSE
	warn_dying = FALSE
	last_blink
	check_every = 2 SECONDS
	grace_period = 1 SECONDS
	damage_rate = 5 // organ damage taken per tick
	var/datum/action/cooldown/manual_blink_button/blink_button

/datum/component/manual_blinking/overdrive/Initialize()
	if(!iscarbon(parent))
		return COMPONENT_INCOMPATIBLE

	var/mob/living/carbon/C = parent
	E = C.get_organ_slot(ORGAN_SLOT_EYES)

	blink_button = new
	blink_button.Grant(C)

	if(E)
		START_PROCESSING(SSdcs, src)
		last_blink = world.time
		to_chat(C, span_userdanger("You suddenly realize you're blinking manually."))

/datum/component/manual_blinking/overdrive/Destroy(force)
	QDEL_NULL(blink_button)
	E = null
	STOP_PROCESSING(SSdcs, src)
	to_chat(parent, span_notice("You revert back to automatic blinking."))
	return ..()

/datum/component/manual_blinking/overdrive/process()
	var/mob/living/carbon/C = parent

	if(world.time > (last_blink + check_every + grace_period))
		if(!warn_dying)
			to_chat(C, span_userdanger("Your eyes begin to wither, you need to blink!"))
			warn_dying = TRUE

		E.set_organ_damage(min(E.damage + damage_rate, 35))
	else if(world.time > (last_blink + check_every))
		if(!warn_grace)
			to_chat(C, span_danger("You feel a need to blink!"))
			warn_grace = TRUE

/datum/action/cooldown/manual_blink_button
	name = "Blink"
	cooldown_time = 2.5 SECONDS
	button_icon = 'icons/effects/mouse_pointers/blind_target.dmi'
	button_icon_state = "blink"

/datum/action/cooldown/manual_blink_button/Activate(atom/target)
	. = ..()

	var/mob/living/carbon/C = owner
	if(!istype(C))
		return

	C.emote("blink")
