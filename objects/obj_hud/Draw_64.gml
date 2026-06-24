// =============================================================================
// HUD — Draw GUI. Reads hp/mp/posture from obj_player.
// Colors, layout, and the segment/posture drawers live in Create_0.
// =============================================================================

// Nearest-neighbour sampling — resets every frame, so set it every frame
gpu_set_tex_filter(false);

if (!instance_exists(obj_player)) exit;
var _p = obj_player;

// Safety net: if the Create event's PIXELATION vars are missing (e.g. the
// event got reverted), define them here so this event can't crash. The
// Create value wins when it exists, so hud_px stays tunable there.
if (!variable_instance_exists(id, "hud_px"))      hud_px = 5;
if (!variable_instance_exists(id, "surf_meters")) surf_meters = -1;

// Resolve HUD sprites DIRECTLY here every frame. Two reasons:
//  1) Direct references keep the compiler from stripping them as "unused"
//     (string asset_get_index lookups don't count as a reference → -1 at
//     runtime → vitalsBG vanishes, bars fall back to primitives).
//  2) This event isn't open in the GameMaker editor, so these assignments
//     survive even if the Create event reverts and re-breaks the lookups.
sprVitalsBG     = spr_vitalsBG;
sprBarFill      = spr_bar_fill;
sprBarBg        = spr_bar_bg;
sprPostureFill  = spr_posture_fill;
sprPostureFrame = spr_posture_frame;
sprAbilitySlot  = spr_ability_slot;

draw_set_alpha(1);

// ==========================================
// LOW-RES METER PASS — render HP/MP/posture into a small surface, then
// upscale it nearest-neighbour so the edges show chunky pixel steps that
// match the game world. The world matrix scales every draw down by 1/hud_px,
// so the meter code below keeps using normal GUI coordinates unchanged.
// ==========================================
var _lw = ceil(display_get_gui_width()  / hud_px);
var _lh = ceil(display_get_gui_height() / hud_px);
if (!surface_exists(surf_meters)) surf_meters = surface_create(_lw, _lh);
surface_set_target(surf_meters);
draw_clear_alpha(c_black, 0);
matrix_set(matrix_world, matrix_build(0, 0, 0, 0, 0, 0, 1 / hud_px, 1 / hud_px, 1));

// ==========================================
// HP BAR — 5 segments, drains right to left
// ==========================================
draw_segment_bar(hp_x, hp_y, _p.hp, _p.maxHp, col_hp, hp_flip);

// ==========================================
// MP BAR — same mechanic, mirrored from HP
// ==========================================
draw_segment_bar(mp_x, mp_y, _p.mp, _p.mp_max, col_mp, mp_flip);

// ==========================================
// END LOW-RES PASS — restore matrix/target and blit the HP/MP bars back up,
// nearest-neighbour, so each low-res pixel becomes a hud_px-sized block
// ==========================================
matrix_set(matrix_world, matrix_build_identity());
surface_reset_target();

gpu_set_tex_filter(false);
draw_surface_ext(surf_meters, 0, 0, hud_px, hud_px, 0, c_white, 1);

// ==========================================
// POSTURE BAR — drawn at FULL resolution (OUTSIDE the pixelation pass). Its
// staircase art is already pixel-art; routing it through the low-res surface
// downsampled the steps onto a coarse grid and made their heights uneven.
// Wings close in toward the center; the connector is always visible.
// ==========================================
var _pos_pct = clamp(_p.posture / _p.posture_max, 0, 1);
var _pos_col = get_posture_color(_pos_pct);

// Posture nudged down 50px. Applied here as a local offset (not via pos_box_y
// in Create_0) because that event keeps getting reverted by the IDE. To make
// this the single source of truth, bump pos_box_y by 50 in Create_0 and zero
// this out.
var _pos_y = pos_y + 50;

if (sprite_exists(sprPostureFill))
{
	var _wing_l = pos_wing_span_l * _pos_pct;
	var _wing_r = pos_wing_span_r * _pos_pct;
	var _lx     = pos_center_x - _wing_l;

	if (_pos_pct > 0)
	{
		// Left wing — outer edge moves right as posture drains
		draw_sprite_part_ext(sprPostureFill, 0, _lx, 0, _wing_l, pos_sprite_h,
			pos_x + _lx * pos_scale_x, _pos_y, pos_scale_x, pos_scale_y, _pos_col, 1);
		// Right wing — outer edge moves left as posture drains
		draw_sprite_part_ext(sprPostureFill, 0, pos_center_rw, 0, _wing_r, pos_sprite_h,
			pos_x + pos_center_rw * pos_scale_x, _pos_y, pos_scale_x, pos_scale_y, _pos_col, 1);
	}

	// Center connector — minimum state, always drawn
	draw_sprite_part_ext(sprPostureFill, 0, pos_center_x, 0, pos_center_w, pos_sprite_h,
		pos_x + pos_center_x * pos_scale_x, _pos_y, pos_scale_x, pos_scale_y, _pos_col, 1);
}
else
{
	draw_posture_fill_fallback(_pos_pct, _pos_col);
}

