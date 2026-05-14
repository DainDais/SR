// Reference to the character that owns this hitbox
owner = noone;

// Team identifier (for collision filtering)
team = "player";  // or "enemy"

// Attack properties (set these when spawning)
damage = 10;
knockbackX = 0;
knockbackY = 0;

// Size (set when spawning, or use owner's sprite)
hitboxWidth = 32;
hitboxHeight = 32;

// Behavior
followOwner = true;  // Does it stick to owner?
offsetX = 0;  // Offset from owner
offsetY = 0;

// Lifetime (0 = infinite, destroyed manually)
lifetime = 0;
lifetimeTimer = 0;

// Hit tracking
hitList = ds_list_create();  // What's been hit already
destroyOnHit = false;  // Destroy after first hit?

// Visual debug
debug_show = false;
debug_color = c_yellow;
debug_alpha = 0.5;

// Depth
depth = -100;
