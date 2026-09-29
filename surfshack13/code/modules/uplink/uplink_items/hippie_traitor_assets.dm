// Original HippieStation presentation for the restored traitor gear.
// Mechanics stay on SurfShack's current systems; these paths use byte-for-byte imported Hippie assets.

/obj/item/chainsaw/energy
	icon = 'surfshack13/icons/hippie/energy_chainsaw.dmi'
	icon_state = "echainsaw_off"
	inhand_icon_state = "echainsaw_off"
	lefthand_file = 'surfshack13/icons/hippie/energy_chainsaw_lefthand.dmi'
	righthand_file = 'surfshack13/icons/hippie/energy_chainsaw_righthand.dmi'
	w_class = WEIGHT_CLASS_HUGE

/obj/item/chainsaw/energy/Initialize(mapload)
	. = ..()
	var/datum/component/transforming/transform_comp = GetComponent(/datum/component/transforming)
	if(transform_comp)
		transform_comp.hitsound_on = pick(
			'surfshack13/sound/hippie/echainsawhit1.ogg',
			'surfshack13/sound/hippie/echainsawhit2.ogg',
		)

/obj/item/chainsaw/energy/on_transform(obj/item/source, mob/user, active)
	. = ..()
	icon_state = active ? "echainsaw_on" : "echainsaw_off"
	inhand_icon_state = icon_state
	if(active)
		hitsound = pick(
			'surfshack13/sound/hippie/echainsawhit1.ogg',
			'surfshack13/sound/hippie/echainsawhit2.ogg',
		)
	else
		hitsound = initial(hitsound)
	playsound(src, active ? 'surfshack13/sound/hippie/echainsawon.ogg' : 'surfshack13/sound/hippie/echainsawoff.ogg', 50, TRUE)
	update_inhand_icon()
	return COMPONENT_NO_DEFAULT_MESSAGE

/obj/item/highfrequencyblade/hippie
	name = "high frequency blade"
	desc = "RULES OF NATURE"
	icon = 'surfshack13/icons/hippie/hfblade.dmi'
	icon_state = "hfblade"
	inhand_icon_state = "hfblade"
	lefthand_file = 'surfshack13/icons/hippie/hfblade_lefthand.dmi'
	righthand_file = 'surfshack13/icons/hippie/hfblade_righthand.dmi'
	var/brazil = FALSE

/obj/item/highfrequencyblade/hippie/update_icon_state()
	icon_state = brazil ? "hfblade-red" : "hfblade"
	inhand_icon_state = icon_state
	return NONE

/obj/item/highfrequencyblade/hippie/attackby(obj/item/used_item, mob/living/user, params)
	if(istype(used_item, /obj/item/multitool))
		if(brazil)
			to_chat(user, span_notice("Don't get edgier than this, son."))
			return TRUE
		to_chat(user, span_notice("You enable the buttrock speakers on the sword. Its new red color faintly reminds you of Brazil, for some reason."))
		desc = "Said to have been passed down from several British weeaboos, and one of them outfitted the sword with speakers to play music. Come to Brazil."
		brazil = TRUE
		pickup_sound = 'surfshack13/sound/hippie/hfblade-music1.ogg'
		drop_sound = 'surfshack13/sound/hippie/hfblade-music2.ogg'
		set_light(7, 1, "red")
		update_appearance()
		update_inhand_icon()
		playsound(user, 'sound/vehicles/clowncar_fart.ogg', 50, TRUE)
		return TRUE
	return ..()

/obj/item/storage/belt/hfblade/hippie
	name = "edgelord's sheath"
	desc = "A strange sheath designed to hold an electric blade of some sort. One could only imagine how edgy this guy's musical preference is."
	icon = 'surfshack13/icons/hippie/hfblade.dmi'
	icon_state = "sheath-sabre"
	inhand_icon_state = "sheath-sabre"
	worn_icon = 'surfshack13/icons/hippie/hfblade_worn.dmi'
	worn_icon_state = "sheath-sabre"
	w_class = WEIGHT_CLASS_BULKY

/obj/item/storage/belt/hfblade/hippie/Initialize(mapload)
	. = ..()
	atom_storage.max_slots = 1
	atom_storage.max_specific_storage = WEIGHT_CLASS_HUGE
	atom_storage.max_total_storage = 16
	atom_storage.set_holdable(/obj/item/highfrequencyblade/hippie)
	atom_storage.open_sound = 'sound/items/unsheath.ogg'

/obj/item/storage/belt/hfblade/hippie/PopulateContents()
	new /obj/item/highfrequencyblade/hippie(src)
	update_appearance()

/obj/item/storage/belt/hfblade/hippie/update_icon_state()
	. = ..()
	var/new_state = length(contents) ? "sheath-sabre" : "sheath"
	icon_state = new_state
	inhand_icon_state = new_state
	worn_icon_state = new_state

// Original CryNet item art and action button art on top of the modern MOD implementation.
/obj/item/mod/control/pre_equipped/crynet/faithful
	icon = 'surfshack13/icons/hippie/nanosuit.dmi'
	icon_state = "nanosuit"

/datum/mod_theme/elite/crynet/set_skin(obj/item/mod/control/mod, skin)
	. = ..()
	mod.icon = 'surfshack13/icons/hippie/nanosuit.dmi'
	mod.icon_state = "nanosuit"
	for(var/obj/item/clothing/part as anything in mod.get_parts())
		if(istype(part, /obj/item/clothing/suit/mod))
			part.icon = 'surfshack13/icons/hippie/nanosuit.dmi'
			part.worn_icon = 'surfshack13/icons/hippie/nanosuit_worn.dmi'
			part.icon_state = "nanosuit"
			part.worn_icon_state = "nanosuit"
		else if(istype(part, /obj/item/clothing/head/mod))
			part.icon = 'surfshack13/icons/hippie/nanosuit.dmi'
			part.worn_icon = 'surfshack13/icons/hippie/nanosuit_worn.dmi'
			part.icon_state = "nanohelmet"
			part.worn_icon_state = "nanohelmet"

/obj/item/mod/module/crynet_mode/armor
	icon = 'surfshack13/icons/hippie/actions_nanosuit.dmi'
	icon_state = "armor_mode"

/obj/item/mod/module/crynet_mode/cloak
	icon = 'surfshack13/icons/hippie/actions_nanosuit.dmi'
	icon_state = "cloak_mode"

/obj/item/mod/module/crynet_mode/speed
	icon = 'surfshack13/icons/hippie/actions_nanosuit.dmi'
	icon_state = "speed_mode"

/obj/item/mod/module/crynet_mode/strength
	icon = 'surfshack13/icons/hippie/actions_nanosuit.dmi'
	icon_state = "strength_mode"

/obj/item/mod/module/visor/night/crynet
	name = "CryNet night vision visor"
	icon = 'surfshack13/icons/hippie/actions_nanosuit.dmi'
	icon_state = "toggle_goggle"
