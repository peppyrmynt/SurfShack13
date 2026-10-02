/// Big angry bovine. Paws the ground, then charges through whatever's in the way.
/mob/living/basic/bull
	name = "bull"
	desc = "A massive, short-tempered beast. Probably best not to wear red around it."
	icon = 'surfshack13/icons/mob/bull.dmi'
	icon_state = "Bull"
	icon_living = "Bull"
	icon_dead = "Dead"
	// 64px wide sprite, centre it on the tile. pixel_w so shaking and riding offsets leave it alone
	pixel_w = -16
	gender = MALE
	mob_biotypes = MOB_ORGANIC | MOB_BEAST | MOB_RUMINANT
	mob_size = MOB_SIZE_LARGE
	speak_emote = list("snorts", "bellows")
	response_help_continuous = "carefully pats"
	response_help_simple = "carefully pat"
	response_disarm_continuous = "shoves"
	response_disarm_simple = "shove"
	response_harm_continuous = "punches"
	response_harm_simple = "punch"
	attack_verb_continuous = "rams"
	attack_verb_simple = "ram"
	attack_sound = 'sound/items/weapons/punch1.ogg'
	// Sound slot: death bellow (placeholder: cow moo)
	death_sound = 'sound/mobs/non-humanoids/cow/cow.ogg'
	attack_vis_effect = ATTACK_EFFECT_SMASH
	butcher_results = list(/obj/item/food/meat/slab/grassfed = 8)
	faction = list(FACTION_HOSTILE)
	health = 200
	maxHealth = 200
	melee_damage_lower = 10
	melee_damage_upper = 15
	obj_damage = 40
	speed = 1
	move_force = MOVE_FORCE_VERY_STRONG
	move_resist = MOVE_FORCE_VERY_STRONG
	pull_force = MOVE_FORCE_VERY_STRONG
	blood_volume = BLOOD_VOLUME_NORMAL
	ai_controller = /datum/ai_controller/basic_controller/bull
	/// Extra brute damage on top of melee damage when a regular attack gores someone
	var/gore_damage = 5
	/// How far regular attacks fling people (a full charge flings further)
	var/gore_fling_range = 3
	/// Chance a regular attack tosses its victim high into the air
	var/gore_toss_chance = 15
	/// Chance a regular attack gives a wound
	var/gore_wound_chance = 20
	/// Our charge ability
	var/datum/action/cooldown/mob_cooldown/bull_charge/charge

/mob/living/basic/bull/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/footstep, footstep_type = FOOTSTEP_MOB_SHOE)
	AddElement(/datum/element/ai_retaliate)
	charge = new(src)
	charge.Grant(src)
	ai_controller.set_blackboard_key(BB_TARGETED_ACTION, charge)
	RegisterSignal(src, COMSIG_HOSTILE_POST_ATTACKINGTARGET, PROC_REF(on_attacked_target))
	setup_riding()

/// Our regular attacks gore too, just with less oomph than a full charge
/mob/living/basic/bull/proc/on_attacked_target(mob/living/basic/source, atom/target, success)
	SIGNAL_HANDLER
	if(!success || !isliving(target) || target == src)
		return
	var/mob/living/victim = target
	if(victim.stat == DEAD)
		return
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(bull_gore), src, victim, gore_damage, gore_fling_range, get_dir(src, victim), WOUND_SEVERITY_MODERATE, 1 SECONDS, gore_toss_chance, gore_wound_chance)

/mob/living/basic/bull/Destroy()
	QDEL_NULL(charge)
	return ..()

/// Bulls show up under NPCs in the ghost orbit menu, so ghosts can watch the carnage
/datum/orbit_menu/validate_mob_poi(datum/point_of_interest/mob_poi/potential_poi)
	if(istype(potential_poi.target, /mob/living/basic/bull))
		return potential_poi.validate()
	return ..()

/// One very angry bull in a reinforced critter crate. Whoever opens it had better be fast.
/datum/supply_pack/critter/bull
	name = "Bull Crate"
	desc = "One prize fighting bull, freshly retired from the space spaniard's arena. \
		Shipped sedated in a reinforced crate; the sedative wears off the moment the lid opens. \
		Nanotrasen accepts no liability for damage to the station, the crew, or anything red."
	cost = CARGO_CRATE_VALUE * 100
	contains = list(/mob/living/basic/bull)
	crate_name = "bull crate"
	discountable = SUPPLY_PACK_RARE_DISCOUNTABLE
