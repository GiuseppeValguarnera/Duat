extends Enemy
## Aker, il dio dell'orizzonte: il boss di Sokar (riscritto nel blocco 9). Nei templi è dipinto
## come due leoni schiena contro schiena, Ieri che guarda a ovest e Domani che guarda a est.
##
## FASE 1 — il Leone dell'Orizzonte: un corpo, due teste (sabbia e fuoco), una barra di vita.
## Ti dà la caccia: cammina verso di te e ruota lentamente il corpo per tenerti davanti a una testa.
## Sui FIANCHI i colpi fanno ×1,35, sulle teste ×0,8: girargli intorno è il modo di colpirlo.
## Mosse (avviso 0,5-0,7 s): morso e artigliate (tre colpi che ti seguono), carica dell'orizzonte
## (in linea, scia di sabbie mobili, rimbalza sul muro e ricarica verso di te), soffio doppio
## (sabbia da una testa, fuoco dall'altra, il corpo ruota e i coni spazzano l'arena), balzo (ombra
## a terra, atterraggio e onda d'urto), raggio dell'alba (ruota mentre lui continua a camminare;
## prima il ruggito fa cadere al massimo due pietre, che fermano il raggio e si sgretolano dopo tre
## passaggi). Dalla metà della fase le mosse si legano due a due (pausa 0,5 s); dopo una mossa
## grande c'è la finestra per punirlo (1,2 s).
## Finita la vita della fase 1 trema (1,8 s, invulnerabile) e si divide: Ieri e Domani
## (aker_lion.gd), 500 di vita ciascuno, che attaccano INSIEME. La barra resta una sola.
## Tutti i numeri da tarare sono qui sotto.

@warning_ignore("unused_signal")
signal summon(kinds: Array)        # il gioco lo collega a ogni boss: Aker non chiama rinforzi
signal split(lions: Array)          ## si divide: il gioco aggiunge i due leoni (game.gd)

const LionScene := preload("res://scenes/aker_lion.tscn")

# ---------------------------------------------------------------- numeri da tarare
const HP := 1500.0                    ## la vita della fase 1 (nella scena: max_hp)
const LION_HP := 500.0                ## la vita di Ieri e di Domani (fase 2): in tutto 2500
const WALK := 78.0                    ## passo di caccia (60% della velocità dell'eroe, 130)
const TURN_RATE := 70.0               ## gradi al secondo: girargli intorno a piedi è possibile
const FLANK_MULT := 1.35              ## colpi sui fianchi
const HEAD_MULT := 0.8                ## colpi sulle teste
const HEAD_CONE := 35.0               ## entro quanti gradi dall'asse del corpo si colpisce una testa
const CONTACT := 10.0                 ## toccarlo
const PUNISH := 1.2                   ## la pausa dopo una mossa grande: la finestra per colpirlo
const CHAIN_GAP := 0.5                ## la pausa tra due mosse legate (dalla metà della fase 1)
const CHAIN_FROM := 0.5               ## da quanta vita della fase in giù le mosse si legano
const BITE_WINDUP := [0.6, 0.45, 0.45] ## morso e artigliate: avviso di ognuno dei tre colpi
const BITE_DAMAGE := 11.0             ## per colpo (tre colpi: circa il 40% della vita se li prendi tutti)
const BITE_REACH := 42.0              ## raggio del colpo davanti alla testa
const BITE_LUNGE := 70.0              ## quanto avanza a ogni colpo
const CHARGE_WINDUP := 0.65
const CHARGE_REAIM := 0.5             ## avviso della seconda carica, dopo il rimbalzo
const CHARGE_SPEED := 340.0
const CHARGE_MAX := 1.4               ## secondi al massimo per carica
const CHARGE_DAMAGE := 22.0
const CHARGE_HALF := 32.0             ## blocco 12: corpo 24 + giocatore 6 + 2 (= la striscia d'avviso)
const TRAIL_STEP := 34.0              ## ogni quanti pixel una pozza di sabbie mobili
const TRAIL_LIFE := 4.0
const BREATH_WINDUP := 0.6
const BREATH_TIME := 1.3
const BREATH_RANGE := 175.0
const BREATH_HALF := 24.0             ## mezza apertura del cono, in gradi
const BREATH_SWEEP := 80.0            ## quanto ruota il corpo mentre soffia
const BREATH_SAND := 8.0              ## la sabbia spinge e fa poco male
const BREATH_FIRE := 16.0             ## il fuoco fa male
const BREATH_PUSH := 220.0
const LEAP_WINDUP := 0.6
const LEAP_LOCK := 0.25               ## negli ultimi 0,25 s l'ombra non ti segue più
const LEAP_TIME := 0.55
const LEAP_RADIUS := 46.0
const LEAP_DAMAGE := 24.0
const WAVE_SPEED := 260.0             ## l'onda d'urto dopo l'atterraggio
const WAVE_MAX := 140.0
const WAVE_DAMAGE := 10.0
const ROAR_TIME := 0.6
const MAX_STONES := 2
const RAY_WARN := 0.6
const RAY_TIME := 1.8
const RAY_SWEEP := 110.0
const RAY_DAMAGE := 10.0              ## a ogni colpo del raggio (uno ogni 0,6 s)
const RAY_WALK := 0.5                 ## mentre il raggio gira cammina a metà passo
const RAY_COOLDOWN := 8.0
const TREMBLE := 1.8

