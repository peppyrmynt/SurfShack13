/// Horizontal pixels between each glyph of the combo counter.
#define COMBO_GLYPH_SPACING 20
/// Time for one flash of the counter when the combo was just refreshed.
#define COMBO_FLASH_SLOWEST (1.2 SECONDS)
/// Time for one flash of the counter when the combo is about to run out.
#define COMBO_FLASH_FASTEST (0.2 SECONDS)
/// How visible the counter is while there's no combo going.
#define COMBO_IDLE_ALPHA 90
/// Below this fraction of time left, the counter starts shaking.
#define COMBO_SHAKE_THRESHOLD 0.25
/// How long the "falling off" animation takes when a combo is lost.
#define COMBO_FALL_TIME (0.6 SECONDS)
/// Width in pixels of the drain bar sprite at normal scale.
#define COMBO_BAR_SPRITE_WIDTH 30

/**
 * Hotline style combo counter in the top right of the screen, like "12X".
 * Built out of single digit sprites so it can count as high as it needs to.
 *
 * * Idle: a dim "0X".
 * * Active: pops on every hit, flashes faster and faster as the combo runs out, with a timer bar underneath that drains.
 * * Almost out: starts shaking.
 * * Lost: the number drops, tilts and fades away, then the dim "0X" fades back in.
 *
 * This holder takes the pop, shake and fall animations; the glyphs inside it do the flashing and the bar does the
 * draining, so none of the animations cancel each other.
 */
/atom/movable/screen/rampage_combo
	icon = null
	screen_loc = "EAST:-6,NORTH:-10"
	plane = ABOVE_HUD_PLANE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	alpha = COMBO_IDLE_ALPHA
	/// The number currently shown. Starts invalid so the first set_combo() always draws.
	var/shown_combo = -1
	/// Current flash cycle length, so we only restart the flash loop when it changes.
	var/flash_period = 0
	/// The digits themselves.
	var/atom/movable/screen/rampage_combo_glyphs/glyphs
	/// The timer bar under the digits.
	var/atom/movable/screen/rampage_combo_bar/bar
	/// Timer for the end of the falling off animation.
	var/fall_timer

/atom/movable/screen/rampage_combo/Initialize(mapload, datum/hud/hud_owner)
	. = ..()
	glyphs = new(null, hud_owner)
	bar = new(null, hud_owner)
	vis_contents += list(glyphs, bar)
	set_combo(0)

/atom/movable/screen/rampage_combo/Destroy()
	deltimer(fall_timer)
	vis_contents -= list(glyphs, bar)
	QDEL_NULL(glyphs)
	QDEL_NULL(bar)
	return ..()

/// Draws the number with an X after it.
/atom/movable/screen/rampage_combo/proc/draw_digits(number)
	glyphs.cut_overlays()
	var/digits = "[number]"
	var/digit_count = length(digits)
	for(var/position in 1 to digit_count)
		var/mutable_appearance/digit = mutable_appearance(glyphs.icon, copytext(digits, position, position + 1))
		digit.pixel_x = -(digit_count - position + 1) * COMBO_GLYPH_SPACING
		glyphs.add_overlay(digit)

/// Puts the holder back to its resting position, cancelling any pop, shake or fall.
/atom/movable/screen/rampage_combo/proc/reset_motion()
	deltimer(fall_timer)
	fall_timer = null
	animate(src)
	transform = matrix()
	pixel_x = 0
	pixel_y = 0

/// Shows the given combo. Going up pops the counter, dropping to zero plays the falling off animation.
/atom/movable/screen/rampage_combo/proc/set_combo(combo)
	combo = max(combo, 0)
	if(combo == shown_combo)
		return
	var/previous = shown_combo
	shown_combo = combo

	if(combo <= 0)
		flash_period = 0
		animate(glyphs)
		glyphs.alpha = 255
		animate(bar)
		bar.alpha = 0
		reset_motion()
		if(previous > 0)
			fall_off()
		else
			draw_digits(0)
			animate(src, alpha = COMBO_IDLE_ALPHA, time = 0.5 SECONDS)
		return

	reset_motion()
	draw_digits(combo)
	alpha = 255
	bar.alpha = 255
	if(combo > previous && previous >= 0)
		transform = matrix() * 1.4
		animate(src, transform = matrix(), time = 0.3 SECONDS, easing = ELASTIC_EASING)

