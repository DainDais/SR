// Fullscreen toggle
if keyboard_check_pressed(vk_f8)
{
    window_set_fullscreen(!window_get_fullscreen());
}

// Follow target with look-ahead
if (follow != noone && instance_exists(follow))
{
    // Add velocity-based offset to camera target
    xTo = follow.x + (follow.xspd * lookAheadDist);
    yTo = follow.y + (follow.yspd * lookAheadDist);
}

// Smooth camera movement
x += (xTo - x)/25;
y += (yTo - y)/25;

// Position the view: centered on (x,y) plus the manual offset.
// Rounded so the pixel grid stays stable while easing.
camera_set_view_pos(view_camera[0],
    round(x - camWidth  * 0.5 + camOffsetX),
    round(y - camHeight * 0.5 + camOffsetY));
