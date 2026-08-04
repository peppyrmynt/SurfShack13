/obj/machinery/dna_scannernew
	name = "\improper DNA scanner"
	desc = "It scans DNA structures."
	icon = 'icons/obj/machines/cloning.dmi'
	icon_state = "scanner"
	base_icon_state = "scanner"
	density = TRUE
	obj_flags = BLOCKS_CONSTRUCTION // Becomes undense when the door is open
	interaction_flags_mouse_drop = NEED_DEXTERITY
	occupant_typecache = list(/mob/living, /obj/item/bodypart/head, /obj/item/organ/brain)
	circuit = /obj/item/circuitboard/machine/dnascanner

	var/locked = FALSE
	var/damage_coeff = 1
	var/scan_level
	var/precision_coeff = 1
	var/message_cooldown
	var/breakout_time = 1200
	var/obj/machinery/computer/scan_consolenew/linked_console = null

/obj/machinery/dna_scannernew/RefreshParts()
	. = ..()
	scan_level = 0
	damage_coeff = 0
	precision_coeff = 0
	for(var/datum/stock_part/scanning_module/scanning_module in component_parts)
		scan_level += scanning_module.tier
	for(var/datum/stock_part/matter_bin/matter_bin in component_parts)
		precision_coeff = matter_bin.tier
	for(var/datum/stock_part/micro_laser/micro_laser in component_parts)
		damage_coeff = micro_laser.tier

/obj/machinery/dna_scannernew/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += span_notice("The status display reads: Radiation pulse accuracy increased by factor <b>[precision_coeff**2]</b>.<br>Radiation pulse damage decreased by factor <b>[damage_coeff**2]</b>.")

/obj/machinery/dna_scannernew/update_icon_state()
	//no power or maintenance
	if(machine_stat & (NOPOWER|BROKEN))
		icon_state = "[base_icon_state][state_open ? "_open" : null]_unpowered"
		return ..()

	if((machine_stat & MAINT) || panel_open)
		icon_state = "[base_icon_state][state_open ? "_open" : null]_maintenance"
		return ..()

	//running and someone in there
	if(occupant)
		icon_state = "[base_icon_state]_occupied"
		return ..()

	//running
	icon_state = "[base_icon_state][state_open ? "_open" : null]"
	return ..()

/obj/machinery/dna_scannernew/proc/toggle_open(mob/user)
	if(panel_open)
		to_chat(user, span_notice("Close the maintenance panel first."))
		return

	if(state_open)
		close_machine()
		return

	else if(locked)
		to_chat(user, span_notice("The bolts are locked down, securing the door shut."))
		return

	open_machine()

/obj/machinery/dna_scannernew/container_resist_act(mob/living/user)
	if(!locked)
		open_machine()
		return
	user.changeNext_move(CLICK_CD_BREAKOUT)
	user.last_special = world.time + CLICK_CD_BREAKOUT
	user.visible_message(span_notice("You see [user] kicking against the door of [src]!"), \
		span_notice("You lean on the back of [src] and start pushing the door open... (this will take about [DisplayTimeText(breakout_time)].)"), \
		span_hear("You hear a metallic creaking from [src]."))
	if(do_after(user,(breakout_time), target = src))
		if(!user || user.stat != CONSCIOUS || user.loc != src || state_open || !locked)
			return
		locked = FALSE
		user.visible_message(span_warning("[user] successfully broke out of [src]!"), \
			span_notice("You successfully break out of [src]!"))
		open_machine()

/obj/machinery/dna_scannernew/proc/locate_computer(type_)
	for(var/direction in GLOB.cardinals)
		var/C = locate(type_, get_step(src, direction))
		if(C)
			return C
	return null

/obj/machinery/dna_scannernew/close_machine(mob/living/carbon/user, density_to_set = TRUE)
	if(!state_open)
		return FALSE

	..(user)

	// DNA manipulators cannot operate on severed heads or brains
	if(iscarbon(occupant))
		if(linked_console)
			linked_console.on_scanner_close()

	return TRUE

/obj/machinery/dna_scannernew/open_machine(drop = TRUE, density_to_set = FALSE)
	if(state_open)
		return FALSE

	..()

	if(linked_console)
		linked_console.on_scanner_open()

	return TRUE

/obj/machinery/dna_scannernew/relaymove(mob/living/user, direction)
	if(user.stat || locked)
		if(message_cooldown <= world.time)
			message_cooldown = world.time + 50
			to_chat(user, span_warning("[src]'s door won't budge!"))
		return
	open_machine()

