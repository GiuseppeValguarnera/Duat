extends Enemy
## APOPI, il serpente del caos: il boss del Banco di Apopi (la settima ora). Nel Libro dell'Amduat beve
## l'acqua del fiume per arenare la barca di Ra sul suo banco di sabbia; non può essere ucciso, solo
## legato, ogni notte: Serket lo lega, i coltelli lo tagliano.
##
## È un MURO (riscritto il 15/11): va studiato. La regola che regge tutto lo scontro:
##   le SCAGLIE non si aprono (i colpi fanno il 55%). Sul banco ci sono 4 PALI DI SERKET: se il suo
##   AFFONDO finisce contro un palo, la corda lo LEGA per 3,2 s e i colpi fanno il 170%. Quando la
##   striscia rossa dell'affondo passa su un palo, il palo BRILLA: mettiti dietro un palo e aspettalo.
##   Un palo serve una volta; ricrescono a ogni cambio di fase. Se manca il palo, sbatte e si riprende subito.
##   Blocco 22: ogni legatura toglie al massimo il 9% della vita (poi la corda si sfilaccia e schiocca),
##   e la vita non scende sotto il 66% / il 33% senza almeno 2 legature in quella fase. In fase 3 la coda
##   e l'anello spezzano i pali che prendono (rossi 1 s prima, al massimo 2 per fase).
## Tre fasi (a 66% e 33% della vita: ruggito, pali nuovi, mosse nuove):
##   1 «Il banco»: AFFONDO · CODA (cerchio dove sei) · BEVE IL FIUME (ti risucchia, poi SPUTA un ventaglio)
##     · FIGLI (due serpi).
##   2 «Le spire»: + STRETTA (un anello di spire si allarga dalla testa: ha un VARCO segnato d'oro,
##     si passa di lì o con lo scatto) · due affondi di fila · due code.
##   3 «La notte»: + SGUARDO (un cono: chi ci resta dentro è INCANTATO, lento per 2 s) · il BUIO a
##     intervalli · due anelli con varchi diversi · tre code · risucchio più forte.
## Tutte le mosse hanno l'avviso con le misure vere. Costanti qui sotto.

signal summon(kinds: Array)        # il gioco lo collega a ogni boss: fa uscire i Figli di Apopi

const BoltScript := preload("res://scripts/enemy_bolt.gd")

const HP := 2800.0
const ARMOR := 0.35                 ## le scaglie: quanto passa di un colpo quando non è legato
const BOUND_MULT := 1.4             ## legato a un palo
const BOUND_TIME := 2.6
## Blocco 22: lo scontro si misura in LEGATURE, non nel danno della build.
const BIND_CAP := 0.09              ## ogni legatura toglie al massimo il 9% della vita massima; poi la corda cede
const PHASE_BINDS := [2, 2]         ## legature da fare prima che la vita possa scendere sotto il 66% / il 33%
const FRAY_TIME := 0.6              ## la corda si sfilaccia (avviso), poi schiocca
const SNAP_R := 44.0                ## lo schiocco della corda attorno alla testa
const SNAP_DMG := 8.0
const STAKE_BREAKS := 2             ## pali che coda e anello possono spezzare, per fase (solo in fase 3)
const PHASES := [0.66, 0.33]
const LUNGE_WARN := 0.75
const LUNGE_WARN2 := 0.5
const LUNGE_LEN := 420.0
const LUNGE_SPEED := 540.0
const LUNGE_HALF := 22.0
const LUNGE_DMG := 20.0
const MISS_REST := 0.7              ## se non c'è il palo: sbatte e si riprende in fretta
const PULL_WARN := 0.8
const PULL_TIME := 2.4
const PULL_SPEED := 80.0
const PULL_SPEED3 := 100.0
const MAW_R := 34.0
const MAW_DMG := 7.0
const MAW_TICK := 0.4
const SPIT_N := 5
const SPIT_SPREAD := 80.0
const SPIT_SPEED := 170.0
const SPIT_DMG := 7.0
const TAIL_WARN := 1.0
const TAIL_GAP := 0.45
const TAIL_R := 46.0
const TAIL_DMG := 18.0
const RING_WARN := 0.9
const RING_SPEED := 135.0
const RING_MAX := 430.0
const RING_THICK := 9.0
const RING_GAP := 30.0              ## mezza apertura del varco, in gradi
const RING_DMG := 16.0
const GAZE_WARN := 1.1
const GAZE_HALF := 26.0             ## mezza apertura del cono, in gradi
const GAZE_RANGE := 250.0
const GAZE_DMG := 8.0
const GAZE_SLOW := 2.0              ## secondi di incanto (cammini al 45%)
const BROOD_MAX := 2
const BROOD_CD := 14.0
const DARK_ON := 5.0
const DARK_OFF := 10.0
const HOVER := 118.0                ## quanto sta lontano da te mentre ti studia
const STAKE_AT := [Vector2(-120, -56), Vector2(120, -56), Vector2(-120, 60), Vector2(120, 60)]

