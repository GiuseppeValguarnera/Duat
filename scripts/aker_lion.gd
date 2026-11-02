extends Enemy
## Ieri e Domani: i due leoni di Aker, separati quando finisce la fase 1 (aker.gd). Attaccano
## INSIEME (non più a turno) e ti danno la caccia.
## - Ieri (ovest, la sabbia, il tramonto): carica in linea con scia di sabbie mobili; onda di sabbia a
##   cono che ti spinge.
## - Domani (est, il fuoco, l'alba): balzo con l'ombra dove atterra; raggio dell'alba.
## - Tenaglia: i due si mettono ai lati opposti e caricano insieme attraverso di te: si esce di lato.
## Quando uno cade, l'altro si infuria: prende la mossa del compagno ed è il 25% più veloce e più
## forte fino alla fine. Peso del Cuore "L'ira di Aker": la furia vale il doppio (+50%) e i due
## cominciano già un po' infuriati (+10%).
## Tutti i numeri da tarare sono qui sotto.

@warning_ignore("unused_signal")
signal summon(kinds: Array)        # rinforzi: il gioco lo collega a ogni boss
@warning_ignore("unused_signal")
signal split(lions: Array)         # il gioco lo collega (Aker diviso); i leoni non si dividono più

# ---------------------------------------------------------------- numeri da tarare
const PROWL_SPEED := {"ieri": 72.0, "domani": 92.0}
const PROWL_DIST := {"ieri": 80.0, "domani": 130.0}
const RECOVER := 1.0                  ## la pausa dopo una mossa grande
const FURY := 0.25                    ## il sopravvissuto: +25% velocità e danni, avvisi più corti
const IRA_FURY := 0.5                 ## con il Peso del Cuore "L'ira di Aker"
const IRA_START := 0.1                ## con l'ira cominciano già infuriati del 10%
const CHARGE_WINDUP := 0.65
const CHARGE_TIME := 0.6
const CHARGE_SPEED := 430.0
const CHARGE_DAMAGE := 20.0
const WAVE_WINDUP := 0.55
const WAVE_TIME := 0.6
const WAVE_RANGE := 150.0
const WAVE_HALF := 30.0
const WAVE_DAMAGE := 12.0
const WAVE_PUSH := 200.0
const POUNCE_WINDUP := 0.55
const POUNCE_TIME := 0.45
const POUNCE_RADIUS := 34.0
const POUNCE_DAMAGE := 20.0
const RAY_WARN := 0.6
const RAY_TIME := 1.5
const RAY_SWEEP := 90.0
const RAY_DAMAGE := 10.0
const PINCER_COOLDOWN := 11.0         ## la tenaglia, ogni tanto
const PINCER_OFFSET := 170.0          ## quanto lontano da te si mettono prima di caricare
const PINCER_MOVE := 1.0              ## tempo massimo per mettersi in posizione
const PINCER_WINDUP := 0.7
const MIN_WINDUP := 0.45              ## anche infuriati, mai avvisi più corti di così
const CONTACT := 9.0
const S := 1.6
const SAND := Color(0.78, 0.62, 0.38)

@export var kind := "ieri"           ## "ieri" (sabbia) o "domani" (fuoco)

var partner = null                   # l'altro leone
var floor_rect := Rect2(32, 64, 736, 384)
var state := "intro"
var st := 0.9
var aim := Vector2.RIGHT
var sx := 1.0                        # verso dove guarda (disegno)
var alone := false                   # il compagno è caduto: ha preso la sua mossa
var fury := 0.0                      # quanto è infuriato (0 = normale)
var circle_dir := 1.0
var hit_once := false
var jump_from := Vector2.ZERO
var jump_to := Vector2.ZERO
var trail_last := Vector2.ZERO
var ray: Node2D = null
var pincer_cd := 6.0
var pincer_spot := Vector2.ZERO
var windup_len := 0.6
var paired := false                  # aveva un compagno (un oggetto liberato vale null: serve ricordarlo)


func _ready() -> void:
	is_boss = true
	speed = PROWL_SPEED.get(kind, 80.0)
	if Weights.rank("ira_aker") > 0:
		fury = IRA_START
	circle_dir = 1.0 if kind == "ieri" else -1.0
	paired = partner != null
	super._ready()


func busy() -> bool:
	return state not in ["prowl", "recover", "intro"]


func _partner_alive() -> bool:
	return partner != null and is_instance_valid(partner) and not partner.dead


func _player():
	var p = get_tree().get_first_node_in_group("player")
	return p if p != null and not p.dead else null


func _hurt(amount: float, from: Vector2) -> bool:
	var p = _player()
	return p != null and p.take_damage(amount * (1.0 + fury), from, self)


## L'avviso, accorciato dalla furia ma mai sotto MIN_WINDUP.
func _wu(base: float) -> float:
	windup_len = maxf(MIN_WINDUP, base / (1.0 + fury))
	return windup_len


