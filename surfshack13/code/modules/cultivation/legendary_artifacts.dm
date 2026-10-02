/**
 * Legendary weapons and treasures from Chinese legend and the martial novels.
 * One turns up somewhere in maintenance each round. Any of them can be bound with Returning Iron.
 */

/obj/item/cultivation_artifact
	icon = 'surfshack13/icons/cultivation/cultivation_artifacts.dmi'
	resistance_flags = FIRE_PROOF | ACID_PROOF | LAVA_PROOF
	/// Shown on examine to cultivators
	var/legend = ""

/obj/item/cultivation_artifact/examine(mob/user)
	. = ..()
	if(legend && (IS_CULTIVATOR(user) || isobserver(user)))
		. += span_notice("<i>[legend]</i>")

// ===================== Ganjiang and Moye =====================

/obj/item/cultivation_artifact/twin_sword
	icon_state = "ganjiang"
	inhand_icon_state = "sabre"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 17
	throwforce = 12
	w_class = WEIGHT_CLASS_NORMAL
	sharpness = SHARP_EDGED
	attack_verb_continuous = list("slashes", "cuts", "pierces")
	attack_verb_simple = list("slash", "cut", "pierce")
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	block_chance = 15
	legend = "The swordsmith Ganjiang and his wife Moye forged a pair of swords, one male and one female. Held together, they long for each other."
	/// The other sword type of the pair
	var/partner_type = /obj/item/cultivation_artifact/twin_sword/moye

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
	if(!isliving(target) || !paired(user))
		return
	var/mob/living/victim = target
	victim.apply_damage(7, BRUTE, sharpness = SHARP_EDGED)
	new /obj/effect/temp_visual/slash(get_turf(victim), victim, rand(10, 22), rand(10, 22), "#9fb8ff")
	if(prob(25))
		user.visible_message(span_danger("Ganjiang and Moye sing in harmony as [user] strikes!"))

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
	desc = "A long, impossibly keen sword of pale jade-white steel. It cuts iron like mud."
	icon_state = "heaven_reliant"
	inhand_icon_state = "katana"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 22
	throwforce = 15
	armour_penetration = 50
	w_class = WEIGHT_CLASS_BULKY
	sharpness = SHARP_EDGED
	block_chance = 20
	attack_verb_continuous = list("slices", "cleaves", "shears")
	attack_verb_simple = list("slice", "cleave", "shear")
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	legend = "\"Supreme in the martial world is the Dragon Slaying Saber. Who dares not obey? If the Heaven Reliant Sword does not appear, who can contend with it?\""

/obj/item/cultivation_artifact/heaven_reliant/afterattack(atom/target, mob/user, list/modifiers, list/attack_modifiers)
	. = ..()
	// It cuts through iron like mud
	if(isobj(target) && !isitem(target))
		var/obj/cut = target
		cut.take_damage(force * 2, BRUTE, MELEE)

/obj/item/cultivation_artifact/dragon_saber
	name = "Dragon Slaying Saber"
	desc = "A massive black dao with a golden dragon coiled along the blade. Every blow lands like a falling mountain."
	icon_state = "dragon_saber"
	inhand_icon_state = "claymore"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 26
	throwforce = 18
	w_class = WEIGHT_CLASS_BULKY
	sharpness = SHARP_EDGED
	attack_speed = CLICK_CD_MELEE * 1.5
	attack_verb_continuous = list("hacks", "cleaves", "crushes")
	attack_verb_simple = list("hack", "cleave", "crush")
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	legend = "\"Supreme in the martial world is the Dragon Slaying Saber.\" Legend says it holds a secret, revealed only when it meets the Heaven Reliant Sword."

/obj/item/cultivation_artifact/dragon_saber/afterattack(atom/target, mob/user, list/modifiers, list/attack_modifiers)
	. = ..()
	if(!isliving(target))
		return
	var/mob/living/victim = target
	if(!HAS_TRAIT(victim, TRAIT_PUSHIMMUNE) && victim.move_resist < MOVE_FORCE_OVERPOWERING)
		victim.throw_at(get_edge_target_turf(victim, get_dir(user, victim)), 2, 2, user)
	victim.Shake(2, 2, 0.4 SECONDS)

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
	var/extended = FALSE

/obj/item/cultivation_artifact/ruyi_jingu_bang/attack_self(mob/user)
	extended = !extended
	if(extended)
		name = "Ruyi Jingu Bang"
		desc = "The Monkey King's staff, grown to full size. It reaches further than any normal weapon. Use it in hand to shrink it."
		icon_state = "ruyi_staff"
		inhand_icon_state = "bostaff1"
		w_class = WEIGHT_CLASS_HUGE
		force = 18
		throwforce = 15
		reach = 2
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
	if(ismonkey(user))
		victim.apply_damage(10, BRUTE)
	if(!HAS_TRAIT(victim, TRAIT_PUSHIMMUNE) && victim.move_resist < MOVE_FORCE_OVERPOWERING && prob(40))
		victim.throw_at(get_edge_target_turf(victim, get_dir(user, victim)), 3, 2, user)

// ===================== Purple-Gold Gourd =====================

