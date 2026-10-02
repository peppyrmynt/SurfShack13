// Techniques for the Water, Fire, Earth and Wood laws, plus combination techniques.

// ===== Water: Still Water Scripture =====

/datum/action/cooldown/spell/pointed/cultivation/still_water_ward
	name = "Still Water Ward"
	desc = "Wrap yourself or an ally in a skin of perfectly still water that absorbs the next 30 damage."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "shield"
	cast_range = 3
	cooldown_time = 30 SECONDS
	qi_cost = 25

/datum/action/cooldown/spell/pointed/cultivation/still_water_ward/is_valid_target(atom/cast_on)
	return isliving(cast_on)

/datum/action/cooldown/spell/pointed/cultivation/still_water_ward/cast(mob/living/cast_on)
	. = ..()
	cast_on.visible_message(span_notice("A shimmering skin of water settles over [cast_on]."))
	playsound(cast_on, 'sound/effects/splash.ogg', 40, TRUE)
	cast_on.apply_status_effect(/datum/status_effect/still_water_ward)

/datum/action/cooldown/spell/pointed/cultivation/calm_heart
	name = "Calm Heart"
	desc = "Touch someone's mind with stillness. Shakes off stuns, dizziness, confusion and jitters."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "sacredflame"
	cast_range = 2
	cooldown_time = 40 SECONDS
	qi_cost = 20

/datum/action/cooldown/spell/pointed/cultivation/calm_heart/is_valid_target(atom/cast_on)
	return isliving(cast_on)

/datum/action/cooldown/spell/pointed/cultivation/calm_heart/cast(mob/living/cast_on)
	. = ..()
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
	desc = "Slow your breath until you need none at all. For half a minute you don't need to breathe."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "bonechill"
	cooldown_time = 60 SECONDS
	qi_cost = 30

/datum/action/cooldown/spell/cultivation/turtle_breathing/cast(mob/living/cast_on)
	. = ..()
	to_chat(cast_on, span_notice("You slow your breathing... and then stop."))
	ADD_TRAIT(cast_on, TRAIT_NOBREATH, REF(src))
	addtimer(CALLBACK(src, PROC_REF(breathe_again), cast_on), 30 SECONDS)

/datum/action/cooldown/spell/cultivation/turtle_breathing/proc/breathe_again(mob/living/user)
	REMOVE_TRAIT(user, TRAIT_NOBREATH, REF(src))
	to_chat(user, span_warning("You draw a deep breath. Your turtle breathing ends."))

// ===== Fire: Furnace Heart Canon =====

/datum/action/cooldown/spell/pointed/cultivation/kindle
	name = "Kindle"
	desc = "Light something with a snap of your fingers. Candles, cigarettes, stoves... or people, if you're close enough."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "fireball0"
	cast_range = 3
	cooldown_time = 10 SECONDS
	qi_cost = 10

/datum/action/cooldown/spell/pointed/cultivation/kindle/is_valid_target(atom/cast_on)
	return !isturf(cast_on)

/datum/action/cooldown/spell/pointed/cultivation/kindle/cast(atom/cast_on)
	. = ..()
	owner.visible_message(span_warning("[owner] snaps [owner.p_their()] fingers, and a spark leaps to [cast_on]!"))
	if(isliving(cast_on))
		if(get_dist(owner, cast_on) > 1)
			to_chat(owner, span_warning("Living things need a touch to catch."))
			return
		var/mob/living/victim = cast_on
		victim.adjust_fire_stacks(2)
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
	cooldown_time = 40 SECONDS
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
	for(var/turf/open/target_turf as anything in turfs)
		new /obj/effect/hotspot(target_turf)
		target_turf.hotspot_expose(700, 50, 1)
		for(var/mob/living/victim in target_turf)
			victim.apply_damage(10, BURN)
			victim.adjust_fire_stacks(2)
			victim.ignite_mob()
	user.apply_damage(5, BURN)
	to_chat(user, span_warning("The heat sears your own meridians."))

/datum/action/cooldown/spell/cultivation/burning_blood
	name = "Burning Blood Essence"
	desc = "The desperate technique. Burn your own blood essence for a flood of qi and speed. It hurts."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "exsanguinating_strike"
	cooldown_time = 120 SECONDS
	qi_cost = 0

