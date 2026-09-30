// Ported from tgstation: the NT-20 'Excalibur' stunsword, a two-in-one claymore and stun baton.
// Sprites are in surfshack13/icons (copied from tg's baton.dmi and 64x64 inhand files).

/obj/item/melee/baton/security/stunsword
	name = "\improper NT-20 'Excalibur' Stunsword"
	desc = "It's a sword. It stuns. What more could you want?"
	icon = 'surfshack13/icons/obj/weapons/stunsword.dmi'
	icon_state = "stunsword"
	inhand_icon_state = "stunsword"
	lefthand_file = 'surfshack13/icons/mob/inhands/stunsword_lefthand.dmi'
	righthand_file = 'surfshack13/icons/mob/inhands/stunsword_righthand.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	attack_verb_continuous = list("attacks", "slashes", "slices", "tears", "lacerates", "rips", "dices", "cuts")
	attack_verb_simple = list("attack", "slash", "slice", "tear", "lacerate", "rip", "dice", "cut")
	w_class = WEIGHT_CLASS_HUGE
	sharpness = SHARP_EDGED
	force = 30
	throwforce = 10
	wound_bonus = 0
	throw_stun_chance = 60
	convertible = FALSE
	obj_flags = UNIQUE_RENAME
	unique_reskin = list(
		"Default" = "stunsword",
		"Energy" = "stunsword_energy",
	)
	unique_reskin_changes_inhand = TRUE
	/// Sprite base, changes when reskinned
	var/skin_base = "stunsword"

/obj/item/melee/baton/security/stunsword/reskin_obj(mob/user)
	. = ..()
	skin_base = unique_reskin[current_skin] || "stunsword"
	update_appearance()

/obj/item/melee/baton/security/stunsword/update_icon_state()
	. = ..()
	// The security baton keys its sprite off initial(icon_state), which breaks the energy skin, so set it ourselves
	var/state_suffix = ""
	if(active)
		state_suffix = "_active"
	else if(!cell)
		state_suffix = "_nocell"
	icon_state = "[skin_base][state_suffix]"
	inhand_icon_state = active ? "[skin_base]_active" : skin_base

/// Comes with a good cell installed, for crates
/obj/item/melee/baton/security/stunsword/loaded
	preload_cell_type = /obj/item/stock_parts/power_store/cell/super

/datum/crafting_recipe/stunsword
	name = "\improper NT-20 'Excalibur' Stunsword"
	result = /obj/item/melee/baton/security/stunsword
	reqs = list(
		/obj/item/claymore = 1,
		/obj/item/melee/baton/security = 1,
	)
	blacklist = list(
		/obj/item/claymore/cutlass,
		/obj/item/claymore/cutlass/old,
		/obj/item/claymore/carrot,
		/obj/item/claymore/shortsword,
		/obj/item/claymore/highlander,
		/obj/item/claymore/weak,
		/obj/item/claymore/weak/ceremonial,
		/obj/item/claymore/highlander/robot,
	)
	tool_behaviors = list(TOOL_WELDER)
	time = 10 SECONDS
	category = CAT_WEAPON_MELEE

/datum/crafting_recipe/stunswordalt
	name = "\improper NT-20 'Excalibur' Stunsword"
	result = /obj/item/melee/baton/security/stunsword
	reqs = list(
		/obj/item/katana = 1,
		/obj/item/melee/baton/security = 1,
	)
	tool_behaviors = list(TOOL_WELDER)
	time = 10 SECONDS
	category = CAT_WEAPON_MELEE

/datum/crafting_recipe/stunswordalt2
	name = "\improper NT-20 'Excalibur' Stunsword"
	result = /obj/item/melee/baton/security/stunsword
	reqs = list(
		/obj/item/melee/sabre = 1,
		/obj/item/melee/baton/telescopic/contractor_baton = 1,
	)
	tool_behaviors = list(TOOL_WELDER)
	time = 10 SECONDS
	category = CAT_WEAPON_MELEE
