// See code\__DEFINES\research\techweb_nodes.dm
#define TECHWEB_NODE_NANITE_BASE "nanite_base"
#define TECHWEB_NODE_NANITE_SMART "nanite_smart"
#define TECHWEB_NODE_NANITE_MESH "nanite_mesh"
#define TECHWEB_NODE_NANITE_BIO "nanite_bio"
#define TECHWEB_NODE_NANITE_NEURAL "nanite_neural"
#define TECHWEB_NODE_NANITE_SYNAPTIC "nanite_synaptic"
#define TECHWEB_NODE_NANITE_HARMONIC "nanite_harmonic"
#define TECHWEB_NODE_NANITE_MILITARY "nanite_military"
#define TECHWEB_NODE_NANITE_HAZARD "nanite_hazard"
#define TECHWEB_NODE_NANITE_REPLICATION "nanite_replication_protocols"
#define TECHWEB_NODE_NANITE_STORAGE "nanite_storage_protocols"


#define TECHWEB_NODE_NANITE_BASIC_TOOL "nanite_tool"
#define TECHWEB_NODE_NANITE_ADV_TOOL "nanite_tool_adv"
#define TECHWEB_NODE_NANITE_EXPERI "nanite_experi"
#define TECHWEB_NODE_NANITE_BRAINAUG "nanite_brainaug"
#define TECHWEB_NODE_NANITE_ILLEGAL "nanite_illegal"
#define TECHWEB_NODE_NANITE_EXPERI_MED "nanite_experi_med"
#define TECHWEB_NODE_NANITE_EXPERI_MED_ADV "nanite_experi_med_adv"
#define TECHWEB_NODE_NANITE_EXPERI_ADV "nanite_experi_adv"
#define TECHWEB_NODE_NANITE_MAGIC "nanite_magical"

#define TECHWEB_NODE_NANITE_REPLICATION_ADV "nanite_replication_protocols_adv"

/datum/techweb_node/nanite_base
	id = TECHWEB_NODE_NANITE_BASE
	starting_node = TRUE
	display_name = "Basic Nanite Programming"
	description = "The basics of nanite construction and programming."
	design_ids = list(
		"nanite_disk",
		"nanite_remote",
		"nanite_comm_remote",
		"nanite_scanner",
		"nanite_chamber",
		"nanite_chamber_control",
		"nanite_programmer",
		"nanite_program_hub",
		"nanite_cloud_control",
		"nanite_chamber_public",
		"relay_nanites",
		"access_nanites",
		"repairing_nanites",
		"sensor_nanite_volume",
		"repeater_nanites",
		"relay_repeater_nanites",
		"red_diag_nanites",
		"monitoring_nanites",
		"sensor_name_nanites",
		"sensor_resting_nanites",
	)
	research_costs = list(
		TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_1_POINTS,
	)

/datum/techweb_node/nanite_smart
	id = TECHWEB_NODE_NANITE_SMART
	display_name = "Smart Nanite Programming"
	description = "Nanite programs that require nanites to perform complex actions, act independently, roam or seek targets."
	prereq_ids = list(TECHWEB_NODE_NANITE_BASE, TECHWEB_NODE_ROBOTICS)
	design_ids = list(
		"purging_nanites",
		"metabolic_nanites",
		"stealth_nanites",
		"memleak_nanites",
		"sensor_voice_nanites",
		"voice_nanites",
		"research_nanites",
		"sensor_job_nanites",
		"sensor_incapacitated_nanites",
	)
	research_costs = list(
		TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_1_POINTS,
		TECHWEB_POINT_TYPE_NANITES = TECHWEB_TIER_1_POINTS*NANITE_POINT_CONVERSION_RATE,
	)

/datum/techweb_node/nanite_mesh
	id = TECHWEB_NODE_NANITE_MESH
	display_name = "Mesh Nanite Programming"
	description = "Nanite programs that require static structures and membranes."
	prereq_ids = list(TECHWEB_NODE_NANITE_BASE, TECHWEB_NODE_PARTS_ADV)
	design_ids = list(
		"hardening_nanites",
		"dermal_button_nanites",
		"refractive_nanites",
		"cryo_nanites",
		"conductive_nanites",
		"shock_nanites",
		"emp_nanites",
		"temperature_nanites",
	)
	research_costs = list(
		TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_2_POINTS,
		TECHWEB_POINT_TYPE_NANITES = TECHWEB_TIER_1_POINTS*NANITE_POINT_CONVERSION_RATE,
	)

