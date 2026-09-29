#include "crynet_nanosuit.inc"
#include "crynet_fidelity.inc"
#include "fusion_test_canisters.inc"

/datum/uplink_item/dangerous/execution_sword
	name = "Execution Sword"
	desc = "This modified energy sword has been specially designed to cleanly remove the head of a human\
			 in one well aimed swipe. It contains a hacked transmitter that will broadcast the\
			 details of your gruesome execution on the station announcement channel so everyone will know the\
			 name of the filthy pig you are about to slaughter. You may dedicate your executions to whomever you\
			 please by using the device in hand but you may only do so once. Be warned that you must remain still\
			 for a long time to execute a target so be sure to have them restrained and if you should be interrupted\
			 then news of your failure will be broadcast to the station."
	item = /obj/item/melee/execution_sword/antag
	cost = 1
	surplus = 30
	purchasable_from = ~UPLINK_INFILTRATORS

// HippieStation traitor gear ports, modernized to use existing SurfShack systems where possible.

/obj/item/chainsaw/energy
	name = "energy chainsaw"
	desc = "An incredibly deadly modified chainsaw using plasma-based energy cutters in place of an ordinary chain. Heavy, loud, and exceptionally destructive."
	force_on = 60
	armour_penetration = 15
	block_chance = 50

/datum/uplink_item/dangerous/energy_chainsaw
	name = "Energy Chainsaw"
	desc = "An incredibly deadly modified chainsaw with plasma-based energy cutters. It tears through matter with extreme efficiency, but remains heavy, large, and monstrously loud."
	item = /obj/item/chainsaw/energy
	cost = 14
	purchasable_from = UPLINK_TRAITORS

/obj/item/extra_arm
	name = "extra arm installer"
	desc = "A Syndicate surgical device that adapts the user's nervous system to support an additional arm."
	icon = 'icons/obj/devices/tool.dmi'
	icon_state = "autosurgeon"
	w_class = WEIGHT_CLASS_SMALL
	var/used = FALSE

/obj/item/extra_arm/attack_self(mob/living/carbon/user)
	if(used)
		balloon_alert(user, "already used!")
		return

	user.change_number_of_hands(length(user.held_items) + 1)
	used = TRUE
	desc += " It has already been used."
	user.visible_message(
		span_notice("[user] presses a button on [src], followed by a disgusting wet noise."),
		span_notice("You feel a sharp sting as [src] implants an additional arm into your body."),
	)
	to_chat(user, span_notice("You feel more dexterous."))
	playsound(user, 'sound/misc/splort.ogg', 50, vary = TRUE)

/datum/uplink_item/device_tools/additional_arm
	name = "Additional Arm"
	desc = "An additional arm prepared for rapid implantation with a Syndicate surgical installer."
	item = /obj/item/extra_arm
	cost = 4
	limited_stock = 2
	purchasable_from = UPLINK_TRAITORS

/datum/uplink_item/dangerous/high_frequency_blade
	name = "High Frequency Blade"
	desc = "An electric katana that weakens the molecular bonds of whatever it touches. Perfect for slicing apart obstacles and opponents."
	item = /obj/item/highfrequencyblade
	cost = 9
	purchasable_from = UPLINK_TRAITORS

// The normal MOD control powers itself off at exactly zero charge. CryNet instead falls back to
// Maximum Armor and recharges after its delay, so retain a negligible reserve while active.
/obj/item/mod/control/pre_equipped/crynet/process(seconds_per_tick)
	if(active && get_charge() <= 0)
		add_charge(0.01)
	return ..()

/datum/uplink_item/dangerous/crynet_nanosuit
	name = "CryNet Nanosuit"
	desc = "A banned CryNet adaptive combat nanosuit with mutually exclusive Armor, Cloak, Speed, and Strength modes. Once worn it locks to the operator and broadcasts its activation on the station. Its systems include self-recharging power, emergency medical nanites, defrosting, night vision, threat HUDs, explosion sensing, a jetpack, and an emag-overclockable combat controller."
	item = /obj/item/mod/control/pre_equipped/crynet/faithful
	cost = 20
	surplus = 0
	purchasable_from = UPLINK_TRAITORS
