/// Trait source for everything the chicken mask applies.
#define CHICKEN_MASK_TRAIT "chicken_mask"
/// If TRUE, only hits on and executions of player-controlled mobs count towards the combo.
/// FALSE while testing so NPCs and monkeys count. MUST be TRUE before this is pushed/PR'd.
#define RAMPAGE_REQUIRE_SENTIENT_TARGETS FALSE
/// Time without landing a hit before the combo resets.
#define RAMPAGE_COMBO_TIMEOUT (12.5 SECONDS)
/// Getting hit takes this much off the time left on the combo.
#define RAMPAGE_HIT_TIMER_PENALTY (RAMPAGE_COMBO_TIMEOUT / 4)
/// Combo points for finishing an execution.
#define RAMPAGE_EXECUTION_BONUS 2
/// Speed boost just for wearing the mask.
#define RAMPAGE_BASE_SPEED 0.15
/// Speed boost at max, the same as stimulants.
#define RAMPAGE_MAX_SPEED 0.55
/// Combo at which the speed boost reaches RAMPAGE_MAX_SPEED. It ramps up evenly until then.
#define RAMPAGE_MAX_SPEED_COMBO 50
/// How far the wearer's music carries with no combo.
#define RAMPAGE_MUSIC_BASE_RANGE 15
/// How far the wearer's music carries at RAMPAGE_MUSIC_MAX_RANGE_COMBO combo and above.
#define RAMPAGE_MUSIC_MAX_RANGE 50
/// Combo at which the music reaches its max range.
#define RAMPAGE_MUSIC_MAX_RANGE_COMBO 100
/// Extra combo for a kill, on top of the point for the hit itself.
#define RAMPAGE_KILL_COMBO_BONUS 1
/// Score for a kill, multiplied by the combo.
#define RAMPAGE_KILL_POINTS 100
/// Score for an execution, multiplied by the combo.
#define RAMPAGE_EXECUTION_POINTS 250
/// Click cooldown reduction per point of combo.
#define RAMPAGE_CLICK_SPEED_PER_COMBO 0.01
/// Click cooldown floor. Effectively no limit (a melee cooldown at 1% is shorter than a server tick),
/// it only exists because the modifier is multiplied in and divided back out, and can't be zero.
#define RAMPAGE_MIN_CLICK_MODIFIER 0.01
/// Combo at which gaining combo starts having a chance to mend a wound.
#define RAMPAGE_WOUND_HEAL_MIN_COMBO 10
/// Chance to mend a wound per combo gain at RAMPAGE_WOUND_HEAL_MIN_COMBO.
#define RAMPAGE_WOUND_HEAL_MIN_CHANCE 35
/// Combo at which every combo gain mends a wound.
#define RAMPAGE_WOUND_HEAL_MAX_COMBO 50
/// Damage of every punch thrown by the mask's martial art.
#define RAMPAGE_PUNCH_DAMAGE 15
/// Melee armor at which punches only penetrate half of it. Below this they penetrate more, up to all of it against no armor.
#define RAMPAGE_PUNCH_HEAVY_ARMOR 50

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
	icon = 'surfshack13/icons/obj/clothing/chicken_mask.dmi'
	icon_state = "chicken_rampage"
	worn_icon = 'surfshack13/icons/mob/clothing/chicken_mask.dmi'
	worn_icon_state = "chicken_rampage"
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
	/// The mask's martial art, so punches never miss.
	var/datum/martial_art/chicken_rampage/martial
	/// This wearer's score and stats for the round end report.
	var/datum/rampage_record/record
	/// Timer that moves the playlist on to the next song.
	var/playlist_timer
	/// The last playlist song, so the shuffle never plays it twice in a row.
	var/last_song
	/// Are we playing the dying song instead of the playlist?
	var/playing_dying_song = FALSE
	COOLDOWN_DECLARE(door_kick_cooldown)

/datum/component/chicken_rampage/Initialize(obj/item/clothing/mask/chicken_rampage/mask)
	if(!isliving(parent) || QDELETED(mask))
		return COMPONENT_INCOMPATIBLE
	src.mask = mask
	// However the mask leaves the wearer's face, the rampage (and its music) ends with it.
	RegisterSignals(mask, list(COMSIG_QDELETING, COMSIG_ITEM_POST_UNEQUIP), PROC_REF(on_mask_lost))

