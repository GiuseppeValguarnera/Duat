extends Enemy
## Avvoltoio di Nekhbet, nel cielo nero di Sokar. Vola alto, fuori dalla portata della lama:
## lo vedi in alto e, a terra, la sua ombra.
## - gira intorno a te per qualche secondo (l'Occhio di Horus lo prende anche in volo);
## - poi sceglie il punto: la sua ombra si stringe su di te (l'avviso: guarda il pavimento);
## - scende in picchiata dove eri; se sei ancora lì ti artiglia;
## - risale piano, a terra per un attimo: è il momento di colpirlo con la lama.
## Vola sopra colonne e ostacoli. Insegna a guardare il pavimento.

@export var orbit := 130.0
@export var dive_warn := 0.85
@export var dive_time := 0.28
@export var dive_damage := 10.0
@export var rise_time := 1.1

var state := "soar"
var st := 2.5
var alt := 1.0                             ## quota: 1 in volo, 0 a terra
var ang := 0.0
var target := Vector2.ZERO
var from := Vector2.ZERO
var hit_done := false
var room := Rect2(32, 64, 736, 384)


func _ready() -> void:
	super._ready()
	collision_layer = 0                    # vola: niente collisioni con muri, colonne, nemici
	collision_mask = 0
	ang = randf() * TAU
	st = randf_range(2.0, 3.5)
	var g := get_tree().current_scene as Game
	if g != null:
		room = Rect2(g.WALL, g.TOP, g.ROOM.size.x - g.WALL * 2.0, g.ROOM.size.y - g.WALL - g.TOP)


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta
	if to == Vector2.ZERO:
		return Vector2.ZERO
	var player_pos := global_position + to
	match state:
		"soar":
			alt = move_toward(alt, 1.0, delta * 1.5)
			ang += delta * 0.9
			var want := _clamp(player_pos + Vector2.from_angle(ang) * orbit)
			if st <= 0.0:
				state = "warn"
				st = dive_warn
				var p = get_tree().get_first_node_in_group("player")
				var lead: Vector2 = p.velocity * 0.25 if p != null else Vector2.ZERO
				target = _clamp(player_pos + lead)
				Sfx.play_at("serpent_hiss", global_position, 0.3)
				return Vector2.ZERO
			return (want - global_position).limit_length(speed * 1.6 * delta) / maxf(delta, 0.001) * 0.9
		"warn":
			# resta sopra, l'ombra corre verso il punto e si stringe (vedi _draw)
			if st <= 0.0:
				state = "dive"
				st = dive_time
				from = global_position
				hit_done = false
			return Vector2.ZERO
		"dive":
			var k := 1.0 - st / dive_time
			global_position = from.lerp(target, clampf(k, 0.0, 1.0))
			alt = 1.0 - k
			if st <= 0.0:
				alt = 0.0
				Fx.burst(target, Color(0.78, 0.64, 0.42), 14, 90.0)
				Fx.shake(2.0)
				var p = get_tree().get_first_node_in_group("player")
				if p != null and not hit_done and p.global_position.distance_to(target) < 20.0:
					hit_done = true
					p.take_damage(dive_damage, global_position, self)
				state = "rise"
				st = rise_time
			return Vector2.ZERO
		"rise":
			# a terra, poi risale piano: si può colpire con la lama
			alt = clampf(1.0 - st / rise_time, 0.0, 1.0) * 0.7
			if st <= 0.0:
				state = "soar"
				st = randf_range(2.2, 3.6)
				ang = (global_position - player_pos).angle()
			return Vector2.ZERO
	return Vector2.ZERO


func _clamp(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, room.position.x + 16, room.end.x - 16), clampf(p.y, room.position.y + 16, room.end.y - 16))


## In volo la lama non arriva: il colpo si sente solo se è basso (a terra o risale).
func take_hit(dmg: float, dir: Vector2, kb: float, can_burn: bool = false) -> void:
	if alt > 0.55 and state != "rise":
		# in alto solo i colpi da lontano (l'Occhio, gli spiriti): quelli della lama non ci arrivano
		var p = get_tree().get_first_node_in_group("player")
		if p != null and p.global_position.distance_to(global_position) < 60.0:
			return
	super.take_hit(dmg, dir, kb * 0.3, can_burn)


func _stagger_time() -> float:
	return 0.0


func _contact_damage() -> float:
	return 0.0


## L'avvoltoio: ali larghe e scure con le punte chiare, il collo nudo e il becco adunco, la gorgiera
## bianca (Nekhbet porta la corona bianca). In volo è disegnato in alto; a terra resta l'ombra.
func _draw_body(flash: bool) -> void:
	var wing := _f(Color(0.2, 0.16, 0.14), flash)
	var tip := _f(Color(0.62, 0.55, 0.46), flash)
	var neck := _f(Color(0.82, 0.55, 0.45), flash)
	var ruff := _f(Color(0.92, 0.9, 0.84), flash)
	# l'ombra a terra (nell'avviso corre verso il punto e si stringe)
	var sh := Vector2.ZERO
	var sh_r := 12.0
	if state == "warn":
		var k := 1.0 - st / dive_warn
		sh = (target - global_position) * k
		sh_r = lerpf(18.0, 9.0, k)
		draw_arc(target - global_position, 20.0, 0.0, TAU, 24, Color(1, 0.25, 0.15, 0.3 + 0.5 * k), 1.5)
	draw_set_transform(sh, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, sh_r, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var up := Vector2(0, -12.0 - 46.0 * alt)
	var flap := sin(t * (9.0 if alt > 0.3 else 3.0)) * (5.0 if alt > 0.3 else 1.5)
	draw_set_transform(up, 0.0, Vector2.ONE)
	for sx in [-1.0, 1.0]:
		var w := PackedVector2Array([Vector2(sx * 3, -1), Vector2(sx * 12, -6 - flap), Vector2(sx * 22, -3 - flap * 0.6), Vector2(sx * 19, 1), Vector2(sx * 10, 3), Vector2(sx * 3, 3)])
		_op(w, wing)
		for f in range(3):
			draw_line(Vector2(sx * (14 + f * 2.5), -2 - flap * 0.7), Vector2(sx * (16 + f * 2.5), 2), tip, 1.0)
	_op(_ell(Vector2(0, 1), 4.5, 5.0, 12), wing)
	_op(_ell(Vector2(0, -3.5), 3.2, 1.8, 10), ruff)
	_op(_ell(Vector2(0, -6.5), 1.8, 2.4, 8), neck)
	draw_colored_polygon(PackedVector2Array([Vector2(-1, -8.5), Vector2(1, -8.5), Vector2(0.5, -6.5), Vector2(-0.2, -6.0)]), Color(0.95, 0.85, 0.55))
	draw_circle(Vector2(-0.8, -7.2), 0.5, Color(0.05, 0.04, 0.04))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw() -> void:
	# niente ombra tonda della classe base: ha la sua (che si sposta nell'avviso)
	_draw_body(flash_t > 0.0)
	if hp < max_hp:
		var w := 20.0
		var y := -70.0 * alt - 18.0
		draw_rect(Rect2(-w / 2.0, y, w, 3), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(-w / 2.0, y, w * hp / max_hp, 3), Color(0.85, 0.2, 0.15))