/obj/machinery/dna_scannernew/attackby(obj/item/I, mob/user, params)

	if(!occupant && default_deconstruction_screwdriver(user, icon_state, icon_state, I))//sent icon_state is irrelevant...
		update_appearance()//..since we're updating the icon here, since the scanner can be unpowered when opened/closed
		return

	if(default_pry_open(I, close_after_pry = FALSE, open_density = FALSE, closed_density = TRUE))
		return

	if(default_deconstruction_crowbar(I))
		return

	return ..()

/obj/machinery/dna_scannernew/interact(mob/user)
	toggle_open(user)

/obj/machinery/dna_scannernew/mouse_drop_receive(atom/target, mob/user, params)
	if(!iscarbon(target))
		return
	close_machine(target)

//This is only called by the scanner. if you ever want to use this outside of that context you'll need to refactor things a bit
/obj/machinery/dna_scannernew/proc/set_linked_console(new_console)
	if(linked_console)
		UnregisterSignal(linked_console, COMSIG_QDELETING)
	linked_console = new_console
	if(linked_console)
		RegisterSignal(linked_console, COMSIG_QDELETING, PROC_REF(react_to_console_del))

/obj/machinery/dna_scannernew/proc/react_to_console_del(datum/source)
	SIGNAL_HANDLER
	set_linked_console(null)


//Just for transferring between genetics machines.
/obj/item/disk/data
	name = "DNA data disk"
	icon_state = "datadisk0" //Gosh I hope syndies don't mistake them for the nuke disk.
	var/list/genetic_makeup_buffer = list()
	var/list/mutations = list()
	var/max_mutations = 6
	var/read_only = FALSE //Well,it's still a floppy disk

/obj/item/disk/data/Initialize(mapload)
	. = ..()
	icon_state = "datadisk[rand(0,7)]"
	add_overlay("datadisk_gene")

/obj/item/disk/data/debug
	name = "\improper CentCom DNA disk"
	desc = "A debug item for genetics"
	custom_materials = null

/obj/item/disk/data/debug/Initialize(mapload)
	. = ..()
	// Grabs all instances of mutations and adds them to the disk
	for(var/datum/mutation/human/mut as anything in subtypesof(/datum/mutation/human))
		var/datum/mutation/human/ref = GET_INITIALIZED_MUTATION(mut)
		mutations += ref

/obj/item/disk/data/attack_self(mob/user)
	read_only = !read_only
	to_chat(user, span_notice("You flip the write-protect tab to [read_only ? "protected" : "unprotected"]."))

/obj/item/disk/data/examine(mob/user)
	. = ..()
	. += "The write-protect tab is set to [read_only ? "protected" : "unprotected"]."

#define CLONER_INITIAL_BRUTE_DAMAGE 60
#define CLONER_INITIAL_BURN_DAMAGE 60
#define CLONER_BASE_HEAL_RATE 1
#define CLONING_POD_TRAIT_SOURCE "cloning_pod"

/**
 * Persistent data captured by a cloning console.
 *
 * DNA is copied into a detached datum, so deleting or gibbing the original
 * body cannot invalidate the record. The mind reference is intentionally
 * retained so antagonists, objectives, languages, and other mind-bound state
 * move into the replacement body instead of being duplicated.
 */
/datum/cloning_record
	var/record_name
	var/datum/dna/dna
	var/datum/mind/mind
	var/scanned_at
	var/underwear
	var/undershirt
	var/socks
	var/list/factions
	var/obj/machinery/clonepod/active_pod

/datum/cloning_record/New(mob/living/carbon/human/source)
	. = ..()
	record_name = source.real_name
	mind = source.mind
	scanned_at = world.time
	underwear = source.underwear
	undershirt = source.undershirt
	socks = source.socks
	factions = source.faction.Copy()
	dna = new
	source.dna.copy_dna(dna)

/datum/cloning_record/Destroy()
	if(active_pod?.active_record == src)
		active_pod.active_record = null
	active_pod = null
	QDEL_NULL(dna)
	mind = null
	factions = null
	return ..()

/datum/cloning_record/proc/is_cloneable()
	if(active_pod && !QDELETED(active_pod))
		return FALSE
	if(!mind)
		return FALSE
	if(!mind.current || QDELETED(mind.current))
		return TRUE
	return mind.current.stat == DEAD

