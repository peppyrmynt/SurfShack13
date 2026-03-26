/datum/nanite_program/sensor
	name = NANITES_CATEGORY_SENSOR
	desc = "These nanites send a signal code when a certain condition is met."
	unique = FALSE
	var/can_rule = FALSE

/datum/nanite_program/sensor/register_extra_settings()
	extra_settings[NES_SENT_CODE] = new /datum/nanite_extra_setting/number(0, 1, 9999)

/datum/nanite_program/sensor/proc/check_event()
	return FALSE

/datum/nanite_program/sensor/proc/send_code()
	if(activated)
		var/datum/nanite_extra_setting/ES = extra_settings[NES_SENT_CODE]
		SEND_SIGNAL(host_mob, COMSIG_NANITE_SIGNAL, ES.value, "a [name] program")

/datum/nanite_program/sensor/active_effect()
	if(check_event())
		send_code()

/datum/nanite_program/sensor/proc/make_rule(datum/nanite_program/target)
	return

/datum/nanite_program/sensor/repeat
	name = "Signal Repeater"
	desc = "When triggered, sends another signal to the nanites, optionally with a delay."
	can_trigger = TRUE
	trigger_cost = 0
	trigger_cooldown = 10

/datum/nanite_program/sensor/repeat/register_extra_settings()
	. = ..()
	extra_settings[NES_DELAY] = new /datum/nanite_extra_setting/number(0, 0, 3600, "s")

/datum/nanite_program/sensor/repeat/on_trigger(comm_message)
	var/datum/nanite_extra_setting/ES = extra_settings[NES_DELAY]
	addtimer(CALLBACK(src, PROC_REF(send_code)), ES.get_value() * 10)

/datum/nanite_program/sensor/relay_repeat
	name = "Relay Signal Repeater"
	desc = "When triggered, sends another signal to a relay channel, optionally with a delay."
	can_trigger = TRUE
	trigger_cost = 0
	trigger_cooldown = 10

/datum/nanite_program/sensor/relay_repeat/register_extra_settings()
	. = ..()
	extra_settings[NES_RELAY_CHANNEL] = new /datum/nanite_extra_setting/number(1, 1, 9999)
	extra_settings[NES_DELAY] = new /datum/nanite_extra_setting/number(0, 0, 3600, "s")

/datum/nanite_program/sensor/relay_repeat/on_trigger(comm_message)
	var/datum/nanite_extra_setting/ES = extra_settings[NES_DELAY]
	addtimer(CALLBACK(src, PROC_REF(send_code)), ES.get_value() * 10)

/datum/nanite_program/sensor/relay_repeat/send_code()
	var/datum/nanite_extra_setting/relay = extra_settings[NES_RELAY_CHANNEL]
	if(activated && relay.get_value())
		for(var/datum/nanite_program/relay/relays as anything in SSnanites.nanite_relays)
			var/datum/nanite_extra_setting/code = extra_settings[NES_SENT_CODE]
			relays.relay_signal(code.get_value(), relay.get_value(), "a [name] program")

/datum/nanite_program/sensor/health
	name = "Health Sensor"
	desc = "The nanites receive a signal when the host's health is above/below a target percentage."
	can_rule = TRUE
	var/spent = FALSE

/datum/nanite_program/sensor/health/register_extra_settings()
	. = ..()
	extra_settings[NES_HEALTH_PERCENT] = new /datum/nanite_extra_setting/number(50, -100, 100, "%")
	extra_settings[NES_DIRECTION] = new /datum/nanite_extra_setting/boolean(TRUE, "Above", "Below")

/datum/nanite_program/sensor/health/check_event()
	var/health_percent = host_mob.health / host_mob.maxHealth * 100
	var/datum/nanite_extra_setting/percent = extra_settings[NES_HEALTH_PERCENT]
	var/datum/nanite_extra_setting/direction = extra_settings[NES_DIRECTION]
	var/detected = FALSE
	if(direction.get_value())
		if(health_percent >= percent.get_value())
			detected = TRUE
	else
		if(health_percent < percent.get_value())
			detected = TRUE

	if(detected)
		if(!spent)
			spent = TRUE
			return TRUE
		return FALSE
	else
		spent = FALSE
		return FALSE

/datum/nanite_program/sensor/health/make_rule(datum/nanite_program/target)
	var/datum/nanite_rule/health/rule = new(target)
	var/datum/nanite_extra_setting/direction = extra_settings[NES_DIRECTION]
	var/datum/nanite_extra_setting/percent = extra_settings[NES_HEALTH_PERCENT]
	rule.above = direction.get_value()
	rule.threshold = percent.get_value()
	return rule

