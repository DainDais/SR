// F2 toggles the entire debug overlay
if (!variable_global_exists("debugOverlayVisible") || !global.debugOverlayVisible) exit;

draw_set_colour(c_white);

#region STATES SECTION
var _parentName = getParentStateName();
var _subName = (parentState == ParentState.GROUND)
    ? getGroundStateName()
    : getAirStateName();

draw_text(16, 16, "=== STATES ===");
draw_text(16, 32, "Parent: " + _parentName);
draw_text(16, 48, "Substate: " + _subName);
#endregion

#region GLOBAL STATES SECTION
draw_text(16, 80, "=== GLOBAL STATES ===");
draw_text(16, 96, "Attacking: " + string(isAttacking));
draw_text(16, 112, "Dashing: " + string(isDashing));
draw_text(16, 128, "BackStepping: " + string(isBackStepping));
draw_text(16, 144, "Climbing: " + string(isClimbing));
draw_text(16, 160, "Grappling: " + string(grappling));
draw_text(16, 176, "LedgeGrab: " + string(isLedgeGrabbing));

// Attack details (y=232/248 — between Dash Cooldown and Locks, nothing else uses these slots)
if (isAttacking)
{
    draw_text(16, 232, "  Attack: " + attackName);
    draw_text(16, 248, "  Frame: " + string(floor(image_index)) + "/" + string(sprite_get_number(sprite_index) - 1));
}

// Grapple details
if (instance_exists(grappleTarget))
{
    draw_text(16, 192, "  Target: " + string(grappleTarget));
}

// Dash info
draw_text(16, 208, "Dash Charges: " + string(dashCharges) + "/" + string(dashChargesMax));
draw_text(16, 224, "Dash Cooldown: " + string(dashCooldownTimer));
#endregion

#region LOCKS SECTION
draw_text(16, 256, "=== LOCKS ===");
draw_text(16, 272, "Move Lock: " + string(inputLockMove));
draw_text(16, 288, "Face Lock: " + string(inputLockFace));
draw_text(16, 304, "Jump Lock: " + string(inputLockJump));
draw_text(16, 320, "lockX: " + string(lockX));
draw_text(16, 336, "lockY: " + string(lockY));
draw_text(16, 352, "Gravity Override: " + string(gravityOverride));
#endregion

#region HITBOX DEBUG
// Check if any hitbox exists and is colliding
var _hitboxActive = instance_exists(obj_hitbox);
var _hitboxColliding = false;
var _hitboxX = 0;
var _hitboxY = 0;
var _hitboxOwnerX = 0;
var _playerFace = face;

if (_hitboxActive)
{
    with (obj_hitbox)
    {
        // Only show debug info for hitboxes owned by the player
        if (owner != other.id) continue;
        other._hitboxX = x;
        other._hitboxY = y;
        other._hitboxOwnerX = owner.x;
        
        var _checkHurtbox = instance_place(x, y, obj_hurtbox);
        if (_checkHurtbox != noone && _checkHurtbox.owner != owner)
        {
            other._hitboxColliding = true;
        }
    }
}

draw_text(16, 384, "=== HITBOX ===");
draw_text(16, 400, "Active: " + string(_hitboxActive));
draw_text(16, 416, "Making Contact: " + string(_hitboxColliding));
draw_text(16, 432, "Player Face: " + string(_playerFace));
draw_text(16, 448, "Player X: " + string(round(_hitboxOwnerX)));
draw_text(16, 464, "Hitbox X: " + string(round(_hitboxX)));
draw_text(16, 480, "Offset: " + string(round(_hitboxX - _hitboxOwnerX)));
#endregion

#region HURTBOX DEBUG
if (instance_exists(myHurtbox))
{
    draw_text(16, 512, "=== HURTBOX ===");
    draw_text(16, 528, "Active: " + string(instance_exists(myHurtbox)));
    draw_text(16, 544, "Debug Visible: " + string(myHurtbox.debug_show) + " (F1)");
    draw_text(16, 560, "Size: " + string(round(myHurtbox.image_xscale)) + "x" + string(round(myHurtbox.image_yscale)));
}
#endregion

#region AFTERIMAGE DEBUG
draw_text(16, 592, "=== AFTERIMAGE ===");
draw_text(16, 608, "Enabled: " + string(afterimageEnabled));
draw_text(16, 624, "Timer: " + string(afterimageTimer) + "/" + string(afterimageSpawnRate));
draw_text(16, 640, "Afterimages in room: " + string(instance_number(obj_afterimage)));
draw_text(16, 656, "Speed (abs): " + string(abs(xspd)));
#endregion