var state := "intro"
var st := 1.8
var aim := Vector2.DOWN
var phase := 1
var arena := Rect2()
var trail: Array[Vector2] = []
var lunge_left := 0.0
var lunge_hit := false
var lunges_left := 0
var maw_cd := 0.0
var tails: Array = []               ## [posizione, secondi all'impatto]
var rings: Array = []               ## [origine, raggio, angolo del varco, colpito]
var ring_gaps: Array = []           ## i varchi degli anelli in preparazione
var brood_cd := 7.0
var last_move := ""
var dark: Chaos.Darkness = null
var dark_t := 3.0
var dark_on := false
var mouth := 0.0
var stakes: Array = []
var scale_txt := 0.0
var gaze_dir := Vector2.DOWN
var bind_hp0 := 0.0                 ## la vita quando la corda l'ha preso
var binds_phase := 0                ## legature fatte in questa fase
var breaks_phase := 0               ## pali spezzati (o condannati) in questa fase
var gate_txt := 0.0


func _ready() -> void:
	is_boss = true
	max_hp = HP * (1.0 + 0.1 * Weights.rank("piombo"))
	super._ready()
	for i in range(46):
		trail.append(global_position + Vector2(0, -i * 7.0))
	_plant_stakes.call_deferred()


func _plant_stakes() -> void:
	var c := arena.get_center() if arena.size != Vector2.ZERO else global_position + Vector2(0, 110)
	for off in STAKE_AT:
		var s := Chaos.Stake.new()
		s.position = c + off
		get_parent().add_child(s)
		stakes.append(s)


func _alive_stakes() -> Array:
	return stakes.filter(func(s) -> bool: return is_instance_valid(s) and s.alive and s.grow >= 1.0)


