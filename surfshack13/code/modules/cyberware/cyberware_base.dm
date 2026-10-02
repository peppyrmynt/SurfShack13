/**
 * # Cyberware organ bases
 *
 * Two bases, one behavior. Most ware extends /obj/item/organ/cyberimp/cyberware;
 * the optics ladder extends /obj/item/organ/eyes/robotic/cyberware instead so
 * it inherits the robotic eyes' nightvision/flash/EMP-static plumbing (and
 * evicting it costs you your meat eyes, that flavor is kept on purpose).
 * Single inheritance forces the split, so both bases carry the same thin set
 * of overrides and delegate everything real to /datum/component/cyberware and
 * the shared procs below.
 *
 * The install rules, enforced at the ORGAN so this fork's universal
 * TRAIT_SELF_SURGERY hits the same wall as everyone else:
 * - Capacity: net load after the swap must fit: the check nets out whatever
 *   incumbent the insert would replace, so ladder upgrades work at high load.
 * - Context: Insert() outside organ-manipulation surgery, the Chrome Cradle
 *   or special = TRUE (init/admin) is refused. Bare autosurgeons choke.
 * On refusal the organ always survives where it was: Insert() returns FALSE
 * before ..(), and the autosurgeon keeps its stored organ on a FALSE return
 * (autosurgeon.dm's "insertion failed!" path).
 */
/**
 * The worn-chrome overlay. Surf's tg base predates organ augment overlays, so
 * chrome carries its own: a simple bodypart overlay added to the limb the ware
 * sits in on insert and taken back off on removal. It draws at
 * CYBERWARE_WORN_LAYER: over underwear and undershirts, still under eyes,
 * damage, and every EQUIPPED clothing layer.
 */
/datum/bodypart_overlay/simple/cyberware
	icon = 'surfshack13/icons/cyberware/cyberware_worn.dmi'
	layers = EXTERNAL_ADJACENT
	/// Glow twin: "[icon_state]_e" is drawn as an emissive over the plate.
	var/emissive = FALSE
	/// Optional extra plate drawn at the hand's own layer (Gorilla Arms).
	var/hand_state

/datum/bodypart_overlay/simple/cyberware/bitflag_to_layer(layer)
	if(layer == EXTERNAL_ADJACENT)
		return -CYBERWARE_WORN_LAYER
	return ..()

/datum/bodypart_overlay/simple/cyberware/get_overlay(layer, obj/item/bodypart/limb)
	. = ..()
	if(!islist(.))
		. = list(.)
	var/image_layer = bitflag_to_layer(layer)
	if(emissive && limb && icon_exists(icon, "[icon_state]_e"))
		. += emissive_appearance(icon, "[icon_state]_e", limb, layer = image_layer)
	if(hand_state && icon_exists(icon, hand_state))
		. += image(icon = icon, icon_state = hand_state, layer = -BODYPARTS_HIGH_LAYER)

/datum/bodypart_overlay/simple/cyberware/generate_icon_cache()
	. = ..()
	. += "[emissive]"
	. += "[hand_state]"

/// The worn state this ware draws on its limb, or null for hidden chrome.
/obj/item/organ/proc/get_chrome_overlay_state()
	return null

/// Paints this ware's worn overlay onto the limb it sits in.
/obj/item/organ/proc/apply_chrome_overlay(mob/living/carbon/bearer)
	var/state = get_chrome_overlay_state()
	if(!state || !istype(bearer))
		return
	var/obj/item/bodypart/limb = bearer.get_bodypart(deprecise_zone(zone))
	if(!limb)
		return
	var/datum/bodypart_overlay/simple/cyberware/plate = new()
	plate.icon_state = state
	plate.emissive = chrome_overlay_emissive_enabled()
	if(icon_exists(plate.icon, "[state]_hand"))
		plate.hand_state = "[state]_hand"
	chrome_worn_plate = plate
	chrome_worn_limb = WEAKREF(limb)
	limb.add_bodypart_overlay(plate)