/datum/action/cooldown/spell/cultivation/burning_blood/cast(mob/living/cast_on)
	. = ..()
	cast_on.visible_message(span_danger("[cast_on] coughs up blood as a crimson aura flares around [cast_on.p_them()]!"), span_userdanger("You burn your blood essence!"))
	cast_on.apply_damage(25, BRUTE, BODY_ZONE_CHEST)
	var/datum/antagonist/cultivator/cultivation_datum = IS_CULTIVATOR(cast_on)
	cultivation_datum?.adjust_qi(60)
	cast_on.apply_status_effect(/datum/status_effect/burning_blood)

// ===== Earth: Rooted Mountain Manual =====

/datum/action/cooldown/spell/cultivation/rooted_stance
	name = "Rooted Stance"
	desc = "Plant yourself like a mountain. You can't move, but nothing can push, slip or drag you for 10 seconds."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "statue"
	cooldown_time = 20 SECONDS
	qi_cost = 15

/datum/action/cooldown/spell/cultivation/rooted_stance/cast(mob/living/cast_on)
	. = ..()
	cast_on.visible_message(span_notice("[cast_on] sinks into a deep stance, as immovable as a mountain."))
	cast_on.apply_status_effect(/datum/status_effect/rooted_stance)

/datum/action/cooldown/spell/cultivation/golden_bell
	name = "Golden Bell Shield"
	desc = "Wrap yourself in a bell of golden qi. For 5 seconds you shrug off most damage, but can't move."
	button_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "berserk_mode"
	cooldown_time = 45 SECONDS
	qi_cost = 30

/datum/action/cooldown/spell/cultivation/golden_bell/cast(mob/living/cast_on)
	. = ..()
	cast_on.visible_message(span_boldwarning("A great golden bell of qi descends over [cast_on] with a deep GONG!"))
	playsound(cast_on, 'sound/effects/gong.ogg', 60, TRUE)
	cast_on.apply_status_effect(/datum/status_effect/golden_bell)

/datum/action/cooldown/spell/cultivation/dharma_idol
	name = "Dharma Idol"
	desc = "Manifest a towering golden idol around yourself. You grow huge, sturdy and impossible to shove for 15 seconds, at the cost of speed."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "barn"
	cooldown_time = 120 SECONDS
	qi_cost = 60

/datum/action/cooldown/spell/cultivation/dharma_idol/cast(mob/living/cast_on)
	. = ..()
	cast_on.apply_status_effect(/datum/status_effect/dharma_idol)

// ===== Wood: Evergreen Spring Classic =====

/datum/action/cooldown/spell/pointed/cultivation/spring_mending
	name = "Spring Mending"
	desc = "Channel spring qi into someone beside you, slowly closing wounds and burns. Weaker on yourself."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "nose"
	cast_range = 1
	cooldown_time = 10 SECONDS
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
	var/amount = (patient == healer) ? 7 : 15
	patient.heal_overall_damage(brute = amount, burn = amount)
	to_chat(patient, span_nicegreen("Warm spring qi knits your wounds together."))
	if(patient != healer)
		var/datum/antagonist/cultivator/cultivation_datum = IS_CULTIVATOR(healer)
		cultivation_datum?.notify_laws(INSIGHT_SOURCE_SURGERY, patient)

/datum/action/cooldown/spell/cultivation/verdant_growth
	name = "Verdant Growth"
	desc = "Pour wood qi into the plants around you. Nearby trays grow faster, heal, and lose their weeds and pests."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "bee"
	cooldown_time = 60 SECONDS
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
		cast_on.visible_message(span_notice("The plants around [cast_on] stretch and bloom!"))
	else
		to_chat(cast_on, span_warning("There are no living plants nearby to nourish."))

/datum/action/cooldown/spell/pointed/cultivation/binding_vines
	name = "Binding Vines"
	desc = "Command vines to burst from the floor and hold someone in place for a few seconds."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "the_traps"
	cast_range = 6
	cooldown_time = 40 SECONDS
	qi_cost = 30

/datum/action/cooldown/spell/pointed/cultivation/binding_vines/is_valid_target(atom/cast_on)
	return ..() && isliving(cast_on)

