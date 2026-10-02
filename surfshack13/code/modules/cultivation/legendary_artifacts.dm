/**
 * Legendary weapons and treasures from Chinese legend and the martial novels.
 * One turns up somewhere in maintenance each round. Any of them can be bound with Returning Iron.
 *
 * They are meant to stand level with (or above) a Primordial Chaos Body: every hit from a legendary artifact is true damage that
 * ignores tempered flesh, Iron Shirt and the Vajra Golden Body, cracks those defences off, knocks the breath out of a body cultivator
 * (exhaustion), and hits harder the more tempered the body is. Nobody braces against them by realm. Refining a bound artifact makes it stronger still.
 */

/obj/item/cultivation_artifact
	icon = 'surfshack13/icons/cultivation/cultivation_artifacts.dmi'
	resistance_flags = INDESTRUCTIBLE | FIRE_PROOF | ACID_PROOF | LAVA_PROOF
	/// Shown on examine to cultivators
	var/legend = ""
	/// What its active power does, shown on examine to everyone
	var/power_text = ""

/obj/item/cultivation_artifact/examine(mob/user)
	. = ..()
	if(power_text)
		. += span_notice("[power_text]")
	. += span_notice("Its blows are true damage that ignore any body's tempering, and shatter Iron Shirt and the Vajra Golden Body.")
	if(legend && (IS_CULTIVATOR(user) || IS_BODY_CULTIVATOR(user) || isobserver(user)))
		. += span_notice("<i>[legend]</i>")

/// How much stronger a bound, refined artifact hits: +10% per refinement grade
/proc/legendary_power(obj/item/artifact)
	var/datum/component/cultivation_artifact/bond = artifact?.GetComponent(/datum/component/cultivation_artifact)
	return 1 + (bond ? 0.1 * bond.refinement : 0)

/**
 * A legendary blow. True damage (no armour, no damage reduction, no realm bracing), heavier against tempered bodies,
 * and it breaks a body cultivator's protective techniques and knocks the wind out of them.
 */
/proc/legendary_hit(mob/living/user, mob/living/victim, damage, knockdown = 0, source_name = "a legendary artifact", obj/item/artifact)
	if(QDELETED(victim) || victim == user || victim.stat == DEAD)
		return FALSE
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(victim)
	if(body_datum?.stage)
		damage += 3 * body_datum.stage
		var/broke_defence = victim.has_status_effect(/datum/status_effect/body_iron_shirt) || victim.has_status_effect(/datum/status_effect/body_vajra)
		victim.remove_status_effect(/datum/status_effect/body_iron_shirt)
		victim.remove_status_effect(/datum/status_effect/body_vajra)
		victim.remove_status_effect(/datum/status_effect/body_blood_boil)
		body_datum.add_exhaustion(10 + 2 * body_datum.stage)
		new /obj/effect/temp_visual/cultivation_spark(get_turf(victim), "#ffffff", rand(-6, 6), rand(0, 10))
		if(broke_defence)
			victim.visible_message(span_danger("[source_name] shatters [victim]'s golden body like glass!"), span_userdanger("[source_name] cracks your tempered body open!"))
	victim.apply_damage(damage * legendary_power(artifact), BRUTE, forced = TRUE, wound_bonus = 10)
	if(knockdown)
		victim.Knockdown(knockdown)
	log_combat(user, victim, "struck with [source_name]")
	return TRUE

// ===================== Ganjiang and Moye =====================

/obj/item/cultivation_artifact/twin_sword
	icon_state = "ganjiang"
	inhand_icon_state = "sabre"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 22
	throwforce = 18
	armour_penetration = 40
	w_class = WEIGHT_CLASS_NORMAL
	sharpness = SHARP_EDGED
	attack_verb_continuous = list("slashes", "cuts", "pierces")
	attack_verb_simple = list("slash", "cut", "pierce")
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	block_chance = 30
	legend = "The swordsmith Ganjiang and his wife Moye forged a pair of swords, one male and one female. Held together, they long for each other."
	power_text = "Held together, the pair strike twice as hard, parry far more, and can be used in hand to unleash the Twin Dragon Sword Storm: five seconds of slashing everything around you."
	/// The other sword type of the pair
	var/partner_type = /obj/item/cultivation_artifact/twin_sword/moye
	COOLDOWN_DECLARE(storm_cooldown)

/obj/item/cultivation_artifact/twin_sword/ganjiang
	name = "Ganjiang"
	desc = "A dark blue-black jian, the male sword of the legendary pair."

/obj/item/cultivation_artifact/twin_sword/moye
	name = "Moye"
	desc = "A pale silver jian with a red tassel, the female sword of the legendary pair."
	icon_state = "moye"
	partner_type = /obj/item/cultivation_artifact/twin_sword/ganjiang

/obj/item/cultivation_artifact/twin_sword/proc/paired(mob/living/user)
	return istype(user) && (locate(partner_type) in user.held_items)

