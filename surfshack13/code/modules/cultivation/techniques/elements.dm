// Techniques for the Water, Fire, Earth and Wood laws, plus combination techniques.

// ===== Water: Still Water Scripture =====

/datum/action/cooldown/spell/pointed/cultivation/still_water_ward
	name = "Still Water Ward"
	desc = "Wrap yourself or an ally in a skin of perfectly still water that absorbs the next 30 damage (more at higher realms)."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "shield"
	cast_range = 3
	cooldown_time = 15 SECONDS
	qi_cost = 25

/datum/action/cooldown/spell/pointed/cultivation/still_water_ward/is_valid_target(atom/cast_on)
	return isliving(cast_on)

/datum/action/cooldown/spell/pointed/cultivation/still_water_ward/cast(mob/living/cast_on)
	. = ..()
	cast_on.visible_message(span_notice("A shimmering skin of water settles over [cast_on]."))
	playsound(cast_on, 'sound/effects/splash.ogg', 40, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/water(get_turf(cast_on))
	cast_on.apply_status_effect(/datum/status_effect/still_water_ward, 20 + 10 * cultivation_realm_of(owner))

/datum/action/cooldown/spell/pointed/cultivation/calm_heart
	name = "Calm Heart"
	desc = "Touch someone's mind with stillness. Shakes off stuns, dizziness, confusion and jitters."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "sacredflame"
	cast_range = 2
	cooldown_time = 20 SECONDS
	qi_cost = 20

/datum/action/cooldown/spell/pointed/cultivation/calm_heart/is_valid_target(atom/cast_on)
	return isliving(cast_on)

/datum/action/cooldown/spell/pointed/cultivation/calm_heart/cast(mob/living/cast_on)
	. = ..()
	new /obj/effect/temp_visual/circle_wave/cultivation/water(get_turf(cast_on))
	new /obj/effect/temp_visual/heal(get_turf(cast_on), "#4fb3ff")
	cast_on.AdjustAllImmobility(-4 SECONDS)
	cast_on.adjustStaminaLoss(-30)
	cast_on.remove_status_effect(/datum/status_effect/dizziness)
	cast_on.remove_status_effect(/datum/status_effect/confusion)
	cast_on.remove_status_effect(/datum/status_effect/jitter)
	cast_on.remove_status_effect(/datum/status_effect/cultivation_slow)
	to_chat(cast_on, span_nicegreen("A wave of calm washes through you. Your mind is as still as a lake at dawn."))
	cast_on.add_mood_event("calm_heart", /datum/mood_event/calm_heart)

/datum/mood_event/calm_heart
	description = "My heart is calm, like still water."
	mood_change = 3
	timeout = 3 MINUTES

/datum/action/cooldown/spell/cultivation/turtle_breathing
	name = "Turtle Breathing"
	desc = "Slow your breath until you need none at all. For half a minute you don't need to breathe and can endure the cold vacuum of space."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "bonechill"
	cooldown_time = 30 SECONDS
	qi_cost = 30

/datum/action/cooldown/spell/cultivation/turtle_breathing/cast(mob/living/cast_on)
	. = ..()
	to_chat(cast_on, span_notice("You slow your breathing... and then stop."))
	new /obj/effect/temp_visual/circle_wave/cultivation/water(get_turf(cast_on))
	cast_on.add_traits(list(TRAIT_NOBREATH, TRAIT_RESISTLOWPRESSURE, TRAIT_RESISTCOLD), REF(src))
	addtimer(CALLBACK(src, PROC_REF(breathe_again), cast_on), 30 SECONDS)

/datum/action/cooldown/spell/cultivation/turtle_breathing/proc/breathe_again(mob/living/user)
	user.remove_traits(list(TRAIT_NOBREATH, TRAIT_RESISTLOWPRESSURE, TRAIT_RESISTCOLD), REF(src))
	to_chat(user, span_warning("You draw a deep breath. Your turtle breathing ends."))

// ===== Fire: Furnace Heart Canon =====

/datum/action/cooldown/spell/pointed/cultivation/kindle
	name = "Kindle"
	desc = "Light something with a snap of your fingers. Candles, cigarettes, stoves... or people, if you're close enough."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "fireball0"
	cast_range = 3
	cooldown_time = 4 SECONDS
	qi_cost = 10

/datum/action/cooldown/spell/pointed/cultivation/kindle/is_valid_target(atom/cast_on)
	return ..() && !isturf(cast_on)

/datum/action/cooldown/spell/pointed/cultivation/kindle/cast(atom/cast_on)
	. = ..()
	owner.visible_message(span_warning("[owner] snaps [owner.p_their()] fingers, and a spark leaps to [cast_on]!"))
	owner.Beam(cast_on, icon_state = "lightning[rand(1, 12)]", time = 0.3 SECONDS)
	do_sparks(2, FALSE, cast_on)
	if(isliving(cast_on))
		if(get_dist(owner, cast_on) > 1)
			to_chat(owner, span_warning("Living things need a touch to catch."))
			return
		var/mob/living/victim = cast_on
		victim.apply_damage(5, BURN)
		victim.adjust_fire_stacks(3)
		victim.ignite_mob()
		return
	if(istype(cast_on, /obj/item/cigarette))
		var/obj/item/cigarette/cig = cast_on
		cig.light()
		return
	if(istype(cast_on, /obj/item/flashlight/flare))
		var/obj/item/flashlight/flare/flare = cast_on
		flare.ignition()
		return
	cast_on.fire_act(500, 10)

/datum/action/cooldown/spell/cultivation/furnace_burst
	name = "Furnace Burst"
	desc = "Stoke your inner furnace for a moment, then release a ring of fire around you. It's hot for you too."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "fireball"
	cooldown_time = 20 SECONDS
	qi_cost = 35

/datum/action/cooldown/spell/cultivation/furnace_burst/cast(mob/living/cast_on)
	. = ..()
	cast_on.visible_message(span_boldwarning("[cast_on] glows red-hot, heat shimmering around [cast_on.p_them()]!"), span_warning("You stoke your inner furnace..."))
	cast_on.add_filter("furnace_burst", 2, list("type" = "outline", "color" = "#ff5a1f", "size" = 2))
	var/list/turfs = list()
	for(var/turf/open/nearby in range(2, cast_on))
		if(nearby == get_turf(cast_on))
			continue
		turfs += nearby
		new /obj/effect/temp_visual/cultivation_telegraph/fire(nearby)
	addtimer(CALLBACK(src, PROC_REF(burst), cast_on, turfs), 1.5 SECONDS)

/datum/action/cooldown/spell/cultivation/furnace_burst/proc/burst(mob/living/user, list/turfs)
	user.remove_filter("furnace_burst")
	if(QDELETED(user) || user.stat == DEAD)
		return
	playsound(user, 'sound/effects/magic/fireball.ogg', 60, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/fire(get_turf(user))
	user.Shake(2, 2, 0.5 SECONDS)
	for(var/turf/open/target_turf as anything in turfs)
		new /obj/effect/hotspot(target_turf)
		target_turf.hotspot_expose(700, 50, 1)
		for(var/mob/living/victim in target_turf)
			victim.apply_damage(8 + 3 * cultivation_realm_of(user), BURN)
			victim.adjust_fire_stacks(2)
			victim.ignite_mob()
	user.apply_damage(5, BURN)
	to_chat(user, span_warning("The heat sears your own meridians."))

/datum/action/cooldown/spell/cultivation/burning_blood
	name = "Burning Blood Essence"
	desc = "The desperate technique. Burn your own blood essence for a flood of qi and speed. It hurts."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "exsanguinating_strike"
	cooldown_time = 60 SECONDS
	qi_cost = 0

/datum/action/cooldown/spell/cultivation/burning_blood/cast(mob/living/cast_on)
	. = ..()
	cast_on.visible_message(span_danger("[cast_on] coughs up blood as a crimson aura flares around [cast_on.p_them()]!"), span_userdanger("You burn your blood essence!"))
	cast_on.apply_damage(25, BRUTE, BODY_ZONE_CHEST)
	new /obj/effect/temp_visual/circle_wave/cultivation/blood(get_turf(cast_on))
	new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(cast_on), pick(GLOB.alldirs))
	var/datum/antagonist/cultivator/cultivation_datum = IS_CULTIVATOR(cast_on)
	cultivation_datum?.adjust_qi(60)
	cast_on.apply_status_effect(/datum/status_effect/burning_blood)

// ===== Earth: Rooted Mountain Manual =====

/datum/action/cooldown/spell/cultivation/rooted_stance
	name = "Rooted Stance"
	desc = "Sink into the stance of a mountain for 10 seconds. You walk slowly, but can't be shoved, slipped or stunned, take 40% less damage \
		and slowly mend. Use again to end it early."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "statue"
	cooldown_time = 20 SECONDS
	qi_cost = 20

/datum/action/cooldown/spell/cultivation/rooted_stance/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	var/mob/living/user = owner
	if(user.has_status_effect(/datum/status_effect/rooted_stance))
		user.remove_status_effect(/datum/status_effect/rooted_stance)
		return . | SPELL_CANCEL_CAST

/datum/action/cooldown/spell/cultivation/rooted_stance/cast(mob/living/cast_on)
	. = ..()
	cast_on.visible_message(span_notice("[cast_on] sinks into a deep stance, as immovable as a mountain."))
	new /obj/effect/temp_visual/circle_wave/cultivation/earth(get_turf(cast_on))
	new /obj/effect/temp_visual/mook_dust(get_turf(cast_on))
	cast_on.apply_status_effect(/datum/status_effect/rooted_stance)

/datum/action/cooldown/spell/cultivation/golden_bell
	name = "Golden Bell Shield"
	desc = "Wrap yourself in a bell of golden qi. For a few seconds (longer at higher realms) you take no damage, can't be stunned, \
		and anyone who hits you bounces off. You can't move while inside it."
	button_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "berserk_mode"
	cooldown_time = 20 SECONDS
	qi_cost = 30

/datum/action/cooldown/spell/cultivation/golden_bell/cast(mob/living/cast_on)
	. = ..()
	cast_on.visible_message(span_boldwarning("A great golden bell of qi descends over [cast_on] with a deep GONG!"))
	playsound(cast_on, 'sound/effects/gong.ogg', 60, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/gold(get_turf(cast_on))
	cast_on.apply_status_effect(/datum/status_effect/golden_bell, 4 SECONDS + cultivation_realm_of(cast_on) * 1 SECONDS)

/datum/action/cooldown/spell/cultivation/dharma_idol
	name = "Dharma Idol"
	desc = "Project a towering golden Buddha behind you for 15 seconds. You grow larger, take less damage, can't be shoved, \
		and your combat-mode punches become giant golden palms that hurl people away and smash structures."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "barn"
	cooldown_time = 60 SECONDS
	qi_cost = 60

/datum/action/cooldown/spell/cultivation/dharma_idol/cast(mob/living/cast_on)
	. = ..()
	new /obj/effect/temp_visual/circle_wave/cultivation/gold/big(get_turf(cast_on))
	cultivation_temple_sound(cast_on, 80)
	playsound(cast_on, 'sound/effects/gong.ogg', 90, TRUE, frequency = 0.5)
	playsound(cast_on, 'sound/effects/magic/clockwork/ark_activation.ogg', 40, TRUE)
	cast_on.Shake(2, 2, 0.8 SECONDS)
	cast_on.apply_status_effect(/datum/status_effect/dharma_idol)

// ===== Wood: Evergreen Spring Classic =====

/datum/action/cooldown/spell/pointed/cultivation/spring_mending
	name = "Spring Mending"
	desc = "Channel spring qi into someone beside you: heals brute and (extra) burn damage and closes their worst wound, \
		up to severe at Foundation and critical at Golden Core. Half as strong on yourself."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "nose"
	cast_range = 1
	cooldown_time = 5 SECONDS
	qi_cost = 20

/datum/action/cooldown/spell/pointed/cultivation/spring_mending/is_valid_target(atom/cast_on)
	return isliving(cast_on)

/datum/action/cooldown/spell/pointed/cultivation/spring_mending/cast(mob/living/cast_on)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(mend), owner, cast_on)

/datum/action/cooldown/spell/pointed/cultivation/spring_mending/proc/mend(mob/living/healer, mob/living/patient)
	healer.visible_message(span_notice("[healer] rests a glowing green hand on [patient]."))
	patient.add_filter("spring_mending", 2, list("type" = "outline", "color" = "#5fd35f", "size" = 1))
	var/success = do_after(healer, 5 SECONDS, patient)
	patient.remove_filter("spring_mending")
	if(!success)
		return
	var/realm = cultivation_realm_of(healer)
	var/amount = 15 + 5 * realm
	if(patient == healer)
		amount = round(amount / 2)
	patient.heal_overall_damage(brute = amount, burn = round(amount * 1.25))
	var/max_severity = realm >= REALM_GOLDEN_CORE ? WOUND_SEVERITY_CRITICAL : (realm >= REALM_FOUNDATION ? WOUND_SEVERITY_SEVERE : WOUND_SEVERITY_MODERATE)
	cultivation_mend_wounds(patient, max_severity, 1)
	new /obj/effect/temp_visual/heal(get_turf(patient), "#5fd35f")
	new /obj/effect/temp_visual/circle_wave/cultivation/wood(get_turf(patient))
	to_chat(patient, span_nicegreen("Warm spring qi knits your wounds together."))
	if(patient != healer)
		var/datum/antagonist/cultivator/cultivation_datum = IS_CULTIVATOR(healer)
		cultivation_datum?.notify_laws(INSIGHT_SOURCE_SURGERY, patient)

/datum/action/cooldown/spell/cultivation/verdant_growth
	name = "Verdant Growth"
	desc = "Pour wood qi into the plants around you. Nearby trays grow faster, heal, and lose their weeds and pests."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "bee"
	cooldown_time = 30 SECONDS
	qi_cost = 20

/datum/action/cooldown/spell/cultivation/verdant_growth/cast(mob/living/cast_on)
	. = ..()
	var/count = 0
	for(var/obj/machinery/hydroponics/tray in view(3, cast_on))
		if(!tray.myseed || tray.plant_status == HYDROTRAY_PLANT_DEAD)
			continue
		tray.age += 3
		tray.set_weedlevel(0)
		tray.set_pestlevel(0)
		tray.set_plant_health(tray.myseed.endurance)
		new /obj/effect/temp_visual/heal(get_turf(tray), "#5fd35f")
		count++
	if(count)
		new /obj/effect/temp_visual/circle_wave/tree/healer(get_turf(cast_on))
		cast_on.visible_message(span_notice("The plants around [cast_on] stretch and bloom!"))
	else
		to_chat(cast_on, span_warning("There are no living plants nearby to nourish."))

/datum/action/cooldown/spell/pointed/cultivation/binding_vines
	name = "Binding Vines"
	desc = "Command vines to burst from the floor and hold someone in place for a few seconds."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "the_traps"
	cast_range = 6
	cooldown_time = 18 SECONDS
	qi_cost = 30

/datum/action/cooldown/spell/pointed/cultivation/binding_vines/is_valid_target(atom/cast_on)
	return ..() && isliving(cast_on)

/datum/action/cooldown/spell/pointed/cultivation/binding_vines/cast(mob/living/cast_on)
	. = ..()
	cast_on.visible_message(span_danger("Vines erupt from the floor and wrap around [cast_on]!"), span_userdanger("Vines seize your legs!"))
	new /obj/effect/temp_visual/circle_wave/cultivation/wood(get_turf(cast_on))
	playsound(cast_on, 'sound/effects/bush/crunchybushwhack2.ogg', 60, TRUE)
	var/realm_gap = cultivation_realm_of(owner) - cultivation_realm_of(cast_on)
	var/hold_time = clamp(2.5 SECONDS + realm_gap * 0.5 SECONDS, 1.5 SECONDS, 4 SECONDS)
	cast_on.Immobilize(hold_time)
	new /obj/effect/temp_visual/cultivation_vines(get_turf(cast_on), hold_time)

// ===== Combination techniques =====

/datum/action/cooldown/spell/cultivation/steam_veil
	name = "Steam Veil"
	desc = "Fire and water meet: a billowing cloud of steam hides you."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "smoke"
	cooldown_time = 20 SECONDS
	qi_cost = 25

/datum/action/cooldown/spell/cultivation/steam_veil/cast(mob/living/cast_on)
	. = ..()
	cast_on.visible_message(span_warning("Steam explodes outward from [cast_on]!"))
	playsound(cast_on, 'sound/effects/bubbles/bubbles.ogg', 50, TRUE)
	do_smoke(3, holder = cast_on, location = get_turf(cast_on))

/datum/action/cooldown/spell/pointed/cultivation/thousand_thorns
	name = "Thousand Thorn Swords"
	desc = "Metal and wood meet: a rippling fan of five iron-hard thorn swords that pierce and stagger whoever they hit."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "magicm"
	cast_range = 6
	cooldown_time = 12 SECONDS
	qi_cost = 30

/datum/action/cooldown/spell/pointed/cultivation/thousand_thorns/is_valid_target(atom/cast_on)
	return TRUE

/datum/action/cooldown/spell/pointed/cultivation/thousand_thorns/cast(atom/cast_on)
	. = ..()
	var/mob/living/user = owner
	user.visible_message(span_warning("[user] sweeps an arm and a fan of iron-hard thorn swords bursts from the air!"))
	playsound(user, 'sound/effects/bush/crunchybushwhack1.ogg', 50, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/wood(get_turf(user))
	var/turf/aim_turf = get_turf(cast_on)
	var/list/spreads = list(-24, -12, 0, 12, 24)
	for(var/i in 1 to length(spreads))
		addtimer(CALLBACK(src, PROC_REF(fire_thorn), user, aim_turf, spreads[i]), (i - 1) * 0.06 SECONDS)

/datum/action/cooldown/spell/pointed/cultivation/thousand_thorns/proc/fire_thorn(mob/living/user, turf/aim_turf, spread)
	if(QDELETED(user) || user.stat != CONSCIOUS)
		return
	var/obj/projectile/cultivation_thorn/thorn = new(get_turf(user))
	thorn.aim_projectile(aim_turf, user, deviation = spread)
	thorn.firer = user
	thorn.fired_from = user
	thorn.damage = 6 + cultivation_realm_of(user)
	playsound(user, 'sound/items/weapons/fwoosh.ogg', 25, TRUE, frequency = 1.4)
	thorn.fire()

/obj/projectile/cultivation_thorn
	name = "thorn sword"
	icon = 'surfshack13/icons/cultivation/cultivation_effects.dmi'
	icon_state = "thorn_sword"
	damage = 6
	damage_type = BRUTE
	sharpness = SHARP_POINTY
	armour_penetration = 15
	wound_bonus = 5
	range = 7
	speed = 1.6
	hitsound = 'sound/items/weapons/pierce.ogg'
	impact_effect_type = /obj/effect/temp_visual/impact_effect/cultivation_thorn

/obj/projectile/cultivation_thorn/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	if(isturf(old_loc))
		var/obj/effect/temp_visual/decoy/fading/trail = new(old_loc, src)
		trail.alpha = 100
		trail.color = "#9fe08a"
		animate(trail, alpha = 0, time = 0.2 SECONDS)
		QDEL_IN(trail, 0.2 SECONDS)

/obj/projectile/cultivation_thorn/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	new /obj/effect/temp_visual/impact_effect/cultivation_thorn(get_turf(target), 0, 0)
	if(isliving(target) && !blocked)
		var/mob/living/victim = target
		victim.adjust_staggered_up_to(STAGGERED_SLOWDOWN_LENGTH, 6 SECONDS)

/obj/effect/temp_visual/impact_effect/cultivation_thorn
	icon = 'surfshack13/icons/cultivation/cultivation_effects.dmi'
	icon_state = "thorn_splinters"
	duration = 0.5 SECONDS

/datum/action/cooldown/spell/cultivation/molten_step
	name = "Molten Step"
	desc = "Earth and fire meet: for 8 seconds every step leaves glowing magma footprints behind you. They burn anyone who walks on them until they cool."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "firebeam"
	cooldown_time = 20 SECONDS
	qi_cost = 25

/datum/action/cooldown/spell/cultivation/molten_step/cast(mob/living/cast_on)
	. = ..()
	cast_on.visible_message(span_warning("[cast_on]'s footsteps begin to glow like magma!"))
	cast_on.apply_status_effect(/datum/status_effect/molten_step)

/datum/action/cooldown/spell/pointed/cultivation/mud_prison
	name = "Mud Prison"
	desc = "Water and earth meet: turn a 3x3 area into bubbling mud for 6 seconds. Anyone wading through is slowed, and whoever stands at the centre is stuck for a moment."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "snow"
	cast_range = 6
	cooldown_time = 18 SECONDS
	qi_cost = 25
	aim_assist = FALSE

/datum/action/cooldown/spell/pointed/cultivation/mud_prison/is_valid_target(atom/cast_on)
	return TRUE

/datum/action/cooldown/spell/pointed/cultivation/mud_prison/cast(atom/cast_on)
	. = ..()
	var/turf/center = get_turf(cast_on)
	playsound(center, 'sound/effects/splash.ogg', 60, TRUE, frequency = 0.6)
	playsound(center, 'sound/effects/bubbles/bubbles.ogg', 50, TRUE)
	new /obj/effect/temp_visual/circle_wave/cultivation/earth(center)
	for(var/turf/open/mud_turf in range(1, center))
		if(locate(/obj/effect/cultivation_mud) in mud_turf)
			continue
		new /obj/effect/cultivation_mud(mud_turf, owner, 6 SECONDS)
	// Whoever stands at the heart of it sinks to the knees
	for(var/mob/living/victim in center)
		if(victim == owner)
			continue
		victim.Immobilize(1.5 SECONDS)
		to_chat(victim, span_userdanger("The floor turns to mud and swallows your legs!"))

// ===== Visuals =====

/obj/effect/temp_visual/cultivation_telegraph
	icon = 'icons/mob/telegraphing/telegraph_holographic.dmi'
	icon_state = "target_circle"
	duration = 1.5 SECONDS

/obj/effect/temp_visual/cultivation_telegraph/fire
	color = "#ff7a1f"

/obj/effect/temp_visual/cultivation_telegraph/vines
	color = "#3fa83f"
	duration = 3 SECONDS

/obj/effect/temp_visual/cultivation_telegraph/mud
	color = "#6b4a2b"
	duration = 5 SECONDS

/obj/effect/temp_visual/cultivation_vines
	name = "binding vines"
	icon = 'surfshack13/icons/cultivation/cultivation_terrain.dmi'
	icon_state = "vines_grow"
	layer = ABOVE_MOB_LAYER
	duration = 3 SECONDS

/obj/effect/temp_visual/cultivation_vines/Initialize(mapload, hold_time = 3 SECONDS)
	duration = hold_time
	. = ..()
	addtimer(VARSET_CALLBACK(src, icon_state, "vines_sway"), 0.5 SECONDS)
	animate(src, alpha = 255, time = hold_time - 0.4 SECONDS)
	animate(alpha = 0, time = 0.4 SECONDS)

// ----- Mud: a lasting pool that slows anyone wading through -----

/obj/effect/cultivation_mud
	name = "sucking mud"
	desc = "Thick, bubbling mud. Your feet sink into it."
	icon = 'surfshack13/icons/cultivation/cultivation_terrain.dmi'
	icon_state = "mud"
	layer = BELOW_OBJ_LAYER
	plane = FLOOR_PLANE
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	alpha = 0
	/// The mud's maker wades through freely
	var/datum/weakref/maker_ref

/obj/effect/cultivation_mud/Initialize(mapload, mob/living/maker, lifetime = 6 SECONDS)
	. = ..()
	maker_ref = WEAKREF(maker)
	animate(src, alpha = 230, time = 0.4 SECONDS)
	START_PROCESSING(SSfastprocess, src)
	addtimer(CALLBACK(src, PROC_REF(dry_up)), lifetime)

/obj/effect/cultivation_mud/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	return ..()

/obj/effect/cultivation_mud/process(seconds_per_tick)
	var/mob/living/maker = maker_ref?.resolve()
	for(var/mob/living/wader in loc)
		if(wader == maker || (wader.movement_type & (FLYING|FLOATING)))
			continue
		wader.apply_status_effect(/datum/status_effect/cultivation_slow, 1 SECONDS)

/obj/effect/cultivation_mud/proc/dry_up()
	STOP_PROCESSING(SSfastprocess, src)
	animate(src, alpha = 0, time = 0.6 SECONDS)
	QDEL_IN(src, 0.6 SECONDS)

// ----- Molten footprints: glowing magma steps that cool to black -----

/obj/effect/cultivation_molten_step
	name = "molten footprints"
	desc = "Footprints of glowing magma, slowly cooling."
	icon = 'surfshack13/icons/cultivation/cultivation_terrain.dmi'
	icon_state = "molten_steps"
	layer = BELOW_OBJ_LAYER
	plane = FLOOR_PLANE
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	light_system = OVERLAY_LIGHT
	light_range = 1.5
	light_power = 1.2
	light_color = "#ff7a2c"
	var/datum/weakref/maker_ref
	/// Still hot enough to hurt
	var/hot = TRUE

/obj/effect/cultivation_molten_step/Initialize(mapload, mob/living/maker)
	. = ..()
	maker_ref = WEAKREF(maker)
	var/static/list/connections = list(COMSIG_ATOM_ENTERED = PROC_REF(on_entered))
	AddElement(/datum/element/connect_loc, connections)
	addtimer(CALLBACK(src, PROC_REF(cool)), 4 SECONDS)
	QDEL_IN(src, 10 SECONDS)

/obj/effect/cultivation_molten_step/proc/cool()
	hot = FALSE
	set_light_on(FALSE)

/obj/effect/cultivation_molten_step/proc/on_entered(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER
	if(!hot || !isliving(arrived) || arrived == maker_ref?.resolve())
		return
	var/mob/living/burned = arrived
	if(burned.movement_type & (FLYING|FLOATING))
		return
	burned.apply_damage(8, BURN, pick(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
	burned.adjust_fire_stacks(1)
	burned.ignite_mob()
	to_chat(burned, span_userdanger("You step in glowing magma!"))
	playsound(burned, 'sound/effects/wounds/sizzle1.ogg', 50, TRUE)
