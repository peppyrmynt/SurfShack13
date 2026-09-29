/// Horizontal pixels between each glyph of the combo counter.
#define COMBO_GLYPH_SPACING 20

/**
 * Hotline style combo counter in the top right of the screen, like "12X".
 * Built out of single digit sprites so it can count as high as it needs to.
 */
/atom/movable/screen/rampage_combo
	icon = 'surfshack13/icons/effects/ultraviolence_combo.dmi'
	icon_state = "x"
	screen_loc = "EAST:-6,NORTH:-10"
	plane = ABOVE_HUD_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	alpha = 0
	/// The number currently shown.
	var/shown_combo = 0

/// Shows the given combo, popping the counter up. Zero hides it.
/atom/movable/screen/rampage_combo/proc/set_combo(combo)
	if(combo == shown_combo)
		return
	var/increased = combo > shown_combo
	shown_combo = combo
	if(combo <= 0)
		animate(src, alpha = 0, time = 0.5 SECONDS)
		return

	cut_overlays()
	var/digits = "[combo]"
	var/digit_count = length(digits)
	for(var/position in 1 to digit_count)
		var/mutable_appearance/digit = mutable_appearance(icon, copytext(digits, position, position + 1))
		digit.pixel_x = -(digit_count - position + 1) * COMBO_GLYPH_SPACING
		add_overlay(digit)

	alpha = 255
	if(increased)
		transform = matrix() * 1.4
		animate(src, transform = matrix(), time = 0.3 SECONDS, easing = ELASTIC_EASING)

#undef COMBO_GLYPH_SPACING