/obj/item/cultivation_artifact/twin_sword/afterattack(atom/target, mob/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(!isliving(target))
		return
	var/mob/living/victim = target
	var/together = paired(user)
	legendary_hit(user, victim, together ? 12 : 5, 0, name, src)
	new /obj/effect/temp_visual/slash(get_turf(victim), victim, rand(10, 22), rand(10, 22), "#9fb8ff")
	if(together && prob(25))
		user.visible_message(span_danger("Ganjiang and Moye sing in harmony as [user] strikes!"))

/obj/item/cultivation_artifact/twin_sword/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK, damage_type = BRUTE)
	if(paired(owner))
		final_block_chance += 30
	return ..()

/obj/item/cultivation_artifact/twin_sword/attack_self(mob/user)
	if(!paired(user))
		to_chat(user, span_warning("A single sword can't sing alone. Hold both Ganjiang and Moye."))
		return
	for(var/obj/item/cultivation_artifact/twin_sword/sword in user.held_items)
		if(!COOLDOWN_FINISHED(sword, storm_cooldown))
			user.balloon_alert(user, "the swords are resting!")
			return
	for(var/obj/item/cultivation_artifact/twin_sword/sword in user.held_items)
		COOLDOWN_START(sword, storm_cooldown, 40 SECONDS)
	user.say("TWIN DRAGON SWORD STORM!!", forced = "ganjiang and moye")
	user.visible_message(span_boldwarning("[user] spins into a whirlwind of blue and silver steel!"))
	playsound(user, 'sound/effects/magic/repulse.ogg', 70, TRUE, frequency = 1.4)
	for(var/i in 0 to 9)
		addtimer(CALLBACK(src, PROC_REF(storm_tick), user), i * 0.5 SECONDS)

/obj/item/cultivation_artifact/twin_sword/proc/storm_tick(mob/living/user)
	if(QDELETED(user) || user.stat != CONSCIOUS || !paired(user))
		return
	user.SpinAnimation(4, 1)
	playsound(user, pick('sound/items/weapons/bladeslice.ogg', 'sound/items/weapons/slice.ogg'), 50, TRUE)
	for(var/mob/living/victim in range(2, user))
		if(victim == user || victim.stat == DEAD)
			continue
		new /obj/effect/temp_visual/slash(get_turf(victim), victim, rand(10, 22), rand(10, 22), pick("#9fb8ff", "#e8e8ff"))
		legendary_hit(user, victim, 8, 0, "Ganjiang and Moye", src)
	for(var/turf/nearby in range(1, user))
		for(var/obj/structure/window/window in nearby)
			window.take_damage(40, BRUTE, MELEE)

/obj/item/cultivation_artifact/twin_sword/equipped(mob/user, slot, initial)
	. = ..()
	update_pair_glow(user)

/obj/item/cultivation_artifact/twin_sword/dropped(mob/user, silent)
	. = ..()
	remove_filter("twin_glow")
	for(var/obj/item/cultivation_artifact/twin_sword/other in user?.held_items)
		other.remove_filter("twin_glow")

/obj/item/cultivation_artifact/twin_sword/proc/update_pair_glow(mob/living/user)
	if(!paired(user))
		return
	for(var/obj/item/cultivation_artifact/twin_sword/sword in user.held_items)
		sword.add_filter("twin_glow", 2, list("type" = "outline", "color" = "#c0d0ff", "size" = 1))
	to_chat(user, span_notice("Ganjiang and Moye hum as they are reunited."))

// ===================== Heaven Reliant Sword and Dragon Slaying Saber =====================

/obj/item/cultivation_artifact/heaven_reliant
	name = "Heaven Reliant Sword"
	desc = "A long, impossibly keen sword of pale jade-white steel. It cuts iron like mud: use it on a wall to carve straight through it, \
		and doors, windows and machines fall apart under it."
	icon_state = "heaven_reliant"
	inhand_icon_state = "katana"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 30
	throwforce = 20
	armour_penetration = 80
	w_class = WEIGHT_CLASS_BULKY
	sharpness = SHARP_EDGED
	block_chance = 30
	attack_verb_continuous = list("slices", "cleaves", "shears")
	attack_verb_simple = list("slice", "cleave", "shear")
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	legend = "\"Supreme in the martial world is the Dragon Slaying Saber. Who dares not obey? If the Heaven Reliant Sword does not appear, who can contend with it?\""
	power_text = "Click a distant spot to loose the Heaven-Cleaving Stroke: a blade of light fourteen tiles long and three wide that slices through people, doors and even reinforced walls."
	COOLDOWN_DECLARE(cleave_cooldown)

/obj/item/cultivation_artifact/heaven_reliant/afterattack(atom/target, mob/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(isliving(target))
		legendary_hit(user, target, 12, 0, name, src)
		return
	// It cuts through iron like mud: doors, windows, grilles, lockers and machines barely slow it down
	if(isobj(target) && !isitem(target))
		var/obj/cut = target
		if(!cut.uses_integrity || (cut.resistance_flags & INDESTRUCTIBLE))
			return
		cut.take_damage(force * 6, BRUTE, MELEE, armour_penetration = 100)
		new /obj/effect/temp_visual/slash(get_turf(cut), cut, rand(10, 22), rand(10, 22), "#d8fff0")

/// Walls are carved straight through, like mud
/obj/item/cultivation_artifact/heaven_reliant/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!iswallturf(interacting_with))
		return NONE
	INVOKE_ASYNC(src, PROC_REF(carve_wall), interacting_with, user)
	return ITEM_INTERACT_SUCCESS

