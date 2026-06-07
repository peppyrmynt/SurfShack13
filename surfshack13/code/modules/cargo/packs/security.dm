/datum/supply_pack/security/armory/mk58
	name = "Mk58 Pistols Crate"
	desc = "Contains three Mk58 Pistols and a spare magazine for each."
	cost = CARGO_CRATE_VALUE * 15
	access = ACCESS_ARMORY
	contains = list(/obj/item/gun/ballistic/automatic/pistol/mk58,
					/obj/item/gun/ballistic/automatic/pistol/mk58,
					/obj/item/gun/ballistic/automatic/pistol/mk58,
					/obj/item/ammo_box/magazine/v38,
					/obj/item/ammo_box/magazine/v38,
					/obj/item/ammo_box/magazine/v38)
	crate_name = "mk58 pistol crate"

/datum/supply_pack/security/armory/mk58single
	name = "Mk58 Pistol Crate Single-Pack"
	desc = "Contains one Mk58 Pistol and a spare magazine for it."
	cost = CARGO_CRATE_VALUE * 8.75
	contains = list(/obj/item/gun/ballistic/automatic/pistol/mk58,
					/obj/item/ammo_box/magazine/v38)
	crate_name = "mk58 pistol crate"

/datum/supply_pack/security/armory/kammerer
	name = "Kammerer Crate"
	desc = "Contains three Kammerers and three boxes of lethal shells."
	cost = CARGO_CRATE_VALUE * 20
	access = ACCESS_ARMORY
	contains = list(/obj/item/gun/ballistic/shotgun/automatic/combat/kammerer,
					/obj/item/gun/ballistic/shotgun/automatic/combat/kammerer,
					/obj/item/gun/ballistic/shotgun/automatic/combat/kammerer,
					/obj/item/storage/box/lethalshot,
					/obj/item/storage/box/lethalshot,
					/obj/item/storage/box/lethalshot)
	crate_name = "kammerer crate"

/datum/supply_pack/security/armory/kammerersingle
	name = "Kammerer Crate Single-Pack"
	desc = "Contains one Kammerer and one boxes of lethal shells."
	cost = CARGO_CRATE_VALUE * 12.5
	access = ACCESS_ARMORY
	contains = list(/obj/item/gun/ballistic/shotgun/automatic/combat/kammerer,
					/obj/item/storage/box/lethalshot)
	crate_name = "single kammerer crate"

/datum/supply_pack/security/armory/enforcer
	name = "Enforcer Crate"
	desc = "Contains three Enforcers and three boxes of lethal shells."
	cost = CARGO_CRATE_VALUE * 30
	access = ACCESS_ARMORY
	contains = list(/obj/item/gun/ballistic/shotgun/enforcer,
					/obj/item/gun/ballistic/shotgun/enforcer,
					/obj/item/gun/ballistic/shotgun/enforcer,
					/obj/item/storage/box/lethalshot,
					/obj/item/storage/box/lethalshot,
					/obj/item/storage/box/lethalshot)
	crate_name = "enforcer crate"

/datum/supply_pack/security/armory/enforcersingle
	name = "Enforcer Crate Single-Pack"
	desc = "Contains one Enforcer and one boxes of lethal shells."
	cost = CARGO_CRATE_VALUE * 17.5
	access = ACCESS_ARMORY
	contains = list(/obj/item/gun/ballistic/shotgun/enforcer,
					/obj/item/storage/box/lethalshot)
	crate_name = "single enforcer crate"


/datum/supply_pack/security/armory/hristov
	name = "Hristov Crate"
	desc = "Contains two Hristov Sniper Rifles and two bandoliers containing twelve additional rounds."
	cost = CARGO_CRATE_VALUE * 37.5
	access = ACCESS_ARMORY
	contains = list(/obj/item/gun/ballistic/rifle/sniper_rifle/hristov,
					/obj/item/gun/ballistic/rifle/sniper_rifle/hristov,
					/obj/item/storage/belt/bandolier/hristov,
					/obj/item/storage/belt/bandolier/hristov)
	crate_name = "hristov crate"

/datum/supply_pack/security/armory/hristovsingle
	name = "Hristov Crate Single-Pack"
	desc = "Contains one Hristov Sniper Rifle and a bandolier containing twelve additional rounds."
	cost = CARGO_CRATE_VALUE * 20
	access = ACCESS_ARMORY
	contains = list(/obj/item/gun/ballistic/rifle/sniper_rifle/hristov,
					/obj/item/storage/belt/bandolier/hristov)
	crate_name = "hristov crate"

/datum/supply_pack/security/armory/lecter
	name = "Lecter Crate"
	desc = "Contains two Lecters and four additional magazines."
	cost = CARGO_CRATE_VALUE * 40
	access = ACCESS_ARMORY
	contains = list(/obj/item/gun/ballistic/automatic/lecter,
					/obj/item/gun/ballistic/automatic/lecter,
					/obj/item/ammo_box/magazine/r556,
					/obj/item/ammo_box/magazine/r556,
					/obj/item/ammo_box/magazine/r556,
					/obj/item/ammo_box/magazine/r556)
	crate_name = "lecter crate"

/datum/supply_pack/security/armory/lectersingle
	name = "Lecter Crate Single-Pack"
	desc = "Contains one Lecter and two additional magazines."
	cost = CARGO_CRATE_VALUE * 22.5
	access = ACCESS_ARMORY
	contains = list(/obj/item/gun/ballistic/automatic/lecter,
					/obj/item/ammo_box/magazine/r556,
					/obj/item/ammo_box/magazine/r556)
	crate_name = "lecter crate"

/datum/supply_pack/security/armory/drozd
	name = "Drozd Crate"
	desc = "Contains two Drozd and four additional magazines."
	cost = CARGO_CRATE_VALUE * 50
	access = ACCESS_ARMORY
	contains = list(/obj/item/gun/ballistic/automatic/drozd,
					/obj/item/gun/ballistic/automatic/drozd,
					/obj/item/ammo_box/magazine/r556,
					/obj/item/ammo_box/magazine/r556,
					/obj/item/ammo_box/magazine/r556,
					/obj/item/ammo_box/magazine/r556)
	crate_name = "drozd crate"

/datum/supply_pack/security/armory/drozdsingle
	name = "Drozd Crate Single-Pack"
	desc = "Contains one Drozd and two additional magazines."
	cost = CARGO_CRATE_VALUE * 30
	access = ACCESS_ARMORY
	contains = list(/obj/item/gun/ballistic/automatic/drozd,
					/obj/item/ammo_box/magazine/r556,
					/obj/item/ammo_box/magazine/r556)
	crate_name = "drozd crate"
