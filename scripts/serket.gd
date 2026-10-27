extends Enemy
## Serket, la dea scorpione: la guardiana a metà di Sokar (stanza 5 della seconda tappa).
## "Colei che fa respirare la gola": proteggeva dal veleno chi la onorava... e lo sapeva usare.
## Qui ha la forma divina: un grande scorpione nero e oro con il volto della dea.
##
## Mosse (ognuna con il suo avviso, diverso da quelli del Serpente):
## - Ventaglio: la coda si alza e a terra si disegna uno spicchio rosso davanti a lei. Copre i
##   lati: non si schiva di lato come l'affondo del Serpente, ma uscendo dallo spicchio, cioè
##   allontanandosi o passandole dietro.
## - Sotto la sabbia: si infila nella sabbia e avanza verso di te lasciando un SOLCO visibile.
##   Non sparisce mai del tutto: il solco dice sempre dov'è. Sul piano di pietra al centro del
##   tempio non può scavare: se ci sei sopra si ferma sul bordo.
##   Mentre è sotto, dai cumuli di sabbia escono i suoi scorpioni (al massimo 5 vivi).
##   A volte, ancora sotto, alza la coda dalla sabbia e colpisce in linea retta (linea rossa).
##   Riemerge con un balzo in linea, nella direzione in cui stava andando: si schiva uscendo
##   dalla linea, non allontanandosi da un punto.
## Sotto metà vita si adira: intorno a lei sale una nube di veleno (stare attaccati a colpirla
## costa caro: colpisci e allontanati), il ventaglio diventa doppio, e dove riemerge lascia una
## nube che resta per qualche secondo. Escono più scorpioni e la coda dalla sabbia colpisce
## sempre.

@warning_ignore("unused_signal")
signal summon(kinds: Array)        # il gioco lo collega a ogni guardiano: qui evoca gli scorpioni

@export var fan_windup := 0.72
@export var fan_radius := 92.0
@export var fan_angle := 130.0          ## ampiezza dello spicchio, in gradi
@export var fan_damage := 15.0
@export var under_time := 3.6
@export var under_speed := 118.0
@export var line_warn := 0.62
@export var line_len := 175.0
@export var line_damage := 13.0
@export var breach_warn := 0.55
@export var breach_len := 140.0
@export var breach_time := 0.22
@export var breach_damage := 17.0
@export var max_scorpions := 5
@export var aura_radius := 48.0

const SQUASH := 0.7                     ## le forme a terra sono ellissi schiacciate (prospettiva)
const SAND := Color(0.78, 0.62, 0.38)
const SAND_D := Color(0.5, 0.37, 0.2)
const FURROW_LIFE := 3.0                ## quanto resta visibile il solco (secondi)

var state := "intro"
var st := 1.5
var aim := Vector2.DOWN
var enraged := false
var second_fan := false
var burrow_cd := 4.0                    # secondi prima che possa scavare di nuovo
var under_left := 0.0                   # quanto resta sotto la sabbia (il colpo di coda lo sospende)
var line_done := false
var breach_from := Vector2.ZERO
var breach_hit := false
var aura_cool := 0.0
var furrow: Array[Vector3] = []         # il solco: x, y, momento in cui è stato scavato
var buried := false
## L'arena (game.gd, prima che entri in scena): il piano di pietra e i cumuli di sabbia.
var dais_center := Vector2.ZERO
var dais_radii := Vector2.ZERO
var mounds: Array = []


func _ready() -> void:
	miniboss = true
	super._ready()


func on_dais(p: Vector2) -> bool:
	if dais_radii == Vector2.ZERO:
		return false
	return ((p - dais_center) / dais_radii).length() < 1.0


