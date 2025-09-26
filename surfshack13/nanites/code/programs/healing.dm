/datum/nanite_program/regenerative
	name = "Accelerated Regeneration"
	desc = "The nanites boost the host's natural regeneration, increasing their healing speed. \
		Does not consume nanites if the host is unharmed. \
		Works better in low-pressure environments."
	use_rate = 0.5
	rogue_types = list(/datum/nanite_program/necrotic)

/datum/nanite_program/regenerative/check_conditions()
	if(!host_mob.getBruteLoss() && !host_mob.getFireLoss())
		return FALSE
	if(iscarbon(host_mob))
		var/mob/living/carbon/host_carbon = host_mob
		var/list/parts = host_carbon.get_damaged_bodyparts(brute = TRUE, burn = TRUE, required_bodytype = BODYTYPE_ORGANIC)
		if(!parts.len)
			return FALSE
	return ..()

/datum/nanite_program/regenerative/active_effect()
	if(iscarbon(host_mob))
		host_mob.adjustBruteLoss(-0.5, TRUE)
		host_mob.adjustFireLoss(-0.5, TRUE)
		return
	var/lavaland_bonus = (lavaland_equipment_pressure_check(get_turf(host_mob)) ? 1 : 0.6) // 0.5 on lavaland, 0.3 on station
	host_mob.heal_overall_damage(brute = (0.5 * lavaland_bonus), brute = (0.5 * lavaland_bonus), required_bodytype = BODYTYPE_ORGANIC)

/datum/nanite_program/regenerative_advanced
	name = "Bio-Reconstruction"
	desc = "The nanites manually repair and replace organic cells, acting much faster than normal regeneration. \
			However, this program cannot detect the difference between harmed and unharmed, causing it to consume nanites even if it has no effect. \
			Works better in low-pressure environments."
	use_rate = 5.5
	rogue_types = list(/datum/nanite_program/suffocating, /datum/nanite_program/necrotic)

/datum/nanite_program/regenerative_advanced/active_effect()
	if(iscarbon(host_mob))
		host_mob.adjustBruteLoss(-3, TRUE)
		host_mob.adjustFireLoss(-3, TRUE)
		return
	var/lavaland_bonus = (lavaland_equipment_pressure_check(get_turf(host_mob)) ? 1 : 0.8) // 1.5 on Lavaland, 1.2 on station
	host_mob.heal_overall_damage(brute = (1.5 * lavaland_bonus), brute = (1.5 * lavaland_bonus), required_bodytype = BODYTYPE_ORGANIC)

/datum/nanite_program/temperature
	name = "Temperature Adjustment"
	desc = "The nanites adjust the host's internal temperature to an ideal level. Does not consume nanites if the host has a nominal temperature."
	use_rate = 3.5
	rogue_types = list(/datum/nanite_program/skin_decay)

/datum/nanite_program/temperature/check_conditions()
	if(host_mob.bodytemperature > (host_mob.get_body_temp_normal(apply_change = FALSE) - 30) && host_mob.bodytemperature < (host_mob.get_body_temp_normal(apply_change = FALSE) + 30))
		return FALSE
	return ..()

/datum/nanite_program/temperature/active_effect()
	if(host_mob.bodytemperature > host_mob.get_body_temp_normal(apply_change=FALSE))
		host_mob.adjust_bodytemperature(-40 * TEMPERATURE_DAMAGE_COEFFICIENT, host_mob.get_body_temp_normal(apply_change=FALSE))
	else if(host_mob.bodytemperature < (host_mob.get_body_temp_normal(apply_change=FALSE) + 1))
		host_mob.adjust_bodytemperature(40 * TEMPERATURE_DAMAGE_COEFFICIENT, 0, host_mob.get_body_temp_normal(apply_change=FALSE))

/datum/nanite_program/purging
	name = "Blood Purification"
	desc = "The nanites purge toxins and chemicals from the host's bloodstream."
	use_rate = 1
	rogue_types = list(/datum/nanite_program/suffocating, /datum/nanite_program/necrotic)

/datum/nanite_program/purging/check_conditions()
	var/foreign_reagent = length(host_mob.reagents?.reagent_list)
	if(!host_mob.getToxLoss() && !foreign_reagent)
		return FALSE
	return ..()

