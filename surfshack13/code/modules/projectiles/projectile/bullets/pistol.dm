/obj/projectile/bullet/v38
	name = ".38 special bullet"
	damage = 21
	wound_bonus = -30
	wound_falloff_tile = -2.5
	wound_bonus = 15
	ricochets_max = 2
	reflect_range_decrease = 1
	ricochet_chance = 45
	ricochet_auto_aim_range = 2
	ricochet_auto_aim_angle = 30
	ricochet_incidence_leeway = 0

/obj/projectile/bullet/v38/rubber
	name = ".38 rubber bullet"
	damage = 7
	stamina = 30
	armour_penetration = -30 //Armor hit by this is modified by x1.43.
	sharpness = NONE

/obj/projectile/bullet/v38/ap
	name = ".38 armor-piercing bullet"
	damage = 18
	armour_penetration = 15 //Not actually all that great against armor, but not *terrible*

/obj/projectile/bullet/v38/frost //Basically Iceblax 2
	name = ".38 frost bullet"
	armour_penetration = -45 //x1.81 vs x1.43 for how much more effective armor is
	var/temperature = 100

/obj/projectile/bullet/v38/frost/on_hit(atom/target, blocked = FALSE, pierce_hit)
	if(blocked != 100)
		if(isliving(target))
			var/mob/living/L = target
			L.adjust_bodytemperature(((100-blocked)/100)*(temperature - L.bodytemperature))
	return ..()

/obj/projectile/bullet/v38/talon
	name = ".38 talon bullet"
	damage = 8 // 8+20 rolls 21-38 wound dmg vs no armor
	wound_bonus = 20
	wound_bonus = 0
	wound_falloff_tile = -1
	sharpness = SHARP_EDGED

/obj/projectile/bullet/v38/bluespace
	name = ".38 bluespace bullet"
	damage = 18
	speed = 0.2 //Very, very, very fast
