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
		host_human.physiology.bleed_mod *= 0.5

/datum/nanite_program/coagulating/disable_passive_effect()
	. = ..()
	if(ishuman(host_mob))
		var/mob/living/carbon/human/host_human = host_mob
		host_human.physiology.bleed_mod *= 2

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
	use_rate = 2.5
	rogue_types = list(/datum/nanite_program/toxic)

/datum/nanite_program/bodily_augment/enable_passive_effect()
	if(..())
		return
	host_mob.maxHealth += 25

/datum/nanite_program/bodily_augment/disable_passive_effect()
	if(..())
		return
	host_mob.maxHealth -= 25

/datum/nanite_program/metabolic_suppression
	name = "Metabolism Suppression"
	desc = "The nanites expend a small amount of themselves to synthesize nutrients for the host, slowing the hosts metabolism."
	use_rate = 2.5
	rogue_types = list(/datum/nanite_program/necrotic)

/datum/nanite_program/metabolic_suppression/check_conditions()
	if(!iscarbon(host_mob))
		return FALSE
	var/mob/living/carbon/C = host_mob
	if(C.nutrition <= NUTRITION_LEVEL_WELL_FED)
		return FALSE
	return ..()

/datum/nanite_program/metabolic_suppression/active_effect()
	host_mob.adjust_nutrition(0.2)

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

/datum/nanite_program/antibomb
	name = "Explosive Resistance"
	desc = "The nanites form a metallic netting within the host, preventing the host from being torn apart by explosives. Additionally increases the hosts resilience against explosives."
	use_rate = 1.5
	rogue_types = list(/datum/nanite_program/glitch)
	// The amount of armor we initially added, to then be retracted later.
	var/current_armor = 0

/datum/nanite_program/antibomb/enable_passive_effect()
	. = ..()
	host_mob.add_traits(list(TRAIT_BOMBGIBIMMUNE), TRAIT_NANITES)

	var/datum/armor/our_armor = host_mob.get_armor()
	var/list/armorlist = our_armor.get_rating_list()

	// Get your current armor. Usually you don't have armor as a mob, but we'll account for it.
	// Then, multiply your current armor by 0.25, to find our difference.
	// Basically, we're minimizing how much armor you get in total, but at the bare minimum, we'll give you 20 armor.
	// If this makes you 100% resistance to bombs, we do nothing.
	var/armor_bonus = CEILING((100 - armorlist[BOMB]) * 0.25, 20)
	if(armorlist[BOMB] + armor_bonus >= 100)
		armor_bonus = 0
	armorlist[BOMB] += armor_bonus
	current_armor = armor_bonus

	host_mob.set_armor(our_armor.generate_new_with_specific(armorlist))

/datum/nanite_program/antibomb/disable_passive_effect()
	. = ..()
	host_mob.remove_traits(list(TRAIT_BOMBGIBIMMUNE), TRAIT_NANITES)

	var/datum/armor/our_armor = host_mob.get_armor()
	var/list/armorlist = our_armor.get_rating_list()
	armorlist[BOMB] -= current_armor

	host_mob.set_armor(our_armor.generate_new_with_specific(armorlist))