/datum/cloning_record/proc/status_text()
	if(active_pod && !QDELETED(active_pod))
		return "Cloning in progress"
	if(!mind)
		return "Invalid mind"
	if(!mind.current || QDELETED(mind.current))
		return "Ready: no living body detected"
	if(mind.current.stat == DEAD)
		return "Ready: subject deceased"
	return "Unavailable: subject alive"

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

/obj/machinery/cloning_pod
	parent_type = /obj/machinery/clonepod

/obj/machinery/clonepod/RefreshParts()
	. = ..()
	heal_rate = CLONER_BASE_HEAL_RATE
	for(var/datum/stock_part/servo/servo in component_parts)
		heal_rate += servo.tier * 0.5

/obj/machinery/clonepod/Destroy()
	if(clone && !QDELETED(clone))
		clear_maturation_traits(clone)
		clone.forceMove(drop_location())
	if(active_record?.active_pod == src)
		active_record.active_pod = null
	clone = null
	active_record = null
	return ..()

/obj/machinery/clonepod/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == clone)
		clear_maturation_traits(clone)
		if(active_record?.active_pod == src)
			active_record.active_pod = null
		clone = null
		active_record = null
		update_appearance()

/obj/machinery/clonepod/update_icon_state()
	if(machine_stat & (NOPOWER | BROKEN))
		icon_state = clone ? "pod_g" : "pod_0"
		return ..()
	if(panel_open)
		icon_state = "pod_0"
		return ..()
	icon_state = clone ? "pod_g" : "pod_0"
	return ..()

/obj/machinery/clonepod/examine(mob/user)
	. = ..()
	if(clone)
		var/remaining_damage = round(clone.getBruteLoss() + clone.getFireLoss(), 1)
		. += span_notice("The maturation cycle is active. Remaining growth trauma: [remaining_damage].")
	else
		. += span_notice("The pod is empty and ready to receive a cloning record.")
	. += span_notice("Upgraded servos increase maturation speed.")

/obj/machinery/clonepod/screwdriver_act(mob/living/user, obj/item/tool)
	if(clone)
		to_chat(user, span_warning("You cannot open the maintenance panel while [src] is growing a clone."))
		return ITEM_INTERACT_BLOCKING
	if(default_deconstruction_screwdriver(user, initial(icon_state), initial(icon_state), tool))
		update_appearance()
		return ITEM_INTERACT_SUCCESS
	return ..()

/obj/machinery/clonepod/crowbar_act(mob/living/user, obj/item/tool)
	if(clone)
		to_chat(user, span_warning("You cannot deconstruct [src] while it is growing a clone."))
		return ITEM_INTERACT_BLOCKING
	if(default_deconstruction_crowbar(tool))
		return ITEM_INTERACT_SUCCESS
	return ..()

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

/obj/machinery/clonepod/proc/apply_maturation_traits(mob/living/carbon/human/new_clone)
	ADD_TRAIT(new_clone, TRAIT_NODEATH, CLONING_POD_TRAIT_SOURCE)
	ADD_TRAIT(new_clone, TRAIT_NOBREATH, CLONING_POD_TRAIT_SOURCE)
	ADD_TRAIT(new_clone, TRAIT_NOCRITDAMAGE, CLONING_POD_TRAIT_SOURCE)
	ADD_TRAIT(new_clone, TRAIT_MUTE, CLONING_POD_TRAIT_SOURCE)
	ADD_TRAIT(new_clone, TRAIT_EMOTEMUTE, CLONING_POD_TRAIT_SOURCE)
	ADD_TRAIT(new_clone, TRAIT_IMMOBILIZED, CLONING_POD_TRAIT_SOURCE)