/obj/item/cultivation_artifact/heaven_reliant/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!COOLDOWN_FINISHED(src, cleave_cooldown))
		user.balloon_alert(user, "the blade is gathering light!")
		return ITEM_INTERACT_BLOCKING
	var/direction = get_dir(user, interacting_with)
	if(!direction)
		return NONE
	COOLDOWN_START(src, cleave_cooldown, 20 SECONDS)
	user.say("HEAVEN-CLEAVING STROKE!!", forced = "heaven reliant sword")
	user.visible_message(span_boldwarning("[user] sweeps the Heaven Reliant Sword and a blade of pale light splits the air!"))
	user.do_attack_animation(get_step(user, direction))
	playsound(user, 'sound/items/weapons/bladeslice.ogg', 80, TRUE, frequency = 0.6)
	playsound(user, 'sound/effects/magic/repulse.ogg', 60, TRUE, frequency = 1.5)
	cultivation_distortion_wave(user, 3, 0.4 SECONDS, 200)
	body_art_shatter_line(user, get_turf(user), direction, 14, 1, 25, 2, name, 0.2, src)
	return ITEM_INTERACT_SUCCESS

/obj/item/cultivation_artifact/heaven_reliant/proc/carve_wall(turf/closed/wall/wall, mob/living/user)
	if(DOING_INTERACTION_WITH_TARGET(user, wall))
		return
	var/reinforced = istype(wall, /turf/closed/wall/r_wall)
	user.visible_message(span_warning("[user] draws the Heaven Reliant Sword across [wall]. The blade sinks into the metal like it's mud!"),
		span_notice("You begin carving through [wall]..."))
	playsound(wall, 'sound/items/weapons/bladeslice.ogg', 60, TRUE)
	var/carve_time = reinforced ? 2 SECONDS : 1 SECONDS
	if(!do_after(user, carve_time, wall))
		return
	new /obj/effect/temp_visual/slash(wall, null, 0, 0, "#d8fff0")
	do_sparks(2, FALSE, wall)
	if(QDELETED(wall) || !iswallturf(wall))
		return
	user.visible_message(span_boldwarning("[user] slices clean through [wall], which collapses into neat pieces!"))
	playsound(wall, 'sound/effects/meteorimpact.ogg', 40, TRUE)
	user.log_message("carved through [wall] at [AREACOORD(wall)] with the Heaven Reliant Sword", LOG_ATTACK)
	wall.dismantle_wall()

/obj/item/cultivation_artifact/dragon_saber
	name = "Dragon Slaying Saber"
	desc = "A massive black dao with a golden dragon coiled along the blade. Every blow lands like a falling mountain."
	icon_state = "dragon_saber"
	inhand_icon_state = "claymore"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 35
	throwforce = 25
	armour_penetration = 60
	w_class = WEIGHT_CLASS_BULKY
	sharpness = SHARP_EDGED
	attack_speed = CLICK_CD_MELEE * 1.3
	attack_verb_continuous = list("hacks", "cleaves", "crushes")
	attack_verb_simple = list("hack", "cleave", "crush")
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	legend = "\"Supreme in the martial world is the Dragon Slaying Saber.\" Legend says it holds a secret, revealed only when it meets the Heaven Reliant Sword."
	power_text = "Every blow hurls its target and cracks the floor. Use it in hand to wake the dragon: your next blow within ten seconds is the Dragon Slaying Strike, \
		a cataclysm that flattens everything within three tiles and brings down even reinforced walls."
	/// The dragon is awake: the next hit is the Dragon Slaying Strike
	var/dragon_awake = FALSE
	COOLDOWN_DECLARE(dragon_cooldown)

/obj/item/cultivation_artifact/dragon_saber/attack_self(mob/user)
	if(dragon_awake)
		return
	if(!COOLDOWN_FINISHED(src, dragon_cooldown))
		user.balloon_alert(user, "the dragon sleeps!")
		return
	COOLDOWN_START(src, dragon_cooldown, 30 SECONDS)
	dragon_awake = TRUE
	add_filter("dragon_awake", 2, list("type" = "outline", "color" = "#ffcc33", "size" = 2))
	user.visible_message(span_boldwarning("The golden dragon on [user]'s saber opens its eyes!"))
	playsound(user, 'sound/effects/magic/demon_dies.ogg', 50, TRUE, frequency = 0.5)
	addtimer(CALLBACK(src, PROC_REF(dragon_sleeps)), 10 SECONDS)

/obj/item/cultivation_artifact/dragon_saber/proc/dragon_sleeps()
	dragon_awake = FALSE
	remove_filter("dragon_awake")