/datum/component/chicken_rampage/RegisterWithParent()
	var/mob/living/wearer = parent
	wearer.add_traits(list(TRAIT_NOSOFTCRIT, TRAIT_ANALGESIA, TRAIT_BRUTAL_THROWER, TRAIT_RAMPAGE_EXECUTIONER), CHICKEN_MASK_TRAIT)
	wearer.AddComponentFrom(CHICKEN_MASK_TRAIT, /datum/component/ultraviolence)
	// Feels no pain, like morphine: no pain messages or shock, and injuries don't slow them down.
	wearer.add_movespeed_mod_immunities(CHICKEN_MASK_TRAIT, /datum/movespeed_modifier/damage_slowdown)
	record = get_rampage_record(wearer)
	update_combo_bonuses()
	// Temporary, so whatever martial art they had comes back if the mask ever comes off.
	martial = new
	if(!martial.teach(wearer, make_temporary = TRUE))
		QDEL_NULL(martial)

	combo_display = new
	wearer.client?.screen += combo_display
	music = new(wearer, RAMPAGE_MUSIC_BASE_RANGE)
	update_music()

	RegisterSignal(wearer, COMSIG_MOB_ATTACK_LANDED, PROC_REF(on_attack_landed))
	RegisterSignal(wearer, COMSIG_MOB_ULTRAVIOLENCE_EXECUTION, PROC_REF(on_execution))
	RegisterSignal(wearer, COMSIG_MOB_AFTER_APPLY_DAMAGE, PROC_REF(on_damaged))
	RegisterSignal(wearer, COMSIG_ATOM_HITBY, PROC_REF(on_hit_by_thrown))
	RegisterSignal(wearer, COMSIG_LIVING_HEALTH_UPDATE, PROC_REF(update_music))
	RegisterSignal(wearer, COMSIG_LIVING_DEATH, PROC_REF(on_death))
	RegisterSignal(wearer, COMSIG_LIVING_REVIVE, PROC_REF(update_music))
	RegisterSignal(wearer, COMSIG_MOB_LOGIN, PROC_REF(on_login))
	RegisterSignal(wearer, COMSIG_LIVING_UNARMED_ATTACK, PROC_REF(on_unarmed_kick))
	RegisterSignal(wearer, COMSIG_USER_ITEM_INTERACTION_SECONDARY, PROC_REF(on_item_kick))

	to_chat(wearer, span_userdanger("The mask tightens around your head. It isn't coming off. <i>Do you like hurting other people?</i>"))

/datum/component/chicken_rampage/UnregisterFromParent()
	var/mob/living/wearer = parent
	UnregisterSignal(wearer, list(
		COMSIG_MOB_ATTACK_LANDED,
		COMSIG_MOB_ULTRAVIOLENCE_EXECUTION,
		COMSIG_MOB_AFTER_APPLY_DAMAGE,
		COMSIG_ATOM_HITBY,
		COMSIG_LIVING_HEALTH_UPDATE,
		COMSIG_LIVING_DEATH,
		COMSIG_LIVING_REVIVE,
		COMSIG_MOB_LOGIN,
		COMSIG_LIVING_UNARMED_ATTACK,
		COMSIG_USER_ITEM_INTERACTION_SECONDARY,
	))
	wearer.remove_traits(list(TRAIT_NOSOFTCRIT, TRAIT_ANALGESIA, TRAIT_BRUTAL_THROWER, TRAIT_RAMPAGE_EXECUTIONER), CHICKEN_MASK_TRAIT)
	wearer.RemoveComponentSource(CHICKEN_MASK_TRAIT, /datum/component/ultraviolence)
	wearer.remove_movespeed_modifier(/datum/movespeed_modifier/chicken_rampage)
	wearer.remove_movespeed_mod_immunities(CHICKEN_MASK_TRAIT, /datum/movespeed_modifier/damage_slowdown)
	wearer.next_move_modifier /= applied_click_modifier
	applied_click_modifier = 1
	wearer.client?.screen -= combo_display
	martial?.fully_remove(wearer)
	martial = null

/datum/component/chicken_rampage/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	stop_playlist()
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
	try_mend_wound()

/**
 * From RAMPAGE_WOUND_HEAL_MIN_COMBO combo on, every combo gain has a chance to close one of the wearer's wounds:
 * RAMPAGE_WOUND_HEAL_MIN_CHANCE at the start, rising evenly to 100% at RAMPAGE_WOUND_HEAL_MAX_COMBO.
 */