/datum/action/cooldown/spell/pointed/cultivation/binding_vines/cast(mob/living/cast_on)
	. = ..()
	cast_on.visible_message(span_danger("Vines erupt from the floor and wrap around [cast_on]!"), span_userdanger("Vines seize your legs!"))
	new /obj/effect/temp_visual/cultivation_telegraph/vines(get_turf(cast_on))
	var/realm_gap = cultivation_realm_of(owner) - cultivation_realm_of(cast_on)
	cast_on.Immobilize(clamp(2.5 SECONDS + realm_gap * 0.5 SECONDS, 1.5 SECONDS, 4 SECONDS))

// ===== Combination techniques =====

/datum/action/cooldown/spell/cultivation/steam_veil
	name = "Steam Veil"
	desc = "Fire and water meet: a billowing cloud of steam hides you."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "smoke"
	cooldown_time = 45 SECONDS
	qi_cost = 25

/datum/action/cooldown/spell/cultivation/steam_veil/cast(mob/living/cast_on)
	. = ..()
	cast_on.visible_message(span_warning("Steam explodes outward from [cast_on]!"))
	playsound(cast_on, 'sound/effects/bubbles/bubbles.ogg', 50, TRUE)
	do_smoke(3, holder = cast_on, location = get_turf(cast_on))

/datum/action/cooldown/spell/pointed/cultivation/thousand_thorns
	name = "Thousand Thorn Swords"
	desc = "Metal and wood meet: a fan of iron-hard splinters."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "magicm"
	cast_range = 6
	cooldown_time = 30 SECONDS
	qi_cost = 30

/datum/action/cooldown/spell/pointed/cultivation/thousand_thorns/is_valid_target(atom/cast_on)
	return TRUE

/datum/action/cooldown/spell/pointed/cultivation/thousand_thorns/cast(atom/cast_on)
	. = ..()
	var/mob/living/user = owner
	for(var/spread in list(-20, -10, 0, 10, 20))
		var/obj/projectile/cultivation_thorn/thorn = new(get_turf(user))
		thorn.aim_projectile(cast_on, user, deviation = spread)
		thorn.firer = user
		thorn.fired_from = user
		thorn.fire()
	playsound(user, 'sound/items/weapons/fwoosh.ogg', 50, TRUE)

/obj/projectile/cultivation_thorn
	name = "thorn sword"
	icon = 'icons/obj/weapons/guns/projectiles.dmi'
	icon_state = "seedling"
	damage = 6
	damage_type = BRUTE
	sharpness = SHARP_POINTY
	range = 6

/datum/action/cooldown/spell/cultivation/molten_step
	name = "Molten Step"
	desc = "Earth and fire meet: for a few seconds, every step you take leaves burning ground behind you. Your feet are fine."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "firebeam"
	cooldown_time = 40 SECONDS
	qi_cost = 25

/datum/action/cooldown/spell/cultivation/molten_step/cast(mob/living/cast_on)
	. = ..()
	cast_on.visible_message(span_warning("[cast_on]'s footsteps begin to glow like magma!"))
	cast_on.apply_status_effect(/datum/status_effect/molten_step)

/datum/action/cooldown/spell/pointed/cultivation/mud_prison
	name = "Mud Prison"
	desc = "Water and earth meet: turn the floor around a point into sucking mud, slowing everyone in it."
	button_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "snow"
	cast_range = 6
	cooldown_time = 40 SECONDS
	qi_cost = 25
	aim_assist = FALSE

/datum/action/cooldown/spell/pointed/cultivation/mud_prison/is_valid_target(atom/cast_on)
	return TRUE

/datum/action/cooldown/spell/pointed/cultivation/mud_prison/cast(atom/cast_on)
	. = ..()
	var/turf/center = get_turf(cast_on)
	for(var/turf/open/mud_turf in range(1, center))
		new /obj/effect/temp_visual/cultivation_telegraph/mud(mud_turf)
		for(var/mob/living/victim in mud_turf)
			if(victim == owner)
				continue
			victim.apply_status_effect(/datum/status_effect/cultivation_slow, 5 SECONDS)
			to_chat(victim, span_warning("The floor turns to sucking mud under your feet!"))

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
