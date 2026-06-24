// =============================================================================
// HUD — colors, layout constants, sprite lookups, threshold helpers.
//
// HP and MP bars are SEGMENTED: 5 separate parallelogram segments per bar,
// each worth exactly 20% of the resource, with a small gap between them.
// Only one segment drains at a time (right to left within itself); segments
// left of it are full, segments right of it are empty. Bar color is tied to
// which segment is active, not to a % of the total.
// HP and MP are horizontal mirrors of each other (hp_flip / mp_flip below);
// the MP bar is navy blue.
//
// Sprites are resolved by name at runtime (asset_get_index). Until they are
// imported, each meter falls back to primitive drawing so the HUD always
// renders. Import sprites with these exact names to switch over automatically:
//   spr_bar_fill      153x50   pure white parallelogram — ONE segment
//   spr_bar_bg        153x50   dark parallelogram — ONE empty segment
//   spr_posture_fill  816x117  pure white staircase (wings + center connector)
//   spr_posture_frame 816x117  outline + < > brackets + center pin
// All imported with Nearest Neighbour sampling, origin top-left.
// =============================================================================

#region COLORS
	// HP bar — color follows the active segment (index = active segment, 0 = leftmost)
	col_hp[0] = make_colour_rgb(107,   0,  16);  // only segment 0 remains
	col_hp[1] = make_colour_rgb(144,  18,  16);  // segments 2–4 gone
	col_hp[2] = make_colour_rgb(181,  36,  16);  // segments 3–4 gone
	col_hp[3] = make_colour_rgb(218,  54,  16);  // segment 4 gone
	col_hp[4] = make_colour_rgb(255,  72,  16);  // rightmost segment still has HP

	// MP bar
	col_mp[0] = make_colour_rgb(  6,  11,  45);
	col_mp[1] = make_colour_rgb( 16,  32,  94);
	col_mp[2] = make_colour_rgb( 26,  53, 143);
	col_mp[3] = make_colour_rgb( 36,  74, 192);
	col_mp[4] = make_colour_rgb( 47,  94, 239);

	// Posture bar — threshold on total %, index 0 = critical
	col_pos[0] = make_colour_rgb(243,  28,   7);  //  0–16%  Critical
	col_pos[1] = make_colour_rgb(247,  90,   0);  // 17–33%  Danger
	col_pos[2] = make_colour_rgb(247, 183,   0);  // 34–50%  Caution
	col_pos[3] = make_colour_rgb(215, 245,   0);  // 51–66%  Guarded
	col_pos[4] = make_colour_rgb(167, 246,   0);  // 67–83%  Stable
	col_pos[5] = make_colour_rgb( 43, 248,   0);  // 84–100% Safe

	// Empty-segment background (used by primitive fallback for HP/MP)
	col_bar_bg = make_colour_rgb(24, 20, 28);
#endregion

#region HP / MP SEGMENT GEOMETRY
	seg_count = 5;     // segments per bar, each = 20% of the resource
	seg_w     = 153;   // native segment sprite width
	seg_h     = 50;    // native segment sprite height
	seg_slant = 25;    // horizontal run of each diagonal side (native)
	seg_gap   = 4;     // gap between segments, in display pixels

	// Target total bar size from the Pixelmator layout (all 5 segments + gaps).
	bar_total_w = 423;
	bar_total_h = 36;

	// Per-segment display size and scale, derived to hit the total exactly:
	//   bar_total_w = seg_count*seg_disp_w + (seg_count-1)*seg_gap
	seg_disp_w  = (bar_total_w - seg_gap * (seg_count - 1)) / seg_count;  // 81.4
	seg_scale_x = seg_disp_w / seg_w;    // 0.532
	seg_scale_y = bar_total_h / seg_h;   // 0.72

	// Horizontal mirroring per bar (true = segments drawn mirrored).
	// Depletion stays right-to-left on screen either way.
	hp_flip = false;
	mp_flip = true;
#endregion

#region POSTURE BAR GEOMETRY (sprite space)
	// Wing/connector coordinates measured from the imported spr_posture_fill
	// artwork (shape spans x 27–788, y 21–95 in the 816x117 canvas).
	pos_center_x    = 393;   // left wing ends / center connector starts
	pos_center_rw   = 429;   // center connector ends / right wing starts
	pos_center_w    = 36;    // connector width (always drawn)
	pos_center_y1   = 21;    // connector top
	pos_center_y2   = 95;    // connector bottom
	pos_wing_span_l = 366;   // left wing span  (27→393)
	pos_wing_span_r = 360;   // right wing span (429→789)
	pos_mirror      = 815;   // fallback-only mirror axis x2 (≈ shape center)
	pos_sprite_w    = 816;
	pos_sprite_h    = 117;

	// Visible staircase bounds inside the 816x117 canvas (alpha bbox).
	pos_shape_x = 27;   pos_shape_w = 762;   // x 27–788
	pos_shape_y = 21;   pos_shape_h = 75;    // y 21–95

	// Left-wing staircase steps as [x1, x2, y1, y2], innermost first.
	// Fallback-only (unused while the posture sprites exist).
	pos_steps = [
		[354, 393, 27, 89],
		[261, 354, 30, 86],
		[168, 261, 33, 83],
		[ 75, 168, 36, 80],
		[ 27,  75, 39, 77],
	];
