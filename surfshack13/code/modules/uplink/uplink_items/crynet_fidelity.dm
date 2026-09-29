// Additional fidelity layer for the HippieStation CryNet nanosuit port.
// Keeps the modern MOD shell, but restores operator HUDs, explosion sensing and boot feedback.

/obj/item/mod/module/crynet_controller/faithful
	var/explosion_detection_dist = 21

/obj/item/mod/module/crynet_controller/faithful/on_equip()
	. = ..()
	if(!mod?.wearer)
		return
	playsound(get_turf(mod.wearer), 'surfshack13/sound/hippie/nanosuitengage.ogg', 100, FALSE)
	var/datum/atom_hud/medical_hud = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
	var/datum/atom_hud/security_hud = GLOB.huds[DATA_HUD_SECURITY_ADVANCED]
	var/datum/atom_hud/diagnostic_hud = GLOB.huds[DATA_HUD_DIAGNOSTIC]
	medical_hud?.show_to(mod.wearer)
	security_hud?.show_to(mod.wearer)
	diagnostic_hud?.show_to(mod.wearer)
	RegisterSignal(SSdcs, COMSIG_GLOB_EXPLOSION, PROC_REF(sense_explosion))

/obj/item/mod/module/crynet_controller/faithful/on_unequip()
	if(mod?.wearer)
		var/datum/atom_hud/medical_hud = GLOB.huds[DATA_HUD_MEDICAL_ADVANCED]
		var/datum/atom_hud/security_hud = GLOB.huds[DATA_HUD_SECURITY_ADVANCED]
		var/datum/atom_hud/diagnostic_hud = GLOB.huds[DATA_HUD_DIAGNOSTIC]
		medical_hud?.hide_from(mod.wearer)
		security_hud?.hide_from(mod.wearer)
		diagnostic_hud?.hide_from(mod.wearer)
	UnregisterSignal(SSdcs, COMSIG_GLOB_EXPLOSION)
	return ..()

/obj/item/mod/module/crynet_controller/faithful/on_part_activation()
	. = ..()
	if(!mod?.wearer)
		return
	INVOKE_ASYNC(src, PROC_REF(boot_feedback))

/obj/item/mod/module/crynet_controller/faithful/proc/boot_feedback()
	if(!mod?.wearer)
		return
	to_chat(mod.wearer, span_notice("CryNet - UEFI v1.32 Syndicate Systems"))
	sleep(1 SECONDS)
	if(!mod?.wearer)
		return
	to_chat(mod.wearer, span_notice("P.O.S.T. commencing..."))
	sleep(2 SECONDS)
	if(!mod?.wearer)
		return
	to_chat(mod.wearer, span_notice("Memory test: 6144MB OK. Onboard equipment test: OK."))
	sleep(1 SECONDS)
	if(!mod?.wearer)
		return
	to_chat(mod.wearer, span_notice("Life signs, atmospheric, power and radiation sensors: OK."))
	sleep(1 SECONDS)
	if(!mod?.wearer)
		return
	to_chat(mod.wearer, span_notice("Default configuration loaded. Have a safe and secure day."))

/obj/item/mod/module/crynet_controller/faithful/proc/sense_explosion(datum/source, turf/epicenter,
	devastation_range, heavy_impact_range, light_impact_range, took, orig_dev_range, orig_heavy_range, orig_light_range)
	SIGNAL_HANDLER
	if(!mod?.wearer || !epicenter)
		return
	var/turf/wearer_turf = get_turf(mod.wearer)
	if(!wearer_turf || wearer_turf.z != epicenter.z || get_dist(wearer_turf, epicenter) > explosion_detection_dist)
		return
	to_chat(mod.wearer, span_warning("CryNet: Explosion detected! Devastation [devastation_range], heavy impact [heavy_impact_range], light impact [light_impact_range]."))

/obj/item/mod/control/pre_equipped/crynet/faithful
	applied_modules = list(
		/obj/item/mod/module/crynet_controller/faithful,
		/obj/item/mod/module/crynet_mode/armor,
		/obj/item/mod/module/crynet_mode/cloak,
		/obj/item/mod/module/crynet_mode/speed,
		/obj/item/mod/module/crynet_mode/strength,
		/obj/item/mod/module/crynet_jump,
		/obj/item/mod/module/shock_absorber,
		/obj/item/mod/module/rad_protection,
		/obj/item/mod/module/jetpack,
		/obj/item/mod/module/visor/night/crynet,
	)