/// Takes the worn overlay back off whatever limb it was painted on.
/obj/item/organ/proc/clear_chrome_overlay()
	if(!chrome_worn_plate)
		return
	var/obj/item/bodypart/limb = chrome_worn_limb?.resolve()
	limb?.remove_bodypart_overlay(chrome_worn_plate)
	QDEL_NULL(chrome_worn_plate)
	chrome_worn_limb = null

/obj/item/organ/proc/chrome_overlay_emissive_enabled()
	return FALSE

/obj/item/organ
	/// The worn-chrome plate currently painted on a limb, if any.
	var/datum/bodypart_overlay/simple/cyberware/chrome_worn_plate
	/// The limb that plate is painted on.
	var/datum/weakref/chrome_worn_limb

/obj/item/organ/cyberimp/cyberware
	name = "cyberware"
	desc = "Aftermarket chrome. Someone sat in a parlor chair for this."
	icon = 'surfshack13/icons/cyberware/cyberware.dmi'
	// Worn look: ware that reads from outside the body sets chrome_overlay to a
	// state in this sheet and tg's bodypart-overlay pipeline draws it ON the
	// bearer, over the character-setup underwear, under equipped clothing.
	// Stack enough chrome and you stop looking human.
	organ_flags = ORGAN_ROBOTIC
	failing_desc = "is dark and inert, browned out, EMP-scrambled, or plain broken."
	/// Neural load this ware puts on its bearer. 0-12; see the tier bands.
	var/chrome_load = 1
	/// CYBERWARE_TIER_*, drives accent colours and the parlor experience.
	var/tier = CYBERWARE_TIER_1
	/// Chrome capacity this ware grants while installed (the Governor hook).
	var/chrome_capacity_bonus = 0
	/// Worn look: a state in cyberware_worn.dmi drawn ON the bearer's limb.
	/// Stack enough chrome and you stop looking human.
	var/chrome_overlay
	/// Whether the worn look has a glowing "_e" twin.
	var/chrome_overlay_emissive = FALSE

/obj/item/organ/cyberimp/cyberware/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/cyberware, chrome_load, tier, chrome_capacity_bonus)

/obj/item/organ/cyberimp/cyberware/get_chrome_overlay_state()
	return chrome_overlay

/obj/item/organ/cyberimp/cyberware/chrome_overlay_emissive_enabled()
	return chrome_overlay_emissive

/obj/item/organ/cyberimp/cyberware/Destroy()
	// Never silently eat contents: the Cargo Cavity keeps a player's stash in
	// here, and anything else a subtype stores deserves the same courtesy.
	// No turf (nullspace deletion) means there is genuinely nowhere to drop.
	var/turf/drop_turf = get_turf(src)
	if(drop_turf)
		for(var/obj/item/held in src)
			held.forceMove(drop_turf)
	return ..()

/obj/item/organ/cyberimp/cyberware/examine(mob/user)
	. = ..()
	. += span_notice("Neural load: <b>[chrome_load]</b>[chrome_capacity_bonus ? ", grants +[chrome_capacity_bonus] chrome capacity" : ""]. Tier [tier] chrome, install at a Chrome Cradle or through organ-manipulation surgery.")
	. += cyberware_emp_examine_line()

/obj/item/organ/cyberimp/cyberware/Insert(mob/living/carbon/receiver, special = FALSE, movement_flags)
	if(!special && !cyberware_can_insert(src, receiver))
		return FALSE
	return ..()

/obj/item/organ/cyberimp/cyberware/pre_surgical_insertion(mob/living/user, mob/living/carbon/new_owner, target_zone)
	// Capacity refusal happens up front, before the parent gets a say, so the
	// surgeon hears why the step failed instead of fumbling a full operation.
	if(!cyberware_insert_check(src, new_owner, feedback_to = user))
		return FALSE
	. = ..()
	if(!.)
		return
	var/datum/component/cyberware/chrome = GetComponent(/datum/component/cyberware)
	chrome?.grant_install_context(new_owner)

