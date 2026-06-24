// =============================================================================
// PLAYER PARRY SYSTEM
// Called from obj_player Step event after processAttack().
//
// States:
//   P_INITIAL       — First press; standard active window.
//   P_SEQUENTIAL    — Chained after a successful initial parry; reduced window.
//   P_CHARGING      — Held past chargeStartFrames; no window (vulnerable).
//   P_CHARGE_ACTIVE — Released at charge level 2+; window active.
//
// External entry:
//   triggerParrySuccess() — called by obj_hitbox when the window catches a hit.
// =============================================================================

// -----------------------------------------------------------------------------
// endParry()
// Cleans up all parry state. Safe to call from any sub-state.
// -----------------------------------------------------------------------------
function endParry() {
    isParrying          = false;
    parryState          = ParryState.P_NONE;
    parryFrame          = 0;
    isParryWindowActive = false;
    parrySuccess        = false;
    parryCharge         = 0;
    parryChargeLevel    = 0;
    parryNudgeTimer     = 0;
    parryNudgeX         = 0;
    lockX               = false;
    lockY               = false;
    gravityOverride     = false;
}

// -----------------------------------------------------------------------------
// triggerParrySuccess(_damage, _nudgeX, _strengthLevel)
// Called by obj_hitbox when this entity's window catches an incoming attack.
//   _nudgeX        — signed push (positive = right), derived from attack knockback
//   _strengthLevel — attacker's strength tier for overcharge comparison
// -----------------------------------------------------------------------------
function triggerParrySuccess(_damage, _nudgeX, _strengthLevel) {
    parrySuccess        = true;
    isParryWindowActive = false;   // window consumed by this hit

    // Brief push in the direction of the incoming attack
    var _nudgeSpeed = max(1.5, abs(_nudgeX) * 0.4);
    parryNudgeX     = sign(_nudgeX) * _nudgeSpeed;
    parryNudgeTimer = 5;

    // === MISCHARGE — parry level vs attack strength ===
    // Attacks with no strength level (<= 0) never penalize a level mismatch.
    if (_strengthLevel > 0) {
        if (parryChargeLevel > _strengthLevel) {
            // OVER-parry: too much charge for the attack → downtime penalty
            parryDowntimeTimer = parryDowntimeFrames;
            endParry();
        } else if (parryChargeLevel < _strengthLevel) {
            // UNDER-parry: not enough charge → open a window of amplified posture damage
            postureVulnTimer = postureVulnFrames;
        }
        // else: parry level matches attack strength → clean parry, no penalty
    }
}

// -----------------------------------------------------------------------------
// processParry()
// Per-frame processor. Call once per step unconditionally.
// -----------------------------------------------------------------------------
function processParry() {

    // Tick cooldown and downtime independently of parry state
    if (parryCooldownTimer > 0) { parryCooldownTimer--; }
    if (parryDowntimeTimer  > 0) { parryDowntimeTimer--;  }

    // Tick the under-parry posture-vulnerability window (opened in triggerParrySuccess)
    if (postureVulnTimer    > 0) { postureVulnTimer--;    }

    if (!isParrying) { return; }

    // Charge parry cancel — jump key exits charge and allows normal jump
    if (parryState == ParryState.P_CHARGING && jumpKeyBuffered) {
        endParry();
        return;
    }

    // Hold position: suspend gravity and stop all momentum (floats in air too)
    lockX           = true;
    lockY           = true;
    gravityOverride = true;

    // Nudge override: brief push applied right after a successful parry
    if (parryNudgeTimer > 0) {
        lockX = false;
        xspd  = parryNudgeX;
        parryNudgeTimer--;
    } else {
        xspd = 0;
        yspd = 0;
    }

    parryFrame++;

    // -------------------------------------------------------------------------
    switch (parryState) {

        // =====================================================================
        case ParryState.P_INITIAL:
        // =====================================================================

            // Transition to charge if button is still held long enough
            if (parryKeyHeld && parryFrame >= parryChargeStartFrames) {
                parryState          = ParryState.P_CHARGING;
                isParryWindowActive = false;
                parryFrame          = 0;
                parryCharge         = 0;
                parryChargeLevel    = 0;
                break;
            }

            // Active window: open for parryWindowFrames frames after startup
            if (!parrySuccess) {
                isParryWindowActive = (parryFrame >= parryStartupFrames
                                    && parryFrame <  parryStartupFrames + parryWindowFrames);
            }

            if (parryFrame >= parryDuration) {
                if (!parrySuccess) { parryCooldownTimer = parryCooldownFrames; }
                endParry();
            }
            break;

        // =====================================================================
        case ParryState.P_SEQUENTIAL:
        // =====================================================================

            // Sequential can also charge — same hold threshold as initial
            if (parryKeyHeld && parryFrame >= parryChargeStartFrames) {
                parryState          = ParryState.P_CHARGING;
                isParryWindowActive = false;
                parryFrame          = 0;
                parryCharge         = 0;
                parryChargeLevel    = 0;
                break;
            }

            if (!parrySuccess) {
                isParryWindowActive = (parryFrame >= parryStartupFrames
                                    && parryFrame <  parryStartupFrames + parrySeqWindowFrames);
            }

            if (parryFrame >= parrySeqDuration) {
                if (!parrySuccess) { parryCooldownTimer = parryCooldownFrames; }
                endParry();
            }
            break;

        // =====================================================================
        case ParryState.P_CHARGING:
        // =====================================================================

            isParryWindowActive = false;   // exposed while charging

            parryCharge += parryChargeGain;

            // Resolve current charge level
            parryChargeLevel = 0;
            for (var i = parryChargeMaxLevel - 1; i >= 0; i--) {
                if (parryCharge >= parryChargeLevelLimits[i]) {
                    parryChargeLevel = i + 1;
                    break;
                }
            }

            // Release detection
            if (parryJustReleased) {
                if (parryChargeLevel >= 2) {
                    // Enough charge: open the parry window
                    parryState          = ParryState.P_CHARGE_ACTIVE;
                    isParryWindowActive = true;
                    parryFrame          = 0;
                } else {
                    // Not enough charge: exit without cooldown
                    endParry();
                }
            }
            break;

        // =====================================================================
        case ParryState.P_CHARGE_ACTIVE:
        // =====================================================================

            isParryWindowActive = !parrySuccess && (parryFrame <= parryChargeActiveDuration);

            if (parryFrame > parryChargeActiveDuration) {
                if (!parrySuccess) { parryCooldownTimer = parryCooldownFrames; }
                endParry();
            }
            break;
    }
}