## Il palo che l'affondo (da `from` verso `dir`) colpirebbe, o null.
func _stake_on_line(from: Vector2, dir: Vector2):
	var best = null
	var best_d := LUNGE_LEN + 30.0
	for s in _alive_stakes():
		var v: Vector2 = s.global_position - from
		var along := v.dot(dir)
		if along > 10.0 and along < best_d and absf(v.dot(dir.orthogonal())) < LUNGE_HALF + 6.0:
			best_d = along
			best = s
	return best


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta
	brood_cd -= delta
	scale_txt = maxf(0.0, scale_txt - delta)
	gate_txt = maxf(0.0, gate_txt - delta)
	# le due regole del blocco 22, tenute sulla VITA (così valgono anche per bruciature e veleni):
	# la soglia di fase e il tetto della legatura
	if phase <= PHASES.size() and binds_phase < int(PHASE_BINDS[phase - 1]):
		hp = maxf(hp, max_hp * float(PHASES[phase - 1]) + 1.0)
	if state == "bound" and bind_hp0 - hp >= max_hp * BIND_CAP - 0.5:
		hp = bind_hp0 - max_hp * BIND_CAP
		_fray()
	maw_cd = maxf(0.0, maw_cd - delta)
	_update_tails(delta)
	_update_rings(delta)
	_update_dark(delta)
	_update_trail()
	var want_mouth := 1.0 if state in ["pull_warn", "pull", "spit"] else (0.5 if state.begins_with("lunge") else 0.0)
	mouth = move_toward(mouth, want_mouth, delta * 3.0)
	for s in stakes:
		if is_instance_valid(s):
			s.lit = false
	if state == "lunge_warn":
		var hit_s = _stake_on_line(global_position, aim)
		if hit_s != null:
			hit_s.lit = true
	if phase <= PHASES.size() and hp < max_hp * float(PHASES[phase - 1]) and state in ["hover", "recover", "bound", "tail"]:
		_next_phase()
		return Vector2.ZERO
	if to == Vector2.ZERO:
		return Vector2.ZERO
	var d := to.length()
	var u := to / d
	var p = get_tree().get_first_node_in_group("player")
	match state:
		"intro", "roar":
			if st <= 0.0:
				_next(1.0)
			return Vector2.ZERO
		"hover":
			aim = u
			if st <= 0.0:
				_choose(d)
				return Vector2.ZERO
			var radial := u * clampf((d - HOVER) / 40.0, -1.0, 1.0)
			return (radial + u.orthogonal() * _side * 0.8).normalized() * speed * (1.0 + 0.12 * (phase - 1))
		"lunge_warn":
			var total := LUNGE_WARN if lunges_left == _lunge_count() else LUNGE_WARN2
			if st > total * 0.5:
				aim = u
			if st <= 0.0:
				state = "lunge"
				lunge_left = LUNGE_LEN
				lunge_hit = false
				lunges_left -= 1
				Sfx.play_at("serpent_strike", global_position, 0.05)
				Fx.shake(4.0)
			return -aim * 26.0
		"lunge":
			if not lunge_hit and p != null and touches(p, LUNGE_HALF - PLAYER_R - TOUCH_PAD):
				lunge_hit = p.take_damage(LUNGE_DMG, global_position, self)
			for s in _alive_stakes():
				if s.global_position.distance_to(global_position) < LUNGE_HALF + 8.0:
					_bind(s)
					return Vector2.ZERO
			lunge_left -= LUNGE_SPEED * delta
			var hit_wall := false
			for i in range(get_slide_collision_count()):
				var col := get_slide_collision(i)
				if col.get_collider() is StaticBody2D and aim.dot(col.get_normal()) < -0.5:
					hit_wall = true
			if lunge_left <= 0.0 or hit_wall or not _inside(global_position + aim * 26.0):
				Fx.shake(6.0)
				Sfx.play_at("amheh_land", global_position, 0.1)
				Fx.burst(global_position + aim * 16.0, Color(0.55, 0.45, 0.4), 18, 150.0)
				if lunges_left > 0:
					state = "lunge_warn"
					st = LUNGE_WARN2
					Sfx.play_at("serpent_hiss", global_position, 0.1)
					return Vector2.ZERO
				state = "recover"
				st = MISS_REST
				return Vector2.ZERO
			return aim * LUNGE_SPEED
		"fray":
			if st <= 0.0:
				# la corda schiocca: chi è rimasto addosso alla testa prende la frustata
				Fx.shake(7.0)
				Sfx.play_at("hit", global_position, 0.2)
				Sfx.play_at("serpent_hiss", global_position, 0.1)
				Fx.burst(global_position, Color(1.0, 0.85, 0.4), 22, 170.0)
				if p != null and not p.dead and d < SNAP_R:
					p.take_damage(SNAP_DMG, global_position, null, "corda")
				_next(0.9)
			return Vector2.ZERO
		"bound":
			if st <= 0.0:
				Fx.burst(global_position, Color(0.94, 0.72, 0.3), 16, 120.0)
				Sfx.play_at("serpent_hiss", global_position, 0.1)
				_next(0.9)
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
				var v := PULL_SPEED3 if phase >= 3 else PULL_SPEED
				if p.dash_t <= 0.0:
					p.move_and_collide(-u * v * delta)
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
				st = 1.0
			return Vector2.ZERO
		"tail":
			if st <= 0.0:
				state = "recover"
				st = 0.4
			return (u.orthogonal() * _side).normalized() * speed * 0.5
		"ring_warn":
			if st <= 0.0:
				for ga in ring_gaps:
					rings.append([global_position, 20.0, float(ga), false])
					break
				ring_gaps.pop_front()
				Sfx.play_at("dash", global_position, 0.05)
				Fx.shake(5.0)
				if ring_gaps.is_empty():
					state = "recover"
					st = 1.0
				else:
					st = RING_WARN * 0.8
			return Vector2.ZERO
		"gaze_warn":
			if st > GAZE_WARN * 0.4:
				gaze_dir = u
			if st <= 0.0:
				_gaze_flash()
				state = "recover"
				st = 0.9
			return Vector2.ZERO
		"recover":
			if st <= 0.0:
				_next(randf_range(0.6, 1.0) / (1.0 + 0.15 * (phase - 1)))
			return Vector2.ZERO
	return Vector2.ZERO


func _inside(p: Vector2) -> bool:
	return arena.size == Vector2.ZERO or arena.grow(-6.0).has_point(p)


func _next(time: float) -> void:
	state = "hover"
	st = time
	if randf() < 0.5:
		_side = -_side


func _lunge_count() -> int:
	return 1 if phase == 1 else 2


## La corda ha dato tutto quello che poteva (il 9% della vita): si sfilaccia e poi schiocca.
func _fray() -> void:
	if state == "fray":
		return
	state = "fray"
	st = FRAY_TIME
	Sfx.play_at("scorpion_windup", global_position, 0.3)
	Fx.float_text(global_position + Vector2(0, -44), Lang.t("LA CORDA CEDE"), Color(1.0, 0.6, 0.4))


func _bind(s) -> void:
	s.spend()
	state = "bound"
	st = BOUND_TIME
	bind_hp0 = hp
	binds_phase += 1
	lunges_left = 0
	Fx.shake(9.0)
	Fx.hitstop(0.08)
	Sfx.play("amheh_land", 0.0)
	Sfx.play("divine", 0.0)
	Fx.float_text(global_position + Vector2(0, -44), Lang.t("LEGATO!"), Color(1.0, 0.85, 0.4))


