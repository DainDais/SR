// =============================================================================
// PLAYER DASH & BACKSTEP SYSTEM
// Maintains dash and backstep states each frame, manages timers, and resets
// dash charges on landing.
// Input detection (triggering) is handled in player_input.gml.
//
// Required variables on the entity:
//   isDashing, dashDir, lockY, yspd, dashLockTimer, dashLockFrames
//   dashCooldownTimer, dashCooldownFrames, dashCharges, dashChargesMax
//   isBackStepping, backStepLockTimer, onGround
// =============================================================================

// -----------------------------------------------------------------------------
// processDash()
// Call after processInput(), before applyXMovement().
// -----------------------------------------------------------------------------
function processDash() {

    // === LANDING RESET ===
    // Restore dash charges when the entity touches the ground.
    if (onGround) {
        dashCharges = dashChargesMax;
    }

    // === DASH COOLDOWN TIMER ===
    if (dashCooldownTimer > 0) { dashCooldownTimer--; }

    // === DASH STATE MAINTENANCE ===
    if (isDashing) {
        // Lock facing and vertical movement for the dash duration
        face  = dashDir;
        lockY = true;
        yspd  = 0;

        if (dashLockTimer > 0) {
            dashLockTimer--;
        } else {
            // Dash expired
            isDashing         = false;
            lockY             = false;
            dashCooldownTimer = dashCooldownFrames;
        }
    }

    // === BACKSTEP STATE MAINTENANCE ===
    if (isBackStepping) {
        lockY = true;
        yspd  = 0;

        if (backStepLockTimer > 0) {
            backStepLockTimer--;
        } else {
            // Backstep expired
            isBackStepping    = false;
            lockY             = false;
            dashCooldownTimer = dashCooldownFrames;
        }
    }
}
