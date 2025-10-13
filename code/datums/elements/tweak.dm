/**
 * tweak.dm
 *
 * It's an element that makes things shake like his grace.
 * see /atom/proc/spasm_animation
 * if time passed, cant be lower then 4 seconds
*/

/datum/element/tweak
	element_flags = ELEMENT_DETACH_ON_HOST_DESTROY | ELEMENT_BESPOKE
	var/tick_time = 4 SECONDS
	var/list/processing = list()
	var/list/tweak_cycle = alist() //we wouldnt want everything to be tweaking in sync
	var/is_processing = FALSE

/datum/element/tweak/Attach(datum/target)
	. = ..()
	if(!isatom(target))
		return ELEMENT_INCOMPATIBLE
	processing |= target
	if(!is_processing)
		is_processing = TRUE
		START_PROCESSING(SSfastprocess, src)


/datum/element/tweak/process(tick_time)
	if(!length(processing))
		is_processing = FALSE
		return PROCESS_KILL

	for(var/atom/target in processing)
		if(!tweak_cycle[target])
			tweak_cycle[target] = rand(0,4)

		var/X = target.pixel_x
		var/Y = target.pixel_y
		//I hope you get migrane looking at this
		switch(tweak_cycle[target])
			if(0)
				animate(target, pixel_x=X, pixel_y=Y, time = 0.1,  loop = 5)
				animate(pixel_x=X-1, pixel_y=Y, time = 0.1)
				animate(pixel_x=X+1, pixel_y=Y+1, time = 0.1)
				animate(pixel_x=X+1, pixel_y=Y-1, time = 0.2)
				animate(pixel_x=X-1, pixel_y=Y-1, time = 0.3)
				animate(pixel_x=X, pixel_y=Y+1, time = 0)

			if(1)
				animate(target, pixel_x=X, pixel_y=Y-1, time = 0.3,  loop = 5)
				animate(pixel_x=X+1, pixel_y=Y+1, time = 0.1)
				animate(pixel_x=X-1, pixel_y=Y-1, time = 0.1)
				animate(pixel_x=X-1, pixel_y=Y, time = 0.1)
				animate(pixel_x=X+1, pixel_y=Y+1, time = 0.2)
				animate(pixel_x=X, pixel_y=Y, time = 0.1)

			if(2)
				animate(target, pixel_x=X+1, pixel_y=Y-1, time = 0.2,  loop = 5)
				animate(pixel_x=X+1, pixel_y=Y-1, time = 0.3)
				animate(pixel_x=X-1, pixel_y=Y+1, time = 0.1)
				animate(pixel_x=X-1, pixel_y=Y, time = 0.1)
				animate(pixel_x=X, pixel_y=Y+1, time = 0.1)
				animate(pixel_x=X, pixel_y=Y, time = 0.1)

			if(3)
				animate(target, pixel_x=X, pixel_y=Y+1, time = 0.1,  loop = 5)
				animate(pixel_x=X+1, pixel_y=Y-1, time = 0.2)
				animate(pixel_x=X+1, pixel_y=Y-1, time = 0.3)
				animate(pixel_x=X-1, pixel_y=Y+1, time = 0.1)
				animate(pixel_x=X-1, pixel_y=Y, time = 0.1)
				animate(pixel_x=X, pixel_y=Y, time = 0.1)

			else
				animate(target, pixel_x=X-1, pixel_y=Y-1, time = 0.1,  loop = 5)
				animate(pixel_x=X-1, pixel_y=Y+1, time = 0.1)
				animate(pixel_x=X+1, pixel_y=Y+1, time = 0.2)
				animate(pixel_x=X+1, pixel_y=Y-1, time = 0.3)
				animate(pixel_x=X, pixel_y=Y, time = 0.1)

/datum/element/tweak/Detach(datum/source, ...)
	. = ..()
	processing -= source
	tweak_cycle.Remove(source)



/obj/item/gun/magic/wand/tweak
	name = "wand of tweaking"
	desc = "shieet"
	fire_sound = 'sound/effects/magic/wandodeath.ogg'
	ammo_type = /obj/item/ammo_casing/magic/tweak
	max_charges = 50

/obj/item/gun/magic/wand/tweak/zap_self(mob/living/user)
	. = ..()
	user.AddElement(/datum/element/tweak)

/obj/item/ammo_casing/magic/tweak
	projectile_type = /obj/projectile/magic/tweak


/obj/projectile/magic/tweak
	name = "bolt of tweaking"
	icon_state = "pulse1_bl"

/obj/projectile/magic/tweak/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	target.AddElement(/datum/element/tweak)
