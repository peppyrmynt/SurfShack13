/datum/design/mk58pistol
	name = "Mk58"
	desc = "A modernized handgun of remarkable quality often provided to security forces occupying areas with suitable gravity."
	id = "mk58"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 12, /datum/material/plastic = SHEET_MATERIAL_AMOUNT * 4)
	build_path = /obj/item/gun/ballistic/automatic/pistol/mk58/freshprint
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_RANGED
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/v38_rubber
	name = "Magazine (v38 Rubber) (Less Lethal)"
	desc = "Designed to quickly incapacitate targets in a hurry. Rubber bullets are bouncy and less-than-lethal."
	id = "v38_rubber"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 12)
	build_path = /obj/item/ammo_box/magazine/v38/rubber
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/v38_lethal
	name = "Magazine (v38) (Lethal)"
	desc = "Designed to quickly incapacitate or kill targets in a hurry. Deadly against unarmored foes."
	id = "v38_lethal"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 15)
	build_path = /obj/item/ammo_box/magazine/v38
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/v38_ap
	name = "AP Magazine (v38 AP) (Lethal)"
	desc = "Designed to quickly incapacitate or kill targets in a hurry. Less damaging, but doesn't suffer against armor."
	id = "v38_ap"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 15, /datum/material/diamond = SHEET_MATERIAL_AMOUNT * 2.5)
	build_path = /obj/item/ammo_box/magazine/v38/ap
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/v38_frost
	name = "Magazine (v38 Frost) (Lethal)"
	desc = "Designed to quickly incapacitate or kill targets in a hurry. Less effective against armor, but chills bodies."
	id = "v38_frost"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 15, /datum/material/plasma = SHEET_MATERIAL_AMOUNT * 2.5)
	build_path = /obj/item/ammo_box/magazine/v38/frost
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/v38_talon
	name = "Magazine (v38 Talon) (Lethal)"
	desc = "Designed to quickly incapacitate or kill targets in a hurry. Not as directly lethal, but painful while causing blood loss."
	id = "v38_talon"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 15, /datum/material/silver = SHEET_MATERIAL_AMOUNT * 2.5)
	build_path = /obj/item/ammo_box/magazine/v38/talon
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/v38_bluespace
	name = "Magazine (v38 Bluespace) (Lethal)"
	desc = "Designed to quickly incapacitate or kill targets in a hurry. Less damaging, but incredibly fast."
	id = "v38_bluespace"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 15, /datum/material/bluespace = SHEET_MATERIAL_AMOUNT * 2.5)
	build_path = /obj/item/ammo_box/magazine/v38/bluespace
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/lecter
	name = "Lecter"
	desc = "A high-end military-grade assault rifle capable of mowing down dangerous attackers. Uses 5.56mm rifle ammo."
	id = "lecter"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 20, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 6, /datum/material/plastic = SHEET_MATERIAL_AMOUNT * 4)
	build_path = /obj/item/gun/ballistic/automatic/lecter/freshprint
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_RANGED
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/drozd
	name = "Drozd"
	desc = "An excellent, fully automatic Heavy SMG. Uses 5.56mm rifle ammo."
	id = "drozd"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 20, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 6, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 6, /datum/material/plastic = SHEET_MATERIAL_AMOUNT * 4)
	build_path = /obj/item/gun/ballistic/automatic/drozd/freshprint
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_RANGED
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/ntmag_556
	name = "Magazine (5.56) (Lethal)"
	desc = "Designed to quickly incapacitate or kill targets."
	id = "ntmag_556"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 25)
	build_path = /obj/item/ammo_box/magazine/r556
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/ntmag_556_rubber
	name = "Magazine (5.56 Rubber) (Less Lethal)"
	desc = "Designed to quickly incapacitate targets. Deals significant damage to one's will (to live)."
	id = "ntmag_556_rubber"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 20)
	build_path = /obj/item/ammo_box/magazine/r556/rubber
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/ntmag_556_ap
	name = "Magazine (5.56 AP) (Lethal)"
	desc = "Designed to quickly incapacitate or kill targets. Sacrifices outright damage for armor penetration."
	id = "ntmag_556_ap"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 25, /datum/material/diamond = SHEET_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/ammo_box/magazine/r556/ap
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/ntmag_556_inc
	name = "Magazine (5.56 Incendiary) (Lethal)"
	desc = "Designed to quickly incapacitate or kill targets. Leaves behind trails of fire after being fired."
	id = "ntmag_556_inc"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 25, /datum/material/plasma = SHEET_MATERIAL_AMOUNT * 5)
	build_path = /obj/item/ammo_box/magazine/r556/inc
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/hristov
	name = "Hristov"
	desc = "A long ranged weapon that does significant damage. Uses 7.62 ammo."
	id = "hristov"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 10, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 5, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 10, /datum/material/plastic = SHEET_MATERIAL_AMOUNT * 4)
	build_path = /obj/item/gun/ballistic/rifle/sniper_rifle/hristov/freshprint
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_RANGED
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/nt_a762
	name = "Bullet (7.62mm) (Lethal)"
	desc = "A highly lethal bullet designed to be fired from a Hristov."
	id = "nt_a762"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/ammo_casing/a762
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/nt_a762_raze
	name = "Bullet (7.62mm RAZE) (Lethal)"
	desc = "A highly lethal bullet designed to be fired from a Hristov. Emits a highly intense burst of radiation after being shot into something."
	id = "nt_a762_raze"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 3, /datum/material/uranium = SHEET_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/ammo_casing/a762/raze
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/nt_a762_pen
	name = "Bullet (7.62mm Anti-Material) (Lethal)"
	desc = "A highly lethal bullet designed to be fired from a Hristov. Bypasses structures and armor alike."
	id = "nt_a762_pen"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 3, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2, /datum/material/diamond = SHEET_MATERIAL_AMOUNT * 2)
	build_path = /obj/item/ammo_casing/a762/pen
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/nt_a762_vulcan
	name = "Bullet (7.62mm Vulcan) (Lethal)"
	desc = "A highly lethal bullet designed to be fired from a Hristov. Bullets upon impact explode violently without causing major hazards."
	id = "nt_a762_vulcan"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 3, /datum/material/plasma = SHEET_MATERIAL_AMOUNT * 3)
	build_path = /obj/item/ammo_casing/a762/vulcan
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_AMMO
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/kammerer
	name = "Kammerer"
	desc = "A semi-automatic shotgun with a four-shell capacity. Often favored over compact shotguns for their slightly better performance."
	id = "kammerer"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 14, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 6, /datum/material/plastic = SHEET_MATERIAL_AMOUNT * 4)
	build_path = /obj/item/gun/ballistic/shotgun/automatic/combat/kammerer/nopin
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_RANGED
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY

/datum/design/enforcer
	name = "Enforcer"
	desc = "A semi-auto shotgun for combat in narrow corridors, originally conceived to compete against the syndicate's famous 'Bulldog'."
	id = "enforcer"
	build_type = PROTOLATHE | AWAY_LATHE
	materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 18, /datum/material/glass = SHEET_MATERIAL_AMOUNT * 2, /datum/material/titanium = SHEET_MATERIAL_AMOUNT * 5, /datum/material/plastic = SHEET_MATERIAL_AMOUNT * 4)
	build_path = /obj/item/gun/ballistic/shotgun/enforcer/nopin
	category = list(
		RND_CATEGORY_WEAPONS + RND_SUBCATEGORY_WEAPONS_RANGED
	)
	departmental_flags = DEPARTMENT_BITFLAG_SECURITY
