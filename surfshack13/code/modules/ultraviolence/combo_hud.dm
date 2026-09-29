/// Horizontal pixels between each glyph of the combo counter.
#define COMBO_GLYPH_SPACING 20
/// Time for one flash of the counter when the combo was just refreshed.
#define COMBO_FLASH_SLOWEST (1.2 SECONDS)
/// Time for one flash of the counter when the combo is about to run out.
#define COMBO_FLASH_FASTEST (0.2 SECONDS)

/**
 * Hotline style combo counter in the top right of the screen, like "12X".
 * Built out of single digit sprites so it can count as high as it needs to.
 * Flashes faster and faster as the combo gets close to running out.
 *
 * This holder takes the pop animation on each hit; the glyphs inside it do the flashing,
 * so neither animation cancels the other.
 */
/atom/movable/screen/rampage_combo
	icon = null
	screen_loc = "EAST:-6,NORTH:-10"
	plane = ABOVE_HUD_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	alpha = 0
	/// The number currently shown.
	var/shown_combo = 0
	/// Current flash cycle length, so we only restart the flash loop when it changes.
	var/flash_period = 0
	/// The digits themselves.
	var/atom/movable/screen/rampage_combo_glyphs/glyphs

/atom/movable/screen/rampage_combo/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	glyphs = new(null, hud_owner)
	vis_contents += glyphs

/atom/movable/screen/rampage_combo/Destroy()
	vis_contents -= glyphs
	QDEL_NULL(glyphs)
	return ..()

/// Shows the given combo, popping the counter up. Zero hides it.
/atom/movable/screen/rampage_combo/proc/set_combo(combo)
	if(combo == shown_combo)
		return
	var/increased = combo > shown_combo
	shown_combo = combo
	if(combo <= 0)
		flash_period = 0
		animate(src, alpha = 0, time = 0.5 SECONDS)
		return

	glyphs.cut_overlays()
	var/digits = "[combo]"
	var/digit_count = length(digits)
	for(var/position in 1 to digit_count)
		var/mutable_appearance/digit = mutable_appearance(glyphs.icon, copytext(digits, position, position + 1))
		digit.pixel_x = -(digit_count - position + 1) * COMBO_GLYPH_SPACING
		glyphs.add_overlay(digit)

	alpha = 255
	if(increased)
		transform = matrix() * 1.4
		animate(src, transform = matrix(), time = 0.3 SECONDS, easing = ELASTIC_EASING)

/**
 * Updates how fast the counter flashes.
 *
 * Arguments:
 * * time_left_fraction - 1 when the combo was just refreshed, 0 when it's about to run out.
 */
/atom/movable/screen/rampage_combo/proc/set_time_left(time_left_fraction)
	if(shown_combo <= 0)
		return
	time_left_fraction = clamp(time_left_fraction, 0, 1)
	var/new_period = max(round(COMBO_FLASH_FASTEST + (COMBO_FLASH_SLOWEST - COMBO_FLASH_FASTEST) * time_left_fraction, 1), COMBO_FLASH_FASTEST)
	if(new_period == flash_period)
		return
	flash_period = new_period
	var/half_period = new_period / 2
	animate(glyphs, alpha = 70, time = half_period, loop = -1, easing = SINE_EASING)
	animate(alpha = 255, time = half_period, easing = SINE_EASING)

/// The digits of the combo counter. Lives inside the counter's vis_contents.
/atom/movable/screen/rampage_combo_glyphs
	icon = 'surfshack13/icons/effects/ultraviolence_combo.dmi'
	icon_state = "x"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_PLANE|VIS_INHERIT_LAYER

#undef COMBO_GLYPH_SPACING
#undef COMBO_FLASH_SLOWEST
#undef COMBO_FLASH_FASTEST
