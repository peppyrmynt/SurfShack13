/**
 * tweak.dm
 *
 * It's an component that makes things shake like his grace.
 * see /atom/proc/spasm_animation
 * if time is passed, expires after time ticks
*/


/datum/component/tweak
	// element_flags = ELEMENT_DETACH_ON_HOST_DESTROY | ELEMENT_BESPOKE
	dupe_mode = COMPONENT_DUPE_HIGHLANDER
	var/tick_time = 4 SECONDS
	var/tweak_cycle //we wouldnt want everything to be tweaking in sync
	var/is_processing = FALSE
	var/atom/A


/datum/component/tweak/Initialize(time=-1)
	A = parent
	if(isliving(A))
		var/mob/living/L = A
		if(L.stat > SOFT_CRIT)
			return COMPONENT_INCOMPATIBLE
	if(!isatom(A))
		return COMPONENT_INCOMPATIBLE

	START_PROCESSING(SSfastprocess, src)
	if(time>0)
		addtimer(CALLBACK(src, PROC_REF(Destroy)), time)

/datum/component/tweak/process(tick_time)
	var/X = A.pixel_x
	var/Y = A.pixel_y
	if(!tweak_cycle)
		tweak_cycle = rand(1,4)
	switch(tweak_cycle)
		if(1)
			animate(A, pixel_x=X-1, pixel_y=Y, time = 0.1,  loop = 5)
			animate(   pixel_x=X,   pixel_y=Y+1, time = 0.1)
			animate(   pixel_x=X+1, pixel_y=Y, time = 0.2)
			animate(   pixel_x=X,   pixel_y=Y-1, time = 0.3)
			animate(   pixel_x=X,   pixel_y=Y, time = 0.1)
		if(2)
			animate(A, pixel_x=X,   pixel_y=Y-1, time = 0.3,  loop = 5)
			animate(   pixel_x=X-1, pixel_y=Y, time = 0.1)
			animate(   pixel_x=X,   pixel_y=Y+1, time = 0.1)
			animate(   pixel_x=X+1, pixel_y=Y, time = 0.2)
			animate(   pixel_x=X,   pixel_y=Y, time = 0.1)
		if(3)
			animate(A, pixel_x=X+1, pixel_y=Y, time = 0.2,  loop = 5)
			animate(   pixel_x=X,   pixel_y=Y-1, time = 0.3)
			animate(   pixel_x=X-1, pixel_y=Y, time = 0.1)
			animate(   pixel_x=X,   pixel_y=Y+1, time = 0.1)
			animate(   pixel_x=X,   pixel_y=Y, time = 0.1)
		else
			animate(A, pixel_x=X,   pixel_y=Y+1, time = 0.1,  loop = 5)
			animate(   pixel_x=X+1, pixel_y=Y, time = 0.2)
			animate(   pixel_x=X,   pixel_y=Y-1, time = 0.3)
			animate(   pixel_x=X-1, pixel_y=Y, time = 0.1)
			animate(   pixel_x=X,   pixel_y=Y, time = 0.1)

/datum/component/tweak/Destroy(force)
	A = null

	return ..()

/datum/component/tweak/proc/stop()
	SIGNAL_HANDLER

	STOP_PROCESSING(SSfastprocess, src)
	src.Destroy()

/datum/component/tweak/RegisterWithParent()
	if(!isliving(parent))
		return
	RegisterSignal(parent, COMSIG_LIVING_DEATH, PROC_REF(stop))

/datum/component/tweak/UnregisterFromParent()
	if(!isliving(parent))
		return
	UnregisterSignal(parent, COMSIG_LIVING_DEATH)

