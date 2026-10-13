// High Frequency Blade - ported from HippieStation.
// Surf already has a high frequency blade; this is a subtype with Hippie's sprites, sheath and multitool easter egg.

/obj/item/highfrequencyblade/hippie
	desc = "An electric katana that weakens the molecular bonds of whatever it touches. RULES OF NATURE."
	icon = 'surfshack13/icons/hippie/hfblade.dmi'
	icon_state = "hfblade"
	inhand_icon_state = "hfblade"
	worn_icon_state = null
	lefthand_file = 'surfshack13/icons/hippie/hfblade_lefthand.dmi'
	righthand_file = 'surfshack13/icons/hippie/hfblade_righthand.dmi'
	slot_flags = NONE // carried in its sheath, Hippie had no back sprite for it
	/// Whether the buttrock speakers have been enabled with a multitool
	var/brazil = FALSE
	/// Stops the draw and sheathe songs from stacking on top of each other
	COOLDOWN_DECLARE(music_cooldown)

/obj/item/highfrequencyblade/hippie/update_icon_state()
	. = ..()
	icon_state = brazil ? "hfblade-red" : "hfblade"
	inhand_icon_state = icon_state

/obj/item/highfrequencyblade/hippie/multitool_act(mob/living/user, obj/item/tool)
	if(brazil)
		to_chat(user, span_notice("Don't get edgier than this, son."))
		return ITEM_INTERACT_BLOCKING
	if(!user.is_holding(src))
		balloon_alert(user, "hold it first!")
		return ITEM_INTERACT_BLOCKING
	balloon_alert(user, "fiddling with the wiring...")
	if(!tool.use_tool(src, user, 2 SECONDS, volume = 50) || brazil || !user.is_holding(src))
		return ITEM_INTERACT_BLOCKING
	to_chat(user, span_notice("You enable the buttrock speakers on the sword. Its new red color faintly reminds you of Brazil, for some reason."))
	desc = "Said to have been passed down from several British weeaboos, and one of them outfitted the sword with speakers to play music. Come to Brazil."
	brazil = TRUE
	slash_color = COLOR_RED
	set_light(7, 1, COLOR_RED)
	update_appearance()
	playsound(user, 'sound/vehicles/clowncar_fart.ogg', 50, TRUE)
	return ITEM_INTERACT_SUCCESS

/obj/item/highfrequencyblade/hippie/equipped(mob/user, slot, initial = FALSE)
	. = ..()
	if(slot & ITEM_SLOT_HANDS)
		play_music('surfshack13/sound/hippie/hfblade-music1.ogg', 4.5 SECONDS)

/obj/item/highfrequencyblade/hippie/dropped(mob/user, silent = FALSE)
	. = ..()
	if(!silent)
		play_music('surfshack13/sound/hippie/hfblade-music2.ogg', 2.8 SECONDS)

/// Plays one of the buttrock stings, but never while the last one is still going.
/obj/item/highfrequencyblade/hippie/proc/play_music(song, song_length)
	if(!brazil || !COOLDOWN_FINISHED(src, music_cooldown))
		return
	COOLDOWN_START(src, music_cooldown, song_length)
	playsound(src, song, 50, FALSE)

/obj/item/storage/belt/sabre/hfblade
	name = "high frequency blade sheath"
	desc = "A sturdy sheath designed to hold an electric blade of some sort."
	icon = 'surfshack13/icons/hippie/hfblade.dmi'
	// sold with the blade inside, so show the full sheath in the uplink and on spawn
	icon_state = "sheath-sabre"
	worn_icon = 'surfshack13/icons/hippie/hfblade_worn.dmi'
	// Surf's sabre sheath in-hands recoloured, so it never shows the captain's red sheath
	lefthand_file = 'surfshack13/icons/hippie/hfblade_sheath_lefthand.dmi'
	righthand_file = 'surfshack13/icons/hippie/hfblade_sheath_righthand.dmi'
	/// Set once a blade with its buttrock speakers enabled has been sheathed
	var/edgelord = FALSE

/obj/item/storage/belt/sabre/hfblade/Entered(atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	. = ..()
	var/obj/item/highfrequencyblade/hippie/blade = arrived
	if(!edgelord && istype(blade) && blade.brazil)
		edgelord = TRUE
		name = "edgelord's sheath"
		desc = "A strange sheath designed to hold an electric blade of some sort. One could only imagine how edgy this guy's musical preference is."

/obj/item/storage/belt/sabre/hfblade/Initialize(mapload)
	. = ..()
	atom_storage.set_holdable(/obj/item/highfrequencyblade/hippie)
	atom_storage.max_specific_storage = WEIGHT_CLASS_BULKY

/obj/item/storage/belt/sabre/hfblade/PopulateContents()
	new /obj/item/highfrequencyblade/hippie(src)
	update_appearance()

/datum/uplink_item/dangerous/high_frequency_blade
	name = "High Frequency Blade"
	desc = "An electric katana that weakens the molecular bonds of whatever it touches. Perfect for slicing off the limbs of your coworkers. \
		Avoid using a multitool on it."
	item = /obj/item/storage/belt/sabre/hfblade
	cost = 9
	surplus = 15
	purchasable_from = UPLINK_TRAITORS | UPLINK_SERIOUS_OPS
