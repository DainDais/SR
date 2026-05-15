// =============================================================================
// PLAYER GRAPPLE SYSTEM
// Target finding and grapple state management.
// Grapple functions previously defined in obj_player Create_0 have been moved
// here as global script functions so they are callable from anywhere.
//
// Required variables on the entity:
//   grappling, grappleTarget, grappleKeyPressed, isClimbing, isDashing
//   grappleDirX, grappleDirY, grappleHangOffsetY, grappleAccel, grapplePullSpeed
//   grappleApproachSpeed, grappleDetachDist, grappleCancelJump
//   gravityOverride, coyoteHangTimer, xspd, yspd
//   grappleScanWidth, grappleScanHeight, grappleScanXOffset, grappleScanYOffset
//   face, bbox_bottom, setOnGround()
// =============================================================================

// -----------------------------------------------------------------------------
// grapple_get_scan_rect()
// Returns [left, top, right, bottom] of the grapple detection box.
// Centered on the player's feet + configurable offsets.
// -----------------------------------------------------------------------------
function grapple_get_scan_rect() {
    var feetY = bbox_bottom;
    var cx    = x + (grappleScanXOffset * face);
    var cy    = feetY - (grappleScanHeight * 0.5) + grappleScanYOffset;
    var halfW = grappleScanWidth  * 0.5;
    var halfH = grappleScanHeight * 0.5;
    return [cx - halfW, cy - halfH, cx + halfW, cy + halfH];
}

// -----------------------------------------------------------------------------
// grapple_find_best_target()
// Returns the closest grapple point in front of and above the entity.
// -----------------------------------------------------------------------------
function grapple_find_best_target() {
    var r = grapple_get_scan_rect();
    return grapple_find_best_in_rect(r[0], r[1], r[2], r[3]);
}

// -----------------------------------------------------------------------------
// grapple_find_best_in_rect(_left, _top, _right, _bottom)
// Scans a rectangle for obj_grapplePoint instances and returns the closest
// one that is in front of and above the entity. Returns noone if none found.
// -----------------------------------------------------------------------------
function grapple_find_best_in_rect(_left, _top, _right, _bottom) {
    var list = ds_list_create();
    var n = collision_rectangle_list(
        _left, _top, _right, _bottom,
        obj_grapplePoint, false, false,
        list, false
    );

    var best   = noone;
    var bestD2 = 999999999;

    for (var i = 0; i < n; i++) {
        var gp = list[| i];

        // Must be in front of the entity
        if ((gp.x - x) * face <= 0) continue;

        // Must be above the entity
        if (gp.y > y) continue;

        var dx = gp.x - x;
        var dy = gp.y - y;
        var d2 = dx * dx + dy * dy;

        if (d2 < bestD2) {
            bestD2 = d2;
            best   = gp;
        }
    }

    ds_list_destroy(list);
    return best;
}

// -----------------------------------------------------------------------------
// processGrapple()
// Handles grapple initiation and in-flight movement each frame.
// Call after processInput() and processDash(), before applyXMovement().
// -----------------------------------------------------------------------------
function processGrapple() {

    // === INITIATE GRAPPLE ===
    if (!grappling && !isClimbing && grappleKeyPressed) {
        var _target = grapple_find_best_target();

        if (instance_exists(_target)) {
            grappling     = true;
            grappleTarget = _target;

            var tx  = grappleTarget.x;
            var ty  = grappleTarget.y + grappleHangOffsetY;
            var dx  = tx - x;
            var dy  = ty - y;
            var mag = max(0.0001, sqrt(dx * dx + dy * dy));

            grappleDirX = dx / mag;
            grappleDirY = dy / mag;

            var _impulse = min(grappleAccel * 2, grapplePullSpeed);
            xspd = grappleDirX * _impulse;
            yspd = grappleDirY * _impulse;

            setOnGround(false);
            isDashing = false;
            lockY     = false;
        }
    }

    // === GRAPPLE IN FLIGHT ===
    if (grappling) {
        if (!instance_exists(grappleTarget)) {
            grappling = false;
        } else {
            var tx   = grappleTarget.x;
            var ty   = grappleTarget.y + grappleHangOffsetY;
            var dx   = tx - x;
            var dy   = ty - y;
            var dist = sqrt(dx * dx + dy * dy);

            if (dist <= grappleDetachDist) {
                // Arrived — snap and detach
                var nx = (dist > 0.0001) ? dx / dist : 0;
                var ny = (dist > 0.0001) ? dy / dist : 0;
                xspd = nx * grappleApproachSpeed;
                yspd = ny * grappleApproachSpeed;

                if (!place_meeting(tx, ty, obj_wall)) {
                    x = tx;
                    y = ty;
                }
                grappling = false;
            } else {
                // Still travelling
                var _step = min(grappleApproachSpeed, dist);
                var _nx   = dx / dist;
                var _ny   = dy / dist;
                xspd = _nx * _step;
                yspd = _ny * _step;

                setOnGround(false);
                coyoteHangTimer = 1;
                gravityOverride = true;

                if (grappleCancelJump && jumpKeyPressed) {
                    grappling       = false;
                    gravityOverride = false;
                }
            }
        }
    } else {
        // Not grappling — clear gravity override unless another system holds it
        if (!isDashing && !isClimbing) {
            gravityOverride = false;
        }
    }
}
