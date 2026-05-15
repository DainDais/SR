// =============================================================================
// PLAYER FX SYSTEM
// Manages afterimage trails and dust/particle FX spawning.
// Both systems live here since they share the same "one call per step" pattern.
//
// Required variables on the entity:
//   isDashing, isBackStepping, airState, wallJumpLockTimer, xspd, yspd, grappling
//   afterimageEnabled, afterimageTimer, afterimageSpawnRate, afterimageColor
//   afterimageColorDash, afterimageColorBackStep, afterimageColorWallJump
//   afterimageColorSpeed, afterimageColorGrapple
//   sprite_index, image_index, image_xscale, image_yscale, image_angle, face
//   prevJumpCount, jumpCount, prevAirStateWallJump, prevWallDir
//   prevJumpCountDouble, prevOnGround, onGround, runDustTimer, myWallSlideFX
//   wallStickTimer, groundState, dashLockFrames, dashLockTimer
//   backStepLockFrames, backStepLockTimer
//   AirState, GroundState enums
// =============================================================================

// -----------------------------------------------------------------------------
// updateFX()
// Call after updateAnimation(), before tickInputLocks().
// -----------------------------------------------------------------------------
function updateFX() {

    // =========================================================================
    // AFTERIMAGE
    // =========================================================================
    afterimageEnabled = false;

    if (isDashing) {
        afterimageEnabled = true;
        afterimageColor   = afterimageColorDash;
    }

    if (isBackStepping) {
        afterimageEnabled = true;
        afterimageColor   = afterimageColorBackStep;
    }

    if (airState == AirState.A_WALLJUMP && wallJumpLockTimer > 0) {
        afterimageEnabled = true;
        afterimageColor   = afterimageColorWallJump;
    }

    if (abs(xspd) > 4 || abs(yspd) > 4) {
        afterimageEnabled = true;
        afterimageColor   = afterimageColorSpeed;
    }

    if (grappling) {
        afterimageEnabled = true;
        afterimageColor   = afterimageColorGrapple;
    }

    if (afterimageEnabled) {
        afterimageTimer++;
        if (afterimageTimer >= afterimageSpawnRate) {
            var _afterimage = instance_create_depth(x, y, depth + 1, obj_afterimage);
            _afterimage.stored_sprite  = sprite_index;
            _afterimage.stored_frame   = image_index;
            _afterimage.stored_x       = x;
            _afterimage.stored_y       = y;
            _afterimage.stored_xscale  = image_xscale * face;
            _afterimage.stored_yscale  = image_yscale;
            _afterimage.stored_angle   = image_angle;
            _afterimage.stored_color   = afterimageColor;
            afterimageTimer = 0;
        }
    } else {
        afterimageTimer = 0;
    }

    // =========================================================================
    // DUST & PARTICLE FX
    // =========================================================================
    var _isWallSliding = (airState == AirState.A_WALLCLING && wallStickTimer <= 0);

    // Dash start
    if (isDashing && dashLockTimer == dashLockFrames - 1) {
        spawnFX(obj_fxDashDust, 1);
    }

    // Backstep start
    if (isBackStepping && backStepLockTimer == backStepLockFrames - 1) {
        spawnFX(obj_fxBackStepDust, 1);
    }

    // First jump / coyote jump
    if (jumpCount > prevJumpCount && jumpCount == 1) {
        spawnFX(obj_fxJumpDust, 1);
    }
    prevJumpCount = jumpCount;

    // Wall jump
    if (prevAirStateWallJump == AirState.A_WALLCLING && airState == AirState.A_WALLJUMP) {
        var _wjFX = spawnFX(obj_fxWallJumpDust, 1);
        _wjFX.fxDirection = prevWallDir;
    }
    prevAirStateWallJump = airState;

    // Double jump
    if (jumpCount > prevJumpCountDouble && jumpCount == 2) {
        spawnFX(obj_fxDoubleJump, -1);
    }
    prevJumpCountDouble = jumpCount;

    // Landing
    if (onGround && !prevOnGround) {
        spawnFX(obj_fxLandingDust, 1);
    }
    prevOnGround = onGround;

    // Run dust (continuous while sprinting)
    if (onGround && groundState == GroundState.G_RUN && abs(xspd) > 2) {
        runDustTimer++;
        if (runDustTimer >= 8) {
            spawnFX(obj_fxRunDust, 1);
            runDustTimer = 0;
        }
    } else {
        runDustTimer = 0;
    }

    // Wall slide (persistent FX object)
    if (_isWallSliding && !instance_exists(myWallSlideFX)) {
        myWallSlideFX = spawnFX(obj_fxWallSlide, -1);
    }

    if (!instance_exists(myWallSlideFX)) {
        myWallSlideFX = noone;
    }
}