/datum/nanite_program/purging/active_effect()
	host_mob.adjustToxLoss(-1)
	for(var/datum/reagent/reagents as anything in host_mob.reagents.reagent_list)
		host_mob.reagents.remove_reagent(reagents.type, amount = 1)

/datum/nanite_program/brain_heal
	name = "Neural Regeneration"
	desc = "The nanites fix neural connections in the host's brain, reversing brain damage and minor traumas."
	use_rate = 1.5
	rogue_types = list(/datum/nanite_program/brain_decay)

/datum/nanite_program/brain_heal/check_conditions()
	var/problems = FALSE
	if(iscarbon(host_mob))
		var/mob/living/carbon/carbon_host = host_mob
		if(length(carbon_host.get_traumas()))
			problems = TRUE
	if(host_mob.get_organ_loss(ORGAN_SLOT_BRAIN) > 0)
		problems = TRUE
	return problems ? ..() : FALSE

/datum/nanite_program/brain_heal/active_effect()
	host_mob.adjustOrganLoss(ORGAN_SLOT_BRAIN, -1)
	if(iscarbon(host_mob) && prob(10))
		var/mob/living/carbon/carbon_host = host_mob
		carbon_host.cure_trauma_type(resilience = TRAUMA_RESILIENCE_BASIC)

#define NANITE_BLOOD_RESTORE_DEFAULT 2

/datum/nanite_program/blood_restoring
	name = "Blood Regeneration"
	desc = "The nanites stimulate and boost blood cell production in the host."
	use_rate = 1
	rogue_types = list(/datum/nanite_program/suffocating)
	///The amount of blood that we restore every active effect tick.
	var/blood_restore_amount = NANITE_BLOOD_RESTORE_DEFAULT

/datum/nanite_program/blood_restoring/check_conditions()
	if(!iscarbon(host_mob))
		return FALSE
	var/mob/living/carbon/carbon_host = host_mob
	if(carbon_host.blood_volume >= BLOOD_VOLUME_SAFE)
		return FALSE
	return ..()

/datum/nanite_program/blood_restoring/active_effect()
	if(!iscarbon(host_mob))
		return
	var/mob/living/carbon/carbon_host = host_mob
	carbon_host.blood_volume += blood_restore_amount

#undef NANITE_BLOOD_RESTORE_DEFAULT

/datum/nanite_program/repairing
	name = "Mechanical Repair"
	desc = "The nanites fix damage in the host's mechanical limbs."
	use_rate = 0.5
	rogue_types = list(/datum/nanite_program/necrotic)

/datum/nanite_program/repairing/check_conditions()
	if(!host_mob.getBruteLoss() && !host_mob.getFireLoss())
		return FALSE

	if(!iscarbon(host_mob))
		if(!(host_mob.mob_biotypes & MOB_ROBOTIC))
			return FALSE
		return ..()

	var/mob/living/carbon/carbon_host = host_mob
	var/list/parts = carbon_host.get_damaged_bodyparts(brute = TRUE, burn = TRUE, required_bodytype = BODYTYPE_ROBOTIC)
	if(!parts.len)
		return FALSE
	return ..()

/datum/nanite_program/repairing/active_effect(mob/living/M)
	if(!iscarbon(host_mob))
		host_mob.adjustBruteLoss(-1.5, TRUE)
		host_mob.adjustFireLoss(-1.5, TRUE)
		return
	host_mob.heal_overall_damage(brute = 1.5, brute = 1.5, required_bodytype = BODYTYPE_ROBOTIC)

/datum/nanite_program/purging_advanced
	name = "Selective Blood Purification"
	desc = "The nanites purge toxins and dangerous chemicals from the host's bloodstream, while ignoring beneficial chemicals. \
			The added processing power required to analyze the chemicals severely increases the nanite consumption rate."
	use_rate = 2
	rogue_types = list(/datum/nanite_program/suffocating, /datum/nanite_program/necrotic)

/datum/nanite_program/purging_advanced/check_conditions()
	var/foreign_reagent = FALSE
	for(var/datum/reagent/toxin/toxic_reagents in host_mob.reagents.reagent_list)
		foreign_reagent = TRUE
		break
	if(!host_mob.getToxLoss() && !foreign_reagent)
		return FALSE
	return ..()

