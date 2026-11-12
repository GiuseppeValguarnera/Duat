extends Enemy
## APOPI, il serpente del caos: il boss del Banco di Apopi (la settima ora). Nel Libro dell'Amduat beve
## l'acqua del fiume per arenare la barca di Ra sul suo banco di sabbia; non può essere ucciso, solo
## respinto e legato, ogni notte.
##
## Si combatte la TESTA (il corpo sono le spire che la seguono). Mosse, tutte con l'avviso rosso vero:
## - AFFONDO: si ritrae, una striscia larga attraversa l'arena, poi scatta. Finisce col muso nella
##   sabbia: ESPOSTO per 1,3 s (i colpi fanno +25%). È il momento di colpire.
## - BEVE IL FIUME: spalanca la bocca e ti risucchia verso di sé per 2,4 s (cammina contro, scatta
##   di lato); vicino alla bocca si viene morsi. Poi SPUTA un ventaglio di caos.
## - CODA: un cerchio rosso dove sei, la coda cade dall'alto e lascia una pozza di Isfet.
## - FIGLI: chiama le sue serpi (mai più di 3 vive).
## Sotto metà vita INGHIOTTE LA LUCE: il buio va e viene (Chaos.Darkness: vedi bene solo vicino a te,
## ma gli avvisi restano visibili), due affondi di fila, tre code, risucchio più forte.

signal summon(kinds: Array)        # il gioco lo collega a ogni boss: fa uscire i Figli di Apopi

const BoltScript := preload("res://scripts/enemy_bolt.gd")

const HP := 3200.0
const LUNGE_WARN := 0.75
const LUNGE_WARN2 := 0.5
const LUNGE_LEN := 420.0
const LUNGE_SPEED := 540.0
const LUNGE_HALF := 22.0
const LUNGE_DMG := 22.0
const STUCK := 1.3
const STUCK_MULT := 1.25
const PULL_WARN := 0.8
const PULL_TIME := 2.4
const PULL_SPEED := 80.0
const PULL_SPEED2 := 104.0
const MAW_R := 34.0
const MAW_DMG := 7.0
const MAW_TICK := 0.4
const SPIT_N := 7
const SPIT_SPREAD := 80.0
const SPIT_SPEED := 170.0
const SPIT_DMG := 9.0
const TAIL_WARN := 1.0
const TAIL_GAP := 0.45
const TAIL_R := 46.0
const TAIL_DMG := 20.0
const BROOD_MAX := 3
const BROOD_CD := 13.0
const DARK_ON := 7.0
const DARK_OFF := 9.0
const HOVER := 118.0              ## quanto sta lontano da te mentre ti studia

var state := "intro"
var st := 1.8
var aim := Vector2.DOWN
var enraged := false
var arena := Rect2()
var trail: Array[Vector2] = []
var trail_gap := 0.0
var lunge_left := 0.0
var lunge_hit := false
var second_lunge := false
var maw_cd := 0.0
var tails: Array = []             ## [posizione, secondi all'impatto]
var brood_cd := 6.0
var last_move := ""
var dark: Chaos.Darkness = null
var dark_t := 3.0
var dark_on := false
var mouth := 0.0                  ## 0 chiusa → 1 spalancata


func _ready() -> void:
	is_boss = true
	max_hp = HP * (1.0 + 0.1 * Weights.rank("piombo"))
	super._ready()
	for i in range(46):
		trail.append(global_position + Vector2(0, -i * 7.0))