const S := 1.8                        ## scala del disegno
const HEAD_DIST := 52.0               ## distanza delle teste dal centro, lungo l'asse
const SAND := Color(0.78, 0.62, 0.38)
const FIRE := Color(1.0, 0.55, 0.2)

var state := "intro"
var st := 1.6
var fire_dir := Vector2.RIGHT          ## l'asse del corpo: la testa di fuoco è qui, quella di sabbia dall'altra parte
var bar_extra := LION_HP * 2.0         ## la vita dei due leoni che verranno (per la barra unica, game.gd)
var floor_rect := Rect2(32, 64, 736, 384)
var split_done := false
var last_move := ""
var chain_left := 0                    ## mosse ancora da legare in questa sequenza
var ray_cd := 4.0
var hit_done := false
# morso
var bite_n := 0
var bite_dir := Vector2.RIGHT
var bite_at := Vector2.ZERO              ## blocco 12: il centro vero del morso (lo stesso dell'avviso)
# carica
var charge_dir := Vector2.RIGHT
var charges := 0
var trail_last := Vector2.ZERO
# soffio
var breath_spin := 1.0
var sand_hit := false
var fire_hit := false
# balzo e onda
var jump_from := Vector2.ZERO
var jump_to := Vector2.ZERO
var wave_r := -1.0
var wave_hit := false
var ray: Node2D = null


func _ready() -> void:
	is_boss = true
	super._ready()


func _player():
	var p = get_tree().get_first_node_in_group("player")
	return p if p != null and not p.dead else null


## Il centro del morso: davanti alla testa, a metà dello slancio (avviso e colpo usano lo stesso punto).
func _bite_center() -> Vector2:
	return head_pos(facing_sign(bite_dir)) + bite_dir * (12.0 + BITE_LUNGE * 0.5)


func _hurt(amount: float, from: Vector2) -> bool:
	var p = _player()
	return p != null and p.take_damage(amount, from, self)


## La testa verso cui guardi: +1 quella di fuoco, -1 quella di sabbia.
func facing_sign(to: Vector2) -> float:
	return 1.0 if to.dot(fire_dir) >= 0.0 else -1.0


func head_pos(sign_: float) -> Vector2:
	return global_position + fire_dir * HEAD_DIST * sign_ + Vector2(0, -20)


func busy() -> bool:
	return state not in ["hunt", "recover"]