func _next_phase() -> void:
	phase += 1
	binds_phase = 0
	breaks_phase = 0
	state = "roar"
	st = 2.0
	tails.clear()
	ring_gaps.clear()
	Fx.shake(12.0)
	Sfx.play("roar", 0.0)
	for s in stakes:
		if is_instance_valid(s):
			s.doomed = false
			if not s.alive:
				s.regrow()
	var g = get_tree().current_scene
	if phase == 2:
		if g != null and g.has_method("_banner"):
			g._banner(Lang.t("Le spire di Apopi"), Lang.t("I pali di Serket sono tornati. Nell'anello di spire cerca il varco d'oro"), Color(0.75, 0.5, 1.0), 3.0)
	else:
		if g != null and g.has_method("_banner"):
			g._banner(Lang.t("Apopi inghiotte la luce"), Lang.t("Il buio va e viene. Non restare nel cono del suo sguardo"), Color(0.7, 0.4, 1.0), 3.0)
		dark = Chaos.Darkness.new()
		get_parent().add_child(dark)
		dark_t = 2.5
		dark_on = false
		z_index = 6                       # sopra il buio: lui e i suoi avvisi si vedono sempre
		for s in stakes:
			if is_instance_valid(s):
				s.z_index = 6


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
		brood_cd = BROOD_CD
		var kinds := []
		for i in range(BROOD_MAX - brood):
			kinds.append("apep_spawn")
		summon.emit(kinds)
		Sfx.play_at("cobra_hiss", global_position, 0.1)
		Fx.float_text(global_position + Vector2(0, -44), Lang.t("I FIGLI DI APOPI"), Color(0.75, 0.45, 1.0))
		_next(0.7)
		return
	var opts := ["lunge", "lunge", "tail", "pull"]
	if phase >= 2:
		opts.append("ring")
		opts.append("ring")
	if phase >= 3:
		opts.append("gaze")
		opts.append("gaze")
	if d < 60.0:
		opts.append("tail")
	opts = opts.filter(func(o) -> bool: return o != last_move)
	var m: String = opts.pick_random()
	last_move = m
	match m:
		"lunge":
			state = "lunge_warn"
			st = LUNGE_WARN
			lunges_left = _lunge_count()
			Sfx.play_at("serpent_hiss", global_position, 0.05)
		"pull":
			state = "pull_warn"
			st = PULL_WARN
			Sfx.play_at("amheh_growl", global_position, 0.05)
			Fx.float_text(global_position + Vector2(0, -44), Lang.t("APOPI BEVE IL FIUME"), Color(0.6, 0.8, 1.0))
		"tail":
			state = "tail"
			var n := phase
			st = TAIL_WARN + TAIL_GAP * (n - 1) + 0.2
			tails.clear()
			for i in range(n):
				tails.append([Vector2.INF, TAIL_WARN + TAIL_GAP * i])
			Sfx.play_at("serpent_burrow", global_position, 0.1)
		"ring":
			state = "ring_warn"
			st = RING_WARN
			ring_gaps.clear()
			var p = get_tree().get_first_node_in_group("player")
			var base := randf() * TAU
			if p != null:
				# il primo varco mai proprio addosso a te, né dalla parte opposta: a un quarto di giro
				base = (p.global_position - global_position).angle() + (PI * 0.5 if randf() < 0.5 else -PI * 0.5)
			ring_gaps.append(base)
			if phase >= 3:
				ring_gaps.append(base + PI * randf_range(0.6, 1.0))
			Sfx.play_at("serpent_hiss", global_position, 0.05)
			Fx.float_text(global_position + Vector2(0, -44), Lang.t("LA STRETTA"), Color(0.9, 0.5, 0.5))
		"gaze":
			state = "gaze_warn"
			st = GAZE_WARN
			gaze_dir = aim
			Sfx.play_at("soul", global_position, 0.05)
			Fx.float_text(global_position + Vector2(0, -44), Lang.t("LO SGUARDO"), Color(0.85, 0.5, 1.0))


func _update_tails(delta: float) -> void:
	var p = get_tree().get_first_node_in_group("player")
	for tl in tails:
		var before: float = tl[1]
		tl[1] = before - delta
		var at: Vector2 = tl[0]
		if at == Vector2.INF and float(tl[1]) <= TAIL_WARN and p != null:
			tl[0] = p.global_position          # il cerchio si ferma dove sei quando parte il SUO avviso
			at = tl[0]
			# fase 3: la coda spezza il palo che ha sotto. Il palo diventa rosso adesso, 1 s prima:
			# non farti prendere dalla coda vicino a un palo che ti serve
			if phase >= 3:
				for s in _alive_stakes():
					if not s.doomed and breaks_phase < STAKE_BREAKS and s.global_position.distance_to(at) < TAIL_R:
						s.doomed = true
						breaks_phase += 1
		if before > 0.0 and float(tl[1]) <= 0.0 and at != Vector2.INF:
			Fx.shake(8.0)
			Fx.burst(at, Color(0.35, 0.2, 0.45), 26, 170.0)
			Sfx.play_at("amheh_land", at, 0.15)
			if p != null and not p.dead and p.global_position.distance_to(at) < TAIL_R:
				p.take_damage(TAIL_DMG, at, self)
			for s in stakes:
				if is_instance_valid(s) and s.alive and s.doomed and s.global_position.distance_to(at) < TAIL_R + 2.0:
					s.shatter()
			var pool := Chaos.Isfet.new()
			pool.r = 20.0
			pool.life = 4.0
			get_parent().add_child(pool)
			pool.global_position = at
	tails = tails.filter(func(x) -> bool: return float(x[1]) > -0.4)


