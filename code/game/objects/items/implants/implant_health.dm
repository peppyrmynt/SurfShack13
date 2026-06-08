/obj/item/implant/robusttec
	name = "R.O.B.U.S.T tech implant"
	desc = "An exceedingly rare implant designed to produce medicinal chemicals within the host should they be harmed too greatly."
	actions_types = null
	var/primarymed = /datum/reagent/medicine/omnizine
	var/primaryamt = 10
	var/secondarymed = /datum/reagent/medicine/coagulant
	var/secondaryamt = 10
	var/triggermod = 40 // crit + 40 health.
	var/cd_dur = 100 SECONDS // 100 seconds to ensure all the omnizine is metabolized
	var/cooldown = FALSE

/obj/item/implant/robusttec/implant(mob/living/target, mob/user, silent = FALSE, force = FALSE)
	. = ..()
	if(.)
		RegisterSignal(target, COMSIG_LIVING_HEALTH_UPDATE, PROC_REF(check_health))

/obj/item/implant/robusttec/removed(mob/target, silent = FALSE, special = FALSE)
	. = ..()
	if(.)
		UnregisterSignal(target, COMSIG_LIVING_HEALTH_UPDATE)

/obj/item/implant/robusttec/proc/check_health(mob/living/source)
	SIGNAL_HANDLER

	if(cooldown)
		return
	if(source.health < (source.crit_threshold + triggermod))
		inject_chems(source)

/obj/item/implant/robusttec/proc/inject_chems(mob/living/source)
	cooldown = TRUE

	if(!source.reagents.has_reagent(primarymed))
		source.reagents.add_reagent(primarymed, primaryamt)
	if(!source.reagents.has_reagent(secondarymed))
		source.reagents.add_reagent(secondarymed, secondaryamt)

	addtimer(CALLBACK(src, PROC_REF(reset_cd)), cd_dur)

/obj/item/implant/robusttec/proc/reset_cd(mob/living/source)
	cooldown = FALSE


/obj/item/implant/robusttec/lesser
	primarymed = /datum/reagent/medicine/omnizine/protozine
	primaryamt = 4
	secondaryamt = 4

/obj/item/implant/robusttec/antirot
	name = "R.O.T.B.U.S.T tech implant"
	desc = "An exceedingly rare implant designed to automatically preserve corpses."
	primarymed = /datum/reagent/medicine/omnizine/protozine
	primaryamt = 1
	secondarymed = /datum/reagent/toxin/formaldehyde
	secondaryamt = 3
	triggermod = -100 // proc on death, assuming you don't have VITALITY or SUPERHUMAN.


/obj/item/implanter/robusttec
	name = "implanter (R.O.B.U.S.T)"
	imp_type = /obj/item/implant/robusttec

/obj/item/implantcase/robusttec
	name = "Implant Case - 'R.O.B.U.S.T'"
	desc = "A glass case containing a R.O.B.U.S.T implant."
	imp_type = /obj/item/implant/robusttec

/obj/item/implanter/robusttec/lesser
	name = "implanter (R.O.B.U.S.T)"
	imp_type = /obj/item/implant/robusttec/lesser

/obj/item/implantcase/robusttec/lesser
	name = "Implant Case - 'R.O.B.U.S.T'"
	desc = "A glass case containing a R.O.B.U.S.T implant."
	imp_type = /obj/item/implant/robusttec/lesser

/obj/item/implanter/robusttec/antirot
	name = "implanter (R.O.T.B.U.S.T)"
	imp_type = /obj/item/implant/robusttec/antirot

/obj/item/implantcase/robusttec/antirot
	name = "Implant Case - 'R.O.T.B.U.S.T'"
	desc = "A glass case containing a R.O.T.B.U.S.T implant."
	imp_type = /obj/item/implant/robusttec/antirot