/datum/nanite_program/sensor/crit
	name = "Critical Health Sensor"
	desc = "The nanites receive a signal when the host is in critical health."
	can_rule = TRUE

/datum/nanite_program/sensor/crit/check_event()
	if(HAS_TRAIT(host_mob, TRAIT_CRITICAL_CONDITION))
		return TRUE
	return FALSE

/datum/nanite_program/sensor/crit/make_rule(datum/nanite_program/target)
	var/datum/nanite_rule/crit/rule = new(target)
	return rule

/datum/nanite_program/sensor/death
	name = "Death Sensor"
	desc = "The nanites receive a signal when they detect the host is dead."
	can_rule = TRUE

/datum/nanite_program/sensor/death/check_event()
	if(host_mob.stat == DEAD)
		return TRUE
	return FALSE

/datum/nanite_program/sensor/death/on_death(gibbed)
	send_code()

/datum/nanite_program/sensor/death/make_rule(datum/nanite_program/target)
	var/datum/nanite_rule/death/rule = new(target)
	return rule

/datum/nanite_program/sensor/nanite_volume
	name = "Nanite Volume Sensor"
	desc = "The nanites receive a signal when the nanite supply is above/below a certain percentage."
	can_rule = TRUE
	var/spent = FALSE

/datum/nanite_program/sensor/nanite_volume/register_extra_settings()
	. = ..()
	extra_settings[NES_NANITE_PERCENT] = new /datum/nanite_extra_setting/number(50, -100, 100, "%")
	extra_settings[NES_DIRECTION] = new /datum/nanite_extra_setting/boolean(TRUE, "Above", "Below")

/datum/nanite_program/sensor/nanite_volume/check_event()
	var/nanite_percent = (nanites.nanite_volume - nanites.safety_threshold)/(nanites.max_nanites - nanites.safety_threshold)*100
	var/datum/nanite_extra_setting/percent = extra_settings[NES_NANITE_PERCENT]
	var/datum/nanite_extra_setting/direction = extra_settings[NES_DIRECTION]
	var/detected = FALSE
	if(direction.get_value())
		if(nanite_percent >= percent.get_value())
			detected = TRUE
	else
		if(nanite_percent < percent.get_value())
			detected = TRUE

	if(detected)
		if(!spent)
			spent = TRUE
			return TRUE
		return FALSE
	else
		spent = FALSE
		return FALSE

/datum/nanite_program/sensor/nanite_volume/make_rule(datum/nanite_program/target)
	var/datum/nanite_rule/nanites/rule = new(target)
	var/datum/nanite_extra_setting/direction = extra_settings[NES_DIRECTION]
	var/datum/nanite_extra_setting/percent = extra_settings[NES_NANITE_PERCENT]
	rule.above = direction.get_value()
	rule.threshold = percent.get_value()
	return rule

/datum/nanite_program/sensor/damage
	name = "Damage Sensor"
	desc = "The nanites receive a signal when a host's specific damage type is above/below a target value."
	can_rule = TRUE
	var/spent = FALSE

/datum/nanite_program/sensor/damage/register_extra_settings()
	. = ..()
	extra_settings[NES_DAMAGE_TYPE] = new /datum/nanite_extra_setting/type(BRUTE, list(BRUTE, BURN, TOX, OXY, STAMINA))
	extra_settings[NES_DAMAGE] = new /datum/nanite_extra_setting/number(0, 0, 500)
	extra_settings[NES_DIRECTION] = new /datum/nanite_extra_setting/boolean(TRUE, "Above", "Below")

/datum/nanite_program/sensor/damage/check_event()
	var/reached_threshold = FALSE
	var/datum/nanite_extra_setting/type = extra_settings[NES_DAMAGE_TYPE]
	var/datum/nanite_extra_setting/damage = extra_settings[NES_DAMAGE]
	var/datum/nanite_extra_setting/direction = extra_settings[NES_DIRECTION]
	var/check_above =  direction.get_value()
	var/damage_amt = 0
	switch(type.get_value())
		if(BRUTE)
			damage_amt = host_mob.getBruteLoss()
		if(BURN)
			damage_amt = host_mob.getFireLoss()
		if(TOX)
			damage_amt = host_mob.getToxLoss()
		if(OXY)
			damage_amt = host_mob.getOxyLoss()
		if(STAMINA)
			var/mob/living/carbon/human/tired_fella = host_mob
			damage_amt = tired_fella.getStaminaLoss()

	if(check_above)
		if(damage_amt >= damage.get_value())
			reached_threshold = TRUE
	else
		if(damage_amt < damage.get_value())
			reached_threshold = TRUE

	if(reached_threshold)
		if(!spent)
			spent = TRUE
			return TRUE
		return FALSE
	else
		spent = FALSE
		return FALSE