## Gli anelli di spire: si allargano dall'origine; feriscono chi tocca la fascia fuori dal varco.
func _update_rings(delta: float) -> void:
	var p = get_tree().get_first_node_in_group("player")
	for rg in rings:
		rg[1] = float(rg[1]) + RING_SPEED * delta
		# fase 3: l'anello spezza i pali che incontra fuori dal varco (rossi da 1 s prima, al massimo 2 per fase)
		if phase >= 3:
			for s in stakes:
				if not is_instance_valid(s) or not s.alive:
					continue
				var sv: Vector2 = s.global_position - rg[0]
				if absf(angle_difference(sv.angle(), float(rg[2]))) <= deg_to_rad(RING_GAP):
					continue
				var ahead := sv.length() - float(rg[1])
				if not s.doomed and breaks_phase < STAKE_BREAKS and ahead > 0.0 and ahead <= RING_SPEED * 1.0:
					s.doomed = true
					breaks_phase += 1
				elif s.doomed and absf(ahead) < RING_THICK:
					s.shatter()
		if p == null or p.dead or rg[3]:
			continue
		var v: Vector2 = p.global_position - rg[0]
		if absf(v.length() - float(rg[1])) < RING_THICK and absf(angle_difference(v.angle(), float(rg[2]))) > deg_to_rad(RING_GAP):
			if p.dash_t <= 0.0 and p.take_damage(RING_DMG, rg[0], self):
				rg[3] = true
	rings = rings.filter(func(x) -> bool: return float(x[1]) < RING_MAX)


func _gaze_flash() -> void:
	Sfx.play("divine", -4.0)
	Fx.shake(5.0)
	var p = get_tree().get_first_node_in_group("player")
	if p == null or p.dead:
		return
	var v: Vector2 = p.global_position - global_position
	if v.length() < GAZE_RANGE and absf(rad_to_deg(gaze_dir.angle_to(v))) < GAZE_HALF:
		if p.take_damage(GAZE_DMG, global_position, self):
			p.charm_t = GAZE_SLOW
			Fx.float_text(p.global_position + Vector2(0, -30), Lang.t("INCANTATO"), Color(0.85, 0.5, 1.0))


func _spit() -> void:
	Sfx.play_at("cobra_spit", global_position, 0.1)
	var n := SPIT_N + (2 if phase >= 3 else 0)
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
	if state == "intro" or state == "roar" or state == "fray":
		return                              # mentre la corda cede il danno non conta più
	var k := BOUND_MULT if state == "bound" else ARMOR
	var amount := dmg * k
	if state == "bound":
		amount = minf(amount, maxf(0.0, max_hp * BIND_CAP - (bind_hp0 - hp)))
	elif phase <= PHASES.size() and binds_phase < int(PHASE_BINDS[phase - 1]):
		# la soglia di fase: senza le legature della fase la vita non scende oltre
		var floor_hp := max_hp * float(PHASES[phase - 1]) + 1.0
		amount = minf(amount, maxf(0.0, hp - floor_hp))
		if amount <= 0.0:
			if gate_txt <= 0.0 and not dead:
				gate_txt = 1.6
				Fx.float_text(global_position + Vector2(0, -34), Lang.t("SOLO LA CORDA LO FERISCE"), Color(1.0, 0.85, 0.4))
			return
	if state != "bound" and scale_txt <= 0.0 and not dead:
		scale_txt = 1.6
		Fx.float_text(global_position + Vector2(0, -34), Lang.t("SCAGLIE"), Color(0.7, 0.7, 0.8))
	if amount <= 0.0:
		return
	super.take_hit(amount, dir, 0.0, can_burn)


func _stagger_time() -> float:
	return 0.0


func _contact_damage() -> float:
	return 0.0


func die() -> void:
	if dark != null and is_instance_valid(dark):
		dark.target = 0.0
		get_tree().create_timer(1.5, false).timeout.connect(dark.queue_free)
	for s in stakes:
		if is_instance_valid(s):
			s.queue_free()
	super.die()


## Per i bot: dove mettersi per far finire l'affondo contro un palo (dietro il palo più vicino,
## visto dalla testa). Vector2.INF = niente da fare.
func bot_bait(pos: Vector2) -> Vector2:
	if state not in ["hover", "lunge_warn"]:
		return Vector2.INF
	var best := Vector2.INF
	var best_d := 1e9
	for s in _alive_stakes():
		var away: Vector2 = (s.global_position - global_position).normalized()
		var spot: Vector2 = s.global_position + away * 34.0
		if not _inside(spot):
			continue
		var dd := pos.distance_to(spot)
		if dd < best_d:
			best_d = dd
			best = spot
	return best


