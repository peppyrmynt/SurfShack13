/**
 * # Grenade Compartment Component
 *
 * Contains a single grenade within the component, which can then be primed via signals.
 * Requires a BCI shell.
 */

/obj/item/circuit_component/grenade_storage
	display_name = "Grenade Primer"
	desc = "A component that can store chemical grenades and prime them for detonation through BCI signals."
	category = "BCI"

	required_shells = list(/obj/item/organ/cyberimp/bci)

	var/datum/port/input/prime
	var/datum/port/output/primed

	var/obj/item/organ/cyberimp/bci/bci

/obj/item/circuit_component/grenade_storage/Initialize(mapload)
	. = ..()
	create_storage(storage_type = /datum/storage/bci_gs)

/obj/item/circuit_component/grenade_storage/populate_ports()
	. = ..()
	prime = add_input_port("Prime", PORT_TYPE_SIGNAL, trigger = PROC_REF(trigger_grenade))
	primed = add_output_port("Primed", PORT_TYPE_SIGNAL)

/obj/item/circuit_component/grenade_storage/proc/trigger_grenade()
	CIRCUIT_TRIGGER
	if(!bci.owner)
		return
	var/our_activator = bci.owner
	for(var/obj/item/grenade/stored_grenade in src.get_all_contents())
		if(!stored_grenade)
			return
		stored_grenade.arm_grenade(our_activator, msg = FALSE)
		primed.set_output(COMPONENT_SIGNAL)

/obj/item/circuit_component/grenade_storage/register_shell(atom/movable/shell)
	. = ..()
	if(istype(shell, /obj/item/organ/cyberimp/bci))
		bci = shell

/obj/item/circuit_component/grenade_storage/unregister_shell(atom/movable/shell)
	. = ..()
	bci = null
