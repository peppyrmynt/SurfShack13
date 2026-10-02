/**
 * # Dantian
 *
 * The physical half of cultivation. Knowledge lives on the mind (the cultivator datum),
 * but you can only wield as much of it as your body's dantian can hold.
 * A transplanted dantian does nothing for a mortal, and a cultivator in a fresh body has to rebuild one.
 */
/obj/item/organ/dantian
	name = "dantian"
	desc = "A small, faintly warm knot of tissue that hums when held. Cultivators store their qi here."
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'
	icon_state = "dantian"
	zone = BODY_ZONE_CHEST
	slot = ORGAN_SLOT_DANTIAN
	organ_flags = ORGAN_ORGANIC
	decay_factor = 0
	/// Which realm this dantian has been refined to
	var/grade = REALM_QI_CONDENSATION
	/// Cracked cores halve max qi until mended through meditation
	var/cracked = FALSE
	/// Meditations left to mend the crack
	var/mend_sessions = 0
	/// Real name of the first cultivator who formed this, so a stolen core carries an owner signature
	var/original_owner

/obj/item/organ/dantian/on_mob_insert(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	if(!original_owner)
		original_owner = organ_owner.real_name

/obj/item/organ/dantian/proc/set_grade(new_grade)
	grade = new_grade
	if(grade >= REALM_GOLDEN_CORE)
		name = "golden core"
		desc = "A marble-sized sphere of solid gold light, warm as a living heart. It would be worth a fortune to the wrong sort of cultivator."
		icon_state = "golden_core"
	else
		name = initial(name)
		desc = initial(desc)
		icon_state = initial(icon_state)
	update_appearance()

/obj/item/organ/dantian/proc/crack()
	cracked = TRUE
	mend_sessions = 3
	name = "cracked [name]"

/obj/item/organ/dantian/proc/mend_step()
	if(!cracked)
		return FALSE
	mend_sessions--
	if(mend_sessions <= 0)
		cracked = FALSE
		set_grade(grade)
		return TRUE
	return FALSE

/obj/item/organ/dantian/examine(mob/user)
	. = ..()
	if(IS_CULTIVATOR(user) || isobserver(user))
		. += span_notice("It has been refined to the [grade >= REALM_GOLDEN_CORE ? "Golden Core" : "Foundation"] level.[cracked ? " It is cracked." : ""]")
		if(original_owner)
			. += span_notice("The qi within still carries the signature of <b>[original_owner]</b>.")
