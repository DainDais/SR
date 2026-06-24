// === IDENTITY ===
face = 1;
team = "enemy";

// === HEALTH (via entity_health script) ===
// initHealth(hp, maxHp, invincibleFrames)
initHealth(50, 50, 10);

// === HURTBOX ===
myHurtbox = instance_create_depth(x, y, depth + 1, obj_hurtbox);
myHurtbox.owner      = id;
myHurtbox.debug_show = true;
myHurtbox.debug_color = c_lime;

// === SHOOTING ===
shootTimer    = 0;
shootInterval = 180;  // fire every 3 seconds at 60fps
