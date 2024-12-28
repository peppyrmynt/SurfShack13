/datum/surgery/gender_reassignment
	name = "gender reassignment"
	possible_locs = list(BODY_ZONE_PRECISE_GROIN)
	steps = list(
	/datum/surgery_step/incise,
	/datum/surgery_step/clamp_bleeders,
	/datum/surgery_step/reshape_genitals,
	/datum/surgery_step/close
	)


//reshape_genitals
/datum/surgery_step/reshape_genitals
	name = "reshape genitals"
	implements = list(TOOL_SCALPEL = 100)
	time = 6.4 SECONDS

/datum/surgery_step/reshape_genitals/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	if(ishuman(target))
		var/mob/living/carbon/human/target_human = target
		if(target_human.physique == FEMALE)
			user.visible_message("[user] begins to reshape [target]'s genitals to look more masculine.", "<span class='notice'>You begin to reshape [target]'s genitals to look more masculine...</span>")
		else
			user.visible_message("[user] begins to reshape [target]'s genitals to look more feminine.", "<span class='notice'>You begin to reshape [target]'s genitals to look more feminine...</span>")

/datum/surgery_step/reshape_genitals/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/mob/living/carbon/human/H = target	//no type check, as that should be handled by the surgery
	if(ishuman(target))
		var/mob/living/carbon/human/target_human = target
		if(target_human.physique == FEMALE)
			user.visible_message("[user] has made a man of [target]!", "<span class='notice'>You made [target] a man.</span>")
			target_human.gender = MALE
			target_human.physique = MALE
			target_human.update_body_parts(TRUE)
		else
			user.visible_message("[user] has made a woman of [target]!", "<span class='notice'>You made [target] a woman.</span>")
			target_human.gender = FEMALE
			target_human.physique = FEMALE
			target_human.update_body_parts(TRUE)
	target.regenerate_icons()
	return TRUE

/datum/surgery_step/reshape_genitals/failure(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/mob/living/carbon/human/H = target
	user.visible_message("<span class='warning'>[user] accidentally mutilates [target]'s genitals beyond the point of recognition!</span>", "<span class='warning'>You accidentally mutilate [target]'s genitals beyond the point of recognition!</span>")
	target.gender = pick(MALE, FEMALE)
	target.regenerate_icons()
	return TRUE
