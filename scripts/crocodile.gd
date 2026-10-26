extends Enemy
## I coccodrilli del Duat (Libro dei Morti, capitoli 31 e 32: formule "per respingere il
## coccodrillo che viene a portare via la magia" del morto). Vivono nelle acque di Wernes.
##
## Un nemico da agguato, diverso da tutti gli altri:
## - sott'acqua non lo puoi colpire: vedi due occhi e una scia, e lui si sposta nel punto della
##   pozza o del canale più vicino a te;
## - quando passi vicino all'acqua gli occhi diventano rossi e l'acqua ribolle (l'avviso), poi
##   esce di scatto e morde;
## - sulla terra è lento e vulnerabile: è il momento di colpirlo. Poco dopo torna in acqua.
## Insegna a non camminare lungo l'acqua senza pensarci. Senza acqua (la pozza evaporata) resta
## a terra e ti insegue piano.

@export var lunge_speed := 250.0
@export var lunge_time := 0.32
@export var warn_time := 0.5
@export var bite_damage := 14.0
@export var land_time := 1.8
@export var notice := 82.0                 ## a che distanza dal bordo dell'acqua si accorge di te

var state := "submerged"
var st := 0.0
var aim := Vector2.LEFT
var home: Hazards.WaterPool = null         ## la pozza o il canale dove vive
var bit := false
var under_t := 0.0                         ## da quanto è sott'acqua: se aspetta troppo, esce lo stesso


func _ready() -> void:
	super._ready()
	_pick_home()
	if home != null:
		global_position = _water_point(global_position)
		_set_submerged(true)
	else:
		state = "land"
		st = 99.0


func _pick_home() -> void:
	var best: Hazards.WaterPool = null
	for n in get_tree().get_nodes_in_group("water"):
		var w := n as Hazards.WaterPool
		if w == null or w.drying or w.warn_t > 0.0 or w.basin:
			continue
		if best == null or w.global_position.distance_to(global_position) < best.global_position.distance_to(global_position):
			best = w
	home = best


## Il punto dentro l'acqua più vicino a `p` (un po' dentro il bordo).
func _water_point(p: Vector2) -> Vector2:
	if home == null or not is_instance_valid(home):
		return global_position
	var c := home.global_position
	var rect: Vector2 = home.rect
	if rect != Vector2.ZERO:
		var h := rect / 2.0 - Vector2(6, 6)
		return Vector2(clampf(p.x, c.x - h.x, c.x + h.x), clampf(p.y, c.y - h.y, c.y + h.y))
	var radii: Vector2 = home.radii * 0.75
	var d := (p - c) / radii
	if d.length() > 1.0:
		d = d.normalized()
	return c + d * radii


func _set_submerged(on: bool) -> void:
	state = "submerged" if on else state
	collision_layer = 0 if on else 4
	if contact != null:
		contact.set_deferred("monitoring", not on)
	if on:
		remove_from_group("enemies")        # sott'acqua non lo si mira e non lo si colpisce
	elif not is_in_group("enemies"):
		add_to_group("enemies")


func take_hit(dmg: float, dir: Vector2, kb: float, can_burn: bool = false) -> void:
	if state == "submerged":
		return
	super.take_hit(dmg, dir, kb * 0.5, can_burn)


func _stagger_time() -> float:
	return 0.12 if state == "land" else 0.0


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta
	var home_ok := home != null and is_instance_valid(home) and not home.drying
	if not home_ok and state == "submerged":
		_set_submerged(false)
		state = "land"
		st = 99.0
	if to != Vector2.ZERO and state != "lunge":
		aim = aim.lerp(to.normalized(), 0.15 if state == "land" else 0.4).normalized()
	match state:
		"submerged":
			if to == Vector2.ZERO:
				return Vector2.ZERO
			under_t += delta
			var player_pos := global_position + to
			var target := _water_point(player_pos)
			# se non ti avvicini, dopo un po' esce lui a cercarti (prima, e subito, se è l'ultimo
			# rimasto): un coccodrillo che aspetta per sempre bloccava la stanza
			var others := get_tree().get_nodes_in_group("enemies").size()
			var impatient := under_t > (2.0 if others == 0 else 6.0)
			if (impatient or player_pos.distance_to(target) < notice) and global_position.distance_to(target) < 12.0 and st <= 0.0:
				state = "warn"
				st = warn_time
				under_t = 0.0
				Sfx.play_at("serpent_hiss", global_position, 0.2)
				return Vector2.ZERO
			var v := target - global_position
			return v.normalized() * minf(speed * 1.6, v.length() / maxf(delta, 0.001)) if v.length() > 2.0 else Vector2.ZERO
		"warn":
			if randf() < 0.3:
				Fx.burst(global_position + Vector2(randf_range(-8, 8), randf_range(-4, 4)), Color(0.8, 0.95, 1.0, 0.7), 1, 30.0)
			if st <= 0.0:
				_set_submerged(false)
				state = "lunge"
				st = lunge_time
				bit = false
				if to != Vector2.ZERO:
					aim = to.normalized()
				Fx.burst(global_position, Color(0.6, 0.85, 1.0), 22, 120.0)
				Sfx.play_at("serpent_erupt", global_position, 0.2)
			return Vector2.ZERO
		"lunge":
			# il morso arriva durante lo scatto, una volta sola
			if not bit and to != Vector2.ZERO and to.length() < radius + 16.0:
				bit = true
				var p = get_tree().get_first_node_in_group("player")
				if p != null:
					p.take_damage(bite_damage, global_position, self)
			if st <= 0.0:
				state = "land"
				st = land_time
				return Vector2.ZERO
			return aim * lunge_speed
		"land":
			# a terra è lento: il momento di colpirlo. Poi torna verso l'acqua (se gli resti lontano
			# resta a terra più a lungo e ti viene a cercare).
			if st <= 0.0 and home_ok and (to == Vector2.ZERO or to.length() < 140.0 or st < -4.0):
				state = "return"
				st = 3.0
				return Vector2.ZERO
			if to == Vector2.ZERO:
				return Vector2.ZERO
			return _steer(to.normalized() * speed * 0.45, delta)
		"return":
			var back := _water_point(global_position) - global_position
			if back.length() < 8.0 or st <= 0.0:
				Fx.burst(global_position, Color(0.6, 0.85, 1.0), 14, 80.0)
				_set_submerged(true)
				st = 1.2                    # prima di riattaccare, qualche istante sott'acqua
				return Vector2.ZERO
			return _steer(back.normalized() * speed, delta)
	return Vector2.ZERO