/datum/techweb_node/nanite_bio
	id = TECHWEB_NODE_NANITE_BIO
	display_name = "Biological Nanite Programming"
	description = "Nanite programs that require complex biological interaction."
	prereq_ids = list(TECHWEB_NODE_NANITE_BASE, TECHWEB_NODE_MEDBAY_EQUIP)
	design_ids = list(
		"regenerative_nanites",
		"bloodheal_nanites",
		"coagulating_nanites",
		"oxyheal_nanites",
		"poison_nanites",
		"flesheating_nanites",
		"sensor_crit_nanites",
		"sensor_death_nanites",
		"sensor_health_nanites",
		"sensor_damage_nanites",
		"sensor_species_nanites",
		"sensor_alive_nanites",
	)
	research_costs = list(
		TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_2_POINTS,
		TECHWEB_POINT_TYPE_NANITES = TECHWEB_TIER_1_POINTS*NANITE_POINT_CONVERSION_RATE,
	)

/datum/techweb_node/nanite_neural
	id = TECHWEB_NODE_NANITE_NEURAL
	display_name = "Neural Nanite Programming"
	description = "Nanite programs affecting nerves and brain matter."
	prereq_ids = list(TECHWEB_NODE_NANITE_BIO, TECHWEB_NODE_NANITE_SMART)
	design_ids = list(
		"nervous_nanites",
		"brainheal_nanites",
		"paralyzing_nanites",
		"stun_nanites",
		"selfscan_nanites",
		"good_mood_nanites",
		"bad_mood_nanites",
	)
	research_costs = list(
		TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_3_POINTS,
		TECHWEB_POINT_TYPE_NANITES = TECHWEB_TIER_2_POINTS*NANITE_POINT_CONVERSION_RATE,
	)

/datum/techweb_node/nanite_synaptic
	id = TECHWEB_NODE_NANITE_SYNAPTIC
	display_name = "Synaptic Nanite Programming"
	description = "Nanite programs affecting mind and thoughts."
	prereq_ids = list(TECHWEB_NODE_NANITE_NEURAL, TECHWEB_NODE_PASSIVE_IMPLANTS)
	design_ids = list(
		"mindshield_nanites",
		"pacifying_nanites",
		"blinding_nanites",
		"sleep_nanites",
		"mute_nanites",
		"speech_nanites",
		"researchplus_nanites",
	)
	research_costs = list(
		TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_3_POINTS,
		TECHWEB_POINT_TYPE_NANITES = TECHWEB_TIER_2_POINTS*NANITE_POINT_CONVERSION_RATE,
	)

/datum/techweb_node/nanite_harmonic
	id = TECHWEB_NODE_NANITE_HARMONIC
	display_name = "Harmonic Nanite Programming"
	description = "Nanite programs that require seamless integration between nanites and biology."
	prereq_ids = list(TECHWEB_NODE_NANITE_NEURAL, TECHWEB_NODE_NANITE_MESH)
	design_ids = list(
		"fakedeath_nanites",
		"aggressive_nanites",
		"defib_nanites",
		"regenerative_plus_nanites",
		"brainheal_plus_nanites",
		"purging_plus_nanites",
		"adrenaline_nanites",
	)
	research_costs = list(
		TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_4_POINTS,
		TECHWEB_POINT_TYPE_NANITES = TECHWEB_TIER_4_POINTS*NANITE_POINT_CONVERSION_RATE,
	)

/datum/techweb_node/nanite_combat
	id = TECHWEB_NODE_NANITE_MILITARY
	display_name = "Military Nanite Programming"
	description = "Nanite programs that perform military-grade functions."
	prereq_ids = list(TECHWEB_NODE_NANITE_HARMONIC, TECHWEB_NODE_SYNDICATE_BASIC)
	design_ids = list(
		"explosive_nanites",
		"pyro_nanites",
		"meltdown_nanites",
		"viral_nanites",
		"nanite_sting_nanites",
	)
	research_costs = list(
		TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_5_POINTS,
		TECHWEB_POINT_TYPE_NANITES = TECHWEB_TIER_3_POINTS*NANITE_POINT_CONVERSION_RATE,
	)

/datum/techweb_node/nanite_hazard
	id = TECHWEB_NODE_NANITE_HAZARD
	display_name = "Hazard Nanite Programs"
	description = "Extremely advanced Nanite programs with the potential of being extremely dangerous."
	prereq_ids = list(TECHWEB_NODE_NANITE_HARMONIC, TECHWEB_NODE_ALIENTECH)
	design_ids = list(
		"spreading_nanites",
		"mindcontrol_nanites",
		"mitosis_nanites",
	)
	research_costs = list(
		TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_5_POINTS,
		TECHWEB_POINT_TYPE_NANITES = TECHWEB_TIER_5_POINTS*NANITE_POINT_CONVERSION_RATE,
	)

