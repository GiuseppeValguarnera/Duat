extends Enemy
## Am-heh, "il Divoratore di Milioni": un dio dalla testa di cane che nel Duat vive in un
## lago di fuoco e divora le anime dei dannati. È il boss della Prima Ora, le acque di Wernes.
## (Ammit resta per il finale, nella Sala delle Due Verità: vedi docs/storia.md.)
##
## L'arena ha quattro pozze d'acqua: il fuoco non vi entra. Mosse, tutte annunciate:
##  - Morso: da vicino, un ventaglio rosso davanti alle fauci, poi azzanna.
##  - Balzo: un cerchio rosso segna dove atterrerà; all'atterraggio accende un anello di fuoco.
##  - Fiato di fuoco: un cono arancione mostra la direzione, poi soffia fiamme che restano a terra.
##  - Marea di fuoco: ulula, il pavimento si accende di rosso a ondata, poi divampa ovunque
##    tranne nell'acqua. Dopo resta esausto qualche secondo e subisce il 50% di danni in più.
## Al 60% e al 30% della vita fa evaporare una pozza (ne restano sempre due) e chiama scarabei.

signal summon(kinds: Array)

@export_group("Morso")
@export var bite_range := 64.0
@export var bite_windup := 0.45
@export var bite_reach := 50.0
@export var bite_arc := 100.0
@export var bite_damage := 20.0

@export_group("Balzo")
@export var leap_windup := 0.75
@export var leap_time := 0.5
@export var leap_radius := 34.0
@export var leap_damage := 20.0

@export_group("Fiato di fuoco")
@export var breath_windup := 0.6
@export var breath_time := 1.1
@export var breath_range := 130.0
@export var breath_arc := 50.0
@export var breath_damage := 4.0

@export_group("Marea di fuoco")
@export var flood_warn := 2.0
@export var flood_damage := 18.0
@export var exhausted_time := 2.5

var state := "intro"
var st := 1.2
var aim := Vector2.DOWN
var phase := 0                         # 0, 1 sotto il 60%, 2 sotto il 30%
var since_flood := 0                   # attacchi dall'ultima marea
var leap_from := Vector2.ZERO
var leap_to := Vector2.ZERO
var breath_tick := 0.0
var breath_spawn := 0.0
var arena := Rect2()                   # il pavimento della stanza, per la marea


func _ready() -> void:
	is_boss = true
	if Weights.rank("fame") > 0:
		max_hp *= 1.3                 # Peso del Cuore: la fame di Am-heh
	super._ready()


func _rage() -> float:
	return 1.0 + 0.15 * phase


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta * _rage()
	_check_phase()
	match state:
		"intro", "phase":
			if st <= 0.0:
				state = "chase"
				st = 0.8
			return Vector2.ZERO
		"chase":
			if to != Vector2.ZERO:
				aim = to.normalized()
			if st <= 0.0:
				_choose_attack(to)
				return Vector2.ZERO
			return aim * speed * _rage()
		"bite":
			if st > bite_windup * 0.5 and to != Vector2.ZERO:
				aim = to.normalized()
			if st <= 0.0:
				_bite()
				_after_attack(0.55)
			return Vector2.ZERO
		"leap_windup":
			# il bersaglio segue il giocatore fino a metà dell'avviso, poi resta fermo
			if st > leap_windup * 0.5 and to != Vector2.ZERO:
				leap_to = _clamp_arena(global_position + to)
			if st <= 0.0:
				state = "leap"
				st = leap_time
				leap_from = global_position
				Sfx.play("dash", 0.1)
			return Vector2.ZERO
		"leap":
			var k := clampf(1.0 - st / leap_time, 0.0, 1.0)
			global_position = leap_from.lerp(leap_to, k)
			if st <= 0.0:
				_land()
				_after_attack(0.7)
			return Vector2.ZERO
		"breath_windup":
			if to != Vector2.ZERO:
				aim = to.normalized()
			if st <= 0.0:
				state = "breath"
				st = breath_time
				breath_tick = 0.0
				breath_spawn = 0.0
				Sfx.play("roar", 0.2)
			return Vector2.ZERO
		"breath":
			# la fiamma segue il giocatore, ma lentamente: ci si sottrae girandogli intorno
			if to != Vector2.ZERO:
				var turn := (0.55 + 0.2 * phase) * delta
				aim = aim.rotated(clampf(aim.angle_to(to), -turn, turn))
			_breathe(delta, to)
			if st <= 0.0:
				_after_attack(0.6)
			return Vector2.ZERO
		"howl":
			if st <= 0.0:
				state = "exhausted"
				st = exhausted_time
				Fx.float_text(global_position + Vector2(0, -36), "ESAUSTO", Color(1, 0.85, 0.3))
			return Vector2.ZERO
		"exhausted", "recover":
			if st <= 0.0:
				state = "chase"
				st = 0.9 + randf() * 0.7
			return Vector2.ZERO
	return Vector2.ZERO


