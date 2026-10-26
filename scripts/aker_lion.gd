extends Enemy
## Ieri e Domani: i due leoni di Aker, separati a metà dello scontro (aker.gd).
## - Ieri (ovest, la sabbia, il tramonto): lento e pesante. Carica in linea lasciando una scia di
##   sabbie mobili; onda di sabbia a cono che ti spinge via.
## - Domani (est, il fuoco, l'alba): agile. Balzo con il cerchio rosso dove atterra; raggio dell'alba.
## REGOLA: non fanno mai una mossa grande nello stesso momento. Mentre uno attacca, l'altro ti gira
## intorno e a volte ruggisce (cadono pietre). Due boss insieme, sul telefono, sarebbero caos.
## Quando uno cade, l'altro ruggisce e PRENDE la mossa forte del compagno: Ieri il raggio dell'alba,
## Domani la carica di sabbia. È più veloce.
## Peso del Cuore "L'ira di Aker": se non finisci il secondo entro 8 secondi, il compagno caduto
## rinasce dalla sua sabbia o dal suo fuoco con metà della vita. Ieri e Domani non muoiono da soli.

@warning_ignore("unused_signal")
signal summon(kinds: Array)        # rinforzi: il gioco lo collega a ogni boss
signal split(lions: Array)         ## l'ira di Aker: il compagno che rinasce (game.gd lo aggiunge)

const LionScene := preload("res://scenes/aker_lion.tscn")
const S := 1.6
const SAND := Color(0.78, 0.62, 0.38)
const REVIVE_TIME := 8.0

@export var kind := "ieri"           ## "ieri" (sabbia) o "domani" (fuoco)

var partner: Enemy = null
var partner_pos := Vector2.ZERO
var floor_rect := Rect2(32, 64, 736, 384)
var state := "intro"
var st := 0.9
var aim := Vector2.RIGHT
var sx := 1.0                        # verso dove guarda (disegno)
var alone := false                   # il compagno è caduto: ha preso la sua mossa
var ira := false
var revive_t := -1.0
var revive_pos := Vector2.ZERO
var roar_cd := 4.0
var circle_dir := 1.0
var hit_once := false
var leap_from := Vector2.ZERO
var leap_to := Vector2.ZERO
var trail_last := Vector2.ZERO
var ray: Node2D = null

@export var charge_windup := 0.75
@export var charge_time := 0.55
@export var charge_speed := 470.0
@export var charge_damage := 16.0
@export var wave_windup := 0.6
@export var wave_time := 0.6
@export var wave_range := 150.0
@export var wave_damage := 8.0
@export var pounce_windup := 0.6
@export var pounce_time := 0.4
@export var pounce_radius := 30.0
@export var pounce_damage := 15.0


func _ready() -> void:
	is_boss = true
	speed = 44.0 if kind == "ieri" else 72.0
	ira = Weights.rank("ira_aker") > 0
	circle_dir = 1.0 if kind == "ieri" else -1.0
	super._ready()


func busy() -> bool:
	return state in ["charge_windup", "charge", "wave_windup", "wave", "pounce_windup", "pounce", "ray"]


func _fast() -> float:
	return 0.85 if alone else 1.0         # da solo, gli avvisi sono un po' più corti


func _partner_alive() -> bool:
	return partner != null and is_instance_valid(partner) and not partner.dead


