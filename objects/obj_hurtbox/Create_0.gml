// Reference to the character that owns this hurtbox
owner = noone;

// Visual debug toggle
debug_show = false;
debug_color = c_red;
debug_alpha = 0.4;

// Hit flash effect
hit_flash_timer = 0;
hit_flash_color = c_blue;

// Depth slightly above owner so it's visible in debug
depth = -100;

// Hit detection (to be used later)
canBeHit = true;