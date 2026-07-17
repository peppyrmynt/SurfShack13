/datum/nanite_rule
	var/name = "Generic Condition"
	var/desc = "When triggered, the program is active"
	var/datum/nanite_program/program

/datum/nanite_rule/New(datum/nanite_program/new_program)
	program = new_program
	if(LAZYLEN(new_program.rules) <= 5) //Avoid infinite stacking rules
		new_program.rules += src
	else
		qdel(src)

/datum/nanite_rule/proc/remove()
	program.rules -= src
	program = null
	qdel(src)

/datum/nanite_rule/proc/check_rule()
	return TRUE

/datum/nanite_rule/proc/display()
	return name

/datum/nanite_rule/proc/copy_to(datum/nanite_program/new_program)
	new type(new_program)

/datum/nanite_rule/health
	name = "Health"
	desc = "Checks the host's health status."

	var/threshold = 50
	var/above = TRUE

/datum/nanite_rule/health/check_rule()
	var/health_percent = program.host_mob.health / program.host_mob.maxHealth * 100
	if(above)
		if(health_percent >= threshold)
			return TRUE
	else
		if(health_percent < threshold)
			return TRUE
	return FALSE

/datum/nanite_rule/health/display()
	return "[name] [above ? ">" : "<"] [threshold]%"

/datum/nanite_rule/health/copy_to(datum/nanite_program/new_program)
	var/datum/nanite_rule/health/rule = new(new_program)
	rule.above = above
	rule.threshold = threshold

//TODO allow inversion
/datum/nanite_rule/crit
	name = "Crit"
	desc = "Checks if the host is in critical condition."

/datum/nanite_rule/crit/check_rule()
	return HAS_TRAIT(program.host_mob, TRAIT_CRITICAL_CONDITION)


/datum/nanite_rule/death
	name = "Death"
	desc = "Checks if the host is dead."

/datum/nanite_rule/death/check_rule()
	if(program.host_mob.stat == DEAD || HAS_TRAIT(program.host_mob, TRAIT_FAKEDEATH))
		return TRUE
	return FALSE

/datum/nanite_rule/nanites
	name = "Nanite Volume"
	desc = "Checks the host's nanite volume."

	var/threshold = 50
	var/above = TRUE

/datum/nanite_rule/nanites/check_rule()
	var/nanite_percent = (program.nanites.nanite_volume - program.nanites.safety_threshold)/(program.nanites.max_nanites - program.nanites.safety_threshold)*100
	if(above)
		if(nanite_percent >= threshold)
			return TRUE
	else
		if(nanite_percent < threshold)
			return TRUE
	return FALSE

/datum/nanite_rule/nanites/copy_to(datum/nanite_program/new_program)
	var/datum/nanite_rule/nanites/rule = new(new_program)
	rule.above = above
	rule.threshold = threshold

/datum/nanite_rule/nanites/display()
	return "[name] [above ? ">" : "<"] [threshold]%"

/datum/nanite_rule/damage
	name = "Damage"
	desc = "Checks the host's damage."

	var/threshold = 50
	var/above = TRUE
	var/damage_type = BRUTE

/datum/nanite_rule/damage/check_rule()
	var/damage_amt = 0
	switch(damage_type)
		if(BRUTE)
			damage_amt = program.host_mob.getBruteLoss()
		if(BURN)
			damage_amt = program.host_mob.getFireLoss()
		if(TOX)
			damage_amt = program.host_mob.getToxLoss()
		if(OXY)
			damage_amt = program.host_mob.getOxyLoss()
		if(STAMINA)
			var/mob/living/carbon/human/tired_fella = program.host_mob
			damage_amt = tired_fella.getStaminaLoss()

	if(above)
		if(damage_amt >= threshold)
			return TRUE
	else
		if(damage_amt < threshold)
			return TRUE
	return FALSE

/datum/nanite_rule/damage/copy_to(datum/nanite_program/new_program)
	var/datum/nanite_rule/damage/rule = new(new_program)
	rule.above = above
	rule.threshold = threshold
	rule.damage_type = damage_type

