// ===== Cultivation manuals =====

/**
 * Reading one awakens you (if you're a mortal) and teaches its law.
 * Counterfeit copies work, but make you shout every technique name and cost extra qi.
 * A cultivator who already knows the law can tell a counterfeit apart by examining it.
 */
/obj/item/book/granter/cultivation_manual
	name = "cultivation manual"
	desc = "A thread-bound book of meridian diagrams and very confident claims."
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'
	icon_state = "manual"
	remarks = list(
		"Circulate qi through the twelve primary meridians...",
		"Only those with an unyielding Dao heart may proceed past this page...",
		"Ignore the diagram on page four, the artist was drunk...",
		"Breathe in for four counts, hold for seven, out for eight...",
		"The ancients say heaven is jealous of talent. Heaven sounds petty.",
		"Junior, if you are reading this, this old master has long since ascended...",
	)
	pages_to_mastery = 3
	reading_time = 4 SECONDS
	uses = 2
	/// Law this manual teaches
	var/datum/cultivation_law/law_type
	/// Is it a fake
	var/counterfeit = FALSE

/obj/item/book/granter/cultivation_manual/Initialize(mapload)
	. = ..()
	if(law_type)
		name = initial(law_type.name)
		desc = "[initial(desc)] [initial(law_type.desc)]"
	if(counterfeit)
		name = "[name] [pick("(Abridged)", "(Revised Edition)", "(Bootleg)", "(Translated)", "Vol. 2")]"

/obj/item/book/granter/cultivation_manual/examine(mob/user)
	. = ..()
	if(!counterfeit)
		return
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(user)
	if(cultivator?.has_law(law_type))
		. += span_warning("Wait, these meridian diagrams are upside down. This is a counterfeit!")

/obj/item/book/granter/cultivation_manual/can_learn(mob/living/user)
	if(!ishuman(user) || !user.mind)
		to_chat(user, span_warning("You can't make sense of the diagrams."))
		return FALSE
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(user)
	var/datum/cultivation_law/known = cultivator?.has_law(law_type)
	if(known && !(known.counterfeit && !counterfeit))
		to_chat(user, span_warning("You already cultivate this law."))
		return FALSE
	if(cultivator && !known && length(cultivator.laws) >= cultivator.law_slots())
		to_chat(user, span_warning("Your meridians can't hold another law until you break through to a higher realm."))
		return FALSE
	return TRUE

/obj/item/book/granter/cultivation_manual/on_reading_finished(mob/living/user)
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(user)
	if(!cultivator)
		cultivator = user.mind.add_antag_datum(/datum/antagonist/cultivator)
	var/datum/cultivation_law/known = cultivator.has_law(law_type)
	if(known)
		known.counterfeit = FALSE
		to_chat(user, span_boldnotice("Comparing against the genuine text, you correct the mistakes in your [known.name]!"))
		return
	cultivator.learn_law(law_type, counterfeit)

/obj/item/book/granter/cultivation_manual/recoil(mob/living/user)
	to_chat(user, span_warning("The ink has faded to nothing. Whatever qi this book held has been used up."))

/obj/item/book/granter/cultivation_manual/returning_iron
	icon_state = "manual_metal"
	law_type = /datum/cultivation_law/returning_iron

/obj/item/book/granter/cultivation_manual/still_water
	icon_state = "manual_water"
	law_type = /datum/cultivation_law/still_water

/obj/item/book/granter/cultivation_manual/furnace_heart
	icon_state = "manual_fire"
	law_type = /datum/cultivation_law/furnace_heart

/obj/item/book/granter/cultivation_manual/rooted_mountain
	icon_state = "manual_earth"
	law_type = /datum/cultivation_law/rooted_mountain

/obj/item/book/granter/cultivation_manual/evergreen_spring
	icon_state = "manual_wood"
	law_type = /datum/cultivation_law/evergreen_spring

/// A random law, one in four chance of being a fake
/obj/effect/spawner/random/cultivation_manual
	name = "random cultivation manual"
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'
	icon_state = "manual"
	loot = list(
		/obj/item/book/granter/cultivation_manual/returning_iron,
		/obj/item/book/granter/cultivation_manual/still_water,
		/obj/item/book/granter/cultivation_manual/furnace_heart,
		/obj/item/book/granter/cultivation_manual/rooted_mountain,
		/obj/item/book/granter/cultivation_manual/evergreen_spring,
	)

