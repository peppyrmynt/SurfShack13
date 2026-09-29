/// Trait source for everything the chicken mask applies.
#define CHICKEN_MASK_TRAIT "chicken_mask"
/// Time without landing a hit before the combo resets.
#define RAMPAGE_COMBO_TIMEOUT (12.5 SECONDS)
/// Getting hit takes this much off the time left on the combo.
#define RAMPAGE_HIT_TIMER_PENALTY (RAMPAGE_COMBO_TIMEOUT / 4)
/// Combo points for finishing an execution.
#define RAMPAGE_EXECUTION_BONUS 2
/// Speed boost just for wearing the mask.
#define RAMPAGE_BASE_SPEED 0.15
/// Extra speed per point of combo. Uncapped.
#define RAMPAGE_SPEED_PER_COMBO 0.025
/// Click cooldown reduction per point of combo.
#define RAMPAGE_CLICK_SPEED_PER_COMBO 0.01
/// Click cooldown can't drop below this fraction of normal, otherwise a big enough combo means no cooldown at all.
#define RAMPAGE_MIN_CLICK_MODIFIER 0.1

/**
 * The chicken mask.
 *
 * Once it's on, it doesn't come off. The wearer goes on a rampage: gory kills, executions on anyone who's down,
 * a combo counter that makes them faster and attack quicker, no soft crit, brutal throws, and music that plays out
 * of them, through walls, changing with their health.
 */
/obj/item/clothing/mask/chicken_rampage
	name = "chicken mask"
	desc = "A rubber chicken mask. It smells like blood and cheap cologne."
	icon = 'icons/obj/clothing/head/costume.dmi'
	icon_state = "chickenhead"
	worn_icon = 'icons/mob/clothing/head/costume.dmi'
	worn_icon_state = "chickenhead"
	lefthand_file = 'icons/mob/inhands/clothing/hats_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/clothing/hats_righthand.dmi'
	inhand_icon_state = "chicken_head"
	w_class = WEIGHT_CLASS_SMALL
	flags_inv = HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR|HIDESNOUT
	flags_cover = MASKCOVERSMOUTH

/obj/item/clothing/mask/chicken_rampage/equipped(mob/living/user, slot)
	. = ..()
	if(!(slot & ITEM_SLOT_MASK) || !isliving(user))
		return
	ADD_TRAIT(src, TRAIT_NODROP, CHICKEN_MASK_TRAIT)
	user.AddComponent(/datum/component/chicken_rampage, src)

/obj/item/clothing/mask/chicken_rampage/dropped(mob/living/user)
	. = ..()
	// Only happens if it gets forced off, like losing the head.
	REMOVE_TRAIT(src, TRAIT_NODROP, CHICKEN_MASK_TRAIT)
	qdel(user.GetComponent(/datum/component/chicken_rampage))

/obj/item/clothing/mask/chicken_rampage/examine(mob/user)
	. = ..()
	if(HAS_TRAIT(src, TRAIT_NODROP))
		. += span_warning("It's stuck fast. It isn't coming off.")

/**
 * Everything the chicken mask does to its wearer.
 */
/datum/component/chicken_rampage
	/// The mask that gave us this.
	var/obj/item/clothing/mask/chicken_rampage/mask
	/// Current combo. Uncapped.
	var/combo = 0
	/// world.time the combo runs out at.
	var/combo_expires = 0
	/// Last mob we got a combo point from and when, so a shotgun blast only counts as one hit on each target.
	var/datum/weakref/last_combo_target
	var/last_combo_time = 0
	/// Last time getting hit cut our combo timer, so a shotgun blast only counts once.
	var/last_hurt_time = 0
	/// The click cooldown multiplier we've applied to the wearer, so we can take it back off exactly.
	var/applied_click_modifier = 1
	/// The combo counter on the wearer's screen.
	var/atom/movable/screen/rampage_combo/combo_display
	/// The music coming out of the wearer.
	var/datum/rampage_music/music

