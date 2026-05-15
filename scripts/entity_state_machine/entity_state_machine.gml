// =============================================================================
// ENTITY STATE MACHINE
// Universal parent/ground/air state determination.
// Call after all ability scripts (dash, grapple, climb) and after X collision,
// but BEFORE applyGravity() — gravity reads airState to decide wall-slide vs normal.
//
// Required variables on the entity:
//   onGround, isClimbing, parentState, groundState, airState
//   isDashing, isWallCling, wallDir, prevWallDir, wallStickTimer, wallJumpLockTimer
//   lockY, downKey, xspd, runKey, mask_index, maskSpr, crouchMaskSpr
//   wallStickFrames, wallJumpLockFrames, wallJumpXSpeed, wallJumpYSpeed
//   wallJumpLockFrames, face, jumpCount, jumpHoldTimer
//   inputLockMove, inputLockFace, inputLockJump
//   jumpKeyBuffered, jumpKeyBufferTimer, jumpKeyPressed
//   ParentState, GroundState, AirState enums
// =============================================================================

// -----------------------------------------------------------------------------
// updateStateMachine()
// Sets parentState, groundState, and airState from current physics state.
// Also manages wall cling, wall jump lock, and wall jump execution.
// -----------------------------------------------------------------------------
function updateStateMachine() {

    // === PARENT STATE ===
    if (onGround && !isClimbing) {
        parentState = ParentState.GROUND;
    } else {
        parentState = ParentState.AIR;
    }

    // === GROUND SUBSTATES ===
    if (parentState == ParentState.GROUND) {
        // Reset all air variables on landing
        airState          = AirState.A_NONE;
        isWallCling       = false;
        wallDir           = 0;
        prevWallDir       = 0;
        wallStickTimer    = 0;
        wallJumpLockTimer = 0;
        lockY             = false;

        if (downKey) {
            groundState = GroundState.G_CROUCH;
            mask_index  = crouchMaskSpr;
        } else {
            mask_index = maskSpr;

            if (place_meeting(x, y, obj_wall)) {
                // Forced into crouch by low ceiling
                groundState = GroundState.G_CROUCH;
                mask_index  = crouchMaskSpr;
            } else {
                var _absX = abs(xspd);
                if (_absX < 0.1) {
                    groundState = GroundState.G_IDLE;
                } else if (runKey) {
                    groundState = GroundState.G_RUN;
                } else {
                    groundState = GroundState.G_WALK;
                }
            }
        }

    // === AIR SUBSTATES ===
    } else {
        groundState = GroundState.G_IDLE;

        var _touchLeft  = place_meeting(x - 1, y, obj_wall);
        var _touchRight = place_meeting(x + 1, y, obj_wall);

        var _currentWallDir = 0;
        if (_touchLeft)       _currentWallDir = -1;
        else if (_touchRight) _currentWallDir =  1;

        var _touchingWall      = (_currentWallDir != 0);
        var _falling           = (yspd > 0);
        var _inputDir          = rightKey - leftKey;
        var _inputTowardWall   = (_inputDir == _currentWallDir);
        var _inputAwayFromWall = (_inputDir == -_currentWallDir && _inputDir != 0);

        if (!isClimbing) {

            // --- WALL JUMP STATE ---
            if (airState == AirState.A_WALLJUMP) {
                if (_touchingWall && _currentWallDir == -prevWallDir) {
                    // Hit opposite wall — transition to cling
                    airState       = AirState.A_WALLCLING;
                    isWallCling    = true;
                    wallDir        = _currentWallDir;
                    wallStickTimer = wallStickFrames;
                    lockY          = true;
                } else {
                    if (wallJumpLockTimer > 0) {
                        wallJumpLockTimer--;
                        wallDir = prevWallDir;
                    } else {
                        airState = _falling ? AirState.A_FALL : AirState.A_NONE;
                        wallDir  = 0;
                    }
                }

            // --- WALL CLING STATE ---
            } else if (airState == AirState.A_WALLCLING) {
                if (_touchingWall && !onGround) {
                    wallDir     = _currentWallDir;
                    isWallCling = true;

                    if (wallStickTimer > 0) {
                        lockY = true;
                        wallStickTimer--;
                    } else {
                        lockY = false;
                    }

                    if (_inputAwayFromWall) {
                        // Push off wall — fall
                        airState       = AirState.A_FALL;
                        isWallCling    = false;
                        lockY          = false;
                        wallStickTimer = 0;
                        prevWallDir    = wallDir;
                        wallDir        = 0;
                    } else if (jumpKeyPressed) {
                        // Wall jump
                        airState       = AirState.A_WALLJUMP;
                        isWallCling    = false;
                        lockY          = false;
                        wallStickTimer = 0;

                        xspd = -wallDir * wallJumpXSpeed;
                        yspd = wallJumpYSpeed;
                        face = -wallDir;

                        inputLockMove     = wallJumpLockFrames;
                        inputLockFace     = wallJumpLockFrames;
                        inputLockJump     = wallJumpLockFrames;
                        wallJumpLockTimer = wallJumpLockFrames;

                        prevWallDir = wallDir;
                        jumpCount   = 1;
                        jumpHoldTimer = 0;

                        jumpKeyBuffered    = false;
                        jumpKeyBufferTimer = 0;
                    }
                } else {
                    // Left the wall
                    airState       = _falling ? AirState.A_FALL : AirState.A_NONE;
                    isWallCling    = false;
                    lockY          = false;
                    wallStickTimer = 0;
                    prevWallDir    = wallDir;
                    wallDir        = 0;
                }

            // --- NORMAL AIR (NONE / FALL) ---
            } else {
                if (_touchingWall && _falling && _inputTowardWall) {
                    // Enter wall cling
                    airState       = AirState.A_WALLCLING;
                    isWallCling    = true;
                    wallDir        = _currentWallDir;
                    wallStickTimer = wallStickFrames;
                    lockY          = true;
                    prevWallDir    = 0;
                } else {
                    wallDir     = 0;
                    isWallCling = false;
                    lockY       = false;
                    airState    = _falling ? AirState.A_FALL : AirState.A_NONE;
                }
            }
        }
    }
}
