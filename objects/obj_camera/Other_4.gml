// Kill the room's built-in follow target — if it's set, it overrides
// camera_set_view_pos every frame and camOffsetX/Y stop working. The room
// editor tends to re-add it on save, so clear it here at runtime.
camera_set_view_target(view_camera[0], noone);

// Apply zoom — the room files still say 480x270, but this runs every Room
// Start (camera is persistent), so camWidth/camHeight are the source of truth
camera_set_view_size(view_camera[0], camWidth, camHeight);

// Start at player position
if (instance_exists(obj_player))
{
    x = obj_player.x;
    y = obj_player.y;
    xTo = x;
    yTo = y;
}

// Disable sprite smoothing
gpu_set_texfilter(false);