/obj/item/organ/cyberimp/cyberware/on_mob_insert(mob/living/carbon/organ_owner, special = FALSE, movement_flags)
	. = ..()
	if(!special)
		cyberware_boot_splash(organ_owner, src)

/obj/item/organ/cyberimp/cyberware/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	var/datum/component/cyberware/chrome = GetComponent(/datum/component/cyberware)
	if(!chrome || chrome.emp_down)
		return
	chrome.start_emp_reboot(severity)
	if(owner)
		owner.balloon_alert(owner, "[name] glitches out!")
		do_sparks(2, TRUE, owner)

/**
 * # Cyberware optics base
 *
 * The eyes-side twin of the base above, for the Nightshade -> Deadeye /
 * Prospector ladder. Uses tg's ORGAN_SLOT_EYES, the design's
 * `cyberware_optics` slot is dead, so installing chrome optics replaces
 * your eyes outright. Robotic-eyes EMP static still fires through ..();
 * our reboot downtime stacks on top of it.
 *
 * Every optic on this base carries the chrome read (cyberware_scan.dm), the
 * diagnostic bus is what makes chrome eyes chrome eyes. Subtypes that add
 * their own ability must keep the read in their actions_types list.
 */
/obj/item/organ/eyes/robotic/cyberware
	name = "cyberware optics"
	desc = "Aftermarket eyes. The irises catch the light in a way real ones don't."
	icon = 'surfshack13/icons/cyberware/cyberware.dmi'
	icon_state = "nightshade"
	actions_types = list(/datum/action/cooldown/cyberware/chrome_read)
	/// Neural load this ware puts on its bearer.
	var/chrome_load = 1
	/// CYBERWARE_TIER_*, drives accent colours and the parlor experience.
	var/tier = CYBERWARE_TIER_1
	/// Chrome capacity this ware grants while installed (the Governor hook).
	var/chrome_capacity_bonus = 0
	/// How much of a body the chrome read resolves, CYBERWARE_SCAN_SILHOUETTE
	/// counts signatures, CYBERWARE_SCAN_ITEMIZED names every one of them.
	var/chrome_scan_resolution = CYBERWARE_SCAN_ITEMIZED

/obj/item/organ/eyes/robotic/cyberware/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/cyberware, chrome_load, tier, chrome_capacity_bonus)

/obj/item/organ/eyes/robotic/cyberware/Destroy()
	var/turf/drop_turf = get_turf(src)
	if(drop_turf)
		for(var/obj/item/held in src)
			held.forceMove(drop_turf)
	return ..()

