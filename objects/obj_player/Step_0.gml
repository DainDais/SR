//Get inputs
getControls();

// --- GRAPPLE INPUT EDGES ---
grappleJustReleased = false;

var _grappleHeld    = (grappleKey != 0);
var _grapplePressed = (_grappleHeld && !grappleKeyPrev);

if (!_grappleHeld && grappleKeyPrev) {
    grappleJustReleased = true;
}

grappleKeyPrev    = _grappleHeld;
grappleKeyPressed = _grapplePressed;

#region Dash/Backstep Input (NOT LOGIC)
// Get movement input
var _moveInput = (leftKey || rightKey);

// BACKSTEP INPUT (Ground only, no directional input, has dash charges)
if (!isDashing && !isBackStepping && onGround && dashCooldownTimer <= 0 
    && dashKey && !_moveInput && dashCharges > 0)
{
    isBackStepping = true;
    dashCharges--;
    xspd = face * backStepSpeed;
    yspd = 0;
    inputLockMove = backStepLockFrames;
    inputLockFace = backStepLockFrames;
    backStepLockTimer = backStepLockFrames;
    lockY = true;
}
// DASH INPUT (Forward dash with directional input)
else if (!isDashing && !isBackStepping && dashCooldownTimer <= 0 
         && dashKey && _moveInput && dashCharges > 0)
{
    isDashing = true;
    dashCharges--;
    moveDir = rightKey - leftKey;
    dashDir = (moveDir != 0) ? moveDir : face;
    face = dashDir;
    dashWasAir = !onGround;
    xspd = dashDir * dashSpeed;
    yspd = 0;
    inputLockMove = dashLockFrames;
    inputLockFace = dashLockFrames;
    dashLockTimer = dashLockFrames;
    lockY = true;
}
#endregion

// --- PREEMPTIVE: INPUT LOCKS ---
if (inputLockMove > 0)
{
    rightKey = 0;
    leftKey  = 0;
}

if (inputLockJump > 0)
{
    jumpKeyPressed  = 0;
    jumpKeyBuffered = 0;
    jumpKey         = 0;
}

//Get out of solid moving platforms
#region
    var _rightWall = noone;
    var _leftWall = noone;
    var _bottomWall = noone;
    var _topWall = noone;
    var _list = ds_list_create();
    var _listSize = instance_place_list( x, y, obj_movePlat, _list, false );

    for( var i = 0; i <_listSize; i++ )
    {
        var _listInst = _list [| i];
    
        if _listInst.bbox_left - _listInst.xspd >= bbox_right-1
        {
            if !instance_exists(_rightWall) || _listInst.bbox_left < _rightWall.bbox_left
            {
                _rightWall = _listInst;
            }
        }
    
        if _listInst.bbox_right - _listInst.xspd <= bbox_left+1
        {
            if !instance_exists(_leftWall) || _listInst.bbox_right > _leftWall.bbox_right
            {
                _leftWall = _listInst;
            }
        }
    
        if _listInst.bbox_top - _listInst.yspd >= bbox_bottom-1
        {
            if !instance_exists (_bottomWall) || _listInst.bbox_top < _bottomWall.bbox_top
            {
                _bottomWall = _listInst;
            }
        }
    
        if _listInst.bbox_bottom - _listInst.yspd <= bbox_top+1
        {
            if !instance_exists(_topWall) || _listInst.bbox_bottom + _listInst.yspd <= _topWall.bbox_bottom + _topWall.yspd
            {
                _topWall = _listInst;
            }
        }
    }

    ds_list_destroy(_list);

    if instance_exists(_rightWall)
    {
        var _rightDist = bbox_right - x;
        x = _rightWall.bbox_left - _rightDist;
    }

    if instance_exists(_leftWall)
    {
        var _leftDist = x -  bbox_left ;
        x = _leftWall.bbox_right + _leftDist;
    }
    
    if instance_exists(_bottomWall)
    {
        var _bottomDist = bbox_bottom - y;
        y = _bottomWall.bbox_top - _bottomDist;
    }

    if instance_exists(_topWall)
    {
        var _upDist = y - bbox_top;
        var _targetY = _topWall.bbox_bottom + _upDist;
        if !place_meeting ( x, _targetY, obj_wall )
        {
            y = _targetY;
        }
    }
#endregion

//Dont get left behind by moveplat
earlyMoveplatXspd = false;
if instance_exists( myFloorPlat ) && myFloorPlat.xspd != 0 && !place_meeting (x, y + moveplatMaxYspd + 1, myFloorPlat )
{
    if !place_meeting( x + myFloorPlat.xspd, y, obj_wall )
    {
        x += myFloorPlat.xspd;
        earlyMoveplatXspd = true;
    }
}