func _rage() -> float:
	return 1.2 if enraged else 1.0


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta * _rage()
	burrow_cd -= delta
	aura_cool = maxf(0.0, aura_cool - delta)
	if not enraged and hp < max_hp * 0.5:
		enraged = true
		Fx.shake(6.0)
		Fx.burst(global_position + Vector2(0, -14), Color(0.55, 1.0, 0.35), 30, 120.0)
		Fx.float_text(global_position + Vector2(0, -40), Lang.t("SERKET SI ADIRA"), Color(0.5, 1, 0.75))
		Sfx.play_at("roar", global_position, 0.05)
	_aura()
	_age_furrow()
	match state:
		"intro":
			if st <= 0.0:
				_next(0.8)
			return Vector2.ZERO
		"chase":
			if to != Vector2.ZERO:
				aim = to.normalized()
			if st <= 0.0:
				_choose(to)
				return Vector2.ZERO
			return _steer(aim * speed * _rage(), delta)
		"fan_windup":
			# mira finché la coda non è quasi su: poi lo spicchio resta fermo
			if st > fan_windup * 0.45 and to != Vector2.ZERO:
				aim = to.normalized()
			if st <= 0.0:
				_fan()
				if enraged and not second_fan:
					second_fan = true
					st = fan_windup * 0.6
					Sfx.play_at("scorpion_windup", global_position, 0.05)
					return Vector2.ZERO
				second_fan = false
				state = "recover"
				st = 0.75
			return Vector2.ZERO
		"seek_sand":
			# sul piano di pietra non si scava: prima ne esce (ed è il tuo avviso)
			var out := global_position - dais_center
			if out == Vector2.ZERO:
				out = Vector2.RIGHT
			if not on_dais(global_position - out.normalized() * 12.0) or st <= 0.0:
				_dive()
				return Vector2.ZERO
			return _steer(out.normalized() * speed * 1.5, delta)
		"dive":
			if st <= 0.0:
				state = "under"
				under_left = under_time
				line_done = false
				_set_buried(true)
				_summon_scorpions()
			return Vector2.ZERO
		"under":
			under_left -= delta
			_dig()
			# a metà strada, a volte, la coda esce dalla sabbia e colpisce in linea
			if not line_done and under_left < under_time * 0.6 and to != Vector2.ZERO and to.length() < line_len + 20.0:
				line_done = true
				if enraged or randf() < 0.6:
					state = "line_warn"
					st = line_warn
					aim = to.normalized()
					Sfx.play_at("scorpion_windup", global_position, 0.05)
					return Vector2.ZERO
			if to == Vector2.ZERO:
				return Vector2.ZERO
			var step := to.normalized() * under_speed * _rage()
			var blocked := on_dais(global_position + step.normalized() * 14.0)
			if under_left <= 0.0 or to.length() < 30.0 or blocked:
				state = "breach_warn"
				st = breach_warn
				# esce nella direzione in cui stava andando, verso di te
				aim = to.normalized()
				Sfx.play_at("serpent_hiss", global_position, 0.1)
				return Vector2.ZERO
			return _steer(step, delta)
		"line_warn":
			if st <= 0.0:
				_line_strike()
				state = "under"
				Fx.shake(4.0)
			return Vector2.ZERO
		"breach_warn":
			if st <= 0.0:
				state = "breach"
				st = breach_time
				breach_from = global_position
				breach_hit = false
				_set_buried(false)
				Fx.shake(8.0)
				Fx.burst(global_position, SAND, 40, 180.0)
				Sfx.play_at("serpent_erupt", global_position, 0.05)
			return Vector2.ZERO
		"breach":
			_breach_check()
			if st <= 0.0:
				if enraged:
					var cloud := Hazards.VenomCloud.new()
					cloud.position = breach_from
					get_parent().add_child(cloud)
				state = "recover"
				st = 1.0
				burrow_cd = 5.0 + randf() * 2.0
				return Vector2.ZERO
			return aim * breach_len / breach_time
		"recover":
			if st <= 0.0:
				_next(0.7 + randf() * 0.6)
			return Vector2.ZERO
	return Vector2.ZERO


func _next(time: float) -> void:
	state = "chase"
	st = time


func _choose(to: Vector2) -> void:
	var d := to.length() if to != Vector2.ZERO else 999.0
	if burrow_cd <= 0.0 and (d > 170.0 or randf() < 0.45):
		if on_dais(global_position):
			state = "seek_sand"
			st = 2.0
		else:
			_dive()
		return
	if d < 135.0:
		state = "fan_windup"
		st = fan_windup
		Sfx.play_at("scorpion_windup", global_position, 0.05)
		return
	_next(0.5)          # troppo lontana per il ventaglio: si avvicina ancora


func _dive() -> void:
	state = "dive"
	st = 0.5
	Fx.burst(global_position, SAND, 26, 110.0)
	Sfx.play_at("serpent_burrow", global_position, 0.1)


