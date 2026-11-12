extends Enemy
## Shezmu, il Signore del Torchio: il dio-demone che spreme le teste dei dannati come grappoli e ne
## porta il vino rosso a chi ha superato il giudizio. Guardiano del Banco di Apopi (stanza 5).
##
## Mosse (ogni mossa ha il suo avviso rosso con le misure vere):
## - MANNAIA: lancia la mannaia in linea; va fino in fondo e TORNA (ferisce andando e tornando).
##   Finché non l'ha ripresa non può caricare né lanciare.
## - TORCHIO: alza le braccia, tre ombre rotonde a terra (una su di te), poi le pietre del torchio
##   cadono. Infuriato: cinque, una dopo l'altra, che ti seguono.
## - VINO: un colpo a ventaglio davanti a sé che lascia pozze di Isfet rosso scuro.
## - CARICA: abbassa la testa (striscia larga) e travolge. Se finisce contro il muro resta stordito.
## Sotto metà vita si infuria: più rapido, due mannaie a V, cinque pietre.

@warning_ignore("unused_signal")
signal summon(kinds: Array)        # il gioco lo collega a ogni guardiano; Shezmu non chiama nessuno

const CLEAVER_WARN := 0.55
const CLEAVER_DIST := 250.0
const CLEAVER_SPEED := 330.0
const CLEAVER_HALF := 10.0
const CLEAVER_DMG := 11.0
const PRESS_WARN := 0.9
const PRESS_R := 32.0
const PRESS_DMG := 15.0
const WINE_WARN := 0.6
const WINE_RANGE := 104.0
const WINE_CONE := 55.0            ## mezza apertura in gradi
const WINE_DMG := 10.0
const CHARGE_WARN := 0.65
const CHARGE_SPEED := 370.0
const CHARGE_TIME := 0.62
const CHARGE_HALF := 18.0
const CHARGE_DMG := 14.0
const PUNISH := 1.0

var state := "intro"
var st := 1.4
var aim := Vector2.DOWN
var enraged := false
var cleavers: Array = []           ## mannaie in volo
var press_spots: Array = []        ## [posizione, secondi all'impatto]
var charge_hit := false
var last_move := ""


func _ready() -> void:
	miniboss = true
	super._ready()


class Cleaver extends Node2D:
	var dir := Vector2.RIGHT
	var owner_ref: WeakRef
	var out := true
	var gone := 0.0
	var hit_out := false
	var hit_back := false
	var spin := 0.0

	func _process(delta: float) -> void:
		spin += delta * 20.0
		var boss = owner_ref.get_ref()
		if boss == null or boss.dead:
			queue_free()
			return
		var p = get_tree().get_first_node_in_group("player")
		if out:
			var step: float = CLEAVER_SPEED * delta
			position += dir * step
			gone += step
			var g = get_tree().current_scene
			var wall: bool = g != null and g.has_method("_in_floor") and not g._in_floor(global_position, 8.0)
			if gone >= CLEAVER_DIST or wall:
				out = false
				Sfx.play_at("hit", global_position, 0.3)
			if not hit_out and p != null and not p.dead and p.global_position.distance_to(global_position) < CLEAVER_HALF + Enemy.PLAYER_R:
				hit_out = p.take_damage(CLEAVER_DMG, global_position, boss)
		else:
			var back: Vector2 = boss.global_position + Vector2(0, -10) - global_position
			if back.length() < 14.0:
				queue_free()
				return
			position += back.normalized() * CLEAVER_SPEED * 1.15 * delta
			if not hit_back and p != null and not p.dead and p.global_position.distance_to(global_position) < CLEAVER_HALF + Enemy.PLAYER_R:
				hit_back = p.take_damage(CLEAVER_DMG, global_position, boss)
		queue_redraw()

	func _draw() -> void:
		if Run.show_zones():
			draw_arc(Vector2.ZERO, CLEAVER_HALF, 0.0, TAU, 14, Color(1.0, 0.3, 0.2, 0.9), 1.0)
		draw_circle(Vector2(0, 8), 7.0, Color(0, 0, 0, 0.3))
		var k := Vector2.from_angle(spin)
		var o := k.orthogonal()
		draw_line(-k * 9.0, k * 2.0, Color(0.12, 0.08, 0.05), 3.4)
		draw_line(-k * 9.0, k * 2.0, Color(0.5, 0.33, 0.18), 2.0)
		var blade := PackedVector2Array([k * 1.0 - o * 1.5, k * 11.0 - o * 2.0, k * 11.0 + o * 7.0, k * 1.0 + o * 5.0])
		draw_colored_polygon(blade, Color(0.75, 0.72, 0.7))
		blade.append(blade[0])
		draw_polyline(blade, Color(0.12, 0.08, 0.05), 1.0)
		draw_line(k * 2.0 + o * 5.5, k * 11.0 + o * 7.0, Color(0.7, 0.1, 0.12), 1.6)
		draw_arc(Vector2.ZERO, 12.0, spin, spin + 2.0, 8, Color(1, 1, 1, 0.3), 1.2)


