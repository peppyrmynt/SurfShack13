// Gang recruitment pen, territory spraycan, gang tags and the implant breaker.

// ---- Recruitment pen ----

/obj/item/pen/gang
	icon = 'surfshack13/icons/hippie/gang_items.dmi'
	/// Whether the pen is recharging
	var/cooldown = FALSE

/obj/item/pen/gang/attack(mob/living/target_mob, mob/living/user, params)
	var/datum/antagonist/gang/boss/leader = user.mind?.has_antag_datum(/datum/antagonist/gang/boss)
	if(!leader || !ishuman(target_mob) || target_mob.stat == DEAD || target_mob == user)
		return ..()
	. = ..()
	if(!.)
		return
	if(cooldown)
		to_chat(user, span_warning("[src] needs more time to recharge before it can be used."))
		return
	if(!target_mob.client || !target_mob.mind)
		to_chat(user, span_warning("A braindead gangster is a useless gangster!"))
		return
	if(!add_gangster(user, leader.gang, target_mob.mind))
		return
	cooldown = TRUE
	icon_state = "pen_blink"
	update_appearance()
	addtimer(CALLBACK(src, PROC_REF(recharge)), 60 SECONDS / max(1, length(leader.gang.leaders)))

/obj/item/pen/gang/proc/recharge()
	cooldown = FALSE
	icon_state = initial(icon_state)
	update_appearance()
	var/mob/holder = get(loc, /mob)
	if(holder)
		to_chat(holder, span_notice("[icon2html(src, holder)] [src][(loc == holder) ? "" : " in your [loc]"] vibrates softly. It is ready to be used again."))

/// Tries to convert someone into the gang. Returns TRUE on success.
/obj/item/pen/gang/proc/add_gangster(mob/user, datum/team/gang/gang, datum/mind/gangster_mind)
	var/datum/antagonist/gang/existing = gangster_mind.has_antag_datum(/datum/antagonist/gang)
	if(existing)
		if(existing.gang == gang)
			to_chat(user, span_danger("This mind is already controlled by your gang!"))
		else
			to_chat(user, span_danger("This mind is already controlled by someone else!"))
		return FALSE
	var/mob/living/carbon/human/recruit = gangster_mind.current
	if(HAS_TRAIT(recruit, TRAIT_MINDSHIELD) || HAS_MIND_TRAIT(recruit, TRAIT_UNCONVERTABLE))
		to_chat(user, span_danger("This mind is too strong to control!"))
		return FALSE
	recruit.set_silence_if_lower(10 SECONDS)
	recruit.Knockdown(10 SECONDS)
	gangster_mind.add_antag_datum(/datum/antagonist/gang, gang)
	log_combat(user, recruit, "recruited into the [gang.name] gang", src)
	return TRUE

// ---- Territory spraycan ----

/obj/item/toy/crayon/spraycan/gang
	desc = "A modified container containing suspicious paint."
	can_change_colour = FALSE
	charges = 30
	/// The gang this can tags for. Spraycans are gang-locked because of their colour.
	var/datum/team/gang/gang

/obj/item/toy/crayon/spraycan/gang/Initialize(mapload, datum/team/gang/new_gang)
	. = ..()
	if(istype(new_gang))
		gang = new_gang
		set_painting_tool_color(gang.color)

/obj/item/toy/crayon/spraycan/gang/examine(mob/user)
	. = ..()
	if(gang && (user.mind?.has_antag_datum(/datum/antagonist/gang) || isobserver(user)))
		. += span_notice("This spraycan has been specially modified for tagging territory for the [gang.name] Gang.")

/obj/item/toy/crayon/spraycan/gang/use_on(atom/target, mob/user, list/modifiers)
	var/turf/target_turf = istype(target, /obj/effect/decal/cleanable) ? target.loc : target
	if(!gang || !isturf(target_turf) || LAZYACCESS(modifiers, CTRL_CLICK))
		return ..()
	var/datum/antagonist/gang/member = user.mind?.has_antag_datum(/datum/antagonist/gang)
	if(!member)
		return ..()
	if(member.gang != gang)
		to_chat(user, span_danger("This spraycan's color isn't your gang's one! You cannot use it."))
		return ITEM_INTERACT_BLOCKING
	if(is_capped)
		balloon_alert(user, "take the cap off first!")
		return ITEM_INTERACT_BLOCKING
	if(check_empty(user))
		return ITEM_INTERACT_BLOCKING
	if(!can_claim_for_gang(user, target_turf))
		return ITEM_INTERACT_BLOCKING
	tag_for_gang(user, target_turf)
	use_charges(user, 1)
	playsound(user, 'sound/effects/spray.ogg', 5, TRUE, 5)
	return ITEM_INTERACT_SUCCESS

