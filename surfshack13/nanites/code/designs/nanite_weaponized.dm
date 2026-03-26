/datum/design/nanites/flesh_eating
	name = "Cellular Breakdown"
	desc = "The nanites destroy cellular structures in the host's body, causing brute damage."
	id = "flesheating_nanites"
	category = list(NANITES_CATEGORY_WEAPONIZED)
	program_type = /datum/nanite_program/flesh_eating

/datum/design/nanites/poison
	name = "Poisoning"
	desc = "The nanites deliver poisonous chemicals to the host's internal organs, causing toxin damage and vomiting."
	id = "poison_nanites"
	category = list(NANITES_CATEGORY_WEAPONIZED)
	program_type = /datum/nanite_program/poison

/datum/design/nanites/memory_leak
	name = "Memory Leak"
	desc = "This program invades the memory space used by other programs, causing frequent corruptions and errors."
	id = "memleak_nanites"
	category = list(NANITES_CATEGORY_WEAPONIZED)
	program_type = /datum/nanite_program/memory_leak

/datum/design/nanites/aggressive_replication
	name = "Aggressive Replication"
	desc = "Nanites will consume organic matter to improve their replication rate, damaging the host."
	id = "aggressive_nanites"
	category = list(NANITES_CATEGORY_WEAPONIZED)
	program_type = /datum/nanite_program/aggressive_replication

/datum/design/nanites/meltdown
	name = "Meltdown"
	desc = "Causes an internal meltdown inside the nanites, causing internal burns inside the host as well as rapidly destroying the nanite population.\
			Sets the nanites' safety threshold to 0 when activated."
	id = "meltdown_nanites"
	category = list(NANITES_CATEGORY_WEAPONIZED)
	program_type = /datum/nanite_program/meltdown

/datum/design/nanites/cryo
	name = "Cryogenic Treatment"
	desc = "The nanites rapidly skin heat through the host's skin, lowering their temperature."
	id = "cryo_nanites"
	category = list(NANITES_CATEGORY_WEAPONIZED)
	program_type = /datum/nanite_program/cryo

/datum/design/nanites/pyro
	name = "Sub-Dermal Combustion"
	desc = "The nanites cause buildup of flammable fluids under the host's skin, then ignites them."
	id = "pyro_nanites"
	category = list(NANITES_CATEGORY_WEAPONIZED)
	program_type = /datum/nanite_program/pyro

/datum/design/nanites/heart_stop
	name = "Heart-Stopper"
	desc = "Stops the host's heart when triggered; restarts it if triggered again."
	id = "heartstop_nanites"
	category = list(NANITES_CATEGORY_WEAPONIZED)
	program_type = /datum/nanite_program/heart_stop

/datum/design/nanites/explosive
	name = "Chain Detonation"
	desc = "Blows up all the nanites inside the host in a chain reaction when triggered."
	id = "explosive_nanites"
	category = list(NANITES_CATEGORY_WEAPONIZED)
	program_type = /datum/nanite_program/explosive

/datum/design/nanites/mind_control
	name = "Mind Control"
	desc = "The nanites imprint an absolute directive onto the host's brain while they're active."
	id = "mindcontrol_nanites"
	category = list(NANITES_CATEGORY_WEAPONIZED)
	program_type = /datum/nanite_program/comm/mind_control


/datum/design/nanites/construct_ammo
	name = "Construct Ammunition"
	desc = "The nanites expends a moderate amount of themselves to create a ammo box loaded with a certain kind of ammunition, ready for use."
	id = "construct_ammo_nanites"
	program_type = /datum/nanite_program/construct_ammo
	category = list(NANITES_CATEGORY_WEAPONIZED)

/datum/design/nanites/construct_c4
	name = "Explosives Construction"
	desc = "The nanites expends a large amount of themselves to create a C4 charge."
	id = "construct_c4_nanites"
	program_type = /datum/nanite_program/construct_c4
	category = list(NANITES_CATEGORY_WEAPONIZED)

/datum/design/nanites/kravmaga
	name = "Martial Art Imprinting"
	desc = "The nanites imprint the knowledge of krav maga onto the host, allowing them to use the martial art so long as this program exists."
	id = "kravmaga_nanites"
	program_type = /datum/nanite_program/kravmaga
	category = list(NANITES_CATEGORY_WEAPONIZED)

/datum/design/nanites/neuraltrauma
	name = "Neural Traumatic Nanites"
	desc = "The nanites inflict havoc with the host's brain by firing electrical signals spontaneously, resulting in neural trauma."
	id = "neuraltrauma_nanites"
	program_type = /datum/nanite_program/neuraltrauma
	category = list(NANITES_CATEGORY_WEAPONIZED)

/datum/design/nanites/braintrauma
	name = "Brain Traumatic Nanites"
	desc = "The nanites begin disassembling parts of the brain in a non-lethal manner, causing wide-spread chaos and trauma all across the brain. This results in severe brain trauma for the host."
	id = "braintrauma_nanites"
	program_type = /datum/nanite_program/braintrauma
	category = list(NANITES_CATEGORY_WEAPONIZED)

/datum/design/nanites/suicidal
	name = "Suicide Procedure"
	desc = "The nanites expend a large portion of themselves to synthesis cyanide within the host's blood. Resulting in either a severely damaged liver, or death in the host."
	id = "suicidal_nanites"
	program_type = /datum/nanite_program/suicidal
	category = list(NANITES_CATEGORY_WEAPONIZED)

/datum/design/nanites/lungdestruction
	name = "Respiratory Distress"
	desc = "The nanites slowly cripple and destroy the host's lungs."
	id = "lungdestruction_nanites"
	program_type = /datum/nanite_program/lungdestruction
	category = list(NANITES_CATEGORY_WEAPONIZED)