func bot_escape(pos: Vector2) -> Vector2:
	for tl in tails:
		var at: Vector2 = tl[0]
		if at != Vector2.INF and float(tl[1]) > 0.0 and pos.distance_to(at) < TAIL_R + 10.0:
			return (pos - at).normalized() if pos != at else Vector2.RIGHT
	var v := pos - global_position
	for rg in rings:
		var rv: Vector2 = pos - rg[0]
		var gap_dir := Vector2.from_angle(float(rg[2]))
		if rv.length() > float(rg[1]) - 10.0 and rv.length() - float(rg[1]) < 90.0 and absf(angle_difference(rv.angle(), float(rg[2]))) > deg_to_rad(RING_GAP * 0.6):
			# verso il varco, girando attorno all'origine
			var want: Vector2 = rg[0] + gap_dir * maxf(rv.length(), 40.0)
			return (want - pos).normalized()
	if state == "ring_warn" and not ring_gaps.is_empty():
		var want2: Vector2 = global_position + Vector2.from_angle(float(ring_gaps[0])) * maxf(v.length(), 60.0)
		if pos.distance_to(want2) > 14.0:
			return (want2 - pos).normalized()
	if state == "gaze_warn" and v.length() < GAZE_RANGE + 10.0 and absf(rad_to_deg(gaze_dir.angle_to(v))) < GAZE_HALF + 8.0:
		return gaze_dir.orthogonal() * (1.0 if v.dot(gaze_dir.orthogonal()) >= 0.0 else -1.0)
	if state == "lunge":
		if absf(v.dot(aim.orthogonal())) < LUNGE_HALF + 18.0 and v.dot(aim) > -20.0:
			return aim.orthogonal() * (1.0 if v.dot(aim.orthogonal()) >= 0.0 else -1.0)
	if state == "lunge_warn" and st < 0.3 and _stake_on_line(global_position, aim) == null:
		if absf(v.dot(aim.orthogonal())) < LUNGE_HALF + 18.0 and v.dot(aim) > -20.0:
			return aim.orthogonal() * (1.0 if v.dot(aim.orthogonal()) >= 0.0 else -1.0)
	if state == "lunge_warn" and st < 0.22:
		# il palo è sulla linea: all'ultimo ci si toglie di lato, il serpente va dritto
		if absf(v.dot(aim.orthogonal())) < LUNGE_HALF + 14.0 and v.dot(aim) > -20.0:
			return aim.orthogonal() * (1.0 if v.dot(aim.orthogonal()) >= 0.0 else -1.0)
	if state == "fray" and v.length() < SNAP_R + 12.0:
		return v.normalized() if v != Vector2.ZERO else Vector2.RIGHT
	if state == "pull" and v.length() < 150.0:
		return v.normalized()
	if state == "spit" and v.length() < 200.0 and absf(rad_to_deg(aim.angle_to(v))) < SPIT_SPREAD / 2.0 + 10.0:
		return aim.orthogonal()
	return Vector2.ZERO


func _zones() -> void:
	draw_arc(Vector2.ZERO, LUNGE_HALF, 0.0, TAU, 24, Color(1.0, 0.3, 0.2, 0.6), 1.0)
	draw_arc(Vector2.ZERO, MAW_R, 0.0, TAU, 24, Color(1.0, 0.6, 0.2, 0.5), 1.0)


