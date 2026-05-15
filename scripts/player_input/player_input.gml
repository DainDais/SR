// =============================================================================
// PLAYER INPUT PROCESSING
// Handles all per-frame input detection: edge signals, ability triggers,
// preemptive lock application, and attack initiation.
// NPCs skip this and use their own AI driver instead.
//
// processInput()   — call right after getControls(), before any ability logic
// tickInputLocks() — call at the very end of Step, after all physics
// =============================================================================

// -----------------------------------------------------------------------------
// processInput()
// Detects grapple edges, triggers dash/backstep/attack, and applies input locks.
// -----------------------------------------------------------------------------
function processInput() {

    // === GRAPPLE EDGE DETECTION ===
    grappleJustReleased = false;
    var _grappleHeld    = (grappleKey != 0);
    var _grapplePressed = (_grappleHeld && !grappleKeyPrev);

    if (!_grappleHeld && grappleKeyPrev) {
        grappleJustReleased = true;
    }
    grappleKeyPrev    = _grappleHeld;
    grappleKeyPressed = _grapplePressed;

    // === DASH / BACKSTEP INPUT ===
    var _moveInput = (leftKey || rightKey);

    // Backstep: grounded, no directional input, has charges
    if (!isDashing && !isBackStepping && onGround && dashCooldownTimer <= 0
    && dashKey && !_moveInput && dashCharges > 0) {
        isBackStepping    = true;
        dashCharges--;
        xspd              = face * backStepSpeed;
        yspd              = 0;
        inputLockMove     = backStepLockFrames;
        inputLockFace     = backStepLockFrames;
        backStepLockTimer = backStepLockFrames;
        lockY             = true;

    // Dash: has directional input, has charges
    } else if (!isDashing && !isBackStepping && dashCooldownTimer <= 0
    && dashKey && _moveInput && dashCharges > 0) {
        isDashing   = true;
        dashCharges--;
        moveDir     = rightKey - leftKey;
        dashDir     = (moveDir != 0) ? moveDir : face;
        if (inputLockFace <= 0) { face = dashDir; }
        dashWasAir  = !onGround;
        xspd        = dashDir * dashSpeed;
        yspd        = 0;
        inputLockMove   = dashLockFrames;
        inputLockFace   = dashLockFrames;
        dashLockTimer   = dashLockFrames;
        lockY           = true;
    }

    // === PREEMPTIVE INPUT LOCKS ===
    // Zero out directional input so locked movement isn't applied this frame
    if (inputLockMove > 0) {
        rightKey = 0;
        leftKey  = 0;
    }

    if (inputLockJump > 0) {
        jumpKeyPressed  = 0;
        jumpKeyBuffered = 0;
        jumpKey         = 0;
    }

    // === ATTACK INPUT ===
    // Ground attacks
    if (!isAttacking && !isDashing && !isClimbing && !grappling && onGround && attackKey) {
        if (downKey) {
            attackName     = "crouch";
            isAttacking    = true;
            attackFrame    = 0;
            attackFrameMax = sprite_get_number(attackTable.crouch.sprite);
            inputLockMove  = attackFrameMax;
            inputLockFace  = attackFrameMax;
            inputLockJump  = attackFrameMax;
            xspd = 0;
        } else {
            attackName     = "standingSwing1";
            isAttacking    = true;
            attackFrame    = 0;
            attackFrameMax = sprite_get_number(attackTable.standingSwing1.sprite);
            inputLockMove  = attackFrameMax;
            inputLockFace  = attackFrameMax;
            inputLockJump  = attackFrameMax;
            xspd = 0;
        }
    }

    // Air attack
    if (!isAttacking && !isDashing && !isClimbing && !grappling && !onGround && attackKey) {
        attackName     = "jump";
        isAttacking    = true;
        attackFrame    = 0;
        attackFrameMax = sprite_get_number(attackTable.jump.sprite);
        inputLockMove  = attackFrameMax;
        inputLockFace  = attackFrameMax;
        inputLockJump  = attackFrameMax;
        xspd *= 0.5;
    }
}

// -----------------------------------------------------------------------------
// tickInputLocks()
// Decrements all input lock timers. Call at the very end of Step.
// -----------------------------------------------------------------------------
function tickInputLocks() {
    if (inputLockMove > 0) inputLockMove--;
    if (inputLockFace > 0) inputLockFace--;
    if (inputLockJump > 0) inputLockJump--;
}