#endregion

#region LAYOUT (GUI-space, 1920x1080)
	// All positions are the TOP-LEFT of the element's bounding box — Pixelmator
	// Pro's position field reports top-left (origin 0,0 at canvas top-left).

	// Vitals background — decorative art behind the HP/MP bars. Drawn via
	// draw_sprite_stretched into this exact box, so it fills it regardless of
	// the PNG's native size or origin.
	vitals_x = 60;    vitals_y = 12;
	vitals_w = 592;   vitals_h = 229;

	// HP / MP bars — top-left of the whole 5-segment bar
	hp_x = 270;   hp_y =  86;
	mp_x = 270;   mp_y = 144;

	// Posture bar — fit the visible staircase into the target box (top-left
	// 572,974, size 774x69). Scales are non-uniform to match the box exactly.
	pos_box_x = 572;   pos_box_y = 974;
	pos_box_w = 774;   pos_box_h =  30;
	pos_scale_x = pos_box_w / pos_shape_w;   // 1.016
	pos_scale_y = pos_box_h / pos_shape_h;   // 0.92

	// Draw the full canvas so the shape's top-left lands at the box top-left.
	pos_x = pos_box_x - pos_shape_x * pos_scale_x;
	pos_y = pos_box_y - pos_shape_y * pos_scale_y;
#endregion

#region SPRITE LOOKUPS (-1 until the sprite is imported)
	sprBarFill      = asset_get_index("spr_bar_fill");
	sprBarBg        = asset_get_index("spr_bar_bg");
	sprPostureFill  = asset_get_index("spr_posture_fill");
	sprPostureFrame = asset_get_index("spr_posture_frame");

	// Decorative static art (drawn behind the bars)
	sprVitalsBG     = asset_get_index("spr_vitalsBG");

	// Surface for the MP active segment — clipping and flipping can't be
	// combined in one sprite call, so the clipped fill is rendered here and
	// the surface is drawn mirrored.
	surf_mp = -1;
#endregion

#region POSTURE THRESHOLD HELPER — color snaps per band, never blended
	function get_posture_color(_pct)
	{
		if (_pct >= 0.84) return col_pos[5];
		if (_pct >= 0.67) return col_pos[4];
		if (_pct >= 0.51) return col_pos[3];
		if (_pct >= 0.34) return col_pos[2];
		if (_pct >= 0.17) return col_pos[1];
		return col_pos[0];
	}
#endregion

