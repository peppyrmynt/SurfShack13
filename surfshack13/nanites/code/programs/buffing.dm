/datum/nanite_program/nervous
	name = "Nerve Support"
	desc = "The nanites act as a secondary nervous system, reducing the amount of time the host is stunned."
	use_rate = 1.5
	rogue_types = list(/datum/nanite_program/nerve_decay)

/datum/nanite_program/nervous/enable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/host_human = host_mob
		host_human.physiology.stun_mod *= 0.5

/datum/nanite_program/nervous/disable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/host_human = host_mob
		host_human.physiology.stun_mod *= 2

/datum/nanite_program/adrenaline
	name = "Adrenaline Burst"
	desc = "The nanites cause a burst of adrenaline when triggered, waking the host from stuns and temporarily increasing their speed."
	can_trigger = TRUE
	trigger_cost = 25
	trigger_cooldown = 1200
	rogue_types = list(/datum/nanite_program/toxic, /datum/nanite_program/nerve_decay)

/datum/nanite_program/adrenaline/on_trigger()
	to_chat(host_mob, span_notice("You feel a sudden surge of energy!"))
	host_mob.SetAllImmobility(0)
	host_mob.adjustStaminaLoss(-75)
	host_mob.set_resting(FALSE)
	host_mob.reagents.add_reagent(/datum/reagent/medicine/stimulants, 1.5)

/datum/nanite_program/hardening
	name = "Dermal Hardening"
	desc = "The nanites form a mesh under the host's skin, protecting them from melee and bullet impacts."
	use_rate = 1.0
	rogue_types = list(/datum/nanite_program/skin_decay)

/datum/armor/nanite_hardening
	melee = 25
	bullet = 20

//TODO on_hit effect that turns skin grey for a moment

/datum/nanite_program/hardening/enable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/user = host_mob
		user.physiology.armor = user.physiology.armor.add_other_armor(/datum/armor/nanite_hardening)

/datum/nanite_program/hardening/disable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/user = host_mob
		user.physiology.armor = user.physiology.armor.subtract_other_armor(/datum/armor/nanite_hardening)

/datum/nanite_program/refractive
	name = "Dermal Refractive Surface"
	desc = "The nanites form a membrane above the host's skin, reducing the effect of laser and energy impacts."
	use_rate = 1.0
	rogue_types = list(/datum/nanite_program/skin_decay)

/datum/armor/nanite_refractive
	laser = 25
	energy = 20

/datum/nanite_program/refractive/enable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/user = host_mob
		user.physiology.armor = user.physiology.armor.add_other_armor(/datum/armor/nanite_refractive)

/datum/nanite_program/refractive/disable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/user = host_mob
		user.physiology.armor = user.physiology.armor.subtract_other_armor(/datum/armor/nanite_refractive)

/datum/nanite_program/coagulating
	name = "Rapid Coagulation"
	desc = "The nanites induce rapid coagulation when the host is wounded, dramatically reducing bleeding rate."
	use_rate = 0.10
	rogue_types = list(/datum/nanite_program/suffocating)

/datum/nanite_program/coagulating/enable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/host_human = host_mob
		host_human.physiology.bleed_mod *= 0.1

/datum/nanite_program/coagulating/disable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/host_human = host_mob
		host_human.physiology.bleed_mod *= 10

/datum/nanite_program/conductive
	name = "Electric Conduction"
	desc = "The nanites act as a grounding rod for electric shocks, protecting the host. Shocks can still damage the nanites themselves."
	use_rate = 0.20
	program_flags = NANITE_SHOCK_IMMUNE
	rogue_types = list(/datum/nanite_program/nerve_decay)

/datum/nanite_program/conductive/enable_passive_effect()
	. = ..()
	ADD_TRAIT(host_mob, TRAIT_SHOCKIMMUNE, TRAIT_NANITES)

/datum/nanite_program/conductive/disable_passive_effect()
	. = ..()
	REMOVE_TRAIT(host_mob, TRAIT_SHOCKIMMUNE, TRAIT_NANITES)

/datum/nanite_program/mindshield
	name = "Mental Barrier"
	desc = "The nanites form a protective membrane around the host's brain, shielding them from abnormal influences while they're active."
	use_rate = 0.40
	rogue_types = list(/datum/nanite_program/brain_decay, /datum/nanite_program/brain_misfire)