/datum/nanite_program/sensor/damage/make_rule(datum/nanite_program/target)
	var/datum/nanite_rule/damage/rule = new(target)
	var/datum/nanite_extra_setting/direction = extra_settings[NES_DIRECTION]
	var/datum/nanite_extra_setting/damage_type = extra_settings[NES_DAMAGE_TYPE]
	var/datum/nanite_extra_setting/damage = extra_settings[NES_DAMAGE]
	rule.above = direction.get_value()
	rule.threshold = damage.get_value()
	rule.damage_type = damage_type.get_value()
	return rule

/datum/nanite_program/sensor/voice
	name = "Voice Sensor"
	desc = "Sends a signal when the nanites hear a determined word or sentence."

/datum/nanite_program/sensor/voice/register_extra_settings()
	. = ..()
	extra_settings[NES_SENTENCE] = new /datum/nanite_extra_setting/text("")
	extra_settings[NES_INCLUSIVE_MODE] = new /datum/nanite_extra_setting/boolean(TRUE, "Inclusive", "Exclusive")

/datum/nanite_program/sensor/voice/on_mob_add()
	. = ..()
	RegisterSignal(host_mob, COMSIG_MOVABLE_HEAR, PROC_REF(on_hear))

/datum/nanite_program/sensor/voice/on_mob_remove()
	UnregisterSignal(host_mob, COMSIG_MOVABLE_HEAR)
	return ..()

/datum/nanite_program/sensor/voice/proc/on_hear(datum/source, list/hearing_args)
	var/datum/nanite_extra_setting/sentence = extra_settings[NES_SENTENCE]
	var/datum/nanite_extra_setting/inclusive = extra_settings[NES_INCLUSIVE_MODE]
	if(!sentence.get_value())
		return
	if(inclusive.get_value())
		if(findtext(hearing_args[HEARING_RAW_MESSAGE], sentence.get_value()))
			send_code()
	else
		if(lowertext(hearing_args[HEARING_RAW_MESSAGE]) == lowertext(sentence.get_value()))
			send_code()

/datum/nanite_program/sensor/species
	name = "Species Sensor"
	desc = "When triggered, the nanites scan the host to determine their species and output a signal depending on the conditions set in the settings."
	can_trigger = TRUE
	trigger_cost = 0
	trigger_cooldown = 5

	///List of all species we can add special sensors for.
	var/static/list/allowed_species = list(
		"Human" = /datum/species/human,
		"Lizard" = /datum/species/lizard,
		"Moth" = /datum/species/moth,
		"Ethereal" = /datum/species/ethereal,
		"Pod" = /datum/species/pod,
		"Fly" = /datum/species/fly,
		"Jelly" = /datum/species/jelly,
		"Monkey" = /datum/species/monkey,
	)

/datum/nanite_program/sensor/species/register_extra_settings()
	. = ..()
	var/list/species_types = list()
	for(var/name in allowed_species)
		species_types += name
	species_types += "Other"
	extra_settings[NES_RACE] = new /datum/nanite_extra_setting/type("Human", species_types)
	extra_settings[NES_MODE] = new /datum/nanite_extra_setting/boolean(TRUE, "Is", "Is Not")

/datum/nanite_program/sensor/species/on_trigger(comm_message)
	var/datum/nanite_extra_setting/species_type = extra_settings[NES_RACE]
	var/species = allowed_species[species_type.get_value()]
	var/species_match = FALSE

	if(species)
		if(is_species(host_mob, species))
			species_match = TRUE
	else	//this is the check for the "Other" option
		species_match = TRUE
		for(var/name in allowed_species)
			var/species_other = allowed_species[name]
			if(is_species(host_mob, species_other))
				species_match = FALSE
				break

	var/datum/nanite_extra_setting/mode = extra_settings[NES_MODE]
	if(mode.get_value())
		if(species_match)
			send_code()
	else
		if(!species_match)
			send_code()


/datum/nanite_program/sensor/alive
	name = "Vital Sensor"
	desc = "The nanites receive a signal constantly while the host is alive."
	can_rule = TRUE

/datum/nanite_program/sensor/alive/check_event()
	if(host_mob.stat != DEAD)
		return TRUE
	return FALSE

/datum/nanite_program/sensor/alive/make_rule(datum/nanite_program/target)
	var/datum/nanite_rule/alive/rule = new(target)
	return rule