#region SEGMENTED BAR DRAWER (HP / MP)

	// One parallelogram segment via primitives, clipped at sprite-space width
	// _cw. Used until spr_bar_fill / spr_bar_bg are imported. The clipped
	// shape is always convex, so a triangle fan covers every case.
	// _flip draws the horizontally-mirrored (MP) segment: mirroring the
	// right-clipped region horizontally equals mirroring the left-clipped
	// region vertically, so a y-mirror of the same points is all it takes.
	function draw_para_fill(_x, _y, _cw, _col, _flip = false)
	{
		if (_cw <= 0) exit;
		_cw = min(_cw, seg_w);

		var _pts;
		if (_cw <= seg_slant)
		{
			// clip line crosses the left diagonal
			var _yd = seg_h * (1 - _cw / seg_slant);
			_pts = [[0, seg_h], [_cw, _yd], [_cw, seg_h]];
		}
		else if (_cw <= seg_w - seg_slant)
		{
			_pts = [[0, seg_h], [seg_slant, 0], [_cw, 0], [_cw, seg_h]];
		}
		else if (_cw < seg_w)
		{
			// clip line crosses the right diagonal
			var _yd = seg_h * (seg_w - _cw) / seg_slant;
			_pts = [[0, seg_h], [seg_slant, 0], [_cw, 0], [_cw, _yd], [seg_w - seg_slant, seg_h]];
		}
		else
		{
			_pts = [[0, seg_h], [seg_slant, 0], [seg_w, 0], [seg_w - seg_slant, seg_h]];
		}

		draw_primitive_begin(pr_trianglefan);
		for (var i = 0; i < array_length(_pts); i++)
		{
			var _py = _flip ? (seg_h - _pts[i][1]) : _pts[i][1];
			draw_vertex_colour(_x + _pts[i][0] * seg_scale_x, _y + _py * seg_scale_y, _col, 1);
		}
		draw_primitive_end();
	}

	// Draws a full 5-segment bar at (_x,_y). _cols is the per-active-segment
	// color array. _flip mirrors every segment horizontally (see hp_flip /
	// mp_flip in the geometry region).
	function draw_segment_bar(_x, _y, _val, _max, _cols, _flip)
	{
		if (_max <= 0) exit;

		var _seg_size = _max / seg_count;
		var _active   = clamp(floor(_val / _seg_size), 0, seg_count - 1);
		var _fill_pct = clamp((_val - _active * _seg_size) / _seg_size, 0, 1);
		var _col      = _cols[_active];   // uniform across all visible segments
		var _sw       = seg_w * seg_scale_x;   // one segment's display width
		var _use_fill = sprite_exists(sprBarFill);
		var _use_bg   = sprite_exists(sprBarBg);

		for (var i = 0; i < seg_count; i++)
		{
			var _sx = _x + i * (_sw + seg_gap);

			// ---- Full segment (left of the active one) ----
			if (i < _active)
			{
				if (_use_fill)
				{
					if (_flip) draw_sprite_ext(sprBarFill, 0, _sx + _sw, _y, -seg_scale_x, seg_scale_y, 0, _col, 1);
					else       draw_sprite_ext(sprBarFill, 0, _sx,       _y,  seg_scale_x, seg_scale_y, 0, _col, 1);
				}
				else
				{
					draw_para_fill(_sx, _y, seg_w, _col, _flip);
				}
				continue;
			}

			// ---- Background — under the active segment and on lost segments ----
			if (_use_bg)
			{
				if (_flip) draw_sprite_ext(sprBarBg, 0, _sx + _sw, _y, -seg_scale_x, seg_scale_y, 0, c_white, 1);
				else       draw_sprite_ext(sprBarBg, 0, _sx,       _y,  seg_scale_x, seg_scale_y, 0, c_white, 1);
			}
			else
			{
				draw_para_fill(_sx, _y, seg_w, col_bar_bg, _flip);
			}

			if (i > _active) continue;   // lost segment — background only

			// ---- Active segment — fill clipped within this 20% tier ----
			var _clip_w = seg_w * _fill_pct;
			if (_clip_w <= 0) continue;

			if (!_use_fill)
			{
				draw_para_fill(_sx, _y, _clip_w, _col, _flip);
			}
			else if (!_flip)
			{
				draw_sprite_part_ext(sprBarFill, 0, 0, 0, _clip_w, seg_h,
					_sx, _y, seg_scale_x, seg_scale_y, _col, 1);
			}
			else
			{
				// Flipped + clipped: render the clip to a native-size surface,
				// then draw it mirrored + scaled. Clip from the sprite's RIGHT
				// side so the mirrored fill still depletes right-to-left.
				if (!surface_exists(surf_mp)) surf_mp = surface_create(seg_w, seg_h);
				surface_set_target(surf_mp);
				draw_clear_alpha(c_black, 0);
				draw_sprite_part_ext(sprBarFill, 0, seg_w - _clip_w, 0, _clip_w, seg_h,
					seg_w - _clip_w, 0, 1, 1, _col, 1);
				surface_reset_target();
				draw_surface_ext(surf_mp, _sx + _sw, _y, -seg_scale_x, seg_scale_y, 0, c_white, 1);
			}
		}
	}
#endregion

#region POSTURE PRIMITIVE FALLBACK — used until the posture sprites are imported

	// Staircase fill: center connector always, wings clipped symmetrically.
	function draw_posture_fill_fallback(_t, _col)
	{
		var _clip_l = pos_center_x  - pos_wing_span_l * _t;  // left wing visible where x >= this
		var _clip_r = pos_center_rw + pos_wing_span_r * _t;  // right wing visible where x <= this
		var _sx = pos_scale_x;
		var _sy = pos_scale_y;

		draw_set_colour(_col);

		// Center connector — the minimum state of the bar
		draw_rectangle(
			pos_x + pos_center_x  * _sx, pos_y + pos_center_y1 * _sy,
			pos_x + pos_center_rw * _sx, pos_y + pos_center_y2 * _sy, false);

		for (var i = 0; i < array_length(pos_steps); i++)
		{
			var _x1 = pos_steps[i][0];
			var _x2 = pos_steps[i][1];
			var _y1 = pos_steps[i][2];
			var _y2 = pos_steps[i][3];

			// Left wing — clip the outer (left) edge inward
			var _lx1 = max(_x1, _clip_l);
			if (_lx1 < _x2)
			{
				draw_rectangle(
					pos_x + _lx1 * _sx, pos_y + _y1 * _sy,
					pos_x + _x2  * _sx, pos_y + _y2 * _sy, false);
			}

			// Right wing (mirrored) — clip the outer (right) edge inward
			var _rx1 = pos_mirror - _x2;
			var _rx2 = min(pos_mirror - _x1, _clip_r);
			if (_rx1 < _rx2)
			{
				draw_rectangle(
					pos_x + _rx1 * _sx, pos_y + _y1 * _sy,
					pos_x + _rx2 * _sx, pos_y + _y2 * _sy, false);
			}
		}

		draw_set_colour(c_white);
	}
#endregion
