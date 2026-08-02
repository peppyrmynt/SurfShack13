/datum/emote/living/tweak
	key = "tweak"
	key_third_person = "tweaks"
	message = "starts tweaking"

// muscle twitching is incredibly energy intensive, IRL the body does it in an attempt to increase circulation and flush harmful chemicals out the body, or to warm up the body
/datum/emote/living/tweak/run_emote(mob/user, params, type_override, intentional)
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		if(!C.adjustStaminaLoss(60))
			return
	user.AddComponent(/datum/component/tweak, time=8 SECONDS)
	return ..()

// HYPER ADRENALINE: force the global damage/healing multiplier to at least 2x.
// This late-loaded modular definition overrides the upstream config entry defaults
// and rejects a lower value from game_options.txt.
/datum/config_entry/number/damage_multiplier
	default = 2
	min_val = 2
	integer = FALSE