func _contact_damage() -> float:
	return contact_damage if state == "land" or state == "return" else 0.0


## Sott'acqua: due occhi e la scia. Fuori: il corpo lungo con la cresta di scaglie, quattro zampe
## corte, il muso lungo; la pancia chiara si vede ai lati.
func _draw_body(flash: bool) -> void:
	if state == "submerged" or state == "warn":
		var warn := state == "warn"
		var k := 1.0 - st / warn_time if warn else 0.0
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, 14.0, Color(0.03, 0.1, 0.06, 0.4))
		for i in range(2 + int(warn) * 2):
			var rr := fmod(t * (14.0 + 20.0 * k) + i * 7.0, 20.0)
			draw_arc(Vector2.ZERO, rr, 0.0, TAU, 18, Color(0.75, 0.92, 1.0, 0.4 * (1.0 - rr / 20.0)), 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var side := aim.orthogonal() * 3.0
		var eye_c := Color(1.0, 0.25, 0.15) if warn else Color(0.9, 0.8, 0.3)
		for s in [-1.0, 1.0]:
			draw_circle(aim * 5.0 + side * s + Vector2(0, -1), 2.0, Color(0.15, 0.25, 0.15))
			draw_circle(aim * 5.0 + side * s + Vector2(0, -1.5), 1.0, eye_c)
		draw_circle(aim * 12.0 + Vector2(0, -0.5), 1.2, Color(0.15, 0.25, 0.15))          # le narici
		return
	var skin := _f(Color(0.27, 0.38, 0.2), flash)
	var skin_d := _f(Color(0.17, 0.26, 0.13), flash)
	var belly := _f(Color(0.7, 0.66, 0.42), flash)
	var ang := aim.angle()
	draw_set_transform(Vector2(0, -3), ang, Vector2.ONE)
	var walk := sin(t * (14.0 if state != "land" else 6.0)) * 2.0
	# zampe corte e storte
	for lx in [6.0, -8.0]:
		for sy in [-1.0, 1.0]:
			var w := walk * (1.0 if (lx > 0) == (sy > 0) else -1.0)
			_limb(Vector2(lx, sy * 5.0), Vector2(lx + 3.0 + w, sy * 10.0), skin_d, 2.6)
	# coda, corpo, muso
	var body := PackedVector2Array([Vector2(-26, 0), Vector2(-16, -4), Vector2(-4, -6.5), Vector2(8, -6), Vector2(14, -3.5), Vector2(24, -2), Vector2(26, 0), Vector2(24, 2), Vector2(14, 3.5), Vector2(8, 6), Vector2(-4, 6.5), Vector2(-16, 4)])
	_op(body, skin, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-12, 3), Vector2(8, 4.5), Vector2(8, 5.6), Vector2(-12, 3.8)]), belly)
	for i in range(7):
		var x := -20.0 + i * 5.0
		draw_line(Vector2(x, -1.5), Vector2(x + 2.0, 1.5), skin_d, 1.0)
		draw_circle(Vector2(x, 0), 1.0, skin_d.lightened(0.1))
	# occhi in rilievo e denti
	for sy in [-1.0, 1.0]:
		draw_circle(Vector2(12, sy * 3.5), 1.6, skin_d)
		draw_circle(Vector2(12.3, sy * 3.5), 0.8, Color(0.95, 0.8, 0.3))
	var jaw := 1.5 if state == "lunge" else 0.0
	for k in range(4):
		draw_line(Vector2(17 + k * 2.2, -2.2 - jaw), Vector2(17.6 + k * 2.2, -1.0 - jaw), Color(0.95, 0.92, 0.85), 0.8)
		draw_line(Vector2(17 + k * 2.2, 2.2 + jaw), Vector2(17.6 + k * 2.2, 1.0 + jaw), Color(0.95, 0.92, 0.85), 0.8)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