func _rage() -> float:
	return 1.25 if enraged else 1.0


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta
	cleavers = cleavers.filter(func(c) -> bool: return is_instance_valid(c))
	_update_press(delta)
	if not enraged and hp < max_hp * 0.5:
		enraged = true
		Fx.shake(7.0)
		Sfx.play_at("roar", global_position, 0.1)
		Fx.float_text(global_position + Vector2(0, -44), Lang.t("IL TORCHIO GIRA"), Color(0.9, 0.2, 0.2))
	if to == Vector2.ZERO:
		return Vector2.ZERO
	var d := to.length()
	var u := to / d
	match state:
		"intro":
			if st <= 0.0:
				_next(0.6)
			return Vector2.ZERO
		"chase":
			aim = u
			if st <= 0.0:
				_choose(d)
				return Vector2.ZERO
			return _steer(u * speed * _rage(), delta) if d > 46.0 else Vector2.ZERO
		"cleaver_warn":
			if st > CLEAVER_WARN * 0.4:
				aim = u
			if st <= 0.0:
				_throw()
				state = "recover"
				st = 0.7
			return Vector2.ZERO
		"press_warn":
			if st <= 0.0:
				state = "recover"
				st = PUNISH
			return Vector2.ZERO
		"wine_warn":
			if st > WINE_WARN * 0.5:
				aim = u
			if st <= 0.0:
				_wine()
				state = "recover"
				st = 0.8
			return Vector2.ZERO
		"charge_warn":
			if st > CHARGE_WARN * 0.5:
				aim = u
			if st <= 0.0:
				state = "charge"
				st = CHARGE_TIME
				charge_hit = false
				Sfx.play_at("dash", global_position, 0.2)
			return -aim * 14.0
		"charge":
			var p = get_tree().get_first_node_in_group("player")
			if not charge_hit and p != null and touches(p, CHARGE_HALF - PLAYER_R - TOUCH_PAD):
				charge_hit = p.take_damage(CHARGE_DMG, global_position, self)
			for i in range(get_slide_collision_count()):
				var col := get_slide_collision(i)
				if col.get_collider() is StaticBody2D and aim.dot(col.get_normal()) < -0.6:
					Fx.shake(6.0)
					Sfx.play_at("amheh_land", global_position, 0.2)
					Fx.float_text(global_position + Vector2(0, -40), Lang.t("STORDITO"), Color(1, 0.9, 0.5))
					state = "recover"
					st = PUNISH + 0.9
					return Vector2.ZERO
			if st <= 0.0:
				state = "recover"
				st = PUNISH
			return aim * CHARGE_SPEED
		"recover":
			if st <= 0.0:
				_next(randf_range(0.7, 1.2) / _rage())
			return Vector2.ZERO
	return Vector2.ZERO


func _next(time: float) -> void:
	state = "chase"
	st = time


func _choose(d: float) -> void:
	var opts := []
	if cleavers.is_empty():
		opts.append("cleaver")
		if d > 70.0:
			opts.append("charge")
	opts.append("press")
	if d < WINE_RANGE * 0.9:
		opts.append("wine")
		opts.append("wine")
	opts.erase(last_move)
	if opts.is_empty():
		opts = ["press"]
	var m: String = opts.pick_random()
	last_move = m
	match m:
		"cleaver":
			state = "cleaver_warn"
			st = CLEAVER_WARN
			Sfx.play_at("mummy_windup", global_position, 0.2)
		"press":
			state = "press_warn"
			st = PRESS_WARN + (0.9 if enraged else 0.0)
			_start_press()
		"wine":
			state = "wine_warn"
			st = WINE_WARN
			Sfx.play_at("amheh_growl", global_position, 0.2)
		"charge":
			state = "charge_warn"
			st = CHARGE_WARN
			Sfx.play_at("amheh_growl", global_position, 0.1)


