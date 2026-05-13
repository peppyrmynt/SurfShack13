/datum/design/nanites/kickstart
	name = "Kickstart Protocol"
	desc = "Replication Protocol: the nanites focus on early growth, heavily boosting replication rate for a few minutes after the initial implantation."
	id = "kickstart_nanites"
	category = list(NANITES_CATEGORY_PROTOCOLS)
	program_type = /datum/nanite_program/protocol/kickstart

/datum/design/nanites/factory
	name = "Factory Protocol"
	desc = "Replication Protocol: the nanites build a factory matrix within the host, gradually increasing replication speed over time. The factory decays if the protocol is not active."
	id = "factory_nanites"
	category = list(NANITES_CATEGORY_PROTOCOLS)
	program_type = /datum/nanite_program/protocol/factory

/datum/design/nanites/tinker
	name = "Tinker Protocol"
	desc = "Replication Protocol: the nanites learn to use metallic material in the host's bloodstream to speed up the replication process."
	id = "tinker_nanites"
	category = list(NANITES_CATEGORY_PROTOCOLS)
	program_type = /datum/nanite_program/protocol/tinker

/datum/design/nanites/offline
	name = "Offline Production Protocol"
	desc = "Replication Protocol: while the host is asleep or otherwise unconcious, the nanites exploit the reduced interference to replicate more quickly."
	id = "offline_nanites"
	category = list(NANITES_CATEGORY_PROTOCOLS)
	program_type = /datum/nanite_program/protocol/offline

/datum/design/nanites/hive
	name = "Hive Protocol"
	desc = "Storage Protocol: the nanites use a more efficient grid arrangment for volume storage, increasing maximum volume in a host."
	id = "hive_nanites"
	category = list(NANITES_CATEGORY_PROTOCOLS)
	program_type = /datum/nanite_program/protocol/hive

/datum/design/nanites/zip
	name = "Zip Protocol"
	desc = "Storage Protocol: the nanites are disassembled and compacted when unused, greatly increasing the maximum volume while in a host. However, the process slows down the replication rate slightly."
	id = "zip_nanites"
	category = list(NANITES_CATEGORY_PROTOCOLS)
	program_type = /datum/nanite_program/protocol/zip

/datum/design/nanites/free_range
	name = "Free-range Protocol"
	desc = "Storage Protocol: the nanites discard their default storage protocols in favour of a cheaper and more organic approach. Reduces maximum volume, but increases the replication rate."
	id = "free_range_nanites"
	category = list(NANITES_CATEGORY_PROTOCOLS)
	program_type = /datum/nanite_program/protocol/free_range

/datum/design/nanites/unsafe_storage
	name = "S.L.O. Protocol"
	desc = "Storage Protocol: 'S.L.O.P.', or Storage Level Override Protocol, completely disables the safety measures normally present in nanites,\
		allowing them to reach much higher saturation levels, but at the risk of causing internal damage to the host."
	id = "unsafe_storage_nanites"
	category = list(NANITES_CATEGORY_PROTOCOLS)
	program_type = /datum/nanite_program/protocol/unsafe_storage


/datum/design/nanites/pyramid
	name = "Pyramid Protocol"
	desc = "Replication Protocol: the nanites implement an alternate cooperative replication protocol that is active as long as the nanite saturation level is above 50%, \
			resulting in an additional volume production of 1.5 per second."
	id = "pyramid_nanites"
	program_type = /datum/nanite_program/protocol/pyramid
	category = list(NANITES_CATEGORY_PROTOCOLS)

/datum/design/nanites/eclipse
	name = "Eclipse Protocol"
	desc = "Replication Protocol: while the host is dead, the nanites exploit the reduced interference to replicate roughly 6x quicker than normal."
	id = "eclipse_nanites"
	program_type = /datum/nanite_program/protocol/eclipse
	category = list(NANITES_CATEGORY_PROTOCOLS)

/datum/design/nanites/collective
	name = "Collective Protocol"
	desc = "Replication Protocol: the nanites adopt more strategic protocols for mass-replication, decreasing replication speed by 0.5, but increasing replication speed by a small amount for each host using this protocol."
	id = "collective_nanites"
	program_type = /datum/nanite_program/protocol/collective
	category = list(NANITES_CATEGORY_PROTOCOLS)

/datum/design/nanites/backup
	name = "Backup Protocol"
	desc = "Replication Protocol: the nanites siphon a small amount of themselves and stash them within the host for emergencies, slowing the replication speed by 0.5, but when the host falls to the default safety threshold of 50, they'll instantly recover a large amount of nanites."
	id = "backup_nanites"
	program_type = /datum/nanite_program/protocol/backup
	category = list(NANITES_CATEGORY_PROTOCOLS)

/datum/design/nanites/blood_storage
	name = "BLOOD Protocol"
	desc = "Replication Protocol: the nanites make themselves at home within the host's flesh and blood, but this comes at the cost of the host's blood and sometimes flesh."
	id = "blood_storage_nanites"
	program_type = /datum/nanite_program/protocol/blood_storage
	category = list(NANITES_CATEGORY_PROTOCOLS)

/datum/design/nanites/emergency
	name = "Emergency Protocol"
	desc = "Replication Protocol: the nanites can capable of detecting if the host is severely injured (atleast 75 damage), and will ramp up production in response."
	id = "emergency_nanites"
	program_type = /datum/nanite_program/protocol/emergency
	category = list(NANITES_CATEGORY_PROTOCOLS)

/datum/design/nanites/stasis
	name = "Stasis Protocol"
	desc = "Replication Protocol: the nanites take advantage of innately inert environments such as stasis or dead hosts, and can now replicate quickly without trouble in such environments. Also slightly boosts replication speeds in perfect health hosts."
	id = "stasis_nanites"
	program_type = /datum/nanite_program/protocol/stasis
	category = list(NANITES_CATEGORY_PROTOCOLS)