func head_pos() -> Vector2:
	return global_position + Vector2(sx * 26.0, -31.0)


func _clamp_floor(p: Vector2) -> Vector2:
	var r := floor_rect.grow(-30.0)
	return Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta
	pincer_cd -= delta
	if not alone and paired and not _partner_alive():
		_partner_fell()
	if ray != null and is_instance_valid(ray):
		ray.global_position = head_pos()
	if to != Vector2.ZERO and not busy():
		sx = -1.0 if to.x < 0.0 else 1.0
	var d := to.length() if to != Vector2.ZERO else 999.0
	var spd := speed * (1.0 + fury)
	match state:
		"intro":
			# Ieri esce verso ovest, Domani verso est: l'arena ti dice chi è chi
			if st <= 0.0:
				_next(0.3)
			return Vector2(-1.0 if kind == "ieri" else 1.0, 0.0) * spd * 2.0
		"prowl":
			if st <= 0.0:
				_choose(to, d)
				return Vector2.ZERO
			if to == Vector2.ZERO:
				return Vector2.ZERO
			# ti dà la caccia: si avvicina alla sua distanza girandoti intorno
			var want: float = PROWL_DIST.get(kind, 100.0)
			var u := to / d
			var radial := u * clampf((d - want) / 30.0, -1.0, 1.0)
			return _steer((radial * 1.4 + u.orthogonal() * circle_dir * 0.6).normalized() * spd, delta)
		"recover":
			if st <= 0.0:
				_next(0.25 + randf() * 0.35)
			return Vector2.ZERO
		"pincer_move":
			var go := pincer_spot - global_position
			if go.length() < 10.0 or st <= 0.0:
				_begin_charge(to, PINCER_WINDUP)
				return Vector2.ZERO
			return go.normalized() * 230.0
		"charge_windup":
			if st > windup_len * 0.4 and to != Vector2.ZERO:
				aim = to / d
				sx = -1.0 if aim.x < 0.0 else 1.0
			if st <= 0.0:
				state = "charge"
				st = CHARGE_TIME
				hit_once = false
				trail_last = global_position
				Sfx.play_at("charge", global_position, 0.05)
			return Vector2.ZERO
		"charge":
			if not hit_once:
				var p = _player()
				if p != null and p.global_position.distance_to(global_position) < 26.0:
					hit_once = _hurt(CHARGE_DAMAGE, global_position)
			if kind == "ieri" or alone:
				if global_position.distance_to(trail_last) > 36.0:
					trail_last = global_position
					var q := Hazards.Quicksand.new()
					q.radii = Vector2(22, 12)
					q.life = 3.5
					q.position = global_position
					get_parent().add_child(q)
			if st <= 0.0:
				_recover()
				return Vector2.ZERO
			return aim * CHARGE_SPEED * (1.0 + fury * 0.5)
		"wave_windup":
			if st > windup_len * 0.5 and to != Vector2.ZERO:
				aim = to / d
				sx = -1.0 if aim.x < 0.0 else 1.0
			if st <= 0.0:
				state = "wave"
				st = WAVE_TIME
				hit_once = false
				Sfx.play_at("fire_whoosh", global_position, 0.2)
				var q := Hazards.Quicksand.new()
				q.radii = Vector2(26, 15)
				q.life = 4.0
				q.position = head_pos() + aim * WAVE_RANGE * 0.6 + Vector2(0, 28)
				get_parent().add_child(q)
			return Vector2.ZERO
		"wave":
			_wave(delta)
			if st <= 0.0:
				_recover()
			return Vector2.ZERO
		"pounce_windup":
			if st > windup_len * 0.4 and to != Vector2.ZERO:
				jump_to = _clamp_floor(global_position + to)
			if st <= 0.0:
				state = "pounce"
				st = POUNCE_TIME
				jump_from = global_position
				Sfx.play_at("amheh_growl", global_position, 0.1)
			return Vector2.ZERO
		"pounce":
			if st <= 0.0:
				_land()
				_recover()
				return Vector2.ZERO
			return (jump_to - jump_from) / POUNCE_TIME
		"ray":
			if st <= 0.0:
				_recover()
				return Vector2.ZERO
			# anche mentre il raggio gira continua a cacciarti, piano
			return _steer(to.normalized() * spd * 0.4, delta) if d > 60.0 else Vector2.ZERO
	return Vector2.ZERO


func _next(time: float) -> void:
	state = "prowl"
	st = time


func _recover() -> void:
	state = "recover"
	st = RECOVER / (1.0 + fury * 0.5)


