/obj/item/autosurgeon
	name = "autosurgeon"
	desc = "A device that automatically inserts an implant, skillchip or organ into the user without the hassle of extensive surgery. \
		It has a slot to insert implants or organs and a screwdriver slot for removing accidentally added items."
	icon = 'icons/obj/devices/tool.dmi'
	icon_state = "autosurgeon"
	inhand_icon_state = "nothing"
	w_class = WEIGHT_CLASS_SMALL

	/// How many times you can use the autosurgeon before it becomes useless
	var/uses = INFINITY
	/// What organ will the autosurgeon sub-type will start with. ie, CMO autosurgeon start with a medi-hud.
	var/starting_organ
	/// The organ currently loaded in the autosurgeon, ready to be implanted.
	var/obj/item/organ/stored_organ
	/// The list of organs and their children we allow into the autosurgeon. An empty list means no whitelist.
	var/list/organ_whitelist = list()
	/// The percentage modifier for how fast you can use the autosurgeon to implant other people.
	var/surgery_speed = 1
	/// The overlay that shows when the autosurgeon has an organ inside of it.
	var/loaded_overlay = "autosurgeon_loaded_overlay"
	//surfshack start
	/// Organs that cant be put in by players, but still hard coded into autosurgeons
	var/list/organ_blacklist = list(
		/obj/item/organ/brain,
		)
	/// amount of uses left before theres a risk of malfunction
	var/malfunction_threshold = 3

/obj/item/autosurgeon/emag_act(mob/user, obj/item/card/emag/emag_card)
	if(obj_flags & EMAGGED)
		return FALSE
	obj_flags |= EMAGGED
	visible_message(span_warning("\The [src] whirs gently!"))
	return TRUE

/obj/item/autosurgeon/Destroy(force)
	if(stored_organ)
		stored_organ.forceMove(get_turf(src))
	do_sparks(1)
	. = ..()

/obj/item/autosurgeon/examine_more(mob/user)
	. = ..()
	. += span_warning("Warrenty void after [malfunction_threshold] operations.")
//surfshack end

/obj/item/autosurgeon/attack_self_tk(mob/user)
	return //stops TK fuckery

/obj/item/autosurgeon/Initialize(mapload)
	. = ..()
	if(starting_organ)
		load_organ(new starting_organ(src))

/obj/item/autosurgeon/update_overlays()
	. = ..()
	if(stored_organ)
		. += loaded_overlay
		. += emissive_appearance(icon, loaded_overlay, src)

//surfshack start
/obj/item/autosurgeon/proc/malfunction(mob/living/carbon/human/H)
	if(!ishuman(H))
		return
	for(var/obj/item/bodypart/arm/ripped in H.bodyparts)
		//dismember 25% of the time, otherwise apply same damage as circular saw.
		to_chat(H, span_userdanger("\The [src] Malfunctions and starts to prod and carve your arm."))
		playsound(src, 'sound/items/weapons/chainsawhit.ogg', 60, vary = TRUE)
		if(prob(25))
			ripped.dismember()
		else
			ripped.receive_damage(brute = 30, sharpness = SHARP_EDGED)
		return
//surfshack end

/obj/item/autosurgeon/proc/load_organ(obj/item/organ/loaded_organ, mob/living/user)
	if(user)
		if(stored_organ)
			to_chat(user, span_alert("[src] already has an implant stored."))
			return

		if(uses <= 0)
			to_chat(user, span_alert("[src] is used up and cannot be loaded with more implants."))
			return
		//surfshack start
		if(organ_blacklist.Find(loaded_organ.type))
			to_chat(user, span_alert("[src] cant implant the [loaded_organ] and refuses it!"))
			return
		//surfshack end
		if(organ_whitelist.len)
			var/organ_whitelisted
			for(var/whitelisted_organ in organ_whitelist)
				if(istype(loaded_organ, whitelisted_organ))
					organ_whitelisted = TRUE
					break
			if(!organ_whitelisted)
				to_chat(user, span_alert("[src] is not compatible with [loaded_organ]."))
				return

		if(!user.transferItemToLoc(loaded_organ, src))
			to_chat(user, span_alert("[loaded_organ] is stuck to your hand!"))
			return

	stored_organ = loaded_organ
	loaded_organ.forceMove(src)

	name = "[initial(name)] ([stored_organ.name])" //to tell you the organ type, like "suspicious autosurgeon (Reviver implant)"
	update_appearance()

