// =============================================================================
// ENTITY GRAVITY & JUMP SYSTEM
// Universal. Call from any entity that uses gravity and jumping.
//
// Required variables on the entity:
//   grav, gravityOverride, isClimbing, airState, wallSlideAccel, wallSlideSpeed
//   lockY, yspd, coyoteHangTimer, coyoteHangFrames, onGround
//   coyoteJumpTimer, coyoteJumpFrames, jumpCount, jumpMax
//   jumpKeyBuffered, jumpKeyBufferTimer, downKey, jumpHoldTimer, jumpHoldFrames[]
//   jspd[], jumpKey
//
// Entity-specific resets on landing (e.g. dashCharges) belong in their own scripts.
// =============================================================================

// -----------------------------------------------------------------------------
// applyGravity()
// Accumulates yspd each frame. Handles coyote hang, wall slide, and override.
// Call this AFTER updateStateMachine() so airState is current.
// -----------------------------------------------------------------------------
function applyGravity() {
    if (coyoteHangTimer > 0) {
        coyoteHangTimer--;
    } else {
        if (!gravityOverride && !isClimbing) {
            if (airState == AirState.A_WALLCLING) {
                // Wall slide: freeze or drift down slowly
                if (lockY) {
                    yspd = 0;
                } else {
                    yspd = min(yspd + wallSlideAccel, wallSlideSpeed);
                }
            } else {
                yspd += grav;
            }
        }

        if (!isClimbing) {
            setOnGround(false);
        }
    }
}

// -----------------------------------------------------------------------------
// applyJump()
// Manages coyote jump window, jump execution, variable height, and lockY.
// Call after applyGravity(), before resolveYCollision().
// -----------------------------------------------------------------------------
function applyJump() {
    // Ground resets
    if (onGround) {
        jumpCount     = 0;
        jumpHoldTimer = 0;
        coyoteJumpTimer = coyoteJumpFrames;
    } else {
        coyoteJumpTimer--;
        if (jumpCount == 0 && coyoteJumpTimer <= 0) { jumpCount = 1; }
    }

    // Execute buffered jump
    if (jumpKeyBuffered && !downKey && jumpCount < jumpMax) {
        jumpKeyBuffered    = 0;
        jumpKeyBufferTimer = 0;
        jumpCount++;
        jumpHoldTimer = jumpHoldFrames[jumpCount - 1];
        setOnGround(false);
        coyoteJumpTimer = 0;
    }

    // Variable jump height — release key to cut ascent
    if (!jumpKey) {
        jumpHoldTimer = 0;
    }

    if (jumpHoldTimer > 0) {
        yspd = jspd[jumpCount - 1];
        jumpHoldTimer--;
    }

    // Axis lock overrides yspd last
    if (lockY) {
        yspd = 0;
    }
}
