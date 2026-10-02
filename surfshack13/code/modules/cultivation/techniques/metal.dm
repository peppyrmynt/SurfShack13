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
	/// Wound bonus before the flight
	var/old_wound_bonus
	/// Realm of whoever launched it
	var/launch_realm = REALM_MORTAL
	/// Refinement grade, see refinement_grades. Raised by meditating with it and tempering it in an alchemy cauldron.
	var/refinement = 0
	/// Progress towards the next grade
	var/refine_points = 0
	/// Names for each refinement grade
	var/static/list/refinement_grades = list("Mortal", "Spirit", "Earth", "Heaven", "Immortal", "Dao")
	/// Outline colour per grade
	var/static/list/refinement_colors = list("#c0d8ff", "#9fe3ff", "#c9a26b", "#ffd55a", "#ffffff", "#e9b5ff")

/datum/component/cultivation_artifact/Initialize(datum/mind/owner_mind)
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	src.owner_mind = owner_mind

/datum/component/cultivation_artifact/RegisterWithParent()
	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	update_refinement_glow()

/datum/component/cultivation_artifact/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_ATOM_EXAMINE, COMSIG_MOVABLE_PRE_IMPACT))
	var/obj/item/item = parent
	item.remove_filter("cultivation_artifact")
	end_flight()

/datum/component/cultivation_artifact/Destroy(force)
	owner_mind = null
	return ..()

