extends Enemy
## Sacerdote di Sokar: non attacca. Ogni 4 secondi circa dà uno scudo di sabbia a un alleato vicino
## (prima la sabbia gli si raccoglie tra le mani, poi un fiotto la porta all'alleato). Resta lontano
## da te, dietro gli altri: è il bersaglio da cercare per primo. In Sokar prende il posto del
## sacerdote di Set. Veste di nero e d'oro, con la maschera del falco di Sokar.

@export var keep_min := 130.0
@export var shield_every := 4.0
@export var windup := 0.6
@export var reach := 150.0

var cd := 2.0
var casting := 0.0
var target_ally: Enemy = null
var beam_t := 0.0
var beam_to := Vector2.ZERO


func _behave(delta: float, to: Vector2) -> Vector2:
	cd -= delta
	beam_t = maxf(0.0, beam_t - delta)
	if casting > 0.0:
		casting -= delta
		if casting <= 0.0:
			_give_shield()
		return Vector2.ZERO
	if cd <= 0.0:
		target_ally = _pick_ally()
		if target_ally != null:
			casting = windup
			cd = shield_every + randf() * 0.6
			Sfx.play_at("priest_cast", global_position, 0.1)
			return Vector2.ZERO
		cd = 0.8
	if to == Vector2.ZERO:
		return Vector2.ZERO
	# si tiene lontano da te e vicino agli alleati
	var d := to.length()
	var u := to / maxf(d, 0.01)
	var v := Vector2.ZERO
	if d < keep_min:
		v -= u
	var ally := _nearest_ally()
	if ally != null and global_position.distance_to(ally.global_position) > reach * 0.7:
		v += (ally.global_position - global_position).normalized() * 0.7
	v += u.orthogonal() * sin(t * 0.7 + seed_offset) * 0.4
	if v.length() < 0.05:
		return Vector2.ZERO
	return _steer(v.normalized() * speed, delta)


func _allies() -> Array:
	var out := []
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or e.dead or e.is_boss or e.miniboss or not e.has_method("_behave"):
			continue
		if e.get_script() == get_script():
			continue                  # i sacerdoti non si proteggono tra loro
		if global_position.distance_to(e.global_position) < reach:
			out.append(e)
	return out


func _nearest_ally() -> Enemy:
	var best: Enemy = null
	var bd := 1e9
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or e.dead or e.is_boss:
			continue
		var d := global_position.distance_to(e.global_position)
		if d < bd:
			bd = d
			best = e
	return best


## Chi proteggere: un alleato vicino senza scudo, il più ferito.
func _pick_ally() -> Enemy:
	var best: Enemy = null
	var score := -1e9
	for e in _allies():
		if e.sand_shield > 0.0:
			continue
		var s: float = 1.0 - e.hp / e.max_hp + randf() * 0.2
		if s > score:
			score = s
			best = e
	return best


func _give_shield() -> void:
	if target_ally == null or not is_instance_valid(target_ally) or target_ally.dead:
		return
	target_ally.sand_shield = minf(target_ally.max_hp * 0.4, 30.0 * Run.enemy_hp_mult())
	beam_t = 0.4
	beam_to = target_ally.global_position
	Fx.burst(target_ally.global_position + Vector2(0, -10), Color(0.9, 0.75, 0.45), 16, 80.0)
	Sfx.play_at("orb", global_position, 0.1)


func _on_hit(_dmg: float) -> void:
	if casting > 0.0:
		casting = 0.0                 # colpito mentre prega: lo scudo salta
		cd = 1.2


func _draw_body(flash: bool) -> void:
	var robe := _f(Color(0.12, 0.1, 0.1), flash)
	var robe_d := _f(Color(0.05, 0.04, 0.04), flash)
	var gold := _f(GOLD, flash)
	var mask := _f(Color(0.2, 0.36, 0.3), flash)
	var skin := _f(Color(0.5, 0.32, 0.2), flash)
	var bob := sin(t * 2.5) * 0.5
	draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE)
	_op(PackedVector2Array([Vector2(-8.5, 0), Vector2(8.5, 0), Vector2(5.0, -15), Vector2(4.0, -21), Vector2(-4.0, -21), Vector2(-5.0, -15)]), robe)
	draw_line(Vector2(-5.5, -14), Vector2(5.5, -14), gold, 1.2)
	draw_line(Vector2(0, -14), Vector2(0, 0), robe_d, 0.9)
	# braccia alzate quando prega
	var k := 0.0 if casting <= 0.0 else 1.0 - casting / windup
	for sx in [-1.0, 1.0]:
		_limb(Vector2(sx * 4.0, -19), Vector2(sx * (6.0 + 2.0 * k), -14.0 - 10.0 * k), skin, 1.5)
	# la maschera del falco di Sokar, verde scuro con il becco d'oro
	var hc := Vector2(0, -24.5)
	_op(_ell(hc, 4.4, 4.0, 12), mask)
	_op(PackedVector2Array([hc + Vector2(2.6, -1.2), hc + Vector2(7.0, 0.6), hc + Vector2(2.8, 2.0)]), gold, 0.6)
	draw_circle(hc + Vector2(1.6, -0.8), 0.9, Color(1.0, 0.85, 0.4) if not flash else Color.WHITE)
	draw_circle(hc + Vector2(0, -6.0), 2.2, gold)                       # il disco del sole sul capo
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if casting > 0.0:
		for i in range(5):
			var a := t * 6.0 + i * TAU / 5.0
			draw_circle(Vector2(0, -32) + Vector2.from_angle(a) * (7.0 - 4.0 * k), 1.3, Color(0.95, 0.8, 0.5, 0.8))
	if beam_t > 0.0:
		var to := beam_to - global_position
		draw_line(Vector2(0, -30), to + Vector2(0, -12), Color(0.95, 0.8, 0.5, beam_t * 2.0), 2.5)
