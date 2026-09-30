// Cortical Borer - ported from HippieStation.
// A ghost-controlled brain slug that crawls into a host's head, talks to them, feeds them chemicals,
// and can eventually take over their body. Sugar in the host's blood makes it docile.
// Rebuilt on basic mobs, cooldown actions and mind transfers instead of Hippie's verbs and raw ckey swaps.

GLOBAL_LIST_EMPTY(cortical_borers)

#define BORER_MAX_CHEMICALS 250

/mob/living/basic/cortical_borer
	name = "cortical borer"
	real_name = "cortical borer"
	desc = "A small, quivering, slug-like creature."
	icon = 'surfshack13/icons/hippie/cortical_borer.dmi'
	icon_state = "borer"
	icon_living = "borer"
	icon_dead = "borer_dead"
	health = 20
	maxHealth = 20
	melee_damage_lower = 5
	melee_damage_upper = 5
	attack_verb_continuous = "chomps"
	attack_verb_simple = "chomp"
	attack_sound = 'sound/items/weapons/bite.ogg'
	pass_flags = PASSTABLE | PASSMOB
	mob_size = MOB_SIZE_TINY
	density = FALSE
	faction = list("creature")
	speak_emote = list("chirps")
	unsuitable_atmos_damage = 0
	habitable_atmos = null
	minimum_survivable_temperature = 0
	maximum_survivable_temperature = 1500

	/// Which generation of borer this is, used for its true name
	var/generation = 1
	/// Name shown on the cortical link
	var/truename
	/// The mob we are currently living in
	var/mob/living/carbon/human/host
	/// Holds the host's own mind while we control their body
	var/mob/living/captive_brain/host_brain
	/// Our own mind, remembered while it is piloting the host's body
	var/datum/mind/borer_mind
	/// Chemicals used to fuel our abilities
	var/chemicals = 10
	/// Sugar in the host makes us unable to use most abilities
	var/docile = FALSE
	/// Timer for waking up once the sugar is gone
	var/wake_timer
	/// Whether we are working towards taking control
	var/bonding = FALSE
	/// Whether we are currently piloting the host
	var/controlling = FALSE
	/// Whether we are working our way out of the host
	var/leaving = FALSE
	/// Whether we are hiding under things
	var/hiding = FALSE

	/// Abilities available while outside a host
	var/list/datum/action/outside_actions = list()
	/// Abilities available while inside a host
	var/list/datum/action/inside_actions = list()
	/// Given to the host so they can talk back to us
	var/datum/action/cooldown/borer/talk_to_borer/host_talk_action
	/// Given to our own mind while it pilots the host
	var/list/datum/action/control_actions = list()

	var/static/list/borer_names = list(
		"Primary", "Secondary", "Tertiary", "Quaternary", "Quinary", "Senary",
		"Septenary", "Octonary", "Novenary", "Decenary", "Undenary", "Duodenary",
	)

/mob/living/basic/cortical_borer/Initialize(mapload, generation = 1)
	. = ..()
	src.generation = generation
	real_name = "Cortical Borer [rand(1000, 9999)]"
	name = real_name
	truename = "[borer_names[min(generation, length(borer_names))]] [rand(1000, 9999)]"
	GLOB.cortical_borers += src
	ADD_TRAIT(src, TRAIT_VENTCRAWLER_ALWAYS, INNATE_TRAIT)

	for(var/action_type in list(
		/datum/action/cooldown/borer/infest,
		/datum/action/cooldown/borer/toggle_hide,
		/datum/action/cooldown/borer/paralyze,
	))
		outside_actions += new action_type(src)
	for(var/action_type in list(
		/datum/action/cooldown/borer/talk_to_host,
		/datum/action/cooldown/borer/leave_host,
		/datum/action/cooldown/borer/assume_control,
		/datum/action/cooldown/borer/punish,
		/datum/action/cooldown/borer/secrete_chemicals,
		/datum/action/cooldown/borer/jumpstart,
	))
		inside_actions += new action_type(src)
	for(var/action_type in list(
		/datum/action/cooldown/borer/release_control,
		/datum/action/cooldown/borer/talk_to_trapped_mind,
		/datum/action/cooldown/borer/reproduce,
	))
		control_actions += new action_type(src)
	host_talk_action = new(src)

	for(var/datum/action/outside as anything in outside_actions)
		outside.Grant(src)

	AddComponent(\
		/datum/component/ghost_direct_control,\
		ban_type = ROLE_ALIEN,\
		role_name = "cortical borer",\
		poll_question = "Do you want to play as a cortical borer?",\
		poll_ignore_key = POLL_IGNORE_ALIEN_LARVA,\
		assumed_control_message = "You are a cortical borer! Crawl into someone's head and keep yourself, your host and your spawn alive.",\
		after_assumed_control = CALLBACK(src, PROC_REF(became_player_controlled)),\
	)