/datum/nanite_program/mindshield/enable_passive_effect()
	. = ..()
	if(!host_mob.mind.has_antag_datum(/datum/antagonist/rev, TRUE)) //won't work if on a rev, to avoid having implanted revs.
		ADD_TRAIT(host_mob, TRAIT_MINDSHIELD, TRAIT_NANITES)
		host_mob.sec_hud_set_implants()

/datum/nanite_program/mindshield/disable_passive_effect()
	. = ..()
	REMOVE_TRAIT(host_mob, TRAIT_MINDSHIELD, TRAIT_NANITES)
	host_mob.sec_hud_set_implants()


/datum/nanite_program/bodily_augment
	name = "Bodily Augmentation"
	desc = "The nanites attach to cells in the body and reinforce them, allowing the host to sustain more damage than normal without falling into a critical state or dying outright."
	use_rate = 0.8
	rogue_types = list(/datum/nanite_program/regenerative)

/datum/nanite_program/bodily_augment/enable_passive_effect()
	if(..())
		return
	host_mob.maxHealth += 25

/datum/nanite_program/bodily_augment/disable_passive_effect()
	if(..())
		return
	host_mob.maxHealth -= 25

/datum/nanite_program/sticky_fingers
	name = "Nanite-Secured Fingers"
	desc = "The nanites form netting within the host's fingers that attaches easily to anything the host(s) may hold. Preventing disarms from would-be attackers."
	can_trigger = TRUE
	trigger_cost = 5
	trigger_cooldown = 20
	rogue_types = list(/datum/nanite_program/toxic)
	var/list/stored_items = list()
	var/stickyfingers = 0

/datum/nanite_program/sticky_fingers/on_trigger()
	if(..())
		return

	if(stickyfingers == 0)
		for(var/obj/item/I in host_mob.held_items)
			stored_items += I

		var/list/L = host_mob.get_empty_held_indexes()
		if(LAZYLEN(L) == host_mob.held_items.len)
			stored_items = list()

		for(var/obj/item/I in stored_items)
			to_chat(host_mob, span_notice("Your [host_mob.get_held_index_name(host_mob.get_held_index_of_item(I))]'s suddenly develop strangely sticky pads!"))
			ADD_TRAIT(I, TRAIT_NODROP, "anti-drop nanites")
			stickyfingers = 1

	if(stickyfingers == 1)
		for(var/obj/item/I in stored_items)
			REMOVE_TRAIT(I, TRAIT_NODROP, "anti-drop nanites")
			to_chat(host_mob, span_notice("You feel the nanites within your fingers retract and fade..."))
			stickyfingers = 0

/datum/nanite_program/sticky_fingers/disable_passive_effect()
	if(..())
		return

	for(var/obj/item/I in stored_items)
		REMOVE_TRAIT(I, TRAIT_NODROP, "anti-drop nanites")
		to_chat(host_mob, span_notice("You feel the nanites within your fingers retract and fade..."))
		stickyfingers = 0


/datum/nanite_program/metabolic_suppression
	name = "Metabolism Suppression"
	desc = "The nanites expend a small amount of themselves to synthesize nutrients for the host, slowing the hosts metabolism."
	use_rate = 0.2
	rogue_types = list(/datum/nanite_program/metabolic_synthesis)

/datum/nanite_program/metabolic_suppression/check_conditions()
	if(!iscarbon(host_mob))
		return FALSE
	var/mob/living/carbon/C = host_mob
	if(C.nutrition <= NUTRITION_LEVEL_WELL_FED)
		return FALSE
	return ..()

/datum/nanite_program/metabolic_suppression/active_effect()
	host_mob.adjust_nutrition(0.2)


/datum/nanite_program/extinguisher
	name = "Extinguishing Nanites"
	desc = "The nanites will detect if the host is on fire and will administer both water and other fire-retardent chemicals around the body to extinguish the host."
	use_rate = 0.5
	rogue_types = list(/datum/nanite_program/pyro)

/datum/nanite_program/extinguisher/check_conditions()
	if(!host_mob.on_fire)
		return FALSE
	return ..()

/datum/nanite_program/extinguisher/active_effect()
	//if(!host_mob.on_fire)
	//	return
	if(prob(4))
		to_chat(host_mob, "You feel the flames suddenly die down a bit.")
		host_mob.adjust_fire_stacks(-1)


