/obj/item/organ/heart/sheep
	name = "sheep heart"
	desc = "An heart that's seen it's fair share of work. Likely extracted from a sheep."
	icon_state = "heart-on"
	base_icon_state = "heart"
	maxHealth = STANDARD_ORGAN_THRESHOLD * 0.5 // Something to help counteract the bonus, frequent brushes with death will seal your fate. Also shorter time before your heart decays while dead.
	var/damage_heart_toggle = TRUE
	/// The cooldown until the next time this heart cam speed you up.
	COOLDOWN_DECLARE(sheep_boost_cooldown)

/obj/item/organ/heart/sheep/on_life(seconds_per_tick, times_fired)
	. = ..()
	if(owner.health < 5 && COOLDOWN_FINISHED(src, sheep_boost_cooldown) && !(organ_flags & ORGAN_FAILING))
		COOLDOWN_START(src, sheep_boost_cooldown, rand(25 SECONDS, 1 MINUTES))
		to_chat(owner, span_userdanger("You feel yourself dying, but something primal kicks in to keep you moving!"))
		owner.heal_overall_damage(brute = 15, burn = 15, required_bodytype = BODYTYPE_ORGANIC)
		if(damage_heart_toggle)
			var/mob/living/carbon/my_human = owner
			my_human.adjustOrganLoss(ORGAN_SLOT_HEART, 20)
		if(owner.reagents.get_reagent_amount(/datum/reagent/determination) < 10)
			owner.reagents.add_reagent(/datum/reagent/determination, 10)

/obj/item/organ/heart/sheep/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/organ_set_bonus, /datum/status_effect/organ_set_bonus/sheep)

/obj/item/organ/liver/sheep
	name = "sheep liver"
	desc = "A sheep's liver. Rumored to provide healing for those weak of heart."
	icon_state = "liver"

/obj/item/organ/liver/sheep/handle_chemical(mob/living/carbon/organ_owner, datum/reagent/chem, seconds_per_tick, times_fired)
	. = ..()
	//parent returned COMSIG_MOB_STOP_REAGENT_CHECK or we are failing
	if((. & COMSIG_MOB_STOP_REAGENT_CHECK) || (organ_flags & ORGAN_FAILING))
		return
	if(istype(chem, /datum/reagent/consumable/nutriment))
		owner.heal_overall_damage(brute = 0.1, burn = 0.1, required_bodytype = BODYTYPE_ORGANIC)

/obj/item/organ/liver/sheep/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/organ_set_bonus, /datum/status_effect/organ_set_bonus/sheep)

///bonus of the sheep: your woolly flesh insulates you from the cold!
/datum/status_effect/organ_set_bonus/sheep
	id = "organ_set_bonus_sheep"
	organs_needed = 2
	bonus_activate_text = span_notice("Sheep DNA is deeply infused with you! You've become resistant to extremely cold temperatures!")
	bonus_deactivate_text = span_notice("Your DNA is no longer majority sheep, and you're no longer resistant to extremely cold temperatures...")
	bonus_traits = list(TRAIT_RESISTCOLD)