/obj/effect/spawner/random/cultivation_manual/make_item(spawn_loc, type_path_to_make)
	var/obj/item/book/granter/cultivation_manual/manual = new type_path_to_make(spawn_loc)
	if(prob(25))
		manual.counterfeit = TRUE
		manual.name = "[manual.name] [pick("(Abridged)", "(Revised Edition)", "(Bootleg)", "(Translated)", "Vol. 2")]"
	return manual

// ===== Talismans =====

/**
 * One-use paper talismans written by cultivators. Anyone can use them, which is the point:
 * the bartender can sell them, security can confiscate them.
 */
/obj/item/cultivation_talisman
	name = "talisman"
	desc = "A strip of yellow paper covered in glowing red characters."
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'
	icon_state = "talisman"
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = FLAMMABLE
	/// Text shown on use
	var/use_text = "The talisman flares and crumbles to ash."

/obj/item/cultivation_talisman/proc/burn_out(mob/living/user)
	if(user)
		to_chat(user, span_notice(use_text))
	var/turf/here = get_turf(src)
	new /obj/effect/temp_visual/cultivation_talisman_flare(here, src)
	playsound(here, 'sound/items/match_strike.ogg', 40, TRUE)
	new /obj/effect/decal/cleanable/ash(drop_location())
	qdel(src)

/// The talisman's own effect on whoever it hit
/obj/item/cultivation_talisman/proc/talisman_effect(mob/living/target)
	return

/// Slap a talisman on a living target
/obj/item/cultivation_talisman/proc/apply_to(mob/living/target, mob/living/user)
	return FALSE

/obj/item/cultivation_talisman/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isliving(interacting_with))
		return NONE
	if(apply_to(interacting_with, user))
		user.do_attack_animation(interacting_with)
		talisman_effect(interacting_with)
		burn_out(user)
		return ITEM_INTERACT_SUCCESS
	return ITEM_INTERACT_BLOCKING

/obj/item/cultivation_talisman/fire
	name = "fire talisman"
	desc = "A talisman with the character for fire. Throw it and it bursts into flame where it lands."
	icon_state = "talisman_fire"
	use_text = "The fire talisman bursts into flame!"

/obj/item/cultivation_talisman/fire/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	var/turf/open/landing = get_turf(src)
	if(istype(landing))
		for(var/turf/open/burn_turf in range(1, landing))
			new /obj/effect/hotspot(burn_turf)
			burn_turf.hotspot_expose(700, 50, 1)
	playsound(landing, 'sound/effects/magic/fireball.ogg', 40, TRUE)
	burn_out()

/obj/item/cultivation_talisman/binding
	name = "binding talisman"
	desc = "A talisman with the character for binding. Slap it on someone to make their legs heavy."
	icon_state = "talisman_binding"

/obj/item/cultivation_talisman/binding/apply_to(mob/living/target, mob/living/user)
	target.visible_message(span_warning("[user] slaps a talisman onto [target]!"), span_userdanger("Your legs turn to lead!"))
	target.apply_status_effect(/datum/status_effect/cultivation_slow, 5 SECONDS)
	return TRUE

/obj/item/cultivation_talisman/binding/talisman_effect(mob/living/target)
	var/obj/effect/temp_visual/circle_wave/cultivation/ring = new(get_turf(target))
	ring.color = "#c2a8ff"
	target.Shake(1, 0, 0.5 SECONDS)
	playsound(target, 'sound/items/weapons/chainhit.ogg', 40, TRUE)

/obj/item/cultivation_talisman/ward
	name = "ward talisman"
	desc = "A talisman with the character for protection. Use it in hand or on someone to cover them in still water."
	icon_state = "talisman_ward"

/obj/item/cultivation_talisman/ward/apply_to(mob/living/target, mob/living/user)
	target.apply_status_effect(/datum/status_effect/still_water_ward)
	return TRUE

/obj/item/cultivation_talisman/ward/talisman_effect(mob/living/target)
	new /obj/effect/temp_visual/circle_wave/cultivation/water(get_turf(target))
	playsound(target, 'sound/effects/splash.ogg', 30, TRUE, frequency = 1.4)

/obj/item/cultivation_talisman/ward/attack_self(mob/user)
	if(isliving(user) && apply_to(user, user))
		talisman_effect(user)
		burn_out(user)

