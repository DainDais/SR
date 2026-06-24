// Reference to the character that owns this hitbox
owner = noone;

// Team identifier (for collision filtering)
team = "player";  // or "enemy"

// Attack properties (set these when spawning)
damage = 10;
postureDamage = 0;  // posture damage dealt on a non-parried hit (0 = none)
knockbackX = 0;
knockbackY = 0;
strengthLevel = 1;  // tier used for charged-parry overcharge comparison

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

// Cached bounds (updated each Step; initialized to zero so they exist on frame 1)
hbLeft   = 0;
hbRight  = 0;
hbTop    = 0;
hbBottom = 0;

// Visual debug
debug_show = false;
debug_color = c_yellow;
debug_alpha = 0.5;

// Depth
depth = -100;
