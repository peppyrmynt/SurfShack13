/datum/element/empprotection
	element_flags = ELEMENT_BESPOKE | ELEMENT_DETACH_ON_HOST_DESTROY // Detach for turfs
	argument_hash_start_idx = 2
	var/flags = NONE

/datum/element/empprotection/Attach(datum/target, _flags)
	. = ..()
	if(. == ELEMENT_INCOMPATIBLE || !isatom(target))
		return ELEMENT_INCOMPATIBLE
	flags = _flags
	RegisterSignal(target, COMSIG_ATOM_PRE_EMP_ACT, PROC_REF(getEmpFlags))
	if(isliving(target))
		ADD_TRAIT(target, TRAIT_EMPIMMUNE, "emp-protection")

/datum/element/empprotection/Detach(atom/target)
	UnregisterSignal(target, COMSIG_ATOM_PRE_EMP_ACT)
	if(isliving(target))
		REMOVE_TRAIT(target, TRAIT_EMPIMMUNE, "emp-protection")
	return ..()

/datum/element/empprotection/proc/getEmpFlags(datum/source, severity)
	SIGNAL_HANDLER

	return flags
