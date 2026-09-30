// Security cargo additions: particle acceleration rifle, NT-20 stunswords and MOD plating.
// These are also orderable through the security departmental order console (free, but they lock the department out for a long time).

/datum/supply_pack
	/// Minimum cooldown (in deciseconds) the departmental order console imposes after ordering this pack. 0 uses the normal cost-based cooldown.
	var/dept_order_cooldown = 0

/datum/supply_pack/security/armory/particle_rifle
	name = "Particle Acceleration Rifle Crate"
	desc = "Contains one experimental particle acceleration rifle, an anti-material marksman rifle that fires piercing particle beams, \
		and a spare capacitor. Requires a scope to fire. Extremely expensive, and the armory needs time to ready another."
	cost = CARGO_CRATE_VALUE * 30
	access_view = ACCESS_ARMORY
	contains = list(
		/obj/item/gun/energy/particle_rifle,
		/obj/item/stock_parts/power_store/cell/particle_rifle,
	)
	crate_name = "particle acceleration rifle crate"
	crate_type = /obj/structure/closet/crate/secure/plasma
	dept_order_cooldown = 45 MINUTES

/datum/supply_pack/security/armory/stunsword
	name = "NT-20 Stunsword Crate"
	desc = "Contains two NT-20 'Excalibur' stunswords, each with a high capacity cell. A sword that stuns."
	cost = CARGO_CRATE_VALUE * 14
	access_view = ACCESS_ARMORY
	contains = list(/obj/item/melee/baton/security/stunsword/loaded = 2)
	crate_name = "stunsword crate"
	crate_type = /obj/structure/closet/crate/secure/plasma
	dept_order_cooldown = 25 MINUTES

/datum/supply_pack/security/modsuit_plating
	name = "Security MOD Plating"
	desc = "A single set of security MOD suit plating."
	cost = CARGO_CRATE_VALUE * 2
	access_view = ACCESS_SECURITY
	contains = list(/obj/item/mod/construction/plating/security)
	crate_name = "\improper MOD plating crate"