func head_pos() -> Vector2:
	return global_position + Vector2(sx * 26.0, -31.0)


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta
	roar_cd -= delta
	if _partner_alive():
		partner_pos = partner.global_position
	elif not alone:
		_partner_fell()
	if revive_t > 0.0:
		revive_t -= delta
		if revive_t <= 0.0:
			_revive_partner()
	if to != Vector2.ZERO and not busy():
		sx = -1.0 if to.x < 0.0 else 1.0
	var d := to.length() if to != Vector2.ZERO else 999.0
	match state:
		"intro":
			# Ieri esce verso ovest, Domani verso est: l'arena ti dice chi è chi
			if st <= 0.0:
				_next(0.4)
			return Vector2(-1.0 if kind == "ieri" else 1.0, 0.0) * speed * 2.0
		"prowl":
			if st <= 0.0:
				_choose(to, d)
				return Vector2.ZERO
			if to == Vector2.ZERO:
				return Vector2.ZERO
			# ti gira intorno alla sua distanza: Ieri più vicino, Domani più largo
			var want := 110.0 if kind == "ieri" else 150.0
			var u := to / d
			var radial := u * clampf((d - want) / 40.0, -1.0, 1.0)
			return _steer((radial + u.orthogonal() * circle_dir * 0.8).normalized() * speed, delta)
		"roar":
			if st <= 0.0:
				_drop_stones(3)
				_next(0.6)
			return Vector2.ZERO
		"charge_windup":
			if st > charge_windup * _fast() * 0.4 and to != Vector2.ZERO:
				aim = to / d
				sx = -1.0 if aim.x < 0.0 else 1.0
			if st <= 0.0:
				state = "charge"
				st = charge_time
				hit_once = false
				trail_last = global_position
				Sfx.play_at("charge", global_position, 0.05)
			return Vector2.ZERO
		"charge":
			_charge_hit()
			if global_position.distance_to(trail_last) > 38.0:
				trail_last = global_position
				var q := Hazards.Quicksand.new()
				q.radii = Vector2(22, 12)
				q.life = 3.5
				q.position = global_position
				get_parent().add_child(q)
			if st <= 0.0:
				state = "recover"
				st = 0.9
				return Vector2.ZERO
			return aim * charge_speed
		"wave_windup":
			if st > wave_windup * _fast() * 0.5 and to != Vector2.ZERO:
				aim = to / d
				sx = -1.0 if aim.x < 0.0 else 1.0
			if st <= 0.0:
				state = "wave"
				st = wave_time
				hit_once = false
				Sfx.play_at("fire_whoosh", global_position, 0.2)
				var q := Hazards.Quicksand.new()
				q.radii = Vector2(26, 15)
				q.life = 4.0
				q.position = head_pos() + aim * wave_range * 0.6 + Vector2(0, 28)
				get_parent().add_child(q)
			return Vector2.ZERO
		"wave":
			_wave(delta)
			if st <= 0.0:
				state = "recover"
				st = 0.7
			return Vector2.ZERO
		"pounce_windup":
			if st <= 0.0:
				state = "pounce"
				st = pounce_time
				leap_from = global_position
				Sfx.play_at("amheh_growl", global_position, 0.1)
			return Vector2.ZERO
		"pounce":
			if st <= 0.0:
				_land()
				state = "recover"
				st = 0.7
				return Vector2.ZERO
			return (leap_to - leap_from) / pounce_time
		"ray":
			if st <= 0.0:
				state = "recover"
				st = 0.6
			return Vector2.ZERO
		"recover":
			if st <= 0.0:
				_next(0.5 + randf() * 0.5)
			return Vector2.ZERO
	return Vector2.ZERO


func _next(time: float) -> void:
	state = "prowl"
	st = time


func _choose(to: Vector2, d: float) -> void:
	# a turno: se il compagno sta attaccando, questo gira intorno (e a volte ruggisce)
	if _partner_alive() and partner.call("busy"):
		if roar_cd <= 0.0 and partner.get("state") != "roar":
			state = "roar"
			st = 0.8
			roar_cd = randf_range(7.0, 9.0)
			Sfx.play_at("roar", global_position, 0.1)
			Fx.shake(4.0)
			return
		_next(0.5)
		return
	if to == Vector2.ZERO:
		_next(0.5)
		return
	var r := randf()
	if kind == "ieri":
		if alone and r < 0.3:
			_ray(to)
		elif d < wave_range + 20.0 and r < 0.6:
			state = "wave_windup"
			st = wave_windup * _fast()
			aim = to / d
			Sfx.play_at("amheh_growl", global_position, 0.1)
		else:
			state = "charge_windup"
			st = charge_windup * _fast()
			aim = to / d
			Sfx.play_at("amheh_growl", global_position, 0.1)
		return
	# Domani
	if alone and r < 0.3:
		state = "charge_windup"
		st = charge_windup * _fast()
		aim = to / d
	elif d < 220.0 and r < 0.6:
		state = "pounce_windup"
		st = pounce_windup * _fast()
		leap_to = global_position + to
		leap_to.x = clampf(leap_to.x, floor_rect.position.x + 20.0, floor_rect.end.x - 20.0)
		leap_to.y = clampf(leap_to.y, floor_rect.position.y + 20.0, floor_rect.end.y - 10.0)
	else:
		_ray(to)