/obj/item/cultivation_talisman/light
	name = "light talisman"
	desc = "A talisman with the character for light. Use it in hand and it glows for a few minutes."
	icon_state = "talisman_light"
	light_range = 4
	light_color = "#fff2b0"
	light_on = FALSE
	light_system = OVERLAY_LIGHT
	var/used = FALSE

/obj/item/cultivation_talisman/light/attack_self(mob/user)
	if(used)
		return
	used = TRUE
	set_light_on(TRUE)
	add_filter("talisman_glow", 2, list("type" = "outline", "color" = "#fff2b0", "size" = 1))
	new /obj/effect/temp_visual/cultivation_spark(get_turf(src), "#fff2b0")
	cultivation_wind_chimes(src, 20)
	to_chat(user, span_notice("The talisman begins to glow softly."))
	addtimer(CALLBACK(src, PROC_REF(burn_out)), 3 MINUTES)

/obj/item/cultivation_talisman/jiangshi
	name = "jiangshi-sealing talisman"
	desc = "A talisman for sealing hopping corpses. Slap it on the forehead of the undead to freeze them in place."
	icon_state = "talisman_jiangshi"

/obj/item/cultivation_talisman/jiangshi/apply_to(mob/living/target, mob/living/user)
	if(istype(target, /mob/living/basic/corpse_puppet))
		var/mob/living/basic/corpse_puppet/puppet = target
		target.visible_message(span_danger("[user] slaps a talisman onto [target]'s forehead! The demonic qi holding it up gutters out!"))
		puppet.collapse()
		return TRUE
	var/undead = (target.mob_biotypes & MOB_UNDEAD) || IS_BLOODSUCKER(target)
	if(!undead)
		to_chat(user, span_warning("[target] isn't undead. The talisman just sticks to [target.p_their()] forehead and looks silly."))
		return TRUE
	target.visible_message(span_danger("[user] slaps a talisman onto [target]'s forehead, and [target.p_they()] freeze[target.p_s()] rigid!"), span_userdanger("A talisman seals your corpse-qi! You can't move!"))
	new /obj/effect/temp_visual/cultivation_spark(get_turf(target), "#ffd27a", 0, 10)
	cultivation_temple_sound(target, 40)
	target.Paralyze(5 SECONDS)
	return TRUE

// ===== Spirit beasts =====

/**
 * A station animal under a cultivator's contract. It befriends its master and plugs into the normal pet command system:
 * alt-click it for a radial (follow, stay, attack, free), or call commands out loud and point at targets.
 * It automatically defends its master when they're attacked, and grows with its master's realm.
 */
/datum/component/spirit_beast
	var/datum/mind/master_mind
	/// Realm we last scaled to
	var/scaled_realm = 0
	var/base_max_health
	/// Did we add the obeys_commands component ourselves (so we remove it again)
	var/added_obedience = FALSE
	/// Planning subtrees before we taught it to listen
	var/list/original_subtrees
	/// Bloodline awakenings: 0 spirit beast, 1 awakened, 2 divine. Fed Beast Awakening Pills.
	var/evolution = 0
	/// Aura sprite once awakened
	var/obj/effect/abstract/cultivation_vis/aura
	/// Names for each stage
	var/static/list/evolution_titles = list("Spirit", "Awakened Spirit", "Divine Spirit")
	COOLDOWN_DECLARE(catch_up_cooldown)
	/// Commands every spirit beast understands
	var/static/list/spirit_beast_commands = list(
		/datum/pet_command/idle,
		/datum/pet_command/free,
		/datum/pet_command/follow,
		/datum/pet_command/point_targeting/attack,
		/datum/pet_command/protect_owner,
	)
	/// Monkeys fight with their own AI, so their attack commands just point that AI at someone
	var/static/list/spirit_monkey_commands = list(
		/datum/pet_command/idle,
		/datum/pet_command/free,
		/datum/pet_command/follow,
		/datum/pet_command/point_targeting/attack/spirit_monkey,
		/datum/pet_command/protect_owner/spirit_monkey,
	)

/datum/component/spirit_beast/Initialize(datum/mind/master_mind)
	if(!isbasicmob(parent) && !ismonkey(parent))
		return COMPONENT_INCOMPATIBLE
	var/mob/living/beast = parent
	if(!beast.ai_controller)
		return COMPONENT_INCOMPATIBLE
	src.master_mind = master_mind
	base_max_health = beast.maxHealth

