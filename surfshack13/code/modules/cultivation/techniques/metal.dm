// Returning Iron Sutra: one soul-bound artifact that flies, returns, and can be carried into the sky.

/**
 * Marks an item as someone's bound artifact. The item stays a real object: it can be stolen,
 * locked in a closet, or confiscated, and the owner can't just yank it out of secure storage.
 */
/datum/component/cultivation_artifact
	/// Mind of the cultivator this is bound to
	var/datum/mind/owner_mind
	/// Is it currently flying under our control
	var/in_flight = FALSE
	/// Throwforce before we boosted it for a flight
	var/old_throwforce

/datum/component/cultivation_artifact/Initialize(datum/mind/owner_mind)
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	src.owner_mind = owner_mind

/datum/component/cultivation_artifact/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	var/obj/item/item = parent
	item.add_filter("cultivation_artifact", 2, list("type" = "outline", "color" = "#c0d8ff", "size" = 1, "alpha" = 120))

/datum/component/cultivation_artifact/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ATOM_EXAMINE)
	var/obj/item/item = parent
	item.remove_filter("cultivation_artifact")
	end_flight()

/datum/component/cultivation_artifact/Destroy(force)
	owner_mind = null
	return ..()

/datum/component/cultivation_artifact/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_notice("It hums faintly. [user.mind == owner_mind ? "It is bound to your soul." : "Someone's qi is bound into it."]")

/// Fly at a target, hit with a capped amount of force, then come home if possible
/datum/component/cultivation_artifact/proc/launch(atom/target, mob/living/launcher, range = 7)
	var/obj/item/item = parent
	if(in_flight)
		return FALSE
	if(ismob(item.loc))
		var/mob/holder = item.loc
		if(!holder.temporarilyRemoveItemFromInventory(item))
			return FALSE
		item.forceMove(get_turf(holder))
	in_flight = TRUE
	old_throwforce = item.throwforce
	// Controlled power budget: always hurts a bit, never more than a solid melee hit
	item.throwforce = clamp(max(item.force, item.throwforce) + 4, 8, 18)
	item.throw_at(target, range, 3, launcher, spin = TRUE, callback = CALLBACK(src, PROC_REF(flight_over), launcher))
	return TRUE

/datum/component/cultivation_artifact/proc/flight_over(mob/living/launcher)
	end_flight()
	addtimer(CALLBACK(src, PROC_REF(return_home), launcher), 0.5 SECONDS)

/datum/component/cultivation_artifact/proc/end_flight()
	if(!in_flight)
		return
	in_flight = FALSE
	var/obj/item/item = parent
	item.throwforce = old_throwforce

/// Fly back to the owner if it's lying in the open and they're close
/datum/component/cultivation_artifact/proc/return_home(mob/living/launcher)
	var/obj/item/item = parent
	if(QDELETED(item) || QDELETED(launcher) || launcher.mind != owner_mind)
		return
	if(!can_recall(launcher, feedback = FALSE))
		return
	item.throw_at(launcher, 8, 3, launcher, spin = TRUE, gentle = TRUE, callback = CALLBACK(src, PROC_REF(caught), launcher))

/datum/component/cultivation_artifact/proc/caught(mob/living/launcher)
	var/obj/item/item = parent
	if(get_dist(item, launcher) <= 1 && isturf(item.loc))
		launcher.put_in_hands(item)

/// Can the owner call this back right now? Containers, other people and walls all stop it.
/datum/component/cultivation_artifact/proc/can_recall(mob/living/caller, feedback = TRUE)
	var/obj/item/item = parent
	if(!isturf(item.loc))
		if(feedback)
			to_chat(caller, span_warning("You feel [item] tug against something holding it. It won't come."))
		return FALSE
	if(get_dist(item, caller) > 7 || item.z != caller.z)
		if(feedback)
			to_chat(caller, span_warning("[item] is too far away to answer your call."))
		return FALSE
	if(!can_see(caller, item, 7))
		if(feedback)
			to_chat(caller, span_warning("You can't see a clear path for [item] to fly to you."))
		return FALSE
	if(item.anchored)
		return FALSE
	return TRUE

// ----- Bind Artifact -----

/datum/action/cooldown/spell/cultivation/bind_artifact
	name = "Bind Artifact"
	desc = "With an item in hand, bind it to your soul (one at a time). With empty hands, call your artifact back from up to 7 tiles, \
		if nothing is holding it. Use while holding it to release the bond."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "summons"
	cooldown_time = 3 SECONDS
	qi_cost = 5
	/// The bound item
	var/datum/weakref/artifact_ref

/datum/action/cooldown/spell/cultivation/bind_artifact/proc/get_artifact()
	var/obj/item/artifact = artifact_ref?.resolve()
	if(QDELETED(artifact) || !artifact.GetComponent(/datum/component/cultivation_artifact))
		artifact_ref = null
		return null
	return artifact

/datum/action/cooldown/spell/cultivation/bind_artifact/proc/is_eligible(obj/item/item, mob/living/user)
	if(item.item_flags & (ABSTRACT|DROPDEL) || HAS_TRAIT(item, TRAIT_NODROP))
		to_chat(user, span_warning("[item] has no substance to bind your qi to."))
		return FALSE
	if(item.w_class > WEIGHT_CLASS_BULKY)
		to_chat(user, span_warning("[item] is far too large to fly."))
		return FALSE
	// No remote gunfire, syringes, grenades or bombs
	var/static/list/forbidden = typecacheof(list(
		/obj/item/gun,
		/obj/item/grenade,
		/obj/item/reagent_containers/syringe,
		/obj/item/reagent_containers/hypospray,
		/obj/item/transfer_valve,
		/obj/item/assembly,
		/obj/item/clothing,
		/obj/item/organ,
		/obj/item/bodypart,
	))
	if(is_type_in_typecache(item, forbidden))
		to_chat(user, span_warning("[item] resists your qi. Its nature is too unstable to bind."))
		return FALSE
	if(item.GetComponent(/datum/component/cultivation_artifact))
		to_chat(user, span_warning("[item] is already bound to someone's soul!"))
		return FALSE
	return TRUE

/datum/action/cooldown/spell/cultivation/bind_artifact/cast(mob/living/cast_on)
	. = ..()
	var/obj/item/artifact = get_artifact()
	var/obj/item/held = cast_on.get_active_held_item()
	if(artifact && held == artifact)
		qdel(artifact.GetComponent(/datum/component/cultivation_artifact))
		artifact_ref = null
		to_chat(cast_on, span_notice("You release your bond with [held]."))
		return
	if(held)
		if(artifact)
			to_chat(cast_on, span_warning("You are already bound to [artifact]. Release it first (use this while holding it)."))
			return
		if(!is_eligible(held, cast_on))
			return
		cast_on.visible_message(span_notice("[cast_on] breathes qi into [held], which begins to hum."), span_notice("You bind [held] to your soul."))
		held.AddComponent(/datum/component/cultivation_artifact, cast_on.mind)
		artifact_ref = WEAKREF(held)
		return
	if(!artifact)
		to_chat(cast_on, span_warning("You have no bound artifact. Hold something to bind it."))
		return
	var/datum/component/cultivation_artifact/bond = artifact.GetComponent(/datum/component/cultivation_artifact)
	if(!bond.can_recall(cast_on))
		return
	cast_on.visible_message(span_notice("[artifact] leaps up and flies to [cast_on]'s hand!"))
	artifact.throw_at(cast_on, 8, 3, cast_on, spin = TRUE, gentle = TRUE, callback = CALLBACK(bond, TYPE_PROC_REF(/datum/component/cultivation_artifact, caught), cast_on))

/// Finds the caster's bound artifact through their Bind Artifact technique
/proc/cultivation_get_artifact(mob/living/user)
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(user)
	for(var/datum/action/cooldown/spell/cultivation/bind_artifact/binder in cultivator?.techniques)
		return binder.get_artifact()
	return null

// ----- Flying Sword -----

/datum/action/cooldown/spell/pointed/cultivation/flying_sword
	name = "Flying Sword"
	desc = "Send your bound artifact flying at a target. It returns if nothing stops it. Works from your hand or from the floor nearby."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "bolt_action"
	cast_range = 7
	cooldown_time = 5 SECONDS
	qi_cost = 12
	aim_assist = TRUE

/datum/action/cooldown/spell/pointed/cultivation/flying_sword/is_valid_target(atom/cast_on)
	return TRUE

/datum/action/cooldown/spell/pointed/cultivation/flying_sword/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	var/obj/item/artifact = cultivation_get_artifact(owner)
	if(!artifact)
		to_chat(owner, span_warning("You have no bound artifact!"))
		return . | SPELL_CANCEL_CAST
	if(artifact.loc != owner)
		var/datum/component/cultivation_artifact/bond = artifact.GetComponent(/datum/component/cultivation_artifact)
		if(!bond.can_recall(owner))
			return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/pointed/cultivation/flying_sword/cast(atom/cast_on)
	. = ..()
	var/obj/item/artifact = cultivation_get_artifact(owner)
	var/datum/component/cultivation_artifact/bond = artifact.GetComponent(/datum/component/cultivation_artifact)
	owner.visible_message(span_danger("[owner] points, and [artifact] shoots through the air!"))
	bond.launch(cast_on, owner)

// ----- Sword Qi -----

/datum/action/cooldown/spell/pointed/cultivation/sword_qi
	name = "Sword Qi Slash"
	desc = "Swing your bound artifact and release a crescent of cutting qi. You must be holding the artifact."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "arcane_barrage"
	cast_range = 5
	cooldown_time = 8 SECONDS
	qi_cost = 20

/datum/action/cooldown/spell/pointed/cultivation/sword_qi/is_valid_target(atom/cast_on)
	return TRUE

/datum/action/cooldown/spell/pointed/cultivation/sword_qi/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	var/obj/item/artifact = cultivation_get_artifact(owner)
	if(!artifact || artifact.loc != owner)
		to_chat(owner, span_warning("You need your bound artifact in hand!"))
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/pointed/cultivation/sword_qi/cast(atom/cast_on)
	. = ..()
	var/mob/living/user = owner
	var/obj/projectile/cultivation_sword_qi/slash = new(get_turf(user))
	slash.aim_projectile(cast_on, user)
	slash.firer = user
	slash.fired_from = user
	playsound(user, 'sound/items/weapons/fwoosh.ogg', 50, TRUE)
	slash.fire()

/obj/projectile/cultivation_sword_qi
	name = "sword qi"
	icon = 'icons/obj/weapons/guns/projectiles.dmi'
	icon_state = "soulslash"
	damage = 15
	damage_type = BRUTE
	armour_penetration = 10
	sharpness = SHARP_EDGED
	range = 5
	hitsound = 'sound/items/weapons/bladeslice.ogg'

// ----- Sword Riding -----

/datum/action/cooldown/spell/cultivation/sword_riding
	name = "Sword Riding"
	desc = "Stand on your bound artifact and fly over chasms, lava and gaps for a few seconds. Drop it and you fall."
	button_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "flight"
	cooldown_time = 45 SECONDS
	qi_cost = 40

/datum/action/cooldown/spell/cultivation/sword_riding/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	var/obj/item/artifact = cultivation_get_artifact(owner)
	if(!artifact || artifact.loc != owner)
		to_chat(owner, span_warning("You need your bound artifact in hand!"))
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/cultivation/sword_riding/cast(mob/living/cast_on)
	. = ..()
	cast_on.apply_status_effect(/datum/status_effect/sword_riding, cultivation_get_artifact(cast_on))
