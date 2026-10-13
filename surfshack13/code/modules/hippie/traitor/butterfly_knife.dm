// Butterfly knives - ported from HippieStation.
// Concealable flip knives that deal a huge backstab when used from behind in combat mode.

/obj/item/butterfly_knife
	name = "butterfly knife"
	desc = "A stealthy knife famously used by spy organisations. Capable of piercing armour and causing massive backstab damage when used in combat mode."
	icon = 'surfshack13/icons/hippie/butterfly_knife.dmi'
	icon_state = "butterfly"
	inhand_icon_state = "butterfly"
	lefthand_file = 'surfshack13/icons/hippie/butterfly_knife_lefthand.dmi'
	righthand_file = 'surfshack13/icons/hippie/butterfly_knife_righthand.dmi'
	obj_flags = CONDUCTS_ELECTRICITY
	force = 0
	throwforce = 0
	armour_penetration = 20
	w_class = WEIGHT_CLASS_SMALL
	attack_verb_continuous = list("taps", "prods")
	attack_verb_simple = list("tap", "prod")
	custom_materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 6)
	resistance_flags = FIRE_PROOF
	/// Damage while open
	var/force_on = 10
	/// Damage dealt when stabbing someone from behind
	var/backstab_force = 30

/obj/item/butterfly_knife/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)
	AddComponent( \
		/datum/component/transforming, \
		force_on = force_on, \
		throwforce_on = force_on, \
		throw_speed_on = throw_speed, \
		sharpness_on = SHARP_POINTY, \
		hitsound_on = 'surfshack13/sound/hippie/knife.ogg', \
		w_class_on = WEIGHT_CLASS_NORMAL, \
		attack_verb_continuous_on = list("pokes", "slashes", "stabs", "slices", "tears", "pierces", "dices", "cuts"), \
		attack_verb_simple_on = list("poke", "slash", "stab", "slice", "tear", "pierce", "dice", "cut"), \
	)
	RegisterSignal(src, COMSIG_TRANSFORMING_ON_TRANSFORM, PROC_REF(on_transform))

/obj/item/butterfly_knife/get_all_tool_behaviours()
	return list(TOOL_KNIFE)

/obj/item/butterfly_knife/proc/on_transform(obj/item/source, mob/user, active)
	SIGNAL_HANDLER

	tool_behaviour = (active ? TOOL_KNIFE : NONE)
	playsound(user || src, active ? 'surfshack13/sound/hippie/knifeopen.ogg' : 'surfshack13/sound/hippie/knifeclose.ogg', 50, TRUE)
	if(user)
		to_chat(user, span_notice("[src] [active ? "is now active" : "can now be concealed"]."))
	return COMPONENT_NO_DEFAULT_MESSAGE

/obj/item/butterfly_knife/attack(mob/living/target_mob, mob/living/user, params)
	if(!HAS_TRAIT(src, TRAIT_TRANSFORM_ACTIVE) || !user.combat_mode || !ishuman(target_mob) || target_mob == user || HAS_TRAIT(user, TRAIT_PACIFISM))
		return ..()
	if(target_mob.stat == DEAD || check_target_facings(user, target_mob) != FACING_SAME_DIR)
		return ..()
	backstab(target_mob, user)
	return TRUE

/// Deals the backstab to the victim's chest and makes them drop whatever they are holding.
/obj/item/butterfly_knife/proc/backstab(mob/living/carbon/human/victim, mob/living/user)
	if(!victim.get_bodypart(BODY_ZONE_CHEST))
		return
	victim.visible_message(
		span_danger("[user] backstabs [victim] with [src]!"),
		span_userdanger("[user] backstabs you with [src]!"),
	)
	add_fingerprint(user)
	playsound(victim, 'surfshack13/sound/hippie/knifecrit.ogg', 40, TRUE, -1)
	user.do_attack_animation(victim)
	user.changeNext_move(CLICK_CD_MELEE)
	var/armor_block = victim.run_armor_check(BODY_ZONE_CHEST, MELEE, armour_penetration = armour_penetration)
	victim.apply_damage(backstab_force, BRUTE, BODY_ZONE_CHEST, armor_block, sharpness = SHARP_POINTY)
	victim.dropItemToGround(victim.get_active_held_item())
	log_combat(user, victim, "backstabbed", src)

/obj/item/butterfly_knife/energy
	name = "energy balisong"
	desc = "A vicious carbon fibre blade and plasma tip allow for unparalleled precision strikes against fat Nanotrasen backsides."
	icon_state = "energy_butterfly"
	inhand_icon_state = "balisong"
	force_on = 20
	backstab_force = 125
	light_system = OVERLAY_LIGHT
	light_range = 1.5
	light_power = 1.3
	light_color = "#ff2448"
	light_on = FALSE

/obj/item/butterfly_knife/energy/on_transform(obj/item/source, mob/user, active)
	. = ..()
	set_light_on(active)
	update_appearance(UPDATE_OVERLAYS)

// The plasma blade glows in the dark
/obj/item/butterfly_knife/energy/update_overlays()
	. = ..()
	if(HAS_TRAIT(src, TRAIT_TRANSFORM_ACTIVE))
		. += emissive_appearance(icon, "energy_butterfly_on_emissive", src, alpha = src.alpha)

/datum/uplink_item/dangerous/butterfly
	name = "Energy Butterfly Knife"
	desc = "A highly lethal and concealable knife that causes critical backstab damage when used from behind in combat mode."
	item = /obj/item/butterfly_knife/energy
	cost = 8
	surplus = 15
	purchasable_from = UPLINK_TRAITORS | UPLINK_SERIOUS_OPS