/datum/nanite_program/sensor/job
	name = "Job Sensor"
	desc = "When triggered, the nanites scan the host's biodata and match it with Nanotrasen's private bio-records and output a signal depending on the conditions set in the settings."
	can_trigger = TRUE
	trigger_cost = 0
	trigger_cooldown = 5

	///List of all jobs we can add special sensors for.
	var/static/list/allowed_jobs = list(
		"Assistant" = "Assistant",
		"Atmos Tech" = "Atmospheric Technician",
		"Bartender" = "Bartender",
		"Botanist" = "Botanist",
		"Captain" = "Captain",
		"Cargo Tech" = "Cargo Technician",
		"Chemist" = "Chemist",
		"CE" = "Chief Engineer",
		"CMO" = "Chief Medical Officer",
		"Clown" = "Clown",
		"Cook" = "Cook",
		"Coroner" = "Coroner",
		"Curator" = "Curator",
		"Detective" = "Detective",
		"Geneticist" = "Geneticist",
		"HoP" = "Head of Personnel",
		"HoS" = "Head of Security",
		"Janitor" = "Janitor",
		"Lawyer" = "Lawyer",
		"Med Doctor" = "Medical Doctor",
		"Mime" = "Mime",
		"Paramedic" = "Paramedic",
		"Prisoner" = "Prisoner",
		"Psychologist" = "Psychologist",
		"QM" = "Quartermaster",
		"RD" = "Research Director",
		"Roboticist" = "Roboticist",
		"Scientist" = "Scientist",
		"Sec Officer" = "Security Officer",
		"Miner" = "Shaft Miner",
		"Engineer" = "Station Engineer",
		"Warden" = "Warden",
		"Chaplain" = "Chaplain",
		"Unknown" = "Unassigned Crewmember",
	)

/datum/nanite_program/sensor/job/register_extra_settings()
	. = ..()
	var/list/job_types = list()
	for(var/name in allowed_jobs)
		job_types += name
	extra_settings[NES_JOB] = new /datum/nanite_extra_setting/type("Assistant", job_types)
	extra_settings[NES_MODE] = new /datum/nanite_extra_setting/boolean(TRUE, "Is", "Is Not")

/datum/nanite_program/sensor/job/on_trigger(comm_message)
	var/datum/nanite_extra_setting/job_type = extra_settings[NES_JOB]
	var/host_job = allowed_jobs[job_type.get_value()]
	var/job_match = FALSE

	if(host_job)
		if(host_mob.mind?.assigned_role.title == host_job)
			job_match = TRUE
	else // Just in case the default option is null.
		job_match = FALSE

	var/datum/nanite_extra_setting/mode = extra_settings[NES_MODE]
	if(mode.get_value())
		if(job_match)
			send_code()
	else
		if(!job_match)
			send_code()


/datum/nanite_program/sensor/incapacitated
	name = "Incapacitated Sensor"
	desc = "The nanites receive a signal constantly while the host is incapacitated."
	can_rule = TRUE

/datum/nanite_program/sensor/incapacitated/check_event()
	if(host_mob.incapacitated)
		return TRUE
	return FALSE

/datum/nanite_program/sensor/incapacitated/make_rule(datum/nanite_program/target)
	var/datum/nanite_rule/incapacitated/rule = new(target)
	return rule


/datum/nanite_program/sensor/name
	name = "Name Sensor"
	desc = "Sends a signal when the nanites detect the host mob's identity to be that of the one specified."

/datum/nanite_program/sensor/name/register_extra_settings()
	. = ..()
	extra_settings[NES_NAME] = new /datum/nanite_extra_setting/text("")

/datum/nanite_program/sensor/name/check_event()
	var/datum/nanite_extra_setting/nanite_name_input = extra_settings[NES_NAME]
	var/datum/nanite_extra_setting/mode = extra_settings[NES_MODE]

	var/we_want_a_specific_name = mode.get_value()

	if(host_mob.name == nanite_name_input.get_value() && we_want_a_specific_name)
		return TRUE
	if(!(host_mob.name == nanite_name_input.get_value()) && !we_want_a_specific_name)
		return TRUE
	return FALSE


/datum/nanite_program/sensor/resting
	name = "Resting Sensor"
	desc = "The nanites receive a signal constantly while the host is resting/laying down."
	can_rule = TRUE

/datum/nanite_program/sensor/resting/check_event()
	if(host_mob.resting)
		return TRUE
	return FALSE

/datum/nanite_program/sensor/resting/make_rule(datum/nanite_program/target)
	var/datum/nanite_rule/resting/rule = new(target)
	return rule
