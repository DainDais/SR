#region BASIC MOVEMENT VARIABLES
	airAccel = 0.3;      // 0.3 How fast you accelerate in air
	airMaxSpeed = 1.5;   // 3.5 Max horizontal speed in air (same as run speed)

	xspd = 0;
	yspd = 0;

	face = 1;

	// walk / run
	moveSpd[0] = 2;     // walk
	moveSpd[1] = 3.5;   // run
	moveSpd[2] = 1.5 // Crouch

	runType = 0;
	moveDir = 0;

	// friction
	stopDecelGround = 0.20;
	stopDecelAir    = 0.70;
#endregion

#region JUMP / GRAVITY
	grav       = 0.275; // default 0.275
	termVel    = 5;

	jumpMax    = 2;
	jumpCount  = 0;

	jumpHoldTimer = 0;
	jumpHoldFrames[0] = 18;
	jumpHoldFrames[1] = 10;

	jspd[0] = -3.15;
	jspd[1] = -2.15;

	onGround          = true;

	coyoteHangFrames  = 10;
	coyoteHangTimer   = 0;

	coyoteJumpFrames  = 10;
	coyoteJumpTimer   = 0;

	// Jump buffer
	jumpKeyBuffered    = false;
	jumpKeyBufferTimer = 0;
#endregion

#region PREEMPTIVE TROUBLESHOOT / LOCKS
	// Input lock timers (in frames)
	inputLockMove = 0;  // when > 0, horizontal movement input is ignored
	inputLockFace = 0;  // when > 0, facing direction cannot change
	inputLockJump = 0;  // when > 0, jump inputs are ignored

	// Axis locks (for future dash / climb / grapple states)
	lockX = false;      // when true, xspd will be forced to 0
	lockY = false;      // when true, yspd will be forced to 0

	// Gravity override (for future climbing / grapple)
	gravityOverride = false;

	// Future dash support – harmless for now
	canDash = true;
#endregion

#region MOVING PLATFORM VARS
	myFloorPlat       = noone;
	earlyMoveplatXspd = false;
	moveplatXspd      = 0;
	moveplatMaxYspd   = termVel;

	downSlopeSemiSolid = noone;
	forgetSemiSolid     = noone;

	function setOnGround(_val = true)
	{
	    if (_val)
	    {
	        onGround = true;
	        coyoteHangTimer = coyoteHangFrames;
	    }
	    else
	    {
	        onGround = false;
	        myFloorPlat = noone;
	        coyoteHangTimer = 0;
	    }
	}
#endregion

#region SEMISOLID CHECK FUNCTION
	function checkForSemisolidPlatform(_x,_y)
	{
	    var _r = noone;

	    if (yspd >= 0 && place_meeting(_x, _y, obj_semiSolidWall))
	    {
	        var _list = ds_list_create();
	        var n = instance_place_list(_x, _y, obj_semiSolidWall, _list, false);

	        for (var i = 0; i < n; i++)
	        {
	            var inst = _list[| i];

	            if (inst != forgetSemiSolid
	            && floor(bbox_bottom) <= ceil(inst.bbox_top - inst.yspd))
	            {
	                _r = inst;
	                break;
	            }
	        }

	        ds_list_destroy(_list);
	    }

	    return _r;
	}
#endregion