func _cleaver_dirs() -> Array:
	return [aim.rotated(deg_to_rad(-16.0)), aim.rotated(deg_to_rad(16.0))] if enraged else [aim]


func _throw() -> void:
	Sfx.play_at("swing", global_position, 0.1)
	for dr in _cleaver_dirs():
		var c := Cleaver.new()
		c.dir = dr
		c.owner_ref = weakref(self)
		get_parent().add_child(c)
		c.global_position = global_position + Vector2(0, -10) + Vector2(dr) * 14.0
		cleavers.append(c)


func _start_press() -> void:
	Sfx.play_at("scorpion_windup", global_position, 0.1)
	press_spots.clear()
	var p = get_tree().get_first_node_in_group("player")
	if p == null:
		return
	var g = get_tree().current_scene
	var n := 5 if enraged else 3
	for i in range(n):
		var at: Vector2 = p.global_position
		if i > 0 and not enraged:
			at += Vector2.from_angle(randf() * TAU) * randf_range(46.0, 84.0)
		if g != null and g.has_method("_in_floor") and not g._in_floor(at, 8.0):
			at = p.global_position
		# infuriato: le pietre cadono una dopo l'altra e la posizione si decide all'ultimo (ti seguono)
		press_spots.append([at, PRESS_WARN + (i * 0.22 if enraged else 0.0), enraged and i > 0])


func _update_press(delta: float) -> void:
	var p = get_tree().get_first_node_in_group("player")
	for sp in press_spots:
		var before: float = sp[1]
		sp[1] = before - delta
		if sp[2] and before > PRESS_WARN and float(sp[1]) <= PRESS_WARN and p != null:
			sp[0] = p.global_position        # la pietra in ritardo sceglie il punto quando parte il suo avviso
			sp[2] = false
		if before > 0.0 and float(sp[1]) <= 0.0:
			var at: Vector2 = sp[0]
			Fx.shake(5.0)
			Fx.burst(at, Color(0.5, 0.42, 0.4), 16, 120.0)
			Sfx.play_at("amheh_land", at, 0.2)
			if p != null and not p.dead and p.global_position.distance_to(at) < PRESS_R:
				p.take_damage(PRESS_DMG, at, self)
	press_spots = press_spots.filter(func(s) -> bool: return float(s[1]) > -0.35)


func _wine() -> void:
	Sfx.play_at("splash", global_position, 0.1)
	Fx.burst(global_position + aim * 40.0, Color(0.6, 0.08, 0.12), 26, 150.0)
	var p = get_tree().get_first_node_in_group("player")
	if p != null and not p.dead:
		var v: Vector2 = p.global_position - global_position
		if v.length() < WINE_RANGE and absf(rad_to_deg(aim.angle_to(v))) < WINE_CONE:
			p.take_damage(WINE_DMG, global_position, self)
	var g = get_tree().current_scene
	for i in range(3 if enraged else 2):
		var at := global_position + aim.rotated(deg_to_rad(randf_range(-WINE_CONE, WINE_CONE) * 0.8)) * randf_range(WINE_RANGE * 0.45, WINE_RANGE * 0.95)
		if g != null and g.has_method("_in_floor") and not g._in_floor(at, 12.0):
			continue
		var pool := Chaos.Isfet.new()
		pool.r = 17.0
		pool.life = 6.0
		get_parent().add_child(pool)
		pool.global_position = at


func take_hit(dmg: float, dir: Vector2, kb: float, can_burn: bool = false) -> void:
	super.take_hit(dmg, dir, kb * 0.15, can_burn)


func _stagger_time() -> float:
	return 0.0


func _contact_damage() -> float:
	return contact_damage if state == "chase" else 0.0


func die() -> void:
	for c in cleavers:
		if is_instance_valid(c):
			c.queue_free()
	super.die()


