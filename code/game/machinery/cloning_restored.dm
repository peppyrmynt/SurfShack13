#define CLONER_INITIAL_BRUTE_DAMAGE 60
#define CLONER_INITIAL_BURN_DAMAGE 60
#define CLONER_BASE_HEAL_RATE 2

/**
 * A persistent cloning record created by the cloning console.
 *
 * The record owns a detached DNA datum so the scanned appearance and species
 * survive even when the original body is destroyed.
 */
/datum/cloning_record
	var/record_name
	var/datum/dna/dna
	var/datum/mind/mind
	var/scanned_at

/datum/cloning_record/New(mob/living/carbon/human/source)
	. = ..()
	record_name = source.real_name
	mind = source.mind
	scanned_at = world.time
	dna = new
	source.dna.copy_dna(dna)

/datum/cloning_record/Destroy()
	QDEL_NULL(dna)
	mind = null
	return ..()

/datum/cloning_record/proc/is_cloneable()
	if(!mind)
		return FALSE
	if(!mind.current || QDELETED(mind.current))
		return TRUE
	return mind.current.stat == DEAD

/datum/cloning_record/proc/status_text()
	if(!mind)
		return "Invalid mind"
	if(!mind.current || QDELETED(mind.current))
		return "Ready: no living body detected"
	if(mind.current.stat == DEAD)
		return "Ready: subject deceased"
	return "Unavailable: subject alive"

/**
 * The cloning pod grows a damaged replacement body and releases it after the
 * maturation damage has been healed. It intentionally keeps the classic
 * cloning drawbacks instead of producing a fully healthy instant revival.
 */
/obj/machinery/clonepod
	name = "cloning pod"
	desc = "A sealed pod that grows replacement organic bodies from stored genetic data."
	icon = 'icons/obj/machines/cloning.dmi'
	icon_state = "pod_0"
	base_icon_state = "pod_0"
	density = TRUE
	obj_flags = BLOCKS_CONSTRUCTION
	circuit = /obj/item/circuitboard/machine/clonepod
	processing_flags = START_PROCESSING_ON_INIT
	use_power = ACTIVE_POWER_USE
	idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION
	active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION * 4

	var/mob/living/carbon/human/clone
	var/datum/cloning_record/active_record
	var/heal_rate = CLONER_BASE_HEAL_RATE

/obj/machinery/clonepod/RefreshParts()
	. = ..()
	heal_rate = CLONER_BASE_HEAL_RATE
	for(var/datum/stock_part/servo/servo in component_parts)
		heal_rate += servo.tier * 0.5

/obj/machinery/clonepod/Destroy()
	if(clone && !QDELETED(clone))
		clone.forceMove(drop_location())
	clone = null
	active_record = null
	return ..()

/obj/machinery/clonepod/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == clone)
		clone = null
		active_record = null
		update_appearance()

/obj/machinery/clonepod/update_icon_state()
	if(machine_stat & (NOPOWER | BROKEN))
		icon_state = clone ? "pod_1" : "pod_0"
		return ..()
	if(panel_open)
		icon_state = "pod_0"
		return ..()
	icon_state = clone ? "pod_1" : "pod_0"
	return ..()

/obj/machinery/clonepod/examine(mob/user)
	. = ..()
	if(clone)
		var/remaining_damage = round(clone.getBruteLoss() + clone.getFireLoss(), 1)
		. += span_notice("The maturation cycle is active. Remaining growth trauma: [remaining_damage].")
	else
		. += span_notice("The pod is empty and ready to receive a cloning record.")
	. += span_notice("Upgraded servos increase maturation speed.")

/obj/machinery/clonepod/interact(mob/user)
	if(!clone)
		to_chat(user, span_notice("The cloning pod is empty."))
		return
	to_chat(user, span_warning("You trigger the emergency release. The clone may not be fully developed."))
	eject_clone(FALSE)

/obj/machinery/clonepod/relaymove(mob/living/user, direction)
	if(user == clone)
		eject_clone(FALSE)

/obj/machinery/clonepod/container_resist_act(mob/living/user)
	if(user == clone)
		eject_clone(FALSE)