#region STATE MACHINE
	function getParentStateName()
	{
	    switch (parentState)
	    {
	        case ParentState.GROUND: return "GROUND";
	        case ParentState.AIR:    return "AIR";
	    }
	    return "UNKNOWN";
	}

	function getGroundStateName()
	{
	    switch (groundState)
	    {
	        case GroundState.G_IDLE:   return "IDLE";
	        case GroundState.G_WALK:   return "WALK";
	        case GroundState.G_RUN:    return "RUN";
	        case GroundState.G_CROUCH: return "CROUCH";
	    }
	    return "NONE";
	}

	function getAirStateName()
{
    switch (airState)
    {
        case AirState.A_NONE:      return "NONE";
        case AirState.A_FALL:      return "FALL";
        case AirState.A_WALLCLING: return "WALLCLING";
        case AirState.A_WALLJUMP:  return "WALLJUMP";
        case AirState.A_LEDGEGRAB: return "LEDGEGRAB"; 
    }
    return "UNKNOWN";
}


	// Parent states
	enum ParentState {
	    GROUND = 0,
	    AIR    = 1
	}

	// Ground substates
	enum GroundState {
	    G_IDLE   = 0,
	    G_WALK   = 1,
	    G_RUN    = 2,
	    G_CROUCH = 3
	}

	// Air substates
	// Air substates
	enum AirState {
	    A_NONE      = 0, // generic air (going up, neutral)
	    A_FALL      = 1,
	    A_WALLCLING = 2,
	    A_WALLJUMP  = 3,  
		A_LEDGEGRAB = 4 
	}

	// Global state 
	isDashing = false;

	// Current state variables
	parentState = ParentState.GROUND;
	groundState = GroundState.G_IDLE;
	airState    = AirState.A_NONE;

	// Global overlay flags (we'll actually use these later)
	hasDashState    = false;
	hasGrappleState = false;
	hasClimbState   = false;
#endregion

#region Wall / Air troubleshoot support
	// Direction of nearby wall: -1 = left, 1 = right, 0 = none
	wallDir = 0;

	// Are we currently in a wall cling state?
	isWallCling = false;

	// Wall stick/slide timers
	wallStickFrames = 10;  // How long to freeze on wall before sliding
	wallStickTimer  = 0;
	
	// Wall slide friction (after stick timer expires)
	wallSlideSpeed = 1.2;  // Max slide speed down wall
	wallSlideAccel = 0.1;  // How fast we accelerate to slide speed
	
	// Previous frame wall direction (for detecting new contact)
	prevWallDir = 0;
	
	// Wall jump launch speeds
	wallJumpXSpeed = 4.5;  // Horizontal launch away from wall 4.5
	wallJumpYSpeed = -6.0; // Vertical launch (negative = up) -6
	
	// Wall jump input lock duration
	wallJumpLockFrames = 12; // How long inputs are locked after wall jump
	wallJumpLockTimer  = 0;  // Current lock timer
	
#endregion

#region Dash System
	// Dash sprites
	dashStartSpr = spr_dashStart;
	
	// Dash timing
	dashLockFrames = 12;      // How long inputs are locked (also acts as dash timer)
	dashLockTimer = 0;        // Current lock timer
	
	// Dash speed
	dashSpeed = 6.0;          // Initial burst speed
	
	// Dash cooldown
	dashCooldownFrames = 18;  // Frames before you can dash again
	dashCooldownTimer = 0;    // Current cooldown timer
	
	// Dash charges
	dashChargesMax = 1;       // Maximum dash charges (adjustable)
	dashCharges = dashChargesMax; // Current available dashes
	
	// Dash state tracking
	isDashing = false;        // Are we currently dashing?
	dashDir = 1;              // Direction of current dash
	dashWasAir = false;       // Was this an air dash?
	
	backStepSpr = spr_backStep;
	isBackStepping = false;    // Are we currently backstepping?
	backStepSpeed = -4.0;      // Backstep speed (negative = backward)
	backStepLockFrames = 12;   // How long backstep lasts
	backStepLockTimer = 0;     // Current backstep timer
#endregion

#region Grapple System
	// Visual debug
	debug_grapple_show = false;
	
	// Scan box dimensions (starts at player's feet)
	grappleScanWidth   = 120;  // 120  Width of scan area
	grappleScanHeight  = 120;  // 120  Height of scan area
	grappleScanXOffset = 0;    // 0    Horizontal offset from player
	grappleScanYOffset = 0;    // 0    Vertical offset (0 = starts at feet)
	
	// Movement behavior
	grappleApproachSpeed = 7.0;  // 6.0 Speed when traveling to point
	grapplePullSpeed     = 5.0;  // 5.0   Initial pull speed
	grappleAccel         = 0.7;  // 0.7   Acceleration multiplier
	grappleDetachDist    = 8;    // 8     Distance to consider "arrived"
	grappleHangOffsetY   = 0;    // 0     Y offset for hang point
	grappleCancelJump    = true; // true  Can cancel grapple with jump
	
	// State tracking
	grappling     = false;
	grappleTarget = noone;
	grappleDirX   = 0;
	grappleDirY   = 0;
	
	// Input tracking
	grappleKeyPrev    = false;
	grappleKeyPressed = false;
	grappleJustReleased = false;