/mob/living/basic/cortical_borer/Destroy()
	if(host)
		leave_host()
	GLOB.cortical_borers -= src
	QDEL_LIST(outside_actions)
	QDEL_LIST(inside_actions)
	QDEL_LIST(control_actions)
	QDEL_NULL(host_talk_action)
	borer_mind = null
	return ..()

/mob/living/basic/cortical_borer/death(gibbed)
	. = ..()
	if(host)
		leave_host()

/mob/living/basic/cortical_borer/proc/became_player_controlled()
	mind?.add_antag_datum(/datum/antagonist/cortical_borer)

/mob/living/basic/cortical_borer/get_status_tab_items()
	. = ..()
	. += "Chemicals: [chemicals]/[BORER_MAX_CHEMICALS]"
	if(host)
		. += "Host: [host.real_name]"

/mob/living/basic/cortical_borer/ex_act(severity, target)
	if(host)
		return FALSE
	return ..()

// Borers scan people instead of biting them.
/mob/living/basic/cortical_borer/UnarmedAttack(atom/attack_target, proximity_flag, list/modifiers)
	if(!host && isliving(attack_target) && proximity_flag)
		healthscan(src, attack_target)
		chemscan(src, attack_target)
		return TRUE
	return ..()

/mob/living/basic/cortical_borer/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. = ..()
	if(!host || stat == DEAD)
		return
	chemicals = min(chemicals + (host.stat == DEAD ? 0.5 : 1) * seconds_per_tick, BORER_MAX_CHEMICALS)
	if(host.stat == DEAD)
		return

	var/feedback_mob = controlling ? host : src
	if(host.reagents.has_reagent(/datum/reagent/consumable/sugar))
		if(!docile || wake_timer)
			to_chat(feedback_mob, span_warning("You feel the soporific flow of sugar in your host's blood, lulling you into docility."))
			deltimer(wake_timer)
			wake_timer = null
			docile = TRUE
	else if(docile && !wake_timer)
		to_chat(feedback_mob, span_warning("You start shaking off your lethargy as the sugar leaves your host's blood. This will take about 10 seconds..."))
		wake_timer = addtimer(CALLBACK(src, PROC_REF(wake_up)), 10 SECONDS, TIMER_STOPPABLE)

	if(!controlling)
		return
	if(docile)
		to_chat(host, span_warning("You are feeling far too docile to continue controlling your host..."))
		detach()
		return
	if(SPT_PROB(2.5, seconds_per_tick))
		host.adjustOrganLoss(ORGAN_SLOT_BRAIN, rand(1, 2))
	if(SPT_PROB(host.get_organ_loss(ORGAN_SLOT_BRAIN) / 20, seconds_per_tick))
		host.emote(pick("blink", "blink_r", "choke", "drool", "twitch", "twitch_s", "gasp"))

/mob/living/basic/cortical_borer/proc/wake_up()
	to_chat(controlling ? host : src, span_warning("You finish shaking off your lethargy."))
	docile = FALSE
	wake_timer = null

/// Checks shared by most abilities. Returns TRUE if we can act, with feedback if we can't.
/mob/living/basic/cortical_borer/proc/can_use_ability(needs_host = TRUE, needs_awake = TRUE, chem_cost = 0)
	if(stat != CONSCIOUS)
		to_chat(controlling ? host : src, span_warning("You cannot do that in your current state."))
		return FALSE
	if(needs_host && !host)
		to_chat(src, span_warning("You are not inside a host body."))
		return FALSE
	if(!needs_host && host)
		to_chat(src, span_warning("You cannot do that from within a host body."))
		return FALSE
	if(needs_awake && docile)
		to_chat(controlling ? host : src, span_warning("You are feeling far too docile to do that."))
		return FALSE
	if(chemicals < chem_cost)
		to_chat(controlling ? host : src, span_warning("You need [chem_cost] chemicals stored to do that!"))
		return FALSE
	return TRUE