func _after_attack(rest: float) -> void:
	state = "recover"
	st = rest
	since_flood += 1


## Sceglie la mossa: la marea arriva a intervalli regolari, il resto dipende dalla distanza.
func _choose_attack(to: Vector2) -> void:
	var every := 3 if phase == 0 else 2
	if Weights.rank("fame") > 0:
		every = 2
	if since_flood >= every:
		_howl()
		return
	var d := to.length() if to != Vector2.ZERO else 999.0
	var r := randf()
	if d < bite_range and r < 0.55:
		state = "bite"
		st = bite_windup
	elif r < 0.55 or d > 170.0:
		state = "leap_windup"
		st = leap_windup
		leap_to = _clamp_arena(global_position + to)
	else:
		state = "breath_windup"
		st = breath_windup


func _check_phase() -> void:
	var want := 0
	if hp < max_hp * 0.3:
		want = 2
	elif hp < max_hp * 0.6:
		want = 1
	if want <= phase:
		return
	phase = want
	state = "phase"
	st = 1.0
	Fx.shake(8.0)
	Sfx.play("roar", 0.0)
	_dry_a_pool()
	summon.emit(["scarab", "scarab", "scarab", "scarab"] if phase == 1 else ["scarab", "scarab", "priest"])


## Fa evaporare la pozza più vicina a lui (ne lascia sempre almeno due).
func _dry_a_pool() -> void:
	var pools := get_tree().get_nodes_in_group("water").filter(func(w): return not w.drying)
	if pools.size() <= 2:
		return
	pools.sort_custom(func(a, b): return a.global_position.distance_to(global_position) < b.global_position.distance_to(global_position))
	pools[0].evaporate()
	Fx.float_text(pools[0].global_position + Vector2(0, -20), "L'acqua evapora", Color(0.75, 0.85, 1.0))


func _clamp_arena(p: Vector2) -> Vector2:
	if arena.size == Vector2.ZERO:
		return p
	return Vector2(clampf(p.x, arena.position.x + 20.0, arena.end.x - 20.0), clampf(p.y, arena.position.y + 20.0, arena.end.y - 20.0))


func _bite() -> void:
	Sfx.play("bite")
	Fx.shake(5.0)
	Fx.burst(global_position + Vector2(0, -12) + aim * 28.0, Color(0.95, 0.9, 0.8), 12, 110.0)
	var player = get_tree().get_first_node_in_group("player")
	if player == null or player.dead:
		return
	var to: Vector2 = player.global_position - global_position
	if to.length() <= bite_reach + 6.0 and absf(aim.angle_to(to)) <= deg_to_rad(bite_arc) * 0.5:
		player.take_damage(bite_damage, global_position, self)


func _land() -> void:
	Fx.shake(9.0)
	Sfx.play("charge", 0.1)
	Fx.burst(global_position, Color(1, 0.5, 0.15), 26, 160.0)
	var player = get_tree().get_first_node_in_group("player")
	if player != null and not player.dead and player.global_position.distance_to(global_position) < leap_radius + 6.0:
		player.take_damage(leap_damage, global_position, self)
	# anello di fuoco attorno al punto d'atterraggio
	var n := 6 + 2 * phase
	for i in range(n):
		var p := global_position + Vector2.from_angle(TAU * i / n) * 52.0
		_fire(p, 3.0)