/// The combo was lost: the number drops, tilts and fades away.
/atom/movable/screen/rampage_combo/proc/fall_off()
	var/matrix/tilted = matrix()
	tilted.Turn(-20)
	animate(src, pixel_y = -28, pixel_x = -6, transform = tilted, alpha = 0, time = COMBO_FALL_TIME, easing = QUAD_EASING|EASE_IN)
	fall_timer = addtimer(CALLBACK(src, PROC_REF(finish_fall)), COMBO_FALL_TIME, TIMER_STOPPABLE)

/// After falling off, come back as a dim "0X".
/atom/movable/screen/rampage_combo/proc/finish_fall()
	fall_timer = null
	if(shown_combo > 0)
		return
	animate(src)
	transform = matrix()
	pixel_x = 0
	pixel_y = 0
	draw_digits(0)
	animate(src, alpha = COMBO_IDLE_ALPHA, time = 0.4 SECONDS)

/**
 * Updates the flashing, timer bar and shaking for how much time is left.
 *
 * Arguments:
 * * time_left_fraction - 1 when the combo was just refreshed, 0 when it's about to run out.
 */
/atom/movable/screen/rampage_combo/proc/set_time_left(time_left_fraction)
	if(shown_combo <= 0)
		return
	time_left_fraction = clamp(time_left_fraction, 0, 1)
	update_bar(time_left_fraction)

	// Last stretch: tremble.
	if(time_left_fraction < COMBO_SHAKE_THRESHOLD)
		var/intensity = time_left_fraction < COMBO_SHAKE_THRESHOLD / 2 ? 3 : 2
		pixel_x = rand(-intensity, intensity)
		pixel_y = rand(-intensity, intensity)
	else if(pixel_x || pixel_y)
		pixel_x = 0
		pixel_y = 0

	var/new_period = max(round(COMBO_FLASH_FASTEST + (COMBO_FLASH_SLOWEST - COMBO_FLASH_FASTEST) * time_left_fraction, 1), COMBO_FLASH_FASTEST)
	if(new_period == flash_period)
		return
	flash_period = new_period
	var/half_period = new_period / 2
	animate(glyphs, alpha = 70, time = half_period, loop = -1, easing = SINE_EASING)
	animate(alpha = 255, time = half_period, easing = SINE_EASING)

/// Stretches the timer bar under the digits to the fraction of time left, draining towards the left.
/atom/movable/screen/rampage_combo/proc/update_bar(time_left_fraction)
	var/digit_count = length("[shown_combo]")
	// The counter reaches from the left edge of the first digit to the right edge of the X.
	var/left_edge = -digit_count * COMBO_GLYPH_SPACING + 4
	var/full_width = digit_count * COMBO_GLYPH_SPACING + 24
	var/scale_x = max(full_width * time_left_fraction / COMBO_BAR_SPRITE_WIDTH, 0.01)
	// Scale around the sprite's centre, then slide it so its left edge stays pinned under the first digit.
	var/offset = left_edge - (16 - 16 * scale_x)
	animate(bar, transform = matrix(scale_x, 0, offset, 0, 1, 0), time = 0.2 SECONDS)

/// The digits of the combo counter. Lives inside the counter's vis_contents.
/atom/movable/screen/rampage_combo_glyphs
	icon = 'surfshack13/icons/effects/ultraviolence_combo.dmi'
	icon_state = "x"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_PLANE|VIS_INHERIT_LAYER

/// The combo timer bar. Lives inside the counter's vis_contents, just under the digits.
/atom/movable/screen/rampage_combo_bar
	icon = 'surfshack13/icons/effects/ultraviolence_combo.dmi'
	icon_state = "bar"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	vis_flags = VIS_INHERIT_PLANE|VIS_INHERIT_LAYER
	pixel_y = -8
	alpha = 0

#undef COMBO_GLYPH_SPACING
#undef COMBO_FLASH_SLOWEST
#undef COMBO_FLASH_FASTEST
#undef COMBO_IDLE_ALPHA
#undef COMBO_SHAKE_THRESHOLD
#undef COMBO_FALL_TIME
#undef COMBO_BAR_SPRITE_WIDTH
