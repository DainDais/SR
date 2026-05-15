// =============================================================================
// OBJ_PLAYER — STEP EVENT
// Each line is a script call. See the corresponding script for implementation.
//
// Call order matters — do not reorder without understanding the dependencies.
// See architecture notes in the project wiki or ask Claude.
// =============================================================================

// --- INPUT ---
// Reads hardware and fires ability triggers (dash, attack, grapple edges).
// Input locks are applied here so subsequent systems see locked inputs.
getControls();
processInput();

// --- PLATFORM (early) ---
// Push entity out of any solid platform it was pressed into, then carry it
// along with a moving floor so it doesn't fall behind before movement runs.
resolveMovingPlatformPushOut();
resolveMovingPlatformEarly();

// --- PLAYER ABILITIES ---
// Each script maintains its own state and decrements its own timers.
// Order: dash and backstep first (they set lockY/xspd), then grapple,
// then climbing (both can clear gravityOverride in their else branches).
processDash();
processGrapple();
processClimbing();
processAttack();

// --- HORIZONTAL PHYSICS ---
// Calculate xspd from input + friction, then resolve against walls.
// x += xspd happens inside resolveXCollision.
applyXMovement();
resolveXCollision();

// --- STATE MACHINE ---
// Must run after X movement (reads xspd for ground substate) and after all
// abilities (reads isDashing, isClimbing, grappling), but BEFORE gravity
// (gravity reads airState to decide wall-slide vs normal accumulation).
updateStateMachine();

// --- VERTICAL PHYSICS ---
// Accumulate yspd, execute jumps, then resolve against floors/ceilings.
// y += yspd happens inside resolveYCollision.
applyGravity();
applyJump();
resolveYCollision();

// --- PLATFORM (late) ---
// Apply moving platform xspd, fix vertical jitter, handle semisolid push-through.
resolveMovingPlatformLate();

// --- VISUALS ---
// Animation reads final state; FX reads final position, speed, and state.
updateAnimation();
updateFX();

// --- TIMERS ---
// Input locks tick down last so the locked frame's zeroed inputs have already
// been consumed by applyXMovement and updateStateMachine.
tickInputLocks();

// --- DEBUG ---
if (debugHurtboxKey) {
    with (obj_hurtbox) {
        debug_show = !debug_show;
    }
}