/datum/nanite_program/painnull
	name = "Pain Nullification"
	desc = "The nanites shut down pain receptors in the body to allow for unhindered movement in the host."
	use_rate = 0.2
	rogue_types = list(/datum/nanite_program/nerve_decay)

/datum/nanite_program/painnull/enable_passive_effect()
	. = ..()
	host_mob.add_movespeed_mod_immunities(TRAIT_NANITES, /datum/movespeed_modifier/damage_slowdown)

/datum/nanite_program/painnull/disable_passive_effect()
	. = ..()
	host_mob.remove_movespeed_mod_immunities(TRAIT_NANITES, /datum/movespeed_modifier/damage_slowdown)


/datum/nanite_program/antidismember
	name = "Dismemberment Resistance"
	desc = "The nanites reinforce the skeletal-structure within the host, be it human or robot. This results in an immunity to dismemberment in the host."
	use_rate = 2
	rogue_types = list(/datum/nanite_program/flesh_eating)

/datum/nanite_program/antidismember/enable_passive_effect()
	. = ..()
	host_mob.add_traits(list(TRAIT_NODISMEMBER), TRAIT_NANITES)

/datum/nanite_program/antidismember/disable_passive_effect()
	. = ..()
	host_mob.remove_traits(list(TRAIT_NODISMEMBER), TRAIT_NANITES)


/datum/nanite_program/antibomb
	name = "Explosive Resistance"
	desc = "The nanites form a near-indestructable netting within the host, preventing the host from being harmed by explosives."
	use_rate = 3
	rogue_types = list(/datum/nanite_program/glitch)

/datum/nanite_program/antibomb/enable_passive_effect()
	. = ..()
	host_mob.add_traits(list(TRAIT_BOMBIMMUNE), TRAIT_NANITES)

/datum/nanite_program/antibomb/disable_passive_effect()
	. = ..()
	host_mob.remove_traits(list(TRAIT_BOMBIMMUNE), TRAIT_NANITES)


/datum/nanite_program/slipresist
	name = "Slip Resistance"
	desc = "The nanites build around the feet of the host, and attach themselves lightly to the floor to prevent some means of slipping."
	use_rate = 1.2
	rogue_types = list(/datum/nanite_program/glitch)

/datum/nanite_program/slipresist/enable_passive_effect()
	. = ..()
	host_mob.add_traits(list(TRAIT_NO_SLIP_WATER), TRAIT_NANITES)

/datum/nanite_program/slipresist/disable_passive_effect()
	. = ..()
	host_mob.remove_traits(list(TRAIT_NO_SLIP_WATER), TRAIT_NANITES)


/datum/nanite_program/magicshield
	name = "Magical Shielding"
	desc = "The nanites can detect strange, mystical energies and will expend themselves to protect the host."
	use_rate = 1
	rogue_types = list(/datum/nanite_program/glitch)

/datum/nanite_program/magicshield/enable_passive_effect()
	. = ..()
	host_mob.add_traits(list(TRAIT_ANTIMAGIC), TRAIT_NANITES)

/datum/nanite_program/magicshield/disable_passive_effect()
	. = ..()
	host_mob.remove_traits(list(TRAIT_ANTIMAGIC), TRAIT_NANITES)


/datum/nanite_program/hardiness
	name = "Hardy Procedure"
	desc = "The nanites reinforce muscles, bones, skin, plating, etc. Resulting in the host recieving fewer wounds overall from incoming attacks."
	use_rate = 1
	rogue_types = list(/datum/nanite_program/weakness)

/datum/nanite_program/hardiness/enable_passive_effect()
	. = ..()
	host_mob.add_traits(list(TRAIT_HARDLY_WOUNDED), TRAIT_NANITES)

/datum/nanite_program/hardiness/disable_passive_effect()
	. = ..()
	host_mob.remove_traits(list(TRAIT_HARDLY_WOUNDED), TRAIT_NANITES)


/datum/nanite_program/antikpa
	name = "Pressure Resistance"
	desc = "The nanites form a tight netting just beneath the host's skin, preventing the host from being stretched or compressed by air pressure."
	use_rate = 1.5
	rogue_types = list(/datum/nanite_program/glitch)

