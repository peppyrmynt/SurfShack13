/obj/effect/decal/cleanable/wizcrayon
	name = "Incanting drawing"
	desc = "It appears to be moving"
	icon = 'surfshack13/icons/effects/wizcrayon_decal.dmi'

/obj/effect/decal/cleanable/wizcrayon/Initialize(mapload, list/datum/disease/diseases)
	. = ..()
	RegisterSignal(src, COMSIG_MOVABLE_CROSS, PROC_REF(drawing_crossed))

/obj/effect/decal/cleanable/wizcrayon/Destroy()
	UnregisterSignal(src, COMSIG_MOVABLE_CROSS)
	. = ..()

/obj/effect/decal/cleanable/wizcrayon/proc/drawing_crossed(atom/source, atom/A)
	SIGNAL_HANDLER
	SHOULD_CALL_PARENT(TRUE)
	if(!A.has_gravity(src))
		return

// /obj/effect/decal/cleanable/wizcrayon/razor
// 	name = "razor"
// 	desc = "a drawing of a razor, you see hairs on it."
// 	icon_state = "bald_0"
// 	var/uses = 7

// /obj/effect/decal/cleanable/wizcrayon/razor/drawing_crossed(atom/source, atom/A)
// 	. = ..()
// 	if(!ishuman(A))
// 		return
// 	var/mob/living/carbon/human/H = A
// 	if(H.hairstyle == "Skinhead" && H.facial_hairstyle == "Shaved")
// 		return

// 	// cut the hair
// 	flick("bald_1", src)
// 	H.set_facial_hairstyle("Shaved", update = TRUE)
// 	H.set_hairstyle("Skinhead", update = TRUE)
// 	playsound(A, 'sound/effects/stealthoff.ogg', 100)
// 	to_chat(H, span_danger("your head feels lighter"))
// 	--uses
// 	if(!uses)
// 		Destroy()

/obj/effect/decal/cleanable/wizcrayon/flip
	name = "flipper"
	desc = "a drawing of a bouncepad"
	icon_state = "flip_0"

/obj/effect/decal/cleanable/wizcrayon/flip/drawing_crossed(atom/source, atom/A)
	. = ..()
	A.SpinAnimation(7,1)
	flick("flip_1", src)
	playsound(A, 'surfshack13/sound/misc/cartoon_boing1.ogg', 40, TRUE)


/obj/effect/decal/cleanable/wizcrayon/spore
	name = "fentanyl shroom"
	desc = "a drawing of a fentshroom, you feel dizzy just looking at it"
	icon_state = "drug_0"

/obj/effect/decal/cleanable/wizcrayon/spore/drawing_crossed(atom/source, atom/A)
	. = ..()
	if(!iscarbon(A))
		return
	var/mob/living/carbon/C = A
	if(C.stat || C.has_status_effect(/datum/status_effect/drugginess))
		return

	flick("drug_1",src)
	playsound(A, 'sound/machines/clockcult/steam_whoosh.ogg', 30)
	to_chat(C, span_danger("The air smells lucid."))
	C.set_drugginess(20 SECONDS)
	C.set_dizzy(10 SECONDS)
	C.set_confusion(10 SECONDS)


/obj/effect/decal/cleanable/wizcrayon/fart
	name = "whoopee cushion"
	desc = "a drawing of a whoopee cushion"
	icon_state = "fart_0"
	var/ready = TRUE



/obj/effect/decal/cleanable/wizcrayon/fart/drawing_crossed(atom/source, atom/A)
	. = ..()
	if(!ready)
		return
	icon_state = "fart_1"
	playsound(A, pick('surfshack13/sound/effects/fart.ogg'), 70)
	ready = FALSE
	addtimer(CALLBACK(src, PROC_REF(reset_fart)), 15 SECONDS)


/obj/effect/decal/cleanable/wizcrayon/fart/proc/reset_fart()
	icon_state = "fart_0"
	ready = TRUE

/obj/effect/decal/cleanable/wizcrayon/glow
	name = "light"
	desc = "the drawing glows"
	icon_state = "glow"


/obj/effect/decal/cleanable/wizcrayon/glow/Initialize(mapload, list/datum/disease/diseases)
	. = ..()
	set_light(3, 5, src.color)


/obj/effect/decal/cleanable/wizcrayon/boom
	name = "landmine"
	desc = "a drawing of some bosnian decour"
	icon_state = "mine_0"

/obj/effect/decal/cleanable/wizcrayon/boom/drawing_crossed(atom/source, atom/A)
	. = ..()
	if(!isliving(A))
		return
	var/mob/living/L = A
	if(L.mob_size < MOB_SIZE_HUMAN)
		return

	flick("mine_1", src)
	playsound(A, 'surfshack13/sound/effects/air_burster_shoot.ogg', 50, FALSE)
	do_sparks(5, TRUE, src)
	to_chat(L, span_userdanger("The mine explodes maiming your leg- wait nevermind."))
	L.add_atom_colour(src.color, WASHABLE_COLOUR_PRIORITY)
	addtimer(CALLBACK(src, PROC_REF(go_away)), 6)

/obj/effect/decal/cleanable/wizcrayon/boom/proc/go_away()
	Destroy()

/obj/effect/decal/cleanable/wizcrayon/spin
	name = "spinner"
	desc = "a drawing that seems to pivot"
	icon_state = "spin_0"

/obj/effect/decal/cleanable/wizcrayon/spin/drawing_crossed(atom/source, atom/A)
	. = ..()
	if(!istype(A, /mob))
		return

	var/mob/M = A
	M.spin(10, 1)
	flick("spin_1", src)
	playsound(A, 'surfshack13/sound/effects/cartoon_woink.ogg', 40, FALSE)

