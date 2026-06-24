// Destroy if owner is destroyed
if (!instance_exists(owner))
{
    instance_destroy();
    exit;
}

// Calculate hitbox bounding box
var _hbLeft, _hbRight, _hbTop, _hbBottom;

if (followOwner)
{
    // Simply multiply X values by face direction - works for both sides
    var _nearEdge = owner.x + (offsetX * owner.face);
    var _farEdge  = _nearEdge + (hitboxWidth * owner.face);
    
    // Ensure left < right regardless of direction
    _hbLeft  = min(_nearEdge, _farEdge);
    _hbRight = max(_nearEdge, _farEdge);
    
    _hbTop    = owner.y + offsetY;
    _hbBottom = owner.y + offsetY + hitboxHeight;
}
else
{
    // Independent hitbox (projectiles, etc.) — centered on x,y
    _hbLeft   = x - hitboxWidth  * 0.5;
    _hbRight  = x + hitboxWidth  * 0.5;
    _hbTop    = y - hitboxHeight * 0.5;
    _hbBottom = y + hitboxHeight * 0.5;
}

// Store bounds for drawing and collision
hbLeft   = _hbLeft;
hbRight  = _hbRight;
hbTop    = _hbTop;
hbBottom = _hbBottom;

// Update position for drawing (center of hitbox)
x = (_hbLeft + _hbRight) / 2;
y = (_hbTop + _hbBottom) / 2;

// Scale is always positive
image_xscale = hitboxWidth;
image_yscale = hitboxHeight;

// Lifetime countdown
if (lifetime > 0)
{
    lifetimeTimer++;
    if (lifetimeTimer >= lifetime)
    {
        instance_destroy();
        exit;
    }
}

// --- COLLISION DETECTION ---
// Use collision_rectangle for precise, origin-independent collision
var _hitHurtbox = collision_rectangle(_hbLeft, _hbTop, _hbRight, _hbBottom, obj_hurtbox, false, true);

if (_hitHurtbox != noone)
{
    // Filter: Don't hit your own hurtbox; don't hit same-team targets (friendly fire)
    var _sameTeam = (variable_instance_exists(_hitHurtbox.owner, "team")
                  && variable_instance_exists(id, "team")
                  && _hitHurtbox.owner.team == team);

    if (_hitHurtbox.owner != owner && !_sameTeam)
    {
        // Check if we've already hit this target
        var _alreadyHit = false;
        for (var i = 0; i < ds_list_size(hitList); i++)
        {
            if (hitList[| i] == _hitHurtbox.owner)
            {
                _alreadyHit = true;
                break;
            }
        }
        
        // If not already hit, deal damage or register a parry
        if (!_alreadyHit)
        {
            // Add to hit list (prevents double-hit regardless of parry or damage)
            ds_list_add(hitList, _hitHurtbox.owner);

            var _target = _hitHurtbox.owner;

            // Pre-calculate values while still in hitbox context
            var _dmg        = damage;
            var _postureDmg = postureDamage;
            var _kbX  = instance_exists(owner) ? knockbackX * owner.face : knockbackX;
            var _kbY  = knockbackY;
            var _str  = strengthLevel;

            // Parry window check: redirect to parry handler instead of damage
            if (instance_exists(_target)
            && variable_instance_exists(_target, "isParryWindowActive")
            && _target.isParryWindowActive)
            {
                with (_target) { triggerParrySuccess(_dmg, _kbX, _str); }
            }
            else if (instance_exists(_target) && variable_instance_exists(_target, "hp"))
            {
                with (_target) {
                    // Posture damage only lands when the hit connects (not blocked by i-frames)
                    if (take_damage(_dmg, _kbX, _kbY)) { take_posture_damage(_postureDmg); }
                }
            }

            // Destroy hitbox if set to destroy on hit
            if (destroyOnHit)
            {
                instance_destroy();
                exit;
            }
        }
    }
}
// --- END COLLISION DETECTION ---
