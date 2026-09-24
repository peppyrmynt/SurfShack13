/// Hippie's arrow, using the current guardian creator's possession and summoner APIs.
/obj/item/stand_arrow
	parent_type = /obj/item/guardian_creator
	name = "mysterious arrow"
	desc = "An ancient arrow. Stabbing yourself or someone else with it may awaken an unpredictable power... or kill them."
	icon = 'icons/obj/stands/arrow.dmi'
	icon_state = "standarrow"
	inhand_icon_state = "standarrow"
	lefthand_file = 'icons/mob/inhands/stands/arrow_left.dmi'
	righthand_file = 'icons/mob/inhands/stands/arrow_right.dmi'
	w_class = WEIGHT_CLASS_BULKY
	sharpness = SHARP_POINTY
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	allow_changeling = FALSE
	var/kill_chance = 50
	var/uses = 3
	var/datum/weakref/target_ref
	var/awakening_timer
	var/datum/stand_stats/pending_stats
	var/datum/stand_power/pending_power

/obj/item/stand_arrow/Initialize(mapload)
	. = ..()
	SSpoints_of_interest.make_point_of_interest(src)

/obj/item/stand_arrow/Destroy()
	reset_arrow()
	return ..()

/obj/item/stand_arrow/attack_self(mob/living/user)
	attack(user, user)

/obj/item/stand_arrow/proc/valid_target(mob/living/target)
	return !QDELETED(target) && iscarbon(target) && target.client && target.mind && target.stat != DEAD && !IS_CHANGELING(target) && !length(target.get_all_linked_holoparasites())

/obj/item/stand_arrow/attack(mob/living/target, mob/living/user)
	if(used || uses <= 0)
		return
	if(!valid_target(target))
		balloon_alert(user, "the arrow rejects them!")
		return
	used = TRUE
	user.visible_message(span_warning("[user] raises [src] to stab [target]!"))
	if(!do_after(user, 5 SECONDS, target) || QDELETED(src) || !valid_target(target) || !user.is_holding(src))
		used = FALSE
		return
	if(!user.dropItemToGround(src))
		used = FALSE
		return
	log_combat(user, target, "stabbed with a Stand Arrow")
	message_admins("[ADMIN_LOOKUPFLW(user)] stabbed [ADMIN_LOOKUPFLW(target)] with a Stand Arrow at [ADMIN_VERBOSEJMP(target)].")
	target_ref = WEAKREF(target)
	RegisterSignal(target, COMSIG_QDELETING, PROC_REF(target_deleted))
	forceMove(target)
	target.visible_message(span_holoparasite("[src] embeds itself in [target] and begins to glow!"))
	awakening_timer = addtimer(CALLBACK(src, PROC_REF(awaken)), 15 SECONDS, TIMER_STOPPABLE)

/obj/item/stand_arrow/proc/target_deleted(mob/living/source)
	SIGNAL_HANDLER
	reset_arrow()

/// A single failure releases the arrow; no unbounded poll retries or held strong mob references.
/obj/item/stand_arrow/proc/reset_arrow()
	if(awakening_timer)
		deltimer(awakening_timer)
		awakening_timer = null
	var/mob/living/target = target_ref?.resolve()
	if(target)
		UnregisterSignal(target, COMSIG_QDELETING)
		if(loc == target)
			forceMove(get_turf(target))
	target_ref = null
	QDEL_NULL(pending_stats)
	QDEL_NULL(pending_power)
	used = FALSE

/obj/item/stand_arrow/proc/awaken()
	awakening_timer = null
	var/mob/living/target = target_ref?.resolve()
	if(!valid_target(target) || loc != target)
		reset_arrow()
		return
	if(prob(kill_chance))
		log_game("[key_name(target)] was killed by a Stand Arrow.")
		message_admins("[ADMIN_LOOKUPFLW(target)] failed a Stand Arrow awakening and was dusted.")
		reset_arrow()
		target.visible_message(span_bolddanger("[target] collapses into ash!"))
		target.dust(drop_items = TRUE)
		return
	var/list/weighted_powers = list()
	for(var/datum/stand_power/power_type as anything in subtypesof(/datum/stand_power))
		weighted_powers[power_type] = initial(power_type.weight)
	var/power_type = pick_weight(weighted_powers)
	pending_power = new power_type
	pending_stats = new
	pending_stats.randomize(15 - pending_power.cost)
	var/mob/dead/observer/candidate = SSpolling.poll_ghost_candidates(
		"Become [target.real_name]'s [pending_power.name] Stand? [pending_stats.describe()]",
		check_jobban = ROLE_PAI,
		poll_time = 10 SECONDS,
		ignore_category = POLL_IGNORE_HOLOPARASITE,
		alert_pic = pending_power.guardian_type,
		jump_target = target,
		role_name_text = "Stand",
		amount_to_pick = 1,
	)
	// The arrow, victim and ghost can all disappear while polling yields.
	if(QDELETED(src))
		return
	if(!used || target_ref?.resolve() != target || !valid_target(target) || loc != target || QDELETED(candidate) || !candidate.client)
		reset_arrow()
		return
	var/mob/living/basic/guardian/stand = spawn_guardian(target, candidate, pending_power.guardian_type)
	if(!QDELETED(stand))
		stand.AddComponent(/datum/component/arrow_stand, pending_stats, pending_power, src)
		pending_stats = null
		pending_power = null
		uses--
		SEND_SIGNAL(src, COMSIG_TRAITOR_ITEM_USED(type))
		to_chat(stand, span_holoparasite(stand.playstyle_string))
	reset_arrow()
	if(uses <= 0)
		visible_message(span_warning("[src] crumbles away!"))
		qdel(src)

/obj/item/stand_arrow/examine(mob/user)
	. = ..()
	. += span_notice("It can awaken [uses] more Stand[uses == 1 ? "" : "s"].")
	if(isobserver(user))
		. += "Awakening has a [kill_chance]% chance of killing the victim."

/// Extremely rare meteor from Hippie's original Stand meteor implementation.
/// It intentionally drops the normal arrow so the later Requiem progression is not bypassed.
/obj/effect/meteor/stand
	name = "glowing meteor"
	desc = "An oddly radiant meteor. Something inside it seems far more important than the rock around it."
	icon_state = "glowing"
	hits = 3
	heavy = TRUE
	meteorsound = 'sound/effects/bamf.ogg'
	meteordrop = list(/obj/item/stand_arrow)
	dropamt = 1
	threat = 100
	signature = "mysterious"