/datum/nanite_program/purging_advanced/active_effect()
	host_mob.adjustToxLoss(-1)
	for(var/datum/reagent/toxin/toxic_reagents in host_mob.reagents.reagent_list)
		host_mob.reagents.remove_reagent(toxic_reagents.type, 1)

/datum/nanite_program/brain_heal_advanced
	name = "Neural Reimaging"
	desc = "The nanites are able to backup and restore the host's neural connections, potentially replacing entire chunks of missing or damaged brain matter."
	use_rate = 3
	rogue_types = list(/datum/nanite_program/brain_decay, /datum/nanite_program/brain_misfire)

/datum/nanite_program/brain_heal_advanced/check_conditions()
	var/problems = FALSE
	if(iscarbon(host_mob))
		var/mob/living/carbon/carbon_host = host_mob
		if(length(carbon_host.get_traumas()))
			problems = TRUE
	if(host_mob.get_organ_loss(ORGAN_SLOT_BRAIN) > 0)
		problems = TRUE
	return problems ? ..() : FALSE

/datum/nanite_program/brain_heal_advanced/active_effect()
	host_mob.adjustOrganLoss(ORGAN_SLOT_BRAIN, -2)
	if(iscarbon(host_mob) && prob(10))
		var/mob/living/carbon/carbon_host = host_mob
		carbon_host.cure_trauma_type(resilience = TRAUMA_RESILIENCE_LOBOTOMY)

/datum/nanite_program/defib
	name = "Defibrillation"
	desc = "The nanites shock the host's heart when triggered, bringing them back to life if the body can sustain it."
	can_trigger = TRUE
	trigger_cost = 25
	trigger_cooldown = 120
	rogue_types = list(/datum/nanite_program/shocking)

/datum/nanite_program/defib/on_trigger(comm_message)
	host_mob.notify_revival("Your heart is being defibrillated by nanites. Re-enter your corpse if you want to be revived!")
	addtimer(CALLBACK(src, PROC_REF(start_defibrilation)), 5 SECONDS)

/datum/nanite_program/defib/proc/check_revivable()
	if(!iscarbon(host_mob))
		return FALSE
	var/mob/living/carbon/carbon_host = host_mob
	return carbon_host.can_defib()

/datum/nanite_program/defib/proc/start_defibrilation()
	playsound(host_mob, 'sound/machines/defib/defib_charge.ogg', 50, FALSE)
	addtimer(CALLBACK(src, PROC_REF(perform_defibrilation)), 3 SECONDS)

/datum/nanite_program/defib/proc/perform_defibrilation()
	var/mob/living/carbon/carbon_host = host_mob
	playsound(carbon_host, 'sound/machines/defib/defib_zap.ogg', 50, FALSE)
	if(!check_revivable())
		playsound(carbon_host, 'sound/machines/defib/defib_failed.ogg', 50, FALSE)
		return
	playsound(carbon_host, 'sound/machines/defib/defib_success.ogg', 50, FALSE)
	carbon_host.set_heartattack(FALSE)
	carbon_host.revive()
	carbon_host.emote("gasp")
	carbon_host.set_timed_status_effect(10 SECONDS, /datum/status_effect/jitter, only_if_higher = TRUE)
	SEND_SIGNAL(carbon_host, COMSIG_LIVING_MINOR_SHOCK)
	log_game("[carbon_host] has been successfully defibrillated by nanites.")


/datum/nanite_program/organrepair
	name = "Organ Repair"
	desc = "The nanites begin repairing the host's organs should they be damaged. Does not include brain damage."
	use_rate = 0.4
	rogue_types = list(/datum/nanite_program/necrotic)

/datum/nanite_program/organrepair/check_conditions()
	if(iscarbon(host_mob))
		return FALSE
	return ..()

/datum/nanite_program/organrepair/active_effect()
	if(prob(2))
		to_chat(host_mob, "<span class='warning'>You feel your innards twitch.")

	var/mob/living/carbon/C = host_mob
	//C.adjustOrganLoss(ORGAN_SLOT_BRAIN, -1)
	C.adjustOrganLoss(ORGAN_SLOT_HEART, -0.5)
	C.adjustOrganLoss(ORGAN_SLOT_LUNGS, -0.5)
	C.adjustOrganLoss(ORGAN_SLOT_LIVER, -0.5)
	C.adjustOrganLoss(ORGAN_SLOT_STOMACH, -0.5)
	C.adjustOrganLoss(ORGAN_SLOT_EYES, -0.5)
	C.adjustOrganLoss(ORGAN_SLOT_EARS, -0.5)
	..()
	. = TRUE