/obj/item/organ/eyes/robotic/cyberware/examine(mob/user)
	. = ..()
	. += span_notice("Neural load: <b>[chrome_load]</b>. Tier [tier] chrome, install at a Chrome Cradle or through organ-manipulation surgery.")
	. += span_notice("Diagnostic bus: [chrome_scan_resolution >= CYBERWARE_SCAN_ITEMIZED ? "reads a body's chrome piece by piece" : "counts a body's chrome signatures, but can't name them"].")
	. += cyberware_emp_examine_line()

/obj/item/organ/eyes/robotic/cyberware/Insert(mob/living/carbon/receiver, special = FALSE, movement_flags)
	if(!special && !cyberware_can_insert(src, receiver))
		return FALSE
	return ..()

/obj/item/organ/eyes/robotic/cyberware/pre_surgical_insertion(mob/living/user, mob/living/carbon/new_owner, target_zone)
	if(!cyberware_insert_check(src, new_owner, feedback_to = user))
		return FALSE
	. = ..()
	if(!.)
		return
	var/datum/component/cyberware/chrome = GetComponent(/datum/component/cyberware)
	chrome?.grant_install_context(new_owner)

/obj/item/organ/eyes/robotic/cyberware/on_mob_insert(mob/living/carbon/organ_owner, special = FALSE, movement_flags)
	. = ..()
	if(!special)
		cyberware_boot_splash(organ_owner, src)

/obj/item/organ/eyes/robotic/cyberware/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	var/datum/component/cyberware/chrome = GetComponent(/datum/component/cyberware)
	if(!chrome || chrome.emp_down)
		return
	chrome.start_emp_reboot(severity)
	if(owner)
		owner.balloon_alert(owner, "[name] glitches out!")
		do_sparks(2, TRUE, owner)

/**
 * # Cyberware deployable-arm base
 *
 * The arm-weapon twin, for chrome that extends/retracts a held item, Mantis
 * Blades, Widowline Monowire, the Popup Ronin, Bunker Buster, Icepick Jack,
 * Skyhook, Graverobber, Angler, Fixer's Fingers, Rockjaw. It rides tg's
 * /obj/item/organ/cyberimp/arm/toolkit for the whole extend/retract/radial/
 * NODROP dance and layers the same chrome gate on top. Load splits across the
 * two arms for paired ware: each arm organ carries half, so the per-slot
 * incumbent netting Just Works with no pair-aware override.
 */
/obj/item/organ/cyberimp/arm/cyberware
	name = "arm cyberware"
	desc = "Aftermarket arm hardware. Folds away until you want it."
	icon = 'surfshack13/icons/cyberware/cyberware.dmi'
	icon_state = "fixers"
	/// Neural load this ware puts on its bearer.
	var/chrome_load = 1
	/// CYBERWARE_TIER_*, drives accent colours and the parlor experience.
	var/tier = CYBERWARE_TIER_1
	/// Chrome capacity this ware grants while installed.
	var/chrome_capacity_bonus = 0
	/// Worn look base name; the installed side appends "_left"/"_right".
	var/chrome_overlay

/obj/item/organ/cyberimp/arm/cyberware/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/cyberware, chrome_load, tier, chrome_capacity_bonus)

/obj/item/organ/cyberimp/arm/cyberware/get_chrome_overlay_state()
	if(!chrome_overlay)
		return null
	return "[chrome_overlay]_[zone == BODY_ZONE_R_ARM ? "right" : "left"]"

/obj/item/organ/cyberimp/arm/cyberware/examine(mob/user)
	. = ..()
	. += span_notice("Neural load: <b>[chrome_load]</b>. Tier [tier] chrome, install at a Chrome Cradle or through organ-manipulation surgery.")
	. += cyberware_emp_examine_line()

/obj/item/organ/cyberimp/arm/cyberware/Insert(mob/living/carbon/receiver, special = FALSE, movement_flags)
	if(!special && !cyberware_can_insert(src, receiver))
		return FALSE
	return ..()

/obj/item/organ/cyberimp/arm/cyberware/pre_surgical_insertion(mob/living/user, mob/living/carbon/new_owner, target_zone)
	if(!cyberware_insert_check(src, new_owner, feedback_to = user))
		return FALSE
	. = ..()
	if(!.)
		return
	var/datum/component/cyberware/chrome = GetComponent(/datum/component/cyberware)
	chrome?.grant_install_context(new_owner)

/obj/item/organ/cyberimp/arm/cyberware/on_mob_insert(mob/living/carbon/arm_owner, special = FALSE, movement_flags)
	. = ..()
	if(!special)
		cyberware_boot_splash(arm_owner, src)

// Deploying and stowing arm hardware is the most visible thing a piece of
// chrome does, so it is also the ink's most common cue: every toolkit arm
// (Fixer's Fingers picking a tool off the radial, the Rockjaw drill, blades,
// launchers) lights the bearer up on the way out and on the way back in.
/obj/item/organ/cyberimp/arm/cyberware/Extend(obj/item/augment)
	. = ..()
	// The parent assigns active_item before it knows whether a hand is free
	// (augments_arms.dm), so "did it deploy" is "did it leave us", not "is it set".
	if(active_item && !(active_item in src))
		cyberware_ink_pulse(owner, CYBERWARE_INK_HARD)

/obj/item/organ/cyberimp/arm/cyberware/Retract()
	var/mob/living/carbon/stowing_owner = owner
	. = ..()
	if(.)
		cyberware_ink_pulse(stowing_owner, CYBERWARE_INK_SOFT)

