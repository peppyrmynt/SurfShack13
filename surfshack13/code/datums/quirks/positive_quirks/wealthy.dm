/datum/quirk/wealthy
	name = "Pay Raise"
	desc = "Due to your performance, you've earned a well-deserved pay raise. You'll earn 1.5x your normal paycheck."
	icon = FA_ICON_COINS
	value = 8
	medical_record_text = "This guy seriously makes more money than me!?! How?!?"

/datum/quirk/wealthy/add_unique(client/client_source)
	var/mob/living/carbon/human/human_holder = quirk_holder
	var/datum/bank_account/get_my_bank = human_holder.get_bank_account()

	if(!get_my_bank)
		return

	get_my_bank.payday_modifier *= 1.5