func _ray(to: Vector2) -> void:
	state = "ray"
	var r := Hazards.DawnRay.new()
	var o := head_pos()
	var sw := deg_to_rad(90.0) * (1.0 if randf() < 0.5 else -1.0)
	r.angle = (global_position + to + Vector2(0, -6) - o).angle() - sw * 0.5
	r.sweep = sw
	r.warn = 0.7 * _fast()
	r.src = self
	r.position = o
	get_parent().add_child(r)
	ray = r
	st = r.warn + r.dur + 0.1


## Distanza di un punto dalla linea della carica (per i bot delle prove).
func _charge_line_dist(p: Vector2) -> float:
	var a := global_position
	var ab := aim * charge_speed * charge_time
	var k := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.01), 0.0, 1.0)
	return p.distance_to(a + ab * k)


func _charge_hit() -> void:
	if hit_once:
		return
	var p = get_tree().get_first_node_in_group("player")
	if p != null and not p.dead and p.global_position.distance_to(global_position) < 24.0:
		if p.take_damage(charge_damage, global_position, self):
			hit_once = true


func _wave(delta: float) -> void:
	var p = get_tree().get_first_node_in_group("player")
	if p == null or p.dead or p.dash_t > 0.0:
		return
	var o := head_pos()
	var rel: Vector2 = p.global_position + Vector2(0, -6) - o
	if rel.length() < wave_range and absf(aim.angle_to(rel)) < deg_to_rad(30.0):
		p.move_and_collide(rel.normalized() * 180.0 * delta)
		if not hit_once and p.take_damage(wave_damage, o, self):
			hit_once = true


func _land() -> void:
	Fx.shake(5.0)
	Fx.burst(global_position, Color(1.0, 0.6, 0.2), 24, 140.0)
	Sfx.play_at("amheh_land", global_position, 0.05)
	var p = get_tree().get_first_node_in_group("player")
	if p != null and not p.dead:
		var dd: Vector2 = p.global_position - global_position
		if Vector2(dd.x, dd.y / 0.6).length() < pounce_radius + 4.0:
			p.take_damage(pounce_damage, global_position, self)


func _drop_stones(n: int) -> void:
	var p = get_tree().get_first_node_in_group("player")
	var spots: Array[Vector2] = []
	if p != null and not p.dead:
		spots.append(p.global_position + Vector2(randf_range(-10, 10), randf_range(-6, 6)))
	var area := floor_rect.grow(-30.0)
	var tries := 0
	while spots.size() < n and tries < 60:
		tries += 1
		var c := Vector2(randf_range(area.position.x, area.end.x), randf_range(area.position.y, area.end.y))
		var ok := c.distance_to(global_position) > 50.0
		for o in spots:
			if o.distance_to(c) < 40.0:
				ok = false
		if ok:
			spots.append(c)
	for i in range(spots.size()):
		var stone := Hazards.FallingStone.new()
		stone.position = spots[i]
		stone.warn = 0.9 + i * 0.1
		get_parent().add_child(stone)


## Il compagno è caduto: ruggisce e prende la sua mossa forte. Con l'ira di Aker parte il conto
## alla rovescia: se non lo finisci in tempo, il compagno rinasce.
func _partner_fell() -> void:
	alone = true
	speed *= 1.2
	Fx.shake(7.0)
	Sfx.play_at("roar", global_position, 0.0)
	var txt := Lang.t("IERI PRENDE IL FUOCO DI DOMANI") if kind == "ieri" else Lang.t("DOMANI PRENDE LA SABBIA DI IERI")
	Fx.float_text(global_position + Vector2(0, -50), txt, Color(1, 0.85, 0.5))
	if ira:
		revive_t = REVIVE_TIME
		revive_pos = partner_pos
		Fx.float_text(revive_pos + Vector2(0, -30), Lang.t("RINASCERÀ"), Color(1, 0.5, 0.3))


func _revive_partner() -> void:
	revive_t = -1.0
	var other: Enemy = LionScene.instantiate()
	other.set("kind", "domani" if kind == "ieri" else "ieri")
	other.position = revive_pos
	other.set("partner", self)
	other.set("floor_rect", floor_rect)
	other.max_hp = 175.0
	partner = other
	alone = false
	speed /= 1.2
	Fx.shake(8.0)
	Fx.burst(revive_pos, Color(1.0, 0.7, 0.3) if kind == "ieri" else SAND, 40, 160.0)
	Sfx.play_at("roar", revive_pos, 0.0)
	split.emit([other])