/mob/living/basic/cortical_borer/say(
	message,
	bubble_type,
	list/spans = list(),
	sanitize = TRUE,
	datum/language/language,
	ignore_spam = FALSE,
	forced,
	filterproof = FALSE,
	message_range = 7,
	datum/saymode/saymode,
	list/message_mods = list(),
)
	if(stat == DEAD)
		return ..()
	message = trim(copytext_char(sanitize(message), 1, MAX_MESSAGE_LEN))
	if(!message)
		return
	if(copytext(message, 1, 2) == ";")
		cortical_link(trim(copytext(message, 2)))
		return
	if(host)
		talk_to_host(message)
		return
	to_chat(src, span_warning("You cannot speak without a host! Prefix a message with ; to talk to other borers."))

/// Hive chat between all borers, seen by ghosts.
/mob/living/basic/cortical_borer/proc/cortical_link(message)
	if(!message)
		return
	log_talk(message, LOG_SAY, tag = "cortical link")
	var/rendered = span_alien("<b>Cortical Link:</b> [truename] sings, \"[message]\"")
	for(var/mob/living/basic/cortical_borer/borer as anything in GLOB.cortical_borers)
		to_chat(borer.controlling ? borer.host : borer, rendered)
	for(var/mob/dead/observer/ghost in GLOB.dead_mob_list)
		to_chat(ghost, "[FOLLOW_LINK(ghost, src)] [rendered]")

/mob/living/basic/cortical_borer/proc/talk_to_host(message)
	if(!host || !message)
		return
	var/say_string = docile ? "slurs" : "states"
	log_directed_talk(src, host, message, LOG_SAY, "borer to host")
	to_chat(host, span_changeling("<i>[truename] [say_string]:</i> [message]"))
	to_chat(src, span_changeling("<i>[truename] [say_string]:</i> [message]"))
	relay_to_ghosts("Borer Communication from <b>[truename]</b>: [message]")

/mob/living/basic/cortical_borer/proc/relay_to_ghosts(text)
	for(var/mob/dead/observer/ghost in GLOB.dead_mob_list)
		to_chat(ghost, "[FOLLOW_LINK(ghost, src)] [span_changeling("<i>[text]</i>")]")

/// Crawls into a host's head.
/mob/living/basic/cortical_borer/proc/infest(mob/living/carbon/human/target)
	host = target
	forceMove(target)
	RegisterSignal(host, COMSIG_LIVING_DEATH, PROC_REF(on_host_death))
	RegisterSignal(host, COMSIG_QDELETING, PROC_REF(on_host_deleted))
	for(var/datum/action/outside as anything in outside_actions)
		outside.Remove(src)
	for(var/datum/action/inside as anything in inside_actions)
		inside.Grant(src)
	host_talk_action.Grant(host)
	log_combat(src, host, "infested")

/// Leaves the host and drops to the floor.
/mob/living/basic/cortical_borer/proc/leave_host()
	if(!host)
		return
	if(controlling)
		detach()
	bonding = FALSE
	leaving = FALSE
	UnregisterSignal(host, list(COMSIG_LIVING_DEATH, COMSIG_QDELETING))
	host_talk_action.Remove(host)
	for(var/datum/action/inside as anything in inside_actions)
		inside.Remove(src)
	if(stat != DEAD)
		for(var/datum/action/outside as anything in outside_actions)
			outside.Grant(src)
	var/turf/drop_turf = get_turf(host)
	host = null
	forceMove(drop_turf)
	reset_perspective()

/mob/living/basic/cortical_borer/proc/on_host_death(datum/source)
	SIGNAL_HANDLER
	if(controlling)
		detach()

/mob/living/basic/cortical_borer/proc/on_host_deleted(datum/source)
	SIGNAL_HANDLER
	leave_host()

