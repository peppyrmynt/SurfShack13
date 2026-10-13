/**
 * # Cyberware research
 *
 * Voidcrew sold chrome over a ripperdoc's counter for credits and vouchers.
 * On the station it is a branch of science instead: its own techweb tree,
 * rooted off Cybernetic Implants, climbing the same four tiers the parlor
 * shelves did (Street, Pro, Military, Legend). Everything prints at the
 * protolathe or the robotics exosuit fabricator under its own "Cyberware"
 * category, and the Chrome Cradle that installs it is a medical machine board
 * unlocked by the tree's first node.
 *
 * Military and Legend chrome costs rare materials on purpose: the vouchers
 * were the gate on Voidcrew, bluespace and diamonds are the gate here.
 */

// ---- Node ids ----------------------------------------------------------

#define TECHWEB_NODE_CYBERWARE_BASE "cyberware_base"
#define TECHWEB_NODE_CYBERWARE_STREET "cyberware_street"
#define TECHWEB_NODE_CYBERWARE_PRO_UTILITY "cyberware_pro_utility"
#define TECHWEB_NODE_CYBERWARE_PRO_COMBAT "cyberware_pro_combat"
#define TECHWEB_NODE_CYBERWARE_MILITARY_BODY "cyberware_military_body"
#define TECHWEB_NODE_CYBERWARE_MILITARY_ARMS "cyberware_military_arms"
#define TECHWEB_NODE_CYBERWARE_LEGEND "cyberware_legend"

// ---- Lathe categories --------------------------------------------------

#define RND_CATEGORY_CYBERWARE "/Cyberware"
#define RND_SUBCATEGORY_CYBERWARE_STREET "/Street Chrome"
#define RND_SUBCATEGORY_CYBERWARE_PRO "/Pro Chrome"
#define RND_SUBCATEGORY_CYBERWARE_MILITARY "/Military Chrome"
#define RND_SUBCATEGORY_CYBERWARE_LEGEND "/Legend Chrome"
#define RND_SUBCATEGORY_CYBERWARE_AMMO "/Chrome Ammunition"

// =========================================================================
// TECHWEB NODES
// =========================================================================

/datum/techweb_node/cyberware
	announce_channels = list(RADIO_CHANNEL_SCIENCE, RADIO_CHANNEL_MEDICAL)

/datum/techweb_node/cyberware/base
	id = TECHWEB_NODE_CYBERWARE_BASE
	display_name = "Cyberware: Chrome Fundamentals"
	description = "Neural load, chrome capacity and the Chrome Cradle, the rig that seats aftermarket hardware without a surgical team. The start of the cyberware branch."
	prereq_ids = list(TECHWEB_NODE_CYBER_IMPLANTS)
	design_ids = list(
		"chrome_cradle",
		"cyberware_chromatic_dermis",
		"cyberware_gastro",
		"cyberware_nightshade",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_2_POINTS)

/datum/techweb_node/cyberware/street
	id = TECHWEB_NODE_CYBERWARE_STREET
	display_name = "Cyberware: Street Chrome"
	description = "Cheap, dependable job-lube chrome. Faster knockdown recovery, reinforced knuckles, sticky hands, spare air, and a hidden pocket nobody pats down."
	prereq_ids = list(TECHWEB_NODE_CYBERWARE_BASE)
	design_ids = list(
		"cyberware_shock_coils",
		"cyberware_scrapper",
		"cyberware_gecko",
		"cyberware_second_wind",
		"cyberware_cargo_cavity",
		"cyberware_rockjaw",
		"cyberware_fixers",
		"cyberware_dermal_mesh",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_2_POINTS)

/datum/techweb_node/cyberware/pro_utility
	id = TECHWEB_NODE_CYBERWARE_PRO_UTILITY
	display_name = "Cyberware: Pro Utility Chrome"
	description = "Real capability adds for workers and explorers: blood filtration, coolant loops, surveyor optics, grapples and a data spike for doors that won't open."
	prereq_ids = list(TECHWEB_NODE_CYBERWARE_STREET)
	design_ids = list(
		"cyberware_angler",
		"cyberware_hemoglass",
		"cyberware_coolant",
		"cyberware_doppler",
		"cyberware_prospector",
		"cyberware_graverobber",
		"cyberware_icepick",
		"cyberware_skyhook",
		"cyberware_hopper",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_3_POINTS)