/datum/component/chicken_rampage/proc/try_mend_wound()
	if(combo < RAMPAGE_WOUND_HEAL_MIN_COMBO || !iscarbon(parent))
		return
	var/mob/living/carbon/wearer = parent
	if(!LAZYLEN(wearer.all_wounds))
		return
	var/progress = min((combo - RAMPAGE_WOUND_HEAL_MIN_COMBO) / (RAMPAGE_WOUND_HEAL_MAX_COMBO - RAMPAGE_WOUND_HEAL_MIN_COMBO), 1)
	if(!prob(RAMPAGE_WOUND_HEAL_MIN_CHANCE + (100 - RAMPAGE_WOUND_HEAL_MIN_CHANCE) * progress))
		return
	var/datum/wound/mended = pick(wearer.all_wounds)
	to_chat(wearer, span_notice("The adrenaline shuts out your [LOWER_TEXT(mended.name)]. It's gone."))
	mended.remove_wound()

/// Every hit on something alive counts: melee, fists, guns, thrown stuff.
/datum/component/chicken_rampage/proc/on_attack_landed(mob/living/source, mob/living/target, damage_done, damagetype, def_zone, sharpness, atom/weapon)
	SIGNAL_HANDLER

	if(target == source || !isliving(target) || !is_sentient_player(target))
		return
	// The execution gunshot is paid out by on_execution() instead.
	var/datum/component/ultraviolence/violence = source.GetComponent(/datum/component/ultraviolence)
	if(violence?.executing)
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

	// That hit killed them: bonus combo, and points multiplied by the combo.
	if(target.stat == DEAD)
		add_combo(RAMPAGE_KILL_COMBO_BONUS)
		record?.kills++
		award_points(RAMPAGE_KILL_POINTS, target)

/// Adds points to the wearer's score, multiplied by the current combo, and pops them up over the victim.
/datum/component/chicken_rampage/proc/award_points(base_points, atom/where)
	var/points = base_points * max(combo, 1)
	if(record)
		record.score += points
	where?.balloon_alert(parent, "+[points]")

/// Only players count towards the combo: no monkeys, no NPCs, no mindless bodies.
/datum/component/chicken_rampage/proc/is_sentient_player(mob/living/target)
	if(!RAMPAGE_REQUIRE_SENTIENT_TARGETS)
		return TRUE
	return !isnull(target.mind?.key)

/// Executions of players are worth extra combo, points multiplied by the combo, and heal a percentage of max health equal to the combo.
/datum/component/chicken_rampage/proc/on_execution(mob/living/source, mob/living/carbon/victim, was_alive)
	SIGNAL_HANDLER

	if(!is_sentient_player(victim))
		return
	add_combo(RAMPAGE_EXECUTION_BONUS)
	record?.executions++
	award_points(RAMPAGE_EXECUTION_POINTS, victim)
	var/heal_amount = source.maxHealth * combo / 100
	source.heal_ordered_damage(heal_amount, list(BRUTE, BURN, TOX, OXY))
	to_chat(source, span_notice("+[RAMPAGE_EXECUTION_BONUS] combo, healed [combo]%."))

/// Getting hit eats into the time left on the combo.
/datum/component/chicken_rampage/proc/on_damaged(mob/living/source, damage_dealt, damagetype, def_zone, blocked, wound_bonus, bare_wound_bonus, sharpness, attack_direction, attacking_item, wound_clothing)
	SIGNAL_HANDLER

	if(damage_dealt <= 0)
		return
	// Only actual attacks, not burning, bleeding or other damage over time. Thrown things are handled by on_hit_by_thrown().
	if(!attacking_item && !attack_direction)
		return
	lose_combo_time()