#region ATTACK INPUT
// GROUND ATTACKS (standing and crouch)
if (!isAttacking && !isDashing && !isClimbing && !grappling && onGround && attackKey)
{
    if (downKey)
    {
        isAttacking = true;
        attackName = "crouch";
        attackFrame = 0;
        attackFrameMax = attack_crouch_frames;
        attack_crouch_hitboxSpawned = false;
        
        inputLockMove = attackFrameMax;
        inputLockFace = attackFrameMax;
        inputLockJump = attackFrameMax;
        
        xspd = 0;
    }
    else
    {
        isAttacking = true;
        attackName = "standingSwing1";
        attackFrame = 0;
        attackFrameMax = attack_standingSwing1_frames;
        attack_standingSwing1_hitboxSpawned = false;
        
        inputLockMove = attackFrameMax;
        inputLockFace = attackFrameMax;
        inputLockJump = attackFrameMax;
        
        xspd = 0;
    }
}

// AIR ATTACK (jump attack)
if (!isAttacking && !isDashing && !isClimbing && !grappling && !onGround && attackKey)
{
    isAttacking = true;
    attackName = "jump";
    attackFrame = 0;
    attackFrameMax = attack_jump_frames;
    attack_jump_hitboxSpawned = false;
    
    inputLockMove = attackFrameMax;
    inputLockFace = attackFrameMax;
    inputLockJump = attackFrameMax;
    
    xspd *= 0.5;
}
#endregion

#region X Movement
	if (!grappling)
	{
		moveDir = rightKey - leftKey;

		if (moveDir != 0 && inputLockFace <= 0) {
		    face = moveDir;
		}

		if (moveDir != 0 && inputLockMove <= 0)
		{
		    if (groundState == GroundState.G_CROUCH)
		    {
		        runType = 2;
		    }
		    else
		    {
		        runType = runKey;
		    }
		    
		    xspd = moveDir * moveSpd[runType];
		}
		else if (inputLockMove <= 0)
		{
		    var fric = onGround ? stopDecelGround : stopDecelAir;
		    if (xspd > 0)      xspd = max(0, xspd - fric);
		    else if (xspd < 0) xspd = min(0, xspd + fric);
		}
		else if (onGround)
		{
		    if (xspd > 0)      xspd = max(0, xspd - stopDecelGround);
		    else if (xspd < 0) xspd = min(0, xspd + stopDecelGround);
		}

		if (lockX) {
		    xspd = 0;
		}
	}
#endregion

#region X Collison
    var _subPixel = .5;
    
    if place_meeting( x + xspd , y, obj_wall)
    {
        if !place_meeting( x + xspd, y-abs(xspd)-2, obj_wall)
        {
            while place_meeting( x + xspd, y, obj_wall) { y -= _subPixel; };
        }
        else
        {
            if !place_meeting( x + xspd, y + abs(xspd)+1, obj_wall )
            {
                while place_meeting( x + xspd, y, obj_wall ) {y += _subPixel; };
            }
            else
            {
                var _pixelCheck = _subPixel * sign(xspd);
                while !place_meeting( x + _pixelCheck, y, obj_wall ) {x += _pixelCheck;};
                xspd = 0;
            }
        }
    }

    downSlopeSemiSolid = noone;
    if (yspd >= 0
    && !place_meeting(x + xspd, y + 1, obj_wall)
    && place_meeting(x + xspd, y + abs(xspd) + 3, obj_wall))
    {
        downSlopeSemiSolid = checkForSemisolidPlatform( x + xspd, y + abs(xspd) + 1 );
        if !instance_exists(downSlopeSemiSolid)
        {
            while !place_meeting( x + xspd, y + _subPixel, obj_wall ) { y += _subPixel; };
        }
    }
    
    x += xspd;
#endregion

#region Dash State Logic
if (isDashing)
{
    face = dashDir;
    lockY = true;
    yspd = 0;
    
    if (dashLockTimer > 0)
    {
        dashLockTimer--;
    }
    else
    {
        isDashing = false;
        lockY = false;
        dashCooldownTimer = dashCooldownFrames;
    }
}
#endregion

#region Backstep State Logic
if (isBackStepping)
{
    lockY = true;
    yspd = 0;
    
    if (backStepLockTimer > 0)
    {
        backStepLockTimer--;
    }
    else
    {
        isBackStepping = false;
        lockY = false;
        dashCooldownTimer = dashCooldownFrames;
    }
}
#endregion

#region Grapple State Logic
if (!grappling && !isClimbing && grappleKeyPressed)
{
    var _target = grapple_find_best_target();
    
    if (instance_exists(_target))
    {
        grappling     = true;
        grappleTarget = _target;
        
        var tx = grappleTarget.x;
        var ty = grappleTarget.y + grappleHangOffsetY;
        
        var dx  = tx - x;
        var dy  = ty - y;
        var mag = max(0.0001, sqrt(dx*dx + dy*dy));
        
        grappleDirX = dx / mag;
        grappleDirY = dy / mag;
        
        var _impulse = min(grappleAccel * 2, grapplePullSpeed);
        xspd = grappleDirX * _impulse;
        yspd = grappleDirY * _impulse;
        
        setOnGround(false);
        isDashing = false;
        lockY = false;
    }
}