## Dai cumuli di sabbia escono gli scorpioni (lontano da te, al massimo 5 vivi).
func _summon_scorpions() -> void:
	var alive := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e != self and "sting_dir" in e:
			alive += 1
	var n := mini(max_scorpions - alive, 3 if enraged else 2)
	if n <= 0 or mounds.is_empty():
		return
	var player = get_tree().get_first_node_in_group("player")
	var spots: Array = mounds.duplicate()
	spots.shuffle()
	var out := []
	for p in spots:
		if out.size() >= n:
			break
		var pos: Vector2 = p
		if player != null and pos.distance_to(player.global_position) < 70.0:
			continue
		out.append(["scorpion", pos])
		Fx.burst(pos, SAND, 14, 70.0)
	if not out.is_empty():
		summon.emit(out)


## Il ventaglio: colpisce chi è nello spicchio davanti a lei.
func _fan() -> void:
	Sfx.play_at("scorpion_sting", global_position, 0.05)
	Fx.shake(4.0)
	var half := deg_to_rad(fan_angle) * 0.5
	var a := _ground(aim)
	for i in range(9):
		var dir := _unground(a.rotated(-half + half * 2.0 * i / 8.0))
		Fx.burst(global_position + dir * fan_radius * 0.75, SAND, 3, 60.0)
	var player = get_tree().get_first_node_in_group("player")
	if player == null or player.dead:
		return
	var rel: Vector2 = _ground(player.global_position - global_position)
	if rel.length() < fan_radius + 6.0 and (rel.length() < 12.0 or absf(a.angle_to(rel)) < half):
		player.take_damage(fan_damage, global_position, self)


## La coda esce dalla sabbia e colpisce lungo la linea.
func _line_strike() -> void:
	Sfx.play_at("scorpion_sting", global_position, 0.05)
	for i in range(8):
		Fx.burst(global_position + aim * line_len * (i + 0.5) / 8.0, SAND, 4, 70.0)
	var player = get_tree().get_first_node_in_group("player")
	if player != null and not player.dead and _seg_dist(player.global_position, global_position, global_position + aim * line_len) < 15.0:
		player.take_damage(line_damage, global_position, self)


## Il balzo fuori dalla sabbia: ferisce una volta chi è sulla linea che percorre.
func _breach_check() -> void:
	if breach_hit:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player != null and not player.dead and _seg_dist(player.global_position, breach_from, global_position) < 18.0:
		if player.take_damage(breach_damage, global_position, self):
			breach_hit = true


## Adirata: la nube di veleno intorno a lei. Avvelena chi le sta attaccato (non chi scatta).
func _aura() -> void:
	if not enraged or buried or aura_cool > 0.0:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player == null or player.dead or player.dash_t > 0.0:
		return
	if _ground(player.global_position - global_position).length() < aura_radius:
		player.poison(1.2, "serket")
		aura_cool = 0.5


func _dig() -> void:
	var p := global_position
	if furrow.is_empty() or Vector2(furrow[0].x, furrow[0].y).distance_to(p) > 5.0:
		furrow.push_front(Vector3(p.x, p.y, t))
		if randf() < 0.3:
			Fx.burst(p, SAND, 2, 30.0)


func _age_furrow() -> void:
	while not furrow.is_empty() and t - furrow[furrow.size() - 1].z > FURROW_LIFE:
		furrow.pop_back()


func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	if ab.length_squared() < 0.01:
		return p.distance_to(a)
	var k := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * k)


## Dal mondo al piano a terra (ellisse schiacciata) e ritorno.
func _ground(v: Vector2) -> Vector2:
	return Vector2(v.x, v.y / SQUASH)


func _unground(v: Vector2) -> Vector2:
	return Vector2(v.x, v.y * SQUASH)


## Sotto la sabbia non la si può colpire e non ferisce al contatto.
func _set_buried(on: bool) -> void:
	buried = on
	if on:
		remove_from_group("enemies")
		collision_layer = 0
		if contact != null:
			contact.monitoring = false
	else:
		add_to_group("enemies")
		collision_layer = 4
		if contact != null:
			contact.monitoring = true


func _stagger_time() -> float:
	return 0.0


func _on_hit(_dmg: float) -> void:
	knock *= 0.1


# ---------------------------------------------------------------- disegno

func _draw() -> void:
	_draw_furrow()
	if buried:
		_draw_under()
		return
	super._draw()
	_draw_warnings()


