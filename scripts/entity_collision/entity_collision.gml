// =============================================================================
// ENTITY COLLISION SYSTEM
// Universal X and Y collision resolution against obj_wall and obj_semiSolidWall.
//
// Required variables on the entity:
//   xspd, yspd, termVel, moveDir, bbox_bottom, bbox_top
//   myFloorPlat, forgetSemiSolid, moveplatMaxYspd
//   downSlopeSemiSolid, downKey, jumpKeyPressed
//   setOnGround() — defined in Create_0 per entity
//   checkForSemisolidPlatform() — defined in Create_0 per entity
// =============================================================================

// -----------------------------------------------------------------------------
// resolveXCollision()
// Handles slope stepping and wall stopping. Applies x += xspd at the end.
// Call after applyXMovement().
// -----------------------------------------------------------------------------
function resolveXCollision() {
    var _subPixel = 0.5;

    if (place_meeting(x + xspd, y, obj_wall)) {
        if (!place_meeting(x + xspd, y - abs(xspd) - 2, obj_wall)) {
            // Step up a slope
            while (place_meeting(x + xspd, y, obj_wall)) { y -= _subPixel; }
        } else if (!place_meeting(x + xspd, y + abs(xspd) + 1, obj_wall)) {
            // Step down a slope
            while (place_meeting(x + xspd, y, obj_wall)) { y += _subPixel; }
        } else {
            // Hard wall — slide pixel-by-pixel to edge
            var _pixelCheck = _subPixel * sign(xspd);
            while (!place_meeting(x + _pixelCheck, y, obj_wall)) { x += _pixelCheck; }
            xspd = 0;
        }
    }

    // Stick to downward slopes so the player doesn't float off edges
    downSlopeSemiSolid = noone;
    if (yspd >= 0
    && !place_meeting(x + xspd, y + 1, obj_wall)
    && place_meeting(x + xspd, y + abs(xspd) + 3, obj_wall)) {
        downSlopeSemiSolid = checkForSemisolidPlatform(x + xspd, y + abs(xspd) + 1);
        if (!instance_exists(downSlopeSemiSolid)) {
            while (!place_meeting(x + xspd, y + _subPixel, obj_wall)) { y += _subPixel; }
        }
    }

    x += xspd;
}

// -----------------------------------------------------------------------------
// resolveYCollision()
// Handles ceiling slope slide, floor detection (solid + semisolid), drop-through,
// and applies y += yspd at the end.
// Call after applyJump().
// -----------------------------------------------------------------------------
function resolveYCollision() {
    if (yspd > termVel) { yspd = termVel; }
    var _subPixel = 0.5;

    // === CEILING / UPWARD COLLISION ===
    if (yspd < 0 && place_meeting(x, y + yspd, obj_wall)) {
        var _slopeSlide = false;

        if (moveDir != 1 && !place_meeting(x - abs(yspd) - 1, y + yspd, obj_wall)) {
            while (place_meeting(x, y + yspd, obj_wall)) { x -= 1; }
            _slopeSlide = true;
        }

        if (moveDir != -1 && !place_meeting(x + abs(yspd) + 1, y + yspd, obj_wall)) {
            while (place_meeting(x, y + yspd, obj_wall)) { x += 1; }
            _slopeSlide = true;
        }

        if (!_slopeSlide) {
            var _pixelCheck = _subPixel * sign(yspd);
            while (!place_meeting(x, y + _pixelCheck, obj_wall)) { y += _pixelCheck; }
            yspd = 0;
        }
    }

    // === FLOOR DETECTION ===
    var _clampYspd = max(0, yspd);
    var _list  = ds_list_create();
    var _array = array_create(0);
    array_push(_array, obj_wall, obj_semiSolidWall);

    var _listSize = instance_place_list(x, y + 1 + _clampYspd + moveplatMaxYspd, _array, _list, false);

    for (var i = 0; i < _listSize; i++) {
        var _listInst = _list[| i];
        if (_listInst != forgetSemiSolid
        && (_listInst.yspd <= yspd || instance_exists(myFloorPlat))
        && (_listInst.yspd > 0 || place_meeting(x, y + 1 + _clampYspd, _listInst))) {
            if (_listInst.object_index == obj_wall
            || object_is_ancestor(_listInst.object_index, obj_wall)
            || floor(bbox_bottom) <= ceil(_listInst.bbox_top - _listInst.yspd)) {
                if (!instance_exists(myFloorPlat)
                || _listInst.bbox_top + _listInst.yspd <= myFloorPlat.bbox_top + myFloorPlat.yspd
                || _listInst.bbox_top + _listInst.yspd <= bbox_bottom) {
                    myFloorPlat = _listInst;
                }
            }
        }
    }
    ds_list_destroy(_list);

    if (instance_exists(myFloorPlat) && !place_meeting(x, y + moveplatMaxYspd, myFloorPlat)) {
        myFloorPlat = noone;
    }

    if (instance_exists(myFloorPlat)) {
        while (!place_meeting(x, y + _subPixel, myFloorPlat) && !place_meeting(x, y, obj_wall)) { y += _subPixel; }
        if (myFloorPlat.object_index == obj_semiSolidWall
        || object_is_ancestor(myFloorPlat.object_index, obj_semiSolidWall)) {
            while (place_meeting(x, y, myFloorPlat)) { y -= _subPixel; }
        }
        y = floor(y);
        yspd = 0;
        setOnGround(true);
    }

    // === DROP THROUGH SEMISOLID ===
    if (downKey && jumpKeyPressed) {
        if (instance_exists(myFloorPlat)
        && (myFloorPlat.object_index == obj_semiSolidWall
        || object_is_ancestor(myFloorPlat.object_index, obj_semiSolidWall))) {
            var _yCheck = y + max(1, myFloorPlat.yspd + 1);
            if (!place_meeting(x, _yCheck, obj_wall)) {
                y += 1;
                forgetSemiSolid = myFloorPlat;
                setOnGround(false);
            }
        }
    }

    // === APPLY Y MOVEMENT ===
    if (!place_meeting(x, y + yspd, obj_wall)) {
        y += yspd;
    }

    if (instance_exists(forgetSemiSolid) && !place_meeting(x, y, forgetSemiSolid)) {
        forgetSemiSolid = noone;
    }
}
