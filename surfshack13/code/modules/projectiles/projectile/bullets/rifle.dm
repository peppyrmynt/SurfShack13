// 5.56mm (Drozd SMG + Lecter)

/obj/projectile/bullet/a556
	name = "5.56mm bullet"
	damage = 24
	wound_bonus = -40

/obj/projectile/bullet/a556/ap
	name = "5.56mm armor-piercing bullet"
	damage = 20
	armour_penetration = 50

/obj/projectile/bullet/incendiary/a556
	name = "5.56mm incendiary bullet"
	damage = 18
	fire_stacks = 2

/obj/projectile/bullet/a556/rubber
	name = "5.56mm rubber bullet"
	damage = 6
	stamina = 40
	sharpness = NONE

// 7.62 (Hristov)

/obj/projectile/bullet/a762
	name = "7.62mm bullet"
	speed = 1.3
	damage = 60
	wound_bonus = -35
	wound_falloff_tile = 0
	demolition_mod = 1.2

/obj/projectile/bullet/a762/raze
	name = "7.62mm Raze bullet"
	damage = 40
	var/radiation_chance = 60

/obj/projectile/bullet/a762/raze/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	if (ishuman(target) && prob(radiation_chance))
		radiation_pulse(target, max_range = 0, threshold = RAD_FULL_INSULATION)
	return BULLET_ACT_HIT

/obj/projectile/bullet/a762/pen
	name = "7.62mm anti-material bullet"
	damage = 52
	armour_penetration = 40
	projectile_piercing = PASSSTRUCTURE
	demolition_mod = 1.5 // anti-armor

/obj/projectile/bullet/a762/vulcan
	name = "7.62mm Vulcan bullet"
	damage = 47

/obj/projectile/bullet/a762/vulcan/on_hit(atom/target, blocked = FALSE, pierce_hit) //God-forsaken mutant of explosion and incendiary code that makes it so it does an explosion basically without the throwing around
	..()
	var/turf/central_point = get_turf(target)
	playsound(loc, 'sound/effects/explosion/explosion1.ogg', 20, TRUE)
	new /obj/effect/hotspot(central_point)
	central_point.hotspot_expose(700, 50, 1)
	for(var/turf/warm_spot in RANGE_TURFS(2, central_point)) //Checks all tiles within two spaces of the center
		if(prob(50) && !isspaceturf(warm_spot) && !warm_spot.density)
			new /obj/effect/hotspot(warm_spot)
			warm_spot.hotspot_expose(700, 50, 1)
	return BULLET_ACT_HIT