func _phase_mult() -> float:
	return 1.2 if enraged else 1.0


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta
	brood_cd -= delta
	maw_cd = maxf(0.0, maw_cd - delta)
	_update_tails(delta)
	_update_dark(delta)
	_update_trail()
	var want_mouth := 1.0 if state in ["pull_warn", "pull", "spit"] else (0.5 if state.begins_with("lunge") else 0.0)
	mouth = move_toward(mouth, want_mouth, delta * 3.0)
	if not enraged and hp < max_hp * 0.5 and state in ["hover", "recover", "stuck"]:
		_enrage()
	if to == Vector2.ZERO:
		return Vector2.ZERO
	var d := to.length()
	var u := to / d
	var p = get_tree().get_first_node_in_group("player")
	match state:
		"intro":
			if st <= 0.0:
				_next(1.0)
			return Vector2.ZERO
		"hover":
			aim = u
			if st <= 0.0:
				_choose(d)
				return Vector2.ZERO
			# gira intorno a te tenendosi a distanza: le spire disegnano l'arena
			var radial := u * clampf((d - HOVER) / 40.0, -1.0, 1.0)
			return (radial + u.orthogonal() * _side * 0.8).normalized() * speed * _phase_mult()
		"lunge_warn":
			var total := LUNGE_WARN2 if second_lunge else LUNGE_WARN
			if st > total * 0.5:
				aim = u
			if st <= 0.0:
				state = "lunge"
				lunge_left = LUNGE_LEN
				lunge_hit = false
				Sfx.play_at("serpent_strike", global_position, 0.05)
				Fx.shake(4.0)
			return -aim * 26.0
		"lunge":
			if not lunge_hit and p != null and touches(p, LUNGE_HALF - PLAYER_R - TOUCH_PAD):
				lunge_hit = p.take_damage(LUNGE_DMG, global_position, self)
			lunge_left -= LUNGE_SPEED * delta
			var hit_wall := false
			for i in range(get_slide_collision_count()):
				var col := get_slide_collision(i)
				if col.get_collider() is StaticBody2D and aim.dot(col.get_normal()) < -0.5:
					hit_wall = true
			if lunge_left <= 0.0 or hit_wall or not _inside(global_position + aim * 26.0):
				Fx.shake(7.0)
				Sfx.play_at("amheh_land", global_position, 0.1)
				Fx.burst(global_position + aim * 16.0, Color(0.55, 0.45, 0.4), 22, 150.0)
				if enraged and not second_lunge:
					second_lunge = true
					state = "lunge_warn"
					st = LUNGE_WARN2
					Sfx.play_at("serpent_hiss", global_position, 0.1)
					return Vector2.ZERO
				second_lunge = false
				state = "stuck"
				st = STUCK
				Fx.float_text(global_position + Vector2(0, -40), Lang.t("ESPOSTO"), Color(1, 0.9, 0.5))
				return Vector2.ZERO
			return aim * LUNGE_SPEED
		"stuck":
			if st <= 0.0:
				_next(randf_range(0.9, 1.4) / _phase_mult())
			return Vector2.ZERO
		"pull_warn":
			aim = u
			if st <= 0.0:
				state = "pull"
				st = PULL_TIME
				Sfx.play_at("amheh_howl", global_position, 0.1)
			return Vector2.ZERO
		"pull":
			aim = u
			if p != null and not p.dead:
				var back: Vector2 = -u
				var v := PULL_SPEED2 if enraged else PULL_SPEED
				if p.dash_t <= 0.0:
					p.move_and_collide(back * v * delta)
				if maw_cd <= 0.0 and d < MAW_R:
					if p.take_damage(MAW_DMG, global_position, self):
						maw_cd = MAW_TICK
			if st <= 0.0:
				state = "spit"
				st = 0.45
				Sfx.play_at("serpent_hiss", global_position, 0.1)
			return Vector2.ZERO
		"spit":
			if st <= 0.0:
				_spit()
				state = "recover"
				st = 1.1
			return Vector2.ZERO
		"tail":
			if st <= 0.0:
				state = "recover"
				st = 0.5
			return (u.orthogonal() * _side).normalized() * speed * 0.5
		"recover":
			if st <= 0.0:
				_next(randf_range(0.8, 1.3) / _phase_mult())
			return Vector2.ZERO
	return Vector2.ZERO


func _inside(p: Vector2) -> bool:
	return arena.size == Vector2.ZERO or arena.grow(-6.0).has_point(p)


func _next(time: float) -> void:
	state = "hover"
	st = time
	if randf() < 0.5:
		_side = -_side


func _enrage() -> void:
	enraged = true
	Fx.shake(12.0)
	Sfx.play("roar", 0.0)
	var g = get_tree().current_scene
	if g != null and g.has_method("_banner"):
		g._banner(Lang.t("Apopi inghiotte la luce"), Lang.t("Il buio va e viene. Gli avvisi rossi li vedi sempre"), Color(0.7, 0.4, 1.0), 2.6)
	dark = Chaos.Darkness.new()
	get_parent().add_child(dark)
	dark_t = 1.5
	dark_on = false
	z_index = 6                           # sopra il buio: lui e i suoi avvisi si vedono sempre