## Ruota l'asse verso `to` (o il suo opposto, quello più vicino) al massimo di TURN_RATE.
func _turn(to: Vector2, delta: float, rate: float = TURN_RATE) -> void:
	if to == Vector2.ZERO:
		return
	var want := to.normalized() * facing_sign(to)
	var a := fire_dir.angle_to(want)
	var step := deg_to_rad(rate) * delta
	fire_dir = fire_dir.rotated(clampf(a, -step, step))


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta
	ray_cd -= delta
	_sync_shapes()
	if ray != null and is_instance_valid(ray):
		ray.global_position = head_pos(1.0)            # il raggio esce sempre dalla testa di fuoco
	_update_wave(delta)
	match state:
		"intro":
			if st <= 0.0:
				_hunt(0.4)
			return Vector2.ZERO
		"hunt":
			_turn(to, delta)
			if st <= 0.0 and to != Vector2.ZERO:
				_choose(to)
				return Vector2.ZERO
			return _steer(to.normalized() * WALK, delta) if to.length() > 40.0 else Vector2.ZERO
		"recover":
			_turn(to, delta, TURN_RATE * 0.5)
			if st <= 0.0:
				_after_move(to)
			return Vector2.ZERO
		"bite_windup":
			# ti segue nella prima metà della preparazione, poi la zona resta ferma (blocco 12)
			if st > float(BITE_WINDUP[bite_n]) * 0.5:
				_turn(to, delta, TURN_RATE * 1.5)
				if to != Vector2.ZERO:
					bite_dir = to.normalized()
			if st <= 0.0:
				state = "bite"
				st = 0.15
				hit_done = false
				bite_at = _bite_center()
				Sfx.play_at("swing", global_position, 0.1)
			return Vector2.ZERO
		"bite":
			if not hit_done:
				var p = _player()
				if p != null:
					if p.global_position.distance_to(bite_at) < BITE_REACH:
						hit_done = _hurt(BITE_DAMAGE, bite_at)
			if st <= 0.0:
				bite_n += 1
				if bite_n >= BITE_WINDUP.size():
					_end_move(true)
				else:
					state = "bite_windup"
					st = BITE_WINDUP[bite_n]
				return Vector2.ZERO
			return bite_dir * BITE_LUNGE / 0.15
		"roar":
			if st <= 0.0:
				_drop_stones(MAX_STONES)
				_fire_ray(to)
			return Vector2.ZERO
		"ray":
			_turn(to, delta, TURN_RATE * 0.6)
			if st <= 0.0:
				_end_move(true)
				return Vector2.ZERO
			return _steer(to.normalized() * WALK * RAY_WALK, delta) if to.length() > 50.0 else Vector2.ZERO
		"charge_windup":
			if st > 0.25 and to != Vector2.ZERO:
				charge_dir = to.normalized()
				fire_dir = charge_dir * facing_sign(charge_dir)
			if st <= 0.0:
				state = "charge"
				st = CHARGE_MAX
				hit_done = false
				trail_last = global_position
				Sfx.play_at("charge", global_position, 0.05)
			return Vector2.ZERO
		"charge":
			if not hit_done:
				var p = _player()
				if p != null and p.global_position.distance_to(global_position) < CHARGE_HALF:
					hit_done = _hurt(CHARGE_DAMAGE, global_position)
			if global_position.distance_to(trail_last) > TRAIL_STEP:
				trail_last = global_position
				var q := Hazards.Quicksand.new()
				q.radii = Vector2(24, 13)
				q.life = TRAIL_LIFE
				q.position = global_position
				get_parent().add_child(q)
			# contro il muro (o finito il tempo): rimbalza e carica di nuovo, una volta
			var blocked := get_slide_collision_count() > 0 and st < CHARGE_MAX - 0.15
			if blocked or st <= 0.0:
				charges += 1
				if charges < 2:
					Fx.shake(5.0)
					Sfx.play_at("amheh_land", global_position, 0.1)
					state = "charge_windup"
					st = CHARGE_REAIM
				else:
					_end_move(true)
				return Vector2.ZERO
			return charge_dir * CHARGE_SPEED
		"breath_windup":
			_turn(to, delta, TURN_RATE * 1.2)
			if st <= 0.0:
				state = "breath"
				st = BREATH_TIME
				sand_hit = false
				fire_hit = false
				# il corpo ruota verso il lato dove sei, così i coni ti vengono addosso
				breath_spin = signf(fire_dir.angle_to(to.normalized() * facing_sign(to))) if to != Vector2.ZERO else 1.0
				if breath_spin == 0.0:
					breath_spin = 1.0
				Sfx.play_at("fire_whoosh", global_position, 0.2)
			return Vector2.ZERO
		"breath":
			fire_dir = fire_dir.rotated(deg_to_rad(BREATH_SWEEP) / BREATH_TIME * breath_spin * delta)
			_breath_hits(delta)
			if st <= 0.0:
				_end_move(true)
			return Vector2.ZERO
		"leap_windup":
			if st > LEAP_LOCK and to != Vector2.ZERO:
				jump_to = _clamp_floor(global_position + to)
			if st <= 0.0:
				state = "leap"
				st = LEAP_TIME
				jump_from = global_position
				Sfx.play_at("amheh_growl", global_position, 0.1)
			return Vector2.ZERO
		"leap":
			if st <= 0.0:
				_land()
				_end_move(true)
				return Vector2.ZERO
			return (jump_to - jump_from) / LEAP_TIME
		"tremble":
			if st <= 0.0:
				_split()
			return Vector2(sin(t * 60.0) * 30.0, 0.0)
	return Vector2.ZERO


