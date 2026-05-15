// =============================================================================
// PLAYER CLIMBING SYSTEM
// Handles ladder detection, climbing state, and exit conditions.
//
// Required variables on the entity:
//   isClimbing, ladderX, ladderX, climbSpeedWalk, climbSpeedRun
//   runKey, upKey, downKey, onGround, grappling, isDashing, isWallCling
//   wallDir, lockY, xspd, yspd, gravityOverride, coyoteHangTimer
//   jumpKeyPressed, jumpCount, jumpHoldFrames[], jspd[], inputLockJump
//   jumpKeyBuffered, jumpKeyBufferTimer, setOnGround()
// =============================================================================

// -----------------------------------------------------------------------------
// processClimbing()
// Detects ladder entry, maintains climbing state, and handles exit.
// Call after processGrapple(), before applyXMovement().
// -----------------------------------------------------------------------------
function processClimbing() {
    var _onLadder = place_meeting(x, y, obj_ladder);

    // === ENTER CLIMBING ===
    if (!isClimbing && _onLadder) {
        // Enter from air with directional input, or from ground pressing up
        if ((!onGround && (upKey || downKey)) || (onGround && upKey)) {
            isClimbing  = true;

            var _ladder = instance_place(x, y, obj_ladder);
            if (instance_exists(_ladder)) {
                ladderX = _ladder.x;
            }

            grappling   = false;
            isDashing   = false;
            isWallCling = false;
            wallDir     = 0;
            lockY       = false;
            xspd        = 0;
        }
    }

    // === CLIMBING STATE ===
    if (isClimbing) {
        x    = ladderX;
        xspd = 0;

        var _climbSpeed = runKey ? climbSpeedRun : climbSpeedWalk;
        yspd = (downKey - upKey) * _climbSpeed;

        coyoteHangTimer = 1;
        gravityOverride = true;
        setOnGround(false);

        if (jumpKeyPressed) {
            // Jump off ladder
            isClimbing      = false;
            gravityOverride = false;
            jumpCount       = 1;
            jumpHoldTimer   = jumpHoldFrames[0];
            yspd            = jspd[0];
            setOnGround(false);
            inputLockJump      = 1;
            jumpKeyBuffered    = false;
            jumpKeyBufferTimer = 0;

        } else if (onGround && downKey) {
            // Dismount at base
            isClimbing      = false;
            gravityOverride = false;

        } else if (!_onLadder) {
            // Walked off the ladder
            isClimbing      = false;
            gravityOverride = false;
        }

    } else {
        // Not climbing — clear gravity override unless dash or grapple holds it
        if (!isDashing && !grappling) {
            gravityOverride = false;
        }
    }
}