func _stagger_time() -> float:
	return 0.0


func _on_hit(_dmg: float) -> void:
	knock *= 0.15


# ---------------------------------------------------------------- disegno

func _draw() -> void:
	_draw_warnings()
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 30.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_body(flash_t > 0.0)


func _draw_body(flash: bool) -> void:
	var pal: Dictionary = AkerArt.IERI if kind == "ieri" else AkerArt.DOMANI
	var pose := "stand"
	if state == "pounce":
		pose = "leap"
	elif velocity.length() > 8.0:
		pose = "walk"
	var lift := Vector2.ZERO
	if state == "pounce":
		lift = Vector2(0, -sin((1.0 - st / pounce_time) * PI) * 26.0)
	var mouth := 0.0
	if state in ["charge_windup", "wave_windup", "pounce_windup"]:
		mouth = 1.0 - st / maxf(0.05, (charge_windup if state == "charge_windup" else (wave_windup if state == "wave_windup" else pounce_windup)) * _fast())
	elif state in ["roar", "wave", "ray"]:
		mouth = 1.0
	var glow := 0.0
	if kind == "domani" or alone:
		glow = 0.35 + (0.65 if state in ["ray", "pounce"] else 0.0)
	AkerArt.lion(self, lift + Vector2(-2, 0), sx, S, pal, pose, t, mouth, glow, flash)
	if alone and kind == "ieri":
		# Ieri ha preso il fuoco: braci che salgono dalla criniera
		for i in range(4):
			var k := fmod(t * 1.5 + i * 0.25, 1.0)
			draw_circle(lift + Vector2(sx * 12.0 + sin(i * 2.0) * 6.0, -30.0 - k * 20.0), 1.6 * (1.0 - k), Color(1, 0.6, 0.2, 1.0 - k))


func _draw_warnings() -> void:
	if state == "charge_windup":
		var k := 1.0 - st / (charge_windup * _fast())
		var ln := charge_speed * charge_time
		var side := aim.orthogonal() * 14.0
		draw_colored_polygon(PackedVector2Array([side, aim * ln + side, aim * ln - side, -side]), Color(1, 0.2, 0.15, 0.1 + 0.2 * k))
		draw_line(Vector2.ZERO, aim * ln, Color(1, 0.25, 0.15, 0.5 + 0.4 * k), 2.0)
	elif state == "wave_windup" or state == "wave":
		var o := head_pos() - global_position
		var half := deg_to_rad(30.0)
		var k := 1.0 if state == "wave" else 1.0 - st / (wave_windup * _fast())
		var pts := PackedVector2Array([o])
		for i in range(11):
			pts.append(o + aim.rotated(-half + half * 2.0 * i / 10.0) * wave_range)
		draw_colored_polygon(pts, Color(0.95, 0.75, 0.4, 0.12 + 0.25 * k))
		draw_polyline(pts.slice(1), Color(1, 0.35, 0.15, 0.5 + 0.4 * k), 2.0)
	elif state == "pounce_windup" or state == "pounce":
		var c := leap_to - global_position
		var k := 1.0 if state == "pounce" else 1.0 - st / (pounce_windup * _fast())
		draw_set_transform(c, 0.0, Vector2(1.0, 0.6))
		draw_arc(Vector2.ZERO, pounce_radius, 0.0, TAU, 32, Color(1, 0.3, 0.15, 0.6 + 0.3 * k), 2.0)
		draw_circle(Vector2.ZERO, pounce_radius * k, Color(1, 0.35, 0.15, 0.2))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if revive_t > 0.0:
		# dove è caduto il compagno: il mucchio di sabbia (o di braci) e l'anello che si chiude
		var c := revive_pos - global_position
		var k := revive_t / REVIVE_TIME
		var col := Color(1.0, 0.55, 0.2) if kind == "ieri" else Color(0.85, 0.7, 0.45)
		draw_set_transform(c, 0.0, Vector2(1.0, 0.6))
		draw_circle(Vector2.ZERO, 12.0, Color(col, 0.5))
		draw_arc(Vector2.ZERO, 26.0, -PI * 0.5, -PI * 0.5 + TAU * k, 40, col, 3.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