/obj/item/organ/cyberimp/arm/cyberware/emp_act(severity)
	. = ..() // toolkit's own EMP retract fires first
	if(. & EMP_PROTECT_SELF)
		return
	var/datum/component/cyberware/chrome = GetComponent(/datum/component/cyberware)
	if(!chrome || chrome.emp_down)
		return
	chrome.start_emp_reboot(severity)
	if(owner)
		owner.balloon_alert(owner, "[name] glitches out!")

// ---- Shared insert gate ------------------------------------------------

/// Called when someone starts surgically inserting the organ (hooked into
/// organ manipulation's preop). Returning FALSE fails the step. Only chrome
/// cares: it checks capacity and opens its install window here.
/obj/item/organ/proc/pre_surgical_insertion(mob/living/user, mob/living/carbon/new_owner, target_zone)
	return TRUE

/**
 * The organs this insert would replace on the target, the incumbent
 * occupying our slot. THE netting extension point: paired arm ware (Gorilla
 * Arms, Mantis Blades) overrides this on its own type to return both arms'
 * incumbents, so a full-pair swap nets out both sides of the ladder rung.
 */
/obj/item/organ/proc/cyberware_get_incumbents(mob/living/carbon/target)
	RETURN_TYPE(/list)
	. = list()
	var/obj/item/organ/incumbent = target?.get_organ_slot(slot)
	if(incumbent && incumbent != src)
		. += incumbent

/**
 * Capacity half of the gate: would the target's chrome still fit after this
 * insert? Nets out the incumbent's load AND capacity bonus (swapping a
 * Governor for a Governor must not double-count), never a naive sum.
 * Feedback goes to the patient, plus the surgeon when that's someone else.
 */
/proc/cyberware_insert_check(obj/item/organ/ware, mob/living/carbon/target, silent = FALSE, mob/feedback_to)
	if(!iscarbon(target))
		return FALSE
	var/datum/component/cyberware/chrome = ware.GetComponent(/datum/component/cyberware)
	if(!chrome)
		return TRUE
	var/projected_load = get_chrome_load(target) + chrome.chrome_load
	var/projected_capacity = get_chrome_capacity(target) + chrome.capacity_bonus
	for(var/obj/item/organ/incumbent in ware.cyberware_get_incumbents(target))
		var/datum/component/cyberware/incumbent_chrome = incumbent.GetComponent(/datum/component/cyberware)
		if(!incumbent_chrome)
			continue
		projected_load -= incumbent_chrome.chrome_load
		projected_capacity -= incumbent_chrome.capacity_bonus
	if(projected_load <= projected_capacity)
		return TRUE
	if(!silent)
		target.balloon_alert(target, "no neural headroom!")
		to_chat(target, span_warning("Your nervous system is already maxed out. [ware] needs [projected_load - projected_capacity] more chrome capacity."))
		if(feedback_to && feedback_to != target)
			to_chat(feedback_to, span_warning("[target]'s nervous system can't take [ware], [projected_load - projected_capacity] over capacity."))
	return FALSE

/**
 * Full gate for a live (non-special) Insert(): a legit install context must
 * be open for this receiver, and the netted capacity must fit. The context
 * is consumed only on a pass, so a capacity refusal doesn't strand a surgery
 * that shed load and tried again within the window.
 *
 * A window opened as forced (the admin verb) waives the capacity half as well:
 * the ware goes in over budget and browns out, which is the honest result of
 * admin fiat rather than a silent refusal.
 */
/proc/cyberware_can_insert(obj/item/organ/ware, mob/living/carbon/receiver)
	var/datum/component/cyberware/chrome = ware.GetComponent(/datum/component/cyberware)
	if(!chrome)
		return TRUE
	if(!chrome.has_install_context(receiver))
		if(receiver)
			receiver.balloon_alert(receiver, "needs a real rig!")
			to_chat(receiver, span_warning("The autosurgeon chokes. This needs a real rig."))
		return FALSE
	if(!chrome.install_context_forced && !cyberware_insert_check(ware, receiver))
		return FALSE
	chrome.clear_install_context()
	return TRUE