## Il corpo per gli urti e il contatto ruotano con il leone (come il disegno).
func _sync_shapes() -> void:
	var a := fire_dir.angle()
	var rot := a - PI * signf(a) if absf(a) > PI * 0.5 else a
	for n in [get_node_or_null("Body"), get_node_or_null("ContactArea")]:
		if n != null:
			n.rotation = rot


func _clamp_floor(p: Vector2) -> Vector2:
	var r := floor_rect.grow(-36.0)
	return Vector2(clampf(p.x, r.position.x, r.end.x), clampf(p.y, r.position.y, r.end.y))


func _hunt(time: float) -> void:
	state = "hunt"
	st = time


## La mossa è finita: se la sequenza ha un'altra mossa legata, parte dopo una pausa breve;
## altrimenti la pausa lunga (la finestra per punirlo).
func _end_move(big: bool) -> void:
	state = "recover"
	if chain_left > 0:
		st = CHAIN_GAP
	else:
		st = PUNISH if big else 0.6


func _after_move(to: Vector2) -> void:
	if chain_left > 0 and to != Vector2.ZERO:
		chain_left -= 1
		_start(_chain_next(last_move, to.length()), to)
		return
	_hunt(0.35 + randf() * 0.3)


## Le coppie legate: ruggito → carica, balzo → soffio, morso → balzo, carica → morso, soffio → carica.
func _chain_next(prev: String, d: float) -> String:
	match prev:
		"ray":
			return "charge"
		"leap":
			return "breath"
		"bite":
			return "leap"
		"charge":
			return "bite" if d < 120.0 else "leap"
		"breath":
			return "charge"
	return "bite"


func _choose(to: Vector2) -> void:
	var d := to.length()
	var opts := []
	if d < 80.0:
		opts = ["bite", "bite", "breath", "leap"]
	elif d < 200.0:
		opts = ["charge", "leap", "breath", "bite"]
	else:
		opts = ["charge", "charge", "leap"]
	if ray_cd <= 0.0:
		opts.append("ray")
		opts.append("ray")
	opts.erase(last_move)
	if opts.is_empty():
		opts = ["charge"]
	chain_left = 1 if hp <= max_hp * CHAIN_FROM else 0
	_start(opts.pick_random(), to)


func _start(move: String, to: Vector2) -> void:
	last_move = move
	match move:
		"bite":
			state = "bite_windup"
			bite_n = 0
			st = BITE_WINDUP[0]
			bite_dir = to.normalized() if to != Vector2.ZERO else fire_dir
			Sfx.play_at("amheh_growl", global_position, 0.1)
		"charge":
			state = "charge_windup"
			st = CHARGE_WINDUP
			charges = 0
			charge_dir = to.normalized() if to != Vector2.ZERO else fire_dir
			Sfx.play_at("amheh_growl", global_position, 0.1)
		"breath":
			state = "breath_windup"
			st = BREATH_WINDUP
			Sfx.play_at("amheh_growl", global_position, 0.1)
		"leap":
			state = "leap_windup"
			st = LEAP_WINDUP
			jump_to = _clamp_floor(global_position + to)
		"ray":
			state = "roar"
			st = ROAR_TIME
			ray_cd = RAY_COOLDOWN
			Sfx.play_at("roar", global_position, 0.05)
			Fx.shake(5.0)


func _fire_ray(to: Vector2) -> void:
	state = "ray"
	var r := Hazards.DawnRay.new()
	var o := head_pos(1.0)
	var tp := global_position + to + Vector2(0, -6)
	var sw := deg_to_rad(RAY_SWEEP) * (1.0 if randf() < 0.5 else -1.0)
	r.angle = (tp - o).angle() - sw * 0.5
	r.sweep = sw
	r.warn = RAY_WARN
	r.dur = RAY_TIME
	r.damage = RAY_DAMAGE
	r.src = self
	r.position = o
	get_parent().add_child(r)
	ray = r
	st = r.warn + r.dur + 0.1