/obj/item/autosurgeon/proc/use_autosurgeon(mob/living/target, mob/living/user, implant_time)
	if(!stored_organ)
		to_chat(user, span_alert("[src] currently has no implant stored."))
		return

	if(uses <= 0)
		to_chat(user, span_alert("[src] has already been used. The tools are dull and won't reactivate."))
		return

	if(implant_time)
		user.visible_message(
			span_notice("[user] prepares to use [src] on [target]."),
			span_notice("You begin to prepare to use [src] on [target]."),
		)
		if(!do_after(user, (implant_time * surgery_speed), target))
			return
	if(target != user)
		log_combat(user, target, "autosurgeon implanted [stored_organ] into", "[src]", "in [AREACOORD(target)]")
		user.visible_message(span_notice("[user] presses a button on [src] as it plunges into [target]'s body."), span_notice("You press a button on [src] as it plunges into [target]'s body."))
	else
		user.visible_message(
			span_notice("[user] pressses a button on [src] as it plunges into [user.p_their()] body."),
			span_notice("You press a button on [src] as it plunges into your body."),
		)
	//surfshack start
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(obj_flags & EMAGGED)
			malfunction(H)
			obj_flags -= EMAGGED
			visible_message(span_warning("\The [src] stops whirring!"))
			return
		else if(H.auto_surgeon_uses >= malfunction_threshold && prob(40))
			malfunction(H)
			Destroy()
			return
		else
			H.auto_surgeon_uses ++
	//surfshack end
	stored_organ.Insert(target)//insert stored organ into the user
	stored_organ = null
	name = initial(name) //get rid of the organ in the name
	playsound(target.loc, 'sound/items/weapons/circsawhit.ogg', 50, vary = TRUE)
	update_appearance()
	uses--
	if(uses <= 0)
		desc = "[initial(desc)] Looks like it's been used up."

/obj/item/autosurgeon/attack_self(mob/user)//when the object it used...
	use_autosurgeon(user, user)

/obj/item/autosurgeon/attack(mob/living/target, mob/living/user, params)
	add_fingerprint(user)
	use_autosurgeon(target, user, 8 SECONDS)

/obj/item/autosurgeon/attackby(obj/item/attacking_item, mob/user, params)
	if(isorgan(attacking_item))
		load_organ(attacking_item, user)
	else
		return ..()



/obj/item/autosurgeon/screwdriver_act(mob/living/user, obj/item/screwtool)
	if(..())
		return TRUE
	if(!stored_organ)
		to_chat(user, span_warning("There's no implant in [src] for you to remove!"))
	else
		var/atom/drop_loc = user.drop_location()
		for(var/atom/movable/stored_implant as anything in src)
			stored_implant.forceMove(drop_loc)
			to_chat(user, span_notice("You remove the [stored_organ] from [src]."))
			stored_organ = null

		screwtool.play_tool_sound(src)
		uses--
		if(uses <= 0)
			desc = "[initial(desc)] Looks like it's been used up."
		update_appearance(UPDATE_ICON)
	return TRUE

/obj/item/autosurgeon/medical_hud
	name = "autosurgeon"
	desc = "A single use autosurgeon that contains a medical heads-up display augment. A screwdriver can be used to remove it, but implants can't be placed back in."
	uses = 1
	starting_organ = /obj/item/organ/cyberimp/eyes/hud/medical

/obj/item/autosurgeon/unlocked
	name = "autosurgeon"
	//surfshack start
	// uses = 1
	//surfshack end
	surgery_speed = 0.1

/obj/item/autosurgeon/syndicate
	name = "suspicious autosurgeon"
	icon_state = "autosurgeon_syndicate"
	surgery_speed = 0.75
	loaded_overlay = "autosurgeon_syndicate_loaded_overlay"

/obj/item/autosurgeon/syndicate/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_CONTRABAND, INNATE_TRAIT)

/obj/item/autosurgeon/syndicate/laser_arm
	desc = "A single use autosurgeon that contains a combat arms-up laser augment. A screwdriver can be used to remove it, but implants can't be placed back in."
	uses = 1
	starting_organ = /obj/item/organ/cyberimp/arm/gun/laser

/obj/item/autosurgeon/syndicate/thermal_eyes
	starting_organ = /obj/item/organ/eyes/robotic/thermals

/obj/item/autosurgeon/syndicate/thermal_eyes/single_use
	uses = 1

/obj/item/autosurgeon/syndicate/xray_eyes
	starting_organ = /obj/item/organ/eyes/robotic/xray

/obj/item/autosurgeon/syndicate/xray_eyes/single_use
	uses = 1

/obj/item/autosurgeon/syndicate/anti_stun
	starting_organ = /obj/item/organ/cyberimp/brain/anti_stun

/obj/item/autosurgeon/syndicate/anti_stun/single_use
	uses = 1

/obj/item/autosurgeon/syndicate/reviver
	starting_organ = /obj/item/organ/cyberimp/chest/reviver

/obj/item/autosurgeon/syndicate/reviver/single_use
	uses = 1

/obj/item/autosurgeon/syndicate/commsagent
	desc = "A device that automatically - painfully - inserts an implant. It seems someone's specially \
	modified this one to only insert... tongues. Horrifying."
	starting_organ = /obj/item/organ/tongue

/obj/item/autosurgeon/syndicate/commsagent/Initialize(mapload)
	. = ..()
	organ_whitelist += /obj/item/organ/tongue

/obj/item/autosurgeon/syndicate/emaggedsurgerytoolset
	starting_organ = /obj/item/organ/cyberimp/arm/surgery/emagged

/obj/item/autosurgeon/syndicate/emaggedsurgerytoolset/single_use
	uses = 1

/obj/item/autosurgeon/syndicate/contraband_sechud
	desc = "Contains a contraband SecHUD implant, undetectable by health scanners."
	uses = 1
	starting_organ = /obj/item/organ/cyberimp/eyes/hud/security/syndicate