/// Getting hit by a thrown object also eats into the combo timer.
/datum/component/chicken_rampage/proc/on_hit_by_thrown(mob/living/source, atom/movable/hitting_atom, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER

	if(blocked || !isitem(hitting_atom))
		return
	var/obj/item/thrown_item = hitting_atom
	if(thrown_item.throwforce <= 0)
		return
	lose_combo_time()

/// Takes RAMPAGE_HIT_TIMER_PENALTY off the combo timer, at most once per tick so a shotgun blast counts once.
/datum/component/chicken_rampage/proc/lose_combo_time()
	if(combo <= 0 || last_hurt_time == world.time)
		return
	last_hurt_time = world.time
	combo_expires -= RAMPAGE_HIT_TIMER_PENALTY

/datum/component/chicken_rampage/proc/set_combo(new_combo)
	combo = max(new_combo, 0)
	if(record)
		record.best_combo = max(record.best_combo, combo)
	combo_display?.set_combo(combo)
	update_combo_bonuses()

/// Movement speed, click speed and how far the music carries all scale with the combo.
/datum/component/chicken_rampage/proc/update_combo_bonuses()
	if(music)
		music.range = round(RAMPAGE_MUSIC_BASE_RANGE + (RAMPAGE_MUSIC_MAX_RANGE - RAMPAGE_MUSIC_BASE_RANGE) * min(combo / RAMPAGE_MUSIC_MAX_RANGE_COMBO, 1))

	var/mob/living/wearer = parent
	var/speed = RAMPAGE_BASE_SPEED + (RAMPAGE_MAX_SPEED - RAMPAGE_BASE_SPEED) * min(combo / RAMPAGE_MAX_SPEED_COMBO, 1)
	wearer.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/chicken_rampage, multiplicative_slowdown = -speed)

	var/click_modifier = max(1 - combo * RAMPAGE_CLICK_SPEED_PER_COMBO, RAMPAGE_MIN_CLICK_MODIFIER)
	wearer.next_move_modifier *= click_modifier / applied_click_modifier
	applied_click_modifier = click_modifier

/**
 * Keeps the right music going. Normally a shuffled playlist that never plays the same song twice in a row;
 * in crit it switches to the dying song until they either die (silence) or pull through (back to the playlist).
 */
/datum/component/chicken_rampage/proc/update_music()
	SIGNAL_HANDLER

	var/mob/living/wearer = parent
	if(!music)
		return
	if(wearer.stat == DEAD || QDELETED(wearer))
		stop_playlist()
		playing_dying_song = FALSE
		music.stop(immediate = TRUE)
		return
	if(wearer.stat >= SOFT_CRIT || wearer.health <= HEALTH_THRESHOLD_CRIT)
		if(!playing_dying_song)
			stop_playlist()
			playing_dying_song = TRUE
			music.play('surfshack13/sound/chicken_mask/health_dying.ogg')
		return
	if(playing_dying_song || !playlist_timer || !music.is_playing())
		playing_dying_song = FALSE
		next_song()

/// Crossfades into a random playlist song that isn't the one that just played, and queues the one after it.
/datum/component/chicken_rampage/proc/next_song()
	if(QDELETED(src) || !music)
		return
	// Song file = length in deciseconds.
	var/static/list/playlist = list(
		'surfshack13/sound/chicken_mask/health_full.ogg' = 295.6 SECONDS,
		'surfshack13/sound/chicken_mask/health_hurt.ogg' = 231.6 SECONDS,
		'surfshack13/sound/chicken_mask/health_wounded.ogg' = 257.5 SECONDS,
	)
	var/list/choices = playlist.Copy()
	choices -= last_song
	var/song = pick(choices)
	last_song = song
	music.play(song)
	// Start fading into the next song just before this one ends.
	deltimer(playlist_timer)
	playlist_timer = addtimer(CALLBACK(src, PROC_REF(next_song)), max(playlist[song] - music.fade_time, 1 SECONDS), TIMER_STOPPABLE)

/// Stops the playlist from queueing its next song.
/datum/component/chicken_rampage/proc/stop_playlist()
	deltimer(playlist_timer)
	playlist_timer = null

/datum/component/chicken_rampage/proc/on_death(mob/living/source, gibbed)
	SIGNAL_HANDLER
	set_combo(0)
	STOP_PROCESSING(SSfastprocess, src)
	stop_playlist()
	playing_dying_song = FALSE
	music?.stop(immediate = TRUE)

/datum/component/chicken_rampage/proc/on_login(mob/living/source)
	SIGNAL_HANDLER
	source.client?.screen |= combo_display

/datum/movespeed_modifier/chicken_rampage
	variable = TRUE

/**
 * The chicken mask's fighting style: every punch lands where you aim it and hits for a flat RAMPAGE_PUNCH_DAMAGE.
 * Only works while wearing the mask, so it's inert if it somehow ends up in another body.
 */
/datum/martial_art/chicken_rampage
	name = "Rampage"
	id = "chicken_rampage"
	allow_temp_override = FALSE

/**
 * Punches go through armor, but the heavier the armor the less of it they ignore.
 * No armor: fully penetrated. At RAMPAGE_PUNCH_HEAVY_ARMOR melee armor or more: only half of it is ignored.
 *
 * Returns the percentage of damage the armor still blocks.
 */
