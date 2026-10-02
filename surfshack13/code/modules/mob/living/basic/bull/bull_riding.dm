/**
 * Bull riding
 *
 * Anyone in a cowboy hat (or a sombrero) can drag themselves onto a dazed bull to try and ride it.
 * One in four times they stay on and get to steer it, right clicking to charge.
 * The rest of the time the bull shakes off the daze and runs them straight down, no windup.
 */

/// Chance to actually stay on
#define BULL_RIDE_CHANCE 25

/datum/component/riding/creature/cow/bull
	can_use_abilities = TRUE

/mob/living/basic/bull
	/// Hats that make you think you can ride a bull
	var/static/list/rodeo_hats = typecacheof(list(
		/obj/item/clothing/head/cowboy,
		/obj/item/clothing/head/costume/sombrero,
	))
	/// Stops people spamming mount attempts in one frame
	COOLDOWN_DECLARE(ride_attempt_cooldown)
	/// Sound slot: the rider stays on. YEEHAW!
	var/rodeo_success_sound = 'surfshack13/sound/bull/yeehaw.ogg'

/mob/living/basic/bull/proc/setup_riding()
	AddElement(/datum/element/ridable, /datum/component/riding/creature/cow/bull)
	RegisterSignal(src, COMSIG_MOVABLE_BUCKLE, PROC_REF(on_mounted))
	RegisterSignal(src, COMSIG_MOVABLE_UNBUCKLE, PROC_REF(on_dismounted))

/mob/living/basic/bull/mouse_drop_receive(atom/dropping, mob/user, params)
	if(!isliving(dropping))
		return ..()
	// The only way on is to rodeo it yourself
	if(dropping != user)
		return
	try_rodeo(user)

/mob/living/basic/bull/proc/try_rodeo(mob/living/cowboy)
	if(stat == DEAD || LAZYLEN(buckled_mobs) || !cowboy.Adjacent(src) || HAS_TRAIT(cowboy, TRAIT_INCAPACITATED) || cowboy.buckled)
		return
	if(!is_type_in_typecache(cowboy.get_item_by_slot(ITEM_SLOT_HEAD), rodeo_hats))
		to_chat(cowboy, span_warning("You'd need a proper cowboy hat before you even think about riding [src]."))
		return
	if(!HAS_TRAIT(src, TRAIT_INCAPACITATED))
		to_chat(cowboy, span_warning("[src] is way too wild right now! Wait until [p_theyre()] dazed."))
		return
	if(!COOLDOWN_FINISHED(src, ride_attempt_cooldown))
		return
	COOLDOWN_START(src, ride_attempt_cooldown, 1 SECONDS)

	cowboy.visible_message(
		span_danger("[cowboy] tips [cowboy.p_their()] hat and leaps onto [src]!"),
		span_danger("You tip your hat and leap onto [src]!"),
	)
	if(prob(BULL_RIDE_CHANCE))
		if(!buckle_mob(cowboy, check_loc = FALSE))
			return
		playsound(src, rodeo_success_sound, 100, FALSE)
		visible_message(span_big(span_boldnotice("[src] bucks wildly, but [cowboy] holds on! YEEHAW!")))
		to_chat(cowboy, span_boldnotice("You've tamed [src]! Steer with your movement keys, right click to charge."))
		return

	// Nope
	visible_message(
		span_danger("[src] snaps out of it, throws [cowboy] off and runs [cowboy.p_them()] straight down!"),
		blind_message = span_hear("You hear an angry bellow!"),
	)
	SetStun(0)
	SetParalyzed(0)
	SetKnockdown(0)
	if(!charge?.instant_charge(cowboy))
		// Couldn't line up a charge somehow, gore them anyway
		bull_gore(src, cowboy, charge?.gore_damage || 25, charge?.throw_range || 6, get_dir(src, cowboy), WOUND_SEVERITY_SEVERE, 2 SECONDS, 50, 50)

/mob/living/basic/bull/proc/on_mounted(datum/source, mob/living/rider, force)
	SIGNAL_HANDLER
	RegisterSignal(rider, COMSIG_MOB_CLICKON, PROC_REF(on_rider_click))

/mob/living/basic/bull/proc/on_dismounted(datum/source, mob/living/rider, force)
	SIGNAL_HANDLER
	UnregisterSignal(rider, COMSIG_MOB_CLICKON)

/// Right click anywhere while riding to charge there
/mob/living/basic/bull/proc/on_rider_click(mob/living/rider, atom/target, list/modifiers)
	SIGNAL_HANDLER
	if(!LAZYACCESS(modifiers, RIGHT_CLICK) || rider.buckled != src || !charge)
		return
	if(target == src || target == rider || !(isturf(target) || isturf(target.loc)))
		return
	INVOKE_ASYNC(charge, TYPE_PROC_REF(/datum/action/cooldown, InterceptClickOn), rider, null, target)
	return COMSIG_MOB_CANCEL_CLICKON

#undef BULL_RIDE_CHANCE