/obj/machinery/clonepod/proc/start_clone(datum/cloning_record/record)
	if(!record || !record.dna || !record.mind)
		return FALSE
	if(clone || panel_open || (machine_stat & (NOPOWER | BROKEN)))
		return FALSE
	if(!record.is_cloneable())
		return FALSE

	var/mob/living/carbon/human/new_clone = new(src)
	record.dna.copy_dna(new_clone.dna)
	new_clone.real_name = record.record_name
	new_clone.name = record.record_name
	new_clone.dna.real_name = record.record_name
	new_clone.updateappearance(mutcolor_update = TRUE, mutations_overlay_update = TRUE)

	new_clone.adjustBruteLoss(CLONER_INITIAL_BRUTE_DAMAGE, forced = TRUE)
	new_clone.adjustFireLoss(CLONER_INITIAL_BURN_DAMAGE, forced = TRUE)
	new_clone.adjustOxyLoss(-100, forced = TRUE)
	new_clone.Unconscious(30 SECONDS)

	clone = new_clone
	active_record = record
	record.mind.transfer_to(new_clone)
	new_clone.grab_ghost()
	to_chat(new_clone, span_notice("Consciousness flickers at the edge of a newly forming body. Your clone is still maturing."))
	update_appearance()
	return TRUE

/obj/machinery/clonepod/process(seconds_per_tick)
	if(!clone || QDELETED(clone))
		clone = null
		active_record = null
		update_appearance()
		return
	if(machine_stat & (NOPOWER | BROKEN))
		return

	clone.Unconscious(3 SECONDS)
	clone.adjustOxyLoss(-10 * seconds_per_tick, forced = TRUE)
	clone.adjustBruteLoss(-heal_rate * seconds_per_tick, forced = TRUE)
	clone.adjustFireLoss(-heal_rate * seconds_per_tick, forced = TRUE)
	use_energy(active_power_usage * seconds_per_tick)

	if(clone.getBruteLoss() <= 0 && clone.getFireLoss() <= 0)
		eject_clone(TRUE)

/obj/machinery/clonepod/proc/eject_clone(successful)
	if(!clone || QDELETED(clone))
		clone = null
		active_record = null
		update_appearance()
		return

	var/mob/living/carbon/human/leaving_clone = clone
	clone = null
	active_record = null
	leaving_clone.forceMove(drop_location())
	update_appearance()

	if(successful)
		to_chat(leaving_clone, span_notice("The pod opens. Your new body has finished maturing."))
		leaving_clone.flash_act()
	else
		to_chat(leaving_clone, span_warning("The pod opens before maturation is complete."))

/**
 * Cloning console. A scanner and pod placed on cardinally adjacent tiles are
 * detected automatically, matching the old machine layout while avoiding a
 * fragile global linking system.
 */
/obj/machinery/computer/cloning
	name = "cloning console"
	desc = "Stores genetic records and sends deceased crew records to a cloning pod."
	icon_screen = "dna"
	icon_keyboard = "med_key"
	circuit = /obj/item/circuitboard/computer/cloning
	light_color = LIGHT_COLOR_BLUE

	var/obj/machinery/dna_scannernew/scanner
	var/obj/machinery/clonepod/pod
	var/list/records = list()
	var/status_message = "Ready."

/obj/machinery/computer/cloning/Destroy()
	for(var/datum/cloning_record/record in records)
		qdel(record)
	records.Cut()
	scanner = null
	pod = null
	return ..()

/obj/machinery/computer/cloning/proc/find_hardware()
	scanner = null
	pod = null
	for(var/direction in GLOB.cardinals)
		var/turf/target = get_step(src, direction)
		if(!scanner)
			scanner = locate(/obj/machinery/dna_scannernew) in target
		if(!pod)
			pod = locate(/obj/machinery/clonepod) in target

/obj/machinery/computer/cloning/proc/find_record_by_mind(datum/mind/target_mind)
	for(var/datum/cloning_record/record in records)
		if(record.mind == target_mind)
			return record

/obj/machinery/computer/cloning/proc/scan_occupant()
	find_hardware()
	if(!scanner || (scanner.machine_stat & (NOPOWER | BROKEN)))
		status_message = "Scan failed: no operational adjacent DNA scanner."
		return FALSE
	if(!ishuman(scanner.occupant))
		status_message = "Scan failed: the scanner does not contain a human subject."
		return FALSE

	var/mob/living/carbon/human/subject = scanner.occupant
	if(!subject.mind)
		status_message = "Scan failed: no compatible mind detected."
		return FALSE
	if(!subject.dna || HAS_TRAIT(subject, TRAIT_BADDNA))
		status_message = "Scan failed: genetic data is unusable."
		return FALSE

	var/datum/cloning_record/old_record = find_record_by_mind(subject.mind)
	if(old_record)
		records -= old_record
		qdel(old_record)

	var/datum/cloning_record/new_record = new(subject)
	records += new_record
	status_message = "[subject.real_name]'s cloning record was stored successfully."
	return TRUE

/obj/machinery/computer/cloning/proc/render_record(datum/cloning_record/record)
	var/text = "<div class='block'><b>[record.record_name]</b><br>"
	text += "[record.status_text()]<br>"
	if(record.is_cloneable())
		text += "<a href='byond://?src=[REF(src)];clone=[REF(record)]'>Start cloning</a> | "
	else
		text += "<span class='linkOff'>Start cloning</span> | "
	text += "<a href='byond://?src=[REF(src)];delete=[REF(record)]'>Delete record</a></div><br>"
	return text

