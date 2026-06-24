// === HEALTH TICK ===
tickHealth();

// === FACE PLAYER ===
if (instance_exists(obj_player)) {
    var _dirToPlayer = sign(obj_player.x - x);
    if (_dirToPlayer != 0) {
        face = _dirToPlayer;
    }
}

// === SHOOT ===
shootTimer++;
if (shootTimer >= shootInterval && instance_exists(obj_player)) {
    var _orb = instance_create_depth(x, y, depth - 1, obj_damageOrb);
    _orb.owner = id;
    _orb.dir   = point_direction(x, y, obj_player.x, obj_player.y);
    shootTimer = 0;
}