if (grappling)
{
    if (!instance_exists(grappleTarget))
    {
        grappling = false;
    }
    else
    {
        var tx = grappleTarget.x;
        var ty = grappleTarget.y + grappleHangOffsetY;
        
        var dx   = tx - x;
        var dy   = ty - y;
        var dist = sqrt(dx*dx + dy*dy);
        
        if (dist <= grappleDetachDist)
        {
            var nx = (dist > 0.0001) ? dx / dist : 0;
            var ny = (dist > 0.0001) ? dy / dist : 0;
            
            xspd = nx * grappleApproachSpeed;
            yspd = ny * grappleApproachSpeed;
            
            if (!place_meeting(tx, ty, obj_wall))
            {
                x = tx;
                y = ty;
            }
            
            grappling = false;
        }
        else
        {
            var _step = min(grappleApproachSpeed, dist);
            var _nx   = dx / dist;
            var _ny   = dy / dist;
            
            xspd = _nx * _step;
            yspd = _ny * _step;
            
            setOnGround(false);
            coyoteHangTimer = 1;
            gravityOverride = true;
            
            if (grappleCancelJump && jumpKeyPressed)
            {
                grappling = false;
                gravityOverride = false;
            }
        }
    }
}
else
{
    if (!isDashing && !isClimbing)
    {
        gravityOverride = false;
    }
}
#endregion

#region Climbing State Logic
	var _onLadder = place_meeting(x, y, obj_ladder);

	if (!isClimbing && _onLadder)
	{
	    if ((!onGround && (upKey || downKey)) || (onGround && upKey))
	    {
	        isClimbing = true;
        
	        var _ladder = instance_place(x, y, obj_ladder);
	        if (instance_exists(_ladder))
	        {
	            ladderX = _ladder.x;
	        }
        
	        grappling = false;
	        isDashing = false;
	        isWallCling = false;
	        wallDir = 0;
	        lockY = false;
	        xspd = 0;
	    }
	}

if (isClimbing)
{
    x = ladderX;
    xspd = 0;
    
    var _climbSpeed = runKey ? climbSpeedRun : climbSpeedWalk;
    yspd = (downKey - upKey) * _climbSpeed;
    
    coyoteHangTimer = 1;
    gravityOverride = true;
    setOnGround(false);
    
    if (jumpKeyPressed)
    {
        isClimbing = false;
        gravityOverride = false;
        
        jumpCount = 1;
        jumpHoldTimer = jumpHoldFrames[0];
        yspd = jspd[0];
        setOnGround(false);
        
        inputLockJump = 1;
        jumpKeyBuffered = false;
        jumpKeyBufferTimer = 0;
    }
    else if (onGround && downKey)
    {
        isClimbing = false;
        gravityOverride = false;
    }
    else if (!_onLadder)
    {
        isClimbing = false;
        gravityOverride = false;
    }
}
else
{
    if (!isDashing && !grappling)
    {
        gravityOverride = false;
    }
}
#endregion