// ---- Failing-gated passive layer ---------------------------------------

/**
 * Always-on chrome effects (physiology armor and mods, organ_traits) used to
 * survive ORGAN_FAILING untouched: an EMP'd Slabskin still armored you, an
 * EMP'd Coolant Loop still halved burns, and so EMP never actually countered
 * a chromed-out body (BAL-4). These two hooks are the fix. The cyberware
 * component calls them, edge-triggered off its passives_online latch, whenever
 * the ware's effective failing state settles: EMP reboot, brownout, damage
 * failure, cradle tune-up, install and removal all route through the same
 * pair, so a passive is DOWN whenever the chrome reads as offline and back
 * the moment it repairs. Nothing here is permanent; the ripperdoc/cradle
 * repair path is untouched.
 *
 * The base pair handles the ware's organ_traits with tg's own bookkeeping
 * (same REF(src) source on_mob_insert uses, so add/remove is idempotent
 * against the parent's grants). Subtypes layer their physiology work on top
 * and MUST keep it idempotent, non-idempotent mods (multiply/divide, armor
 * add/subtract) carry their own applied-state bool because the off hook can
 * legitimately run when nothing is applied (inserting an already-EMP'd ware).
 */
/obj/item/organ/proc/chrome_passives_on(mob/living/carbon/bearer)
	SHOULD_CALL_PARENT(TRUE)
	if(isnull(bearer))
		return
	for(var/trait in organ_traits)
		ADD_TRAIT(bearer, trait, REF(src))

/obj/item/organ/proc/chrome_passives_off(mob/living/carbon/bearer)
	SHOULD_CALL_PARENT(TRUE)
	if(isnull(bearer))
		return
	for(var/trait in organ_traits)
		REMOVE_TRAIT(bearer, trait, REF(src))

/// The EMP line every piece of chrome carries on examine. One place, so the
/// number and the wording can't drift between the three cyberware bases. The
/// weakness was always in the design and never legible on the item itself;
/// now that it actually bites (BAL-4), it says so where people read it.
/proc/cyberware_emp_examine_line()
	return span_notice("Electromagnetic pulses scramble chrome. An EMP knocks this offline for up to [DisplayTimeText(CYBERWARE_EMP_DOWNTIME)] and everything it was doing for you stops until it reboots; a Chrome Cradle tune-up clears it early.")

// ---- Ink bus -----------------------------------------------------------

/**
 * Kick the target's Chromatic Dermis, if they wear one. THE integration hook
 * for the ink suite: every ware that does something worth looking at calls
 * this with a CYBERWARE_INK_* strength, and a bearer with ink lights up for
 * it. Safe to call on anyone, no ink, no effect, no cost beyond a slot
 * lookup, so new ware should call it freely rather than checking first.
 */
/proc/cyberware_ink_pulse(mob/living/carbon/target, strength = CYBERWARE_INK_SOFT)
	if(!iscarbon(target))
		return
	var/obj/item/organ/cyberimp/cyberware/chromatic_dermis/ink = target.get_organ_slot(ORGAN_SLOT_CYBERWARE_INK)
	if(istype(ink))
		ink.pulse(strength)

// ---- BIOS boot splash --------------------------------------------------

/**
 * Three staged chat lines in the ware's tier accent plus a synth chime.
 * Fires on every non-special install, Cradle or DIY table alike. Doubles as
 * the "your chrome is live" tutorial beat.
 */
/proc/cyberware_boot_splash(mob/living/target, obj/item/organ/ware)
	if(!istype(target) || QDELETED(ware))
		return
	var/datum/component/cyberware/chrome = ware.GetComponent(/datum/component/cyberware)
	var/accent = cyberware_tier_color(chrome ? chrome.tier : CYBERWARE_TIER_1)
	playsound(target, 'sound/machines/synth/synth_yes.ogg', 40, TRUE)
	cyberware_boot_line(target, accent, "CORTEX HANDSHAKE... OK")
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberware_boot_line), target, accent, "CALIBRATING..."), CYBERWARE_BOOT_LINE_DELAY)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cyberware_boot_line), target, accent, "CHROME ONLINE: [uppertext(ware.name)]"), CYBERWARE_BOOT_LINE_DELAY * 2)