/obj/item/cultivation_artifact/purple_gold_gourd
	name = "Purple-Gold Gourd"
	desc = "A purple calabash with a gold band and a red cork. Point it at someone and call their name. If they answer, they're inside."
	icon_state = "purple_gold_gourd"
	w_class = WEIGHT_CLASS_SMALL
	legend = "From the Journey to the West. Whoever answers when the gourd's holder calls their name is sucked inside."
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
	if(get_dist(user, victim) > 7)
		return ITEM_INTERACT_BLOCKING
	if(cultivation_realm_of(victim) > cultivation_realm_of(user))
		to_chat(user, span_warning("[victim]'s cultivation is too deep. The gourd won't take [victim.p_them()]."))
		return ITEM_INTERACT_BLOCKING
	COOLDOWN_START(src, call_cooldown, 90 SECONDS)
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
	if(QDELETED(src) || get_dist(src, victim) > 9 || prisoner)
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
	to_chat(victim, span_notice("It's dark and smells of wine in here. Resist to try to break out (it takes a while)."))
	// Never forever: the gourd spits them out eventually
	addtimer(CALLBACK(src, PROC_REF(release)), 2 MINUTES)

/obj/item/cultivation_artifact/purple_gold_gourd/container_resist_act(mob/living/user)
	if(user != prisoner)
		return
	to_chat(user, span_notice("You start squirming against the cork... (this will take 30 seconds)"))
	audible_message(span_warning("[src] wobbles and thumps!"))
	if(do_after(user, 30 SECONDS, src, timed_action_flags = IGNORE_TARGET_LOC_CHANGE | IGNORE_HELD_ITEM))
		release()

/obj/item/cultivation_artifact/purple_gold_gourd/relaymove(mob/living/user, direction)
	return

/obj/item/cultivation_artifact/purple_gold_gourd/proc/release()
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
	legend = "The Iron Fan Princess's treasure. One wave of it blows a man fifty thousand li away. Here, it's a few tiles, but still."
	COOLDOWN_DECLARE(gust_cooldown)

/obj/item/cultivation_artifact/plantain_fan/attack_self(mob/user)
	gust(user, get_step(user, user.dir))

/obj/item/cultivation_artifact/plantain_fan/ranged_interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	gust(user, interacting_with)
	return ITEM_INTERACT_SUCCESS

/obj/item/cultivation_artifact/plantain_fan/proc/gust(mob/living/user, atom/towards)
	if(!COOLDOWN_FINISHED(src, gust_cooldown))
		user.balloon_alert(user, "the fan is resting!")
		return
	COOLDOWN_START(src, gust_cooldown, 20 SECONDS)
	var/blow_dir = get_dir(user, towards) || user.dir
	user.visible_message(span_boldwarning("[user] swings the Plantain Fan and a howling gale bursts forth!"))
	playsound(user, 'sound/effects/space_wind.ogg', 80, TRUE)
	user.do_attack_animation(get_step(user, blow_dir))
	var/turf/start = get_turf(user)
	for(var/turf/gust_turf in range(3, start))
		if(gust_turf == start || get_dir(start, gust_turf) & REVERSE_DIR(blow_dir) || !(get_dir(start, gust_turf) & blow_dir))
			continue
		new /obj/effect/temp_visual/small_smoke/halfsecond(gust_turf)
		for(var/obj/effect/hotspot/flame in gust_turf)
			qdel(flame)
		for(var/atom/movable/blown in gust_turf)
			if(blown.anchored || blown == user)
				continue
			if(isliving(blown))
				var/mob/living/victim = blown
				victim.extinguish_mob()
				if(HAS_TRAIT(victim, TRAIT_PUSHIMMUNE))
					continue
				victim.Knockdown(1 SECONDS)
			blown.throw_at(get_edge_target_turf(blown, blow_dir), 5, 2, user)

// ===================== Bagua Mirror =====================

/obj/item/cultivation_artifact/bagua_mirror
	name = "Bagua Mirror"
	desc = "A bronze octagonal mirror ringed with the eight trigrams. Held up, it flashes with a light evil can't stand, and it sometimes turns aside a shot."
	icon_state = "bagua_mirror"
	w_class = WEIGHT_CLASS_SMALL
	block_chance = 25
	legend = "Hung over doorways to turn away evil spirits. In a cultivator's hand it does a great deal more."
	COOLDOWN_DECLARE(flash_cooldown)

/obj/item/cultivation_artifact/bagua_mirror/attack_self(mob/user)
	if(!COOLDOWN_FINISHED(src, flash_cooldown))
		user.balloon_alert(user, "the mirror is dim!")
		return
	COOLDOWN_START(src, flash_cooldown, 30 SECONDS)
	user.visible_message(span_boldwarning("[user] holds up the Bagua Mirror and it blazes with holy light!"))
	playsound(user, 'sound/items/weapons/flash.ogg', 70, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(get_turf(user))
	for(var/mob/living/victim in view(4, user))
		if(victim == user)
			continue
		var/undead = (victim.mob_biotypes & MOB_UNDEAD) || IS_BLOODSUCKER(victim) || IS_CULTIST(victim) || IS_HERETIC(victim)
		if(undead)
			victim.Paralyze(3 SECONDS)
			victim.apply_damage(15, BURN)
			to_chat(victim, span_userdanger("The mirror's light sears your evil qi!"))
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

// ===================== Qiankun Pouch =====================

/obj/item/cultivation_artifact/qiankun_pouch
	name = "Qiankun Pouch"
	desc = "A small embroidered pouch that holds a whole world inside. It fits far more than it should."
	icon_state = "qiankun_pouch"
	w_class = WEIGHT_CLASS_SMALL
	legend = "Qian and Kun, heaven and earth. The inside of this pouch is larger than the outside, which is the point."

/obj/item/cultivation_artifact/qiankun_pouch/Initialize(mapload)
	. = ..()
	create_storage(max_slots = 21, max_specific_storage = WEIGHT_CLASS_BULKY, max_total_storage = 42)

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