#region ATTACK STATE LOGIC
if (isAttacking)
{
    attackFrame++;
    
    if (attackName == "standingSwing1")
    {
        if (floor(image_index) == 2 && !attack_standingSwing1_hitboxSpawned)
        {
            myAttackHitbox = instance_create_depth(x, y, depth - 1, obj_hitbox);
            myAttackHitbox.owner = id;
            myAttackHitbox.followOwner = true;
            myAttackHitbox.offsetX = 15;
            myAttackHitbox.offsetY = -30;
            myAttackHitbox.hitboxWidth = 20;
            myAttackHitbox.hitboxHeight = 20;
            myAttackHitbox.damage = 10;
            myAttackHitbox.lifetime = 0;
            myAttackHitbox.debug_color = c_yellow;
            attack_standingSwing1_hitboxSpawned = true;
        }
        
        if (floor(image_index) >= 4 && instance_exists(myAttackHitbox))
        {
            instance_destroy(myAttackHitbox);
            myAttackHitbox = noone;
        }
        
        var _spriteFrames = sprite_get_number(attackSwing1Spr);
        if (image_index >= _spriteFrames - 0.1)
        {
            isAttacking = false;
            attackName = "";
            attackFrame = 0;
            
            if (instance_exists(myAttackHitbox))
            {
                instance_destroy(myAttackHitbox);
                myAttackHitbox = noone;
            }
        }
    }
    
    if (attackName == "crouch")
    {
        if (!onGround)
        {
            isAttacking = false;
            attackName = "";
            attack_crouch_hitboxSpawned = false;
            
            if (instance_exists(myAttackHitbox))
            {
                instance_destroy(myAttackHitbox);
                myAttackHitbox = noone;
            }
        }
        else
        {

        if (floor(image_index) == 2 && !attack_crouch_hitboxSpawned)
        {
            myAttackHitbox = instance_create_depth(x, y, depth - 1, obj_hitbox);
            myAttackHitbox.owner = id;
            myAttackHitbox.followOwner = true;
            myAttackHitbox.offsetX = 30;
            myAttackHitbox.offsetY = -10;
            myAttackHitbox.hitboxWidth = 50;
            myAttackHitbox.hitboxHeight = 30;
            myAttackHitbox.damage = 8;
            myAttackHitbox.lifetime = 0;
            myAttackHitbox.debug_color = c_orange;
            
            attack_crouch_hitboxSpawned = true;
        }
        
        if (floor(image_index) >= 4 && instance_exists(myAttackHitbox))
        {
            instance_destroy(myAttackHitbox);
            myAttackHitbox = noone;
        }
        
        var _lastFrame = sprite_get_number(attackCrouchSpr) - 1;
        if (floor(image_index) >= _lastFrame)
        {
            image_speed = 0;
            image_index = _lastFrame;
            
            isAttacking = false;
            attackName = "";
            attack_crouch_hitboxSpawned = false;
            
            if (instance_exists(myAttackHitbox))
            {
                instance_destroy(myAttackHitbox);
                myAttackHitbox = noone;
            }
        }
        } // end else (was on ground)
    }

    if (attackName == "jump")
    {
        if (onGround)
        {
            isAttacking = false;
            attackName = "";
            attack_jump_hitboxSpawned = false;

            if (instance_exists(myAttackHitbox))
            {
                instance_destroy(myAttackHitbox);
                myAttackHitbox = noone;
            }
        }
        else
        {

        if (floor(image_index) == 2 && !attack_jump_hitboxSpawned)
        {
            myAttackHitbox = instance_create_depth(x, y, depth - 1, obj_hitbox);
            myAttackHitbox.owner = id;
            myAttackHitbox.followOwner = true;
            myAttackHitbox.offsetX = 25;
            myAttackHitbox.offsetY = -15;
            myAttackHitbox.hitboxWidth = 45;
            myAttackHitbox.hitboxHeight = 45;
            myAttackHitbox.damage = 12;
            myAttackHitbox.lifetime = 0;
            myAttackHitbox.debug_color = c_aqua;
            
            attack_jump_hitboxSpawned = true;
        }
        
        if (floor(image_index) >= 4 && instance_exists(myAttackHitbox))
        {
            instance_destroy(myAttackHitbox);
            myAttackHitbox = noone;
        }
        
        var _lastFrame = sprite_get_number(attackAirSlashSpr) - 1;
        if (floor(image_index) >= _lastFrame)
        {
            image_speed = 0;
            image_index = _lastFrame;
            
            isAttacking = false;
            attackName = "";
            attack_jump_hitboxSpawned = false;
            
            if (instance_exists(myAttackHitbox))
            {
                instance_destroy(myAttackHitbox);
                myAttackHitbox = noone;
            }
        }
        } // end else (was in air)
    }
}
#endregion