func _update_dark(delta: float) -> void:
	if dark == null or not is_instance_valid(dark):
		return
	dark_t -= delta
	if dark_t <= 0.0:
		dark_on = not dark_on
		dark_t = DARK_ON if dark_on else DARK_OFF
		dark.target = 1.0 if dark_on else 0.0
		if dark_on:
			Sfx.play_at("soul", global_position, 0.1)


func _choose(d: float) -> void:
	var brood := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e != self and e is Enemy and not e.dead:
			brood += 1
	if brood_cd <= 0.0 and brood < BROOD_MAX:
		brood_cd = BROOD_CD / _phase_mult()
		var kinds := []
		for i in range(mini(BROOD_MAX - brood, 3 if enraged else 2)):
			kinds.append("apep_spawn")
		summon.emit(kinds)
		Sfx.play_at("cobra_hiss", global_position, 0.1)
		Fx.float_text(global_position + Vector2(0, -44), Lang.t("I FIGLI DI APOPI"), Color(0.75, 0.45, 1.0))
		_next(0.8)
		return
	var opts := ["lunge", "lunge", "tail", "pull"]
	if d < 60.0:
		opts.append("tail")
	opts = opts.filter(func(o) -> bool: return o != last_move)
	var m: String = opts.pick_random()
	last_move = m
	match m:
		"lunge":
			state = "lunge_warn"
			st = LUNGE_WARN
			second_lunge = false
			Sfx.play_at("serpent_hiss", global_position, 0.05)
		"pull":
			state = "pull_warn"
			st = PULL_WARN
			Sfx.play_at("amheh_growl", global_position, 0.05)
			Fx.float_text(global_position + Vector2(0, -44), Lang.t("APOPI BEVE IL FIUME"), Color(0.6, 0.8, 1.0))
		"tail":
			state = "tail"
			var n := 3 if enraged else 1
			st = TAIL_WARN + TAIL_GAP * (n - 1) + 0.2
			tails.clear()
			for i in range(n):
				tails.append([Vector2.INF, TAIL_WARN + TAIL_GAP * i])
			Sfx.play_at("serpent_burrow", global_position, 0.1)


func _update_tails(delta: float) -> void:
	var p = get_tree().get_first_node_in_group("player")
	for tl in tails:
		var before: float = tl[1]
		tl[1] = before - delta
		var at: Vector2 = tl[0]
		if at == Vector2.INF and float(tl[1]) <= TAIL_WARN and p != null:
			tl[0] = p.global_position          # il cerchio si ferma dove sei quando parte il SUO avviso
			at = tl[0]
		if before > 0.0 and float(tl[1]) <= 0.0 and at != Vector2.INF:
			Fx.shake(8.0)
			Fx.burst(at, Color(0.35, 0.2, 0.45), 26, 170.0)
			Sfx.play_at("amheh_land", at, 0.15)
			if p != null and not p.dead and p.global_position.distance_to(at) < TAIL_R:
				p.take_damage(TAIL_DMG, at, self)
			var pool := Chaos.Isfet.new()
			pool.r = 20.0
			pool.life = 5.0
			get_parent().add_child(pool)
			pool.global_position = at
	tails = tails.filter(func(x) -> bool: return float(x[1]) > -0.4)


func _spit() -> void:
	Sfx.play_at("cobra_spit", global_position, 0.1)
	var n := SPIT_N + (2 if enraged else 0)
	for i in range(n):
		var a := deg_to_rad(lerpf(-SPIT_SPREAD / 2.0, SPIT_SPREAD / 2.0, i / float(n - 1)))
		var bolt: Area2D = BoltScript.new()
		bolt.direction = aim.rotated(a)
		bolt.speed = SPIT_SPEED
		bolt.damage = SPIT_DMG
		bolt.shooter = self
		bolt.style = "isfet"
		bolt.life = 2.4
		get_parent().add_child(bolt)
		bolt.global_position = global_position + aim * 22.0


func _update_trail() -> void:
	if trail.is_empty():
		return
	if global_position.distance_to(trail[0]) > 7.0:
		trail.push_front(global_position)
		trail.pop_back()


