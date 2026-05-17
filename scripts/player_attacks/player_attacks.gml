// =============================================================================
// PLAYER ATTACK SYSTEM
// Called from obj_player Step event. All functions run with self = obj_player.
//
// To add a new attack:
//   1. Add an entry to attackTable in obj_player Create event.
//   2. Add an input trigger in the ATTACK INPUT region of Step_0.gml.
//   3. Done. No new functions needed.
// =============================================================================

// -----------------------------------------------------------------------------
// endAttack()
// Releases the attacking state and cleans up hitbox/flags.
// Safe to call from both normal end and cancel paths.
// -----------------------------------------------------------------------------
function endAttack() {
    // Reset the hitboxSpawned flag in the data table for this attack
    var _data = attackTable[$ attackName];
    if (_data != undefined) {
        _data.hitboxSpawned = false;
    }

    isAttacking   = false;
    attackName    = "";
    attackFrame   = 0;

    // Clear input locks that were set when the attack started.
    // Prevents a mid-attack cancel leaving the player stuck.
    inputLockMove = 0;
    inputLockFace = 0;
    inputLockJump = 0;

    if (instance_exists(myAttackHitbox)) {
        instance_destroy(myAttackHitbox);
        myAttackHitbox = noone;
    }
}

// -----------------------------------------------------------------------------
// processAttack()
// Generic per-frame processor. Reads all behaviour from attackTable[$ attackName].
// Called once per step while isAttacking is true.
// -----------------------------------------------------------------------------
function processAttack() {

    // Nothing to process when not attacking — exit immediately.
    // This lets Step_0 call processAttack() unconditionally without guards.
    if (!isAttacking) { return; }

    // Look up the data for the active attack
    var _data = attackTable[$ attackName];

    // Safety: unknown attack name — bail out cleanly
    if (_data == undefined) {
        endAttack();
        return;
    }

    // On the very first frame, guarantee hitboxSpawned is clean
    // (endAttack resets it on normal exits, but this covers edge cases)
    if (attackFrame == 0) {
        _data.hitboxSpawned = false;
    }

    attackFrame++;

    // === CANCEL CHECKS ===
    // Cancel if the required ground state is violated
    if (_data.cancelOnAir && !onGround) {
        endAttack();
        return;
    }
    if (_data.cancelOnGround && onGround) {
        endAttack();
        return;
    }

    // === HITBOX SPAWN ===
    if (floor(image_index) == _data.hitboxFrame && !_data.hitboxSpawned) {
        myAttackHitbox              = instance_create_depth(x, y, depth - 1, obj_hitbox);
        myAttackHitbox.owner        = id;
        myAttackHitbox.followOwner  = true;
        myAttackHitbox.offsetX      = _data.offsetX;
        myAttackHitbox.offsetY      = _data.offsetY;
        myAttackHitbox.hitboxWidth  = _data.width;
        myAttackHitbox.hitboxHeight = _data.height;
        myAttackHitbox.damage       = _data.damage;
        myAttackHitbox.lifetime     = 0;
        myAttackHitbox.debug_color  = _data.debugColor;
        _data.hitboxSpawned = true;
    }

    // === HITBOX DESTROY ===
    if (floor(image_index) >= _data.hitboxEndFrame && instance_exists(myAttackHitbox)) {
        instance_destroy(myAttackHitbox);
        myAttackHitbox = noone;
    }

    // === END CHECK ===
    var _lastFrame = sprite_get_number(_data.sprite) - 1;
    if (floor(image_index) >= _lastFrame) {
        if (_data.holdLastFrame) {
            // Freeze on last frame, stay in attack state.
            // cancelOnAir / cancelOnGround act as the natural exit.
            image_speed = 0;
            image_index = _lastFrame;
            return;
        }
        endAttack();
    }
}