#region State Machine Update
	if (onGround && !isClimbing)
	{
	    parentState = ParentState.GROUND;
	}
	else
	{
	    parentState = ParentState.AIR;
	}

	if (parentState == ParentState.GROUND)
	{
	    airState       = AirState.A_NONE;
	    isWallCling    = false;
	    wallDir        = 0;
	    prevWallDir    = 0;
	    wallStickTimer = 0;
	    wallJumpLockTimer = 0;
	    lockY          = false;

	   if (downKey)
	{
	    groundState = GroundState.G_CROUCH;
	    mask_index = crouchMaskSpr;
	}
	else
	{
	    mask_index = maskSpr;
    
	    if (place_meeting(x, y, obj_wall))
	    {
	        groundState = GroundState.G_CROUCH;
	        mask_index = crouchMaskSpr;
	    }
	    else
	    {
	        var _absX = abs(xspd);

	        if (_absX < 0.1)
	        {
	            groundState = GroundState.G_IDLE;
	        }
	        else
	        {
	            if (runKey)
	            {
	                groundState = GroundState.G_RUN;
	            }
	            else
	            {
	                groundState = GroundState.G_WALK;
	            }
	        }
	    }
	}
}
else
{
    groundState = GroundState.G_IDLE;
    
    var _touchLeft  = place_meeting(x - 1, y, obj_wall);
    var _touchRight = place_meeting(x + 1, y, obj_wall);
    
    var _currentWallDir = 0;
    if (_touchLeft)       _currentWallDir = -1;
    else if (_touchRight) _currentWallDir = 1;
    
    var _touchingWall = (_currentWallDir != 0);
    var _falling = (yspd > 0);
    var _inputDir = rightKey - leftKey;
    var _inputTowardWall = (_inputDir == _currentWallDir);
    var _inputAwayFromWall = (_inputDir == -_currentWallDir && _inputDir != 0);
    
    if (!isClimbing)
    {
        #region WALL JUMP STATE
        if (airState == AirState.A_WALLJUMP)
        {
            if (_touchingWall && _currentWallDir == -prevWallDir)
            {
                airState = AirState.A_WALLCLING;
                isWallCling = true;
                wallDir = _currentWallDir;
                wallStickTimer = wallStickFrames;
                lockY = true;
            }
            else
            {
                if (wallJumpLockTimer > 0)
                {
                    wallJumpLockTimer--;
                    wallDir = prevWallDir;
                }
                else
                {
                    if (_falling)
                    {
                        airState = AirState.A_FALL;
                    }
                    else
                    {
                        airState = AirState.A_NONE;
                    }
                    wallDir = 0;
                }
            }
        }
        #endregion

        #region WALL CLING STATE
        else if (airState == AirState.A_WALLCLING)
        {
            if (_touchingWall && !onGround)
            {
                wallDir = _currentWallDir;
                isWallCling = true;
                
                if (wallStickTimer > 0)
                {
                    lockY = true;
                    wallStickTimer--;
                }
                else
                {
                    lockY = false;
                }
                
                if (_inputAwayFromWall)
                {
                    airState = AirState.A_FALL;
                    isWallCling = false;
                    lockY = false;
                    wallStickTimer = 0;
                    prevWallDir = wallDir;
                    wallDir = 0;
                }
                else if (jumpKeyPressed)
                {
                    airState = AirState.A_WALLJUMP;
                    isWallCling = false;
                    lockY = false;
                    wallStickTimer = 0;
                    
                    xspd = -wallDir * wallJumpXSpeed;
                    yspd = wallJumpYSpeed;
                    
                    face = -wallDir;
                    
                    inputLockMove = wallJumpLockFrames;
                    inputLockFace = wallJumpLockFrames;
                    inputLockJump = wallJumpLockFrames;
                    wallJumpLockTimer = wallJumpLockFrames;
                    
                    prevWallDir = wallDir;
                    
                    jumpCount = 1;
                    jumpHoldTimer = 0;
                    
                    jumpKeyBuffered = false;
                    jumpKeyBufferTimer = 0;
                }
            }
            else
            {
                airState = _falling ? AirState.A_FALL : AirState.A_NONE;
                isWallCling = false;
                lockY = false;
                wallStickTimer = 0;
                prevWallDir = wallDir;
                wallDir = 0;
            }
        }
        #endregion
        
        #region NORMAL AIR STATES (NONE/FALL)
        else
        {
            if (_touchingWall && _falling && _inputTowardWall)
            {
                airState = AirState.A_WALLCLING;
                isWallCling = true;
                wallDir = _currentWallDir;
                wallStickTimer = wallStickFrames;
                lockY = true;
                prevWallDir = 0;
            }
            else
            {
                wallDir = 0;
                isWallCling = false;
                lockY = false;
                
                if (_falling)
                {
                    airState = AirState.A_FALL;
                }
                else
                {
                    airState = AirState.A_NONE;
                }
            }
        }
        #endregion
    }
}
#endregion

#region Y Movement

#region Gravity
	if (coyoteHangTimer > 0) {
	    coyoteHangTimer--;
	} else {
	    if (!gravityOverride && !isClimbing) {
	        if (airState == AirState.A_WALLCLING)
	        {
	            if (lockY)
	            {
	                yspd = 0;
	            }
	            else
	            {
	                yspd = min(yspd + wallSlideAccel, wallSlideSpeed);
	            }
	        }
	        else
	        {
	            yspd += grav;
	        }
	    }
	    
	    if (!isClimbing) {
	        setOnGround(false);
	    }
	}
#endregion

if onGround
{
    jumpCount       = 0;
    jumpHoldTimer   = 0;
    coyoteJumpTimer = coyoteJumpFrames;
    dashCharges = dashChargesMax;
    canDash = true;
} 
else 
{
    coyoteJumpTimer--;
    if jumpCount == 0 && coyoteJumpTimer <= 0 { jumpCount = 1; };
}

if (jumpKeyBuffered && !downKey && jumpCount < jumpMax)
{
    jumpKeyBuffered    = false;
    jumpKeyBufferTimer = 0;
    jumpCount++;
    jumpHoldTimer = jumpHoldFrames[jumpCount - 1];
    setOnGround(false);
    coyoteJumpTimer = 0;
}

if !jumpKey
{
    jumpHoldTimer = 0;
}

