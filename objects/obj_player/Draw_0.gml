draw_sprite_ext(sprite_index, image_index, x, y, image_xscale * face, image_yscale, image_angle, image_blend, image_alpha);

if (grappling && instance_exists(grappleTarget)) {
    draw_set_alpha(1);
    draw_set_colour(c_white);
    draw_line_width(x, y, grappleTarget.x, grappleTarget.y, 2);
}

#region Grapple Scan Visualizer
if (debug_grapple_show)
{
    var r = grapple_get_scan_rect();
    var left   = r[0];
    var top    = r[1];
    var right  = r[2];
    var bottom = r[3];
    
    draw_set_alpha(0.2);
    draw_set_color(c_lime);
    draw_rectangle(left, top, right, bottom, false);
    
    draw_set_alpha(1);
    draw_set_color(c_green);
    draw_rectangle(left, top, right, bottom, true);
    
    draw_line(x, y, x + face * (grappleScanWidth * 0.5 + 8), y);
    
    var list = ds_list_create();
    var n = collision_rectangle_list(left, top, right, bottom, obj_grapplePoint, false, false, list, false);
    
    for (var i = 0; i < n; i++)
    {
        var gp = list[| i];
        
        if ((gp.x - x) * face <= 0) continue;
        if (gp.y > y) continue;
        
        if (instance_exists(grappleTarget) && gp == grappleTarget)
        {
            draw_set_colour(c_yellow);
            draw_circle(gp.x, gp.y, 6, false);
            draw_circle(gp.x, gp.y, 3, false);
        }
        else
        {
            draw_set_colour(c_aqua);
            draw_rectangle(gp.x - 3, gp.y - 3, gp.x + 3, gp.y + 3, false);
        }
    }
    
    ds_list_destroy(list);
    
    draw_set_colour(c_white);
    draw_set_alpha(1);
}
#endregion

#region Parry Bubble
// Visual placeholder for the parry state — drawn as a circle over the player.
// Color rules:
//   P_INITIAL / P_SEQUENTIAL : white,  alpha 0.75
//   P_CHARGING  level 2      : blue,   alpha 0.75
//   P_CHARGING  level 3      : red,    alpha 0.75
//   P_CHARGE_ACTIVE          : matches resolved charge level (blue/red)
if (isParrying) {
    var _bubbleColor = -1;   // -1 = don't draw

    if (parryState == ParryState.P_INITIAL || parryState == ParryState.P_SEQUENTIAL) {
        _bubbleColor = c_white;
    } else if (parryState == ParryState.P_CHARGING || parryState == ParryState.P_CHARGE_ACTIVE) {
        if (parryChargeLevel >= 3) {
            _bubbleColor = c_red;
        } else if (parryChargeLevel >= 2) {
            _bubbleColor = c_blue;
        }
    }

    if (_bubbleColor != -1) {
        var _bubbleX = x;
        var _bubbleY = bbox_top + (bbox_bottom - bbox_top) * 0.35;
        draw_set_alpha(0.75);
        draw_set_color(_bubbleColor);
        draw_circle(_bubbleX, _bubbleY, 18, false);
    }
}
#endregion

draw_set_alpha(1);
draw_set_colour(c_white);