/datum/component/chicken_rampage/Initialize(obj/item/clothing/mask/chicken_rampage/mask)
	if(!isliving(parent) || QDELETED(mask))
		return COMPONENT_INCOMPATIBLE
	src.mask = mask
	// However the mask leaves the wearer's face, the rampage (and its music) ends with it.
	RegisterSignals(mask, list(COMSIG_QDELETING, COMSIG_ITEM_POST_UNEQUIP), PROC_REF(on_mask_lost))

/datum/component/chicken_rampage/RegisterWithParent()
	var/mob/living/wearer = parent
	wearer.add_traits(list(TRAIT_NOSOFTCRIT, TRAIT_BRUTAL_THROWER, TRAIT_RAMPAGE_EXECUTIONER), CHICKEN_MASK_TRAIT)
	wearer.AddComponentFrom(CHICKEN_MASK_TRAIT, /datum/component/ultraviolence)
	update_combo_bonuses()

	combo_display = new
	wearer.client?.screen += combo_display
	music = new(wearer)
	update_music()

	RegisterSignal(wearer, COMSIG_MOB_ATTACK_LANDED, PROC_REF(on_attack_landed))
	RegisterSignal(wearer, COMSIG_MOB_ULTRAVIOLENCE_EXECUTION, PROC_REF(on_execution))
	RegisterSignal(wearer, COMSIG_MOB_AFTER_APPLY_DAMAGE, PROC_REF(on_damaged))
	RegisterSignal(wearer, COMSIG_LIVING_HEALTH_UPDATE, PROC_REF(update_music))
	RegisterSignal(wearer, COMSIG_LIVING_DEATH, PROC_REF(on_death))
	RegisterSignal(wearer, COMSIG_LIVING_REVIVE, PROC_REF(update_music))
	RegisterSignal(wearer, COMSIG_MOB_LOGIN, PROC_REF(on_login))

	to_chat(wearer, span_userdanger("The mask tightens around your head. It isn't coming off. <i>Do you like hurting other people?</i>"))

/datum/component/chicken_rampage/UnregisterFromParent()
	var/mob/living/wearer = parent
	UnregisterSignal(wearer, list(
		COMSIG_MOB_ATTACK_LANDED,
		COMSIG_MOB_ULTRAVIOLENCE_EXECUTION,
		COMSIG_MOB_AFTER_APPLY_DAMAGE,
		COMSIG_LIVING_HEALTH_UPDATE,
		COMSIG_LIVING_DEATH,
		COMSIG_LIVING_REVIVE,
		COMSIG_MOB_LOGIN,
	))
	wearer.remove_traits(list(TRAIT_NOSOFTCRIT, TRAIT_BRUTAL_THROWER, TRAIT_RAMPAGE_EXECUTIONER), CHICKEN_MASK_TRAIT)
	wearer.RemoveComponentSource(CHICKEN_MASK_TRAIT, /datum/component/ultraviolence)
	wearer.remove_movespeed_modifier(/datum/movespeed_modifier/chicken_rampage)
	wearer.next_move_modifier /= applied_click_modifier
	applied_click_modifier = 1
	wearer.client?.screen -= combo_display

/datum/component/chicken_rampage/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	var/mob/living/wearer = parent
	wearer?.client?.screen -= combo_display
	QDEL_NULL(combo_display)
	QDEL_NULL(music)
	if(mask)
		UnregisterSignal(mask, list(COMSIG_QDELETING, COMSIG_ITEM_POST_UNEQUIP))
		mask = null
	return ..()