/datum/techweb_node/cyberware/pro_combat
	id = TECHWEB_NODE_CYBERWARE_PRO_COMBAT
	display_name = "Cyberware: Pro Combat Chrome"
	description = "Targeting optics, reflex boosters and a pain-feedback editor. The first chrome that changes how you fight."
	prereq_ids = list(TECHWEB_NODE_CYBERWARE_STREET, TECHWEB_NODE_COMBAT_IMPLANTS)
	design_ids = list(
		"cyberware_deadeye",
		"cyberware_slipwire",
		"cyberware_dead_channel",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_3_POINTS)

/datum/techweb_node/cyberware/military_body
	id = TECHWEB_NODE_CYBERWARE_MILITARY_BODY
	display_name = "Cyberware: Military Body Chrome"
	description = "Playstyle-defining body chrome: a reinforced skeleton, subdermal armor slabs, optical camouflage and an emergency reviver node."
	prereq_ids = list(TECHWEB_NODE_CYBERWARE_PRO_COMBAT, TECHWEB_NODE_CYBERWARE_PRO_UTILITY)
	design_ids = list(
		"cyberware_atlas",
		"cyberware_slabskin",
		"cyberware_ghostskin",
		"cyberware_lazarus",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_4_POINTS)

/datum/techweb_node/cyberware/military_arms
	id = TECHWEB_NODE_CYBERWARE_MILITARY_ARMS
	display_name = "Cyberware: Military Arm Chrome"
	description = "Weapons that fold into the forearm: mantis blades, monowire, a pop-up submachine gun and a two-shot rocket pod, plus the proprietary reloads they eat."
	prereq_ids = list(TECHWEB_NODE_CYBERWARE_PRO_COMBAT, TECHWEB_NODE_EXOTIC_AMMO)
	design_ids = list(
		"cyberware_gorilla",
		"cyberware_mantis",
		"cyberware_monowire",
		"cyberware_ronin",
		"cyberware_ronin_mag",
		"cyberware_bunker_buster",
		"cyberware_buster_rockets",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_4_POINTS)

/datum/techweb_node/cyberware/legend
	id = TECHWEB_NODE_CYBERWARE_LEGEND
	display_name = "Cyberware: Legend Chrome"
	description = "The chase. A governor that lies about your spine's limits, a reflex lattice that stops the world, a berserker core, and legs that fall like meteors."
	prereq_ids = list(TECHWEB_NODE_CYBERWARE_MILITARY_BODY, TECHWEB_NODE_CYBERWARE_MILITARY_ARMS)
	design_ids = list(
		"cyberware_governor_delete",
		"cyberware_redline",
		"cyberware_cascade",
		"cyberware_piledriver",
	)
	research_costs = list(TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_5_POINTS)

// =========================================================================
// CHROME CRADLE BOARD
// =========================================================================

/obj/item/circuitboard/machine/chrome_cradle
	name = "\improper Chrome Cradle"
	greyscale_colors = CIRCUIT_COLOR_MEDICAL
	build_path = /obj/machinery/chrome_cradle
	req_components = list(
		/obj/item/stack/cable_coil = 5,
		/datum/stock_part/servo = 3,
		/datum/stock_part/scanning_module = 1,
		/obj/item/stack/sheet/plasteel = 2,
	)

/datum/design/board/chrome_cradle
	name = "Chrome Cradle Board"
	desc = "The circuit board for a Chrome Cradle, a six-armed rig that installs, removes and tunes up cyberware."
	id = "chrome_cradle"
	build_path = /obj/item/circuitboard/machine/chrome_cradle
	category = list(
		RND_CATEGORY_MACHINE + RND_SUBCATEGORY_MACHINE_MEDICAL
	)
	departmental_flags = DEPARTMENT_BITFLAG_MEDICAL | DEPARTMENT_BITFLAG_SCIENCE

// =========================================================================
// CHROME DESIGNS
// =========================================================================

/datum/design/cyberware
	name = "Cyberware"
	build_type = PROTOLATHE | MECHFAB
	construction_time = 6 SECONDS
	departmental_flags = DEPARTMENT_BITFLAG_MEDICAL | DEPARTMENT_BITFLAG_SCIENCE
	category = list(RND_CATEGORY_CYBERWARE + RND_SUBCATEGORY_CYBERWARE_STREET)
	materials = list(
		/datum/material/iron = SHEET_MATERIAL_AMOUNT,
		/datum/material/glass = SHEET_MATERIAL_AMOUNT * 0.5,
	)