func take_hit(dmg: float, dir: Vector2, _kb: float, can_burn: bool = false) -> void:
	if state == "intro":
		return
	super.take_hit(dmg * (STUCK_MULT if state == "stuck" else 1.0), dir, 0.0, can_burn)


func _stagger_time() -> float:
	return 0.0


func _contact_damage() -> float:
	return 0.0


func die() -> void:
	if dark != null and is_instance_valid(dark):
		dark.target = 0.0
		get_tree().create_timer(1.5, false).timeout.connect(dark.queue_free)
	super.die()


func bot_escape(pos: Vector2) -> Vector2:
	for tl in tails:
		var at: Vector2 = tl[0]
		if at != Vector2.INF and float(tl[1]) > 0.0 and pos.distance_to(at) < TAIL_R + 10.0:
			return (pos - at).normalized() if pos != at else Vector2.RIGHT
	var v := pos - global_position
	if state == "lunge_warn" or state == "lunge":
		if absf(v.dot(aim.orthogonal())) < LUNGE_HALF + 18.0 and v.dot(aim) > -20.0:
			return aim.orthogonal() * (1.0 if v.dot(aim.orthogonal()) >= 0.0 else -1.0)
	if state == "pull" and v.length() < 150.0:
		return v.normalized()
	if state == "spit" and v.length() < 200.0 and absf(rad_to_deg(aim.angle_to(v))) < SPIT_SPREAD / 2.0 + 10.0:
		return aim.orthogonal()
	return Vector2.ZERO


func _zones() -> void:
	draw_arc(Vector2.ZERO, LUNGE_HALF, 0.0, TAU, 24, Color(1.0, 0.3, 0.2, 0.6), 1.0)
	draw_arc(Vector2.ZERO, MAW_R, 0.0, TAU, 24, Color(1.0, 0.6, 0.2, 0.5), 1.0)


func _draw() -> void:
	# avvisi a terra
	for tl in tails:
		var at: Vector2 = tl[0]
		var left: float = tl[1]
		if at == Vector2.INF:
			continue
		var lp := to_local(at)
		if left > 0.0:
			Enemy.warn_circle(self, lp, TAIL_R, 1.0 - left / TAIL_WARN)
			draw_circle(lp, TAIL_R * (0.25 + 0.55 * (1.0 - left / TAIL_WARN)), Color(0, 0, 0, 0.35))
		else:
			# la coda a terra per un istante
			var a := clampf(1.0 + left / 0.4, 0.0, 1.0)
			draw_line(lp + Vector2(-TAIL_R * 0.8, -6), lp + Vector2(TAIL_R * 0.8, 6), Color(0.05, 0.03, 0.07, a), 22.0)
			draw_line(lp + Vector2(-TAIL_R * 0.8, -6), lp + Vector2(TAIL_R * 0.8, 6), Color(0.26, 0.12, 0.34, a), 17.0)
	if state == "lunge_warn":
		var total := LUNGE_WARN2 if second_lunge else LUNGE_WARN
		Enemy.warn_strip(self, Vector2.ZERO, aim, LUNGE_LEN + LUNGE_HALF, LUNGE_HALF, 1.0 - st / total)
	if state == "pull_warn" or state == "pull":
		var k := 1.0 - st / PULL_WARN if state == "pull_warn" else 1.0
		Enemy.warn_circle(self, Vector2.ZERO, MAW_R, k)
		if state == "pull":
			# l'acqua (e tu) che viene risucchiata: linee che corrono verso la bocca
			for i in range(14):
				var a := seed_offset + TAU * i / 14.0 + sin(t + i) * 0.2
				var r := 230.0 - fmod(t * 190.0 + i * 37.0, 200.0)
				var dv := Vector2.from_angle(a)
				draw_line(dv * r, dv * (r - 16.0), Color(0.55, 0.75, 1.0, 0.45 * clampf(r / 200.0, 0.2, 1.0)), 1.4)
	if state == "spit":
		for i in range(2):
			var edge := aim.rotated(deg_to_rad(SPIT_SPREAD / 2.0 * (1.0 if i == 0 else -1.0)))
			draw_line(aim * 22.0, aim * 22.0 + edge * 200.0, Color(WARN, 0.6), 1.5)
	if Run.show_zones():
		_draw_zones()
	_draw_serpent(flash_t > 0.0)
	if burn_t > 0.0:
		draw_circle(Vector2.ZERO, radius + 4.0, Color(1, 0.5, 0.1, 0.25))