/datum/nanite_program/corpsepreserve
	name = "Corpse Preservation"
	desc = "The nanites will synthesize a small amount of formaldehyde upon the host's death."
	use_rate = 0
	rogue_types = list(/datum/nanite_program/necrotic)
	var/spent = FALSE

/datum/nanite_program/corpsepreserve/active_effect()
	if(host_mob.stat == DEAD)
		var/datum/reagent/S = host_mob.reagents?.has_reagent(/datum/reagent/toxin/formaldehyde)
		if(S)
			return
		if(!spent)
			spent = TRUE
			nanites.adjust_nanites(null, -10)
			host_mob.reagents.add_reagent(/datum/reagent/toxin/formaldehyde, 5)
			return
		return
	else
		spent = FALSE
		return


/datum/nanite_program/critstable
	name = "Critical Stabilization"
	desc = "The nanites will synthesize epinephrine when the host enters a critical state."
	use_rate = 0
	rogue_types = list(/datum/nanite_program/suffocating)
	var/spent = FALSE

/datum/nanite_program/critstable/active_effect()
	if(HAS_TRAIT(host_mob, TRAIT_CRITICAL_CONDITION))
		var/datum/reagent/S = host_mob.reagents?.has_reagent(/datum/reagent/medicine/epinephrine)
		if(S)
			return
		if(!spent)
			spent = TRUE
			nanites.adjust_nanites(null, -15)
			host_mob.reagents.add_reagent(/datum/reagent/medicine/epinephrine, 15)
			return
		return
	else
		spent = FALSE
		return


/datum/nanite_program/naniteresus
	name = "Nanite Resurrection"
	desc = "The nanites expend a large portion of themselves to create a strange reagent while the host is dead, which may result in their resurrection. \
			Cannot repair corpses, and requires them to be unhusked."
	use_rate = 0
	rogue_types = list(/datum/nanite_program/necrotic)
	var/hasnotified = FALSE
	var/hashealed = FALSE

/datum/nanite_program/naniteresus/active_effect()
	if(host_mob.stat == DEAD)
		if(ismegafauna(host_mob)) //they are never coming back
			activated = FALSE // Fuck you, stop checking for something every tick if it'll never change results. (Def of insanity)
			return
		if(iscarbon(host_mob) && (host_mob.getBruteLoss() + host_mob.getFireLoss() + host_mob.getToxLoss() >= 100 || HAS_TRAIT(host_mob, TRAIT_HUSK))) //body is too damaged to be revived
			return // We don't repair corpses, just revive them. (and make them not die afterward)
		else
			if(!hasnotified)
				host_mob.notify_revival("You're being resurrected by nanites! Re-enter your corpse at your earliest conveinence.")
				hasnotified = TRUE
			host_mob.do_jitter_animation(10)
			addtimer(CALLBACK(host_mob, TYPE_PROC_REF(/mob/living/carbon, do_jitter_animation), 10), 40) //jitter immediately, then again after 4 and 8 seconds
			addtimer(CALLBACK(host_mob, TYPE_PROC_REF(/mob/living/carbon, do_jitter_animation), 10), 80)
			sleep(10 SECONDS) //so the ghost has time to re-enter
			if(iscarbon(host_mob))
				var/mob/living/carbon/Carbon_mob = host_mob
				Carbon_mob.adjustOrganLoss(ORGAN_SLOT_BRAIN, -50)
				Carbon_mob.adjustOrganLoss(ORGAN_SLOT_HEART, -25)
				Carbon_mob.adjustOrganLoss(ORGAN_SLOT_LUNGS, -25)
				Carbon_mob.adjustOrganLoss(ORGAN_SLOT_LIVER, -25)
				Carbon_mob.adjustOrganLoss(ORGAN_SLOT_STOMACH, -25)
				Carbon_mob.adjustOrganLoss(ORGAN_SLOT_EYES, -25)
				Carbon_mob.adjustOrganLoss(ORGAN_SLOT_EARS, -25)
				if(!hashealed)
					Carbon_mob.adjustBruteLoss(-10)
					Carbon_mob.adjustFireLoss(-10)
					Carbon_mob.adjustOxyLoss(-101, 0)
					Carbon_mob.adjustToxLoss(-20, 0, TRUE)
					Carbon_mob.blood_volume += 10
					Carbon_mob.updatehealth()
					hashealed = TRUE
			else // just for basic mobs, might as well.
				host_mob.adjustBruteLoss(-10)
				host_mob.adjustFireLoss(-10)
			if(host_mob.revive())
				host_mob.emote("gasp")
				nanites.adjust_nanites(null, -35)
				log_combat(host_mob, host_mob, "revived", src)
				hasnotified = FALSE
				hashealed = FALSE