/obj/machinery/clonepod/proc/clear_maturation_traits(mob/living/carbon/human/leaving_clone)
	if(!leaving_clone || QDELETED(leaving_clone))
		return
	REMOVE_TRAIT(leaving_clone, TRAIT_NODEATH, CLONING_POD_TRAIT_SOURCE)
	REMOVE_TRAIT(leaving_clone, TRAIT_NOBREATH, CLONING_POD_TRAIT_SOURCE)
	REMOVE_TRAIT(leaving_clone, TRAIT_NOCRITDAMAGE, CLONING_POD_TRAIT_SOURCE)
	REMOVE_TRAIT(leaving_clone, TRAIT_MUTE, CLONING_POD_TRAIT_SOURCE)
	REMOVE_TRAIT(leaving_clone, TRAIT_EMOTEMUTE, CLONING_POD_TRAIT_SOURCE)
	REMOVE_TRAIT(leaving_clone, TRAIT_IMMOBILIZED, CLONING_POD_TRAIT_SOURCE)

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
	new_clone.underwear = record.underwear
	new_clone.undershirt = record.undershirt
	new_clone.socks = record.socks
	if(record.factions)
		new_clone.faction |= record.factions
	new_clone.updateappearance(mutcolor_update = TRUE, mutations_overlay_update = TRUE)

	apply_maturation_traits(new_clone)
	new_clone.adjustBruteLoss(CLONER_INITIAL_BRUTE_DAMAGE, forced = TRUE)
	new_clone.adjustFireLoss(CLONER_INITIAL_BURN_DAMAGE, forced = TRUE)
	new_clone.adjustOxyLoss(-new_clone.getOxyLoss(), forced = TRUE)
	new_clone.Unconscious(30 SECONDS)

	clone = new_clone
	active_record = record
	record.active_pod = src
	record.mind.transfer_to(new_clone)
	to_chat(new_clone, span_notice("Consciousness flickers at the edge of a newly forming body. Your clone is still maturing."))
	update_appearance()
	return TRUE

/obj/machinery/clonepod/process(seconds_per_tick)
	if(!clone || QDELETED(clone))
		if(active_record?.active_pod == src)
			active_record.active_pod = null
		clone = null
		active_record = null
		update_appearance()
		return

	if(clone.stat == DEAD)
		eject_clone(FALSE)
		return

	if(machine_stat & (NOPOWER | BROKEN))
		eject_clone(FALSE)
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
		if(active_record?.active_pod == src)
			active_record.active_pod = null
		clone = null
		active_record = null
		update_appearance()
		return FALSE

	var/mob/living/carbon/human/leaving_clone = clone
	var/datum/cloning_record/leaving_record = active_record
	clear_maturation_traits(leaving_clone)
	clone = null
	active_record = null
	if(leaving_record?.active_pod == src)
		leaving_record.active_pod = null
	leaving_clone.adjustOxyLoss(-leaving_clone.getOxyLoss(), forced = TRUE)
	leaving_clone.forceMove(drop_location())
	leaving_clone.grab_ghost()
	update_appearance()

	if(successful)
		to_chat(leaving_clone, span_notice("The pod opens. Your new body has finished maturing."))
		leaving_clone.flash_act()
	else
		to_chat(leaving_clone, span_warning("The pod opens before maturation is complete."))

	return TRUE

