x += lengthdir_x(orbSpeed, dir);
y += lengthdir_y(orbSpeed, dir);

// Sync embedded hitbox position to orb
if (instance_exists(myHitbox))
{
    myHitbox.x      = x;
    myHitbox.y      = y;
    myHitbox.owner  = owner;   // in case owner was set after Create
}
else
{
    // Hitbox was destroyed — it hit something; destroy the orb too
    instance_destroy();
    exit;
}

lifetimer++;
if (lifetimer >= lifetime) {
    instance_destroy();
}
