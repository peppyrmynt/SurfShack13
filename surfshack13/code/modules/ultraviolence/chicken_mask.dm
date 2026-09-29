/// Trait source for everything the chicken mask applies.
#define CHICKEN_MASK_TRAIT "chicken_mask"
/// Time without landing a hit before the combo resets.
#define RAMPAGE_COMBO_TIMEOUT (12.5 SECONDS)
/// Speed boost just for wearing the mask.
#define RAMPAGE_BASE_SPEED 0.15
/// Extra speed per point of combo.
#define RAMPAGE_SPEED_PER_COMBO 0.025
/// Speed boost can't go past this, around the same as stimulants.
#define RAMPAGE_MAX_SPEED 0.55

/**
 * The chicken mask.
 *
 * Once it's on, it doesn't come off. The wearer goes on a rampage: gory kills, a combo counter, a speed boost that
 * grows with the combo, no soft crit, harder throws, and music that plays out of them, through walls, changing with their health.
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
	/// Current combo.
	var/combo = 0
	/// Timer that resets the combo.
	var/combo_timer
	/// Last mob we got a combo point from and when, so a shotgun blast only counts as one hit on each target.
	var/datum/weakref/last_combo_target
	var/last_combo_time = 0
	/// The combo counter on the wearer's screen.
	var/atom/movable/screen/rampage_combo/combo_display
	/// The music coming out of the wearer.
	var/datum/rampage_music/music

/datum/component/chicken_rampage/Initialize(obj/item/clothing/mask/chicken_rampage/mask)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	src.mask = mask

/datum/component/chicken_rampage/RegisterWithParent()
	var/mob/living/wearer = parent
	wearer.add_traits(list(TRAIT_NOSOFTCRIT, TRAIT_BRUTAL_THROWER), CHICKEN_MASK_TRAIT)
	wearer.AddComponentFrom(CHICKEN_MASK_TRAIT, /datum/component/ultraviolence)
	update_speed()

	combo_display = new
	wearer.client?.screen += combo_display
	music = new(wearer)
	update_music()

	RegisterSignal(wearer, COMSIG_MOB_ATTACK_LANDED, PROC_REF(on_attack_landed))
	RegisterSignal(wearer, COMSIG_LIVING_HEALTH_UPDATE, PROC_REF(update_music))
	RegisterSignal(wearer, COMSIG_LIVING_DEATH, PROC_REF(on_death))
	RegisterSignal(wearer, COMSIG_LIVING_REVIVE, PROC_REF(update_music))
	RegisterSignal(wearer, COMSIG_MOB_LOGIN, PROC_REF(on_login))

	to_chat(wearer, span_userdanger("The mask tightens around your head. It isn't coming off. <i>Do you like hurting other people?</i>"))

/datum/component/chicken_rampage/UnregisterFromParent()
	var/mob/living/wearer = parent
	UnregisterSignal(wearer, list(COMSIG_MOB_ATTACK_LANDED, COMSIG_LIVING_HEALTH_UPDATE, COMSIG_LIVING_DEATH, COMSIG_LIVING_REVIVE, COMSIG_MOB_LOGIN))
	wearer.remove_traits(list(TRAIT_NOSOFTCRIT, TRAIT_BRUTAL_THROWER), CHICKEN_MASK_TRAIT)
	wearer.RemoveComponentSource(CHICKEN_MASK_TRAIT, /datum/component/ultraviolence)
	wearer.remove_movespeed_modifier(/datum/movespeed_modifier/chicken_rampage)
	wearer.client?.screen -= combo_display

/datum/component/chicken_rampage/Destroy()
	deltimer(combo_timer)
	QDEL_NULL(combo_display)
	QDEL_NULL(music)
	mask = null
	return ..()

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
	set_combo(combo + 1)
	combo_timer = addtimer(CALLBACK(src, PROC_REF(set_combo), 0), RAMPAGE_COMBO_TIMEOUT, TIMER_STOPPABLE|TIMER_UNIQUE|TIMER_OVERRIDE)

/datum/component/chicken_rampage/proc/set_combo(new_combo)
	combo = max(new_combo, 0)
	combo_display?.set_combo(combo)
	update_speed()

/// Faster the higher the combo goes.
/datum/component/chicken_rampage/proc/update_speed()
	var/mob/living/wearer = parent
	var/speed = min(RAMPAGE_BASE_SPEED + combo * RAMPAGE_SPEED_PER_COMBO, RAMPAGE_MAX_SPEED)
	wearer.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/chicken_rampage, multiplicative_slowdown = -speed)

/// Picks the song for how hurt the wearer is.
/datum/component/chicken_rampage/proc/update_music()
	SIGNAL_HANDLER

	var/mob/living/wearer = parent
	if(!music)
		return
	if(wearer.stat == DEAD)
		music.stop()
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
	deltimer(combo_timer)
	set_combo(0)
	music?.stop()

/datum/component/chicken_rampage/proc/on_login(mob/living/source)
	SIGNAL_HANDLER
	source.client?.screen |= combo_display

/datum/movespeed_modifier/chicken_rampage
	variable = TRUE

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
	if(locate(/obj/item/clothing/mask/chicken_rampage) in src)
		music.play('surfshack13/sound/chicken_mask/box.ogg')
	else
		music.stop()

/datum/uplink_item/dangerous/chicken_mask
	name = "Chicken Mask"
	desc = "A rubber chicken mask in a cardboard box that won't stop playing music. Once you put it on, it never comes off. \
			The wearer goes on a rampage: every hit builds a combo that makes you faster, kills turn into a bloodbath, \
			downed targets can be executed, thrown objects hit harder and you shrug off soft crit. \
			Music plays out of you, through walls, for everyone nearby to hear. They will know where you are."
	item = /obj/item/storage/box/chicken_mask
	cost = 20
	surplus = 0
	purchasable_from = UPLINK_TRAITORS

#undef CHICKEN_MASK_TRAIT
#undef RAMPAGE_COMBO_TIMEOUT
#undef RAMPAGE_BASE_SPEED
#undef RAMPAGE_SPEED_PER_COMBO
#undef RAMPAGE_MAX_SPEED