/datum/techweb_node/nanite_replication_protocols
	id = TECHWEB_NODE_NANITE_REPLICATION
	display_name = "Nanite Replication Protocols"
	description = "Advanced behaviours that allow nanites to exploit certain circumstances to replicate faster."
	prereq_ids = list(TECHWEB_NODE_NANITE_SMART)
	design_ids = list(
		"kickstart_nanites",
		"factory_nanites",
		"tinker_nanites",
		"offline_nanites",
		"collective_nanites",
		"pyramid_nanites",
	)
	research_costs = list(
		TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_3_POINTS,
		TECHWEB_POINT_TYPE_NANITES = TECHWEB_TIER_3_POINTS*NANITE_POINT_CONVERSION_RATE,
	)
	hidden = FALSE
	experimental = TRUE

/datum/techweb_node/nanite_replication_protocols_adv
	id = TECHWEB_NODE_NANITE_REPLICATION_ADV
	display_name = "Nanite Experimental Replication Protocols"
	description = "Highly experimental behaviours that allow nanites to exploit certain circumstances to replicate faster."
	prereq_ids = list(TECHWEB_NODE_NANITE_REPLICATION, TECHWEB_NODE_NANITE_SYNAPTIC)
	design_ids = list(
		"eclipse_nanites",
		"backup_nanites",
		"blood_storage_nanites",
		"emergency_nanites",
		"stasis_nanites",
	)
	research_costs = list(
		TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_3_POINTS,
		TECHWEB_POINT_TYPE_NANITES = TECHWEB_TIER_4_POINTS*NANITE_POINT_CONVERSION_RATE,
	)
	hidden = FALSE
	experimental = TRUE

/datum/techweb_node/nanite_storage_protocols
	id = TECHWEB_NODE_NANITE_STORAGE
	display_name = "Nanite Storage Protocols"
	description = "Protocols that overwrite the default nanite storage routine to achieve more efficiency or greater capacity."
	prereq_ids = list(TECHWEB_NODE_NANITE_SMART)
	design_ids = list(
		"free_range_nanites",
		"hive_nanites",
		"unsafe_storage_nanites",
		"zip_nanites",
	)
	research_costs = list(
		TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_2_POINTS,
		TECHWEB_POINT_TYPE_NANITES = TECHWEB_TIER_3_POINTS*NANITE_POINT_CONVERSION_RATE,
	)
	hidden = FALSE
	experimental = TRUE


/datum/techweb_node/nanite_tools
	id = TECHWEB_NODE_NANITE_BASIC_TOOL
	display_name = "Basic Nanite Manufacturing"
	description = "Nanites programs that allow for easy construction of basic items."
	research_costs = list(
		TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_1_POINTS,
		TECHWEB_POINT_TYPE_NANITES = TECHWEB_TIER_1_POINTS*NANITE_POINT_CONVERSION_RATE,)
	prereq_ids = list(TECHWEB_NODE_NANITE_BASE)
	design_ids = list("construct_tool_nanites", "convert_nanites")

/datum/techweb_node/nanite_tools_adv
	id = TECHWEB_NODE_NANITE_ADV_TOOL
	display_name = "Advanced Nanite Manufacturing"
	description = "Nanites programs that allow for easy construction of advanced items."
	research_costs = list(
		TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_2_POINTS,
		TECHWEB_POINT_TYPE_NANITES = TECHWEB_TIER_2_POINTS*NANITE_POINT_CONVERSION_RATE,)
	prereq_ids = list(TECHWEB_NODE_NANITE_BASIC_TOOL, TECHWEB_NODE_EXP_TOOLS)
	design_ids = list("construct_tool_adv_nanites", "botsummon_nanites")


/datum/techweb_node/nanite_experimental
	id = TECHWEB_NODE_NANITE_EXPERI
	display_name = "Experimental Nanite Programming"
	description = "Nanite programs that aren't specific to any category and are often highly experimental by nature."
	research_costs = list(
		TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_2_POINTS,
		TECHWEB_POINT_TYPE_NANITES = TECHWEB_TIER_2_POINTS*NANITE_POINT_CONVERSION_RATE,)
	prereq_ids = list(TECHWEB_NODE_NANITE_BIO, TECHWEB_NODE_NANITE_SMART)
	design_ids = list("stickyfingers_nanites", "accelerated_synthesis_nanites", "bluespace_blood_nanites", "extinguisher_nanites", "antishove_nanites", "gravity_nanites")