// Frame: outline + < > brackets + center pin, drawn over the fill
if (sprite_exists(sprPostureFrame))
{
	draw_sprite_ext(sprPostureFrame, 0, pos_x, _pos_y, pos_scale_x, pos_scale_y, 0, c_white, 1);
}

// ==========================================
// VITALS BACKGROUND — static decorative art, drawn LAST at full resolution
// (NOT pixelated) so it sits crisp on top of everything
// ==========================================
if (sprite_exists(sprVitalsBG))
{
	// reset blend state so the art draws at full color/alpha
	draw_set_colour(c_white);
	draw_set_alpha(1);
	// draw_sprite_stretched fills the box from its top-left, ignoring the
	// sprite's origin — keeps placement exact even if the PNG is re-exported
	draw_sprite_stretched(sprVitalsBG, 0, vitals_x, vitals_y, vitals_w, vitals_h);
}

// ==========================================
// ABILITY SLOTS — static icons (spr_ability_slot) at full resolution, drawn
// over the backing. Each entry in _slots is [top-left x, y, display w, h]
// (Pixelmator coords). Add/move/resize entries to reposition or add more.
// ==========================================
if (sprite_exists(sprAbilitySlot))
{
	var _aw = sprite_get_width(sprAbilitySlot);    // native 94
	var _ah = sprite_get_height(sprAbilitySlot);   // native 88
	var _slots = [
		[ 824, 914, _aw, _ah],   // native size
		[1013, 914, _aw, _ah],   // native size
		[ 894, 859,  141, 132],  // 1.5x native (94x88 -> 141x132)
	];
	draw_set_colour(c_white);
	draw_set_alpha(1);
	for (var _i = 0; _i < array_length(_slots); _i++)
	{
		draw_sprite_stretched(sprAbilitySlot, 0,
			_slots[_i][0], _slots[_i][1], _slots[_i][2], _slots[_i][3]);
	}
}

// ==========================================
// HP / MP READOUT — "cur/max" at full resolution, on top of everything.
// The current value is big (_big_px); the "/max" is smaller (_small_px) with
// its baseline aligned to the big value's "feet".
// PLACEMENT: top-left coords below.
// SIZE: both are SCALED from Font1's baked Size, so set _font_base to match
//   Font1's actual Size in the IDE. For crispest output bake Font1 at 38 (the
//   largest size used) — then the big value is 1:1 and "/max" is downscaled.
// FONT: the "Font1" asset (open it in the IDE for family/weight). Referenced
//   directly so it isn't stripped — if you rename it, update this reference.
// ==========================================
var _hp_tx = 251, _hp_ty =  44;   // HP readout top-left (above the HP bar)
var _mp_tx = 251, _mp_ty = 170;   // MP readout top-left (below the MP bar)

var _font_base = 38;   // <-- Font1's baked Size in the IDE; keep in sync
var _big_px    = 38;   // current-value size
var _small_px  = 18;   // "/max" size
// Vertical drop of the "/max" so its baseline (the digits' "feet") sits on the
// same line as the big value's feet. Derived from the size difference; tune the
// 0.8 (or add px) if your font's metrics make the feet sit slightly high/low.
var _small_dy = (_big_px - _small_px) * 1;

var _sb = _big_px   / _font_base;   // big-text scale
var _ss = _small_px / _font_base;   // small-text scale

draw_set_font(Font1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// Text color tracks the bar color — same active-segment lookup the bars use
// (col_hp/col_mp[active]), so each number switches color exactly when its bar
// does. Mirrors the math inside draw_segment_bar.
var _hp_col = col_hp[clamp(floor(_p.hp / (_p.maxHp  / seg_count)), 0, seg_count - 1)];
var _mp_col = col_mp[clamp(floor(_p.mp / (_p.mp_max / seg_count)), 0, seg_count - 1)];

// HP: floor(hp) big, /maxHp small (small baseline-aligned to the big feet)
draw_set_colour(_hp_col);
var _hc = string(floor(_p.hp));
var _hm = "/" + string(floor(_p.maxHp));
draw_text_transformed(_hp_tx, _hp_ty, _hc, _sb, _sb, 0);
draw_text_transformed(_hp_tx + string_width(_hc) * _sb, _hp_ty + _small_dy, _hm, _ss, _ss, 0);

// MP: floor(mp) big, /mp_max small
draw_set_colour(_mp_col);
var _mc = string(floor(_p.mp));
var _mm = "/" + string(floor(_p.mp_max));
draw_text_transformed(_mp_tx, _mp_ty, _mc, _sb, _sb, 0);
draw_text_transformed(_mp_tx + string_width(_mc) * _sb, _mp_ty + _small_dy, _mm, _ss, _ss, 0);

draw_set_font(-1);   // back to default

// ==========================================
// RESET DRAW STATE
// ==========================================
draw_set_colour(c_white);
draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
