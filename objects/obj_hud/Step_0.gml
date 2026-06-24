// =============================================================================
// DEBUG ONLY — hold number keys to test the meters. Delete this event (or its
// contents) once real gameplay systems drive hp/mp/posture.
//   1 / 2 : drain / refill HP
//   3 / 4 : drain / refill MP
//   5 / 6 : drain / refill Posture
// =============================================================================

if (!instance_exists(obj_player)) exit;

with (obj_player)
{
	if (keyboard_check(ord("1"))) hp      = max(hp - 0.5, 0);
	if (keyboard_check(ord("2"))) hp      = min(hp + 0.5, maxHp);
	if (keyboard_check(ord("3"))) mp      = max(mp - 0.5, 0);
	if (keyboard_check(ord("4"))) mp      = min(mp + 0.5, mp_max);
	if (keyboard_check(ord("5"))) posture = max(posture - 0.5, 0);
	if (keyboard_check(ord("6"))) posture = min(posture + 0.5, posture_max);
}
