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

    // === HIT / STUN LOCKOUT ===
    // Posture-break stun: completely locked — drop every input, run no abilities.
    if (isStunned) {
        rightKey = 0; leftKey = 0; upKey = 0; downKey = 0;
        jumpKeyPressed = 0; jumpKeyBuffered = 0; jumpKey = 0;
        attackKey = 0; dashKey = 0; grappleKey = 0;
        parryKey = 0; parryKeyHeld = 0;
        xspd = 0;
        return;
    }

    // === GRAPPLE EDGE DETECTION ===
    grappleJustReleased = false;
    var _grappleHeld    = (grappleKey != 0);
    var _grapplePressed = (_grappleHeld && !grappleKeyPrev);

    if (!_grappleHeld && grappleKeyPrev) {
        grappleJustReleased = true;
    }
    grappleKeyPrev    = _grappleHeld;
    grappleKeyPressed = _grapplePressed;

    // === PARRY EDGE DETECTION ===
    parryJustReleased = false;
    var _parryHeld = (parryKeyHeld != 0);
    if (!_parryHeld && parryKeyPrev) {
        parryJustReleased = true;
    }
    parryKeyPrev = _parryHeld;

    // === DASH / BACKSTEP INPUT ===
    var _moveInput = (leftKey || rightKey);

    // Charge parry can be canceled by a dash — clear parry state first so the
    // dash trigger below fires normally.
    if (isParrying && parryState == ParryState.P_CHARGING
    && dashKey && dashCharges > 0) {
        endParry();
    }

    // Backstep: grounded, no directional input, has charges
    if (!isDashing && !isBackStepping && !isParrying && !isHurt && onGround && dashCooldownTimer <= 0
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
    } else if (!isDashing && !isBackStepping && !isParrying && !isHurt && dashCooldownTimer <= 0
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

    // Block jump during non-cancelable parry states (charge parry handles its
    // own jump cancel inside processParry).
    if (isParrying && parryState != ParryState.P_CHARGING) {
        jumpKeyPressed  = 0;
        jumpKeyBuffered = 0;
        jumpKey         = 0;
    }

    // === PARRY INPUT ===
    // Sequential parry: still in initial/sequential parry, already had a successful
    // hit, press parry again → reduced window chained parry.
    if (isParrying
    && (parryState == ParryState.P_INITIAL || parryState == ParryState.P_SEQUENTIAL)
    && parrySuccess && parryKey) {
        parryState          = ParryState.P_SEQUENTIAL;
        parryFrame          = 0;
        parrySuccess        = false;
        isParryWindowActive = false;

    // Fresh parry: not already parrying, no cooldown/downtime active.
    } else if (!isParrying && !isDashing && !isBackStepping && !isAttacking && !isClimbing
    && !isHurt && !grappling && parryCooldownTimer <= 0 && parryDowntimeTimer <= 0 && parryKey) {
        isParrying          = true;
        parryState          = ParryState.P_INITIAL;
        parryFrame          = 0;
        isParryWindowActive = false;
        parrySuccess        = false;
        parryCharge         = 0;
        parryChargeLevel    = 0;
        xspd                = 0;
        yspd                = 0;
    }

    // === ATTACK INPUT ===
    // Ground attacks
    if (!isAttacking && !isDashing && !isParrying && !isClimbing && !isHurt && !grappling && onGround && attackKey) {
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
    if (!isAttacking && !isDashing && !isParrying && !isClimbing && !isHurt && !grappling && !onGround && attackKey) {
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

    // Hit reaction timer — ends the spr_hit reaction when it runs out
    if (hurtTimer > 0) {
        hurtTimer--;
        if (hurtTimer <= 0) { isHurt = false; }
    }
}