/datum/nanite_program/antikpa/enable_passive_effect()
	. = ..()
	host_mob.add_traits(list(TRAIT_RESISTHIGHPRESSURE), TRAIT_NANITES)
	host_mob.add_traits(list(TRAIT_RESISTLOWPRESSURE), TRAIT_NANITES)

/datum/nanite_program/antikpa/disable_passive_effect()
	. = ..()
	host_mob.remove_traits(list(TRAIT_RESISTHIGHPRESSURE), TRAIT_NANITES)
	host_mob.remove_traits(list(TRAIT_RESISTLOWPRESSURE), TRAIT_NANITES)


/datum/nanite_program/antirad
	name = "Radiation Resistance"
	desc = "The nanites apply sterilization tactics to the host to prevent harm via radiation."
	use_rate = 1
	rogue_types = list(/datum/nanite_program/pyro)

/datum/nanite_program/antirad/enable_passive_effect()
	. = ..()
	host_mob.add_traits(list(TRAIT_RADIMMUNE), TRAIT_NANITES)

/datum/nanite_program/antirad/disable_passive_effect()
	. = ..()
	host_mob.remove_traits(list(TRAIT_RADIMMUNE), TRAIT_NANITES)


/datum/nanite_program/antigrab
	name = "Grab Resistance"
	desc = "The nanites bulk the host's frame, preventing them from being grabbed aggressively."
	use_rate = 0.5
	rogue_types = list(/datum/nanite_program/flesh_eating)

/datum/nanite_program/antigrab/enable_passive_effect()
	. = ..()
	host_mob.add_traits(list(TRAIT_PUSHIMMUNE), TRAIT_NANITES)

/datum/nanite_program/antigrab/disable_passive_effect()
	. = ..()
	host_mob.remove_traits(list(TRAIT_PUSHIMMUNE), TRAIT_NANITES)


/datum/nanite_program/weatherendure
	name = "Harsh Weather Endurance"
	desc = "The nanites provide the host with the required bio-functionality to survive harsher weather such as ash storms and snow storms."
	use_rate = 0.2
	rogue_types = list(/datum/nanite_program/glitch)

/datum/nanite_program/weatherendure/enable_passive_effect()
	. = ..()
	host_mob.add_traits(list(TRAIT_SNOWSTORM_IMMUNE, TRAIT_ASHSTORM_IMMUNE), TRAIT_NANITES)

/datum/nanite_program/weatherendure/disable_passive_effect()
	. = ..()
	host_mob.remove_traits(list(TRAIT_SNOWSTORM_IMMUNE, TRAIT_ASHSTORM_IMMUNE), TRAIT_NANITES)


/datum/nanite_program/obsidian
	name = "Obsidian Skin"
	desc = "The nanites render the host's flesh or plating with thick insulation capable of enduring lava."
	use_rate = 0.8
	rogue_types = list(/datum/nanite_program/necrotic)

/datum/nanite_program/obsidian/enable_passive_effect()
	. = ..()
	host_mob.add_traits(list(TRAIT_LAVA_IMMUNE), TRAIT_NANITES)

/datum/nanite_program/obsidian/disable_passive_effect()
	. = ..()
	host_mob.remove_traits(list(TRAIT_LAVA_IMMUNE), TRAIT_NANITES)


/datum/nanite_program/plantlike
	name = "Plant Camouflage"
	desc = "The nanites feign the host's dna structure to foreign entities, causing most plant-life to mistake the host for an ally."
	use_rate = 0.5
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/plantlike/enable_passive_effect()
	. = ..()
	host_mob.faction |= "plants"
	host_mob.faction |= "vines"

/datum/nanite_program/plantlike/disable_passive_effect()
	. = ..()
	host_mob.faction -= "plants"
	host_mob.faction -= "vines"


/datum/nanite_program/limbtach
	name = "Limb Bio-tachment"
	desc = "The host's limbs are augmented by the nanites, resulting in the ability to easily remove limbs or re-attach limbs with ease."
	use_rate = 1.5
	rogue_types = list(/datum/nanite_program/flesh_eating)

/datum/nanite_program/limbtach/enable_passive_effect()
	. = ..()
	host_mob.add_traits(list(TRAIT_LIMBATTACHMENT), TRAIT_NANITES)

/datum/nanite_program/limbtach/disable_passive_effect()
	. = ..()
	host_mob.remove_traits(list(TRAIT_LIMBATTACHMENT), TRAIT_NANITES)