/obj/item/toy/crayon/spraycan/gang/proc/can_claim_for_gang(mob/user, turf/target_turf)
	var/area/territory = get_area(target_turf)
	if(!territory || !is_station_level(target_turf.z) || !(territory.area_flags & VALID_TERRITORY))
		to_chat(user, span_warning("[territory] is unsuitable for tagging."))
		return FALSE
	var/spraying_over = FALSE
	for(var/obj/effect/decal/cleanable/crayon/gang/old_tag in target_turf)
		if(old_tag.gang != gang)
			spraying_over = TRUE
			break
	for(var/datum/team/gang/other_gang as anything in GLOB.gangs)
		if(!(territory.type in (other_gang.territories | other_gang.new_territories)))
			continue
		if(other_gang == gang)
			to_chat(user, span_danger("[territory] has already been tagged by your gang!"))
			return FALSE
		if(!spraying_over)
			to_chat(user, span_danger("[territory] has already been tagged by the [other_gang.name] gang! You must get rid of or spray over the old tag first!"))
			return FALSE
	return TRUE

/obj/item/toy/crayon/spraycan/gang/proc/tag_for_gang(mob/user, turf/target_turf)
	for(var/obj/effect/decal/cleanable/crayon/old_marking in target_turf)
		qdel(old_marking)
	var/area/territory = get_area(target_turf)
	new /obj/effect/decal/cleanable/crayon/gang(target_turf, gang, user.mind)
	to_chat(user, span_notice("You tagged [territory] for your gang!"))
	user.log_message("tagged [territory] for the [gang.name] gang.", LOG_GAME)

// ---- Gang tag ----

/obj/effect/decal/cleanable/crayon/gang
	name = "gang tag"
	desc = "Looks like someone's claimed this area for their gang."
	icon = 'surfshack13/icons/hippie/gang_tags.dmi'
	icon_state = "Clandestine"
	layer = ABOVE_NORMAL_TURF_LAYER
	do_icon_rotate = FALSE
	/// The gang this tag claims territory for
	var/datum/team/gang/gang
	/// Who sprayed it, for Gangmageddon personal income
	var/datum/mind/tagger

/obj/effect/decal/cleanable/crayon/gang/Initialize(mapload, datum/team/gang/new_gang, datum/mind/new_tagger)
	if(!istype(new_gang))
		return INITIALIZE_HINT_QDEL
	gang = new_gang
	. = ..(mapload, gang.color, gang.name, "[gang.name] gang tag", 0, 'surfshack13/icons/hippie/gang_tags.dmi', "Looks like someone's claimed this area for the [gang.name] gang.")
	var/area/territory = get_area(src)
	gang.new_territories[territory.type] = territory.name
	gang.lost_territories -= territory.type
	if(new_tagger)
		tagger = new_tagger
		LAZYADD(gang.tags_by_mind[tagger], src)

/obj/effect/decal/cleanable/crayon/gang/Destroy()
	if(gang)
		var/area/territory = get_area(src)
		if(tagger)
			LAZYREMOVE(gang.tags_by_mind[tagger], src)
			tagger = null
		if(territory)
			gang.new_territories -= territory.type
			if(territory.type in gang.territories)
				gang.lost_territories[territory.type] = territory.name
		gang = null
	return ..()

// ---- Implant breaker ----

/obj/item/implant/gang
	name = "gang implant"
	desc = "Makes you a gangster or such."
	/// Which gang this recruits for
	var/datum/team/gang/gang

/obj/item/implant/gang/get_data()
	return "<b>Implant Specifications:</b><br>\
		<b>Name:</b> Criminal brainwash implant<br>\
		<b>Life:</b> A few seconds after injection.<br>\
		<b>Important Notes:</b> Illegal<br>\
		<hr>\
		<b>Implant Details:</b><br>\
		<b>Function:</b> Contains a small pod of nanobots that change the host's brain to be loyal to a certain organization.<br>\
		<b>Special Features:</b> This device will also emit a small EMP pulse, destroying any other implants within the host's brain.<br>\
		<b>Integrity:</b> Implant's EMP function will destroy itself in the process."

/obj/item/implant/gang/implant(mob/living/target, mob/user, silent = FALSE, force = FALSE)
	if(!gang || !ishuman(target) || !target.mind || target.stat == DEAD)
		return FALSE
	var/datum/antagonist/gang/current = target.mind.has_antag_datum(/datum/antagonist/gang)
	if(current?.gang == gang)
		return FALSE
	for(var/obj/item/implant/other_implant as anything in target.implants)
		qdel(other_implant)
	if(istype(current, /datum/antagonist/gang/boss))
		target.visible_message(span_warning("[target] seems to resist the implant!"), span_warning("You feel the influence of your enemies try to invade your mind!"))
		qdel(src)
		return TRUE
	if(current)
		target.mind.remove_antag_datum(/datum/antagonist/gang)
	target.mind.add_antag_datum(/datum/antagonist/gang, gang)
	if(user)
		log_combat(user, target, "gang-implanted", src)
	qdel(src)
	return TRUE

/obj/item/implanter/gang
	name = "implanter (gang)"

/obj/item/implanter/gang/Initialize(mapload, datum/team/gang/new_gang)
	if(!istype(new_gang))
		return INITIALIZE_HINT_QDEL
	var/obj/item/implant/gang/gang_implant = new(src)
	gang_implant.gang = new_gang
	imp = gang_implant
	return ..()
