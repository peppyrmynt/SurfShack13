/// Helper for checking of someone's shapeshifted currently.
#define is_shifted(mob) mob.has_status_effect(/datum/status_effect/shapechange_mob/from_changeling)

/datum/action/changeling/horrorform
	name = "Horror Form"
	desc = "We mutate ourselves into a monstrosity to gain numerous perks, including fast speed and melee damage. Costs 45 chemicals."
	helptext = "The transformation makes us immune to stuns, however makes us completely obvious to anyone who sees us."
	button_icon_state = "horror_form"
	chemical_cost = 45
	dna_cost = 3
	usable_by_basicmobs = TRUE

/datum/action/changeling/horrorform/Remove(mob/remove_from)
	unshift_owner()
	return ..()

//Transform into horror form.
/datum/action/changeling/horrorform/sting_action(mob/living/user)
	. = ..()
	user.buckled?.unbuckle_mob(user, force = TRUE)

	var/currently_ventcrawling = (user.movement_type & VENTCRAWLING)
	var/mob/living/resulting_mob
	var/datum/antagonist/changeling/changeling = IS_CHANGELING(user)
	var/current_chem_charges = changeling.chem_charges

	user.add_splatter_floor()
	playsound(user.loc, 'sound/effects/splat.ogg', 50, TRUE) //So real sounds

	// Do the shift back or forth
	if(is_shifted(user))
		resulting_mob = untransform(user)
	else
		resulting_mob = transform(user)

	build_all_button_icons(update_flags = UPDATE_BUTTON_NAME | UPDATE_BUTTON_ICON)
	//Full mob transformations don't really work with changeling's antag and chem values, so set this here.
	changeling.chem_charges = current_chem_charges - chemical_cost
	// The shift is done, let's make sure they're in a valid state now
	// If we're not ventcrawling, we don't need to mind
	if(!currently_ventcrawling || !resulting_mob)
		return

	// We are ventcrawling - can our new form support ventcrawling?
	if(HAS_TRAIT(resulting_mob, TRAIT_VENTCRAWLER_ALWAYS) || HAS_TRAIT(resulting_mob, TRAIT_VENTCRAWLER_NUDE))
		return

	// Uh oh. You've shapeshifted into something that can't fit into a vent, while ventcrawling.
	eject_from_vents(resulting_mob)

/// Enter your horror form
/datum/action/changeling/horrorform/proc/transform(mob/living/user)
	var/mob/living/new_shape = new /mob/living/basic/changeling_horrorform(user.loc)
	var/datum/status_effect/shapechange_mob/shapechange = new_shape.apply_status_effect(/datum/status_effect/shapechange_mob/from_changeling, user, src)
	if(!shapechange)
		// We failed to shift, maybe because we were already shapeshifted?
		// Whatver the case, this shouldn't happen, so throw a stack trace.
		to_chat(user, span_warning("You can't shapeshift in this form!"))
		stack_trace("[type] transform was called when the mob was already transformed (from horror form).")
		return

	return new_shape

/// Leave horror form
/datum/action/changeling/horrorform/proc/untransform(mob/living/user)
	var/datum/status_effect/shapechange_mob/shapechange = user.has_status_effect(/datum/status_effect/shapechange_mob/from_changeling)
	if(!shapechange)
		// We made it to do_unshapeshift without having a shapeshift status effect, this shouldn't happen.
		to_chat(user, span_warning("You can't un-shapeshift from this form!"))
		stack_trace("[type] untransform was called when the mob wasn't even shapeshifted (from horror form).")
		return

	var/mob/living/unshapeshifted_mob = shapechange.caster_mob
	user.remove_status_effect(/datum/status_effect/shapechange_mob/from_changeling)
	chemical_cost = 45
	return unshapeshifted_mob

/datum/action/changeling/horrorform/update_button_name(atom/movable/screen/movable/action_button/button, force)
	if (is_shifted(owner))
		name = "Human Form"
		desc = "We change back into a human. Costs 45 chemicals."
	else
		name = initial(name)
		desc = initial(desc)
	return ..()

/datum/action/changeling/horrorform/apply_button_icon(atom/movable/screen/movable/action_button/current_button, force)
	button_icon_state = is_shifted(owner) ? "human_form" : initial(button_icon_state)
	return ..()

