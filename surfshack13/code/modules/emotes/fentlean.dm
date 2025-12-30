//this is hacky and intensive, dont merge merge pls

/datum/emote/living/carbon/human/fentlean
	key = "fentlean"
	key_third_person = "stop breathing and fold over"
	message = "stops breathing and folds over!"
	emote_type = EMOTE_VISIBLE
	cooldown = 10 SECONDS


/datum/emote/living/carbon/human/fentlean/run_emote(mob/living/carbon/human/H, params, type_override, intentional)
	H.AddComponent(/datum/component/fentlean)

/datum/movespeed_modifier/fentlean
	multiplicative_slowdown = 9


/datum/component/fentlean
	dupe_mode = COMPONENT_DUPE_UNIQUE

	var/alist/limbs
	var/obj/skeleton
	/// Parent
	var/mob/living/carbon/human/H

	var/icon/head_icon
	var/icon/chest_icon
	var/icon/arms_icon
	var/icon/legs_icon

	var/alist/icons

/datum/component/fentlean/Initialize(time = 8 SECONDS)
	. = ..()
	H = parent
	if(!ishuman(H))
		return COMPONENT_INCOMPATIBLE

	// drop held items, hat and bag fall off
	H.drop_all_held_items()
	H.dropItemToGround(H.head)
	H.dropItemToGround(H.back)
	// slow
	H.add_movespeed_modifier(/datum/movespeed_modifier/fentlean, update = TRUE)

	// grab back of mob
	H.dir = NORTH
	var/icon/north_flat = getFlatIcon(H)
	sleep(1)
	// grab front
	H.dir = SOUTH
	var/icon/south_flat =  getFlatIcon(H)
	// carve up limbs
	head_icon = new (icon = 'surfshack13/icons/mob/human/fentlean/limbcutter.dmi', icon_state = "head")
	head_icon.Blend(north_flat, ICON_MULTIPLY)
	chest_icon = new (icon = 'surfshack13/icons/mob/human/fentlean/limbcutter.dmi', icon_state = "chest")
	chest_icon.Blend(north_flat, ICON_MULTIPLY)
	qdel(north_flat)
	arms_icon = new (icon = 'surfshack13/icons/mob/human/fentlean/limbcutter.dmi', icon_state = "arms")
	arms_icon.Blend(south_flat, ICON_MULTIPLY)
	legs_icon = new (icon = 'surfshack13/icons/mob/human/fentlean/limbcutter.dmi', icon_state = "legs")
	legs_icon.Blend(south_flat, ICON_MULTIPLY)
	qdel(south_flat)

	head_icon.Crop(9, 23, 23, 32)
	chest_icon.Crop(12, 10, 20, 22)
	icons = alist("head" = head_icon, "chest" =  chest_icon, "arms" = arms_icon, "legs" = legs_icon)

	//overlay bodyparts onto invisible mob
	H.alpha = 1 //catch mouse clicks
	skeleton = new /obj/effect/(get_turf(H))
	skeleton.mouse_opacity = FALSE

	limbs = alist()
	for(var/limb_name in icons)
		var/obj/limb_obj = new /obj/effect()
		limb_obj.icon = icons[limb_name]
		limb_obj.icon_state = limb_name
		limb_obj.layer = ABOVE_ALL_MOB_LAYER
		limbs[limb_name] = limb_obj
		skeleton.vis_contents += limb_obj

	// move bodyparts around so the player appears folded over.
	limbs["head"].pixel_y = 2
	limbs["head"].pixel_x = 8
	limbs["head"].layer += 0.02
	limbs["head"].transform = matrix().Turn(180)

	var/matrix/chest_matrix = matrix().Turn(180)
	chest_matrix.Scale(1, 0.5)
	limbs["chest"].pixel_y = 9
	limbs["chest"].pixel_x = 11
	limbs["chest"].layer += 0.01
	limbs["chest"].transform = chest_matrix

	limbs["arms"].pixel_y = -7
	limbs["arms"].layer += 0.01
	RegisterSignal(H, COMSIG_MOVABLE_MOVED, PROC_REF(on_parent_move))
	addtimer(CALLBACK(src, PROC_REF(Destroy)),time)

/datum/component/fentlean/Destroy(force)
	QDEL_LIST_ASSOC_VAL(limbs)
	QDEL_LIST_ASSOC_VAL(icons)
	UnregisterSignal(H, COMSIG_MOVABLE_MOVED)
	qdel(skeleton)
	H.remove_movespeed_modifier(/datum/movespeed_modifier/fentlean, update = TRUE)
	H.alpha = 255
	. = ..()

/datum/component/fentlean/proc/on_parent_move(atom/source)
	skeleton.loc = get_turf(source)
