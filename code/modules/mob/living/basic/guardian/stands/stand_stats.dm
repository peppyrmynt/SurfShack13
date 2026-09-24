/// The arrow's budget is spent after choosing an ability, just as in Hippie's later system.
/datum/stand_stats
	var/damage = 1
	var/defense = 1
	var/speed = 1
	var/potential = 1
	var/range = 1

/datum/stand_stats/proc/randomize(points)
	var/list/categories = list(NAMEOF(src, damage), NAMEOF(src, defense), NAMEOF(src, speed), NAMEOF(src, potential), NAMEOF(src, range))
	while(points > 0 && length(categories))
		var/category = pick(categories)
		vars[category]++
		points--
		if(vars[category] >= 5)
			categories -= category

/datum/stand_stats/proc/apply(mob/living/basic/guardian/guardian)
	guardian.melee_damage_lower = damage * 5
	guardian.melee_damage_upper = damage * 5
	guardian.obj_damage = damage * 16
	guardian.melee_attack_cooldown = (22.5 / speed)
	var/resistance = max(0.25, (6 - defense) * 0.2)
	guardian.damage_coeff = list(BRUTE = resistance, BURN = resistance, TOX = resistance, STAMINA = 0, OXY = resistance)
	guardian.range = range * 2
	guardian.unleash()
	if(!QDELETED(guardian.summoner))
		guardian.leash_to(guardian, guardian.summoner)

/datum/stand_stats/proc/describe()
	var/list/grades = list("F", "D", "C", "B", "A")
	return "Damage: [grades[damage]] | Defense: [grades[defense]] | Speed: [grades[speed]] | Potential: [grades[potential]] | Range: [grades[range]]"

/// Metadata connects arrow generation to modern guardian implementations.
/datum/stand_power
	var/name = "Stand"
	var/cost = 0
	var/weight = 1
	var/guardian_type = /mob/living/basic/guardian

/datum/stand_power/assassin
	name = "Assassin"
	cost = 4
	weight = 0.9
	guardian_type = /mob/living/basic/guardian/assassin

/datum/stand_power/explosive
	name = "Explosive"
	cost = 4
	guardian_type = /mob/living/basic/guardian/explosive

/datum/stand_power/gravity
	name = "Gravity"
	cost = 3
	guardian_type = /mob/living/basic/guardian/gravitokinetic

/datum/stand_power/healing
	name = "Healing"
	cost = 4
	weight = 1.1
	guardian_type = /mob/living/basic/guardian/support

/// Only arrow-created guardians have this component; stock guardians retain their existing balance.
/datum/component/arrow_stand
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/datum/stand_stats/stats
	var/datum/stand_power/power
	var/requiem = FALSE
	var/transforming = FALSE
	var/datum/weakref/creator_arrow

/datum/component/arrow_stand/Initialize(datum/stand_stats/stats, datum/stand_power/power, obj/item/stand_arrow/arrow)
	if(!isguardian(parent))
		return COMPONENT_INCOMPATIBLE
	src.stats = stats
	src.power = power
	creator_arrow = WEAKREF(arrow)
	stats.apply(parent)
	var/mob/living/basic/guardian/guardian = parent
	guardian.playstyle_string += "<br>[stats.describe()]"
	if(istype(guardian, /mob/living/basic/guardian/assassin))
		var/mob/living/basic/guardian/assassin/assassin = guardian
		assassin.stealth_cooldown_time = 7.5 SECONDS / stats.potential
	if(istype(guardian, /mob/living/basic/guardian/explosive))
		var/mob/living/basic/guardian/explosive/explosive = guardian
		explosive.bomb.decay_time = stats.potential * 18 SECONDS
	if(istype(guardian, /mob/living/basic/guardian/gravitokinetic))
		var/mob/living/basic/guardian/gravitokinetic/gravity = guardian
		gravity.gravity_power_range = stats.potential * 2
	if(istype(guardian, /mob/living/basic/guardian/support))
		var/datum/component/healing_touch/healing = guardian.GetComponent(/datum/component/healing_touch)
		healing.heal_brute = stats.potential * 1.5
		healing.heal_burn = stats.potential * 1.5
		healing.heal_tox = stats.potential * 1.5
		healing.heal_oxy = stats.potential * 1.5

/datum/component/arrow_stand/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOB_GET_STATUS_TAB_ITEMS, PROC_REF(show_stats))

/datum/component/arrow_stand/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_GET_STATUS_TAB_ITEMS)

/datum/component/arrow_stand/Destroy()
	QDEL_NULL(stats)
	QDEL_NULL(power)
	return ..()

/datum/component/arrow_stand/proc/show_stats(mob/source, list/items)
	SIGNAL_HANDLER
	items += "[power.name][requiem ? " Requiem" : ""]"
	items += stats.describe()
