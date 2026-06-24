// === CORE FX PROPERTIES ===
owner = noone;              
sprite_index = -1;          

// === POSITION & FOLLOWING ===
followOwner = false;        
followX = false;            
followY = false;            

spawnPointType = "center";  
offsetX = 0;                
offsetY = 0;

// === DIRECTION & FLIPPING ===
directionMode = "match_face";  
fixedDirection = 1;            
flipSprite = true;             
fxDirection = 1;               

// === LIFETIME & BEHAVIOR ===
lifetimeType = "animation_end";  
lifetimeDuration = 0;            
lifetimeTimer = 0;

loopCondition = "";              
alreadySpawned = false;          

// === ANIMATION ===
image_speed = 1;
image_alpha = 1;

// === SETUP ===
depth = -10;  // Default depth (will be set after owner is assigned)

// ============================================
// === USER DEFINED FUNCTIONS ===
// ============================================

// === CALCULATE DIRECTION ===
function calculateDirection()
{
    if (!instance_exists(owner)) return;
    
    switch (directionMode)
    {
        case "match_face":
            if (variable_instance_exists(owner, "face"))
            {
                fxDirection = owner.face;
            }
            break;
            
        case "opposite_face":
            if (variable_instance_exists(owner, "face"))
            {
                fxDirection = -owner.face;
            }
            break;
            
        case "match_wall":
            if (variable_instance_exists(owner, "wallDir"))
            {
                fxDirection = owner.wallDir;
            }
            break;
            
        case "velocity":
            if (variable_instance_exists(owner, "xspd"))
            {
                fxDirection = sign(owner.xspd);
                if (fxDirection == 0) fxDirection = 1;
            }
            break;
            
        case "fixed":
            fxDirection = fixedDirection;
            break;
    }
}

// === GET SPAWN POINT ===
// Returns [x, y] world position for a given spawn point type.
// Called by calculateSpawnPosition(); defined here so all child FX objects
// inherit it automatically via event_inherited().
//
//   "feet"     — bottom edge of the owner's bounding box (ground effects)
//   "center"   — vertical midpoint of the owner (air effects)
//   "wallside" — owner's x position offset toward the wall (wall effects)
//
// _offsetX is multiplied by _dir so positive values always move toward the
// direction the FX is facing (e.g. toward a wall when dir = wallDir).
function getSpawnPoint(_owner, _type, _offsetX, _offsetY, _dir)
{
    var _x = _owner.x;
    var _y = _owner.y;

    switch (_type)
    {
        case "feet":
            _y = _owner.bbox_bottom;
            break;

        case "center":
            _y = (_owner.bbox_top + _owner.bbox_bottom) / 2;
            break;

        case "wallside":
            // x is already owner.x; offsetX pushes toward the wall via _dir
            break;
    }

    _x += _offsetX * _dir;
    _y += _offsetY;

    return [_x, _y];
}

// === CALCULATE SPAWN POSITION ===
function calculateSpawnPosition()
{
    if (!instance_exists(owner)) return;

    var _pos = getSpawnPoint(owner, spawnPointType, offsetX, offsetY, fxDirection);
    x = _pos[0];
    y = _pos[1];
}

// === INITIALIZE FX ===
// Call this AFTER owner is set (from child Create Event)
function initializeFX()
{
    if (instance_exists(owner))
    {
        depth = owner.depth + 1;  // Set depth relative to owner
    }
    
    calculateDirection();
    calculateSpawnPosition();
}

// NOTE: initializeFX() will be called by child objects after setting owner