func _choose(to: Vector2, d: float) -> void:
	if to == Vector2.ZERO:
		_next(0.4)
		return
	# insieme, ma mai nello stesso istante: se il compagno ha appena cominciato, un attimo dopo
	if _partner_alive() and partner.state.ends_with("_windup") and partner.st > 0.35:
		_next(0.35)
		return
	# la tenaglia la decide Ieri, per tutti e due
	if kind == "ieri" and _partner_alive() and pincer_cd <= 0.0 and not partner.busy():
		_pincer(to)
		return
	var r := randf()
	if kind == "ieri":
		if alone and r < 0.35:
			_ray(to)
		elif d < WAVE_RANGE and r < 0.55:
			state = "wave_windup"
			st = _wu(WAVE_WINDUP)
			aim = to / d
			Sfx.play_at("amheh_growl", global_position, 0.1)
		else:
			_begin_charge(to, CHARGE_WINDUP)
		return
	# Domani
	if alone and r < 0.35:
		_begin_charge(to, CHARGE_WINDUP)
	elif d < 230.0 and r < 0.6:
		state = "pounce_windup"
		st = _wu(POUNCE_WINDUP)
		jump_to = _clamp_floor(global_position + to)
	else:
		_ray(to)


func _begin_charge(to: Vector2, windup: float) -> void:
	state = "charge_windup"
	st = _wu(windup)
	if to != Vector2.ZERO:
		aim = to.normalized()
		sx = -1.0 if aim.x < 0.0 else 1.0
	Sfx.play_at("amheh_growl", global_position, 0.1)


## La tenaglia: i due si mettono ai lati opposti di te, sulla stessa linea, e caricano insieme.
## La linea è orizzontale o verticale: si esce di lato, lontano dalle due cariche.
func _pincer(to: Vector2) -> void:
	pincer_cd = PINCER_COOLDOWN
	partner.pincer_cd = PINCER_COOLDOWN
	var center: Vector2 = global_position + to
	var axis := Vector2.RIGHT if randf() < 0.6 else Vector2.DOWN
	var off := PINCER_OFFSET if axis == Vector2.RIGHT else PINCER_OFFSET * 0.7
	var a := _clamp_floor(center - axis * off)
	var b := _clamp_floor(center + axis * off)
	# ognuno va dal lato più vicino a dove si trova
	if global_position.distance_to(b) < global_position.distance_to(a):
		var tmp := a
		a = b
		b = tmp
	state = "pincer_move"
	st = PINCER_MOVE
	pincer_spot = a
	partner.state = "pincer_move"
	partner.st = PINCER_MOVE
	partner.pincer_spot = b
	Sfx.play_at("roar", global_position, 0.05)
	Fx.float_text(center + Vector2(0, -40), Lang.t("TENAGLIA"), Color(1, 0.5, 0.3))


func _ray(to: Vector2) -> void:
	state = "ray"
	var r := Hazards.DawnRay.new()
	var o := head_pos()
	var sw := deg_to_rad(RAY_SWEEP) * (1.0 if randf() < 0.5 else -1.0)
	r.angle = (global_position + to + Vector2(0, -6) - o).angle() - sw * 0.5
	r.sweep = sw
	r.warn = maxf(MIN_WINDUP, RAY_WARN / (1.0 + fury))
	r.dur = RAY_TIME
	r.damage = RAY_DAMAGE * (1.0 + fury)
	r.src = self
	r.position = o
	get_parent().add_child(r)
	ray = r
	st = r.warn + r.dur + 0.1


func _wave(delta: float) -> void:
	var p = _player()
	if p == null or p.dash_t > 0.0:
		return
	var o := head_pos()
	var rel: Vector2 = p.global_position + Vector2(0, -6) - o
	if rel.length() < WAVE_RANGE and absf(aim.angle_to(rel)) < deg_to_rad(WAVE_HALF):
		p.move_and_collide(rel.normalized() * WAVE_PUSH * delta)
		if not hit_once:
			hit_once = _hurt(WAVE_DAMAGE, o)


func _land() -> void:
	Fx.shake(5.0)
	Fx.burst(global_position, Color(1.0, 0.6, 0.2), 24, 140.0)
	Sfx.play_at("amheh_land", global_position, 0.05)
	var p = _player()
	if p != null:
		var dd: Vector2 = p.global_position - global_position
		if Vector2(dd.x, dd.y / 0.6).length() < POUNCE_RADIUS + 4.0:
			_hurt(POUNCE_DAMAGE, global_position)