#endregion

#region Climbing System

	// Climbing state
	isClimbing = false;
	
	// Climbing speeds
	climbSpeedWalk = 2.0;    // Climb speed when not running
	climbSpeedRun  = 3.5;    // Climb speed when holding run key
	
	// Ladder locking
	ladderX = 0;  // X position to lock to while climbing
#endregion

#region Ledge Grab System
    // Ledge grab detection zone
    ledgeGrabHeight = 16;      // How far down from wall top
    ledgeGrabWidth = 8;        // How far out from wall
    
    // Ledge grab state
    isLedgeGrabbing = false;
    ledgeGrabWall = noone;     // Reference to wall we're grabbing
    ledgeGrabX = 0;            // X position to lock to
    ledgeGrabY = 0;            // Y position to lock to
    ledgeGrabDir = 0;          // Direction of wall (-1 left, 1 right)
    
    // Ledge grab behavior
    ledgeGrabMaxSpeed = 3.5;   // Max fall speed to allow grab
    ledgeClimbUpSpeed = -2.5;  // Speed when climbing up
    ledgeClimbUpDist = 20;     // How far to move up when climbing
    
    // Ceiling check
    ledgeCeilingCheckHeight = 24;  // How high to check for ceiling
    
    // Cooldown (prevent re-grab)
    ledgeGrabCooldown = 10;    // Frames before can grab again
    ledgeGrabCooldownTimer = 0;
    lastLedgeGrabbed = noone;  // Last wall grabbed
    
    // Animation tracking
    ledgeGrabAnimFinished = false;  // Has initial grab animation finished?
    
    // Sprites
    ledgeGrabSpr = spr_ledgeGrab;   // Initial grab animation
    ledgeHangSpr = spr_ledgeHang;   // Looping hang animation
	debug_ledge_show = false;

	
	#region Ledge Grab Functions
	    // Check if there's a ledge grab zone collision
	    function checkLedgeGrabZone()
	    {
	        // Only check when falling in air
	        if (onGround || yspd <= 0) return noone;
        
	        // Don't check if on cooldown
	        if (ledgeGrabCooldownTimer > 0) return noone;
        
	        // Check for wall collision on sides
	        var _touchLeft  = place_meeting(x - 1, y, obj_wall);
	        var _touchRight = place_meeting(x + 1, y, obj_wall);
        
	        if (!_touchLeft && !_touchRight) return noone;
        
	        // Determine wall direction
	        var _wallDir = 0;
	        if (_touchLeft)  _wallDir = -1;
	        if (_touchRight) _wallDir = 1;
        
	        // ONLY GRAB IF MOVING TOWARD WALL
	        var _inputDir = rightKey - leftKey;
	        if (_inputDir != _wallDir) return noone;  // Not pressing toward wall
        
	        // Get the wall instance
	        var _wallInst = _wallDir < 0 
	            ? instance_place(x - 1, y, obj_wall)
	            : instance_place(x + 1, y, obj_wall);
        
	        if (!instance_exists(_wallInst)) return noone;
        
	        // Don't grab same ledge twice
	        if (_wallInst == lastLedgeGrabbed) return noone;
        
	        // Get wall's top edge
	        var _wallTop = _wallInst.bbox_top;
        
	        // Define ledge grab zone (vertical strip along wall side, near top)
	        var _zoneTop = _wallTop;
	        var _zoneBottom = _wallTop + ledgeGrabHeight;
        
	        // Define horizontal bounds of zone (extends outward from wall)
	        var _zoneLeft, _zoneRight;
        
	        if (_wallDir < 0)  // Wall on left
	        {
	            _zoneRight = _wallInst.bbox_left;
	            _zoneLeft = _zoneRight - ledgeGrabWidth;
	        }
	        else  // Wall on right
	        {
	            _zoneLeft = _wallInst.bbox_right;
	            _zoneRight = _zoneLeft + ledgeGrabWidth;
	        }
        
	        // Check if player's bounding box overlaps with zone
	        if (bbox_right < _zoneLeft || bbox_left > _zoneRight)
	        {
	            return noone;  // Not horizontally in zone
	        }
        
	        // Check if player's grab point is in vertical zone
	        var _playerCenterY = (bbox_top + bbox_bottom) / 2;
        
	        if (_playerCenterY < _zoneTop || _playerCenterY > _zoneBottom)
	        {
	            return noone;  // Not vertically in zone
	        }
        
	        // Check for ceiling above ledge
	        var _ceilingCheckX = _wallInst.x;
	        var _ceilingCheckY = _wallTop - ledgeCeilingCheckHeight;
        
	        if (place_meeting(_ceilingCheckX, _ceilingCheckY, obj_wall))
	        {
	            return noone;  // Ceiling blocked
	        }
        
	        // All checks passed - return wall instance
	        return _wallInst;
	    }
	#endregion

