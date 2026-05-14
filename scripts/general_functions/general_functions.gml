function controlsSetup()
{
	//How many frames a frame gets buffered
	jumpBufferTime = 5;
	//False until buffer time starts
	//Once jump is pressed, it's set to true
	jumpKeyBuffered = 0;
	//starts the buffer time
	jumpKeyBufferTimer = 0;
}
function getControls()
{
	//-----------Handles user inputs-------------

	//Controller input
	rightKey = keyboard_check( vk_right ) + keyboard_check(ord("D"));
		rightKey = clamp( rightKey, 0, 1 );

	leftKey = keyboard_check( vk_left ) + keyboard_check(ord("A"));
		leftKey = clamp( leftKey, 0, 1 );

	jumpKeyPressed = keyboard_check( vk_space );

	upKey =  keyboard_check(ord("W")) + gamepad_button_check( 0, gp_padu )
		upKey = clamp( upKey, 0, 1 );

	downKey = keyboard_check(ord("S")) + gamepad_button_check( 0, gp_padd );
		downKey = clamp( downKey, 0, 1 );

	//Action Inputs
	//Controlls holding jump button
	// Grapple input
	grappleKey = keyboard_check_pressed(ord("E")) + gamepad_button_check_pressed(0, gp_shoulderl); 
		grappleKey = clamp(grappleKey, 0, 1);

	jumpKeyPressed = keyboard_check_pressed( vk_space ) + gamepad_button_check_pressed ( 0, gp_face1 );
		jumpKeyPressed = clamp ( jumpKeyPressed, 0, 1 );
		
	jumpKey = keyboard_check( vk_space ) + gamepad_button_check ( 0, gp_face1 );
		jumpKey = clamp ( jumpKey, 0, 1 );
		
	runKey = keyboard_check(vk_shift) + gamepad_button_check( 0, gp_face3 );
		runKey = clamp( runKey, 0, 1 );
		
	dashKey = keyboard_check_pressed(ord("H")) 
		dashKey = clamp(dashKey, 0, 1);
		
	attackKey = keyboard_check_pressed(ord("J")) + gamepad_button_check_pressed(0, gp_face2);
	    attackKey = clamp(attackKey, 0, 1);
		
	// Debug toggle for hurtbox visualization
	debugHurtboxKey = keyboard_check_pressed(vk_f1);
		debugHurtboxKey = clamp(debugHurtboxKey, 0, 1);
		
	//Jump key buffering
	if jumpKeyPressed
	{
		jumpKeyBufferTimer = jumpBufferTime;
	}
	if jumpKeyBufferTimer > 0
	{
		jumpKeyBuffered = 1;
		// "--" subtracts 1 every frame
		jumpKeyBufferTimer --;
	} else {
		jumpKeyBuffered = 0;
	}
}
// === FX: SPAWN FX OBJECT ===
// Spawns an FX object at the caller's position, sets its owner, and calls initializeFX().
// Returns the created instance so additional properties can be set afterward.
// Usage:   spawnFX(obj_fxDashDust, 1);
//          var _fx = spawnFX(obj_fxWallJumpDust, 1);  _fx.fxDirection = prevWallDir;
function spawnFX(_obj, _depthOffset)
{
    var _fx = instance_create_depth(x, y, depth + _depthOffset, _obj);
    _fx.owner = id;
    _fx.initializeFX();
    return _fx;
}

// === FX: GET SPAWN POINT ===
// Returns [x, y] array for FX spawn position
function getSpawnPoint(_owner, _pointType, _offsetX, _offsetY, _direction)
{
    var _x = _owner.x;
    var _y = _owner.y;
    
    switch (_pointType)
    {
        case "center":
            // Already at owner.x, owner.y
            break;
            
        case "feet":
            _y = _owner.bbox_bottom;
            break;
            
        case "bbox_top":
            _y = _owner.bbox_top;
            break;
            
        case "bbox_bottom":
            _y = _owner.bbox_bottom;
            break;
            
        case "wallside":
            // Offset to wall side (uses wallDir or face)
            var _wallOffset = 0;
            if (variable_instance_exists(_owner, "wallDir"))
            {
                _wallOffset = _owner.wallDir * abs(_offsetX);
            }
            else if (variable_instance_exists(_owner, "face"))
            {
                _wallOffset = _owner.face * abs(_offsetX);
            }
            
            _x += _wallOffset;
            _offsetX = 0;  // Already applied
            break;
    }
    
    // Apply directional offset
    _x += (_offsetX * _direction);
    _y += _offsetY;
    
    return [_x, _y];
}