## Il compagno è caduto: ruggisce, prende la sua mossa e si infuria fino alla fine.
func _partner_fell() -> void:
	alone = true
	fury += IRA_FURY if Weights.rank("ira_aker") > 0 else FURY
	Fx.shake(8.0)
	Sfx.play_at("roar", global_position, 0.0)
	var g = get_tree().current_scene
	var line := Lang.t("«Domani è caduto? Allora Ieri non avrà più fine.»") if kind == "ieri" else Lang.t("«Ieri è sepolto. Ora ogni cosa è Domani.»")
	if g != null and g.has_method("_banner"):
		g._banner(Lang.t("Ieri") if kind == "ieri" else Lang.t("Domani"), line, Color(1.0, 0.6, 0.3), 2.6)
	var txt := Lang.t("IERI PRENDE IL FUOCO DI DOMANI") if kind == "ieri" else Lang.t("DOMANI PRENDE LA SABBIA DI IERI")
	Fx.float_text(global_position + Vector2(0, -50), txt, Color(1, 0.85, 0.5))


func _stagger_time() -> float:
	return 0.0


func _on_hit(_dmg: float) -> void:
	knock *= 0.15


func _contact_damage() -> float:
	return CONTACT * (1.0 + fury)


## Per i bot delle prove: da che parte scappare adesso (Vector2.ZERO = niente da schivare).
func bot_escape(pos: Vector2) -> Vector2:
	var rel := pos - global_position
	match state:
		"charge_windup":
			var side := aim.orthogonal()
			if absf(rel.dot(side)) < 30.0 and rel.dot(aim) > -20.0:
				return side * (1.0 if rel.dot(side) >= 0.0 else -1.0)
		"wave_windup":
			if rel.length() < WAVE_RANGE + 16.0:
				return rel.normalized() if rel != Vector2.ZERO else Vector2.RIGHT
		"pounce_windup":
			if pos.distance_to(jump_to) < POUNCE_RADIUS + 14.0:
				return (pos - jump_to).normalized() if pos != jump_to else Vector2.RIGHT
	return Vector2.ZERO


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
		lift = Vector2(0, -sin((1.0 - st / POUNCE_TIME) * PI) * 26.0)
	var mouth := 0.0
	if state.ends_with("_windup"):
		mouth = 1.0 - st / maxf(0.05, windup_len)
	elif state in ["wave", "ray", "pincer_move"]:
		mouth = 1.0
	var glow := 0.0
	if kind == "domani" or alone:
		glow = 0.35 + (0.65 if state in ["ray", "pounce"] else 0.0)
	if fury > 0.0:
		# la furia: un alone rosso che pulsa
		draw_circle(lift + Vector2(0, -16), 26.0 + 3.0 * sin(t * 8.0), Color(1.0, 0.25, 0.1, 0.12 + fury * 0.3))
	AkerArt.lion(self, lift + Vector2(-2, 0), sx, S, pal, pose, t, mouth, glow, flash)
	if alone and kind == "ieri":
		# Ieri ha preso il fuoco: braci che salgono dalla criniera
		for i in range(4):
			var k := fmod(t * 1.5 + i * 0.25, 1.0)
			draw_circle(lift + Vector2(sx * 12.0 + sin(i * 2.0) * 6.0, -30.0 - k * 20.0), 1.6 * (1.0 - k), Color(1, 0.6, 0.2, 1.0 - k))


func _draw_warnings() -> void:
	if state == "charge_windup" or state == "pincer_move":
		var k := 1.0 - st / windup_len if state == "charge_windup" else 0.3
		var ln := CHARGE_SPEED * CHARGE_TIME * (1.0 + fury * 0.5)
		var side := aim.orthogonal() * 14.0
		if state == "charge_windup":
			draw_colored_polygon(PackedVector2Array([side, aim * ln + side, aim * ln - side, -side]), Color(1, 0.2, 0.15, 0.1 + 0.2 * k))
			draw_line(Vector2.ZERO, aim * ln, Color(1, 0.25, 0.15, 0.5 + 0.4 * k), 2.0)
	elif state == "wave_windup" or state == "wave":
		var o := head_pos() - global_position
		var half := deg_to_rad(WAVE_HALF)
		var k2 := 1.0 if state == "wave" else 1.0 - st / windup_len
		var pts := PackedVector2Array([o])
		for i in range(11):
			pts.append(o + aim.rotated(-half + half * 2.0 * i / 10.0) * WAVE_RANGE)
		draw_colored_polygon(pts, Color(0.95, 0.75, 0.4, 0.12 + 0.25 * k2))
		draw_polyline(pts.slice(1), Color(1, 0.35, 0.15, 0.5 + 0.4 * k2), 2.0)
	elif state == "pounce_windup" or state == "pounce":
		var c := jump_to - global_position
		var k3 := 1.0 if state == "pounce" else 1.0 - st / windup_len
		draw_set_transform(c, 0.0, Vector2(1.0, 0.6))
		draw_circle(Vector2.ZERO, POUNCE_RADIUS * (0.4 + 0.6 * k3), Color(0, 0, 0, 0.2 + 0.2 * k3))
		draw_arc(Vector2.ZERO, POUNCE_RADIUS, 0.0, TAU, 32, Color(1, 0.3, 0.15, 0.6 + 0.3 * k3), 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
