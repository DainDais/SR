// =============================================================================
// ENTITY MOVING PLATFORM SYSTEM
// Universal. Handles three phases of platform interaction each step.
//
// Call order in Step:
//   1. resolveMovingPlatformPushOut()  — before ability logic
//   2. resolveMovingPlatformEarly()    — before ability logic
//   3. resolveMovingPlatformLate()     — after resolveYCollision()
//
// Required variables on the entity:
//   myFloorPlat, earlyMoveplatXspd, moveplatXspd, moveplatMaxYspd
//   bbox_right, bbox_left, bbox_bottom, bbox_top, xspd, yspd
//   setOnGround() — defined in Create_0 per entity
// =============================================================================

// -----------------------------------------------------------------------------
// resolveMovingPlatformPushOut()
// Prevents the entity from being embedded inside a moving solid platform.
// Call at the very start of the step, before any movement.
// -----------------------------------------------------------------------------
function resolveMovingPlatformPushOut() {
    var _rightWall  = noone;
    var _leftWall   = noone;
    var _bottomWall = noone;
    var _topWall    = noone;
    var _list = ds_list_create();
    var _listSize = instance_place_list(x, y, obj_movePlat, _list, false);

    for (var i = 0; i < _listSize; i++) {
        var _listInst = _list[| i];

        if (_listInst.bbox_left - _listInst.xspd >= bbox_right - 1) {
            if (!instance_exists(_rightWall) || _listInst.bbox_left < _rightWall.bbox_left)
                _rightWall = _listInst;
        }

        if (_listInst.bbox_right - _listInst.xspd <= bbox_left + 1) {
            if (!instance_exists(_leftWall) || _listInst.bbox_right > _leftWall.bbox_right)
                _leftWall = _listInst;
        }

        if (_listInst.bbox_top - _listInst.yspd >= bbox_bottom - 1) {
            if (!instance_exists(_bottomWall) || _listInst.bbox_top < _bottomWall.bbox_top)
                _bottomWall = _listInst;
        }

        if (_listInst.bbox_bottom - _listInst.yspd <= bbox_top + 1) {
            if (!instance_exists(_topWall)
            || _listInst.bbox_bottom + _listInst.yspd <= _topWall.bbox_bottom + _topWall.yspd)
                _topWall = _listInst;
        }
    }
    ds_list_destroy(_list);

    if (instance_exists(_rightWall)) {
        var _rightDist = bbox_right - x;
        x = _rightWall.bbox_left - _rightDist;
    }

    if (instance_exists(_leftWall)) {
        var _leftDist = x - bbox_left;
        x = _leftWall.bbox_right + _leftDist;
    }

    if (instance_exists(_bottomWall)) {
        var _bottomDist = bbox_bottom - y;
        y = _bottomWall.bbox_top - _bottomDist;
    }

    if (instance_exists(_topWall)) {
        var _upDist  = y - bbox_top;
        var _targetY = _topWall.bbox_bottom + _upDist;
        if (!place_meeting(x, _targetY, obj_wall)) {
            y = _targetY;
        }
    }
}

// -----------------------------------------------------------------------------
// resolveMovingPlatformEarly()
// Carries the entity along with a horizontally moving floor platform so it
// doesn't fall off the back edge before movement is processed.
// Call right after resolveMovingPlatformPushOut().
// -----------------------------------------------------------------------------
function resolveMovingPlatformEarly() {
    earlyMoveplatXspd = false;
    if (instance_exists(myFloorPlat)
    && myFloorPlat.xspd != 0
    && !place_meeting(x, y + moveplatMaxYspd + 1, myFloorPlat)) {
        if (!place_meeting(x + myFloorPlat.xspd, y, obj_wall)) {
            x += myFloorPlat.xspd;
            earlyMoveplatXspd = true;
        }
    }
}

// -----------------------------------------------------------------------------
// resolveMovingPlatformLate()
// Applies platform xspd after physics, fixes vertical jitter on moving floors,
// and handles being pushed down through a semisolid by a solid platform.
// Call after resolveYCollision().
// -----------------------------------------------------------------------------
function resolveMovingPlatformLate() {
    // === APPLY PLATFORM X VELOCITY ===
    moveplatXspd = 0;
    if (instance_exists(myFloorPlat)) { moveplatXspd = myFloorPlat.xspd; }

    if (place_meeting(x + moveplatXspd, y, obj_wall)) {
        var _subPixel    = 0.5;
        var _pixelCheck  = _subPixel * sign(moveplatXspd);
        while (!place_meeting(x + _pixelCheck, y, obj_wall)) { x += _pixelCheck; }
        moveplatXspd = 0;
    }
    x += moveplatXspd;

    // === JITTER FIX ===
    if (instance_exists(myFloorPlat) && myFloorPlat.yspd != 0) {
        if (!place_meeting(x, myFloorPlat.bbox_top, obj_wall)
        && myFloorPlat.bbox_top >= bbox_bottom - moveplatMaxYspd) {
            y = myFloorPlat.bbox_top;
        }
    }

    // === PUSHED DOWN THROUGH SEMISOLID ===
    if (instance_exists(myFloorPlat)
    && (myFloorPlat.object_index == obj_semiSolidWall
    || object_is_ancestor(myFloorPlat.object_index, obj_semiSolidWall))
    && place_meeting(x, y, obj_wall)) {
        var _maxPushDist = 10;
        var _pushedDist  = 0;
        var _startY      = y;
        while (place_meeting(x, y, obj_wall) && _pushedDist <= _maxPushDist) {
            y++;
            _pushedDist++;
        }
        setOnGround(false);
        if (_pushedDist > _maxPushDist) { y = _startY; }
    }
}