if jumpHoldTimer > 0
{
    yspd = jspd[jumpCount-1];
    jumpHoldTimer--;
}

if (lockY) {
    yspd = 0;
}
#endregion 
	
#region Y Collision and Movement Logic
    if yspd > termVel { yspd = termVel; };
    var _subPixel = .5;

    if yspd < 0 && place_meeting( x, y + yspd, obj_wall )
    {
        var _slopeSlide = false;
        
        if moveDir != 1 && !place_meeting( x - abs(yspd)-1, y + yspd, obj_wall )
        {
            while place_meeting( x, y + yspd, obj_wall ) { x -= 1; }; 
            _slopeSlide = true;
        }
        
        if moveDir != -1 && !place_meeting( x + abs(yspd) +1, y + yspd, obj_wall )
        {
            while place_meeting( x, y + yspd, obj_wall ) { x += 1; };
            _slopeSlide = true;
        }
        
        if !_slopeSlide
        {
            var _pixelCheck = _subPixel * sign(yspd);
            while !place_meeting( x, y + _pixelCheck, obj_wall )
            {
                y += _pixelCheck;
            }
            yspd = 0;    
        }
    }
    
    var _clampYspd = max( 0, yspd ); 
    var _list = ds_list_create();
    var _array = array_create (0);
    array_push( _array, obj_wall, obj_semiSolidWall );
    
    var _listSize = instance_place_list( x, y+1 + _clampYspd + moveplatMaxYspd, _array, _list, false);
        
    for (var i = 0; i < _listSize; i++)
    {
        var _listInst = _list [| i];
        if _listInst !=forgetSemiSolid
        && (_listInst.yspd <= yspd || instance_exists(myFloorPlat) )
        && ( _listInst.yspd > 0 || place_meeting( x, y+1 + _clampYspd, _listInst) )
        {
            if _listInst.object_index == obj_wall
            || object_is_ancestor( _listInst.object_index, obj_wall )
            || floor(bbox_bottom) <= ceil( _listInst.bbox_top - _listInst.yspd )
            {
                if !instance_exists(myFloorPlat)
                || _listInst.bbox_top + _listInst.yspd <= myFloorPlat.bbox_top + myFloorPlat.yspd
                || _listInst.bbox_top + _listInst.yspd <= bbox_bottom
                {
                    myFloorPlat = _listInst;
                }
            } 
        }
    }
    ds_list_destroy(_list);

    if instance_exists(myFloorPlat) && !place_meeting( x, y + moveplatMaxYspd,  myFloorPlat )
    {
        myFloorPlat = noone;
    }

    if instance_exists(myFloorPlat) 
    {
        var _subPixel = .5;
        while !place_meeting( x, y + _subPixel, myFloorPlat ) && !place_meeting ( x, y, obj_wall ) { y += _subPixel; };
        if myFloorPlat.object_index == obj_semiSolidWall || object_is_ancestor(myFloorPlat.object_index, obj_semiSolidWall)
        {
            while place_meeting ( x, y, myFloorPlat ) { y -= _subPixel; };
        }
        y = floor(y);
        
        yspd = 0;
        setOnGround(true);
    }
    
    if (downKey && jumpKeyPressed)
    {
        if instance_exists(myFloorPlat)
        && ( myFloorPlat.object_index == obj_semiSolidWall || object_is_ancestor( myFloorPlat.object_index, obj_semiSolidWall) )
        {
            var _yCheck = y + max(1, myFloorPlat.yspd + 1 );
            if !place_meeting( x, _yCheck, obj_wall )
            {
                y += 1;
                forgetSemiSolid = myFloorPlat;
                setOnGround(false);
            }
        }
    }
    
    if !place_meeting( x, y + yspd, obj_wall)
    {
        y += yspd;
    }
    if instance_exists(forgetSemiSolid) && !place_meeting(x, y, forgetSemiSolid)
    {
        forgetSemiSolid = noone;
    }
#endregion

#region Moving platform collision and movement
        moveplatXspd = 0;
        if instance_exists(myFloorPlat) { moveplatXspd = myFloorPlat.xspd; };
        if place_meeting( x + moveplatXspd, y, obj_wall )
        {
            var _subPixel = .5;
            var _pixelCheck = _subPixel * sign(moveplatXspd);
            while !place_meeting( x + _pixelCheck, y, obj_wall )
            {
                x += _pixelCheck;
            }
            moveplatXspd = 0;
        }
        x += moveplatXspd;
#endregion

#region Jitter Fix for moving platforms
    if instance_exists(myFloorPlat) && myFloorPlat.yspd != 0
    {
        if !place_meeting(x, myFloorPlat.bbox_top, obj_wall) 
        && myFloorPlat.bbox_top >= bbox_bottom - moveplatMaxYspd
        {
            y = myFloorPlat.bbox_top;
        }
    }