#endregion

#region SPRITES
	#region Masks
		maskSpr    = spr_idle;
		crouchMaskSpr = spr_crouchStill; 
		mask_index = maskSpr;
		
	#endregion
	#region Movememnt
		idleSpr    = spr_idle;
		walkSpr    = spr_walk;
		runSpr     = spr_run;
		jumpSpr    = spr_jump;
		fallSpr    = spr_fall;
		crouchIdleSpr = spr_crouchStill;
		crouchWalkSpr = spr_crouchWalk;
		ladderIdleSpr  = spr_ladderIdle;
		ladderClimbSpr = spr_ladderClimb;
	#endregion
	#region Combat
		attackSwing1Spr = spr_standingSlash 
		attackCrouchSpr = spr_crouchSlash;
		attackAirSlashSpr = spr_airSlash;
	#endregion
	// Frame hold settings per sprite (optional)
	fallSprHoldFrame = 1; // Which frame to hold for fall sprite
	
	image_xscale = 1;
#endregion

#region Animation Control
	// Animation speed (1 = normal, 0 = paused)
	image_speed = 1;
	
	// Frame hold system
	animFrameHold = false;      // Is a frame currently held?
	animHoldFrame = 0;          // Which frame to hold
	animHoldUntilStateChange = false; // Hold until state changes?
	
	// Track previous state for detecting changes
	prevParentState = ParentState.GROUND;
	prevGroundState = GroundState.G_IDLE;
	prevAirState = AirState.A_NONE;
#endregion

#region CONTROLS
	controlsSetup();

	depth = -30;
#endregion

#region Grapple Functions
	// Get scan rectangle (starts at player's feet, extends forward and up)
	grapple_get_scan_rect = function()
	{
	    // Start from player's feet
	    var feetY = bbox_bottom;
	    
	    // Center X is at player position + offset
	    var cx = x + (grappleScanXOffset * face);
	    
	    // Top of scan box is above the feet by the scan height
	    var cy = feetY - (grappleScanHeight * 0.5) + grappleScanYOffset;
	    
	    var halfW = grappleScanWidth * 0.5;
	    var halfH = grappleScanHeight * 0.5;
	    
	    return [
	        cx - halfW,  // left
	        cy - halfH,  // top
	        cx + halfW,  // right
	        cy + halfH   // bottom
	    ];
	};
	
	// Find best grapple point in scan area
	function grapple_find_best_target()
	{
	    var r = grapple_get_scan_rect();
	    return grapple_find_best_in_rect(r[0], r[1], r[2], r[3]);
	}
	
	// Find best point inside rectangle
	function grapple_find_best_in_rect(_left, _top, _right, _bottom)
	{
	    var list = ds_list_create();
	    var n = collision_rectangle_list(
	        _left, _top, _right, _bottom,
	        obj_grapplePoint, false, false,
	        list, false
	    );
	    
	    var best   = noone;
	    var bestD2 = 999999999;
	    
	    for (var i = 0; i < n; i++)
	    {
	        var gp = list[| i];
	        
	        // Only consider points in front of player
	        if ((gp.x - x) * face <= 0) continue;
	        
	        // Only consider points above player
	        if (gp.y > y) continue;
	        
	        // Find closest point
	        var dx = gp.x - x;
	        var dy = gp.y - y;
	        var d2 = dx*dx + dy*dy;
	        
	        if (d2 < bestD2)
	        {
	            bestD2 = d2;
	            best   = gp;
	        }
	    }
	    
	    ds_list_destroy(list);
	    return best;
	}
