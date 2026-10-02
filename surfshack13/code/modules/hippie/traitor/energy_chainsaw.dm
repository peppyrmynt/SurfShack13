// Energy Chainsaw - ported from HippieStation.
// Built on Surf's transforming/two-handed chainsaw, with Hippie's values, sprites and sounds.

/obj/item/chainsaw/energy
	name = "energy chainsaw"
	desc = "An incredibly deadly modified chainsaw with plasma-based energy blades instead of metal and a slick black-and-red finish. Become Leatherspace."
	icon = 'surfshack13/icons/hippie/energy_chainsaw.dmi'
	icon_state = "echainsaw_off"
	inhand_icon_state = "echainsaw_off"
	lefthand_file = 'surfshack13/icons/hippie/energy_chainsaw_lefthand.dmi'
	righthand_file = 'surfshack13/icons/hippie/energy_chainsaw_righthand.dmi'
	attack_verb_continuous = list("saws", "shreds", "rends", "guts", "eviscerates")
	attack_verb_simple = list("saw", "shred", "rend", "gut", "eviscerate")
	force_on = 60
	armour_penetration = 15
	block_chance = 50

/obj/item/chainsaw/energy/on_transform(obj/item/source, mob/user, active)
	. = ..()
	icon_state = active ? "echainsaw_on" : "echainsaw_off"
	inhand_icon_state = icon_state
	hitsound = active ? pick('surfshack13/sound/hippie/echainsawhit1.ogg', 'surfshack13/sound/hippie/echainsawhit2.ogg') : initial(hitsound)
	playsound(src, active ? 'surfshack13/sound/hippie/echainsawon.ogg' : 'surfshack13/sound/hippie/echainsawoff.ogg', 50, TRUE)
	update_inhand_icon()

/obj/item/chainsaw/energy/afterattack(atom/target, mob/user, click_parameters)
	. = ..()
	// Hippie alternated between two hit sounds.
	if(HAS_TRAIT(src, TRAIT_TRANSFORM_ACTIVE))
		hitsound = pick('surfshack13/sound/hippie/echainsawhit1.ogg', 'surfshack13/sound/hippie/echainsawhit2.ogg')

/datum/uplink_item/dangerous/energy_chainsaw
	name = "Energy Chainsaw"
	desc = "An incredibly deadly modified chainsaw with plasma-based energy blades instead of metal and a slick black-and-red finish. \
		While it rips apart matter with extreme efficiency, it is heavy, large, and monstrously loud."
	item = /obj/item/chainsaw/energy
	cost = 14
	purchasable_from = UPLINK_TRAITORS | UPLINK_SERIOUS_OPS