#endregion

#region Get pushed down through a semisolid by a moving solid platform
    if instance_exists( myFloorPlat )
    &&  ( myFloorPlat.object_index == obj_semiSolidWall || object_is_ancestor( myFloorPlat.object_index, obj_semiSolidWall ))
    && place_meeting( x, y, obj_wall )
    {
        var _maxPushDist = 10;
        var _pushedDist = 0;
        var _startY = y;
        while place_meeting( x, y, obj_wall ) && _pushedDist <= _maxPushDist
        {
            y++;
            _pushedDist++;
        }
        setOnGround(false)
        
        if _pushedDist > _maxPushDist {y = _startY;};
    }
#endregion

#region Sprite and Animation Management

	var _stateChanged = false;
	if (parentState != prevParentState)
	{
	    _stateChanged = true;
	}
	else if (parentState == ParentState.GROUND && groundState != prevGroundState)
	{
	    _stateChanged = true;
	}
	else if (parentState == ParentState.AIR && airState != prevAirState)
	{
	    _stateChanged = true;
	}

	if (_stateChanged && animHoldUntilStateChange && !isDashing && !isClimbing)
	{
	    animFrameHold = false;
	    animHoldFrame = 0;
	    animHoldUntilStateChange = false;
	}

var _newSprite = sprite_index;
var _resetAnim = false;

if (isAttacking)
{
    if (attackName == "standingSwing1")
    {
        _newSprite = attackSwing1Spr;
    }
    else if (attackName == "crouch")
    {
        _newSprite = attackCrouchSpr;
    }
    else if (attackName == "jump")
    {
        _newSprite = attackAirSlashSpr;
    }
}
else if (isBackStepping)
{
    _newSprite = backStepSpr;
    
    if (!animFrameHold || sprite_index != backStepSpr)
    {
        animFrameHold = true;
        animHoldFrame = 1;
        animHoldUntilStateChange = false;
    }
}
else if (isDashing)
{
    _newSprite = dashStartSpr;
    
    if (!animFrameHold || sprite_index != dashStartSpr)
    {
        animFrameHold = true;
        animHoldFrame = 1;
        animHoldUntilStateChange = false;
    }
}
else if (isClimbing)
{
    if (yspd == 0)
    {
        _newSprite = ladderIdleSpr;
        animFrameHold = false;
        image_speed = 1;
    }
    else
    {
        _newSprite = ladderClimbSpr;
        animFrameHold = false;
        
        if (yspd > 0)
        {
            image_speed = -1;
        }
        else
        {
            image_speed = 1;
        }
    }
}
else if (parentState == ParentState.GROUND)
{
    if (groundState == GroundState.G_CROUCH)
    {
        var _absX = abs(xspd);
        
        if (_absX < 0.1)
        {
            _newSprite = crouchIdleSpr;
            animFrameHold = false;
        }
        else
        {
            _newSprite = crouchWalkSpr;
            animFrameHold = false;
        }
    }
    else if (groundState == GroundState.G_IDLE)
    {
        _newSprite = idleSpr;
        animFrameHold = false;
    }
    else if (groundState == GroundState.G_WALK)
    {
        _newSprite = walkSpr;
        animFrameHold = false;
    }
    else if (groundState == GroundState.G_RUN)
    {
        _newSprite = runSpr;
        animFrameHold = false;
    }
}
else
{
    if (airState == AirState.A_WALLCLING)
    {
        _newSprite = spr_wallSlide;
        animFrameHold = false;
    }
    else if (yspd < 0)
    {
        _newSprite = jumpSpr;
        animFrameHold = false;
    }
    else
    {
        _newSprite = fallSpr;
        
        if (sprite_index != fallSpr)
        {
            animFrameHold = false;
            animHoldUntilStateChange = false;
        }
        else if (image_index >= 1 && !animFrameHold)
        {
            animFrameHold = true;
            animHoldFrame = 1;
            animHoldUntilStateChange = true;
        }
    }
}

if (_newSprite != sprite_index)
{
    sprite_index = _newSprite;
    _resetAnim = true;
}

if (animFrameHold)
{
    image_speed = 0;
    image_index = animHoldFrame;
}
else
{
    if (!isClimbing || yspd == 0)
    {
        image_speed = 1;
    }
    
    if (_resetAnim)
    {
        image_index = 0;
    }
}

if (!isDashing && sprite_index == dashStartSpr)
{
    animFrameHold = false;
}
if (!isBackStepping && sprite_index == backStepSpr)  
{
    animFrameHold = false;
}

prevParentState = parentState;
prevGroundState = groundState;
prevAirState = airState;

#endregion

if (dashCooldownTimer > 0) dashCooldownTimer--;