## I due coni del soffio: lungo l'asse, uno per testa. Fuori dai coni (sui fianchi) si è al sicuro.
func _breath_hits(delta: float) -> void:
	var p = _player()
	if p == null or p.dash_t > 0.0:
		return
	for sg in [1.0, -1.0]:
		var o := head_pos(sg)
		var axis: Vector2 = fire_dir * sg
		var rel: Vector2 = p.global_position + Vector2(0, -6) - o
		if rel.length() > BREATH_RANGE or absf(axis.angle_to(rel)) > deg_to_rad(BREATH_HALF):
			continue
		if sg > 0.0:
			if not fire_hit:
				fire_hit = _hurt(BREATH_FIRE, o)
		else:
			p.move_and_collide(rel.normalized() * BREATH_PUSH * delta)     # la sabbia ti spinge verso l'angolo
			if not sand_hit:
				sand_hit = _hurt(BREATH_SAND, o)


func _land() -> void:
	Fx.shake(7.0)
	Fx.burst(global_position, SAND, 26, 150.0)
	Sfx.play_at("amheh_land", global_position, 0.05)
	var p = _player()
	if p != null:
		var dd: Vector2 = p.global_position - global_position
		if Vector2(dd.x, dd.y / 0.6).length() < LEAP_RADIUS:
			_hurt(LEAP_DAMAGE, global_position)
	wave_r = LEAP_RADIUS * 0.6
	wave_hit = false


## L'onda d'urto dopo il balzo: un anello che si allarga; si salta con lo scatto.
func _update_wave(delta: float) -> void:
	if wave_r < 0.0:
		return
	wave_r += WAVE_SPEED * delta
	if wave_r > WAVE_MAX:
		wave_r = -1.0
		return
	var p = _player()
	if p == null or wave_hit or p.dash_t > 0.0:
		return
	var dd: Vector2 = p.global_position - global_position
	var dist := Vector2(dd.x, dd.y / 0.6).length()
	if absf(dist - wave_r) < 8.0:
		wave_hit = _hurt(WAVE_DAMAGE, global_position)


## Il ruggito: al massimo MAX_STONES pietre in campo. Una cade sempre vicino a te.
func _drop_stones(n: int) -> void:
	var cur := 0
	for c in get_parent().get_children():
		if c is Hazards.FallingStone:
			cur += 1
	n = mini(n, MAX_STONES - cur)
	if n <= 0:
		return
	var p = _player()
	var spots: Array[Vector2] = []
	if p != null:
		spots.append(p.global_position + Vector2(randf_range(-30, 30), randf_range(-20, 20)))
	var area := floor_rect.grow(-30.0)
	var tries := 0
	while spots.size() < n and tries < 60:
		tries += 1
		var c := Vector2(randf_range(area.position.x, area.end.x), randf_range(area.position.y, area.end.y))
		if c.distance_to(global_position) < 70.0:
			continue
		var ok := true
		for o in spots:
			if o.distance_to(c) < 60.0:
				ok = false
		if ok:
			spots.append(c)
	for i in range(spots.size()):
		var stone := Hazards.FallingStone.new()
		stone.position = spots[i]
		stone.warn = 0.9 + i * 0.1
		get_parent().add_child(stone)


func _start_tremble() -> void:
	state = "tremble"
	st = TREMBLE
	chain_left = 0
	hp = 1.0
	if ray != null and is_instance_valid(ray):
		ray.queue_free()
	wave_r = -1.0
	Fx.shake(10.0)
	Fx.float_text(global_position + Vector2(0, -60), Lang.t("AKER TREMA"), Color(1, 0.85, 0.5))
	Sfx.play_at("roar", global_position, 0.0)


## Si divide: Ieri (sabbia) dalla testa di sabbia, Domani (fuoco) da quella di fuoco.
func _split() -> void:
	split_done = true
	bar_extra = 0.0
	var ieri: Enemy = LionScene.instantiate()
	var domani: Enemy = LionScene.instantiate()
	ieri.set("kind", "ieri")
	domani.set("kind", "domani")
	ieri.position = _clamp_floor(global_position - fire_dir * 34.0 + Vector2(0, 4))
	domani.position = _clamp_floor(global_position + fire_dir * 34.0 + Vector2(0, 4))
	for l in [ieri, domani]:
		l.max_hp = LION_HP
		l.set("floor_rect", floor_rect)
	ieri.set("partner", domani)
	domani.set("partner", ieri)
	Fx.shake(12.0)
	Fx.burst(global_position + Vector2(0, -30), Color(0.6, 0.6, 0.62), 30, 160.0)      # il disco spento si spezza
	Fx.burst(global_position, SAND, 40, 200.0)
	Sfx.play_at("serpent_erupt", global_position, 0.0)
	Music.play("boss_aker2")                   # la seconda fase ha un'altra musica: si sente che è cambiato tutto
	var g = get_tree().current_scene
	if g != null and g.has_method("_banner"):
		g._banner(Lang.t("Ieri e Domani"), Lang.t("«Io sono Ieri: ciò che è stato non torna.» «Io sono Domani: ciò che verrà non si ferma.»"), Color(1.0, 0.78, 0.4), 3.2)
	split.emit([ieri, domani])
	dead = true
	remove_from_group("enemies")
	queue_free()