/// Swaps our mind into the host's body and locks their mind away in a captive brain.
/mob/living/basic/cortical_borer/proc/assume_control()
	if(!host || controlling || host.stat == DEAD || !bonding)
		return
	bonding = FALSE
	if(docile)
		to_chat(src, span_warning("You are feeling far too docile to do that."))
		return
	if(IS_CULTIST(host))
		to_chat(src, span_warning("[host]'s mind seems to be blocked by some unknown force!"))
		return
	if(!mind)
		return

	to_chat(src, span_warning("You plunge your probosci deep into the cortex of the host brain, interfacing directly with their nervous system."))
	to_chat(host, span_userdanger("You feel a strange shifting sensation behind your eyes as an alien consciousness displaces yours."))
	log_combat(src, host, "assumed control of")

	host_brain = new(src)
	host_brain.name = host.real_name
	host_brain.real_name = host.real_name
	host.mind?.transfer_to(host_brain)
	to_chat(host_brain, span_danger("You are trapped in your own mind. You feel that there must be a way to resist!"))

	borer_mind = mind
	borer_mind.transfer_to(host)
	controlling = TRUE
	host_talk_action.Remove(host)
	for(var/datum/action/control as anything in control_actions)
		control.Grant(host)

/// Gives the host their body back.
/mob/living/basic/cortical_borer/proc/detach()
	if(!host || !controlling)
		return
	controlling = FALSE
	for(var/datum/action/control as anything in control_actions)
		control.Remove(host)
	if(borer_mind && borer_mind.current == host)
		borer_mind.transfer_to(src)
	borer_mind = null
	if(host_brain?.mind)
		host_brain.mind.transfer_to(host)
	QDEL_NULL(host_brain)
	if(host.stat != DEAD)
		host_talk_action.Grant(host)
	log_combat(src, host, "released control of")

/// Holds the host's mind while a borer drives their body.
/mob/living/captive_brain
	name = "host brain"
	real_name = "host brain"
	/// Stops two resist attempts running at once
	var/resisting = FALSE

/mob/living/captive_brain/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_GODMODE, INNATE_TRAIT)

/mob/living/captive_brain/say(
	message,
	bubble_type,
	list/spans = list(),
	sanitize = TRUE,
	datum/language/language,
	ignore_spam = FALSE,
	forced,
	filterproof = FALSE,
	message_range = 7,
	datum/saymode/saymode,
	list/message_mods = list(),
)
	var/mob/living/basic/cortical_borer/borer = loc
	if(!istype(borer) || !borer.host)
		return
	message = trim(copytext_char(sanitize(message), 1, MAX_MESSAGE_LEN))
	if(!message)
		return
	log_talk(message, LOG_SAY, tag = "captive brain")
	to_chat(src, span_alien("<i>You whisper silently, \"[message]\"</i>"))
	to_chat(borer.host, span_alien("<i>The captive mind of [src] whispers, \"[message]\"</i>"))
	borer.relay_to_ghosts("Thought-speech, <b>[src]</b> -> <b>[borer.truename]</b>: [message]")

/mob/living/captive_brain/emote(act, m_type, message, intentional, force_silence)
	return FALSE

/mob/living/captive_brain/execute_resist()
	var/mob/living/basic/cortical_borer/borer = loc
	if(!istype(borer) || !borer.controlling || resisting)
		return
	resisting = TRUE
	to_chat(src, span_danger("You begin doggedly resisting the parasite's control (this will take approximately 20 seconds)."))
	to_chat(borer.host, span_danger("You feel the captive mind of [src] begin to resist your control."))
	var/delay = rand(15 SECONDS, 25 SECONDS) + borer.host.get_organ_loss(ORGAN_SLOT_BRAIN)
	addtimer(CALLBACK(src, PROC_REF(return_control), borer), delay)

/mob/living/captive_brain/proc/return_control(mob/living/basic/cortical_borer/borer)
	resisting = FALSE
	if(QDELETED(borer) || !borer.controlling || borer.host_brain != src)
		return
	borer.host.adjustOrganLoss(ORGAN_SLOT_BRAIN, rand(5, 10))
	to_chat(src, span_danger("With an immense exertion of will, you regain control of your body!"))
	to_chat(borer.host, span_danger("You feel control of the host brain ripped from your grasp, and retract your probosci before the wild neural impulses can damage you."))
	borer.detach()

/// Returns the borer living in this mob's head, if any.
/mob/living/proc/get_cortical_borer()
	return locate(/mob/living/basic/cortical_borer) in contents

#undef BORER_MAX_CHEMICALS