#region PHYSICS DEBUG
draw_text(16, 688, "=== PHYSICS ===");
draw_text(16, 704, "onGround: " + string(onGround));
draw_text(16, 720, "xspd: " + string(round(xspd * 100) / 100));
draw_text(16, 736, "yspd: " + string(round(yspd * 100) / 100));
draw_text(16, 752, "wallDir: " + string(wallDir));
draw_text(16, 768, "wallStickTimer: " + string(wallStickTimer));
#endregion

#region HEALTH DEBUG
draw_text(300, 16, "=== HEALTH ===");

if (variable_instance_exists(id, "hp"))
{
    // Health bar tint: red when low, white otherwise
    var _hpFraction = (maxHp > 0) ? (hp / maxHp) : 0;
    if (_hpFraction <= 0.25)
        draw_set_colour(c_red);
    else if (_hpFraction <= 0.5)
        draw_set_colour(c_yellow);
    else
        draw_set_colour(c_white);

    draw_text(300, 32, "HP: " + string(hp) + " / " + string(maxHp));
    draw_set_colour(c_white);

    var _invincStr = isInvincible
        ? ("INVINCIBLE (" + string(invincibleTimer) + " frames left)")
        : "Vulnerable";
    if (isInvincible) draw_set_colour(c_aqua);
    draw_text(300, 48, _invincStr);
    draw_set_colour(c_white);
}
else
{
    draw_text(300, 32, "HP: (no health vars)");
}
#endregion

#region INCOMING HIT DEBUG
draw_text(300, 80, "=== INCOMING HIT ===");

// Check if any non-player hitbox overlaps the player's hurtbox right now
// Uses collision_rectangle with each enemy hitbox's stored bounds (same method obj_hitbox uses)
var _incomingHit   = false;
var _incomingDmg   = 0;
var _incomingOwner = noone;

with (obj_hitbox)
{
    // Skip hitboxes owned by the player
    if (owner == other.id) continue;

    // Ask: does this hitbox's bounding rect overlap any hurtbox owned by the player?
    var _h = collision_rectangle(hbLeft, hbTop, hbRight, hbBottom, obj_hurtbox, false, true);
    if (_h != noone && instance_exists(_h) && _h.owner == other.id)
    {
        other._incomingHit   = true;
        other._incomingDmg   = damage;
        other._incomingOwner = owner;
        break;
    }
}

if (_incomingHit) draw_set_colour(c_red);
draw_text(300, 96,  "Contact: " + (_incomingHit ? "YES  dmg=" + string(_incomingDmg) : "none"));
draw_set_colour(c_white);
draw_text(300, 112, "Src: " + (_incomingOwner != noone && instance_exists(_incomingOwner)
    ? object_get_name(_incomingOwner.object_index)
    : "-"));
#endregion

#region POSTURE DEBUG
draw_text(300, 144, "=== POSTURE ===");

if (variable_instance_exists(id, "posture"))
{
    // Posture readout tint: red when low, yellow at half, white otherwise
    var _postFraction = (posture_max > 0) ? (posture / posture_max) : 0;
    if (_postFraction <= 0.25)
        draw_set_colour(c_red);
    else if (_postFraction <= 0.5)
        draw_set_colour(c_yellow);
    else
        draw_set_colour(c_white);

    draw_text(300, 160, "Posture: " + string(posture) + " / " + string(posture_max));
    draw_set_colour(c_white);

    // Guarding = holding the charge-parry stance (halves posture damage)
    var _guarding = isParrying && parryState == ParryState.P_CHARGING;
    if (_guarding) draw_set_colour(c_aqua);
    draw_text(300, 176, "Guarding: " + string(_guarding)
        + (_guarding ? "  (x" + string(postureGuardMult) + ")" : ""));
    draw_set_colour(c_white);

    // Under-parry vulnerability window (amplified posture damage)
    if (postureVulnTimer > 0) draw_set_colour(c_orange);
    draw_text(300, 192, "Under-parry: " + (postureVulnTimer > 0
        ? string(postureVulnTimer) + "f  (x" + string(postureVulnMult) + ")"
        : "none"));
    draw_set_colour(c_white);

    // Hit / stun reaction state
    if (isStunned) draw_set_colour(c_red);
    else if (isHurt) draw_set_colour(c_orange);
    draw_text(300, 208, "React: " + (isStunned
        ? "STUNNED"
        : (isHurt ? "HURT (" + string(hurtTimer) + "f)" : "none")));
    draw_set_colour(c_white);
}
else
{
    draw_text(300, 160, "Posture: (no posture vars)");
}
#endregion

draw_set_colour(c_white);