/**
 * A cloning console automatically detects a DNA scanner and cloning pod on
 * cardinally adjacent tiles. This preserves the classic compact genetics
 * layout and avoids a global machine-link registry.
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
	if(scanner.state_open)
		status_message = "Scan failed: close the DNA scanner first."
		return FALSE
	if(!ishuman(scanner.occupant))
		status_message = "Scan failed: the scanner does not contain a human subject."
		return FALSE

	var/mob/living/carbon/human/subject = scanner.occupant
	if(subject.stat == DEAD)
		status_message = "Scan failed: the subject is already dead."
		return FALSE
	if(!subject.mind || subject.mind.current != subject)
		status_message = "Scan failed: no compatible mind detected."
		return FALSE
	if(!subject.dna || subject.dna.scrambled || HAS_TRAIT(subject, TRAIT_BADDNA))
		status_message = "Scan failed: genetic data is unusable."
		return FALSE
	if(subject.dna.species?.inherent_biotypes & MOB_ROBOTIC)
		status_message = "Scan failed: the subject is not biologically cloneable."
		return FALSE

	var/datum/cloning_record/old_record = find_record_by_mind(subject.mind)
	if(old_record?.active_pod)
		status_message = "Scan failed: this subject is currently being cloned."
		return FALSE
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
	if(record.active_pod)
		text += "<span class='linkOff'>Delete record</span></div><br>"
	else
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
		dat += "<b>Scanner door:</b> [scanner.state_open ? "Open" : "Closed"]<br>"
		dat += "<b>Scanner occupant:</b> [scanner_occupant ? scanner_occupant : "None"]<br>"
		if(scanner_occupant && !scanner.state_open)
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
		if(!scanner)
			status_message = "No scanner detected."
		else if(scanner.state_open)
			status_message = "Close the scanner before engaging its lock."
		else
			scanner.locked = !scanner.locked
			status_message = scanner.locked ? "Scanner locked." : "Scanner unlocked."

	else if(href_list["clone"])
		var/datum/cloning_record/record = locate(href_list["clone"])
		if(!(record in records))
			status_message = "Clone failed: record not found."
		else if(!pod)
			status_message = "Clone failed: no adjacent cloning pod."
		else if(!record.is_cloneable())
			status_message = "Clone failed: the subject is alive or already being cloned."
		else if(pod.start_clone(record))
			status_message = "Cloning cycle started for [record.record_name]."
		else
			status_message = "Clone failed: the pod is unavailable."

	else if(href_list["delete"])
		var/datum/cloning_record/record = locate(href_list["delete"])
		if(!(record in records))
			status_message = "Delete failed: record not found."
		else if(record.active_pod)
			status_message = "Delete failed: the record is currently in use."
		else
			status_message = "Deleted [record.record_name]'s cloning record."
			records -= record
			qdel(record)

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

#ifdef UNIT_TESTS

/datum/unit_test/cloning_round_trip/Run()
	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human/consistent)
	subject.real_name = "Cloning Test Subject"
	subject.name = subject.real_name
	subject.dna.real_name = subject.real_name
	subject.set_species(/datum/species/lizard)
	subject.mind_initialize()

	var/datum/cloning_record/record = new(subject)
	if(record.record_name != subject.real_name)
		return Fail("The cloning record did not preserve the subject's name.", __FILE__, __LINE__)
	if(record.dna.species.type != subject.dna.species.type)
		return Fail("The cloning record did not preserve the subject's species.", __FILE__, __LINE__)
	if(record.is_cloneable())
		return Fail("A living subject was incorrectly considered cloneable.", __FILE__, __LINE__)

	subject.stat = DEAD
	if(!record.is_cloneable())
		return Fail("A dead subject was not considered cloneable.", __FILE__, __LINE__)

	var/obj/machinery/clonepod/pod = allocate(/obj/machinery/clonepod)
	pod.machine_stat = 0
	pod.active_power_usage = 0
	var/list/pod_icon_states = icon_states(pod.icon)
	if(!("pod_0" in pod_icon_states) || !("pod_g" in pod_icon_states))
		return Fail("The cloning pod sprite sheet is missing its empty or growth state.", __FILE__, __LINE__)
	if(!pod.start_clone(record))
		return Fail("The cloning pod refused a valid dead subject record.", __FILE__, __LINE__)

	var/mob/living/carbon/human/new_clone = pod.clone
	if(!new_clone)
		return Fail("The cloning pod did not create a replacement body.", __FILE__, __LINE__)
	if(pod.icon_state != "pod_g")
		return Fail("The occupied cloning pod did not switch to the growth sprite state.", __FILE__, __LINE__)
	if(new_clone.mind != record.mind)
		return Fail("The subject's mind was not transferred into the clone.", __FILE__, __LINE__)
	if(new_clone.real_name != record.record_name)
		return Fail("The clone did not preserve the subject's name.", __FILE__, __LINE__)
	if(new_clone.dna.species.type != record.dna.species.type)
		return Fail("The clone did not preserve the recorded species.", __FILE__, __LINE__)
	if(!HAS_TRAIT(new_clone, TRAIT_NODEATH) || !HAS_TRAIT(new_clone, TRAIT_NOBREATH))
		return Fail("The clone did not receive maturation protection inside the pod.", __FILE__, __LINE__)
	if(record.is_cloneable())
		return Fail("A record already in use was incorrectly considered cloneable.", __FILE__, __LINE__)

	for(var/iteration in 1 to 180)
		if(!pod.clone)
			break
		pod.process(1)

	if(pod.clone)
		return Fail("The cloning pod did not finish the maturation cycle.", __FILE__, __LINE__)
	if(pod.icon_state != "pod_0")
		return Fail("The cloning pod did not return to the empty sprite state after ejection.", __FILE__, __LINE__)
	if(new_clone.loc == pod)
		return Fail("The mature clone was not ejected from the pod.", __FILE__, __LINE__)
	if(HAS_TRAIT(new_clone, TRAIT_NODEATH) || HAS_TRAIT(new_clone, TRAIT_NOBREATH))
		return Fail("Maturation-only traits remained after ejection.", __FILE__, __LINE__)
	if(new_clone.getBruteLoss() > 0 || new_clone.getFireLoss() > 0)
		return Fail("A successful maturation cycle left growth trauma unhealed.", __FILE__, __LINE__)

	qdel(record)
	qdel(new_clone)

#endif

#undef CLONER_INITIAL_BRUTE_DAMAGE
#undef CLONER_INITIAL_BURN_DAMAGE
#undef CLONER_BASE_HEAL_RATE
#undef CLONING_POD_TRAIT_SOURCE
