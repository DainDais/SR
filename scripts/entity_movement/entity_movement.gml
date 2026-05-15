// =============================================================================
// ENTITY MOVEMENT SYSTEM
// Universal horizontal movement, direction facing, and friction.
// Call applyXMovement() before resolveXCollision().
//
// Required variables on the entity:
//   grappling, rightKey, leftKey, moveDir, inputLockFace, face
//   inputLockMove, groundState, runKey, runType, moveSpd[]
//   stopDecelGround, stopDecelAir, onGround, lockX, xspd
// =============================================================================

// -----------------------------------------------------------------------------
// applyXMovement()
// Calculates xspd from input. Applies friction when no input or locked.
// Note: x += xspd happens inside resolveXCollision(), not here.
// -----------------------------------------------------------------------------
function applyXMovement() {
    if (!grappling) {
        moveDir = rightKey - leftKey;

        if (moveDir != 0 && inputLockFace <= 0) {
            face = moveDir;
        }

        if (moveDir != 0 && inputLockMove <= 0) {
            // Crouch always uses its own slower speed
            if (groundState == GroundState.G_CROUCH) {
                runType = 2;
            } else {
                runType = runKey;
            }
            xspd = moveDir * moveSpd[runType];
        } else if (inputLockMove <= 0) {
            // No input and unlocked: coast to a stop
            var fric = onGround ? stopDecelGround : stopDecelAir;
            if (xspd > 0)      xspd = max(0, xspd - fric);
            else if (xspd < 0) xspd = min(0, xspd + fric);
        } else if (onGround) {
            // Locked but grounded: still bleed off speed so slides don't persist
            if (xspd > 0)      xspd = max(0, xspd - stopDecelGround);
            else if (xspd < 0) xspd = min(0, xspd + stopDecelGround);
        }

        if (lockX) {
            xspd = 0;
        }
    }
}
