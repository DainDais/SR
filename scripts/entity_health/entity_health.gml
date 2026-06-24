// =============================================================================
// ENTITY HEALTH SYSTEM
// Universal health, damage, and invincibility-frame management.
//
// Usage:
//   Create event : call initHealth(_hp, _maxHp, _invincibleFrames)
//                  optionally define  onDeath = method(self, function() {...})
//                  for custom death behaviour (default: instance_destroy())
//   Step event   : call tickHealth()
//
// Required variables (set by initHealth):
//   hp, maxHp, isInvincible, invincibleTimer, invincibleFrames
//
// Optional variables read by take_damage (checked with variable_instance_exists):
//   myHurtbox     — flashed red on hit
//   xspd / yspd   — knockback applied directly
//   inputLockMove — brief stun applied on hit (minimum 12 frames)
//   onDeath       — method called instead of instance_destroy when hp reaches 0
// =============================================================================

// -----------------------------------------------------------------------------
// initHealth(_hp, _maxHp, _invincibleFrames)
// Initialises all health variables. Call once from the entity's Create event.
// _invincibleFrames: how many frames the entity is immune after taking a hit.
// -----------------------------------------------------------------------------
function initHealth(_hp, _maxHp, _invincibleFrames) {
    hp               = _hp;
    maxHp            = _maxHp;
    isInvincible     = false;
    invincibleTimer  = 0;
    invincibleFrames = _invincibleFrames;
}

// -----------------------------------------------------------------------------
// take_damage(_amount, _knockbackX, _knockbackY)
// Resolves a single hit. Returns false if blocked by i-frames, true if damage
// was applied. Called by obj_hitbox during collision resolution.
// -----------------------------------------------------------------------------
function take_damage(_amount, _knockbackX = 0, _knockbackY = 0) {

    // Blocked by invincibility frames
    if (isInvincible) return false;

    // Subtract HP
    hp = max(0, hp - _amount);

    // Start invincibility window. When the entity defines a hit reaction
    // (hitStunFrames), i-frames last exactly as long as that reaction.
    isInvincible    = true;
    invincibleTimer = variable_instance_exists(self, "hitStunFrames") ? hitStunFrames : invincibleFrames;

    // Visual feedback — flash the hurtbox red
    if (variable_instance_exists(self, "myHurtbox") && instance_exists(myHurtbox)) {
        myHurtbox.hit_flash_timer = 20;
        myHurtbox.hit_flash_color = c_red;
    }

    // Apply knockback if the entity uses xspd / yspd
    if (variable_instance_exists(self, "xspd")) { xspd = _knockbackX; }
    if (variable_instance_exists(self, "yspd")) { yspd = _knockbackY; }

    // Brief input stun if the entity uses inputLockMove (hit-reaction length when defined)
    if (variable_instance_exists(self, "inputLockMove")) {
        var _lock = variable_instance_exists(self, "hitStunFrames") ? hitStunFrames : 12;
        inputLockMove = max(inputLockMove, _lock);
    }

    // Hit reaction hook (cancels actions, enters spr_hit, knocks out of a posture stun)
    if (variable_instance_exists(self, "onHurt")) {
        onHurt();
    }

    // Death
    if (hp <= 0) {
        if (variable_instance_exists(self, "onDeath")) {
            onDeath();
        } else {
            instance_destroy();
        }
    }

    return true;
}

// -----------------------------------------------------------------------------
// take_posture_damage(_amount)
// Applies posture damage to entities that carry a `posture` stat. Returns false
// if the entity has no posture or the amount is non-positive, true otherwise.
//
// All modifiers are read defensively, so entities without the optional vars
// (e.g. enemies) still pass through cleanly:
//   - Guard     : holding the charge-parry stance (parryState == P_CHARGING)
//                 scales damage by postureGuardMult (default 0.5).
//   - Mischarge : while postureVulnTimer > 0, damage is scaled by postureVulnMult
//                 (default 2) — the window is opened by a mischarged parry.
// HP is untouched here; guarding still takes full HP damage via take_damage.
// -----------------------------------------------------------------------------
function take_posture_damage(_amount) {

    // Only entities with a posture stat respond to posture damage
    if (!variable_instance_exists(self, "posture")) return false;
    if (_amount <= 0) return false;

    var _dmg = _amount;

    // Guarding = holding the charge-parry stance (see player_parry). Blunts posture loss.
    var _guarding = variable_instance_exists(self, "isParrying") && isParrying
                 && variable_instance_exists(self, "parryState")
                 && parryState == ParryState.P_CHARGING;
    if (_guarding) {
        var _gm = variable_instance_exists(self, "postureGuardMult") ? postureGuardMult : 0.5;
        _dmg *= _gm;
    }

    // Mischarge window: incoming posture damage amplified for a time
    if (variable_instance_exists(self, "postureVulnTimer") && postureVulnTimer > 0) {
        var _vm = variable_instance_exists(self, "postureVulnMult") ? postureVulnMult : 2;
        _dmg *= _vm;
    }

    var _maxP = variable_instance_exists(self, "posture_max") ? posture_max : posture;
    posture = clamp(posture - _dmg, 0, _maxP);

    // Posture-break hook (optional, mirrors onDeath)
    if (posture <= 0 && variable_instance_exists(self, "onPostureBreak")) {
        onPostureBreak();
    }

    return true;
}

// -----------------------------------------------------------------------------
// tickHealth()
// Counts down the invincibility timer. Call every step from the entity's Step event.
// -----------------------------------------------------------------------------
function tickHealth() {
    if (invincibleTimer > 0) {
        invincibleTimer--;
        if (invincibleTimer <= 0) {
            isInvincible = false;
        }
    }
}
