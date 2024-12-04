/datum/job/quartermaster
	title = JOB_QUARTERMASTER
	description = "Coordinate cargo technicians and shaft miners, assist with \
		economical purchasing."
	department_head = list(JOB_HEAD_OF_PERSONNEL)
	faction = FACTION_STATION
	total_positions = 1
	spawn_positions = 1
	supervisors = SUPERVISOR_HOP
	exp_required_type_department = EXP_TYPE_SUPPLY
	exp_granted_type = EXP_TYPE_CREW
	config_tag = "QUARTERMASTER"

	outfit = /datum/outfit/job/quartermaster
	plasmaman_outfit = /datum/outfit/plasmaman/cargo

	paycheck = PAYCHECK_CREW
	paycheck_department = ACCOUNT_CAR

	liver_traits = list(TRAIT_PRETENDER_ROYAL_METABOLISM) // never again

	display_order = JOB_DISPLAY_ORDER_QUARTERMASTER
	bounty_types = CIV_JOB_RANDOM
	departments_list = list(
		/datum/job_department/cargo,
		)
	family_heirlooms = list(/obj/item/stamp, /obj/item/stamp/denied)
	mail_goodies = list(
		/obj/item/circuitboard/machine/emitter = 3
	)
	rpg_title = "Steward"
	job_flags = STATION_JOB_FLAGS

/datum/outfit/job/quartermaster
	name = "Quartermaster"
	jobtype = /datum/job/quartermaster
	id_trim = /datum/id_trim/job/quartermaster
	uniform = /obj/item/clothing/under/rank/cargo/qm
	belt = /obj/item/modular_computer/pda/quartermaster
	suit = /obj/item/clothing/suit/jacket/quartermaster
	ears = /obj/item/radio/headset/headset_cargo
	glasses = /obj/item/clothing/glasses/sunglasses
	shoes = /obj/item/clothing/shoes/laceup
	l_hand = /obj/item/clipboard