/datum/nanite_program/synthflesh
	name = "Corpse Repair"
	desc = "The nanites will slowly produce synthetic flesh over time, and use that to both patch the host's injuries and unhusk them. It only works on dead people."
	use_rate = 2
	rogue_types = list(/datum/nanite_program/necrotic)

/datum/nanite_program/synthflesh/check_conditions()
	if(!host_mob.getBruteLoss() && !host_mob.getFireLoss())
		return FALSE
	return ..()

/datum/nanite_program/synthflesh/active_effect(mob/living/M)
	var/can_heal = FALSE
	if(iscarbon(host_mob))
		//var/mob/living/carbon/C = host_mob
		if(host_mob.stat == DEAD)
			can_heal = TRUE
		if(can_heal)
			if(!ishuman(host_mob))
				host_mob.adjustBruteLoss(-1.25)
				host_mob.adjustFireLoss(-1.25)
			else
				host_mob.adjustBruteLoss(-2)
				host_mob.adjustFireLoss(-2)
				host_mob.adjustToxLoss(-0.1, 0, TRUE) // Think of it as a slight bonus.
				if(HAS_TRAIT_FROM(host_mob, TRAIT_HUSK, BURN) && (host_mob.getFireLoss() < 51) && host_mob.cure_husk(BURN)) //cure husk will return true if it cures the final husking source
					sleep(3 SECONDS)
	..()


/datum/nanite_program/mendingbrute
	name = "Brute Mending"
	desc = "The nanites quickly and efficiently repair blunt force, slashes, and punctures within the host. This program shuts itself off when no damage is available to be healed."
	use_rate = 2.5
	rogue_types = list(/datum/nanite_program/necrotic)
	var/healing = 1.25

/datum/nanite_program/mendingbrute/check_conditions()
	if(!host_mob.getBruteLoss())
		return FALSE
	if(iscarbon(host_mob))
		var/mob/living/carbon/host_carbon = host_mob
		var/list/parts = host_carbon.get_damaged_bodyparts(brute = TRUE, required_bodytype = BODYTYPE_ORGANIC)
		if(!parts.len)
			return FALSE
	return ..()

/datum/nanite_program/mendingbrute/active_effect()
	if(!iscarbon(host_mob))
		host_mob.adjustBruteLoss(-0.5, TRUE)
		return
	var/mob/living/carbon/carbon_mob = host_mob
	carbon_mob.heal_overall_damage(brute = healing, brute = healing, required_bodytype = BODYTYPE_ORGANIC)
	if(carbon_mob.getStaminaLoss() < 71)
		carbon_mob.adjustStaminaLoss(1)
		if(prob(5))
			to_chat(carbon_mob, "<span class='notice'>You suddenly feel your flesh re-adjust.")

/datum/nanite_program/mendingburn
	name = "Burn Mending"
	desc = "The nanites quickly and efficiently repair burns, frostbite, and electric scars within the host. This program shuts itself off when no damage is available to be healed."
	use_rate = 2.5
	rogue_types = list(/datum/nanite_program/pyro)
	var/healing = 1.25

/datum/nanite_program/mendingburn/check_conditions()
	if(!host_mob.getFireLoss())
		return FALSE
	if(iscarbon(host_mob))
		var/mob/living/carbon/host_carbon = host_mob
		var/list/parts = host_carbon.get_damaged_bodyparts(burn = TRUE, required_bodytype = BODYTYPE_ORGANIC)
		if(!parts.len)
			return FALSE
	return ..()

