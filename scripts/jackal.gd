extends Enemy
## Sciacallo del deserto di Sokar. Arrivano in branco da tre e si dividono i compiti:
## - uno ti si mette davanti, a qualche passo, e ringhia: ti distrae;
## - gli altri due ti girano ai lati, uno a destra e uno a sinistra;
## - quando i fianchi sono in posizione, saltano. Prima di ogni salto abbassano la testa e si
##   acquattano (l'avviso), poi balzano dritti con un morso.
## Insegna a non farsi chiudere: colpisci quello davanti e scatta via prima che il cerchio si chiuda.
## Da solo (gli altri morti) non aspetta più nessuno: salta appena può.

@export var leap_windup := 0.42
@export var leap_speed := 290.0
@export var leap_time := 0.3
@export var bite_damage := 8.0
@export var front_dist := 64.0            ## quanto sta lontano quello che ti fa da esca
@export var flank_dist := 70.0

var state := "chase"
var st := 0.0
var aim := Vector2.RIGHT
var role := 0                             ## 0 = davanti, 1 = fianco destro, -1 = fianco sinistro
var bit := false
var role_t := 0.0


func _pack() -> Array:
	var out: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get_script() == get_script() and not e.dead:
			out.append(e)
	out.sort_custom(func(a, b) -> bool: return a.get_instance_id() < b.get_instance_id())
	return out


## Chi fa cosa: il primo del branco ti sta davanti, gli altri ai fianchi.
func _update_role() -> void:
	var pack := _pack()
	var i := pack.find(self)
	if pack.size() <= 1:
		role = 2                                  # solo: niente esca, niente fianchi
	elif i % 3 == 0:
		role = 0
	else:
		role = 1 if i % 3 == 1 else -1


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta
	role_t -= delta
	if role_t <= 0.0:
		role_t = 0.5
		_update_role()
	if to == Vector2.ZERO:
		return Vector2.ZERO
	var d := to.length()
	var u := to / d
	match state:
		"chase":
			aim = u
			var ready_to_leap := st <= 0.0 and d < 110.0
			if role == 0:
				# l'esca: resta davanti a te, a distanza, e salta solo quando i fianchi sono pronti
				if ready_to_leap and _flanks_ready(to):
					return _start_leap()
				var want := global_position + to - u * front_dist
				if randf() < 0.01:
					Sfx.play_at("amheh_growl", global_position, 0.25)
				return _steer((want - global_position).limit_length(1.0) * speed * (1.0 if (want - global_position).length() > 8.0 else 0.0), delta)
			if role == 2:
				if ready_to_leap and d < 90.0:
					return _start_leap()
				return _steer(u * speed, delta)
			# i fianchi: un punto a lato del giocatore, poi il salto
			var side := u.orthogonal() * float(role)
			var spot := global_position + to + side * flank_dist
			if ready_to_leap and (spot - global_position).length() < 26.0:
				return _start_leap()
			var v := spot - global_position
			return _steer(v.normalized() * speed * 1.15, delta) if v.length() > 4.0 else Vector2.ZERO
		"windup":
			if st > leap_windup * 0.4:
				aim = u
			if st <= 0.0:
				state = "leap"
				st = leap_time
				bit = false
				Sfx.play_at("dash", global_position, 0.3)
			return Vector2.ZERO
		"leap":
			if not bit and d < radius + 12.0:
				bit = true
				var p = get_tree().get_first_node_in_group("player")
				if p != null:
					p.take_damage(bite_damage, global_position, self)
			if st <= 0.0:
				state = "recover"
				st = 0.5
			return aim * leap_speed
		"recover":
			if st <= 0.0:
				state = "chase"
				st = randf_range(0.9, 1.6)
			return -u * speed * 0.35
	return Vector2.ZERO


func _start_leap() -> Vector2:
	state = "windup"
	st = leap_windup
	Sfx.play_at("amheh_growl", global_position, 0.2)
	return Vector2.ZERO