## Il corpo: le spire seguono la testa (le posizioni passate), grosse al collo e sottili in coda, nere
## con le scaglie viola e il ventre rosso sangue. La testa: larga, piatta, occhi gialli che diventano
## rossi negli avvisi, bocca che si spalanca (zanne, gola rossa).
func _draw_serpent(flash: bool) -> void:
	var base := _f(Color(0.09, 0.06, 0.12), flash)
	var scale_c := _f(Color(0.3, 0.14, 0.42) if not enraged else Color(0.45, 0.12, 0.3), flash)
	var belly := _f(Color(0.62, 0.12, 0.14), flash)
	var n := trail.size()
	# ombra unica sotto tutto il corpo
	for i in range(n - 1, -1, -3):
		var q0: Vector2 = trail[i] - global_position
		draw_circle(q0 + Vector2(0, 5), lerpf(15.0, 4.0, i / float(n)), Color(0, 0, 0, 0.22))
	for i in range(n - 1, -1, -1):
		var q: Vector2 = trail[i] - global_position
		var k := i / float(n)
		var r := lerpf(14.5, 3.5, k) * (1.0 + 0.05 * sin(t * 3.0 + i * 0.6))
		draw_circle(q, r + 1.2, OUT)
		draw_circle(q, r, base)
		if i % 2 == 0:
			draw_arc(q, r * 0.72, t * 0.3 + i, t * 0.3 + i + PI, 8, scale_c, maxf(1.0, r * 0.22))
		if i % 5 == 0 and r > 6.0:
			draw_circle(q + Vector2(0, r * 0.3), r * 0.3, belly)
	# testa
	var o := aim.orthogonal()
	var back := -aim * (10.0 if state == "lunge_warn" else 0.0)
	var gape := mouth * 13.0
	if mouth > 0.05:
		# gola
		draw_colored_polygon(PackedVector2Array([back + aim * 6.0 + o * (6.0 + gape), back + aim * 30.0, back + aim * 6.0 - o * (6.0 + gape)]), Color(0.7, 0.1, 0.12))
	for s in [-1.0, 1.0]:
		var sd: Vector2 = o * s
		var jaw := PackedVector2Array([back - aim * 12.0 + sd * 3.0, back - aim * 8.0 + sd * 17.0, back + aim * 10.0 + sd * (15.0 + gape * 0.6),
			back + aim * 31.0 + sd * (2.0 + gape), back + aim * 10.0 + sd * (1.0 + gape * 0.5), back - aim * 12.0])
		draw_colored_polygon(jaw, base)
		var cl := jaw.duplicate()
		cl.append(jaw[0])
		draw_polyline(cl, OUT, 1.2)
		# zanna
		if mouth > 0.2:
			var f0 := back + aim * 24.0 + sd * (2.5 + gape * 0.9)
			draw_colored_polygon(PackedVector2Array([f0, f0 + aim * 2.5 - sd * 1.0, f0 - sd * 7.0 * mouth - aim * 1.0]), Color(0.97, 0.95, 0.88))
		# occhio
		var warn: bool = state.ends_with("_warn") or state == "lunge" or state == "pull"
		var ec := back + aim * 8.0 + sd * 10.5
		draw_circle(ec, 4.2, OUT)
		draw_circle(ec, 3.4, Color(1.0, 0.25, 0.12) if warn else Color(1.0, 0.82, 0.2))
		draw_line(ec - aim * 2.6, ec + aim * 2.6, Color(0.05, 0.02, 0.05), 1.4)
		if enraged:
			draw_circle(ec, 6.0, Color(1.0, 0.3, 0.2, 0.18 + 0.1 * sin(t * 8.0)))
		# cresta di scaglie
		draw_line(back - aim * 6.0 + sd * 12.0, back + aim * 16.0 + sd * 8.0, scale_c, 1.6)
	draw_line(back - aim * 10.0, back + aim * 20.0, scale_c, 2.0)
	if state == "stuck":
		for i in range(3):
			var sa := t * 4.0 + i * TAU / 3.0
			UiStyle.star4(self, Vector2(cos(sa) * 18.0, -24.0 + sin(sa) * 4.0), 2.4, Color(1, 0.9, 0.5))
