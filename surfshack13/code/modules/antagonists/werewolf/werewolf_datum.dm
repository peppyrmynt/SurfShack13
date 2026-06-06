/datum/antagonist/werewolf
	name = "\improper Werewolf"
	antagpanel_category = "Werewolf"
	roundend_category = "Werewolves"
	show_in_roundend = TRUE
	show_in_antagpanel = TRUE
	show_name_in_check_antagonists = TRUE
	show_to_ghosts = TRUE
	job_rank = ROLE_WEREWOLF
	var/special_role = ROLE_WEREWOLF
	stinger_sound = 'surfshack13/sound/mobs/humanoid/werewolf/werewolf_howl.ogg'
	hud_icon = 'surfshack13/icons/mob/huds/antag_hud.dmi'
	antag_hud_name = "werewolf"
	show_to_ghosts = FALSE
	preview_outfit = /datum/outfit/job/assistant
	/// Will this kind of werewolf get assassination/maroon objectives?
	var/give_kill_objective = TRUE
	/// Can this werewolf antag type transform back and forth?
	var/can_transform = TRUE
	/// Transformation ability
	var/datum/action/cooldown/mob_cooldown/werewolf_transform/transformation
	/// Maul ability
	var/datum/action/cooldown/spell/touch/werewolf_maul/maul_ability
	/// Pounce ability
	var/datum/action/cooldown/spell/werewolf_pounce/pounce_ability
	/// Tainted Claw ability
	var/datum/action/cooldown/spell/touch/werewolf_tainted_claw/tainted_ability
	/// Defensive Howl ability
	var/datum/action/cooldown/spell/werewolf_def_howl/defhowl_ability
	/// Throw ability
	var/datum/action/cooldown/spell/pointed/werewolf_throw/throw_ability
	/// Thrash ability
	var/datum/action/cooldown/spell/aoe/repulse/werewolf/thrash_ability

/datum/antagonist/werewolf/on_gain()
	forge_objectives()
	return ..()

/datum/antagonist/werewolf/apply_innate_effects(mob/living/mob_override)
	if(iswerewolf(owner.current))
		return FALSE
	if(!transformation && can_transform)
		transformation = new
		transformation.Grant(owner.current)
	if(!maul_ability)
		maul_ability = new
		maul_ability.Grant(owner.current)
	if(!pounce_ability)
		pounce_ability = new
		pounce_ability.Grant(owner.current)
	if(!tainted_ability)
		tainted_ability = new
		tainted_ability.Grant(owner.current)
	if(!defhowl_ability)
		defhowl_ability = new
		defhowl_ability.Grant(owner.current)
	if(!throw_ability)
		throw_ability = new
		throw_ability.Grant(owner.current)
	if(!thrash_ability)
		thrash_ability = new
		thrash_ability.Grant(owner.current)

/datum/antagonist/werewolf/remove_innate_effects()
	QDEL_NULL(transformation)
	QDEL_NULL(maul_ability)
	QDEL_NULL(pounce_ability)
	QDEL_NULL(tainted_ability)
	QDEL_NULL(defhowl_ability)
	QDEL_NULL(throw_ability)
	QDEL_NULL(thrash_ability)
	return ..()

/datum/antagonist/werewolf/greet()
	. = ..()
	owner.announce_objectives()

/datum/antagonist/werewolf/forge_objectives()
	var/datum/objective/eat_hearts/objective = new
	objective.owner = owner
	objectives += objective

	if(give_kill_objective)
		if(prob(60))
			var/datum/objective/maroon/maroon_objective = new()
			maroon_objective.owner = owner
			maroon_objective.find_target()
			objectives += maroon_objective
		else
			var/datum/objective/assassinate/kill_objective = new()
			kill_objective.owner = owner
			kill_objective.find_target()
			objectives += kill_objective

		if(prob(90))
			var/datum/objective/escape/ending_objective = new()
			ending_objective.owner = owner
			objectives += ending_objective
		else
			var/datum/objective/hijack/ending_objective = new()
			ending_objective.owner = owner
			objectives += ending_objective

/datum/antagonist/werewolf/get_preview_icon()
	var/mob/living/carbon/human/dummy/consistent/werewolfman = new()

	werewolfman.hair_color = COLOR_DARK_MODERATE_ORANGE
	werewolfman.update_hair()
	werewolfman.set_species(/datum/species/werewolf)

	var/icon/werewolf_icon = render_preview_outfit(/datum/outfit/job/assistant, werewolfman)

	qdel(werewolfman)

	return finish_preview_icon(werewolf_icon)


/datum/objective/eat_hearts
	completion_credit_reward = 50

/datum/objective/eat_hearts/New()
	target_amount = rand(4, 9)
	explanation_text = "Consume [target_amount] hearts from dead humanoids."
	return ..()

/datum/objective/eat_hearts/check_completion()
	if(QDELETED(owner))
		return FALSE
	var/datum/action/cooldown/spell/touch/werewolf_maul/consume_ability = locate() in owner.current?.actions
	if(consume_ability?.hearts_eaten >= target_amount)
		return TRUE
	else
		return FALSE


/datum/antagonist/werewolf/lycanthropy
	name = "\improper Lycanthropy Victim"
	job_rank = ROLE_LYCANTHROPY_VICTIM
	special_role = ROLE_LYCANTHROPY_VICTIM
	can_transform = FALSE
	give_kill_objective = FALSE

/datum/antagonist/werewolf/invader
	name = "\improper Werewolf Invader"
	job_rank = ROLE_WEREWOLF_INVADER
	special_role = ROLE_WEREWOLF_INVADER
	can_transform = TRUE
