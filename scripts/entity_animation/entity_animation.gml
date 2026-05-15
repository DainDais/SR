// =============================================================================
// ENTITY ANIMATION SYSTEM
// State-driven sprite selection and frame-hold management.
// Call after updateStateMachine() and resolveYCollision() so all states are final.
//
// This script uses the player's sprite variables directly. When adding NPCs,
// provide equivalent sprite variables in their Create event and this function
// will drive them automatically via the same state machine.
//
// Required variables on the entity:
//   isAttacking, attackName, attackTable, isBackStepping, backStepSpr
//   isDashing, dashStartSpr, isClimbing, ladderIdleSpr, ladderClimbSpr
//   parentState, groundState, airState, xspd, runKey, yspd
//   idleSpr, walkSpr, runSpr, jumpSpr, fallSpr, spr_wallSlide
//   crouchIdleSpr, crouchWalkSpr, animFrameHold, animHoldFrame
//   animHoldUntilStateChange, image_speed, image_index, sprite_index
//   prevParentState, prevGroundState, prevAirState
//   ParentState, GroundState, AirState enums
// =============================================================================

// -----------------------------------------------------------------------------
// updateAnimation()
// Selects the correct sprite for the current state, applies the frame-hold
// system, and resets animation when the sprite changes.
// -----------------------------------------------------------------------------
function updateAnimation() {

    // === DETECT STATE CHANGE (for animHoldUntilStateChange) ===
    var _stateChanged = false;
    if (parentState != prevParentState) {
        _stateChanged = true;
    } else if (parentState == ParentState.GROUND && groundState != prevGroundState) {
        _stateChanged = true;
    } else if (parentState == ParentState.AIR && airState != prevAirState) {
        _stateChanged = true;
    }

    if (_stateChanged && animHoldUntilStateChange && !isDashing && !isClimbing) {
        animFrameHold          = false;
        animHoldFrame          = 0;
        animHoldUntilStateChange = false;
    }

    // === SPRITE SELECTION ===
    var _newSprite = sprite_index;
    var _resetAnim = false;

    if (isAttacking) {
        var _attackData = attackTable[$ attackName];
        if (_attackData != undefined) {
            _newSprite = _attackData.sprite;

            // Preserve freeze when holdLastFrame is active on the last frame
            var _atLastFrame = _attackData.holdLastFrame
                && floor(image_index) >= sprite_get_number(_attackData.sprite) - 1;

            if (!_atLastFrame) {
                animFrameHold          = false;
                animHoldUntilStateChange = false;
                image_speed            = 1;
            }
        }

    } else if (isBackStepping) {
        _newSprite = backStepSpr;
        if (!animFrameHold || sprite_index != backStepSpr) {
            animFrameHold          = true;
            animHoldFrame          = 1;
            animHoldUntilStateChange = false;
        }

    } else if (isDashing) {
        _newSprite = dashStartSpr;
        if (!animFrameHold || sprite_index != dashStartSpr) {
            animFrameHold          = true;
            animHoldFrame          = 1;
            animHoldUntilStateChange = false;
        }

    } else if (isClimbing) {
        if (yspd == 0) {
            _newSprite  = ladderIdleSpr;
            animFrameHold = false;
            image_speed = 1;
        } else {
            _newSprite  = ladderClimbSpr;
            animFrameHold = false;
            image_speed = (yspd > 0) ? -1 : 1;
        }

    } else if (parentState == ParentState.GROUND) {
        if (groundState == GroundState.G_CROUCH) {
            if (abs(xspd) < 0.1) {
                _newSprite  = crouchIdleSpr;
                animFrameHold = false;
            } else {
                _newSprite  = crouchWalkSpr;
                animFrameHold = false;
            }
        } else if (groundState == GroundState.G_IDLE) {
            _newSprite  = idleSpr;
            animFrameHold = false;
        } else if (groundState == GroundState.G_WALK) {
            _newSprite  = walkSpr;
            animFrameHold = false;
        } else if (groundState == GroundState.G_RUN) {
            _newSprite  = runSpr;
            animFrameHold = false;
        }

    } else {
        // AIR
        if (airState == AirState.A_WALLCLING) {
            _newSprite  = spr_wallSlide;
            animFrameHold = false;
        } else if (yspd < 0) {
            _newSprite  = jumpSpr;
            animFrameHold = false;
        } else {
            _newSprite = fallSpr;
            if (sprite_index != fallSpr) {
                animFrameHold          = false;
                animHoldUntilStateChange = false;
            } else if (image_index >= 1 && !animFrameHold) {
                animFrameHold          = true;
                animHoldFrame          = 1;
                animHoldUntilStateChange = true;
            }
        }
    }

    // === APPLY SPRITE CHANGE ===
    if (_newSprite != sprite_index) {
        sprite_index = _newSprite;
        _resetAnim   = true;
    }

    // === APPLY FRAME HOLD ===
    if (animFrameHold) {
        image_speed = 0;
        image_index = animHoldFrame;
    } else {
        if (!isClimbing || yspd == 0) {
            image_speed = 1;
        }
        if (_resetAnim) {
            image_index = 0;
        }
    }

    // Clean up stale frame holds when the triggering state ends
    if (!isDashing && sprite_index == dashStartSpr) {
        animFrameHold = false;
    }
    if (!isBackStepping && sprite_index == backStepSpr) {
        animFrameHold = false;
    }

    // === ADVANCE PREVIOUS STATE TRACKING ===
    prevParentState = parentState;
    prevGroundState = groundState;
    prevAirState    = airState;
}