/datum/martial_art/chicken_rampage/proc/get_punch_armor_block(mob/living/defender, zone)
	var/armor = defender.run_armor_check(zone, MELEE, silent = TRUE)
	if(armor <= 0)
		return armor
	var/penetration = 1 - 0.5 * clamp(armor / RAMPAGE_PUNCH_HEAVY_ARMOR, 0, 1)
	var/blocked = min(armor * (1 - penetration), ARMOR_MAX_BLOCK)
	to_chat(defender, span_warning("The punch smashes straight through your armor!"))
	return blocked

/datum/martial_art/chicken_rampage/can_use(mob/living/martial_artist)
	return !!martial_artist.GetComponent(/datum/component/chicken_rampage)

/datum/martial_art/chicken_rampage/harm_act(mob/living/attacker, mob/living/defender)
	// Executions take priority over punching.
	var/datum/component/ultraviolence/violence = attacker.GetComponent(/datum/component/ultraviolence)
	if(violence && (violence.executing || violence.can_execute(attacker, defender)))
		return MARTIAL_ATTACK_INVALID

	var/attack_type = attacker.get_attack_type()
	if(defender.check_block(attacker, RAMPAGE_PUNCH_DAMAGE, "[attacker]'s punch", UNARMED_ATTACK, 0, attack_type))
		return MARTIAL_ATTACK_FAIL

	var/zone = check_zone(attacker.zone_selected)
	if(!defender.get_bodypart(zone) && iscarbon(defender))
		zone = BODY_ZONE_CHEST
	var/armor_block = get_punch_armor_block(defender, zone)
	attacker.do_attack_animation(defender, ATTACK_EFFECT_PUNCH)
	playsound(defender, 'sound/items/weapons/punch1.ogg', 50, TRUE, -1)
	defender.visible_message(
		span_danger("[attacker] punches [defender] in the [parse_zone(zone)]!"),
		span_userdanger("[attacker] punches you in the [parse_zone(zone)]!"),
		span_hear("You hear a sickening sound of flesh hitting flesh!"),
		COMBAT_MESSAGE_RANGE,
		attacker,
	)
	to_chat(attacker, span_danger("You punch [defender] in the [parse_zone(zone)]!"))
	defender.lastattacker = attacker.real_name
	defender.lastattackerckey = attacker.ckey
	var/damage_done = defender.apply_damage(RAMPAGE_PUNCH_DAMAGE, attack_type, zone, armor_block, attack_direction = get_dir(attacker, defender))
	log_combat(attacker, defender, "punched (Rampage)")
	if(damage_done > 0)
		SEND_SIGNAL(attacker, COMSIG_MOB_ATTACK_LANDED, defender, damage_done, attack_type, zone, NONE, null)
	return MARTIAL_ATTACK_SUCCESS

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
	name = "Suspicious Chicken Mask"
	desc = "A cardboard box, left on your doorstep. No return address, no note, just a rubber chicken mask and \
			a tape deck that won't stop playing. Once it's on, it stays on. Chain your hits and you get faster, \
			finish anyone who hits the floor, and the music never stops. Everyone will hear you coming."
	item = /obj/item/storage/box/chicken_mask
	cost = 20
	surplus = 0
	purchasable_from = UPLINK_TRAITORS

#undef CHICKEN_MASK_TRAIT
#undef RAMPAGE_REQUIRE_SENTIENT_TARGETS
#undef RAMPAGE_COMBO_TIMEOUT
#undef RAMPAGE_HIT_TIMER_PENALTY
#undef RAMPAGE_EXECUTION_BONUS
#undef RAMPAGE_BASE_SPEED
#undef RAMPAGE_MAX_SPEED
#undef RAMPAGE_MAX_SPEED_COMBO
#undef RAMPAGE_MUSIC_BASE_RANGE
#undef RAMPAGE_MUSIC_MAX_RANGE
#undef RAMPAGE_MUSIC_MAX_RANGE_COMBO
#undef RAMPAGE_KILL_COMBO_BONUS
#undef RAMPAGE_KILL_POINTS
#undef RAMPAGE_EXECUTION_POINTS
#undef RAMPAGE_CLICK_SPEED_PER_COMBO
#undef RAMPAGE_MIN_CLICK_MODIFIER
#undef RAMPAGE_PUNCH_DAMAGE
#undef RAMPAGE_WOUND_HEAL_MIN_COMBO
#undef RAMPAGE_WOUND_HEAL_MIN_CHANCE
#undef RAMPAGE_WOUND_HEAL_MAX_COMBO
#undef RAMPAGE_PUNCH_HEAVY_ARMOR