## Per il bot: da cosa scappare.
func bot_escape(pos: Vector2) -> Vector2:
	for sp in press_spots:
		var at: Vector2 = sp[0]
		if float(sp[1]) > 0.0 and float(sp[1]) <= PRESS_WARN and pos.distance_to(at) < PRESS_R + 10.0:
			return (pos - at).normalized() if pos != at else Vector2.RIGHT
	if state in ["cleaver_warn", "charge_warn", "charge"]:
		var v := pos - global_position
		if absf(v.dot(aim.orthogonal())) < 34.0 and v.dot(aim) > -10.0:
			return aim.orthogonal() * (1.0 if v.dot(aim.orthogonal()) >= 0.0 else -1.0)
	if state == "wine_warn":
		var v2 := pos - global_position
		if v2.length() < WINE_RANGE + 12.0:
			return v2.normalized()
	for c in cleavers:
		if is_instance_valid(c) and pos.distance_to(c.global_position) < 40.0:
			return (pos - c.global_position).normalized()
	return Vector2.ZERO


func _wine_fan(k: float) -> void:
	var pts := PackedVector2Array([Vector2.ZERO])
	for i in range(13):
		pts.append(aim.rotated(deg_to_rad(lerpf(-WINE_CONE, WINE_CONE, i / 12.0))) * WINE_RANGE)
	draw_colored_polygon(pts, Color(WARN, 0.12))
	var inner := PackedVector2Array([Vector2.ZERO])
	for i in range(13):
		inner.append(aim.rotated(deg_to_rad(lerpf(-WINE_CONE, WINE_CONE, i / 12.0))) * WINE_RANGE * clampf(k, 0.02, 1.0))
	draw_colored_polygon(inner, Color(WARN, 0.18 + 0.17 * k))
	pts.append(Vector2.ZERO)
	draw_polyline(pts, Color(WARN, 0.55 + 0.35 * k), 1.5)


func _zones() -> void:
	draw_arc(Vector2.ZERO, CHARGE_HALF, 0.0, TAU, 20, Color(1.0, 0.3, 0.2, 0.6), 1.0)


func _draw() -> void:
	# gli avvisi a terra, sotto il corpo
	for sp in press_spots:
		var left: float = sp[1]
		if left <= PRESS_WARN:
			var lp: Vector2 = to_local(sp[0])
			if left > 0.0:
				Enemy.warn_circle(self, lp, PRESS_R, 1.0 - left / PRESS_WARN)
				# la pietra che scende: un'ombra che si stringe
				draw_circle(lp, PRESS_R * (0.3 + 0.5 * (1.0 - left / PRESS_WARN)), Color(0, 0, 0, 0.35))
			else:
				draw_circle(lp, PRESS_R * 0.9, Color(0.42, 0.36, 0.34, clampf(1.0 + left / 0.35, 0.0, 1.0)))
				draw_arc(lp, PRESS_R * 0.9, 0.0, TAU, 24, Color(0.1, 0.07, 0.06, clampf(1.0 + left / 0.35, 0.0, 1.0)), 2.0)
	match state:
		"cleaver_warn":
			for dr in _cleaver_dirs():
				Enemy.warn_strip(self, Vector2(0, -6), dr, CLEAVER_DIST, CLEAVER_HALF, 1.0 - st / CLEAVER_WARN)
		"wine_warn":
			_wine_fan(1.0 - st / WINE_WARN)
		"charge_warn":
			Enemy.warn_strip(self, Vector2.ZERO, aim, CHARGE_SPEED * CHARGE_TIME + CHARGE_HALF, CHARGE_HALF, 1.0 - st / CHARGE_WARN)
	super._draw()


