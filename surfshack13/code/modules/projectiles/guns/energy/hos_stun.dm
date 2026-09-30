/obj/item/ammo_casing/energy/electrode/hos
	projectile_type = /obj/projectile/energy/electrode
	select_name = "stun"
	e_cost = LASER_SHOTS(3, STANDARD_CELL_CHARGE * 1.2)

// Guard the actual casing entry point too, including delayed burst callbacks.
/obj/item/ammo_casing/energy/electrode/hos/fire_casing(atom/target, mob/living/user, params, distro, quiet, zone_override, spread, atom/fired_from)
	var/obj/item/gun/energy/e_gun/hos/gun = fired_from
	if(!istype(gun) || !gun.is_authorized_for_stun(user))
		return FALSE
	return ..()

/obj/item/gun/energy/e_gun/hos/examine(mob/user)
	. = ..()
	. += span_notice("Anyone can select its stun mode, but firing it requires a mindshielded, manifest-verified Head of Security carrying their own Head of Security ID. A full charge provides three stun shots.")

/// Returns a specific denial reason, or null when all credentials match.
/obj/item/gun/energy/e_gun/hos/proc/stun_denial_reason(mob/living/user)
	if(!ishuman(user))
		return "human operator required"
	if(user.mind?.assigned_role?.title != JOB_HEAD_OF_SECURITY)
		return "Head of Security role required"
	var/datum/record/crew/record = find_record(user.real_name)
	if(!record)
		return "crew manifest record missing"
	if(record.rank != JOB_HEAD_OF_SECURITY)
		return "manifest rank must be Head of Security"
	if(!HAS_TRAIT(user, TRAIT_MINDSHIELD))
		return "mindshield required"
	var/obj/item/card/id/card = user.get_idcard(TRUE)
	if(!card)
		return "Head of Security ID required"
	if(istype(card, /obj/item/card/id/advanced/chameleon))
		return "chameleon IDs not accepted"
	if(!(ACCESS_HOS in card.GetAccess()))
		return "Head of Security access required"
	if(card.assignment != JOB_HEAD_OF_SECURITY)
		return "ID assignment must be Head of Security"
	if(card.registered_name != user.real_name)
		return "ID name does not match operator"
	return null

/// Re-evaluated on every firing attempt; emagging never bypasses credentials.
/obj/item/gun/energy/e_gun/hos/proc/is_authorized_for_stun(mob/living/user)
	var/reason = stun_denial_reason(user)
	if(!reason)
		return TRUE
	if(user)
		balloon_alert(user, "ACCESS DENIED")
		to_chat(user, span_warning("[src] displays: UNAUTHORIZED USER. ACCESS DENIED."))
	return FALSE

/obj/item/gun/energy/e_gun/hos/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0)
	// Check both the selector and any already chambered stun shot after a handoff.
	if((istype(ammo_type[select], /obj/item/ammo_casing/energy/electrode/hos) || istype(chambered, /obj/item/ammo_casing/energy/electrode/hos)) && !is_authorized_for_stun(user))
		return FALSE
	return ..()

/obj/item/gun/energy/e_gun/hos/update_icon_state()
	. = ..()
	if(istype(ammo_type[select], /obj/item/ammo_casing/energy/electrode/hos))
		// Both hand icon files provide disable0 through disable4, but no stun states.
		inhand_icon_state = "hoslaserdisable[get_charge_ratio()]"

/obj/item/gun/energy/e_gun/hos/update_overlays()
	. = ..()
	// The HoS sprite has no stun overlays; reuse its nonlethal mode indicators.
	for(var/index in 1 to length(.))
		if(.[index] == "hoslaser_stun")
			.[index] = "hoslaser_disable"
		else if(istype(.[index], /mutable_appearance))
			var/mutable_appearance/overlay = .[index]
			if(overlay.icon_state == "hoslaser_charge_stun")
				overlay.icon_state = "hoslaser_charge_disable"