## I fianchi sono il punto debole; sulle teste i colpi fanno meno. Mentre trema non lo si ferisce.
func take_hit(dmg: float, dir: Vector2, kb: float, can_burn: bool = false) -> void:
	if dead:
		return
	if state == "tremble" or split_done:
		Fx.burst(global_position + Vector2(0, -20), Color(1, 0.9, 0.6), 4, 40.0)
		return
	var m := FLANK_MULT
	var p = _player()
	if p != null:
		var rel: Vector2 = p.global_position - global_position
		var a := rad_to_deg(absf(fire_dir.angle_to(rel)))
		if a < HEAD_CONE or a > 180.0 - HEAD_CONE:
			m = HEAD_MULT
	super.take_hit(dmg * m, dir, kb, can_burn)
	if not dead and hp <= 1.0:
		_start_tremble()


## La fase 1 non "muore": finita la vita trema e si divide.
func die() -> void:
	if split_done:
		super.die()
		return
	dead = false
	hp = 1.0
	if state != "tremble":
		_start_tremble()


func _stagger_time() -> float:
	return 0.0


func _on_hit(_dmg: float) -> void:
	knock = Vector2.ZERO


func _contact_damage() -> float:
	return CONTACT


## Per i bot delle prove: da che parte scappare adesso (Vector2.ZERO = niente da schivare).
func bot_escape(pos: Vector2) -> Vector2:
	var rel := pos - global_position
	match state:
		"charge_windup":
			var side := charge_dir.orthogonal()
			if absf(rel.dot(side)) < 40.0 and rel.dot(charge_dir) > -20.0:
				return side * (1.0 if rel.dot(side) >= 0.0 else -1.0)
		"breath_windup", "breath":
			var side2 := fire_dir.orthogonal()
			return side2 * (1.0 if rel.dot(side2) >= 0.0 else -1.0)
		"leap_windup":
			if pos.distance_to(jump_to) < LEAP_RADIUS + 16.0:
				return (pos - jump_to).normalized() if pos != jump_to else Vector2.RIGHT
		"bite_windup":
			if rel.length() < BITE_REACH + HEAD_DIST + 10.0:
				return rel.normalized()
	return Vector2.ZERO


# ---------------------------------------------------------------- disegno