/datum/design/cyberware/street
	category = list(RND_CATEGORY_CYBERWARE + RND_SUBCATEGORY_CYBERWARE_STREET)
	materials = list(
		/datum/material/iron = SHEET_MATERIAL_AMOUNT,
		/datum/material/glass = SHEET_MATERIAL_AMOUNT * 0.5,
		/datum/material/silver = SHEET_MATERIAL_AMOUNT * 0.5,
	)

/datum/design/cyberware/pro
	construction_time = 8 SECONDS
	category = list(RND_CATEGORY_CYBERWARE + RND_SUBCATEGORY_CYBERWARE_PRO)
	materials = list(
		/datum/material/iron = SHEET_MATERIAL_AMOUNT * 1.5,
		/datum/material/glass = SHEET_MATERIAL_AMOUNT,
		/datum/material/silver = SHEET_MATERIAL_AMOUNT,
		/datum/material/gold = SHEET_MATERIAL_AMOUNT,
	)

/datum/design/cyberware/military
	construction_time = 12 SECONDS
	category = list(RND_CATEGORY_CYBERWARE + RND_SUBCATEGORY_CYBERWARE_MILITARY)
	materials = list(
		/datum/material/titanium = SHEET_MATERIAL_AMOUNT * 2,
		/datum/material/glass = SHEET_MATERIAL_AMOUNT,
		/datum/material/gold = SHEET_MATERIAL_AMOUNT,
		/datum/material/uranium = SHEET_MATERIAL_AMOUNT,
		/datum/material/diamond = SHEET_MATERIAL_AMOUNT * 0.5,
	)

/datum/design/cyberware/legend
	construction_time = 20 SECONDS
	category = list(RND_CATEGORY_CYBERWARE + RND_SUBCATEGORY_CYBERWARE_LEGEND)
	materials = list(
		/datum/material/titanium = SHEET_MATERIAL_AMOUNT * 3,
		/datum/material/gold = SHEET_MATERIAL_AMOUNT * 2,
		/datum/material/diamond = SHEET_MATERIAL_AMOUNT * 2,
		/datum/material/bluespace = SHEET_MATERIAL_AMOUNT * 2,
		/datum/material/plasma = SHEET_MATERIAL_AMOUNT * 2,
	)

// ---- Fundamentals ------------------------------------------------------

/datum/design/cyberware/chromatic_dermis
	name = "Chromatic Dermis"
	desc = "Programmable circuit-tattoos under the skin. Pure show."
	id = "cyberware_chromatic_dermis"
	build_path = /obj/item/organ/cyberimp/cyberware/chromatic_dermis

/datum/design/cyberware/gastro
	name = "Gastro Reactor"
	desc = "A furnace where your stomach was. Eats anything that qualifies as food."
	id = "cyberware_gastro"
	build_path = /obj/item/organ/cyberimp/cyberware/gastro

/datum/design/cyberware/nightshade
	name = "Nightshade Optics"
	desc = "Chrome eyes that see in the dark and shrug off flashes. Replaces your eyes."
	id = "cyberware_nightshade"
	build_path = /obj/item/organ/eyes/robotic/cyberware/nightshade

// ---- Street ------------------------------------------------------------

/datum/design/cyberware/street/shock_coils
	name = "Shock Coil Calf Pistons"
	desc = "Faster knockdown recovery, sure footing on wet decks, softer falls."
	id = "cyberware_shock_coils"
	build_path = /obj/item/organ/cyberimp/cyberware/shock_coils

/datum/design/cyberware/street/scrapper
	name = "Scrapper's Knuckles (pair)"
	desc = "Knuckle plating for both hands, cased. Hits people harder, machines a lot harder."
	id = "cyberware_scrapper"
	build_path = /obj/item/storage/case/cyberware/scrapper

/datum/design/cyberware/street/gecko
	name = "Gecko Grips"
	desc = "Grip pads that keep hold of what you're carrying."
	id = "cyberware_gecko"
	build_path = /obj/item/organ/cyberimp/cyberware/gecko

/datum/design/cyberware/street/second_wind
	name = "Second Wind Bladder"
	desc = "A reserve of breathable air behind the lungs."
	id = "cyberware_second_wind"
	build_path = /obj/item/organ/cyberimp/cyberware/second_wind

/datum/design/cyberware/street/cargo_cavity
	name = "Cargo Cavity"
	desc = "One sealed slot behind the sternum that scanners skip."
	id = "cyberware_cargo_cavity"
	build_path = /obj/item/organ/cyberimp/cyberware/cargo_cavity