## Un colosso dalla pelle rosso vino con la testa di leone (criniera scura), grembiule da macellaio
## macchiato, braccia enormi. Tiene la mannaia nella destra (se non l'ha lanciata).
func _draw_body(flash: bool) -> void:
	var skin := _f(Color(0.52, 0.14, 0.16) if not enraged else Color(0.66, 0.12, 0.12), flash)
	var dark := _f(Color(0.2, 0.08, 0.1), flash)
	var apron := _f(Color(0.82, 0.76, 0.62), flash)
	var gold := _f(GOLD, flash)
	var dirx := 1.0 if aim.x >= 0.0 else -1.0
	var step := sin(t * 8.0) * 2.5 if velocity.length() > 12.0 else 0.0
	var lift := 0.0
	if state == "press_warn":
		lift = clampf(1.0 - st / PRESS_WARN, 0.0, 1.0)
	var lean := 0.0
	if state == "charge_warn" or state == "charge":
		lean = 4.0
	# gambe
	_limb(Vector2(-6, -10), Vector2(-7 - step, 0), skin, 4.0)
	_limb(Vector2(6, -10), Vector2(7 + step, 0), skin, 4.0)
	# torso largo
	var c := Vector2(dirx * lean, -22)
	_op(PackedVector2Array([c + Vector2(-13, -9), c + Vector2(13, -9), c + Vector2(10, 12), c + Vector2(-10, 12)]), skin, 1.0)
	# grembiule con le macchie
	_op(PackedVector2Array([c + Vector2(-8, -2), c + Vector2(8, -2), c + Vector2(9, 16), c + Vector2(-9, 16)]), apron)
	draw_circle(c + Vector2(-3, 6), 2.4, Color(0.55, 0.08, 0.1))
	draw_circle(c + Vector2(4, 11), 1.8, Color(0.55, 0.08, 0.1))
	draw_circle(c + Vector2(2, 2), 1.3, Color(0.55, 0.08, 0.1))
	draw_line(c + Vector2(-12, -8), c + Vector2(12, -8), gold, 2.0)
	# braccia
	var has_cleaver := cleavers.is_empty()
	for sx in [-1.0, 1.0]:
		var sh := c + Vector2(sx * 13.0, -6)
		var hand := sh + Vector2(sx * (7.0 - 3.0 * lift), 12.0 - 30.0 * lift)
		if state == "cleaver_warn" and sx == dirx:
			hand = sh + Vector2(-dirx * 4.0, -16.0)
		_limb(sh, hand, skin, 4.6)
		_dot(hand, 3.2, skin)
		if sx == dirx and has_cleaver:
			var k := Vector2(dirx * 0.5, -1.0).normalized()
			if state == "cleaver_warn":
				k = Vector2(-dirx * 0.6, -1.0).normalized()
			var o := k.orthogonal() * dirx
			draw_line(hand - k * 3.0, hand + k * 6.0, dark, 3.0)
			_op(PackedVector2Array([hand + k * 5.0 - o * 1.5, hand + k * 17.0 - o * 2.0, hand + k * 17.0 + o * 8.0, hand + k * 5.0 + o * 6.0]), _f(Color(0.78, 0.75, 0.72), flash))
			draw_line(hand + k * 6.0 + o * 6.3, hand + k * 17.0 + o * 8.0, Color(0.7, 0.1, 0.12), 1.6)
	# testa di leone
	var h := c + Vector2(dirx * 2.0, -15)
	_op(_ell(h, 9.5, 9.0, 14), dark, 1.0)                      # criniera
	_op(_ell(h + Vector2(dirx * 1.5, 1), 6.2, 6.0, 12), skin)
	_op(_ell(h + Vector2(dirx * 5.0, 3.5), 3.4, 2.6, 8), _f(Color(0.7, 0.3, 0.28), flash))
	draw_circle(h + Vector2(dirx * 7.0, 2.6), 1.0, Color(0.1, 0.05, 0.05))
	var eye := Color(1.0, 0.35, 0.15) if state.ends_with("_warn") or enraged else Color(1.0, 0.85, 0.3)
	draw_circle(h + Vector2(dirx * 3.2, -1.2), 1.5, eye)
	draw_circle(h + Vector2(dirx * -0.6, -1.2), 1.3, eye)
	for sx in [-1.0, 1.0]:
		_op(PackedVector2Array([h + Vector2(sx * 4.0, -6), h + Vector2(sx * 7.5, -11), h + Vector2(sx * 8.0, -5)]), dark)
	if state.ends_with("_warn") or state == "charge":
		for k2 in range(3):
			draw_line(h + Vector2(dirx * (3.0 + k2 * 1.6), 5.0), h + Vector2(dirx * (3.4 + k2 * 1.6), 6.8), Color(0.96, 0.94, 0.88), 0.8)
