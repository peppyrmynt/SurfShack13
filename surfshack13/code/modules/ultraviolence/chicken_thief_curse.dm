/// Trait source for the chicken mask sticking to a thief.
#define CHICKEN_THIEF_TRAIT "chicken_thief"
/// How long the mask stays stuck on a thief, playing the dying song out of them.
#define CHICKEN_THIEF_STUCK_TIME (60 SECONDS)
/// Brain damage per second while a thief wears the mask.
#define CHICKEN_THIEF_BRAIN_DAMAGE_PER_SECOND 0.5
/// The mask stops adding brain damage past this, so it can't kill on its own.
#define CHICKEN_THIEF_MAX_BRAIN_DAMAGE 80
/// Hallucinations topped up per second while a thief wears the mask, up to CHICKEN_THIEF_MAX_HALLUCINATION.
#define CHICKEN_THIEF_HALLUCINATION_PER_SECOND (4 SECONDS)
#define CHICKEN_THIEF_MAX_HALLUCINATION (60 SECONDS)

/**
 * What the chicken mask does to anyone who puts it on who isn't its owner.
 *
 * * It sticks for CHICKEN_THIEF_STUCK_TIME, playing the dying song out of them through walls so everyone knows where they are.
 * * Paranoia: hallucinations while it's on, and a bad mood that lingers after it comes off.
 * * Head trauma: a mild brain trauma, and brain damage building up while it's on (capped, never lethal by itself).
 *
 * Ends when the mask comes off (only possible once it loosens), is destroyed, or the thief dies.
 */
/datum/component/chicken_thief_curse
	/// The mask that's cursing us.
	var/obj/item/clothing/head/chicken_rampage/mask
	/// The dying song coming out of the thief while the mask is stuck.
	var/datum/rampage_music/music
	/// Timer for the mask loosening.
	var/loosen_timer

/datum/component/chicken_thief_curse/Initialize(obj/item/clothing/head/chicken_rampage/mask)
	if(!isliving(parent) || QDELETED(mask))
		return COMPONENT_INCOMPATIBLE
	src.mask = mask
	RegisterSignals(mask, list(COMSIG_QDELETING, COMSIG_ITEM_POST_UNEQUIP), PROC_REF(end_curse))

/datum/component/chicken_thief_curse/RegisterWithParent()
	var/mob/living/thief = parent
	ADD_TRAIT(mask, TRAIT_NODROP, CHICKEN_THIEF_TRAIT)
	loosen_timer = addtimer(CALLBACK(src, PROC_REF(loosen)), CHICKEN_THIEF_STUCK_TIME, TIMER_STOPPABLE)
	// The mask's own song pauses while it's busy cursing someone.
	mask.unworn_music?.stop(immediate = TRUE)
	music = new(thief)
	music.play('surfshack13/sound/chicken_mask/health_dying.ogg')

	thief.add_mood_event("chicken_paranoia", /datum/mood_event/chicken_paranoia)
	if(iscarbon(thief))
		var/mob/living/carbon/carbon_thief = thief
		carbon_thief.gain_trauma_type(BRAIN_TRAUMA_MILD, TRAUMA_RESILIENCE_BASIC)
	to_chat(thief, span_warning("The mask clamps down tight. It won't come off."))

	RegisterSignal(thief, COMSIG_LIVING_DEATH, PROC_REF(end_curse))
	START_PROCESSING(SSprocessing, src)

/datum/component/chicken_thief_curse/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_LIVING_DEATH)

/datum/component/chicken_thief_curse/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	deltimer(loosen_timer)
	QDEL_NULL(music)
	if(mask)
		REMOVE_TRAIT(mask, TRAIT_NODROP, CHICKEN_THIEF_TRAIT)
		UnregisterSignal(mask, list(COMSIG_QDELETING, COMSIG_ITEM_POST_UNEQUIP))
		// Still waiting for its owner, so its song picks back up.
		if(!QDELETED(mask))
			mask.unworn_music?.play('surfshack13/sound/chicken_mask/box.ogg')
		mask = null
	return ..()

/datum/component/chicken_thief_curse/proc/end_curse(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/// The mask lets go and the music stops. The paranoia and brain damage keep going until it's taken off.
/datum/component/chicken_thief_curse/proc/loosen()
	loosen_timer = null
	QDEL_NULL(music)
	if(mask)
		REMOVE_TRAIT(mask, TRAIT_NODROP, CHICKEN_THIEF_TRAIT)
	to_chat(parent, span_notice("The mask finally loosens. You can take it off."))

/datum/component/chicken_thief_curse/process(seconds_per_tick)
	var/mob/living/thief = parent
	if(thief.stat == DEAD)
		return
	thief.adjust_hallucinations_up_to(CHICKEN_THIEF_HALLUCINATION_PER_SECOND * seconds_per_tick, CHICKEN_THIEF_MAX_HALLUCINATION)
	if(thief.get_organ_loss(ORGAN_SLOT_BRAIN) < CHICKEN_THIEF_MAX_BRAIN_DAMAGE)
		thief.adjustOrganLoss(ORGAN_SLOT_BRAIN, CHICKEN_THIEF_BRAIN_DAMAGE_PER_SECOND * seconds_per_tick, CHICKEN_THIEF_MAX_BRAIN_DAMAGE)

/datum/mood_event/chicken_paranoia
	description = "Someone was watching me through the eyeholes. I can still feel it."
	mood_change = -8
	timeout = 5 MINUTES

#undef CHICKEN_THIEF_TRAIT
#undef CHICKEN_THIEF_STUCK_TIME
#undef CHICKEN_THIEF_BRAIN_DAMAGE_PER_SECOND
#undef CHICKEN_THIEF_MAX_BRAIN_DAMAGE
#undef CHICKEN_THIEF_HALLUCINATION_PER_SECOND
#undef CHICKEN_THIEF_MAX_HALLUCINATION