/datum/design/cyberware/street/rockjaw
	name = "Rockjaw Drill Arm"
	desc = "A mining drill that folds out of the forearm."
	id = "cyberware_rockjaw"
	build_path = /obj/item/organ/cyberimp/arm/cyberware/rockjaw

/datum/design/cyberware/street/fixers
	name = "Fixer's Fingers"
	desc = "A full tool kit folded into the fingers."
	id = "cyberware_fixers"
	build_path = /obj/item/organ/cyberimp/arm/cyberware/fixers

/datum/design/cyberware/street/dermal_mesh
	name = "Dermal Mesh"
	desc = "Light subdermal plating."
	id = "cyberware_dermal_mesh"
	build_path = /obj/item/organ/cyberimp/cyberware/dermal_mesh

// ---- Pro utility -------------------------------------------------------

/datum/design/cyberware/pro/angler
	name = "Angler Arm"
	desc = "A reel-and-hook arm for fishing things out of places you can't reach."
	id = "cyberware_angler"
	build_path = /obj/item/organ/cyberimp/arm/cyberware/angler

/datum/design/cyberware/pro/hemoglass
	name = "Hemoglass Filter"
	desc = "Filters toxins out of the blood."
	id = "cyberware_hemoglass"
	build_path = /obj/item/organ/cyberimp/cyberware/hemoglass

/datum/design/cyberware/pro/coolant
	name = "Coolant Loops"
	desc = "An environmental seal that keeps heat and cold off the body."
	id = "cyberware_coolant"
	build_path = /obj/item/organ/cyberimp/cyberware/coolant

/datum/design/cyberware/pro/doppler
	name = "Heartbeat Doppler"
	desc = "Aural hardware that hears heartbeats through walls."
	id = "cyberware_doppler"
	build_path = /obj/item/organ/cyberimp/cyberware/doppler

/datum/design/cyberware/pro/prospector
	name = "Prospector Optics"
	desc = "Surveyor eyes that ping ore veins and caches through rock. Replaces your eyes."
	id = "cyberware_prospector"
	build_path = /obj/item/organ/eyes/robotic/cyberware/prospector

/datum/design/cyberware/pro/graverobber
	name = "Graverobber Spike"
	desc = "A skull spike that drains a corpse's last memories for nearby signatures."
	id = "cyberware_graverobber"
	build_path = /obj/item/organ/cyberimp/arm/cyberware/graverobber

/datum/design/cyberware/pro/icepick
	name = "Icepick Data Spike"
	desc = "Knocks turrets offline or forces bolted and unpowered doors. Trips a security alert when it cracks a turret."
	id = "cyberware_icepick"
	build_path = /obj/item/organ/cyberimp/arm/cyberware/icepick

/datum/design/cyberware/pro/skyhook
	name = "Skyhook Wrist Winch"
	desc = "A grapple line that pulls you across gaps."
	id = "cyberware_skyhook"
	build_path = /obj/item/organ/cyberimp/arm/cyberware/skyhook

/datum/design/cyberware/pro/hopper
	name = "Hopper Pistons"
	desc = "Leg pistons that throw you over tables and crowds."
	id = "cyberware_hopper"
	build_path = /obj/item/organ/cyberimp/cyberware/hopper

// ---- Pro combat --------------------------------------------------------

/datum/design/cyberware/pro/deadeye
	name = "Deadeye Link"
	desc = "Targeting optics that tag a target for homing shots. Replaces your eyes."
	id = "cyberware_deadeye"
	build_path = /obj/item/organ/eyes/robotic/cyberware/deadeye

/datum/design/cyberware/pro/slipwire
	name = "Slipwire"
	desc = "A reflex booster wired into the nervous system."
	id = "cyberware_slipwire"
	build_path = /obj/item/organ/cyberimp/cyberware/slipwire

/datum/design/cyberware/pro/dead_channel
	name = "Dead Channel"
	desc = "A pain-feedback editor. You stop feeling how hurt you are, which is the point and the danger."
	id = "cyberware_dead_channel"
	build_path = /obj/item/organ/cyberimp/cyberware/dead_channel

// ---- Military body -----------------------------------------------------

/datum/design/cyberware/military/atlas
	name = "Atlas Frame"
	desc = "Skeletal reinforcement. Bones that don't break."
	id = "cyberware_atlas"
	build_path = /obj/item/organ/cyberimp/cyberware/atlas

/datum/design/cyberware/military/slabskin
	name = "Slabskin Plate"
	desc = "Heavy subdermal armor slabs."
	id = "cyberware_slabskin"
	build_path = /obj/item/organ/cyberimp/cyberware/slabskin