func _breathe(delta: float, to: Vector2) -> void:
	breath_tick -= delta
	breath_spawn -= delta
	if breath_spawn <= 0.0:
		breath_spawn = 0.14
		var a := aim.angle() + deg_to_rad(randf_range(-breath_arc, breath_arc) * 0.5)
		_fire(global_position + Vector2.from_angle(a) * randf_range(36.0, breath_range), 3.5)
	if breath_tick <= 0.0 and to != Vector2.ZERO:
		breath_tick = 0.3
		if to.length() < breath_range and absf(aim.angle_to(to)) < deg_to_rad(breath_arc) * 0.5:
			var player = get_tree().get_first_node_in_group("player")
			if player != null:
				player.take_damage(breath_damage, global_position, self)


func _fire(p: Vector2, life: float) -> void:
	p = _clamp_arena(p)
	if Hazards.in_water(get_tree(), p):
		return
	var f := Hazards.FirePatch.new()
	f.life = life
	get_parent().add_child(f)
	f.global_position = p


func _howl() -> void:
	since_flood = 0
	state = "howl"
	var warn := flood_warn - 0.15 * phase
	st = warn + 0.25
	Sfx.play("roar", 0.0)
	Fx.shake(5.0)
	var flood := Hazards.FireFlood.new()
	flood.area = arena
	flood.origin = global_position
	flood.warn = warn
	flood.damage = flood_damage
	get_parent().add_child(flood)
	flood.setup()
	# l'acqua va disegnata sopra la marea, così si vede dove ripararsi
	for w in get_tree().get_nodes_in_group("water"):
		w.get_parent().move_child(w, -1)


func _damage_mult() -> float:
	return 1.5 if state == "exhausted" else 1.0


func _stagger_time() -> float:
	return 0.0


func _on_hit(_dmg: float) -> void:
	knock *= 0.08


func _contact_damage() -> float:
	return contact_damage * (0.0 if state == "leap" else 1.0)