/datum/component/chicken_rampage/proc/on_mask_lost(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/// Counts the combo down and makes the counter flash faster as it runs out.
/datum/component/chicken_rampage/process(seconds_per_tick)
	if(combo <= 0)
		return PROCESS_KILL
	var/time_left = combo_expires - world.time
	if(time_left <= 0)
		set_combo(0)
		return PROCESS_KILL
	combo_display?.set_time_left(time_left / RAMPAGE_COMBO_TIMEOUT)

/// Adds combo and refreshes the combo timer.
/datum/component/chicken_rampage/proc/add_combo(amount)
	set_combo(combo + amount)
	combo_expires = world.time + RAMPAGE_COMBO_TIMEOUT
	combo_display?.set_time_left(1)
	START_PROCESSING(SSfastprocess, src)

/// Every hit on something alive counts: melee, fists, guns, thrown stuff.
/datum/component/chicken_rampage/proc/on_attack_landed(mob/living/source, mob/living/target, damage_done, damagetype, def_zone, sharpness, atom/weapon)
	SIGNAL_HANDLER

	if(target == source || !isliving(target))
		return
	// Corpses don't count, unless this is the hit that killed them.
	if(target.stat == DEAD && target.timeofdeath != world.time)
		return
	var/datum/weakref/target_ref = WEAKREF(target)
	if(last_combo_target == target_ref && last_combo_time == world.time)
		return
	last_combo_target = target_ref
	last_combo_time = world.time
	add_combo(1)

/// Executions are worth extra combo and heal a percentage of max health equal to the combo.
/datum/component/chicken_rampage/proc/on_execution(mob/living/source, mob/living/carbon/victim)
	SIGNAL_HANDLER

	add_combo(RAMPAGE_EXECUTION_BONUS)
	var/heal_amount = source.maxHealth * combo / 100
	source.heal_ordered_damage(heal_amount, list(BRUTE, BURN, TOX, OXY))
	source.balloon_alert(source, "+[RAMPAGE_EXECUTION_BONUS] combo, healed [combo]%")

/// Getting hit eats into the time left on the combo.
/datum/component/chicken_rampage/proc/on_damaged(mob/living/source, damage_dealt, damagetype, def_zone, blocked, wound_bonus, bare_wound_bonus, sharpness, attack_direction, attacking_item, wound_clothing)
	SIGNAL_HANDLER

	if(combo <= 0 || damage_dealt <= 0 || last_hurt_time == world.time)
		return
	// Only actual attacks, not burning, bleeding or other damage over time.
	if(!attacking_item && !attack_direction)
		return
	last_hurt_time = world.time
	combo_expires -= RAMPAGE_HIT_TIMER_PENALTY

/datum/component/chicken_rampage/proc/set_combo(new_combo)
	combo = max(new_combo, 0)
	combo_display?.set_combo(combo)
	update_combo_bonuses()

/// Movement and click speed both scale with the combo.
/datum/component/chicken_rampage/proc/update_combo_bonuses()
	var/mob/living/wearer = parent
	var/speed = RAMPAGE_BASE_SPEED + combo * RAMPAGE_SPEED_PER_COMBO
	wearer.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/chicken_rampage, multiplicative_slowdown = -speed)

	var/click_modifier = max(1 - combo * RAMPAGE_CLICK_SPEED_PER_COMBO, RAMPAGE_MIN_CLICK_MODIFIER)
	wearer.next_move_modifier *= click_modifier / applied_click_modifier
	applied_click_modifier = click_modifier

/// Picks the song for how hurt the wearer is.
/datum/component/chicken_rampage/proc/update_music()
	SIGNAL_HANDLER

	var/mob/living/wearer = parent
	if(!music)
		return
	if(wearer.stat == DEAD || QDELETED(wearer))
		music.stop(immediate = TRUE)
		return
	var/health_percent = wearer.maxHealth ? (wearer.health / wearer.maxHealth) * 100 : 0
	if(wearer.stat >= SOFT_CRIT || wearer.health <= HEALTH_THRESHOLD_CRIT)
		music.play('surfshack13/sound/chicken_mask/health_dying.ogg')
	else if(health_percent >= 85)
		music.play('surfshack13/sound/chicken_mask/health_full.ogg')
	else if(health_percent >= 50)
		music.play('surfshack13/sound/chicken_mask/health_hurt.ogg')
	else
		music.play('surfshack13/sound/chicken_mask/health_wounded.ogg')

