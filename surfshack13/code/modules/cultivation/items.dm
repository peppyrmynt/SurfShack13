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
	law_type = /datum/cultivation_law/returning_iron

/obj/item/book/granter/cultivation_manual/still_water
	law_type = /datum/cultivation_law/still_water

/obj/item/book/granter/cultivation_manual/furnace_heart
	law_type = /datum/cultivation_law/furnace_heart

/obj/item/book/granter/cultivation_manual/rooted_mountain
	law_type = /datum/cultivation_law/rooted_mountain

/obj/item/book/granter/cultivation_manual/evergreen_spring
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
	icon = 'icons/obj/service/bureaucracy.dmi'
	icon_state = "paper_talisman"
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = FLAMMABLE
	/// Text shown on use
	var/use_text = "The talisman flares and crumbles to ash."

/obj/item/cultivation_talisman/proc/burn_out(mob/living/user)
	if(user)
		to_chat(user, span_notice(use_text))
	new /obj/effect/decal/cleanable/ash(drop_location())
	qdel(src)

/// Slap a talisman on a living target
/obj/item/cultivation_talisman/proc/apply_to(mob/living/target, mob/living/user)
	return FALSE

/obj/item/cultivation_talisman/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isliving(interacting_with))
		return NONE
	if(apply_to(interacting_with, user))
		user.do_attack_animation(interacting_with)
		burn_out(user)
		return ITEM_INTERACT_SUCCESS
	return ITEM_INTERACT_BLOCKING

/obj/item/cultivation_talisman/fire
	name = "fire talisman"
	desc = "A talisman with the character for fire. Throw it and it bursts into flame where it lands."
	color = "#ffb38a"
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
	color = "#c2a8ff"

/obj/item/cultivation_talisman/binding/apply_to(mob/living/target, mob/living/user)
	target.visible_message(span_warning("[user] slaps a talisman onto [target]!"), span_userdanger("Your legs turn to lead!"))
	target.apply_status_effect(/datum/status_effect/cultivation_slow, 5 SECONDS)
	return TRUE

/obj/item/cultivation_talisman/ward
	name = "ward talisman"
	desc = "A talisman with the character for protection. Use it in hand or on someone to cover them in still water."
	color = "#9fd8ff"

/obj/item/cultivation_talisman/ward/apply_to(mob/living/target, mob/living/user)
	target.apply_status_effect(/datum/status_effect/still_water_ward)
	return TRUE

/obj/item/cultivation_talisman/ward/attack_self(mob/user)
	if(isliving(user) && apply_to(user, user))
		burn_out(user)

/obj/item/cultivation_talisman/light
	name = "light talisman"
	desc = "A talisman with the character for light. Use it in hand and it glows for a few minutes."
	color = "#fff6a8"
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
	to_chat(user, span_notice("The talisman begins to glow softly."))
	addtimer(CALLBACK(src, PROC_REF(burn_out)), 3 MINUTES)

/obj/item/cultivation_talisman/jiangshi
	name = "jiangshi-sealing talisman"
	desc = "A talisman for sealing hopping corpses. Slap it on the forehead of the undead to freeze them in place."
	color = "#ffd27a"

/obj/item/cultivation_talisman/jiangshi/apply_to(mob/living/target, mob/living/user)
	var/undead = (target.mob_biotypes & MOB_UNDEAD) || IS_BLOODSUCKER(target)
	if(!undead)
		to_chat(user, span_warning("[target] isn't undead. The talisman just sticks to [target.p_their()] forehead and looks silly."))
		return TRUE
	target.visible_message(span_danger("[user] slaps a talisman onto [target]'s forehead, and [target.p_they()] freeze[target.p_s()] rigid!"), span_userdanger("A talisman seals your corpse-qi! You can't move!"))
	target.Paralyze(8 SECONDS)
	return TRUE

// ===== Spirit beasts =====

/// A station animal under a cultivator's contract. Grows with its master's realm.
/datum/component/spirit_beast
	var/datum/mind/master_mind
	/// Realm we last scaled to
	var/scaled_realm = 0
	var/base_max_health

/datum/component/spirit_beast/Initialize(datum/mind/master_mind)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	src.master_mind = master_mind
	var/mob/living/beast = parent
	base_max_health = beast.maxHealth

/datum/component/spirit_beast/RegisterWithParent()
	var/mob/living/beast = parent
	RegisterSignal(beast, COMSIG_ATOM_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(beast, COMSIG_LIVING_DEATH, PROC_REF(on_death))
	if(master_mind?.current)
		RegisterSignal(master_mind.current, COMSIG_MOB_CULTIVATION_REALM_CHANGED, PROC_REF(rescale))
	beast.add_filter("spirit_beast", 2, list("type" = "outline", "color" = "#b6f2ff", "size" = 1, "alpha" = 150))
	beast.faction |= REF(master_mind?.current)
	if(!findtext(beast.name, "Spirit "))
		beast.name = "Spirit [beast.name]"
	rescale()
	to_chat(master_mind?.current, span_boldnotice("[beast] is now your spirit beast!"))

/datum/component/spirit_beast/UnregisterFromParent()
	var/mob/living/beast = parent
	UnregisterSignal(beast, list(COMSIG_ATOM_EXAMINE, COMSIG_LIVING_DEATH))
	if(master_mind?.current)
		UnregisterSignal(master_mind.current, COMSIG_MOB_CULTIVATION_REALM_CHANGED)
	beast.remove_filter("spirit_beast")
	beast.name = replacetext(beast.name, "Spirit ", "")
	beast.maxHealth = base_max_health
	beast.health = min(beast.health, beast.maxHealth)
	beast.update_transform(1 / (1 + 0.1 * scaled_realm))

/datum/component/spirit_beast/Destroy(force)
	master_mind = null
	return ..()

/datum/component/spirit_beast/proc/rescale(datum/source)
	SIGNAL_HANDLER
	var/mob/living/beast = parent
	var/new_realm = master_mind?.current ? cultivation_realm_of(master_mind.current) : 0
	if(new_realm == scaled_realm)
		return
	beast.update_transform((1 + 0.1 * new_realm) / (1 + 0.1 * scaled_realm))
	scaled_realm = new_realm
	beast.maxHealth = base_max_health * (1 + 0.5 * new_realm)
	beast.heal_overall_damage(brute = 20, burn = 20)
	if(isbasicmob(beast))
		var/mob/living/basic/basic_beast = beast
		basic_beast.melee_damage_lower = max(basic_beast.melee_damage_lower, 2 * new_realm)
		basic_beast.melee_damage_upper = max(basic_beast.melee_damage_upper, 4 * new_realm)
	beast.visible_message(span_notice("[beast] grows a little larger, a faint aura shimmering around it."))

/datum/component/spirit_beast/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	examine_list += span_notice("It is bound by a spirit contract[master_mind?.current ? " to [master_mind.current]" : ""].")

/datum/component/spirit_beast/proc/on_death(datum/source)
	SIGNAL_HANDLER
	var/mob/living/master = master_mind?.current
	if(master)
		to_chat(master, span_userdanger("You feel your spirit beast's life snuff out! Your contract shatters!"))
		master.add_mood_event("spirit_beast_died", /datum/mood_event/spirit_beast_died)
		var/datum/antagonist/cultivator/cultivation_datum = IS_CULTIVATOR(master)
		cultivation_datum?.adjust_instability(10)
	qdel(src)

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
	slot_flags = ITEM_SLOT_GLOVES
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
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "charge"
	background_icon_state = "bg_nature"
	overlay_icon_state = "bg_nature_border"
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