#endregion



#region HURTBOX
	// Create hurtbox as child object
	myHurtbox = instance_create_depth(x, y, depth + 1, obj_hurtbox);
	myHurtbox.owner = id;
	myHurtbox.debug_show = false;
	myHurtbox.debug_color = c_red;
#endregion

#region ATTACK SYSTEM
	// Attack state tracking
	isAttacking = false;
	attackName = "";           // Current attack name
	attackFrame = 0;           // Current frame of attack
	attackFrameMax = 0;        // Total frames in attack
	
	// Reference to current attack hitbox
	myAttackHitbox = noone;

	// -------------------------------------------------------------------------
	// Attack data table — one entry per attack.
	// processAttack() reads from here so adding a new attack = one new entry.
	//
	// To add a new attack:
	//   1. Add an entry below.
	//   2. Add an input trigger in the ATTACK INPUT region of Step_0.
	//   3. Done.
	// -------------------------------------------------------------------------
	attackTable = {
	    standingSwing1: {
	        sprite:         attackSwing1Spr,
	        hitboxFrame:    2,
	        hitboxEndFrame: 4,
	        damage:         10,
	        offsetX:        15,
	        offsetY:        -30,
	        width:          20,
	        height:         20,
	        cancelOnAir:    false,
	        cancelOnGround: false,
	        holdLastFrame:  false,
	        debugColor:     c_yellow,
	        hitboxSpawned:  false,
	    },
	    crouch: {
	        sprite:         attackCrouchSpr,
	        hitboxFrame:    2,
	        hitboxEndFrame: 4,
	        damage:         8,
	        offsetX:        30,
	        offsetY:        -10,
	        width:          50,
	        height:         30,
	        cancelOnAir:    true,
	        cancelOnGround: false,
	        holdLastFrame:  false,  // no cancel condition to exit a ground-hold, so end normally
	        debugColor:     c_orange,
	        hitboxSpawned:  false,
	    },
	    jump: {
	        sprite:         attackAirSlashSpr,
	        hitboxFrame:    2,
	        hitboxEndFrame: 4,
	        damage:         12,
	        offsetX:        25,
	        offsetY:        -15,
	        width:          45,
	        height:         45,
	        cancelOnAir:    false,
	        cancelOnGround: true,
	        holdLastFrame:  true,
	        debugColor:     c_aqua,
	        hitboxSpawned:  false,
	    },
	}
#endregion

#region AFTERIMAGE SYSTEM
    afterimageSpawnRate = 3;     // Spawn every N frames (lower = more trails)
    afterimageTimer = 0;         // Current timer
    afterimageEnabled = false;   // Is spawning active?
    afterimageColor = c_white;   // Tint color (white = normal)

    // Named colors — edit here to change trail look per-state
    afterimageColorDash     = c_aqua;
    afterimageColorBackStep = c_orange;
    afterimageColorWallJump = c_yellow;
    afterimageColorSpeed    = c_white;
    afterimageColorGrapple  = c_lime;
#endregion

#region FX STATE TRACKING
    // Previous-frame values used to detect FX trigger moments.
    prevJumpCount        = 0;
    prevAirStateWallJump = AirState.A_NONE;
    prevJumpCountDouble  = 0;
    prevOnGround         = false;
    runDustTimer         = 0;
    myWallSlideFX        = noone;
#endregion