/datum/component/spirit_beast/RegisterWithParent()
	var/mob/living/beast = parent
	var/mob/living/master = master_mind?.current
	RegisterSignal(beast, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(beast, COMSIG_LIVING_DEATH, PROC_REF(on_death))
	RegisterSignal(beast, COMSIG_LIVING_LIFE, PROC_REF(on_beast_life))
	RegisterSignal(beast, COMSIG_HOSTILE_POST_ATTACKINGTARGET, PROC_REF(on_beast_attack))
	if(master)
		RegisterSignal(master, COMSIG_MOB_CULTIVATION_REALM_CHANGED, PROC_REF(rescale))
		RegisterSignal(master, COMSIG_MOVABLE_MOVED, PROC_REF(on_master_moved))
	beast.add_filter("spirit_beast", 2, list("type" = "outline", "color" = "#b6f2ff", "size" = 1, "alpha" = 150))
	if(!findtext(beast.name, "Spirit "))
		beast.name = "Spirit [beast.name]"
	teach_obedience()
	if(master)
		beast.befriend(master)
		command(master, "Follow")
	rescale()
	if(master)
		to_chat(master, span_boldnotice("[beast] is now your spirit beast! Alt-click it to command it, or point at enemies after telling it to attack. It will defend you if you're attacked."))

/datum/component/spirit_beast/UnregisterFromParent()
	var/mob/living/beast = parent
	var/mob/living/master = master_mind?.current
	UnregisterSignal(beast, list(COMSIG_ATOM_EXAMINE, COMSIG_LIVING_DEATH, COMSIG_LIVING_LIFE, COMSIG_HOSTILE_POST_ATTACKINGTARGET))
	cultivation_detach_vis(beast, aura)
	aura = null
	if(master)
		UnregisterSignal(master, list(COMSIG_MOB_CULTIVATION_REALM_CHANGED, COMSIG_MOVABLE_MOVED))
		beast.unfriend(master)
	if(added_obedience)
		qdel(beast.GetComponent(/datum/component/obeys_commands))
	if(original_subtrees && beast.ai_controller)
		beast.ai_controller.replace_planning_subtrees(original_subtrees)
	beast.remove_filter("spirit_beast")
	beast.name = replacetext(replacetext(replacetext(beast.name, "Divine ", ""), "Awakened ", ""), "Spirit ", "")
	beast.maxHealth = base_max_health
	beast.health = min(beast.health, beast.maxHealth)
	beast.update_transform(1 / ((1 + 0.1 * scaled_realm) * (1 + 0.1 * evolution)))

/datum/component/spirit_beast/Destroy(force)
	master_mind = null
	return ..()

/// Make sure the beast's brain can take pet commands, even if it's not normally a pet
/datum/component/spirit_beast/proc/teach_obedience()
	var/mob/living/beast = parent
	var/datum/ai_controller/brain = beast.ai_controller
	if(isnull(brain.blackboard[BB_PET_TARGETING_STRATEGY]))
		brain.set_blackboard_key(BB_PET_TARGETING_STRATEGY, /datum/targeting_strategy/basic/not_friends)
	if(isnull(brain.blackboard[BB_TARGET_MINIMUM_STAT]))
		brain.set_blackboard_key(BB_TARGET_MINIMUM_STAT, HARD_CRIT)
	var/list/subtree_types = list()
	for(var/datum/ai_planning_subtree/subtree as anything in brain.planning_subtrees)
		subtree_types += subtree.type
	if(!(/datum/ai_planning_subtree/pet_planning in subtree_types))
		original_subtrees = subtree_types.Copy()
		subtree_types.Insert(1, /datum/ai_planning_subtree/pet_planning)
		brain.replace_planning_subtrees(subtree_types)
	var/datum/component/obeys_commands/obedience = beast.GetComponent(/datum/component/obeys_commands)
	if(!obedience)
		beast.AddComponent(/datum/component/obeys_commands, ismonkey(beast) ? spirit_monkey_commands : spirit_beast_commands)
		added_obedience = TRUE
		return
	// Existing pets learn to protect their master too
	var/has_protect = FALSE
	for(var/command_name in obedience.available_commands)
		if(istype(obedience.available_commands[command_name], /datum/pet_command/protect_owner))
			has_protect = TRUE
			break
	if(!has_protect)
		var/datum/pet_command/protect_owner/protect = new(beast)
		obedience.available_commands[protect.command_name] = protect

/// Issue one of the beast's commands by name, as if the master had chosen it from the radial
/datum/component/spirit_beast/proc/command(mob/living/commander, command_name)
	var/mob/living/beast = parent
	var/datum/component/obeys_commands/obedience = beast.GetComponent(/datum/component/obeys_commands)
	for(var/name in obedience?.available_commands)
		var/datum/pet_command/pet_command = obedience.available_commands[name]
		if(pet_command.command_name == command_name || istype(pet_command, /datum/pet_command/follow) && command_name == "Follow")
			pet_command.try_activate_command(commander)
			return TRUE
	return FALSE

/// Jump or rift next to a spot
/datum/component/spirit_beast/proc/hop_to(turf/destination, through_void)
	var/mob/living/beast = parent
	var/turf/landing = destination
	for(var/turf/open/nearby in orange(1, destination))
		if(!nearby.is_blocked_turf(exclude_mobs = TRUE))
			landing = nearby
			break
	if(through_void)
		new /obj/effect/temp_visual/cultivation_void_rift(get_turf(beast))
		cultivation_afterimage(beast, 0.5 SECONDS)
		addtimer(CALLBACK(src, PROC_REF(arrive), landing), 0.3 SECONDS)
		return
	var/old_pass = beast.pass_flags
	beast.pass_flags |= PASSTABLE
	playsound(beast, 'sound/items/weapons/fwoosh.ogg', 30, TRUE, frequency = 1.5)
	beast.throw_at(landing, 8, 2, beast, spin = FALSE, gentle = TRUE, callback = VARSET_CALLBACK(beast, pass_flags, old_pass))

/datum/component/spirit_beast/proc/arrive(turf/landing)
	var/mob/living/beast = parent
	if(QDELETED(beast) || beast.stat == DEAD)
		return
	beast.forceMove(landing)
	new /obj/effect/temp_visual/cultivation_void_rift(landing)
	playsound(landing, 'sound/effects/magic/blink.ogg', 30, TRUE)

/// Master got too far away (barriers, doors, space): the beast rifts after them
/datum/component/spirit_beast/proc/on_master_moved(atom/movable/master, atom/old_loc, dir, forced)
	SIGNAL_HANDLER
	var/mob/living/beast = parent
	if(!COOLDOWN_FINISHED(src, catch_up_cooldown) || beast.stat != CONSCIOUS || master.z != beast.z || get_dist(master, beast) <= 9)
		return
	if(beast.ai_controller?.blackboard[BB_ACTIVE_PET_COMMAND] && !istype(beast.ai_controller.blackboard[BB_ACTIVE_PET_COMMAND], /datum/pet_command/follow))
		return // told to stay or attack something, don't drag it along
	COOLDOWN_START(src, catch_up_cooldown, 10 SECONDS)
	hop_to(get_turf(master), TRUE)

/datum/component/spirit_beast/proc/rescale(datum/source)
	SIGNAL_HANDLER
	var/mob/living/beast = parent
	var/new_realm = master_mind?.current ? cultivation_realm_of(master_mind.current) : 0
	if(new_realm == scaled_realm)
		return
	beast.update_transform((1 + 0.1 * new_realm) / (1 + 0.1 * scaled_realm))
	scaled_realm = new_realm
	apply_stats()
	new /obj/effect/temp_visual/circle_wave/cultivation(get_turf(beast))
	beast.visible_message(span_notice("[beast] grows a little larger, a faint aura shimmering around it."))

/// Health and bite from its master's realm and its own bloodline
/datum/component/spirit_beast/proc/apply_stats()
	var/mob/living/beast = parent
	beast.maxHealth = base_max_health * (1 + 0.5 * scaled_realm) * (1 + 0.5 * evolution)
	beast.heal_overall_damage(brute = 20, burn = 20)
	if(isbasicmob(beast))
		var/mob/living/basic/basic_beast = beast
		basic_beast.melee_damage_lower = max(basic_beast.melee_damage_lower, 2 * scaled_realm + 3 * evolution)
		basic_beast.melee_damage_upper = max(basic_beast.melee_damage_upper, 4 * scaled_realm + 4 * evolution)

/// A Beast Awakening Pill stirs the bloodline. Each awakening needs its master one realm higher (Foundation, then Golden Core).
/datum/component/spirit_beast/proc/evolve()
	var/mob/living/beast = parent
	if(evolution >= 2 || beast.stat == DEAD)
		return FALSE
	var/master_realm = master_mind?.current ? cultivation_realm_of(master_mind.current) : REALM_MORTAL
	if(master_realm < REALM_FOUNDATION + evolution)
		return FALSE
	var/old_title = evolution_titles[evolution + 1]
	evolution++
	beast.update_transform(1.1)
	apply_stats()
	beast.fully_heal(HEAL_DAMAGE)
	beast.name = replacetext(beast.name, "[old_title] ", "[evolution_titles[evolution + 1]] ")
	beast.remove_filter("spirit_beast")
	beast.add_filter("spirit_beast", 2, list("type" = "outline", "color" = evolution >= 2 ? "#ffd55a" : "#b6f2ff", "size" = 1, "alpha" = 200))
	cultivation_detach_vis(beast, aura)
	aura = cultivation_attach_vis(beast, 'surfshack13/icons/cultivation/cultivation_effects_64.dmi', "beast_aura", evolution >= 2 ? "#ffd55a" : null, 64, 0, 170)
	aura.layer = BELOW_MOB_LAYER
	// The awakening itself
	animate(beast, pixel_z = 8, time = 0.6 SECONDS, easing = SINE_EASING | EASE_OUT, flags = ANIMATION_RELATIVE | ANIMATION_PARALLEL)
	animate(pixel_z = -8, time = 0.6 SECONDS, easing = SINE_EASING | EASE_IN, flags = ANIMATION_RELATIVE)
	new /obj/effect/temp_visual/cultivation_ascension_pillar(get_turf(beast))
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(get_turf(beast))
	cultivation_particles(beast, /particles/cultivation/gold, 3 SECONDS)
	cultivation_guqin_phrase(beast, list(1, 2, 3, 5, 6))
	playsound(beast, 'sound/effects/magic/charge.ogg', 60, TRUE)
	beast.visible_message(span_boldnotice("[beast]'s bloodline awakens! It swells with power, its eyes blazing!"))
	if(master_mind?.current)
		to_chat(master_mind.current, span_boldnotice("Your spirit beast has become a [evolution_titles[evolution + 1]] beast! [evolution >= 2 ? "Its bites now bowl enemies over, and it heals quickly." : "It now slowly heals its wounds."]"))
	return TRUE

/// Awakened beasts knit their wounds
/datum/component/spirit_beast/proc/on_beast_life(mob/living/source, seconds_per_tick, times_fired)
	SIGNAL_HANDLER
	if(!evolution || source.stat == DEAD || source.health >= source.maxHealth)
		return
	source.heal_overall_damage(brute = 0.5 * evolution * seconds_per_tick, burn = 0.5 * evolution * seconds_per_tick)

/// Divine beasts knock their prey down
/datum/component/spirit_beast/proc/on_beast_attack(mob/living/source, atom/target, success)
	SIGNAL_HANDLER
	if(evolution < 2 || !success || !isliving(target) || !prob(25))
		return
	var/mob/living/prey = target
	prey.Knockdown(1.5 SECONDS)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold(get_turf(prey))

/datum/component/spirit_beast/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_notice("It is bound by a spirit contract[master_mind?.current ? " to [master_mind.current]" : ""].")
	if(evolution)
		examine_list += span_notice("Its bloodline has awakened: it is a [evolution_titles[evolution + 1]] beast.")

/datum/component/spirit_beast/proc/on_death(datum/source)
	SIGNAL_HANDLER
	var/mob/living/master = master_mind?.current
	if(master)
		to_chat(master, span_userdanger("You feel your spirit beast's life snuff out! Your contract shatters!"))
		master.add_mood_event("spirit_beast_died", /datum/mood_event/spirit_beast_died)
		var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(master)
		cultivator?.adjust_instability(10)
	qdel(src)

/// Your spirit beast comes with you when you leap (it leaps too) or step through the void (it's pulled through the rift)
/proc/cultivation_beast_follow(mob/living/master, turf/destination, through_void)
	var/mob/living/beast = cultivation_get_beast(master.mind)
	if(!beast || beast.stat != CONSCIOUS || beast.z != master.z || get_dist(beast, master) > 9 || beast.buckled || beast.pulledby)
		return
	var/datum/component/spirit_beast/contract = beast.GetComponent(/datum/component/spirit_beast)
	contract.hop_to(destination, through_void)

/// Find a mind's contracted spirit beast
/proc/cultivation_get_beast(datum/mind/master_mind)
	if(!master_mind)
		return null
	for(var/mob/living/beast as anything in GLOB.mob_living_list)
		var/datum/component/spirit_beast/contract = beast.GetComponent(/datum/component/spirit_beast)
		if(contract?.master_mind == master_mind)
			return beast
	return null

/// Monkey version of attack: put the target on the monkey's enemies list and let monkey combat AI take over
/datum/pet_command/point_targeting/attack/spirit_monkey
	command_feedback = "screeches"

/datum/pet_command/point_targeting/attack/spirit_monkey/execute_action(datum/ai_controller/controller)
	var/atom/target = controller.blackboard[BB_CURRENT_PET_TARGET]
	if(isliving(target))
		controller.add_blackboard_key_assoc(BB_MONKEY_ENEMIES, target, MONKEY_HATRED_AMOUNT * 3)
	controller.clear_blackboard_key(BB_ACTIVE_PET_COMMAND)

/datum/pet_command/protect_owner/spirit_monkey/execute_action(datum/ai_controller/controller)
	var/mob/living/attacker = controller.blackboard[BB_CURRENT_PET_TARGET]
	if(isliving(attacker) && attacker != controller.pawn)
		controller.add_blackboard_key_assoc(BB_MONKEY_ENEMIES, attacker, MONKEY_HATRED_AMOUNT * 3)
	controller.clear_blackboard_key(BB_ACTIVE_PET_COMMAND)

/datum/mood_event/spirit_beast_died
	description = "My spirit beast was slain. I will have vengeance."
	mood_change = -8
	timeout = 10 MINUTES

// ===== Grandpa in the Ring =====

/**
 * # Ancestral ring
 *
 * Holds the soul of an old master (a ghost role). The elder can only speak to whoever carries the ring,
 * can lend them qi, and speeds up their insight while they carry it. The chaplain can exorcise the old fool.
 */
/obj/item/ancestral_ring
	name = "ancestral ring"
	desc = "A heavy, tarnished ring with a dull black stone. It feels like it's watching you."
	icon = 'surfshack13/icons/cultivation/cultivation_items.dmi'
	icon_state = "ring"
	w_class = WEIGHT_CLASS_TINY
	/// The old master inside
	var/mob/living/basic/shade/ring_elder/elder
	var/polling = FALSE
	/// Cultivator currently getting our insight bonus
	var/datum/weakref/blessed_ref

/obj/item/ancestral_ring/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/item/ancestral_ring/Destroy()
	STOP_PROCESSING(SSobj, src)
	clear_blessing()
	if(elder)
		elder.ghostize(FALSE)
		QDEL_NULL(elder)
	return ..()

/obj/item/ancestral_ring/examine(mob/user)
	. = ..()
	if(elder)
		. += span_notice("Something old and smug lives in the stone.")
	else if(IS_CULTIVATOR(user))
		. += span_notice("A dormant soul sleeps in the stone. Use the ring in hand to try to wake it.")

/// The carrier of the ring, if any
/obj/item/ancestral_ring/proc/get_bearer()
	return get(src, /mob/living/carbon)

/obj/item/ancestral_ring/process(seconds_per_tick)
	var/mob/living/bearer = get_bearer()
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(bearer)
	var/datum/antagonist/cultivator/blessed = blessed_ref?.resolve()
	if(elder?.client && cultivator)
		if(blessed != cultivator)
			clear_blessing()
			cultivator.insight_bonuses["ancestral_ring"] = 0.25
			blessed_ref = WEAKREF(cultivator)
	else
		clear_blessing()

/obj/item/ancestral_ring/proc/clear_blessing()
	var/datum/antagonist/cultivator/blessed = blessed_ref?.resolve()
	blessed?.insight_bonuses -= "ancestral_ring"
	blessed_ref = null

/obj/item/ancestral_ring/attack_self(mob/user)
	if(elder || polling)
		return
	if(!IS_CULTIVATOR(user))
		to_chat(user, span_notice("It's a ring. You turn it over in your hand. Nothing happens."))
		return
	if(!(GLOB.ghost_role_flags & GHOSTROLE_STATION_SENTIENCE))
		to_chat(user, span_warning("The soul within refuses to stir."))
		return
	polling = TRUE
	to_chat(user, span_notice("You channel a thread of qi into the stone..."))
	INVOKE_ASYNC(src, PROC_REF(awaken), user)

/obj/item/ancestral_ring/proc/awaken(mob/user)
	var/mob/chosen = SSpolling.poll_ghosts_for_target(
		question = "Do you want to play as an ancient master living in [user.real_name]'s ring? You can only speak to the ring's bearer.",
		check_jobban = ROLE_PAI,
		poll_time = 20 SECONDS,
		checked_target = src,
		ignore_category = POLL_IGNORE_POSSESSED_BLADE,
		alert_pic = src,
		role_name_text = "ring grandpa",
		chat_text_border_icon = src,
	)
	polling = FALSE
	if(QDELETED(src))
		return
	if(!chosen?.mind)
		to_chat(user, span_warning("The stone stays cold. Maybe later."))
		return
	elder = new(src)
	chosen.mind.transfer_to(elder)
	elder.fully_replace_character_name(null, "Ancient Master")
	elder.ring = src
	to_chat(elder, span_boldnotice("You are an ancient master, your soul sealed in this ring for ten thousand years. \
		Your new bearer is [user.real_name]. Guide them (or berate them) on their path. Only the ring's bearer can hear you."))
	to_chat(user, span_boldnotice("An old voice yawns inside your head. \"Ten thousand years... and THIS is my successor?\""))

/obj/item/ancestral_ring/attackby(obj/item/attacking_item, mob/user, params)
	if(elder && (istype(attacking_item, /obj/item/book/bible) || istype(attacking_item, /obj/item/nullrod)))
		user.visible_message(span_notice("[user] presses [attacking_item] against [src]. A faint wail echoes from the stone."))
		to_chat(elder, span_userdanger("Holy power banishes you from the ring!"))
		elder.ghostize(FALSE)
		QDEL_NULL(elder)
		return TRUE
	return ..()

/mob/living/basic/shade/ring_elder
	name = "Ancient Master"
	desc = "A wizened ghostly face in a ring."
	/// The ring we live in
	var/obj/item/ancestral_ring/ring

/mob/living/basic/shade/ring_elder/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_GODMODE, INNATE_TRAIT)
	var/datum/action/cooldown/ring_elder_lend_qi/lend = new(src)
	lend.Grant(src)