func _draw_body(flash: bool) -> void:
	var dir := -1.0 if aim.x < 0.0 else 1.0
	var fur := Color.WHITE if flash else Color(0.13, 0.11, 0.13)
	var ember := Color(1.0, 0.45, 0.1)
	var tt := Time.get_ticks_msec() / 1000.0

	# avvisi a terra (disegnati prima del corpo)
	if state == "bite":
		var k := 1.0 - st / bite_windup
		var pts := PackedVector2Array([Vector2.ZERO])
		var half := deg_to_rad(bite_arc) * 0.5
		for i in range(13):
			pts.append(Vector2.from_angle(aim.angle() - half + half * 2.0 * i / 12.0) * bite_reach)
		draw_colored_polygon(pts, Color(1, 0.2, 0.15, 0.12 + 0.3 * k))
	if state == "leap_windup":
		var k := 1.0 - st / leap_windup
		var c := leap_to - global_position
		draw_circle(c, leap_radius, Color(1, 0.2, 0.1, 0.1 + 0.2 * k))
		draw_arc(c, leap_radius * (1.0 - 0.5 * k) + 4.0, 0.0, TAU, 28, Color(1, 0.35, 0.15, 0.4 + 0.4 * k), 2.0)
		draw_arc(c, leap_radius + 18.0 + 34.0, 0.0, TAU, 40, Color(1, 0.55, 0.2, 0.15 + 0.2 * k), 1.0)
	if state == "breath_windup" or state == "breath":
		var k := 1.0 if state == "breath" else 1.0 - st / breath_windup
		var pts := PackedVector2Array([Vector2(0, -10)])
		var half := deg_to_rad(breath_arc) * 0.5
		for i in range(11):
			pts.append(Vector2(0, -10) + Vector2.from_angle(aim.angle() - half + half * 2.0 * i / 10.0) * breath_range)
		draw_colored_polygon(pts, Color(1, 0.5, 0.1, 0.14 + 0.2 * k))
		pts.append(pts[0])
		draw_polyline(pts, Color(1, 0.7, 0.3, 0.35 + 0.4 * k), 1.5)

	# durante il balzo il corpo sale in aria e l'ombra resta a terra
	var lift := 0.0
	if state == "leap":
		var kk := clampf(1.0 - st / leap_time, 0.0, 1.0)
		lift = sin(kk * PI) * 34.0
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 18.0 - lift * 0.15, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if phase > 0:
		draw_circle(Vector2(0, -14 - lift), radius + 9.0, Color(1, 0.3, 0.1, 0.08 * phase))

	var shake_x := randf_range(-1.0, 1.0) if state in ["howl", "breath_windup"] else 0.0
	var head_up := -6.0 if state == "howl" else 0.0
	draw_set_transform(Vector2(shake_x, -lift), 0.0, Vector2(dir, 1.0))
	# zampe
	var step := sin(t * 10.0) * 2.0 if state == "chase" else 0.0
	for lx in [-15.0, -9.0, 5.0, 11.0]:
		var off := step if int(lx) % 2 == 0 else -step
		draw_line(Vector2(lx, -10), Vector2(lx + off, 0), fur, 3.0)
	# corpo snello da cane, con le crepe di brace
	draw_set_transform(Vector2(shake_x, -lift - 15.0), 0.0, Vector2(dir, 0.55))
	draw_circle(Vector2(-3, 0), 16.0, fur)
	draw_set_transform(Vector2(shake_x, -lift), 0.0, Vector2(dir, 1.0))
	for i in range(3):
		var cx := -12.0 + i * 7.0
		draw_line(Vector2(cx, -18), Vector2(cx + 3, -12), Color(ember, 0.7 + 0.3 * sin(tt * 5.0 + i)), 1.0)
	# criniera di fiamme lungo la schiena
	for i in range(6):
		var bx := -16.0 + i * 5.0
		var h := 7.0 + 4.0 * sin(tt * 12.0 + i * 1.3)
		draw_colored_polygon(PackedVector2Array([Vector2(bx - 3, -22), Vector2(bx + 3, -22), Vector2(bx + sin(tt * 8.0 + i) * 2.0, -22 - h)]), Color(1, 0.5, 0.1, 0.9))
		draw_colored_polygon(PackedVector2Array([Vector2(bx - 1.5, -22), Vector2(bx + 1.5, -22), Vector2(bx, -22 - h * 0.55)]), Color(1, 0.88, 0.4))
	# coda di fuoco
	draw_line(Vector2(-18, -16), Vector2(-26, -24 + sin(tt * 6.0) * 2.0), fur, 3.0)
	draw_circle(Vector2(-27, -25 + sin(tt * 6.0) * 2.0), 3.0, Color(1, 0.55, 0.1))
	# collo e testa di cane: muso lungo, orecchie dritte
	var hy := -24.0 + head_up
	draw_line(Vector2(8, -18), Vector2(13, hy + 2), fur, 6.0)
	draw_circle(Vector2(14, hy), 6.0, fur)
	var open := 3.0 if state in ["bite", "breath", "howl"] else 0.0
	draw_colored_polygon(PackedVector2Array([Vector2(17, hy - 3), Vector2(30, hy - 1 - open * 0.3), Vector2(30, hy + 1), Vector2(17, hy + 1)]), fur)
	draw_colored_polygon(PackedVector2Array([Vector2(17, hy + 2), Vector2(28, hy + 2 + open), Vector2(27, hy + 4 + open), Vector2(16, hy + 4)]), fur.darkened(0.2))
	if open > 0.0:
		draw_rect(Rect2(18, hy + 1, 9, open + 1), Color(1, 0.5, 0.1, 0.9))
	draw_colored_polygon(PackedVector2Array([Vector2(10, hy - 4), Vector2(13, hy - 15), Vector2(15, hy - 4)]), fur)
	draw_colored_polygon(PackedVector2Array([Vector2(14, hy - 4), Vector2(17, hy - 14), Vector2(19, hy - 3)]), fur)
	draw_circle(Vector2(17, hy - 2), 1.6, Color(1, 0.3, 0.1))
	if state == "breath":
		for i in range(3):
			draw_circle(Vector2(31 + i * 4, hy + 1 + randf_range(-1, 1)), 2.5 - i * 0.5, Color(1, 0.75, 0.3, 0.9))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if state == "exhausted":
		for i in range(3):
			var a := tt * 3.0 + i * TAU / 3.0
			draw_circle(Vector2(cos(a) * 12.0, -44 + sin(a) * 3.0), 2.0, Color(0.75, 0.75, 0.75, 0.8))