/datum/nanite_program/mendingburn/active_effect()
	if(!iscarbon(host_mob))
		host_mob.adjustFireLoss(-0.5, TRUE)
		return
	var/mob/living/carbon/carbon_mob = host_mob
	carbon_mob.heal_overall_damage(burn = healing, burn = healing, required_bodytype = BODYTYPE_ORGANIC)
	if(carbon_mob.getStaminaLoss() < 71)
		carbon_mob.adjustStaminaLoss(1)
		if(prob(5))
			to_chat(carbon_mob, "<span class='notice'>You suddenly feel your flesh re-adjust.")

/datum/nanite_program/mendingtoxin
	name = "Toxin Cleansing"
	desc = "The nanites run through the host's bloodstream and re-construct cells killed by toxins. This program shuts itself off when no damage is available to be healed."
	use_rate = 2.5
	rogue_types = list(/datum/nanite_program/toxic)
	var/healing = 1.25

/datum/nanite_program/mendingtoxin/check_conditions()
	if(!host_mob.getToxLoss())
		return FALSE
	return ..()

/datum/nanite_program/mendingtoxin/active_effect()
	if(iscarbon(host_mob))
		host_mob.adjustToxLoss(-healing, TRUE)
		if(prob(5))
			to_chat(host_mob, "<span class='notice'>For the briefest of moments, you feel your veins bulk up.")


/datum/nanite_program/selfresp
	name = "Self-Respiration"
	desc = "The nanites synthesize breathable air within the host's lungs and blood, negating the need to breathe."
	use_rate = 2.5
	rogue_types = list(/datum/nanite_program/suffocating)
	var/toggled = FALSE

/datum/nanite_program/selfresp/enable_passive_effect()
	var/mob/living/carbon/M = host_mob
	if(iscarbon(host_mob))
		if(toggled)
			M.adjustOxyLoss(-7, 0)
			M.losebreath = max(0, host_mob.losebreath - 4)
			ADD_TRAIT(M, TRAIT_NOBREATH, TRAIT_NANITES)
		else
			toggled = TRUE

/datum/nanite_program/selfresp/disable_passive_effect()
	var/mob/living/carbon/M = host_mob
	if(iscarbon(host_mob))
		if(toggled)
			toggled = FALSE
			REMOVE_TRAIT(M, TRAIT_NOBREATH, TRAIT_NANITES)


/datum/nanite_program/repairingplus
	name = "Synthetic Regeneration"
	desc = "The nanites repair damage within robotic organisms or limbs including both denting and melting. This program shuts itself off when no damage is available to be healed."
	use_rate = 1.5 //still more efficient than organic healing
	rogue_types = list(/datum/nanite_program/aggressive_replication)
	var/healing = 2

/datum/nanite_program/repairingplus/check_conditions()
	if(!host_mob.getBruteLoss() && !host_mob.getFireLoss())
		return FALSE

	if(!iscarbon(host_mob))
		if(!(host_mob.mob_biotypes & MOB_ROBOTIC))
			return FALSE
		return ..()

	var/mob/living/carbon/carbon_host = host_mob
	var/list/parts = carbon_host.get_damaged_bodyparts(brute = TRUE, burn = TRUE, required_bodytype = BODYTYPE_ROBOTIC)
	if(!parts.len)
		return FALSE
	return ..()

/datum/nanite_program/repairingplus/active_effect(mob/living/M)
	if(!iscarbon(host_mob))
		host_mob.adjustBruteLoss(-healing, TRUE)
		host_mob.adjustFireLoss(-healing, TRUE)
		return
	host_mob.heal_overall_damage(brute = healing, brute = healing, required_bodytype = BODYTYPE_ROBOTIC)
	host_mob.heal_overall_damage(burn = healing, burn = healing, required_bodytype = BODYTYPE_ROBOTIC)


/datum/nanite_program/woundfixer
	name = "Wound-Tending"
	desc = "The nanites slowly and methodically scan the host for major injuries and will slowly fix any wounds detected such as broken bones or hairline fractures -- without ever needing surgery."
	use_rate = 2
	rogue_types = list(/datum/nanite_program/flesh_eating)
	var/woundfixtimer = 0
	var/max_woundfixtimer = 120

/datum/nanite_program/woundfixer/active_effect()
	. = ..()
	woundfixtimer = min(woundfixtimer + 1, max_woundfixtimer)
	if(woundfixtimer >= max_woundfixtimer)
		var/mob/living/carbon/C = host_mob
		for(var/datum/wound/iter_wound as anything in C.all_wounds)
			iter_wound.remove_wound()
			woundfixtimer = 0
