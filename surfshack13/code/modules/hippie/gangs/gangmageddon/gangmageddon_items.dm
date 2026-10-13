// Gangmageddon and vigilante shop entries, the reviver serum, the reinforcements gateway and the Gangbuster Seraph.

// ---- Gangmageddon war gear ----

/datum/gang_item/weapon/machinegun
	name = "Mounted Machine Gun"
	id = "MG"
	cost = 70
	item_path = /obj/machinery/deployable_turret
	spawn_msg = span_notice("The mounted machine gun features enhanced responsiveness. Hold down on the trigger while firing to control where you're shooting.")
	mode_flags = GANG_MODE_GANGMAGEDDON

/datum/gang_item/weapon/machinegun/spawn_item(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	new item_path(get_turf(user))
	to_chat(user, spawn_msg)
	return TRUE

/datum/gang_item/weapon/launcher
	name = "PML-9 Rocket Launcher"
	id = "launcher"
	cost = 60
	item_path = /obj/item/gun/ballistic/rocketlauncher/unrestricted
	mode_flags = GANG_MODE_GANGMAGEDDON | GANG_MODE_VIGILANTE

/datum/gang_item/weapon/rocket
	name = "84mm HE Rocket"
	id = "84he"
	cost = 5
	item_path = /obj/item/ammo_casing/rocket
	mode_flags = GANG_MODE_GANGMAGEDDON | GANG_MODE_VIGILANTE

/datum/gang_item/weapon/rocket_heap
	name = "84mm HEAP Rocket"
	id = "84hedp"
	cost = 10
	item_path = /obj/item/ammo_casing/rocket/heap
	mode_flags = GANG_MODE_GANGMAGEDDON | GANG_MODE_VIGILANTE

/datum/gang_item/equipment/brutepack
	name = "Brute Pack"
	id = "brute"
	cost = 4
	item_path = /obj/item/stack/medical/bruise_pack
	mode_flags = GANG_MODE_GANGMAGEDDON | GANG_MODE_VIGILANTE

/datum/gang_item/equipment/sandbag
	name = "Sandbags"
	id = "sandbag"
	cost = 6
	item_path = /obj/item/stack/sheet/mineral/sandbags
	mode_flags = GANG_MODE_GANGMAGEDDON | GANG_MODE_VIGILANTE

/datum/gang_item/equipment/reviver
	name = "Outlawed Reviver Serum"
	id = "reviver"
	cost = 50
	item_path = /obj/item/reviver
	mode_flags = GANG_MODE_GANGMAGEDDON

/datum/gang_item/function
	category = "Functions"

/datum/gang_item/function/backup
	name = "Create Gateway for Reinforcements"
	id = "backup"
	item_path = /obj/machinery/gang_backup
	mode_flags = GANG_MODE_GANGMAGEDDON

/datum/gang_item/function/backup/can_see(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	return gang && !gang.gateway_built && user.mind?.has_antag_datum(/datum/antagonist/gang/boss)

/datum/gang_item/function/backup/purchase(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool, check_canbuy = TRUE)
	var/area/user_area = get_area(user)
	if(!(user_area.type in (gang.territories | gang.new_territories)))
		to_chat(user, span_warning("This device can only be spawned in territory controlled by your gang!"))
		return FALSE
	if(tgui_alert(user, "Your gang can only place ONE gateway, make sure it is in a well-secured location.", "Are you ready to place the gateway?", list("This location is secure", "I should wait...")) != "This location is secure")
		return FALSE
	if(gang.gateway_built)
		return FALSE
	return ..()

/datum/gang_item/function/backup/spawn_item(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	new /obj/machinery/gang_backup(get_turf(user), gang)
	return TRUE

// ---- Vigilante-only gear ----

/datum/gang_item/equipment/shield
	name = "Telescopic Shield"
	id = "shield"
	cost = 10
	item_path = /obj/item/shield/riot/tele
	mode_flags = GANG_MODE_VIGILANTE

/datum/gang_item/equipment/gangbreaker
	name = "Mindshield Implant"
	id = "gangbreaker"
	cost = 15
	item_path = /obj/item/implanter/mindshield
	spawn_msg = span_notice("Nanotrasen has provided you with a prototype mindshield implant that will both break a gang's control over a person and shield them from further conversion attempts. Gang bosses are immune.")
	mode_flags = GANG_MODE_VIGILANTE

/datum/gang_item/equipment/seraph
	name = "Seraph 'Gangbuster' Mech"
	id = "seraph"
	cost = 250
	item_path = /obj/vehicle/sealed/mecha/marauder/seraph/gangbuster
	spawn_msg = span_notice("For employees who go above and beyond... you know what to do with this.")
	mode_flags = GANG_MODE_VIGILANTE

/datum/gang_item/equipment/seraph/spawn_item(mob/living/carbon/user, datum/team/gang/gang, obj/item/gangtool/gangtool)
	new item_path(get_turf(user))
	to_chat(user, spawn_msg)
	return TRUE

/// Surf's existing Seraph, loaded out like Hippie's Gangbuster and usable by anyone.
/obj/vehicle/sealed/mecha/marauder/seraph/gangbuster
	name = "\improper 'Gangbuster' Seraph"
	desc = "Heavy-duty, combat-type exosuit. This is a custom gangbuster model, utilized only by employees who have proven themselves in the line of fire."
	accesses = list()
	movedelay = 2
	max_integrity = 300
	equip_by_category = list(
		MECHA_L_ARM = /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/scattershot,
		MECHA_R_ARM = /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg,
		MECHA_UTILITY = list(/obj/item/mecha_parts/mecha_equipment/radio, /obj/item/mecha_parts/mecha_equipment/air_tank/full, /obj/item/mecha_parts/mecha_equipment/teleporter),
		MECHA_POWER = list(),
		MECHA_ARMOR = list(),
	)

// ---- Reviver serum ----

/// Brings a dead body back to about half health, at the cost of some brain damage.
/obj/item/reviver
	name = "outlawed revivification serum"
	desc = "Banned due to side effects of extreme rage, reduced intelligence, and violence. For gangs, that's just a fringe benefit."
	icon = 'icons/obj/medical/syringe.dmi'
	icon_state = "implanter1"
	inhand_icon_state = "syringe_0"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	throw_speed = 3
	throw_range = 5
	w_class = WEIGHT_CLASS_SMALL
	/// Spent serums do nothing
	var/used = FALSE

/obj/item/reviver/attack(mob/living/target_mob, mob/living/user, params)
	var/mob/living/carbon/human/patient = target_mob
	if(!ishuman(patient) || used)
		return ..()
	user.visible_message(span_warning("[user] begins to inject [patient] with [src]."), span_warning("You begin to inject [patient] with [src]..."))
	patient.notify_revival("You're being injected with a revivification serum - return to your body!", source = patient)
	if(!do_after(user, 8 SECONDS, patient) || used)
		return TRUE
	if(patient.stat != DEAD)
		to_chat(user, span_warning("[patient] isn't dead!"))
		return TRUE
	patient.visible_message(span_warning("[patient]'s body thrashes violently."))
	playsound(patient, SFX_BODYFALL, 50, TRUE)
	patient.spin(2 SECONDS, 1)
	if(HAS_TRAIT(patient, TRAIT_SUICIDED) || !patient.get_organ_slot(ORGAN_SLOT_HEART) || !patient.get_organ_slot(ORGAN_SLOT_BRAIN) || !patient.mind || (!patient.client && !patient.mind.get_ghost(TRUE)))
		patient.visible_message(span_warning("[patient]'s body falls still again, [patient.p_theyre()] gone for good."))
		return TRUE
	used = TRUE
	icon_state = "implanter0"
	update_appearance()
	// Scale every damage type down so the patient ends up at 50 health
	var/overall_damage = patient.getBruteLoss() + patient.getFireLoss() + patient.getToxLoss() + patient.getOxyLoss()
	var/target_damage = patient.maxHealth - 50
	if(overall_damage > target_damage)
		var/ratio = target_damage / overall_damage
		patient.setBruteLoss(patient.getBruteLoss() * ratio, updating_health = FALSE)
		patient.setFireLoss(patient.getFireLoss() * ratio, updating_health = FALSE)
		patient.setToxLoss(patient.getToxLoss() * ratio, updating_health = FALSE)
		patient.setOxyLoss(patient.getOxyLoss() * ratio, updating_health = FALSE)
		patient.updatehealth()
	patient.set_heartattack(FALSE)
	patient.grab_ghost()
	patient.revive()
	patient.emote("gasp")
	patient.setOrganLoss(ORGAN_SLOT_BRAIN, 40)
	log_combat(user, patient, "revived with a reviver serum")
	return TRUE

// ---- Reinforcements gateway ----

/// Brings dead members of its gang back as reinforcements. One per gang.
/obj/machinery/gang_backup
	name = "gang reinforcements gateway"
	desc = "A gateway used by gangs to bring in muscle from other operations."
	icon = 'surfshack13/icons/hippie/gang_gateway.dmi'
	icon_state = "gang_teleporter_on"
	anchored = TRUE
	density = TRUE
	max_integrity = 400
	use_power = NO_POWER_USE
	processing_flags = NONE
	/// The gang it serves
	var/datum/team/gang/gang
	/// Whether the one-off emergency reinforcement has been used
	var/final_guard = TRUE
	/// Stops two polls overlapping
	var/polling = FALSE

/obj/machinery/gang_backup/Initialize(mapload, datum/team/gang/new_gang)
	. = ..()
	if(!istype(new_gang))
		return INITIALIZE_HINT_QDEL
	gang = new_gang
	gang.gateway_built = TRUE
	name = "[gang.name] reinforcements gateway"
	do_sparks(4, TRUE, src)
	// The first wave comes no earlier than 7.5 minutes into the round
	addtimer(CALLBACK(src, PROC_REF(reinforce)), max(1 SECONDS, 7.5 MINUTES - world.time))

/obj/machinery/gang_backup/Destroy()
	gang = null
	return ..()

/obj/machinery/gang_backup/take_damage(damage_amount, damage_type = BRUTE, damage_flag = "", sound_effect = TRUE, attack_dir, armour_penetration = 0)
	. = ..()
	if(. && !QDELETED(src) && final_guard && atom_integrity < 300)
		final_guard = FALSE
		reinforce(repeat = FALSE)

/// Spawns one reinforcement, then schedules the next. Stronger gangs wait longer.
/obj/machinery/gang_backup/proc/reinforce(repeat = TRUE)
	if(QDELETED(src) || !gang)
		return
	var/our_living = 0
	var/rival_living = 0
	var/list/mob/dead/observer/dead_members = list()
	for(var/datum/team/gang/some_gang as anything in GLOB.gangs)
		for(var/datum/mind/member as anything in some_gang.members)
			if(member.current?.stat != DEAD && member.current)
				if(some_gang == gang)
					our_living++
				else
					rival_living++
			else if(some_gang == gang)
				var/mob/dead/observer/ghost = member.get_ghost(TRUE)
				if(ghost?.client)
					dead_members += ghost
	if(repeat)
		var/share = max(our_living, 1) / (rival_living + max(our_living, 1))
		addtimer(CALLBACK(src, PROC_REF(reinforce)), 25 SECONDS + ((share * 100) ** 2) * 0.1 SECONDS, TIMER_UNIQUE)
	if(length(dead_members) && !polling)
		INVOKE_ASYNC(src, PROC_REF(spawn_gangster), dead_members)

/obj/machinery/gang_backup/proc/spawn_gangster(list/mob/dead/observer/dead_members)
	polling = TRUE
	var/mob/dead/observer/chosen = SSpolling.poll_candidates(
		question = "Would you like to be a [gang.name] gang reinforcement?",
		check_jobban = ROLE_GANG,
		poll_time = 10 SECONDS,
		group = dead_members,
		alert_pic = src,
		role_name_text = "[gang.name] gang reinforcement",
		amount_to_pick = 1,
	)
	polling = FALSE
	if(QDELETED(src) || !gang || !istype(chosen) || !chosen.client)
		return
	var/mob/living/carbon/human/reinforcement = new(get_turf(src))
	randomize_human_normie(reinforcement)
	reinforcement.equipOutfit(/datum/outfit/gang_reinforcement)
	if(length(gang.inner_outfits))
		var/uniform_type = pick(gang.inner_outfits)
		reinforcement.equip_to_slot_or_del(new uniform_type(reinforcement), ITEM_SLOT_ICLOTHING)
	if(length(gang.outer_outfits))
		var/suit_type = pick(gang.outer_outfits)
		var/obj/item/clothing/outerwear = new suit_type(reinforcement)
		outerwear.set_armor(/datum/armor/gang_outerwear)
		reinforcement.equip_to_slot_or_del(outerwear, ITEM_SLOT_OCLOTHING)
	reinforcement.PossessByPlayer(chosen.ckey)
	reinforcement.mind.add_antag_datum(/datum/antagonist/gang, gang)
	do_sparks(4, TRUE, src)
	message_admins("[ADMIN_LOOKUPFLW(reinforcement)] joined the [gang.name] gang as a reinforcement.")
	log_game("[key_name(reinforcement)] joined the [gang.name] gang as a reinforcement.")

/datum/outfit/gang_reinforcement
	name = "Gang Reinforcement"
	shoes = /obj/item/clothing/shoes/jackboots
	l_hand = /obj/item/gun/ballistic/automatic/surplus
	back = /obj/item/storage/backpack
	// Hippie put these in the pockets, but the gang uniform is added after the outfit
	backpack_contents = list(
		/obj/item/ammo_box/magazine/m10mm/rifle = 1,
		/obj/item/switchblade = 1,
	)
	ears = /obj/item/radio/headset