/// One BIOS line, monospace in the tier accent. Split out so the staged
/// timers survive the target logging off mid-boot.
/proc/cyberware_boot_line(mob/living/target, accent, line)
	if(QDELETED(target))
		return
	to_chat(target, "<span style='color: [accent]; font-weight: bold; font-family: \"Courier New\", monospace;'>[line]</span>")

// ---- Cooldown action bridge --------------------------------------------

/**
 * The one cooldown action chrome abilities hang off. Raw /datum/action/cooldown
 * lacks the organ_action owner guard, so this adds it, plus an ORGAN_FAILING
 * gate, a browned-out or EMP-scrambled ware's buttons go dark.
 *
 * Works for both shapes of ability: leave click_to_activate off and override
 * Activate(target) for an instant pulse (target is the owner), or set
 * click_to_activate = TRUE for a targeted ability (target is what they
 * clicked). Either way StartCooldown() is YOURS to call inside Activate().
 * The base never starts it for you.
 */
/datum/action/cooldown/cyberware
	check_flags = AB_CHECK_CONSCIOUS
	/// The chrome this button belongs to. Typed loosely because both organ
	/// bases use this bridge.
	var/obj/item/organ/organ

/datum/action/cooldown/cyberware/New(Target, original = TRUE)
	. = ..()
	if(isorgan(Target))
		organ = Target
	else
		var/datum/target_datum = Target
		stack_trace("cyberware cooldown action created on non-organ target [Target] ([target_datum ? target_datum.type : "null"])")

/datum/action/cooldown/cyberware/Destroy()
	organ = null
	return ..()

/datum/action/cooldown/cyberware/IsAvailable(feedback = FALSE)
	. = ..()
	if(!.)
		return
	if(!organ?.owner)
		return FALSE
	if(organ.organ_flags & ORGAN_FAILING)
		if(feedback)
			organ.owner.balloon_alert(organ.owner, "chrome offline!")
		return FALSE
	return TRUE

/**
 * Is there a clear arc from [here] to [destination]? Shared by every leg
 * ware that throws its owner through the air: Hopper Pistons, Meteor
 * Piledriver.
 *
 * Line of sight is not enough on its own. [/proc/can_see] only asks whether
 * each turf on the way is opaque, and a window, a grille, a girder or a
 * plasteel shutter frame is not, so on that test alone a leap draws a straight
 * line through the glass wall of a sealed room and lands inside it. Legs go up
 * and over things, not through them, so walk the line and stop on anything
 * tall enough to be in the way.
 *
 * What an arc does clear: anything a thrown object already sails over
 * (LETPASSTHROW, so tables, railings, crates, waist-high machinery) and
 * anything you could simply climb. Border objects are skipped for the same
 * reason tg's jaunt check skips them
 * ([/turf/proc/is_blocked_turf_ignore_climbable]): they only block one edge of
 * a tile, and a straight line has no clean way to ask which edge it crossed.
 * Mobs are never obstructions, clearing people is the point of a jump.
 *
 * Returns the first turf that stops the arc, or null if the path is clear.
 */
/datum/action/cooldown/cyberware/proc/arc_blocker(turf/here, turf/destination)
	for(var/turf/crossed as anything in get_line(here, destination))
		// The tile under our own boots is never what stops us leaving it.
		if(crossed == here)
			continue
		// Walls, and any other closed turf.
		if(crossed.density)
			return crossed
		for(var/atom/movable/obstacle as anything in crossed)
			if(!obstacle.density || ismob(obstacle))
				continue
			if(obstacle.flags_1 & ON_BORDER_1)
				continue
			if(obstacle.pass_flags_self & LETPASSTHROW)
				continue
			if(HAS_TRAIT(obstacle, TRAIT_CLIMBABLE))
				continue
			return crossed
	return null