/datum/design/cyberware/military/ghostskin
	name = "Ghostskin Weave"
	desc = "Optical camouflage woven through the skin."
	id = "cyberware_ghostskin"
	build_path = /obj/item/organ/cyberimp/cyberware/ghostskin

/datum/design/cyberware/military/lazarus
	name = "Lazarus Node"
	desc = "An emergency reviver in the heart's aid slot."
	id = "cyberware_lazarus"
	build_path = /obj/item/organ/cyberimp/cyberware/lazarus

// ---- Military arms -----------------------------------------------------

/datum/design/cyberware/military/gorilla
	name = "Gorilla Arms (pair)"
	desc = "A pair of myomer forearm lattices, cased. Punches through people, doors and rock."
	id = "cyberware_gorilla"
	build_path = /obj/item/cyberware_pair_case/gorilla_arms

/datum/design/cyberware/military/mantis
	name = "Mantis Blades (pair)"
	desc = "A pair of folding forearm blades, cased."
	id = "cyberware_mantis"
	build_path = /obj/item/cyberware_pair_case/mantis_blades

/datum/design/cyberware/military/monowire
	name = "Widowline Monowire"
	desc = "A monomolecular whip spooled in the wrist."
	id = "cyberware_monowire"
	build_path = /obj/item/organ/cyberimp/arm/cyberware/monowire

/datum/design/cyberware/military/ronin
	name = "Popup Ronin"
	desc = "A submachine gun that folds into the forearm. Feeds a proprietary caliber."
	id = "cyberware_ronin"
	build_path = /obj/item/organ/cyberimp/arm/cyberware/ronin

/datum/design/cyberware/military/bunker_buster
	name = "Bunker Buster"
	desc = "A two-shot shaped-charge rocket pod built into the forearm."
	id = "cyberware_bunker_buster"
	build_path = /obj/item/organ/cyberimp/arm/cyberware/bunker_buster

/datum/design/cyberware/ammo
	construction_time = 3 SECONDS
	category = list(RND_CATEGORY_CYBERWARE + RND_SUBCATEGORY_CYBERWARE_AMMO)
	departmental_flags = DEPARTMENT_BITFLAG_MEDICAL | DEPARTMENT_BITFLAG_SCIENCE | DEPARTMENT_BITFLAG_SECURITY

/datum/design/cyberware/ammo/ronin_mag
	name = "Ronin Magazine"
	desc = "Proprietary caliber for the Popup Ronin."
	id = "cyberware_ronin_mag"
	build_path = /obj/item/ammo_box/magazine/cyberware_ronin
	materials = list(
		/datum/material/iron = SHEET_MATERIAL_AMOUNT * 2,
	)

/datum/design/cyberware/ammo/buster_rockets
	name = "Bunker Buster Rockets"
	desc = "A matched pair of shaped micro-rockets for the Bunker Buster pod."
	id = "cyberware_buster_rockets"
	build_path = /obj/item/ammo_box/cyberware_buster_rockets
	materials = list(
		/datum/material/iron = SHEET_MATERIAL_AMOUNT * 2,
		/datum/material/plasma = SHEET_MATERIAL_AMOUNT,
		/datum/material/titanium = SHEET_MATERIAL_AMOUNT * 0.5,
	)

// ---- Legend ------------------------------------------------------------

/datum/design/cyberware/legend/governor_delete
	name = "Governor Delete"
	desc = "Firmware that convinces your capacity governor your spine can carry six more points of load."
	id = "cyberware_governor_delete"
	build_path = /obj/item/organ/cyberimp/cyberware/governor_delete

/datum/design/cyberware/legend/redline
	name = "Redline Core"
	desc = "A berserker operating system. Stun immunity and a red window, then a crash."
	id = "cyberware_redline"
	build_path = /obj/item/organ/cyberimp/cyberware/redline

/datum/design/cyberware/legend/cascade
	name = "Cascade Lattice"
	desc = "Sandevistan-class reflex lattice. Eight seconds where everyone else may as well be furniture, then a crash."
	id = "cyberware_cascade"
	build_path = /obj/item/organ/cyberimp/cyberware/cascade

/datum/design/cyberware/legend/piledriver
	name = "Meteor Piledriver"
	desc = "Launch pistons that throw you into the air and down onto whoever is underneath."
	id = "cyberware_piledriver"
	build_path = /obj/item/organ/cyberimp/cyberware/piledriver