func _draw() -> void:
	_draw_warnings_under()
	draw_set_transform(Vector2(0, 2), fire_dir.angle(), Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 62.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_body(flash_t > 0.0)
	_draw_warnings_over()


## Il corpo ruotato lungo l'asse. Se l'asse guarda a sinistra il disegno si capovolge e le teste si
## scambiano posto, così i leoni non stanno mai a testa in giù.
func _draw_body(flash: bool) -> void:
	var a := fire_dir.angle()
	var flip := absf(a) > PI * 0.5
	var rot := a - PI * signf(a) if flip else a
	var shake := Vector2(sin(t * 70.0) * 2.0, 0.0) if state == "tremble" else Vector2.ZERO
	var lift := 0.0
	if state == "leap":
		lift = -sin((1.0 - st / LEAP_TIME) * PI) * 34.0
	draw_set_transform(shake + Vector2(0, lift), rot, Vector2.ONE)
	var west: Dictionary = AkerArt.IERI if not flip else AkerArt.DOMANI
	var east: Dictionary = AkerArt.DOMANI if not flip else AkerArt.IERI
	var mouth_fire := 0.0
	var mouth_sand := 0.0
	if state in ["bite_windup", "bite", "charge_windup", "charge"]:
		var fs := facing_sign(bite_dir if state.begins_with("bite") else charge_dir)
		if fs > 0.0:
			mouth_fire = 1.0
		else:
			mouth_sand = 1.0
	elif state in ["breath_windup", "breath", "roar", "tremble"]:
		mouth_fire = 1.0
		mouth_sand = 1.0
	elif state == "ray":
		mouth_fire = 1.0
	var glow := 0.4 + (0.6 if state in ["ray", "breath"] else 0.0)
	var mw := mouth_sand if west == AkerArt.IERI else mouth_fire
	var me := mouth_fire if east == AkerArt.DOMANI else mouth_sand
	AkerArt.lion(self, Vector2(-22, 0), -1.0, S, west, "lying", t, mw, glow if west == AkerArt.DOMANI else 0.0, flash, false)
	AkerArt.lion(self, Vector2(22, 0), 1.0, S, east, "lying", t, me, glow if east == AkerArt.DOMANI else 0.0, flash, false)
	# il disco del sole spento portato sulla schiena, tra i due leoni
	var dc := Vector2(0, -38)
	draw_circle(dc, 11.0, OUT)
	draw_circle(dc, 10.0, Color(0.4, 0.4, 0.44) if not flash else Color.WHITE)
	draw_circle(dc + Vector2(-2, -2), 6.0, Color(0.5, 0.5, 0.54) if not flash else Color.WHITE)
	if state == "tremble":
		var kk := 1.0 - st / TREMBLE
		for i in range(5):
			draw_line(dc, dc + Vector2.from_angle(i * 1.3) * 10.0 * kk, Color(1, 0.85, 0.5), 1.2)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Gli avvisi a terra (sotto il leone): la linea della carica, l'ombra del balzo, l'onda.
func _draw_warnings_under() -> void:
	if state == "charge_windup":
		var k := 1.0 - st / (CHARGE_WINDUP if charges == 0 else CHARGE_REAIM)
		Enemy.warn_strip(self, Vector2.ZERO, charge_dir, 520.0, CHARGE_HALF, k)
	if state in ["leap_windup", "leap"]:
		var c := jump_to - global_position
		var k2 := 1.0 if state == "leap" else 1.0 - st / LEAP_WINDUP
		draw_set_transform(c, 0.0, Vector2(1.0, 0.6))
		draw_circle(Vector2.ZERO, LEAP_RADIUS * (0.4 + 0.6 * k2), Color(0, 0, 0, 0.2 + 0.25 * k2))
		draw_arc(Vector2.ZERO, LEAP_RADIUS, 0.0, TAU, 32, Color(1, 0.3, 0.15, 0.6 + 0.3 * k2), 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if wave_r > 0.0:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
		var fade := 1.0 - wave_r / WAVE_MAX
		draw_arc(Vector2.ZERO, wave_r, 0.0, TAU, 40, Color(Enemy.WARN, 0.45 * fade), 16.0)   # la fascia vera (±8)
		draw_arc(Vector2.ZERO, wave_r, 0.0, TAU, 40, Color(0.95, 0.8, 0.5, 0.8 * fade), 6.0)
		draw_arc(Vector2.ZERO, wave_r, 0.0, TAU, 40, Color(1, 1, 0.9, 0.9 * fade), 2.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Gli avvisi sopra: i due coni del soffio e la zona del morso.
func _draw_warnings_over() -> void:
	if state in ["breath_windup", "breath"]:
		var k := 1.0 if state == "breath" else 1.0 - st / BREATH_WINDUP
		var half := deg_to_rad(BREATH_HALF)
		for sg in [1.0, -1.0]:
			var o := head_pos(sg) - global_position
			var axis: Vector2 = fire_dir * sg
			var pts := PackedVector2Array([o])
			for i in range(11):
				pts.append(o + axis.rotated(-half + half * 2.0 * i / 10.0) * BREATH_RANGE)
			var col := FIRE if sg > 0.0 else SAND
			draw_colored_polygon(pts, Color(col, (0.12 + 0.2 * k) if state == "breath_windup" else 0.42))
			draw_polyline(pts.slice(1), Color(1, 0.35, 0.15, 0.5 + 0.4 * k), 2.0)
			if state == "breath":
				for i in range(6):
					var f := fmod(t * 3.0 + i * 0.17, 1.0)
					draw_circle(o + axis.rotated((i - 2.5) * half / 3.0) * BREATH_RANGE * f, 2.0 + 3.0 * f, Color(col, 0.7 * (1.0 - f)))
	if state == "bite_windup":
		var k3 := 1.0 - st / float(BITE_WINDUP[bite_n])
		Enemy.warn_circle(self, _bite_center() - global_position, BITE_REACH, k3)