## L'esca aspetta che almeno un fianco sia vicino al suo posto (o che i fianchi stiano già saltando).
func _flanks_ready(to: Vector2) -> bool:
	for e in _pack():
		if e == self or e.role == 0:
			continue
		if e.state == "windup" or e.state == "leap":
			return true
		var side := (to.normalized()).orthogonal() * float(e.role)
		var spot := global_position + to + side * flank_dist
		if (e.global_position - spot).length() < 40.0:
			return true
	return false


func _stagger_time() -> float:
	return 0.25


func _contact_damage() -> float:
	return 0.0                     # morde solo con il salto


## Lo sciacallo: magro, color sabbia con il dorso scuro, orecchie grandi a punta, muso lungo, coda
## folta. Avviso: si acquatta, abbassa la testa e mostra i denti.
func _draw_body(flash: bool) -> void:
	var fur := _f(Color(0.72, 0.52, 0.28), flash)
	var back := _f(Color(0.28, 0.2, 0.14), flash)
	var belly := _f(Color(0.88, 0.76, 0.56), flash)
	var dir := 1.0 if aim.x >= 0.0 else -1.0
	var crouch := 0.0
	if state == "windup":
		crouch = 1.0 - st / leap_windup
	var stretch := 1.0 if state == "leap" else 0.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
	var run := sin(t * (18.0 if velocity.length() > 20.0 else 4.0))
	var by := -9.0 + crouch * 3.0
	# zampe sottili
	for lx in [-5.0, 4.0]:
		var w := run * 2.5 * (1.0 if lx > 0 else -1.0) + stretch * (3.0 if lx > 0 else -3.0)
		_limb(Vector2(lx, by + 3), Vector2(lx + w, -0.5), fur.darkened(0.15), 1.4)
		_limb(Vector2(lx + 1.5, by + 3), Vector2(lx + 1.5 - w, -0.5), fur, 1.4)
	# coda folta, in basso
	_op(PackedVector2Array([Vector2(-7, by), Vector2(-14, by + 3 - stretch * 3.0), Vector2(-15, by + 6 - stretch * 3.0), Vector2(-8, by + 3)]), back)
	# corpo
	_op(_ell(Vector2(0, by), 8.0 + stretch * 2.0, 3.6, 14), fur)
	draw_colored_polygon(PackedVector2Array([Vector2(-7, by - 1.5), Vector2(6, by - 2.5), Vector2(5, by - 1), Vector2(-7, by)]), back)
	draw_line(Vector2(-5, by + 2.6), Vector2(5, by + 2.4), belly, 1.0)
	# testa: si abbassa nell'avviso
	var h := Vector2(8.5, by - 3.0 + crouch * 4.0)
	_op(_ell(h, 3.6, 3.0, 10), fur)
	_op(PackedVector2Array([h + Vector2(2, -1.5), h + Vector2(8, 0.5), h + Vector2(7.5, 1.6), h + Vector2(2, 1.8)]), fur)
	draw_circle(h + Vector2(8, 0.8), 0.9, Color(0.08, 0.06, 0.05))
	# orecchie grandi a punta
	for k in [0.0, 2.2]:
		_op(PackedVector2Array([h + Vector2(-1.5 + k, -2), h + Vector2(-0.5 + k, -7.5 + crouch * 2.0), h + Vector2(0.8 + k, -2)]), back)
	# occhio: rosso nell'avviso
	draw_circle(h + Vector2(1.6, -0.6), 0.8, Color(1.0, 0.3, 0.15) if state == "windup" else Color(0.95, 0.8, 0.3))
	if state == "windup" or state == "leap":
		for k in range(3):
			draw_line(h + Vector2(4 + k * 1.3, 1.6), h + Vector2(4.5 + k * 1.3, 2.6), Color(0.95, 0.92, 0.85), 0.6)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if state == "windup":
		# l'avviso a terra: la linea del salto
		var k2 := 1.0 - st / leap_windup
		draw_line(Vector2(0, -4), Vector2(0, -4) + aim * leap_speed * leap_time * 0.8, Color(1, 0.25, 0.15, 0.25 + 0.4 * k2), 2.0)