## Il solco nella sabbia: due creste chiare e il fondo scuro, che si richiudono col tempo.
func _draw_furrow() -> void:
	for i in range(furrow.size()):
		var f: Vector3 = furrow[i]
		var a := clampf(1.0 - (t - f.z) / FURROW_LIFE, 0.0, 1.0)
		a = minf(1.0, a * 1.6)              # resta ben visibile quasi fino alla fine, poi si chiude
		var p := Vector2(f.x, f.y) - global_position
		# il fondo scuro, largo: deve leggersi anche sul telefono, è il cuore dello scontro
		draw_set_transform(p, 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, 10.0, Color(0.32, 0.22, 0.11, 0.6 * a))
		draw_circle(Vector2.ZERO, 6.0, Color(0.22, 0.14, 0.07, 0.65 * a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# le due creste chiare ai lati
		draw_circle(p + Vector2(0, -5.5), 2.2, Color(0.97, 0.86, 0.6, 0.75 * a))
		draw_circle(p + Vector2(0, 5.5), 2.0, Color(0.97, 0.86, 0.6, 0.6 * a))


## Sotto la sabbia: il cumulo che avanza, la sabbia che schizza e, quando sta per colpire,
## la punta della coda che esce.
func _draw_under() -> void:
	var wob := sin(t * 18.0) * 1.2
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_circle(Vector2.ZERO, 21.0, Color(0, 0, 0, 0.3))
	draw_circle(Vector2(0, -2), 17.5 + wob, Color(0.25, 0.16, 0.08))
	draw_circle(Vector2(0, -2), 16.0 + wob, SAND_D)
	draw_circle(Vector2(-2, -5), 12.0 + wob, SAND)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in range(5):
		var k := fmod(t * 2.5 + i * 0.2, 1.0)
		var gp := Vector2(sin(i * 2.4) * 14.0, -6.0 - k * 10.0)
		draw_circle(gp, 1.4 * (1.0 - k), Color(SAND, 1.0 - k))
	if state == "line_warn" or state == "breach_warn":
		# il pungiglione esce dalla sabbia e si accende
		var k := 1.0 - st / (line_warn if state == "line_warn" else breach_warn)
		var tip := Vector2(0, -6.0 - 14.0 * k)
		draw_line(Vector2(0, -4), tip, OUT, 4.0)
		draw_line(Vector2(0, -4), tip, Color(0.15, 0.12, 0.1), 2.5)
		draw_circle(tip, 3.0 + 2.0 * k, Color(0.6, 1.0, 0.4, 0.3 + 0.4 * k))
		draw_circle(tip, 2.0, Color(0.6, 1.0, 0.4))
		var length := line_len if state == "line_warn" else breach_len
		_warn_line(aim, length, k)


## La linea rossa a terra: la stessa lingua del Serpente (chi l'ha imparata la riconosce).
func _warn_line(dir: Vector2, length: float, k: float) -> void:
	var a := dir * 4.0
	var b := dir * length
	var side := dir.orthogonal() * 9.0
	draw_colored_polygon(PackedVector2Array([a + side, b + side, b - side, a - side]), Color(1, 0.2, 0.15, 0.12 + 0.18 * k))
	draw_line(a, b, Color(1, 0.25, 0.15, 0.45 + 0.4 * k), 2.0)
	draw_line(b + dir.orthogonal() * 6.0, b - dir.orthogonal() * 6.0, Color(1, 0.25, 0.15, 0.7), 2.0)


func _draw_warnings() -> void:
	if state == "fan_windup":
		var k := 1.0 - st / (fan_windup * (0.6 if second_fan else 1.0))
		var half := deg_to_rad(fan_angle) * 0.5
		var a := _ground(aim).angle()
		var pts := PackedVector2Array([Vector2.ZERO])
		var edge := PackedVector2Array()
		for i in range(17):
			var ang := a - half + half * 2.0 * i / 16.0
			var v := _unground(Vector2.from_angle(ang)) * fan_radius
			pts.append(v)
			edge.append(v)
		draw_colored_polygon(pts, Color(1, 0.2, 0.15, 0.1 + 0.2 * k))
		draw_polyline(edge, Color(1, 0.3, 0.15, 0.5 + 0.4 * k), 2.0)
		# lo spicchio si riempie da dentro verso fuori: quando è pieno, la coda cala
		var inner := PackedVector2Array([Vector2.ZERO])
		for i in range(17):
			var ang := a - half + half * 2.0 * i / 16.0
			inner.append(_unground(Vector2.from_angle(ang)) * fan_radius * k)
		draw_colored_polygon(inner, Color(1, 0.25, 0.15, 0.15))
	if enraged:
		# la nube di veleno intorno a lei
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, SQUASH))
		draw_circle(Vector2.ZERO, aura_radius, Color(0.45, 0.9, 0.25, 0.1))
		draw_arc(Vector2.ZERO, aura_radius, 0.0, TAU, 40, Color(0.5, 1.0, 0.35, 0.35), 1.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for i in range(10):
			var k := fmod(t * 0.5 + i * 0.1, 1.0)
			var ang := i * 2.39 + t * 0.4
			var mp := _unground(Vector2.from_angle(ang) * aura_radius * (0.35 + 0.6 * fmod(i * 0.37, 1.0))) + Vector2(0, -k * 14.0)
			draw_circle(mp, 3.0 + 3.0 * k, Color(0.5, 0.95, 0.3, 0.22 * (1.0 - k)))


## Serket in forma divina: grande scorpione dalla corazza nera e oro, con le fasce turchesi della
## dea, e davanti, al posto della testa, il volto della dea di profilo: parrucca nera a righe
## blu, diadema d'oro e lo scorpione sul capo. La coda si alza e il pungiglione si accende di
## verde quando sta per colpire.
func _draw_body(flash: bool) -> void:
	var shell := _f(Color(0.16, 0.12, 0.1), flash)
	var shell_l := _f(Color(0.34, 0.26, 0.2), flash)
	var gold := _f(GOLD, flash)
	var turq := _f(Color(0.22, 0.7, 0.68), flash)
	var skin := _f(Color(0.86, 0.66, 0.36), flash)
	var wig := _f(Color(0.08, 0.07, 0.1), flash)
	var dir := 1.0 if aim.x >= 0.0 else -1.0
	var raise := 0.0
	if state == "fan_windup":
		raise = 1.0 - st / (fan_windup * (0.6 if second_fan else 1.0))
	elif state == "recover" and st > 0.5:
		raise = 0.4
	var S := 2.6
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir * S, S))
	# otto zampe, a passi alternati
	var walk := velocity.length() > 5.0
	for i in range(4):
		var lx := -5.0 + i * 3.2
		var w := sin(t * 14.0 + i * 1.7) * (1.3 if walk else 0.2)
		_limb(Vector2(lx, -4.0), Vector2(lx - 2.2 + w, -7.0), shell, 0.8)
		_limb(Vector2(lx - 2.2 + w, -7.0), Vector2(lx - 3.4 + w, -0.4), shell, 0.8)
		_limb(Vector2(lx, -3.0), Vector2(lx + 1.6 - w, 0.8), shell, 0.9)
	# il corpo a segmenti, con le fasce d'oro e turchesi
	_op(_ell(Vector2(-1.0, -4.5), 7.4, 3.9, 18), shell, 0.6)
	for k in range(4):
		var x := -6.0 + k * 2.8
		draw_line(Vector2(x, -8.0), Vector2(x - 0.4, -1.2), gold, 0.55)
	draw_line(Vector2(-6.5, -6.2), Vector2(4.0, -6.2), turq, 0.7)
	draw_arc(Vector2(-1.5, -5.6), 4.4, PI * 1.1, PI * 1.6, 6, shell_l, 0.7)
	# le chele, grandi, d'oro alle punte
	for k in [0.0, 1.0]:
		var base := Vector2(4.5, -5.5 + k * 2.4)
		var elbow := Vector2(7.5, -8.5 + k * 6.0)
		_limb(base, elbow, shell, 1.4)
		var claw := PackedVector2Array([elbow, elbow + Vector2(3.8, -1.8), elbow + Vector2(5.0, -0.2), elbow + Vector2(2.5, 0.2), elbow + Vector2(4.2, 1.6), elbow + Vector2(1.3, 1.8)])
		_op(claw, gold, 0.5)
	# la coda: sei anelli ad arco sopra il dorso, più alti quando sta per colpire
	var seg := PackedVector2Array()
	for k in range(7):
		var u := k / 6.0
		var ang := lerpf(PI * 0.95, PI * (0.3 - raise * 0.2), u)
		var r := 8.0 + raise * 3.0
		seg.append(Vector2(-8.0, -4.5) + Vector2(cos(ang) * r * 0.6 + u * (4.0 + raise * 5.0), -sin(ang) * r - u * (4.0 + raise * 3.0)))
	for k in range(6):
		_limb(seg[k], seg[k + 1], shell, 1.8)
	for k in range(6):
		var r := 2.5 - k * 0.2
		var c := seg[k].lerp(seg[k + 1], 0.5)
		_dot(c, r, shell if k % 2 == 0 else shell_l)
		draw_arc(c, r * 0.8, PI * 1.1, PI * 1.9, 5, gold, 0.4)
	var tip: Vector2 = seg[6]
	var lit := raise > 0.0 or enraged
	var sting := Color(0.6, 1.0, 0.4) if lit else gold
	if flash:
		sting = Color.WHITE
	if lit:
		draw_circle(tip, 3.0 + raise * 2.5, Color(0.6, 1.0, 0.4, 0.25))
	_op(PackedVector2Array([tip + Vector2(-1.5, -1.1), tip + Vector2(1.7, -1.3), tip + Vector2(2.8, 1.7), tip + Vector2(0.7, 0.7), tip + Vector2(-1.1, 1.3)]), sting, 0.5)
	# il volto della dea, di profilo, davanti al corpo: grande, perché si legga anche da lontano.
	# Prima la parrucca (dietro la nuca, sulle spalle), poi il viso chiaro con l'occhio dipinto.
	var hc := Vector2(6.8, -11.0)
	var hs := 1.45
	var wig_pts := PackedVector2Array()
	for v in [Vector2(-3.6, -3.4), Vector2(0.4, -4.4), Vector2(1.2, -2.0), Vector2(-0.6, -0.6), Vector2(-0.8, 3.6), Vector2(-3.0, 4.2), Vector2(-4.2, 1.0)]:
		wig_pts.append(hc + (v as Vector2) * hs)
	_op(wig_pts, wig, 0.5)
	draw_line(hc + Vector2(-3.4, 2.2) * hs, hc + Vector2(-1.0, 2.2) * hs, turq, 0.5)
	var face := PackedVector2Array()
	for v in [Vector2(-1.2, -3.2), Vector2(1.4, -3.4), Vector2(2.2, -1.8), Vector2(3.4, -0.4), Vector2(2.4, 0.2), Vector2(2.6, 1.3), Vector2(1.8, 2.4), Vector2(-0.6, 2.6), Vector2(-1.0, -0.4)]:
		face.append(hc + (v as Vector2) * hs)
	_op(face, skin, 0.5)
	draw_line(hc + Vector2(-3.8, -3.0) * hs, hc + Vector2(1.6, -3.6) * hs, gold, 0.8)       # il diadema
	# l'occhio grande, bianco, con il kohl che si allunga verso la tempia
	var eye := Color(1, 0.3, 0.2) if enraged else Color(0.1, 0.08, 0.1)
	if flash:
		eye = Color.WHITE
	var ec := hc + Vector2(1.3, -1.4) * hs
	_op(_ell(ec, 1.1, 0.6, 8), Color(0.97, 0.94, 0.86), 0.35)
	draw_circle(ec + Vector2(0.3, 0), 0.45, eye)
	draw_line(ec + Vector2(-1.0, -0.2), ec + Vector2(-2.4, -0.6), OUT, 0.45)
	draw_line(hc + Vector2(2.1, 1.2) * hs, hc + Vector2(2.8, 1.2) * hs, Color(0.6, 0.2, 0.15), 0.4)    # le labbra
	# lo scorpione d'oro sul capo: il segno della dea
	var cp := hc + Vector2(-0.8, -5.2) * hs
	_op(_ell(cp, 2.2, 1.0, 10), gold, 0.4)
	draw_arc(cp + Vector2(-1.6, -1.4), 1.6, PI * 0.5, PI * 1.6, 6, gold, 0.6)
	draw_line(cp + Vector2(1.8, 0), cp + Vector2(3.0, -1.0), gold, 0.5)
	draw_line(cp + Vector2(1.8, 0.2), cp + Vector2(3.0, 1.0), gold, 0.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