if (inputLockMove > 0)  inputLockMove--;
if (inputLockFace > 0)  inputLockFace--;
if (inputLockJump > 0)  inputLockJump--;

#region Debug
if (debugHurtboxKey)
{
    with (obj_hurtbox)
    {
        debug_show = !debug_show;
    }
}
#endregion

#region AFTERIMAGE SPAWNING
afterimageEnabled = false;

if (isDashing)
{
    afterimageEnabled = true;
    afterimageColor = c_aqua;
}

if (isBackStepping)
{
    afterimageEnabled = true;
    afterimageColor = c_orange;
}

if (airState == AirState.A_WALLJUMP && wallJumpLockTimer > 0)
{
    afterimageEnabled = true;
    afterimageColor = c_yellow;
}

if (abs(xspd) > 4 || abs(yspd) > 4)
{
    afterimageEnabled = true;
    afterimageColor = c_white;
}

if (grappling)
{
    afterimageEnabled = true;
    afterimageColor = c_lime;
}

if (afterimageEnabled)
{
    afterimageTimer++;
    
    if (afterimageTimer >= afterimageSpawnRate)
    {
        var _afterimage = instance_create_depth(x, y, depth + 1, obj_afterimage);
        
        _afterimage.stored_sprite = sprite_index;
        _afterimage.stored_frame = image_index;
        _afterimage.stored_x = x;
        _afterimage.stored_y = y;
        _afterimage.stored_xscale = image_xscale * face;
        _afterimage.stored_yscale = image_yscale;
        _afterimage.stored_angle = image_angle;
        _afterimage.stored_color = afterimageColor;
        
        afterimageTimer = 0;
    }
}
else
{
    afterimageTimer = 0;
}
#endregion

#region FX SPAWNING SYSTEM

var isWallSliding = (airState == AirState.A_WALLCLING && wallStickTimer <= 0);

if (isDashing && dashLockTimer == dashLockFrames - 1)
{
    var _fx = instance_create_depth(x, y, depth + 1, obj_fxDashDust);
    _fx.owner = id;
    _fx.initializeFX();
}

if (isBackStepping && backStepLockTimer == backStepLockFrames - 1)
{
    var _fx = instance_create_depth(x, y, depth + 1, obj_fxBackStepDust);
    _fx.owner = id;
    _fx.initializeFX();
}

if (!variable_instance_exists(id, "prevJumpCount"))
{
    prevJumpCount = 0;
}

if (jumpCount > prevJumpCount && jumpCount == 1)
{
    var _fx = instance_create_depth(x, y, depth + 1, obj_fxJumpDust);
    _fx.owner = id;
    _fx.initializeFX();
}

prevJumpCount = jumpCount;

if (!variable_instance_exists(id, "prevAirStateWallJump"))
{
    prevAirStateWallJump = AirState.A_NONE;
}

if (prevAirStateWallJump == AirState.A_WALLCLING && airState == AirState.A_WALLJUMP)
{
    var _fx = instance_create_depth(x, y, depth + 1, obj_fxWallJumpDust);
    _fx.owner = id;
    _fx.fxDirection = prevWallDir;
    _fx.initializeFX();
}

prevAirStateWallJump = airState;

if (!variable_instance_exists(id, "prevJumpCountDouble"))
{
    prevJumpCountDouble = 0;
}

if (jumpCount > prevJumpCountDouble && jumpCount == 2)
{
    var _fx = instance_create_depth(x, y, depth - 1, obj_fxDoubleJump);
    _fx.owner = id;
    _fx.initializeFX();
}

prevJumpCountDouble = jumpCount;

if (!variable_instance_exists(id, "prevOnGround"))
{
    prevOnGround = false;
}

if (onGround && !prevOnGround)
{
    var _fx = instance_create_depth(x, y, depth + 1, obj_fxLandingDust);
    _fx.owner = id;
    _fx.initializeFX();
}

prevOnGround = onGround;

if (!variable_instance_exists(id, "runDustTimer"))
{
    runDustTimer = 0;
}

if (onGround && groundState == GroundState.G_RUN && abs(xspd) > 2)
{
    runDustTimer++;
    
    if (runDustTimer >= 8)
    {
        var _fx = instance_create_depth(x, y, depth + 1, obj_fxRunDust);
        _fx.owner = id;
        _fx.initializeFX();
        
        runDustTimer = 0;
    }
}
else
{
    runDustTimer = 0;
}

if (!variable_instance_exists(id, "myWallSlideFX"))
{
    myWallSlideFX = noone;
}

if (isWallSliding && !instance_exists(myWallSlideFX))
{
    myWallSlideFX = instance_create_depth(x, y, depth - 1, obj_fxWallSlide);
    myWallSlideFX.owner = id;
    myWallSlideFX.initializeFX();
}

if (!instance_exists(myWallSlideFX))
{
    myWallSlideFX = noone;
}

#endregion