/datum/nanite_rule/damage/display()
	return "[damage_type] [above ? ">" : "<"] [threshold]"


/datum/nanite_rule/alive
	name = "Alive"
	desc = "Checks if the host is alive."

/datum/nanite_rule/alive/check_rule()
	if(program.host_mob.stat != DEAD && !HAS_TRAIT(program.host_mob, TRAIT_FAKEDEATH))
		return TRUE
	return FALSE


/datum/nanite_rule/incapacitated
	name = "Incapacitated"
	desc = "Checks if the host is incapacitated."

/datum/nanite_rule/incapacitated/check_rule()
	if(program.host_mob.incapacitated)
		return TRUE
	return FALSE


/datum/nanite_rule/resting
	name = "Resting"
	desc = "Checks if the host is resting."

/datum/nanite_rule/resting/check_rule()
	if(program.host_mob.resting)
		return TRUE
	return FALSE

/datum/nanite_rule/fire
	name = "On Fire"
	desc = "Checks if the host is or isn't on fire."

/datum/nanite_rule/fire/check_rule()
	if(program.host_mob.on_fire)
		return TRUE
	return FALSE

/datum/nanite_rule/fire/display()
	return "[name]"

/datum/nanite_rule/blood
	name = "Blood Volume"
	desc = "Checks if the host has more or less blood than is specified."
	var/threshold = 560
	var/above = TRUE

/datum/nanite_rule/blood/check_rule()
	if(above)
		if(program.host_mob.get_blood_volume() >= threshold)
			return TRUE
	else
		if(program.host_mob.get_blood_volume() < threshold)
			return TRUE
	return FALSE

/datum/nanite_rule/blood/copy_to(datum/nanite_program/new_program)
	var/datum/nanite_rule/blood/rule = new(new_program)
	rule.above = above
	rule.threshold = threshold

/datum/nanite_rule/blood/display()
	return "[name] [above ? ">" : "<"] [threshold]"

/datum/nanite_rule/nutrition
	name = "Nutrition"
	desc = "Checks if the host has more or less nutrition than is specified."
	var/threshold = 400
	var/above = TRUE

/datum/nanite_rule/nutrition/check_rule()
	if(above)
		if(program.host_mob.nutrition >= threshold)
			return TRUE
	else
		if(program.host_mob.nutrition < threshold)
			return TRUE
	return FALSE

/datum/nanite_rule/nutrition/copy_to(datum/nanite_program/new_program)
	var/datum/nanite_rule/nutrition/rule = new(new_program)
	rule.above = above
	rule.threshold = threshold

/datum/nanite_rule/nutrition/display()
	return "[name] [above ? ">" : "<"] [threshold]"

/datum/nanite_rule/soul_check
	name = "Catatonic"
	desc = "Checks if the host is a soulless being or not."
	var/is_soulless = TRUE

/datum/nanite_rule/soul_check/check_rule()
	if(is_soulless)
		if(isnull(program.host_mob.key))
			return TRUE
	else
		if(!isnull(program.host_mob.key))
			return TRUE
	return FALSE

/datum/nanite_rule/soul_check/copy_to(datum/nanite_program/new_program)
	var/datum/nanite_rule/soul_check/rule = new(new_program)
	rule.is_soulless = is_soulless

/datum/nanite_rule/soul_check/display()
	return "[is_soulless ? "Is" : "Is Not"] [name]"

/datum/nanite_rule/temperature
	name = "Temperature Sensor"
	desc = "Checks if the host has a higher or lower temperature than is specified. 310.15 is the normal body temperature for a human."
	var/threshold = 310
	var/above = TRUE

/datum/nanite_rule/temperature/check_rule()
	if(above)
		if(program.host_mob.bodytemperature >= threshold)
			return TRUE
	else
		if(program.host_mob.bodytemperature < threshold)
			return TRUE
	return FALSE

/datum/nanite_rule/temperature/copy_to(datum/nanite_program/new_program)
	var/datum/nanite_rule/temperature/rule = new(new_program)
	rule.above = above
	rule.threshold = threshold

/datum/nanite_rule/temperature/display()
	return "[name]  [above ? ">" : "<"] [threshold]"