/datum/techweb_node/nanite_brainaug
	id = TECHWEB_NODE_NANITE_BRAINAUG
	display_name = "Mental Augmentation Nanite Programming"
	description = "Nanite programs that augment or change one's mind."
	research_costs = list(
		TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_3_POINTS,
		TECHWEB_POINT_TYPE_NANITES = TECHWEB_TIER_3_POINTS*NANITE_POINT_CONVERSION_RATE,)
	prereq_ids = list(TECHWEB_NODE_NANITE_NEURAL, TECHWEB_NODE_NANITE_EXPERI)
	design_ids = list("kravmaga_nanites", "neuraltrauma_nanites")

/datum/techweb_node/nanite_illegal
	id = TECHWEB_NODE_NANITE_ILLEGAL
	display_name = "Illegal Nanite Programming"
	description = "Dangerous nanite programs capable of causing or enabling significant harm, destruction, or mayhem."
	research_costs = list(
		TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_5_POINTS,
		TECHWEB_POINT_TYPE_NANITES = TECHWEB_TIER_5_POINTS*NANITE_POINT_CONVERSION_RATE,)
	prereq_ids = list(TECHWEB_NODE_SYNDICATE_BASIC, TECHWEB_NODE_NANITE_SYNAPTIC)
	design_ids = list("freedom_nanites", "construct_ammo_nanites", "construct_c4_nanites", "slipresist_nanites", "braintrauma_nanites", "suicidal_nanites")

/datum/techweb_node/nanite_experi_med
	id = TECHWEB_NODE_NANITE_EXPERI_MED
	display_name = "Advanced Medical Nanite Programming"
	description = "Nanite programs that provide unique and selective medical features to the host."
	research_costs = list(
		TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_3_POINTS,
		TECHWEB_POINT_TYPE_NANITES = TECHWEB_TIER_3_POINTS*NANITE_POINT_CONVERSION_RATE,)
	prereq_ids = list(TECHWEB_NODE_NANITE_EXPERI, TECHWEB_NODE_NANITE_NEURAL)
	design_ids = list("bodyaugment_nanites", "critstable_nanites", "corpsepreserve_nanites", "organrepair_nanites", "antidismember_nanites", "weakness_nanites", "hardiness_nanites", "mendingbrute_nanites", "mendingburn_nanites")

/datum/techweb_node/nanite_experi_med_adv
	id = TECHWEB_NODE_NANITE_EXPERI_MED_ADV
	display_name = "Experimental Medical Nanite Programming"
	description = "Nanite programs that provide very useful medical-specific benefits to the host."
	research_costs = list(
		TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_4_POINTS,
		TECHWEB_POINT_TYPE_NANITES = TECHWEB_TIER_4_POINTS*NANITE_POINT_CONVERSION_RATE,)
	prereq_ids = list(TECHWEB_NODE_NANITE_EXPERI_MED, TECHWEB_NODE_NANITE_HARMONIC)
	design_ids = list("mendingtoxin_nanites", "selfresp_nanites", "repairingplus_nanites", "woundfixer_nanites", "naniteresus_nanites", "synthflesh_nanites", "painnull_nanites", "alcoholic_nanites", "antikpa_nanites", "limbtach_nanites")

/datum/techweb_node/nanite_experi_adv
	id = TECHWEB_NODE_NANITE_EXPERI_ADV
	display_name = "Highly Experimental Nanite Programming"
	description = "Nanite programs that often exceed the capabilities any normal scientist would expect of our favorite nano-machines."
	research_costs = list(
		TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_3_POINTS,
		TECHWEB_POINT_TYPE_NANITES = TECHWEB_TIER_3_POINTS*NANITE_POINT_CONVERSION_RATE,)
	prereq_ids = list(TECHWEB_NODE_NANITE_EXPERI, TECHWEB_NODE_NANITE_SYNAPTIC)
	design_ids = list("antigibbing_nanites", "antirad_nanites", "weatherendure_nanites", "obsidian_nanites", "plantlike_nanites", "lungdestruction_nanites")

/datum/techweb_node/nanite_magical
	id = TECHWEB_NODE_NANITE_MAGIC
	display_name = "Borderline Magical Nanite Programming"
	description = "Nanite programs that are confounding to our top researchers, you'd have to be a wizard to be able to fathom these programs."
	research_costs = list(
		TECHWEB_POINT_TYPE_GENERIC = TECHWEB_TIER_4_POINTS,
		TECHWEB_POINT_TYPE_NANITES = TECHWEB_TIER_4_POINTS*NANITE_POINT_CONVERSION_RATE,)
	prereq_ids = list(TECHWEB_NODE_NANITE_EXPERI_ADV)
	design_ids = list("magicshield_nanites", "deadchat_nanites")
