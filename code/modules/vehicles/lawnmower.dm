/obj/vehicle/ridden/lawnmower
	name = "lawn mower"
	desc = "Equipped with reliable safeties to prevent <i>accidents</i> in the workplace."
	icon = 'icons/obj/vehicles/lawnmower.dmi'
	icon_state = "lawnmower"
	var/emagged = FALSE
	var/list/drive_sounds = list('sound/vehicles/mowermove1.ogg', 'sound/vehicles/mowermove2.ogg')
	var/list/gib_sounds = list('sound/vehicles/mowermovesquish.ogg')
	var/hit_sound = 'sound/items/weapons/chainsawhit.ogg'

// Blood tracks from the mower should stay wheel tracks instead of bloodying the rider's shoes.
/obj/effect/decal/cleanable/blood/tracks/lawnmower
	bloodiness = 0
	should_dry = FALSE

/obj/vehicle/ridden/lawnmower/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/ridable, /datum/component/riding/vehicle/lawnmower)

/obj/vehicle/ridden/lawnmower/emagged
	name = "Blood Red Lawnmower"
	desc = "A viciously modified lawn mower, painted blood red and stripped of every sensible safety feature. The blades look hungry."
	icon_state = "lawnmoweremag"
	emagged = TRUE

/obj/vehicle/ridden/lawnmower/emag_act(mob/user)
	if(emagged)
		to_chat(user, span_warning("The safety mechanisms on [src] are already disabled!"))
		return
	to_chat(user, span_warning("You disable the safety mechanisms on [src]."))
	emagged = TRUE
	name = "Blood Red Lawnmower"
	desc = "A viciously modified lawn mower, painted blood red and stripped of every sensible safety feature. The blades look hungry."
	icon_state = "lawnmoweremag"

/obj/vehicle/ridden/lawnmower/Bump(atom/bumped_thing)
	if(emagged && isliving(bumped_thing))
		var/mob/living/victim = bumped_thing
		victim.adjustBruteLoss(25)
		playsound(victim, 'sound/effects/hit_kick.ogg', 50, TRUE)
		var/atom/new_loc = get_edge_target_turf(victim, get_dir(src, get_step_away(victim, src)))
		victim.throw_at(new_loc, 4, 1)
	return ..()

/obj/vehicle/ridden/lawnmower/Moved(atom/old_loc, movement_dir, forced, list/old_locs, momentum_change = TRUE)
	. = ..()
	var/mob/living/carbon/human/rider
	if(has_buckled_mobs())
		rider = buckled_mobs[1]

	var/gibbed = FALSE
	for(var/obj/structure/flora/grass/grass in loc)
		qdel(grass)

	if(!emagged)
		playsound(loc, pick(drive_sounds), 75, TRUE)
		return

	for(var/mob/living/simple_animal/bot/secbot/secbot in loc)
		visible_message(span_danger("[src] shreds [secbot] into scrap!"))
		playsound(loc, hit_sound, 50, TRUE)
		secbot.gib()
		gibbed = TRUE

	for(var/mob/living/dead_mob in loc)
		if(dead_mob == rider || dead_mob.stat != DEAD)
			continue
		// Only dead zombie humans are gibbed; dead animals are handled below.
		if(ishuman(dead_mob))
			var/mob/living/carbon/human/dead_human = dead_mob
			if(!iszombie(dead_human) && !is_species(dead_human, /datum/species/human/krokodil_addict))
				continue
		visible_message(span_danger("[src] grinds [dead_mob] into a fine paste!"))
		playsound(loc, hit_sound, 50, TRUE)
		add_mob_blood(dead_mob)
		var/turf/below_dead_mob = get_turf(src)
		below_dead_mob.add_mob_blood(dead_mob)
		AddComponent(/datum/component/blood_walk, \
			blood_type = /obj/effect/decal/cleanable/blood/tracks/lawnmower, \
			target_dir_change = TRUE, \
			transfer_blood_dna = TRUE, \
			max_blood = 4)
		dead_mob.gib()
		gibbed = TRUE

	for(var/mob/living/carbon/human/victim in loc)
		if(victim == rider || victim.stat == DEAD)
			continue
		if(victim.body_position == LYING_DOWN)
			if(iszombie(victim) || is_species(victim, /datum/species/human/krokodil_addict))
				visible_message(span_danger("[src] grinds [victim] into a fine paste!"))
				playsound(loc, hit_sound, 50, TRUE)
				add_mob_blood(victim)
				var/turf/below_us = get_turf(src)
				below_us.add_mob_blood(victim)
				AddComponent(/datum/component/blood_walk, \
					blood_type = /obj/effect/decal/cleanable/blood/tracks/lawnmower, \
					target_dir_change = TRUE, \
					transfer_blood_dna = TRUE, \
					max_blood = 4)
				victim.gib()
				shake_camera(victim, 20, 1)
				gibbed = TRUE
				continue
			visible_message(span_danger("[src] crushes [victim] like a garden shredder!"))
			playsound(loc, hit_sound, 50, TRUE)
			add_mob_blood(victim)
			var/turf/below_us = get_turf(src)
			below_us.add_mob_blood(victim)
			AddComponent(/datum/component/blood_walk, \
				blood_type = /obj/effect/decal/cleanable/blood/tracks/lawnmower, \
				target_dir_change = TRUE, \
				transfer_blood_dna = TRUE, \
				max_blood = 4)
			if(iscarbon(victim) && victim.stat < UNCONSCIOUS)
				victim.say("ARRRRRRRRRRRGH!!!", forced = "lawn mower grinding")
			add_mob_blood(victim)
			victim.Unconscious(100)
			victim.adjustBruteLoss(1000)
			gibbed = TRUE

	if(gibbed)
		if(rider)
			shake_camera(rider, 10, 1)
		playsound(loc, pick(gib_sounds), 75, TRUE)
	else
		playsound(loc, pick(drive_sounds), 75, TRUE)