func _ring_points(origin: Vector2, r: float, gap: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var g := deg_to_rad(RING_GAP)
	var n := 56
	for i in range(n + 1):
		var a := gap + g + (TAU - 2.0 * g) * i / n
		pts.append(to_local(origin + Vector2.from_angle(a) * r))
	return pts


func _draw() -> void:
	# --- avvisi a terra
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
			var a := clampf(1.0 + left / 0.4, 0.0, 1.0)
			draw_line(lp + Vector2(-TAIL_R * 0.8, -6), lp + Vector2(TAIL_R * 0.8, 6), Color(0.05, 0.03, 0.07, a), 22.0)
			draw_line(lp + Vector2(-TAIL_R * 0.8, -6), lp + Vector2(TAIL_R * 0.8, 6), Color(0.26, 0.12, 0.34, a), 17.0)
	if state == "lunge_warn":
		var total := LUNGE_WARN if lunges_left == _lunge_count() else LUNGE_WARN2
		Enemy.warn_strip(self, Vector2.ZERO, aim, LUNGE_LEN + LUNGE_HALF, LUNGE_HALF, 1.0 - st / total)
		var hs = _stake_on_line(global_position, aim)
		if hs != null:
			# la linea d'oro fino al palo: «qui si lega»
			draw_line(Vector2.ZERO, to_local(hs.global_position), Color(1.0, 0.85, 0.4, 0.85), 2.0)
	if state == "pull_warn" or state == "pull":
		var k := 1.0 - st / PULL_WARN if state == "pull_warn" else 1.0
		Enemy.warn_circle(self, Vector2.ZERO, MAW_R, k)
		if state == "pull":
			for i in range(14):
				var a2 := seed_offset + TAU * i / 14.0 + sin(t + i) * 0.2
				var r := 230.0 - fmod(t * 190.0 + i * 37.0, 200.0)
				var dv := Vector2.from_angle(a2)
				draw_line(dv * r, dv * (r - 16.0), Color(0.55, 0.75, 1.0, 0.45 * clampf(r / 200.0, 0.2, 1.0)), 1.4)
	if state == "spit":
		for i in range(2):
			var edge := aim.rotated(deg_to_rad(SPIT_SPREAD / 2.0 * (1.0 if i == 0 else -1.0)))
			draw_line(aim * 22.0, aim * 22.0 + edge * 200.0, Color(WARN, 0.6), 1.5)
	# la stretta in preparazione: un anello sottile attorno alla testa e il VARCO d'oro, lungo fin dove serve
	if state == "ring_warn" and not ring_gaps.is_empty():
		var k2 := 1.0 - st / RING_WARN
		var ga: float = ring_gaps[0]
		draw_polyline(_ring_points(global_position, 26.0 + 10.0 * k2, ga), Color(WARN, 0.5 + 0.4 * k2), 2.0)
		var g := deg_to_rad(RING_GAP)
		var fan := PackedVector2Array([Vector2.ZERO])
		for i in range(9):
			fan.append(Vector2.from_angle(ga - g + 2.0 * g * i / 8.0) * 300.0)
		draw_colored_polygon(fan, Color(1.0, 0.85, 0.4, 0.1 + 0.08 * k2))
		draw_line(Vector2.ZERO, Vector2.from_angle(ga - g) * 300.0, Color(1.0, 0.85, 0.4, 0.7), 1.2)
		draw_line(Vector2.ZERO, Vector2.from_angle(ga + g) * 300.0, Color(1.0, 0.85, 0.4, 0.7), 1.2)
	# gli anelli in corsa: una fascia di spire con le scaglie, il varco resta vuoto e segnato
	for rg in rings:
		var rr: float = rg[1]
		var fade := clampf((RING_MAX - rr) / 80.0, 0.0, 1.0)
		var pts := _ring_points(rg[0], rr, float(rg[2]))
		draw_polyline(pts, Color(0.04, 0.02, 0.06, fade), RING_THICK * 2.0 + 3.0)
		draw_polyline(pts, Color(0.3, 0.13, 0.4, fade), RING_THICK * 2.0)
		draw_polyline(pts, Color(WARN, 0.75 * fade), 1.6)
		for i in range(0, pts.size(), 3):
			draw_circle(pts[i], 2.4, Color(0.62, 0.14, 0.16, fade))
		draw_circle(pts[0], 4.0, Color(1.0, 0.85, 0.4, fade))
		draw_circle(pts[pts.size() - 1], 4.0, Color(1.0, 0.85, 0.4, fade))
	# lo sguardo: un cono viola che si riempie
	if state == "gaze_warn":
		var k3 := 1.0 - st / GAZE_WARN
		var gz := PackedVector2Array([Vector2.ZERO])
		for i in range(11):
			gz.append(gaze_dir.rotated(deg_to_rad(lerpf(-GAZE_HALF, GAZE_HALF, i / 10.0))) * GAZE_RANGE)
		draw_colored_polygon(gz, Color(0.7, 0.2, 0.9, 0.1 + 0.22 * k3))
		var gin := PackedVector2Array([Vector2.ZERO])
		for i in range(11):
			gin.append(gaze_dir.rotated(deg_to_rad(lerpf(-GAZE_HALF, GAZE_HALF, i / 10.0))) * GAZE_RANGE * k3)
		draw_colored_polygon(gin, Color(WARN, 0.16 + 0.14 * k3))
		gz.append(Vector2.ZERO)
		draw_polyline(gz, Color(WARN, 0.6 + 0.3 * k3), 1.5)
	if Run.show_zones():
		_draw_zones()
	_draw_serpent(flash_t > 0.0)
	if burn_t > 0.0:
		draw_circle(Vector2.ZERO, radius + 4.0, Color(1, 0.5, 0.1, 0.25))


## Il corpo: le spire seguono la testa, grosse al collo e sottili in coda, nere con le scaglie viola e
## il ventre rosso sangue; a ogni fase le scaglie si accendono (viola → cremisi → rosso vivo). La testa:
## larga, piatta, occhi gialli che diventano rossi negli avvisi, bocca che si spalanca. Legato: tre giri
## di corda d'oro sul collo e le stelle sopra la testa.
func _draw_serpent(flash: bool) -> void:
	var base := _f(Color(0.09, 0.06, 0.12), flash)
	var scale_c := _f([Color(0.3, 0.14, 0.42), Color(0.45, 0.12, 0.3), Color(0.7, 0.12, 0.16)][phase - 1], flash)
	var belly := _f(Color(0.62, 0.12, 0.14), flash)
	var n := trail.size()
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
	if state == "bound" or state == "fray":
		# la corda: tre giri d'oro sul collo. Più danno ha già dato, più si assottiglia; quando cede
		# trema, si sfilaccia (fili che volano) e lampeggia di rosso
		var used := clampf((bind_hp0 - hp) / maxf(1.0, max_hp * BIND_CAP), 0.0, 1.0)
		var fray := state == "fray"
		for i in range(3):
			var qi: Vector2 = trail[mini(2 + i * 2, n - 1)] - global_position
			if fray:
				qi += Vector2(sin(t * 60.0 + i * 2.0), cos(t * 53.0 + i)) * 1.5
			var rope := Color(1.0, 0.85, 0.4)
			if fray:
				rope = Color(1.0, 0.35, 0.25) if fmod(t * 12.0, 1.0) < 0.5 else Color(1, 1, 1)
			draw_arc(qi, 15.0, 0.0, TAU, 16, Color(0.12, 0.08, 0.05), 4.0)
			draw_arc(qi, 15.0, 0.0, TAU * (1.0 - 0.25 * used), 16, rope, lerpf(2.6, 1.0, used))
			if fray or used > 0.6:
				for f in range(3):
					var fa := seed_offset + i * 2.1 + f * 1.3
					var f0 := qi + Vector2.from_angle(fa) * 15.0
					draw_line(f0, f0 + Vector2.from_angle(fa + sin(t * 9.0 + f)) * (4.0 + 5.0 * used), rope, 0.9)
		if fray:
			Enemy.warn_circle(self, Vector2.ZERO, SNAP_R, 1.0 - st / FRAY_TIME)
	var o := aim.orthogonal()
	var back := -aim * (10.0 if state == "lunge_warn" else 0.0)
	var gape := mouth * 13.0
	if mouth > 0.05:
		draw_colored_polygon(PackedVector2Array([back + aim * 6.0 + o * (6.0 + gape), back + aim * 30.0, back + aim * 6.0 - o * (6.0 + gape)]), Color(0.7, 0.1, 0.12))
	for s in [-1.0, 1.0]:
		var sd: Vector2 = o * s
		var jaw := PackedVector2Array([back - aim * 12.0 + sd * 3.0, back - aim * 8.0 + sd * 17.0, back + aim * 10.0 + sd * (15.0 + gape * 0.6),
			back + aim * 31.0 + sd * (2.0 + gape), back + aim * 10.0 + sd * (1.0 + gape * 0.5), back - aim * 12.0])
		draw_colored_polygon(jaw, base)
		var cl := jaw.duplicate()
		cl.append(jaw[0])
		draw_polyline(cl, OUT, 1.2)
		if mouth > 0.2:
			var f0 := back + aim * 24.0 + sd * (2.5 + gape * 0.9)
			draw_colored_polygon(PackedVector2Array([f0, f0 + aim * 2.5 - sd * 1.0, f0 - sd * 7.0 * mouth - aim * 1.0]), Color(0.97, 0.95, 0.88))
		var warn: bool = state.ends_with("_warn") or state == "lunge" or state == "pull"
		var ec := back + aim * 8.0 + sd * 10.5
		draw_circle(ec, 4.2, OUT)
		var eye_c := Color(1.0, 0.25, 0.12) if warn else Color(1.0, 0.82, 0.2)
		if state == "gaze_warn":
			eye_c = Color(0.9, 0.5, 1.0)
			draw_circle(ec, 6.0 + 4.0 * (1.0 - st / GAZE_WARN), Color(0.8, 0.4, 1.0, 0.35))
		draw_circle(ec, 3.4, eye_c)
		draw_line(ec - aim * 2.6, ec + aim * 2.6, Color(0.05, 0.02, 0.05), 1.4)
		if phase >= 3:
			draw_circle(ec, 6.0, Color(1.0, 0.3, 0.2, 0.18 + 0.1 * sin(t * 8.0)))
		draw_line(back - aim * 6.0 + sd * 12.0, back + aim * 16.0 + sd * 8.0, scale_c, 1.6)
	draw_line(back - aim * 10.0, back + aim * 20.0, scale_c, 2.0)
	if state == "bound":
		for i in range(3):
			var sa := t * 4.0 + i * TAU / 3.0
			UiStyle.star4(self, Vector2(cos(sa) * 18.0, -24.0 + sin(sa) * 4.0), 2.4, Color(1, 0.9, 0.5))
