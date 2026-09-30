// Syndi Gatfruit - ported from HippieStation.
// Normal gatfruit (grows .357 revolvers) that matures twice as fast, sold to traitor botanists.

/obj/item/seeds/gatfruit/syndi
	maturation = 20

/datum/uplink_item/role_restricted/gatfruit
	name = "Syndi Gatfruit"
	desc = "An extremely rare plant seed which grows .357 revolvers. Has been modified to mature twice as fast as normal Gatfruit."
	item = /obj/item/seeds/gatfruit/syndi
	cost = 18
	restricted_roles = list(JOB_BOTANIST)