/datum/component/cultivation_artifact/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_notice("It hums faintly. [user.mind == owner_mind ? "It is bound to your soul." : "Someone's qi is bound into it."]")
	examine_list += span_notice("It is a <b>[refinement_grade_name()]-grade</b> artifact.[refinement < MAX_ARTIFACT_REFINEMENT ? " ([refine_points]/[points_for_next_grade()] towards the next grade)" : ""]")


/datum/component/cultivation_artifact/proc/refinement_grade_name()
	return refinement_grades[refinement + 1]

/datum/component/cultivation_artifact/proc/points_for_next_grade()
	return 5 + 5 * refinement

/datum/component/cultivation_artifact/proc/update_refinement_glow()
	var/obj/item/item = parent
	item.remove_filter("cultivation_artifact")
	item.add_filter("cultivation_artifact", 2, list("type" = "outline", "color" = refinement_colors[refinement + 1], "size" = 1, "alpha" = 120 + 25 * refinement))

/// Feed the artifact refinement. Returns TRUE if it rose a grade.
/datum/component/cultivation_artifact/proc/add_refinement(points, mob/living/refiner)
	if(refinement >= MAX_ARTIFACT_REFINEMENT)
		return FALSE
	refine_points += points
	var/ranked_up = FALSE
	while(refinement < MAX_ARTIFACT_REFINEMENT && refine_points >= points_for_next_grade())
		refine_points -= points_for_next_grade()
		refinement++
		ranked_up = TRUE
	if(refinement >= MAX_ARTIFACT_REFINEMENT)
		refine_points = 0
	if(!ranked_up)
		return FALSE
	var/obj/item/item = parent
	update_refinement_glow()
	var/turf/here = get_turf(item)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold(here)
	new /obj/effect/temp_visual/cultivation_spark(here, refinement_colors[refinement + 1])
	cultivation_guqin_phrase(item, list(3, 5, 6), 0.12 SECONDS, 35)
	item.visible_message(span_boldnotice("[item] rings like a struck bell. It has been refined to a [refinement_grade_name()]-grade artifact!"))
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(refiner)
	cultivator?.notify_laws(INSIGHT_SOURCE_REFINING, item)
	return TRUE


/// Fly at a target, hit with a capped amount of force, then come home if possible
/datum/component/cultivation_artifact/proc/launch(atom/target, mob/living/launcher, range = 7)
	var/obj/item/item = parent
	if(in_flight)
		return FALSE
	if(ismob(item.loc))
		var/mob/holder = item.loc
		if(!holder.temporarilyRemoveItemFromInventory(item, force = TRUE))
			return FALSE
		item.forceMove(get_turf(holder))
	in_flight = TRUE
	old_throwforce = item.throwforce
	// Controlled power budget: always hurts a bit, never more than a solid melee hit
	var/realm = cultivation_realm_of(launcher)
	item.throwforce = clamp(max(item.force, item.throwforce) + 8 + refinement, 12, 20 + 4 * realm + 2 * refinement)
	old_wound_bonus = item.wound_bonus
	item.wound_bonus = max(item.wound_bonus, 15)
	launch_realm = realm
	RegisterSignal(item, COMSIG_MOVABLE_MOVED, PROC_REF(flight_trail), override = TRUE)
	RegisterSignal(item, COMSIG_MOVABLE_IMPACT, PROC_REF(flight_impact), override = TRUE)
	item.throw_at(target, range, 3, launcher, spin = TRUE, callback = CALLBACK(src, PROC_REF(flight_over), launcher))
	return TRUE

/datum/component/cultivation_artifact/proc/flight_trail(atom/movable/source)
	SIGNAL_HANDLER
	cultivation_afterimage(source, 0.3 SECONDS)

/// Blades cut limbs off, everything else knocks people flat
/datum/component/cultivation_artifact/proc/flight_impact(obj/item/source, atom/hit_atom, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER
	if(!in_flight || !isliving(hit_atom))
		return
	var/mob/living/victim = hit_atom
	new /obj/effect/temp_visual/impact_effect/cultivation_sword_qi(get_turf(victim), 0, 0)
	victim.Shake(2, 2, 0.3 SECONDS)
	if(source.sharpness)
		victim.apply_damage(5 + 2 * launch_realm, BRUTE, sharpness = source.sharpness)
		cultivation_sever_limb(victim, 8 + 4 * launch_realm + 2 * refinement, launch_realm)
	else
		victim.Knockdown(1 SECONDS)

/datum/component/cultivation_artifact/proc/flight_over(mob/living/launcher)
	end_flight()
	addtimer(CALLBACK(src, PROC_REF(return_home), launcher), 0.5 SECONDS)

/datum/component/cultivation_artifact/proc/end_flight()
	if(!in_flight)
		return
	in_flight = FALSE
	var/obj/item/item = parent
	item.throwforce = old_throwforce
	item.wound_bonus = old_wound_bonus
	UnregisterSignal(item, list(COMSIG_MOVABLE_MOVED, COMSIG_MOVABLE_IMPACT))

/// Fly back to the owner if it's lying in the open and they're close
/datum/component/cultivation_artifact/proc/return_home(mob/living/launcher)
	var/obj/item/item = parent
	if(QDELETED(item) || QDELETED(launcher) || launcher.mind != owner_mind)
		return
	if(!can_recall(launcher, feedback = FALSE))
		return
	fly_home(launcher)

/// Fly back to the owner's hand. It never hits its own master.
/datum/component/cultivation_artifact/proc/fly_home(mob/living/master)
	var/obj/item/item = parent
	RegisterSignal(item, COMSIG_MOVABLE_PRE_IMPACT, PROC_REF(on_return_impact), override = TRUE)
	RegisterSignal(item, COMSIG_MOVABLE_MOVED, PROC_REF(flight_trail), override = TRUE)
	item.throw_at(master, 8, 3, master, spin = TRUE, gentle = TRUE, callback = CALLBACK(src, PROC_REF(caught), master))

/datum/component/cultivation_artifact/proc/on_return_impact(obj/item/source, atom/hit_atom, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER
	if(!isliving(hit_atom))
		return NONE
	var/mob/living/catcher = hit_atom
	if(catcher.mind != owner_mind)
		return NONE
	UnregisterSignal(source, list(COMSIG_MOVABLE_PRE_IMPACT, COMSIG_MOVABLE_MOVED))
	INVOKE_ASYNC(src, PROC_REF(snap_into_hand), catcher, source)
	return COMPONENT_MOVABLE_IMPACT_NEVERMIND

/// Putting an item in hands can sleep (stack merging), so the catch happens outside the impact signal
/datum/component/cultivation_artifact/proc/snap_into_hand(mob/living/catcher, obj/item/source)
	if(QDELETED(catcher) || QDELETED(source))
		return
	if(!catcher.put_in_hands(source))
		source.forceMove(catcher.drop_location())
	catcher.visible_message(span_notice("[source] slaps neatly into [catcher]'s hand."))

/datum/component/cultivation_artifact/proc/caught(mob/living/master)
	var/obj/item/item = parent
	UnregisterSignal(item, list(COMSIG_MOVABLE_PRE_IMPACT, COMSIG_MOVABLE_MOVED))
	if(QDELETED(master) || !isturf(item.loc) || get_dist(item, master) > 1)
		return
	if(!master.put_in_hands(item))
		item.forceMove(master.drop_location())

/// How far the artifact hears its master
/datum/component/cultivation_artifact/proc/recall_range(mob/living/caller)
	return 7 + 3 * cultivation_realm_of(caller) + refinement

/// Is someone holding our artifact weaker than us? Lower realm (mortals always are), or from a smaller sect.
/datum/component/cultivation_artifact/proc/holder_is_weaker(mob/living/caller, mob/living/holder)
	if(cultivation_realm_of(holder) < cultivation_realm_of(caller))
		return TRUE
	var/datum/jianghu_sect/caller_sect = jianghu_sect_of(caller.mind)
	var/datum/jianghu_sect/holder_sect = jianghu_sect_of(holder.mind)
	if(caller_sect && caller_sect != holder_sect && length(caller_sect.members) > length(holder_sect?.members))
		return TRUE
	return FALSE

/// Can the owner call this back right now? Containers and stronger holders stop it.
/datum/component/cultivation_artifact/proc/can_recall(mob/living/caller, feedback = TRUE)
	var/obj/item/item = parent
	if(item.anchored)
		return FALSE
	if(item.z != caller.z || get_dist(item, caller) > recall_range(caller))
		if(feedback)
			to_chat(caller, span_warning("[item] is too far away to answer your call. (range [recall_range(caller)])"))
		return FALSE
	if(isliving(item.loc))
		var/mob/living/holder = item.loc
		if(holder == caller)
			return FALSE
		if(!holder_is_weaker(caller, holder))
			if(feedback)
				to_chat(caller, span_warning("[holder] grips [item] with qi as strong as your own. It won't come."))
				to_chat(holder, span_warning("[item] tugs in your hand, but you hold on."))
			return FALSE
		return TRUE
	if(!isturf(item.loc))
		if(feedback)
			to_chat(caller, span_warning("You feel [item] tug against something holding it shut. It won't come."))
		return FALSE
	// Out of sight: only a Golden Core can fold space to bring it home
	if(!can_see(caller, item, recall_range(caller)) && cultivation_realm_of(caller) < REALM_GOLDEN_CORE)
		if(feedback)
			to_chat(caller, span_warning("You can't see a clear path for [item] to fly to you. (Golden Core cultivators can call it through walls)"))
		return FALSE
	return TRUE

/// Pull the artifact out of a weaker holder's hand or through walls, then bring it home
/datum/component/cultivation_artifact/proc/recall(mob/living/caller)
	var/obj/item/item = parent
	if(isliving(item.loc))
		var/mob/living/holder = item.loc
		holder.visible_message(span_danger("[item] tears itself out of [holder]'s grip!"), span_userdanger("[item] rips out of your hand, answering its true master!"))
		holder.dropItemToGround(item, force = TRUE)
		playsound(holder, 'sound/items/weapons/thudswoosh.ogg', 50, TRUE)
	if(!can_see(caller, item, recall_range(caller)))
		// Fold space
		new /obj/effect/temp_visual/cultivation_void_rift(get_turf(item))
		new /obj/effect/temp_visual/cultivation_void_rift(get_turf(caller))
		playsound(caller, 'sound/effects/magic/blink.ogg', 40, TRUE)
		item.forceMove(caller.drop_location())
		caller.put_in_hands(item)
		caller.visible_message(span_notice("[item] emerges from a rip in space into [caller]'s hand."))
		return
	caller.visible_message(span_notice("[item] leaps up and flies to [caller]'s hand!"))
	fly_home(caller)

// ----- Bind Artifact -----

/datum/action/cooldown/spell/cultivation/bind_artifact
	name = "Bind Artifact"
	desc = "With an item in hand, bind it to your soul (one at a time). With empty hands, call your artifact back from 7 tiles plus 3 per realm. \
		It rips itself out of the hands of anyone weaker than you (a lower realm, or a smaller sect than yours), and from Golden Core it comes through walls. \
		Closed containers still hold it. Use while holding it to release the bond."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "summons"
	cooldown_time = 1 SECONDS
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
		new /obj/effect/temp_visual/circle_wave/cultivation(get_turf(cast_on))
		held.AddComponent(/datum/component/cultivation_artifact, cast_on.mind)
		artifact_ref = WEAKREF(held)
		return
	if(!artifact)
		to_chat(cast_on, span_warning("You have no bound artifact. Hold something to bind it."))
		return
	var/datum/component/cultivation_artifact/bond = artifact.GetComponent(/datum/component/cultivation_artifact)
	if(!bond.can_recall(cast_on))
		return
	bond.recall(cast_on)

/// Finds the caster's bound artifact through their Bind Artifact technique
/proc/cultivation_get_artifact(mob/living/user)
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(user)
	for(var/datum/action/cooldown/spell/cultivation/bind_artifact/binder in cultivator?.techniques)
		return binder.get_artifact()
	return null

// ----- Flying Sword -----

/datum/action/cooldown/spell/pointed/cultivation/flying_sword
	name = "Flying Sword"
	desc = "Send your bound artifact flying at a target. Blades bite deep and can sever limbs; blunt artifacts knock people down. \
		It returns if nothing stops it. Works from your hand or from the floor nearby."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "bolt_action"
	cast_range = 7
	cooldown_time = 2.5 SECONDS
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
	desc = "Swing your bound artifact and release a crescent of cutting qi that tears deep wounds and can sever limbs (more often at higher realms). \
		You must be holding the artifact."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "arcane_barrage"
	cast_range = 10
	cooldown_time = 4 SECONDS
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
	var/realm = cultivation_realm_of(user)
	slash.damage = 22 + 4 * realm
	slash.caster_realm = realm
	slash.aim_projectile(cast_on, user)
	slash.firer = user
	slash.fired_from = user
	playsound(user, 'sound/items/weapons/fwoosh.ogg', 50, TRUE)
	playsound(user, 'sound/items/unsheath.ogg', 40, TRUE)
	var/turf/swing_turf = get_step(user, get_dir(user, cast_on))
	user.do_attack_animation(swing_turf, ATTACK_EFFECT_SLASH)
	new /obj/effect/temp_visual/circle_wave/cultivation(get_turf(user))
	if(swing_turf)
		new /obj/effect/temp_visual/slash(swing_turf, null, 0, 0, "#d8f0ff")
	slash.fire()

/obj/projectile/cultivation_sword_qi
	name = "sword qi"
	icon = 'surfshack13/icons/cultivation/cultivation_effects.dmi'
	icon_state = "sword_qi"
	damage = 22
	damage_type = BRUTE
	armour_penetration = 25
	sharpness = SHARP_EDGED
	wound_bonus = 20
	bare_wound_bonus = 30
	range = 12
	speed = 2.5
	hitsound = 'sound/items/weapons/bladeslice.ogg'
	impact_effect_type = /obj/effect/temp_visual/impact_effect/cultivation_sword_qi
	light_system = OVERLAY_LIGHT
	light_range = 2
	light_power = 1
	light_color = "#a8d8ff"
	/// Realm of whoever fired it, for severing chance
	var/caster_realm = REALM_FOUNDATION

/// A fading afterimage behind the crescent as it flies
/obj/projectile/cultivation_sword_qi/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	if(isturf(old_loc))
		var/obj/effect/temp_visual/decoy/fading/trail = new(old_loc, src)
		trail.alpha = 140
		animate(trail, alpha = 0, time = 0.25 SECONDS)
		QDEL_IN(trail, 0.25 SECONDS)

/obj/projectile/cultivation_sword_qi/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	new /obj/effect/temp_visual/impact_effect/cultivation_sword_qi(get_turf(target), 0, 0)
	if(isliving(target))
		var/mob/living/victim = target
		victim.Shake(2, 2, 0.3 SECONDS)
		if(!blocked)
			cultivation_sever_limb(victim, 10 + 5 * caster_realm, caster_realm)
		new /obj/effect/temp_visual/slash(get_turf(victim), victim, rand(10, 22), rand(10, 22), "#d8f0ff")

/obj/effect/temp_visual/impact_effect/cultivation_sword_qi
	icon = 'surfshack13/icons/cultivation/cultivation_effects.dmi'
	icon_state = "sword_qi_impact"
	duration = 0.5 SECONDS

// ----- Sword Riding -----

/datum/action/cooldown/spell/cultivation/sword_riding
	name = "Sword Riding"
	desc = "Toss your bound artifact into the air and ride it over chasms, lava and gaps for 8 seconds. Blades become a glowing flying sword; \
		anything else rides a golden cloud. Get stunned and you fall off."
	button_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "flight"
	cooldown_time = 20 SECONDS
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

/**
 * Sword qi cleaves limbs. Picks a random arm or leg (or, for Nascent Soul cultivators, the head of someone already in crit)
 * and severs it with the given chance. Returns TRUE if something came off.
 */
/proc/cultivation_sever_limb(mob/living/carbon/victim, chance, realm = REALM_MORTAL)
	if(!iscarbon(victim) || !prob(chance))
		return FALSE
	var/list/zones = list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	if(realm >= REALM_NASCENT_SOUL && victim.stat >= SOFT_CRIT)
		zones += BODY_ZONE_HEAD
	var/list/candidates = list()
	for(var/zone in zones)
		var/obj/item/bodypart/limb = victim.get_bodypart(zone)
		if(limb?.can_dismember())
			candidates += limb
	if(!length(candidates))
		return FALSE
	var/obj/item/bodypart/severed = pick(candidates)
	victim.visible_message(span_boldwarning("A flash of sword qi cleaves [victim]'s [severed.plaintext_zone] clean off!"), span_userdanger("Your [severed.plaintext_zone] is cut clean off!"))
	new /obj/effect/temp_visual/impact_effect/cultivation_sword_qi(get_turf(victim), 0, 0)
	return severed.dismember(BRUTE, silent = TRUE, wounding_type = WOUND_SLASH)
