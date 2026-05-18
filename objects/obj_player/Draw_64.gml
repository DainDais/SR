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