/obj/machinery/computer/cloning/ui_interact(mob/user)
	. = ..()
	find_hardware()

	var/dat = "<a href='byond://?src=[REF(src)];refresh=1'>Refresh</a><hr>"
	dat += "<h3>System status</h3><div class='statusDisplay'>[status_message]</div>"
	dat += "<b>DNA scanner:</b> [scanner ? "Connected" : "Not detected"]<br>"
	dat += "<b>Cloning pod:</b> [pod ? (pod.clone ? "Maturation cycle active" : "Ready") : "Not detected"]<br><br>"

	if(scanner)
		var/mob/living/scanner_occupant = scanner.occupant
		dat += "<b>Scanner occupant:</b> [scanner_occupant ? scanner_occupant : "None"]<br>"
		if(scanner_occupant)
			dat += "<a href='byond://?src=[REF(src)];scan=1'>Store or update cloning record</a><br>"
		else
			dat += "<span class='linkOff'>Store or update cloning record</span><br>"
		dat += "<a href='byond://?src=[REF(src)];lock=1'>[scanner.locked ? "Unlock scanner" : "Lock scanner"]</a><br><br>"

	dat += "<h3>Cloning records ([records.len])</h3>"
	if(!records.len)
		dat += "No records stored."
	else
		for(var/datum/cloning_record/record in records)
			dat += render_record(record)

	var/datum/browser/popup = new(user, "cloning_console", "Cloning Console", 520, 600)
	popup.set_content(dat)
	popup.open()

/obj/machinery/computer/cloning/Topic(href, href_list)
	if(..())
		return
	find_hardware()

	if(href_list["refresh"])
		status_message = "Status refreshed."

	else if(href_list["scan"])
		scan_occupant()

	else if(href_list["lock"])
		if(scanner)
			scanner.locked = !scanner.locked
			status_message = scanner.locked ? "Scanner locked." : "Scanner unlocked."
		else
			status_message = "No scanner detected."

	else if(href_list["clone"])
		var/datum/cloning_record/record = locate(href_list["clone"])
		if(!(record in records))
			status_message = "Clone failed: record not found."
		else if(!pod)
			status_message = "Clone failed: no adjacent cloning pod."
		else if(!record.is_cloneable())
			status_message = "Clone failed: the subject is still alive."
		else if(pod.start_clone(record))
			status_message = "Cloning cycle started for [record.record_name]."
		else
			status_message = "Clone failed: the pod is unavailable."

	else if(href_list["delete"])
		var/datum/cloning_record/record = locate(href_list["delete"])
		if(record in records)
			status_message = "Deleted [record.record_name]'s cloning record."
			records -= record
			qdel(record)
		else
			status_message = "Delete failed: record not found."

	add_fingerprint(usr)
	ui_interact(usr)

// Construction boards
/obj/item/circuitboard/computer/cloning
	name = "Cloning Console"
	build_path = /obj/machinery/computer/cloning

/obj/item/circuitboard/machine/clonepod
	name = "Clone Pod"
	build_path = /obj/machinery/clonepod
	req_components = list(
		/obj/item/stack/cable_coil = 2,
		/datum/stock_part/scanning_module = 2,
		/datum/stock_part/servo = 2,
		/obj/item/stack/sheet/glass = 2,
	)

// Research designs
/datum/design/board/clonecontrol
	name = "Cloning Console Board"
	desc = "The circuit board for a cloning records console."
	id = "clonecontrol"
	build_path = /obj/item/circuitboard/computer/cloning
	category = list(RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_MEDICAL)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING | DEPARTMENT_BITFLAG_MEDICAL

/datum/design/board/clonepod
	name = "Clone Pod Board"
	desc = "The circuit board for a cloning pod."
	id = "clonepod"
	build_path = /obj/item/circuitboard/machine/clonepod
	category = list(RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_MEDICAL)
	departmental_flags = DEPARTMENT_BITFLAG_ENGINEERING | DEPARTMENT_BITFLAG_MEDICAL

/datum/techweb_node/cloning
	id = "cloning"
	display_name = "Cloning"
	description = "Replacement-body growth and neural reintegration technology."
	prereq_ids = list(TECHWEB_NODE_CRYOSTASIS)
	design_ids = list("clonecontrol", "clonepod")
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_4_POINTS)
	announce_channels = list(RADIO_CHANNEL_MEDICAL)

#undef CLONER_INITIAL_BRUTE_DAMAGE
#undef CLONER_INITIAL_BURN_DAMAGE
#undef CLONER_BASE_HEAL_RATE
