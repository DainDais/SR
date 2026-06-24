// === DAMAGE ORB — projectile fired by enemies ===
// Set owner, team, and dir from the spawning enemy right after creation.

owner    = noone;    // set by enemy after spawn
team     = "enemy";  // set by enemy after spawn
dir      = 0;        // angle in degrees; set by enemy after spawn

orbSpeed    = 3;     // pixels per frame
orbDamage   = 10;
orbPostureDamage = 1; // posture damage dealt to the player on hit
orbStrength = 1;      // attack strength level — parry below this under-parries, above over-parries
knockX      = 3;     // applied in the direction of travel (signed by hitbox)
knockY      = -2;

lifetime    = 180;   // auto-destroy after 3 sec (at 60fps)
lifetimer   = 0;

// Spawn embedded hitbox — non-follow (projectile mode)
myHitbox = instance_create_depth(x, y, depth, obj_hitbox);
myHitbox.owner        = owner;  // synced each step since owner is set after Create
myHitbox.team         = team;
myHitbox.followOwner  = false;
myHitbox.destroyOnHit = true;
myHitbox.damage        = orbDamage;
myHitbox.postureDamage = orbPostureDamage;
myHitbox.strengthLevel = orbStrength;
myHitbox.knockbackX   = knockX;
myHitbox.knockbackY   = knockY;
myHitbox.hitboxWidth  = sprite_get_width(spr_damageOrb);
myHitbox.hitboxHeight = sprite_get_height(spr_damageOrb);
