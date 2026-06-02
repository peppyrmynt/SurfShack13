/datum/uplink_item/role_restricted/nadelauncher
	name = "Grenade Launcher"
	desc = "A somewhat bulky grenade launcher, it can prime and fire many different kinds of grenades INCLUDING chemical grenades. Can load three grenades at any time."
	item = /obj/item/gun/grenadelauncher
	cost = 9
	surplus = 25
	restricted_roles = list(JOB_CHEMIST, JOB_CHIEF_MEDICAL_OFFICER)