/mob/living/basic/shade/ring_elder/Destroy()
	ring = null
	return ..()

/// Only the bearer hears grandpa
/mob/living/basic/shade/ring_elder/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language, ignore_spam = FALSE, forced, filterproof = FALSE, message_range = 7, datum/saymode/saymode, list/message_mods = list())
	if(sanitize)
		message = trim(copytext_char(sanitize(message), 1, MAX_MESSAGE_LEN))
	if(!message)
		return
	log_talk(message, LOG_SAY, tag = "ring elder")
	to_chat(src, span_notice("<i>You murmur to your bearer:</i> \"[message]\""))
	var/mob/living/bearer = ring?.get_bearer()
	if(bearer)
		to_chat(bearer, span_notice("<i>An old voice echoes in your head:</i> <b>\"[message]\"</b>"))
	for(var/mob/dead/observer/ghost in GLOB.dead_mob_list)
		if(ghost.client && (ghost.client.prefs?.chat_toggles & CHAT_GHOSTEARS))
			to_chat(ghost, "[FOLLOW_LINK(ghost, src)] [span_notice("<i>[src] (ring):</i> \"[message]\"")]")

/datum/action/cooldown/ring_elder_lend_qi
	name = "Lend Qi"
	desc = "Pour some of your ancient qi into your bearer."
	button_icon = 'surfshack13/icons/cultivation/cultivation_actions.dmi'
	button_icon_state = "lend_qi"
	background_icon_state = "bg_heretic"
	overlay_icon_state = "bg_heretic_border"
	cooldown_time = 3 MINUTES

/datum/action/cooldown/ring_elder_lend_qi/Activate(atom/target)
	var/mob/living/basic/shade/ring_elder/elder = owner
	var/mob/living/bearer = elder.ring?.get_bearer()
	var/datum/antagonist/cultivator/cultivator = IS_CULTIVATOR(bearer)
	if(!cultivator)
		to_chat(elder, span_warning("Your bearer has no dantian to receive your qi."))
		return FALSE
	cultivator.adjust_qi(30)
	to_chat(bearer, span_nicegreen("Warm, ancient qi flows into you from the ring."))
	to_chat(elder, span_notice("You lend your bearer some of your qi."))
	StartCooldown()
	return TRUE
