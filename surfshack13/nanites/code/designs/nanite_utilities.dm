/datum/design/nanites/metabolic_synthesis
	name = "Metabolic Synthesis"
	desc = "The nanites use the metabolic cycle of the host to speed up their replication rate, using their extra nutrition as fuel."
	id = "metabolic_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/metabolic_synthesis

/datum/design/nanites/viral
	name = "Viral Replica"
	desc = "The nanites constantly send encrypted signals attempting to forcefully copy their own programming into other nanite clusters."
	id = "viral_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/viral

/datum/design/nanites/self_scan
	name = "Host Scan"
	desc = "The nanites display a detailed readout of a body scan to the host."
	id = "selfscan_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/self_scan

/datum/design/nanites/dermal_button
	name = "Dermal Button"
	desc = "Displays a button on the host's skin, which can be used to send a signal to the nanites."
	id = "dermal_button_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/dermal_button

/datum/design/nanites/stealth
	name = "Stealth"
	desc = "The nanites hide their activity and programming from superficial scans."
	id = "stealth_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/stealth

/datum/design/nanites/reduced_diagnostics
	name = "Reduced Diagnostics"
	desc = "Disables some high-cost diagnostics in the nanites, making them unable to communicate their program list to portable scanners. \
	Doing so saves some power, slightly increasing their replication speed."
	id = "red_diag_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/reduced_diagnostics

/datum/design/nanites/access
	name = "Subdermal ID"
	desc = "The nanites store the host's ID access rights in a subdermal magnetic strip. Updates when triggered, copying the host's current access."
	id = "access_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/access

/datum/design/nanites/relay
	name = "Relay"
	desc = "The nanites receive and relay long-range nanite signals."
	id = "relay_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/relay

/datum/design/nanites/repeater
	name = "Signal Repeater"
	desc = "When triggered, sends another signal to the nanites, optionally with a delay."
	id = "repeater_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/sensor/repeat

/datum/design/nanites/relay_repeater
	name = "Relay Signal Repeater"
	desc = "When triggered, sends another signal to a relay channel, optionally with a delay."
	id = "relay_repeater_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/sensor/relay_repeat

/datum/design/nanites/emp
	name = "Electromagnetic Resonance"
	desc = "The nanites cause an electromagnetic pulse around the host when triggered. Will corrupt other nanite programs!"
	id = "emp_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/emp

/datum/design/nanites/spreading
	name = "Infective Exo-Locomotion"
	desc = "The nanites gain the ability to survive for brief periods outside of the human body, as well as the ability to start new colonies without an integration process; \
			resulting in an extremely infective strain of nanites."
	id = "spreading_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/spreading

/datum/design/nanites/nanite_sting
	name = "Nanite Sting"
	desc = "When triggered, projects a nearly invisible spike of nanites that attempts to infect a nearby non-host with a copy of the host's nanites cluster."
	id = "nanite_sting_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/nanite_sting

/datum/design/nanites/mitosis
	name = "Mitosis"
	desc = "The nanites gain the ability to self-replicate, using bluespace to power the process, instead of drawing from a template. This rapidly speeds up the replication rate,\
			but it causes occasional software errors due to faulty copies. Not compatible with cloud sync."
	id = "mitosis_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/mitosis


/datum/design/nanites/research
	name = "Distributed Computing"
	desc = "The nanites aid the research servers by performing a portion of its calculations, providing additional general research point generation and nanite point generation."
	id = "research_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/research

/datum/design/nanites/accelerated_synthesis
	name = "Accelerated Synthesis"
	desc = "The nanites adopt a simpler method of self-replication to speed up their replication rate, while this may cause corruptions, it won't prevent cloud linking."
	id = "accelerated_synthesis_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/accelerated_synthesis

/datum/design/nanites/construct_tool
	name = "Construct Nanite Tool"
	desc = "The nanites gather into the palm of the host's hand and form a specific tool such as a crowbar or wrench."
	id = "construct_tool_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/construct_tool

/datum/design/nanites/convert_nanites
	name = "Convert Nanites"
	desc = "The nanites gather into the palm of the host's hand and form a specific material such as metal sheets or glass sheets. \
			The items do NOT disappear afterward."
	id = "convert_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/convert_nanites

/datum/design/nanites/construct_tool_adv
	name = "Construct Advanced Nanite Tool"
	desc = "The nanites gather into the palm of the host's hand and form a specific tool such as a multitool or holofan projector."
	id = "construct_tool_adv_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/construct_tool_adv

/datum/design/nanites/bluespace_blood
	name = "Bluespace Harvestation"
	desc = "The nanites will harvest foreign bluespace energies and store them away. Once the proper signal is recieved, \
			the nanites invest the bluespace energies into the host's bloodstream. Causing temporary spontaneous short-range teleportation."
	id = "bluespace_blood_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/bluespace_blood

/datum/design/nanites/botsummon
	name = "Simple Bot Construction"
	desc = "The nanites expend a large amount of themselves to develop a single simple bot capable of assisting \
			the station and it's personnel."
	id = "botsummon_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/botsummon

/datum/design/nanites/researchplus
	name = "Nanite Research Servers"
	desc = "The nanites adopt research server programming and may expend themselves to \
			generate both general and nanite research points in substantial amounts."
	id = "researchplus_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/researchplus

/datum/design/nanites/deadchat
	name = "Otherworldly Programming"
	desc = "The nanites keep the host's brain in a constant state of near-death, \
			causing strange yet vivid auditory hallucinations."
	id = "deadchat_nanites"
	category = list(NANITE_CATEGORY_UTILITIES)
	program_type = /datum/nanite_program/deadchat

/datum/design/nanites/monitoring
	name = "Monitoring"
	desc = "The nanites monitor the host's vitals and location, sending them to the suit sensor network. Cannot function if the host isn't wearing a suit."
	id = "monitoring_nanites"
	program_type = /datum/nanite_program/monitoring
	category = list(NANITE_CATEGORY_UTILITIES)

/datum/design/nanites/freedom
	name = "Freedom Procedure"
	desc = "The nanites search for restraints upon the host and remove them quickly."
	id = "freedom_nanites"
	program_type = /datum/nanite_program/freedom
	category = list(NANITE_CATEGORY_UTILITIES)