/// Whenever someone shapeshifts within a vent,
/// and enters a state in which they are no longer a ventcrawler,
/// they are brutally ejected from the vents. In the form of gibs.
/datum/action/changeling/horrorform/proc/eject_from_vents(mob/living/user)
	var/obj/machinery/atmospherics/pipe_you_die_in = user.loc
	var/datum/pipeline/our_pipeline
	var/pipenets = pipe_you_die_in.return_pipenets()
	if(islist(pipenets))
		our_pipeline = pipenets[1]
	else
		our_pipeline = pipenets

	to_chat(user, span_userdanger("Casting [src] inside of [pipe_you_die_in] quickly turns you into a bloody mush!"))
	var/obj/effect/gib_type = isalien(user) ? /obj/effect/gibspawner/xeno : /obj/effect/gibspawner/generic

	for(var/obj/machinery/atmospherics/components/unary/possible_vent in range(10, get_turf(user)))
		if(length(possible_vent.parents) && possible_vent.parents[1] == our_pipeline)
			new gib_type(get_turf(possible_vent))
			playsound(possible_vent, 'sound/mobs/non-humanoids/frog/reee.ogg', 75, TRUE)

	priority_announce("We detected a pipe blockage around [get_area(get_turf(user))], please dispatch someone to investigate.", "[command_name()]")
	// Gib our caster, and make sure to leave nothing behind
	// (If we leave something behind, it'll drop on the turf of the pipe, which is kinda wrong.)
	user.investigate_log("has been gibbed by shapeshifting while ventcrawling.", INVESTIGATE_DEATHS)
	user.gib()

/// Removes an active shapeshift effect from the owner
/datum/action/changeling/horrorform/proc/unshift_owner()
	if (isnull(owner))
		return
	if (is_shifted(owner))
		untransform(owner)

#undef is_shifted

#define HORRORFORM_INTERACTION "horrorform"

/mob/living/basic/changeling_horrorform
	name = "horror form"
	desc = "Oh god, what the fuck is that thing?"
	icon = 'icons/mob/nonhuman-player/changeling_horrorform.dmi'
	icon_state = "horrorform"
	icon_living = "horrorform"
	pixel_x = -8
	base_pixel_x = -8
	death_message = "collapses."
	health = 150
	maxHealth = 150
	unsuitable_atmos_damage = 2
	unsuitable_cold_damage = 2
	unsuitable_heat_damage = 4
	speed = -0.2
	density = TRUE
	pass_flags = PASSTABLE
	basic_mob_flags = FLAMMABLE_MOB
	sight = SEE_TURFS | SEE_OBJS | SEE_MOBS
	gender = NEUTER
	mob_biotypes = MOB_ORGANIC
	mob_size = MOB_SIZE_LARGE
	speak_emote = list("rasps", "mutters")
	damage_coeff = list(BRUTE = 1, BURN = 1.0, TOX = 0, STAMINA = 0, OXY = 0)
	hud_possible = list(DIAG_STAT_HUD, DIAG_HUD, ANTAG_HUD)
	melee_damage_lower = 20
	melee_damage_upper = 20
	melee_attack_cooldown = CLICK_CD_MELEE
	obj_damage = 25
	wound_bonus = 25
	bare_wound_bonus = 25
	armour_penetration = 30
	max_grab = GRAB_KILL
	attack_verb_continuous = "slashes at"
	attack_verb_simple = "slash"
	attack_sound = 'sound/items/weapons/pierce_slow.ogg'
	attack_vis_effect = ATTACK_EFFECT_SLASH
	move_resist = MOVE_FORCE_STRONG
	pull_force = MOVE_FORCE_STRONG
	lighting_cutoff_red = 22
	lighting_cutoff_green = 8
	lighting_cutoff_blue = 5

/mob/living/basic/changeling_horrorform/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/footstep, FOOTSTEP_MOB_CLAW)
	AddElement(/datum/element/door_pryer, pry_time = 5 SECONDS, interaction_key = HORRORFORM_INTERACTION)
	AddElement(/datum/element/poster_tearer, interaction_key = HORRORFORM_INTERACTION)
	RegisterSignal(src, COMSIG_LIVING_IGNITED, PROC_REF(on_ignited))

//Panic
/mob/living/basic/changeling_horrorform/proc/on_ignited()
	to_chat(src, span_alien("You've been caught on fire!"))
	playsound(src, 'sound/effects/hallucinations/far_noise.ogg', 50, 1)
	adjust_confusion(10 SECONDS)
	set_jitter_if_lower(20 SECONDS)

#undef HORRORFORM_INTERACTION
