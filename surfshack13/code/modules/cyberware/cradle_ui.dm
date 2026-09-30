/**
 * # Chrome Cradle console support
 *
 * Everything the cradle interface needs that is not the machine itself: how
 * chrome is filed into rows on screen, what Splice charges for each piece, and
 * the two art assets the console draws itself with.
 */

// ---- Slot grouping -----------------------------------------------------

/**
 * How the cradle files chrome on screen: one row per body system, in head-down
 * order, each owning the organ slots that live there. This is presentation
 * only, the slots themselves are the real uniqueness rule.
 *
 * Anything chrome whose slot isn't listed here falls into a trailing "Other
 * Hardware" group rather than vanishing, so a new slot always shows up
 * somewhere even before it gets a home.
 */
GLOBAL_LIST_INIT(cyberware_ui_groups, list(
	list("id" = "cortex", "name" = "Frontal Cortex", "region" = "head", "slots" = list(ORGAN_SLOT_CYBERWARE_GOVERNOR)),
	list("id" = "ocular", "name" = "Ocular System", "region" = "head", "slots" = list(ORGAN_SLOT_EYES)),
	list("id" = "aural", "name" = "Auditory System", "region" = "head", "slots" = list(ORGAN_SLOT_CYBERWARE_EARS, ORGAN_SLOT_CYBERWARE_LARYNX)),
	list("id" = "os", "name" = "Operating System", "region" = "torso", "slots" = list(ORGAN_SLOT_CYBERWARE_OS)),
	list("id" = "nervous", "name" = "Nervous System", "region" = "torso", "slots" = list(ORGAN_SLOT_CYBERWARE_NERVOUS)),
	list("id" = "circulatory", "name" = "Circulatory System", "region" = "torso", "slots" = list(ORGAN_SLOT_CYBERWARE_FILTER, ORGAN_SLOT_HEART_AID, ORGAN_SLOT_CYBERWARE_HEART_AUX)),
	list("id" = "seal", "name" = "Environment Seal", "region" = "torso", "slots" = list(ORGAN_SLOT_CYBERWARE_SEAL)),
	list("id" = "integumentary", "name" = "Integumentary System", "region" = "torso", "slots" = list(ORGAN_SLOT_CYBERWARE_DERMAL, ORGAN_SLOT_CYBERWARE_SKIN, ORGAN_SLOT_CYBERWARE_INK)),
	list("id" = "skeleton", "name" = "Skeletal Frame", "region" = "torso", "slots" = list(ORGAN_SLOT_CYBERWARE_FRAME)),
	list("id" = "digestive", "name" = "Digestive Tract", "region" = "torso", "slots" = list(ORGAN_SLOT_CYBERWARE_GUT, ORGAN_SLOT_CYBERWARE_STASH)),
	list("id" = "arms", "name" = "Arm Hardware", "region" = "arms", "slots" = list(ORGAN_SLOT_RIGHT_ARM_AUG, ORGAN_SLOT_LEFT_ARM_AUG)),
	list("id" = "hands", "name" = "Hands", "region" = "arms", "slots" = list(ORGAN_SLOT_CYBERWARE_HANDS)),
	list("id" = "legs", "name" = "Mobility", "region" = "legs", "slots" = list(ORGAN_SLOT_CYBERWARE_LEGS)),
))

/// slot string -> the group id that owns it. Built once off the table above.
GLOBAL_LIST_EMPTY(cyberware_slot_to_group)

/// Which UI group a piece of chrome files under. Never null: unrecognised
/// slots land in the catch-all.
/proc/get_cyberware_group_id(obj/item/organ/ware)
	if(!length(GLOB.cyberware_slot_to_group))
		for(var/list/group as anything in GLOB.cyberware_ui_groups)
			for(var/slot in group["slots"])
				GLOB.cyberware_slot_to_group[slot] = group["id"]
	return GLOB.cyberware_slot_to_group[ware.slot] || "other"

// ---- Price tags --------------------------------------------------------

/// Voidcrew's cradle quoted Splice's shop price next to each card. Chrome on
/// the station comes off the protolathe, so there is no price to show.
/proc/get_cyberware_price(obj/item/organ/ware)
	return null

// ---- Console art -------------------------------------------------------

/**
 * Console faceplate. Its bezels match the interface GEOMETRY coordinates.
 */
/datum/asset/simple/chrome_cradle_plate
	assets = list(
		"chrome_cradle_plate.png" = 'surfshack13/icons/cyberware/chrome_cradle_plate.png',
	)

// ---- Card art ----------------------------------------------------------

/**
 * Inventory sprites for the rack cards, as one CSS spritesheet rather than a
 * base64 blob per row: the cradle re-pushes its whole ware list on every servo
 * beat of an install, and inlined icons would put the entire roster on the wire
 * several times a second.
 *
 * Keyed by icon state, since that IS what makes two pieces look different.
 * The interface builds `chrome32x32 <key>` off the `icon` field of a ware.
 */
/datum/asset/spritesheet/chrome
	name = "chrome"

/datum/asset/spritesheet/chrome/create_spritesheets()
	var/list/seen = list()
	var/list/ware_types = typesof(/obj/item/organ/cyberimp/cyberware) \
		+ typesof(/obj/item/organ/eyes/robotic/cyberware) \
		+ typesof(/obj/item/organ/cyberimp/arm/cyberware)
	for(var/obj/item/organ/ware as anything in ware_types)
		var/state = initial(ware.icon_state)
		if(!state || seen[state])
			continue
		var/icon_file = initial(ware.icon)
		if(!icon_exists(icon_file, state))
			continue
		seen[state] = TRUE
		Insert(get_cyberware_card_icon_key(state), icon_file, state, SOUTH)

/// The spritesheet key for a ware's card art. Prefixed so chrome states can
/// never collide with another sheet's class names.
/proc/get_cyberware_card_icon_key(icon_state)
	return "chrome-[icon_state]"