/datum/component/chicken_rampage/proc/on_death(mob/living/source, gibbed)
	SIGNAL_HANDLER
	set_combo(0)
	STOP_PROCESSING(SSfastprocess, src)
	music?.stop(immediate = TRUE)

/datum/component/chicken_rampage/proc/on_login(mob/living/source)
	SIGNAL_HANDLER
	source.client?.screen |= combo_display

/datum/movespeed_modifier/chicken_rampage
	variable = TRUE

/**
 * Called from /mob/living/hitby() when a bulky or bigger item thrown by someone with TRAIT_BRUTAL_THROWER hits us.
 * Sometimes knocks us down, sometimes leaves us dazed, sometimes nothing.
 */
/mob/living/proc/brutal_throw_impact(obj/item/thrown_item, mob/thrower)
	if(prob(30))
		visible_message(span_danger("[src] is knocked off [p_their()] feet by [thrown_item]!"), span_userdanger("[thrown_item] knocks you off your feet!"))
		Knockdown(2 SECONDS)
	else if(prob(45))
		visible_message(span_danger("[src] reels from the impact of [thrown_item]!"), span_userdanger("[thrown_item] leaves you dazed!"))
		adjust_staggered_up_to(3 SECONDS, 6 SECONDS)
		set_confusion_if_lower(3 SECONDS)
		set_dizzy_if_lower(4 SECONDS)

/**
 * The box the chicken mask comes in. Looks like any other cardboard box, except it won't stop playing music
 * until the mask is taken out.
 */
/obj/item/storage/box/chicken_mask
	name = "cardboard box"
	desc = "A plain cardboard box. There's music coming from inside it."
	/// The song coming out of the box.
	var/datum/rampage_music/music

/obj/item/storage/box/chicken_mask/PopulateContents()
	new /obj/item/clothing/mask/chicken_rampage(src)

/obj/item/storage/box/chicken_mask/Initialize(mapload)
	. = ..()
	music = new(src, 9, 50, 25)
	update_music()

/obj/item/storage/box/chicken_mask/Destroy()
	QDEL_NULL(music)
	return ..()

/obj/item/storage/box/chicken_mask/Entered(atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	. = ..()
	if(istype(arrived, /obj/item/clothing/mask/chicken_rampage))
		update_music()

/obj/item/storage/box/chicken_mask/Exited(atom/movable/gone, direction)
	. = ..()
	if(istype(gone, /obj/item/clothing/mask/chicken_rampage))
		update_music()

/// Plays while the mask is inside.
/obj/item/storage/box/chicken_mask/proc/update_music()
	if(!music)
		return
	if(QDELETED(src))
		music.stop(immediate = TRUE)
		return
	if(locate(/obj/item/clothing/mask/chicken_rampage) in src)
		music.play('surfshack13/sound/chicken_mask/box.ogg')
	else
		music.stop()

/datum/uplink_item/dangerous/chicken_mask
	name = "Chicken Mask"
	desc = "A rubber chicken mask in a cardboard box that won't stop playing music. Once you put it on, it never comes off. \
			The wearer goes on a rampage: every hit builds a combo that makes you move and attack faster, kills turn into \
			a bloodbath, anyone who's down can be executed for extra combo and healing, thrown objects hit harder and you \
			shrug off soft crit. Music plays out of you, through walls, for everyone nearby to hear. They will know where you are."
	item = /obj/item/storage/box/chicken_mask
	cost = 20
	surplus = 0
	purchasable_from = UPLINK_TRAITORS

#undef CHICKEN_MASK_TRAIT
#undef RAMPAGE_COMBO_TIMEOUT
#undef RAMPAGE_HIT_TIMER_PENALTY
#undef RAMPAGE_EXECUTION_BONUS
#undef RAMPAGE_BASE_SPEED
#undef RAMPAGE_SPEED_PER_COMBO
#undef RAMPAGE_CLICK_SPEED_PER_COMBO
#undef RAMPAGE_MIN_CLICK_MODIFIER