/obj/item/cultivation_artifact/dragon_saber/afterattack(atom/target, mob/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(!isliving(target))
		return
	var/mob/living/victim = target
	if(dragon_awake)
		dragon_sleeps()
		dragon_slaying_strike(user, victim)
		return
	legendary_hit(user, victim, 15, 1 SECONDS, name, src)
	body_art_crack_ground(get_turf(victim), 0, 70, crater = FALSE)
	victim.Shake(2, 2, 0.4 SECONDS)
	victim.throw_at(get_edge_target_turf(victim, get_dir(user, victim)), 4, 2, user)

/obj/item/cultivation_artifact/dragon_saber/proc/dragon_slaying_strike(mob/living/user, mob/living/victim)
	var/turf/center = get_turf(victim)
	user.say("DRAGON SLAYING STRIKE!!", forced = "dragon slaying saber")
	user.visible_message(span_boldwarning("[user] brings the Dragon Slaying Saber down and a golden dragon erupts from the blade!"))
	playsound(center, 'sound/effects/explosion/explosion_distant.ogg', 90, TRUE)
	playsound(center, 'sound/effects/meteorimpact.ogg', 90, TRUE)
	cultivation_great_bell(center, 80)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(center)
	new /obj/effect/temp_visual/cultivation_crater(center, 2.5)
	cultivation_distortion_wave(victim, 7, 1 SECONDS, 255)
	body_art_crack_ground(center, 3, 70, crater = FALSE)
	legendary_hit(user, victim, 45, 3 SECONDS, "the Dragon Slaying Strike", src)
	for(var/turf/nearby in range(3, center))
		body_art_smash(nearby, user, 150, get_dist(nearby, center) <= 1 ? 2 : 0)
		if(prob(30))
			new /obj/effect/temp_visual/cultivation_rubble(nearby)
	for(var/mob/living/bystander in range(3, center))
		if(bystander == user || bystander == victim)
			continue
		legendary_hit(user, bystander, 15, 1.5 SECONDS, "the Dragon Slaying Strike", src)
		bystander.throw_at(get_edge_target_turf(bystander, get_dir(center, bystander)), 3, 2, user)
	for(var/mob/living/viewer in range(10, center))
		shake_camera(viewer, 6, 3)

/// The legend: strike the saber with the sword and both shatter, revealing the secret manuals hidden inside
/obj/item/cultivation_artifact/dragon_saber/attackby(obj/item/attacking_item, mob/user, list/modifiers)
	if(!istype(attacking_item, /obj/item/cultivation_artifact/heaven_reliant))
		return ..()
	if(tgui_alert(user, "Strike the Dragon Slaying Saber with the Heaven Reliant Sword? Both will shatter.", "The Secret of the Saber", list("Strike!", "No")) != "Strike!")
		return TRUE
	var/turf/clash = get_turf(src)
	user.visible_message(span_boldwarning("[user] brings the Heaven Reliant Sword down on the Dragon Slaying Saber! Both blades shatter, and something falls from within!"))
	playsound(clash, 'sound/effects/gong.ogg', 80, TRUE)
	playsound(clash, 'sound/effects/glass/glassbr3.ogg', 70, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(clash)
	new /obj/effect/spawner/random/cultivation_manual(clash)
	new /obj/effect/spawner/random/cultivation_manual(clash)
	new /obj/effect/spawner/random/wuxia_manual(clash)
	qdel(attacking_item)
	qdel(src)
	return TRUE

// ===================== Ruyi Jingu Bang =====================

/obj/item/cultivation_artifact/ruyi_jingu_bang
	name = "Ruyi Jingu Bang"
	desc = "The Monkey King's staff, shrunk to the size of a sewing needle. Use it in hand to make it grow."
	icon_state = "ruyi_needle"
	inhand_icon_state = "bostaff0"
	lefthand_file = 'icons/mob/inhands/weapons/staves_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/staves_righthand.dmi'
	w_class = WEIGHT_CLASS_TINY
	force = 2
	throwforce = 2
	legend = "The As-You-Will Gold-Banded Cudgel. It weighs thirteen thousand five hundred jin and grows or shrinks at its master's word."
	power_text = "Grown, it strikes three tiles away and sends people flying. Click a distant spot to stretch it to the heavens and bring it down: \
		the Thirteen-Thousand-Jin Slam smashes a three-wide path through everything, walls included, and craters where it lands."
	var/extended = FALSE
	COOLDOWN_DECLARE(slam_cooldown)

/obj/item/cultivation_artifact/ruyi_jingu_bang/attack_self(mob/user)
	extended = !extended
	if(extended)
		name = "Ruyi Jingu Bang"
		desc = "The Monkey King's staff, grown to full size. It reaches further than any normal weapon. Use it in hand to shrink it."
		icon_state = "ruyi_staff"
		inhand_icon_state = "bostaff1"
		w_class = WEIGHT_CLASS_HUGE
		force = 30
		throwforce = 20
		armour_penetration = 50
		reach = 3
		attack_verb_continuous = list("smashes", "whacks", "sends flying")
		attack_verb_simple = list("smash", "whack", "send flying")
		hitsound = 'sound/items/weapons/genhit3.ogg'
		user.visible_message(span_warning("[user] shouts \"Grow!\" and the needle in [user.p_their()] hand becomes a mighty golden-banded staff!"))
		user.say("Grow!", forced = "ruyi jingu bang")
	else
		desc = initial(desc)
		icon_state = initial(icon_state)
		inhand_icon_state = initial(inhand_icon_state)
		w_class = initial(w_class)
		force = initial(force)
		throwforce = initial(throwforce)
		armour_penetration = 0
		reach = 1
		user.visible_message(span_notice("[user]'s staff shrinks back down into a tiny golden needle."))
		user.say("Shrink!", forced = "ruyi jingu bang")
	playsound(src, 'sound/effects/magic/charge.ogg', 40, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold(get_turf(user))
	cultivation_particles(user, /particles/cultivation/gold, 1 SECONDS)
	update_appearance()
	user.update_held_items()

/obj/item/cultivation_artifact/ruyi_jingu_bang/afterattack(atom/target, mob/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(!extended || !isliving(target))
		return
	var/mob/living/victim = target
	// The Monkey King's own kin hit hardest
	legendary_hit(user, victim, ismonkey(user) ? 20 : 10, 0, name, src)
	if(prob(60))
		victim.throw_at(get_edge_target_turf(victim, get_dir(user, victim)), 5, 2, user)

/obj/item/cultivation_artifact/ruyi_jingu_bang/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!extended)
		return NONE
	if(!COOLDOWN_FINISHED(src, slam_cooldown))
		user.balloon_alert(user, "the staff is heavy!")
		return ITEM_INTERACT_BLOCKING
	var/turf/target_turf = get_turf(interacting_with)
	var/direction = get_dir(user, target_turf)
	var/distance = min(get_dist(user, target_turf), 10)
	if(!direction || distance < 2)
		return NONE
	COOLDOWN_START(src, slam_cooldown, 25 SECONDS)
	user.say("THIRTEEN THOUSAND JIN!!", forced = "ruyi jingu bang")
	user.visible_message(span_boldwarning("The Ruyi Jingu Bang shoots up to the heavens and comes crashing down!"))
	playsound(user, 'sound/effects/magic/charge.ogg', 70, TRUE, frequency = 0.6)
	cultivation_particles(user, /particles/cultivation/gold, 1.5 SECONDS)
	body_art_shatter_line(user, get_turf(user), direction, distance, 1, ismonkey(user) ? 35 : 25, 2, name, 0.15, src)
	addtimer(CALLBACK(src, PROC_REF(slam_end), user, target_turf), distance * 0.15 + 0.2 SECONDS)
	return ITEM_INTERACT_SUCCESS

/obj/item/cultivation_artifact/ruyi_jingu_bang/proc/slam_end(mob/living/user, turf/landing)
	playsound(landing, 'sound/effects/explosion/explosion_distant.ogg', 80, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(landing)
	new /obj/effect/temp_visual/cultivation_crater(landing, 2)
	body_art_crack_ground(landing, 2, 60, crater = FALSE)
	for(var/mob/living/victim in range(2, landing))
		if(victim != user)
			legendary_hit(user, victim, 15, 2 SECONDS, name, src)
	for(var/mob/living/viewer in range(8, landing))
		shake_camera(viewer, 4, 3)

// ===================== Purple-Gold Gourd =====================

/obj/item/cultivation_artifact/purple_gold_gourd
	name = "Purple-Gold Gourd"
	desc = "A purple calabash with a gold band and a red cork. Point it at someone and call their name. If they answer, they're inside."
	icon_state = "purple_gold_gourd"
	w_class = WEIGHT_CLASS_SMALL
	legend = "From the Journey to the West. Whoever answers when the gourd's holder calls their name is sucked inside, to be slowly dissolved."
	power_text = "No realm or body is too strong for it. Whoever is inside slowly dissolves, and a body cultivator's training melts away with them."
	/// Who we're waiting to hear from
	var/datum/weakref/target_ref
	/// Who's inside
	var/mob/living/prisoner
	COOLDOWN_DECLARE(call_cooldown)

/obj/item/cultivation_artifact/purple_gold_gourd/Destroy()
	release()
	return ..()

/obj/item/cultivation_artifact/purple_gold_gourd/examine(mob/user)
	. = ..()
	if(prisoner)
		. += span_warning("Something inside is thumping and shouting. Use it in hand to uncork it.")

/obj/item/cultivation_artifact/purple_gold_gourd/attack_self(mob/user)
	if(prisoner)
		user.visible_message(span_notice("[user] uncorks [src]!"))
		release()

/obj/item/cultivation_artifact/purple_gold_gourd/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	return interact_with_atom(interacting_with, user, modifiers)

/obj/item/cultivation_artifact/purple_gold_gourd/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isliving(interacting_with) || interacting_with == user)
		return NONE
	var/mob/living/victim = interacting_with
	if(prisoner)
		to_chat(user, span_warning("The gourd is already full!"))
		return ITEM_INTERACT_BLOCKING
	if(!COOLDOWN_FINISHED(src, call_cooldown))
		to_chat(user, span_warning("The gourd is still gathering its strength."))
		return ITEM_INTERACT_BLOCKING
	if(get_dist(user, victim) > 9)
		return ITEM_INTERACT_BLOCKING
	COOLDOWN_START(src, call_cooldown, 60 SECONDS)
	user.say("[uppertext(victim.real_name)]!", forced = "purple-gold gourd")
	user.visible_message(span_warning("[user] points a purple gourd at [victim] and calls [victim.p_their()] name!"))
	to_chat(victim, span_userdanger("[user] calls your name, pointing a purple gourd at you... You feel a strong urge to answer."))
	target_ref = WEAKREF(victim)
	RegisterSignal(victim, COMSIG_MOB_SAY, PROC_REF(on_answer))
	addtimer(CALLBACK(src, PROC_REF(stop_listening), victim), 6 SECONDS)
	return ITEM_INTERACT_SUCCESS

/obj/item/cultivation_artifact/purple_gold_gourd/proc/stop_listening(mob/living/victim)
	UnregisterSignal(victim, COMSIG_MOB_SAY)
	target_ref = null

/obj/item/cultivation_artifact/purple_gold_gourd/proc/on_answer(mob/living/victim, list/speech_args)
	SIGNAL_HANDLER
	stop_listening(victim)
	if(QDELETED(src) || get_dist(src, victim) > 11 || prisoner)
		return
	INVOKE_ASYNC(src, PROC_REF(suck_in), victim)

/obj/item/cultivation_artifact/purple_gold_gourd/proc/suck_in(mob/living/victim)
	victim.visible_message(span_boldwarning("[victim] answers, and is sucked into the purple gourd with a loud SHLOOP!"), span_userdanger("You answered! You're sucked into the gourd!"))
	playsound(victim, 'sound/effects/chipbagpop.ogg', 70, TRUE, frequency = 0.5)
	victim.Immobilize(0.5 SECONDS)
	// Stretch and shrink into the gourd's mouth
	var/obj/effect/temp_visual/decoy/sucked = new(get_turf(victim), victim)
	sucked.duration = 0.5 SECONDS
	animate(sucked, transform = matrix().Scale(0.4, 1.6), time = 0.15 SECONDS)
	animate(transform = matrix().Scale(0.05), alpha = 0, pixel_x = (x - victim.x) * 32, pixel_y = (y - victim.y) * 32, time = 0.35 SECONDS, easing = QUAD_EASING | EASE_IN)
	QDEL_IN(sucked, 0.5 SECONDS)
	new /obj/effect/temp_visual/circle_wave/cultivation(get_turf(src))
	victim.forceMove(src)
	prisoner = victim
	victim.remove_status_effect(/datum/status_effect/body_iron_shirt)
	victim.remove_status_effect(/datum/status_effect/body_vajra)
	to_chat(victim, span_userdanger("It's dark and smells of wine in here, and your skin is starting to sting. Resist to try to break out (it takes a while)."))
	START_PROCESSING(SSobj, src)
	// Never forever: the gourd spits them out eventually
	addtimer(CALLBACK(src, PROC_REF(release)), 2 MINUTES)

/// The gourd's wine slowly dissolves whoever is inside
/obj/item/cultivation_artifact/purple_gold_gourd/process(seconds_per_tick)
	if(!prisoner || prisoner.loc != src)
		return PROCESS_KILL
	prisoner.apply_damage(1.5 * seconds_per_tick, BURN, forced = TRUE)
	var/datum/antagonist/body_cultivator/body_datum = IS_BODY_CULTIVATOR(prisoner)
	if(body_datum)
		body_datum.tempering = max(body_datum.tempering - 2 * seconds_per_tick, 0)
		body_datum.add_exhaustion(10 * seconds_per_tick)

/obj/item/cultivation_artifact/purple_gold_gourd/container_resist_act(mob/living/user)
	if(user != prisoner)
		return
	to_chat(user, span_notice("You start squirming against the cork... (this will take 45 seconds)"))
	audible_message(span_warning("[src] wobbles and thumps!"))
	if(do_after(user, 45 SECONDS, src, timed_action_flags = IGNORE_TARGET_LOC_CHANGE | IGNORE_HELD_ITEM))
		release()

/obj/item/cultivation_artifact/purple_gold_gourd/relaymove(mob/living/user, direction)
	return

/obj/item/cultivation_artifact/purple_gold_gourd/proc/release()
	STOP_PROCESSING(SSobj, src)
	if(!prisoner)
		return
	var/mob/living/freed = prisoner
	prisoner = null
	if(QDELETED(freed) || freed.loc != src)
		return
	freed.forceMove(drop_location())
	freed.transform = matrix().Scale(0.2)
	animate(freed, transform = matrix().Scale(1.2), time = 0.2 SECONDS, easing = BACK_EASING | EASE_OUT)
	animate(transform = matrix(), time = 0.1 SECONDS)
	freed.visible_message(span_warning("[freed] tumbles out of [src] in a puff of wine-scented smoke!"))
	playsound(src, 'sound/effects/pop.ogg', 60, TRUE)
	new /obj/effect/temp_visual/small_smoke/halfsecond(get_turf(src))

// ===================== Plantain Fan =====================

/obj/item/cultivation_artifact/plantain_fan
	name = "Plantain Fan"
	desc = "A huge fan woven from a single leaf. One wave sends a hurricane in front of you, scattering people and snuffing out flames."
	icon_state = "plantain_fan"
	w_class = WEIGHT_CLASS_NORMAL
	force = 5
	legend = "The Iron Fan Princess's treasure. One wave of it blows a man fifty thousand li away. Here, it's the length of a corridor, but still."
	power_text = "Click a direction to loose a hurricane nine tiles deep that hurls everyone (no stance can root against it) ten tiles away and shatters glass. \
		Use it in hand for a typhoon all around you."
	COOLDOWN_DECLARE(gust_cooldown)

/obj/item/cultivation_artifact/plantain_fan/attack_self(mob/user)
	if(!COOLDOWN_FINISHED(src, gust_cooldown))
		user.balloon_alert(user, "the fan is resting!")
		return
	COOLDOWN_START(src, gust_cooldown, 15 SECONDS)
	user.say("TYPHOON!!", forced = "plantain fan")
	user.visible_message(span_boldwarning("[user] whirls the Plantain Fan overhead and a typhoon explodes outward!"))
	playsound(user, 'sound/effects/space_wind.ogg', 90, TRUE)
	user.SpinAnimation(5, 1)
	var/turf/start = get_turf(user)
	for(var/turf/gust_turf in range(5, start))
		if(gust_turf != start)
			blow(user, gust_turf, get_dir(start, gust_turf))

/obj/item/cultivation_artifact/plantain_fan/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	gust(user, interacting_with)
	return ITEM_INTERACT_SUCCESS

/obj/item/cultivation_artifact/plantain_fan/proc/gust(mob/living/user, atom/towards)
	if(!COOLDOWN_FINISHED(src, gust_cooldown))
		user.balloon_alert(user, "the fan is resting!")
		return
	COOLDOWN_START(src, gust_cooldown, 15 SECONDS)
	var/blow_dir = get_dir(user, towards) || user.dir
	user.say("HURRICANE!!", forced = "plantain fan")
	user.visible_message(span_boldwarning("[user] swings the Plantain Fan and a howling gale bursts forth!"))
	playsound(user, 'sound/effects/space_wind.ogg', 90, TRUE)
	user.do_attack_animation(get_step(user, blow_dir))
	var/turf/start = get_turf(user)
	for(var/turf/gust_turf in range(9, start))
		if(gust_turf == start || !(get_dir(start, gust_turf) & blow_dir) || (get_dir(start, gust_turf) & REVERSE_DIR(blow_dir)))
			continue
		blow(user, gust_turf, blow_dir)

/// Everything on one turf goes flying
/obj/item/cultivation_artifact/plantain_fan/proc/blow(mob/living/user, turf/gust_turf, blow_dir)
	if(prob(40))
		new /obj/effect/temp_visual/small_smoke/halfsecond(gust_turf)
	for(var/obj/effect/hotspot/flame in gust_turf)
		qdel(flame)
	for(var/obj/structure/window/window in gust_turf)
		window.take_damage(50, BRUTE, MELEE)
	for(var/atom/movable/blown in gust_turf)
		if(blown.anchored || blown == user)
			continue
		if(isliving(blown))
			var/mob/living/victim = blown
			victim.extinguish_mob()
			legendary_hit(user, victim, 5, 2 SECONDS, name, src)
		// Positional: some throw_at overrides elsewhere lack the force keyword
		blown.throw_at(get_edge_target_turf(blown, blow_dir), 10, 3, user, TRUE, FALSE, null, MOVE_FORCE_OVERPOWERING)

// ===================== Bagua Mirror =====================

/obj/item/cultivation_artifact/bagua_mirror
	name = "Bagua Mirror"
	desc = "A bronze octagonal mirror ringed with the eight trigrams. Held up, it flashes with a light evil can't stand, and it turns aside shots."
	icon_state = "bagua_mirror"
	w_class = WEIGHT_CLASS_SMALL
	block_chance = 50
	legend = "Hung over doorways to turn away evil spirits. In a cultivator's hand it does a great deal more."
	power_text = "Use it in hand: the Eight Trigrams Seal. Every cultivator who sees the light (qi or body) has their cultivation sealed for twenty seconds: \
		no techniques, no body arts, no Iron Shirt or Golden Body. The undead and the wicked burn."
	COOLDOWN_DECLARE(flash_cooldown)

/obj/item/cultivation_artifact/bagua_mirror/attack_self(mob/user)
	if(!COOLDOWN_FINISHED(src, flash_cooldown))
		user.balloon_alert(user, "the mirror is dim!")
		return
	COOLDOWN_START(src, flash_cooldown, 45 SECONDS)
	user.say("EIGHT TRIGRAMS SEAL!!", forced = "bagua mirror")
	user.visible_message(span_boldwarning("[user] holds up the Bagua Mirror and it blazes with the light of the eight trigrams!"))
	playsound(user, 'sound/items/weapons/flash.ogg', 70, TRUE)
	cultivation_temple_sound(user, 70)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(get_turf(user))
	for(var/mob/living/victim in view(6, user))
		if(victim == user)
			continue
		var/undead = (victim.mob_biotypes & MOB_UNDEAD) || IS_BLOODSUCKER(victim) || IS_CULTIST(victim) || IS_HERETIC(victim)
		if(undead)
			victim.Paralyze(3 SECONDS)
			victim.apply_damage(20, BURN, forced = TRUE)
			to_chat(victim, span_userdanger("The mirror's light sears your evil qi!"))
		if(IS_CULTIVATOR(victim) || IS_BODY_CULTIVATOR(victim))
			victim.apply_status_effect(/datum/status_effect/bagua_sealed)
			victim.Knockdown(1 SECONDS)
		else
			victim.flash_act(1, TRUE)

/obj/item/cultivation_artifact/bagua_mirror/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK, damage_type = BRUTE)
	if(attack_type != PROJECTILE_ATTACK)
		return FALSE
	if(prob(final_block_chance))
		owner.visible_message(span_danger("[owner]'s Bagua Mirror turns [attack_text] aside!"))
		playsound(owner, 'sound/items/weapons/parry.ogg', 50, TRUE)
		return TRUE
	return FALSE

/// Sealed by the eight trigrams: no techniques of any kind
/datum/status_effect/bagua_sealed
	id = "bagua_sealed"
	alert_type = null
	duration = 20 SECONDS
	status_type = STATUS_EFFECT_REFRESH

/datum/status_effect/bagua_sealed/on_apply()
	owner.remove_status_effect(/datum/status_effect/body_iron_shirt)
	owner.remove_status_effect(/datum/status_effect/body_vajra)
	owner.remove_status_effect(/datum/status_effect/body_blood_boil)
	owner.add_filter("bagua_sealed", 2, list("type" = "outline", "color" = "#f0d080", "size" = 1))
	to_chat(owner, span_userdanger("The eight trigrams lock around your meridians and sinews! Your cultivation is sealed!"))
	return TRUE

/datum/status_effect/bagua_sealed/on_remove()
	owner.remove_filter("bagua_sealed")
	to_chat(owner, span_notice("The seal of the eight trigrams fades."))

// ===================== Qiankun Pouch =====================

/obj/item/cultivation_artifact/qiankun_pouch
	name = "Qiankun Pouch"
	desc = "A small embroidered pouch that holds a whole world inside. It fits far more than it should, even huge things."
	icon_state = "qiankun_pouch"
	w_class = WEIGHT_CLASS_SMALL
	legend = "Qian and Kun, heaven and earth. The inside of this pouch is larger than the outside, which is the point."
	power_text = "Use it in hand to Swallow Heaven and Earth: every loose item within five tiles flies into the pouch."
	COOLDOWN_DECLARE(swallow_cooldown)

/obj/item/cultivation_artifact/qiankun_pouch/Initialize(mapload)
	. = ..()
	create_storage(max_slots = 50, max_specific_storage = WEIGHT_CLASS_GIGANTIC, max_total_storage = 200)

/obj/item/cultivation_artifact/qiankun_pouch/attack_self(mob/user)
	if(!COOLDOWN_FINISHED(src, swallow_cooldown))
		user.balloon_alert(user, "the pouch is full of wind!")
		return
	COOLDOWN_START(src, swallow_cooldown, 20 SECONDS)
	user.say("SWALLOW HEAVEN AND EARTH!", forced = "qiankun pouch")
	user.visible_message(span_boldwarning("[user] opens the Qiankun Pouch and everything around [user.p_them()] is dragged inside!"))
	playsound(user, 'sound/effects/magic/summonitems_generic.ogg', 60, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/sense(get_turf(user))
	var/swallowed = 0
	for(var/obj/item/loose in range(5, user))
		if(loose == src || loose.anchored || !isturf(loose.loc) || (loose.item_flags & ABSTRACT))
			continue
		if(!atom_storage?.attempt_insert(loose, user, messages = FALSE))
			continue
		swallowed++
	to_chat(user, span_notice("[swallowed ? "[swallowed] thing\s vanish" : "Nothing vanishes"] into the pouch."))

// ===================== Spawning =====================

/obj/effect/spawner/random/legendary_artifact
	name = "random legendary artifact"
	icon = 'surfshack13/icons/cultivation/cultivation_artifacts.dmi'
	icon_state = "heaven_reliant"
	loot = list(
		/obj/item/cultivation_artifact/twin_sword/ganjiang = 1,
		/obj/item/cultivation_artifact/twin_sword/moye = 1,
		/obj/item/cultivation_artifact/heaven_reliant = 1,
		/obj/item/cultivation_artifact/dragon_saber = 1,
		/obj/item/cultivation_artifact/ruyi_jingu_bang = 1,
		/obj/item/cultivation_artifact/purple_gold_gourd = 1,
		/obj/item/cultivation_artifact/plantain_fan = 1,
		/obj/item/cultivation_artifact/bagua_mirror = 1,
		/obj/item/cultivation_artifact/qiankun_pouch = 1,
	)
