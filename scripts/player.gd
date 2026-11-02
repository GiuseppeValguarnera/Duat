extends CharacterBody2D
## Lo Scriba delle Porte. Movimento, scatto, combo del khopesh, Occhio di Horus
## e Forma Divina (il super attacco che si carica col Sekhem).
## Tutti i numeri che regolano la sensazione di gioco sono esportati:
## selezioni il nodo Player e li cambi dall'Ispettore mentre provi.

signal died
signal health_changed(hp: float, max_hp: float)

const EyeScript := preload("res://scripts/eye.gd")
const PuddleScript := preload("res://scripts/puddle.gd")

@export_group("Vita")
@export var max_hp := 60.0
@export var hit_invuln := 0.8          ## secondi di invulnerabilità dopo un colpo subito

@export_group("Movimento")
@export var speed := 130.0
@export var attack_slowdown := 0.35    ## velocità mentre attacchi (0.35 = 35%)

@export_group("Scatto")
@export var dash_speed := 430.0
@export var dash_time := 0.16
## Lo scatto ha due cariche: dopo l'ultimo scatto, passata questa pausa, tornano tutte e due.
## Così si scatta due volte per uscire dai guai, ma poi si resta scoperti per un momento.
@export var dash_cooldown := 1.2
const DASH_CHARGES := 2
const DASH_GAP := 0.08                  ## tra uno scatto e l'altro della stessa coppia

@export_group("Khopesh")
@export var attack_damage := 12.0

@export_group("Occhio di Horus")
@export var eye_damage := 24.0
@export var eye_cooldown := 2.5

@export_group("Forma Divina")
@export var divine_time := 6.0
@export var divine_damage_mult := 1.5  ## danni del khopesh durante la Forma Divina
@export var divine_armor := 0.3        ## danni subiti durante la Forma Divina (0.3 = 30%)
@export var divine_wave_damage := 30.0
@export var divine_wave_radius := 70.0

## Le tre mosse della combo: portata, ampiezza in gradi, moltiplicatore danno,
## pausa prima del colpo successivo, piccolo slancio in avanti, spinta sul nemico.
const COMBO := [
	{"range": 34.0, "arc": 110.0, "mult": 1.0, "cd": 0.22, "lunge": 20.0, "knock": 110.0},
	{"range": 34.0, "arc": 110.0, "mult": 1.0, "cd": 0.22, "lunge": 20.0, "knock": 110.0},
	{"range": 44.0, "arc": 170.0, "mult": 1.8, "cd": 0.42, "lunge": 45.0, "knock": 240.0},
]

## La lancia di Neith: due affondi lunghi e stretti, poi un'ampia spazzata.
const SPEAR := [
	{"range": 52.0, "arc": 34.0, "mult": 1.0, "cd": 0.26, "lunge": 12.0, "knock": 90.0},
	{"range": 52.0, "arc": 34.0, "mult": 1.0, "cd": 0.26, "lunge": 12.0, "knock": 90.0},
	{"range": 42.0, "arc": 200.0, "mult": 1.6, "cd": 0.46, "lunge": 18.0, "knock": 210.0},
]
## Attacco in scatto (un colpo durante lo scatto o subito dopo). Lancia: affondo in corsa,
## lunghissimo e stretto, che trapassa la fila. Khopesh: fendente più largo e più lungo.
const SPEAR_LUNGE := {"range": 78.0, "arc": 24.0, "mult": 1.5, "cd": 0.32, "lunge": 70.0, "knock": 160.0}
const KHOPESH_DASH := {"range": 50.0, "arc": 210.0, "mult": 1.5, "cd": 0.3, "lunge": 45.0, "knock": 190.0}

## Attacco caricato: si tiene premuto oltre CHARGE_DELAY, si carica per CHARGE_TIME (camminando
## più lento), si rilascia a carica piena. Poi CHARGE_CD secondi di ricarica (lo stesso cerchio).
const CHARGE_DELAY := 0.25
const CHARGE_TIME := 1.0
const CHARGE_CD := 2.0
const CHARGE_SLOW := 0.65               ## regola comune a tutte le armi: −35% mentre carichi
## Khopesh: il fendente a giro attorno all'eroe.
const KHOPESH_SPIN := {"range": 58.0, "mult": 3.0, "knock": 260.0}
## Lancia: il lancio in linea che trapassa tutti e torna (scripts/thrown_spear.gd).
const SPEAR_THROW := {"mult": 2.4, "back_mult": 1.2, "speed": 430.0, "dist": 210.0, "knock": 150.0}
const ThrownSpear := preload("res://scripts/thrown_spear.gd")
## L'Arco di Satet: frecce rapide (circa 3 al secondo) al 60% di un fendente del khopesh, che si
## fermano sul primo nemico; il tiro carico (4 frecce di danni) trapassa la fila; alla fine dello
## scatto un ventaglio di 3 frecce corte. Mentre tende l'arco ci si muove meno piano che con le altre armi.
const BOW_SHOT := {"cd": 0.33, "mult": 0.6, "speed": 440.0, "dist": 250.0, "knock": 35.0}
const BOW_CHARGED := {"mult": 2.4, "speed": 620.0, "dist": 360.0, "knock": 130.0}
const BOW_FAN := {"mult": 0.6, "spread": 18.0, "speed": 420.0, "dist": 120.0, "knock": 70.0}
const BOW_AIM_RANGE := 320.0
const ArrowScript := preload("res://scripts/arrow.gd")
## Il Flagello di Osiride: tre frustate che colpiscono tutti i nemici in linea (larghezza `width`),
## la terza più ampia (un ventaglio di `arc` gradi). Danni pieni alla punta, metà addosso al corpo.
const FLAIL := [
	{"range": 80.0, "width": 9.0, "arc": 0.0, "mult": 0.85, "cd": 0.3, "lunge": 6.0, "knock": 70.0},
	{"range": 80.0, "width": 9.0, "arc": 0.0, "mult": 0.85, "cd": 0.3, "lunge": 6.0, "knock": 70.0},
	{"range": 86.0, "width": 0.0, "arc": 55.0, "mult": 1.4, "cd": 0.46, "lunge": 10.0, "knock": 160.0},
]
## Dopo lo scatto: una frustata lunga che trascina avanti, con te, i nemici colpiti.
const FLAIL_DASH := {"range": 118.0, "width": 11.0, "arc": 0.0, "mult": 1.3, "cd": 0.34, "lunge": 110.0, "knock": 300.0}
const FLAIL_BODY := 0.5                    ## danni addosso al corpo (alla punta 1)
## Il pastorale (attacco caricato): aggancia il nemico nel cono davanti a te; i normali vengono
## lanciati verso di te (o dove ti muovi), con élite, guardiani e boss sei tu a volare da loro.
const HOOK := {"range": 240.0, "cone": 28.0, "mult": 1.6, "fling": 150.0, "pull_speed": 560.0}

var hp := 0.0
var was_wet := false					# per lo schizzo quando entri in acqua
var after_dash_t := 0.0                 # subito dopo uno scatto: l'attacco in scatto
var hold_t := 0.0                       # da quanto tieni premuto "attacca"
var swing_queued := false               # un tocco arrivato durante la pausa tra due colpi: parte appena può
var charging := false                   # attacco caricato: stai caricando
var charge_k := 0.0                     # 0..1
var charge_full := false
var charge_cd := 0.0                    # ricarica dopo l'attacco caricato
var charge_flash_t := 0.0
var spear_thrown: Node2D = null         # la lancia lanciata: finché non torna sei disarmato
var spin_swing := false
var lash_width := 0.0                   # frustata in linea: mezza larghezza (0 = ventaglio)
var hook_vis_t := 0.0                   # il pastorale disegnato verso il nemico agganciato
var hook_to := Vector2.ZERO
var hook_red := false                   # rosso = è l'eroe a essere tirato (élite e boss)
var hook_pull_t := 0.0
var hook_pull_e = null                 # l'ultimo colpo è stato il fendente circolare
var dead := false
var facing := Vector2.RIGHT
var aim := Vector2.RIGHT

var dash_t := 0.0
var dash_cd := 0.0                     # pausa prima che le cariche tornino
var dash_charges := DASH_CHARGES
var dash_gap_t := 0.0
var dash_ready_t := 0.0                # lampo quando le cariche tornano
var dash_dir := Vector2.ZERO
var dash_hit := {}
var shu_dash_hit := {}                 # Ali del Cielo: chi è già stato spinto in questo scatto
var wind_wall_cd := 0.0                # Muro di Vento: pronto quando arriva a 0
var storm_cd := 0.0                    # Signore delle Tempeste: alla prossima raffica
var gust_t := 0.0                      # la raffica in corso
const ShuVortex := preload("res://scripts/shu_vortex.gd")
var leap_ready := false                # Balzo della Leonessa: il colpo dopo lo scatto
var invuln_t := 0.0
var flash_t := 0.0

var atk_t := 0.0
var atk_cd := 0.0
var combo := 0
var combo_window := 0.0
var swing_dir := Vector2.RIGHT
var swing_range := 0.0
var swing_arc := 0.0
var swing_index := 0

var eye_cd := 0.0
var eye_charges := 1                   # Il Sole e la Luna: cariche dell'Occhio pronte
var divine_t := 0.0
var drain_t := 3.0                     # Sete Insaziabile
var poison_t := 0.0                   # veleno dello scorpione: secondi rimasti
var poison_tick := 0.0
var shield := 0.0                      # Ali di Iside: scudo che si ricarica a ogni stanza
var knock := Vector2.ZERO
var walk := 0.0

@onready var camera: Camera2D = $Camera


func _ready() -> void:
	# movimento fluido anche quando lo schermo va a 90 o 120 Hz e la fisica a 60 (vedi project.godot)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	max_hp = Run.max_hp
	hp = Run.hp
	Run.divine = false
	shield = Run.val("iside_wings")
	add_to_group("player")
	Fx.camera = camera


## Ricarica effettiva dell'Occhio, doni compresi.
func eye_cd_max() -> float:
	return eye_cooldown * Run.eye_cooldown_mult()


func dash_cd_max() -> float:
	return maxf(Run.MIN_DASH_CD, dash_cooldown * Run.dash_cooldown_mult())


## Ala del Nibbio (Nefti): lo scatto torna subito pronto.
func refill_dash() -> void:
	dash_charges = DASH_CHARGES
	dash_cd = 0.0
	_dash_ready_fx()


func can_dash() -> bool:
	return dash_charges > 0 and dash_t <= 0.0 and dash_gap_t <= 0.0


## Le cariche sono tornate: un piccolo lampo ai piedi, così lo senti senza guardare.
func _dash_ready_fx() -> void:
	dash_ready_t = 0.25


func heal(amount: float) -> void:
	if dead or amount <= 0.0:
		return
	amount *= Run.heal_mult()
	hp = minf(max_hp, hp + amount)
	Run.hp = hp
	Fx.float_text(global_position, "+%d" % int(amount), Color(0.5, 1, 0.55))
	health_changed.emit(hp, max_hp)


func _physics_process(delta: float) -> void:
	if dead:
		return
	max_hp = Run.max_hp
	_tick(delta)

	var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move.length() > 0.15:
		facing = move.normalized()
	_update_aim(move.length() > 0.15)

	if Input.is_action_just_pressed("dash") and can_dash():
		_start_dash(move)
	_attack_input(delta)
	if Input.is_action_just_pressed("special") and eye_ready() and not Run.in_hub:
		_fire_eye()
	if Input.is_action_just_pressed("super") and Run.sekhem_ready() and divine_t <= 0.0:
		_divine_form()

	if _hook_pulling():
		# il pastorale agganciato a un élite o a un boss: voli da lui
		velocity = (hook_pull_e.global_position - global_position).normalized() * HOOK["pull_speed"]
		hook_to = hook_pull_e.global_position
		hook_vis_t = maxf(hook_vis_t, 0.08)
	elif dash_t > 0.0:
		velocity = dash_dir * dash_speed * (1.0 + Run.val("shu_wings") / 100.0 if Run.has("shu_wings") else 1.0)
		_dash_damage()
	else:
		var s := speed * Run.move_mult() * (attack_slowdown if atk_t > 0.0 else 1.0)
		if charging:
			s *= CHARGE_SLOW                # mentre carichi ti muovi più lento
		if Run.shu_gust:
			s *= 1.2                        # la raffica di Shu
		if Run.in_deep(global_position):
			s *= 0.75                       # l'acqua alta della Porta: si cammina a fatica (lo scatto no)
		for q in get_tree().get_nodes_in_group("quicksand"):
			if q.contains(global_position):
				s *= 0.6                    # le sabbie mobili di Sokar
				break
		var wet := Hazards.in_water(get_tree(), global_position)
		if wet:
			s *= Hazards.WATER_SLOW
		if wet and not was_wet:
			Sfx.play("splash", 0.12)
			Fx.burst(global_position, Color(0.6, 0.85, 1.0, 0.8), 8, 60.0)
		was_wet = wet
		velocity = move * s + knock
		if move.length() > 0.1:
			walk += delta * 10.0
	knock = knock.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()
	_heavy_drain(delta)
	_poison_update(delta)
	queue_redraw()


## "Attacca": un tocco è la combo; tenendo premuto oltre CHARGE_DELAY si carica l'attacco caricato
## (se non è in ricarica), che parte al rilascio solo a carica piena. Mentre è in ricarica, tenendo
## premuto la combo si ripete come prima. Con la lancia lanciata sei disarmato.
func _attack_input(delta: float) -> void:
	if Run.in_hub:
		return
	var armed := spear_thrown == null or not is_instance_valid(spear_thrown)
	var holding := Input.is_action_pressed("attack")
	if Input.is_action_just_pressed("attack"):
		hold_t = 0.0
		swing_queued = armed
	if holding:
		hold_t += delta
	if holding and armed and charge_cd <= 0.0 and dash_t <= 0.0 and hold_t >= CHARGE_DELAY:
		if not charging:
			charging = true
			charge_k = 0.0
			swing_queued = false
		charge_k = minf(1.0, charge_k + delta / CHARGE_TIME)
		if charge_k >= 1.0 and not charge_full:
			charge_full = true
			charge_flash_t = 0.25
			if Run.weapon == "arco" and Run.has("arco_iside"):
				shield = maxf(shield, Run.val("arco_iside"))     # Respiro di Iside: l'arco teso protegge
			Sfx.play("crit", 0.05)
			Fx.burst(global_position + Vector2(0, -30), Color(1.0, 0.85, 0.4), 14, 80.0)
	elif charging and not holding:
		_release_charge()
	elif not charging and armed and atk_cd <= 0.0 and dash_t <= 0.0:
		if swing_queued or (holding and charge_cd > 0.0):
			swing_queued = false
			_swing()
	if not holding:
		hold_t = 0.0


func _release_charge() -> void:
	charging = false
	charge_k = 0.0
	if not charge_full:
		return                              # rilasciato prima del pieno: annullato
	charge_full = false
	charge_cd = _charge_cd_max()
	_charged_attack()


## La ricarica dell'attacco caricato: uguale per tutte le armi (2 s).
func _charge_cd_max() -> float:
	return CHARGE_CD


## L'attacco caricato, nella direzione del momento del rilascio (con la mira automatica se attiva).
func _charged_attack() -> void:
	var spear := Run.weapon == "lancia"
	var bow := Run.weapon == "arco"
	var dir := _bow_aim() if bow else _assisted(aim, 140.0 if spear else 70.0)
	var base: float = attack_damage * Run.khopesh_mult() * _aspect_damage()
	if divine_t > 0.0:
		base *= divine_damage_mult
	swing_dir = dir
	Fx.shake(7.0)
	if Run.has("shu_column"):
		# Colonna d'Aria: un vortice che risucchia i nemici vicini (dove finisce il lancio, o attorno a te)
		var v := ShuVortex.new()
		get_parent().add_child(v)
		v.global_position = global_position + (dir * 150.0 if spear or bow else Vector2.ZERO)
	if Run.weapon == "flagello":
		_hook(dir, base)
		return
	if bow:
		# il tiro carico: una freccia grande che trapassa tutta la fila
		var dmg: float = base * BOW_CHARGED["mult"] * (1.0 + Run.val("arco_sekhmet") / 100.0)
		var crit_chance := Run.khopesh_crit_chance() + Run.val("arco_bastet") / 100.0
		_spawn_arrow(dir, dmg, BOW_CHARGED["speed"], BOW_CHARGED["dist"], BOW_CHARGED["knock"], -1, crit_chance, true)
		atk_t = 0.18
		atk_cd = 0.3
		swing_index = 2
		spin_swing = false
		Sfx.play("crit", 0.05)
		Sfx.play("swing", 0.0)
		Fx.burst(global_position + Vector2(0, -10) + dir * 14.0, Color(1.0, 0.86, 0.45), 18, 120.0)
		knock = -dir * 60.0
		return
	if spear:
		var sp := ThrownSpear.new()
		sp.dir = dir
		sp.player = self
		sp.dmg_out = base * SPEAR_THROW["mult"]
		sp.dmg_back = base * SPEAR_THROW["back_mult"]
		sp.speed = SPEAR_THROW["speed"]
		sp.max_dist = SPEAR_THROW["dist"]
		sp.knock = SPEAR_THROW["knock"] * Run.knock_mult()
		get_parent().add_child(sp)
		sp.global_position = global_position + Vector2(0, -8) + dir * 10.0
		spear_thrown = sp
		Sfx.play("swing", 0.0)
		knock = -dir * 40.0
		return
	# khopesh: il fendente a giro
	atk_t = 0.2
	atk_cd = 0.3
	swing_range = KHOPESH_SPIN["range"]
	swing_arc = TAU
	swing_index = 2
	spin_swing = true
	Sfx.play("swing", 0.0)
	Fx.burst(global_position + Vector2(0, -8), Color(1.0, 0.88, 0.5), 30, 160.0)
	var hit_any := false
	for j in get_tree().get_nodes_in_group("breakables"):
		if not j.broken and global_position.distance_to(j.global_position) < swing_range + 8.0:
			j.smash()
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead:
			continue
		var to: Vector2 = e.global_position - global_position
		if to.length() > swing_range + e.radius:
			continue
		var crit := Run.roll_crit(Run.khopesh_crit_chance())
		if Run.has("nefti_veil"):
			e.mourn_t = 4.0
		Run.nefti_on_hit()
		e.take_hit(base * KHOPESH_SPIN["mult"] * crit, to.normalized(), KHOPESH_SPIN["knock"] * Run.knock_mult(), Run.khopesh_burns())
		Fx.impact(e.global_position + Vector2(0, -e.radius) - to.normalized() * e.radius * 0.6, to.normalized(), true)
		hit_any = true
	if hit_any:
		Fx.hitstop(0.1)


## Shu: il Muro di Vento si ricarica; il Signore delle Tempeste alza una raffica ogni tanto (sempre,
## durante le tempeste di sabbia di Sokar).
func _shu_tick(delta: float) -> void:
	wind_wall_cd = maxf(0.0, wind_wall_cd - delta)
	gust_t = maxf(0.0, gust_t - delta)
	if Run.has("shu_storm"):
		storm_cd -= delta
		if storm_cd <= 0.0:
			storm_cd = Run.val("shu_storm")
			gust_t = 3.0
			Fx.burst(global_position + Vector2(0, -10), Boons.god_color("shu"), 20, 120.0)
			Sfx.play("dash", 0.1)
	var storm := not get_tree().get_nodes_in_group("sandstorm").is_empty()
	Run.shu_gust = Run.has("shu_storm") and not Run.in_hub and (gust_t > 0.0 or storm)


func _tick(delta: float) -> void:
	_shu_tick(delta)
	after_dash_t = maxf(0.0, after_dash_t - delta)
	charge_cd = maxf(0.0, charge_cd - delta)
	charge_flash_t = maxf(0.0, charge_flash_t - delta)
	hook_vis_t = maxf(0.0, hook_vis_t - delta)
	hook_pull_t = maxf(0.0, hook_pull_t - delta)
	var dash_ending := dash_t > 0.0 and dash_t <= delta
	dash_t = maxf(0.0, dash_t - delta)
	if dash_ending:
		_dash_ended()
	dash_gap_t = maxf(0.0, dash_gap_t - delta)
	dash_ready_t = maxf(0.0, dash_ready_t - delta)
	if dash_charges < DASH_CHARGES and dash_t <= 0.0:
		dash_cd -= delta
		if dash_cd <= 0.0:
			dash_cd = 0.0
			dash_charges = DASH_CHARGES
			if not Run.in_hub:
				_dash_ready_fx()
	invuln_t = maxf(0.0, invuln_t - delta)
	flash_t = maxf(0.0, flash_t - delta)
	atk_t = maxf(0.0, atk_t - delta)
	atk_cd = maxf(0.0, atk_cd - delta)
	combo_window = maxf(0.0, combo_window - delta)
	# l'Occhio si ricarica una carica alla volta (di base ne ha una sola)
	var max_charges := Run.eye_charges()
	eye_charges = mini(eye_charges, max_charges)
	if eye_charges < max_charges:
		eye_cd -= delta
		if eye_cd <= 0.0:
			eye_charges += 1
			eye_cd = eye_cd_max() if eye_charges < max_charges else 0.0
	else:
		eye_cd = 0.0
	if divine_t > 0.0:
		divine_t = maxf(0.0, divine_t - delta)
		Run.divine = divine_t > 0.0


## Mira: la direzione la decidi tu (levetta destra, mouse, oppure dove guardi o ti muovi).
## Sul telefono e col pad la mira assistita la corregge di poco verso un nemico davanti (`_assisted`).
func _update_aim(_moving: bool = false) -> void:
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if Fx.device == "mouse" and stick.length() <= 0.3:
		var to := get_global_mouse_position() - (global_position + Vector2(0, -8))
		if to.length() > 4.0:
			aim = to.normalized()
		return
	var base := stick.normalized() if stick.length() > 0.3 else facing
	aim = _assisted(base, ASSIST_RANGE)


## Mira assistita: corregge SOLO la direzione verso un nemico nel cono davanti a `dir` (25° per le
## armi da mischia, 12° per l'arco); non prevede il movimento e non insegue (quello è il dono di
## Horus). Solo nemici visibili, nel 70% centrale dello schermo e senza muri o colonne in mezzo; mai
## alle spalle. Il bersaglio resta lo stesso finché è valido (niente tremolio). Col mouse è spenta, e
## si spegne anche nelle Opzioni.
const ASSIST_MELEE := 25.0
const ASSIST_BOW := 12.0
const ASSIST_RANGE := 420.0
const ASSIST_SCREEN := 0.7
var _aim_target = null


func _assist_on() -> bool:
	return Fx.device != "mouse" and Meta.options.get("autoaim", true)


func _assisted(dir: Vector2, max_dist: float) -> Vector2:
	if not _assist_on() or dir == Vector2.ZERO:
		return dir
	var cone := deg_to_rad(ASSIST_BOW if Run.weapon == "arco" else ASSIST_MELEE)
	# il bersaglio di prima resta finché è valido (con un po' di margine sul cono)
	if _target_ok(_aim_target, dir, cone * 1.25, ASSIST_RANGE):
		var to_t: Vector2 = _aim_target.global_position - global_position
		return to_t.normalized() if to_t.length() <= max_dist else dir
	_aim_target = null
	var best_a := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		if not _target_ok(e, dir, cone, max_dist):
			continue
		var a := absf(dir.angle_to(e.global_position - global_position))
		if a < best_a:
			best_a = a
			_aim_target = e
	if _aim_target == null:
		return dir
	return (_aim_target.global_position - global_position).normalized()


func _target_ok(e, dir: Vector2, cone: float, max_dist: float) -> bool:
	if e == null or not is_instance_valid(e) or e.dead or not e.is_visible_in_tree():
		return false
	var to: Vector2 = e.global_position - global_position
	var d := to.length()
	if d < 1.0 or d > max_dist or absf(dir.angle_to(to)) > cone:
		return false
	# nel 70% centrale dello schermo
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		var half := get_viewport().get_visible_rect().size / (2.0 * cam.zoom) * ASSIST_SCREEN
		var rel: Vector2 = e.global_position - cam.get_screen_center_position()
		if absf(rel.x) > half.x or absf(rel.y) > half.y:
			return false
	# niente muri o colonne in mezzo (lo strato 1 è il mondo)
	var q := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -6), e.global_position + Vector2(0, -6), 1, [get_rid()])
	return get_world_2d().direct_space_state.intersect_ray(q).is_empty()


func _start_dash(move: Vector2) -> void:
	dash_dir = move.normalized() if move.length() > 0.15 else facing
	dash_t = dash_time
	dash_charges -= 1
	charging = false                 # lo scatto interrompe il caricamento
	charge_k = 0.0
	charge_full = false
	dash_gap_t = dash_time + DASH_GAP
	dash_cd = dash_cd_max()          # la pausa riparte da ogni scatto: conta dall'ultimo
	invuln_t = maxf(invuln_t, dash_time + 0.05)
	knock = Vector2.ZERO
	dash_hit.clear()
	shu_dash_hit.clear()
	Run.room_dashed = true
	# Pilastro Djed: al posto tuo resta una statua che attira i nemici (una sola alla volta)
	if Run.wears("djed") and not Run.training and Run.decoy_t <= 0.0:
		var decoy := Amulets.Decoy.new()
		decoy.life = Amulets.val_of("djed")
		decoy.position = position
		get_parent().add_child(decoy)
		get_parent().move_child(decoy, get_index())
	Sfx.play("dash")
	Fx.burst(global_position, Color(0.85, 0.75, 0.55), 8, 60.0)


## Fine dello scatto: apre la finestra per l'affondo della lancia (o il fendente di Wepwawet)
## e attiva i doni legati allo scatto. Va chiamata in _tick, prima che si legga l'attacco.
func _dash_ended() -> void:
	after_dash_t = 0.35
	if Run.has("sekhmet_leap"):
		leap_ready = true
	if Run.has("sobek_tide"):
		var pool := PuddleScript.new()
		pool.position = position
		get_parent().add_child(pool)
		get_parent().move_child(pool, get_index())     # sopra il pavimento, sotto personaggio e nemici


## Corsa dell'Alba: lo scatto ferisce i nemici attraversati. Ali del Cielo (Shu): quelli che sfiori
## vengono spinti via, di lato.
func _dash_damage() -> void:
	if Run.has("shu_wings"):
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.dead or shu_dash_hit.has(e):
				continue
			var rel: Vector2 = e.global_position - global_position
			if rel.length() < e.radius + 14.0:
				shu_dash_hit[e] = true
				var side := dash_dir.orthogonal()
				if rel.dot(side) < 0.0:
					side = -side
				e.shu_push((side + dash_dir * 0.4).normalized(), 280.0)
	if not Run.has("ra_dawn"):
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead or dash_hit.has(e):
			continue
		if global_position.distance_to(e.global_position) < e.radius + 10.0:
			dash_hit[e] = true
			e.take_hit(Run.val("ra_dawn") * Run.all_damage_mult(), dash_dir, 60.0)
			e.burn_t = maxf(e.burn_t, 1.0)


## Il danno in più dell'aspetto scelto, per le armi che ne hanno uno "+% danni".
func _aspect_damage() -> float:
	return 1.0 + Run.aspect_val("faraone") / 100.0 + Run.aspect_val("neith") / 100.0 + Run.aspect_val("satet") / 100.0


## La mira dell'arco: la stessa mira (assistita con un cono stretto, 12°), fino a BOW_AIM_RANGE.
func _bow_aim() -> Vector2:
	return _assisted(aim, BOW_AIM_RANGE)


func _spawn_arrow(dir: Vector2, dmg: float, spd: float, dist: float, kb: float, pierce: int, crit_chance: float, charged: bool) -> void:
	var ar := ArrowScript.new()
	ar.player = self
	ar.dir = dir
	ar.dmg = dmg
	ar.speed = spd
	ar.max_dist = dist
	ar.knock = kb
	ar.pierce = pierce
	ar.crit_chance = crit_chance
	ar.charged = charged
	ar.big = 1.6 if charged else 1.0
	if Run.has("arco_horus"):
		ar.homing = true
		ar.dmg *= 1.0 + Run.val("arco_horus") / 100.0
	if pierce == 0 and Run.has("arco_thoth"):
		ar.pierce = 1
		ar.pierce_mult = Run.val("arco_thoth") / 100.0
	get_parent().add_child(ar)
	ar.global_position = global_position + Vector2(0, -8) + dir * 10.0


## Un colpo dell'arco: una freccia (o il ventaglio di Anubi); dopo lo scatto, tre frecce corte.
func _bow_shot() -> void:
	var dash_atk := after_dash_t > 0.0
	after_dash_t = 0.0
	leap_ready = false
	atk_t = 0.1
	atk_cd = BOW_SHOT["cd"] * Run.attack_speed_mult()
	swing_index = 3 if dash_atk else 0
	spin_swing = false
	swing_range = 0.0
	var dir := _bow_aim()
	swing_dir = dir
	var base: float = attack_damage * Run.khopesh_mult() * _aspect_damage()
	if divine_t > 0.0:
		base *= divine_damage_mult
	var crit_chance := Run.khopesh_crit_chance()
	if dash_atk:
		# il ventaglio dopo lo scatto (il Balzo della Leonessa lo potenzia)
		var fan: float = base * BOW_FAN["mult"] * (1.0 + Run.val("sekhmet_leap") / 100.0)
		for k in [-1.0, 0.0, 1.0]:
			_spawn_arrow(dir.rotated(deg_to_rad(BOW_FAN["spread"]) * k), fan, BOW_FAN["speed"], BOW_FAN["dist"], BOW_FAN["knock"], 0, crit_chance, false)
		Fx.burst(global_position + Vector2(0, -8) + dir * 14.0, Color(0.98, 0.86, 0.45), 8, 70.0)
	else:
		var n := int(Run.val("arco_anubi")) if Run.has("arco_anubi") else 1
		var dmg: float = base * BOW_SHOT["mult"] * (0.65 if n > 1 else 1.0)
		for i in range(n):
			var off := 0.0 if n == 1 else deg_to_rad(10.0) * (i - (n - 1) / 2.0)
			_spawn_arrow(dir.rotated(off), dmg, BOW_SHOT["speed"], BOW_SHOT["dist"], BOW_SHOT["knock"], 0, crit_chance, false)
	Sfx.play("swing", 0.25)
	knock = -dir * 8.0


## Volo verso il nemico agganciato (élite e boss): finisce quando arrivi, se muore o dopo 0,6 s.
func _hook_pulling() -> bool:
	if hook_pull_t <= 0.0:
		return false
	if hook_pull_e == null or not is_instance_valid(hook_pull_e) or hook_pull_e.dead \
			or global_position.distance_to(hook_pull_e.global_position) < hook_pull_e.radius + 14.0:
		hook_pull_t = 0.0
		hook_pull_e = null
		Fx.burst(global_position + Vector2(0, -8), FlailArt.RED, 8, 60.0)
		return false
	return true


## Il nemico che il pastorale aggancerebbe guardando verso `dir` (null se nessuno).
func _hook_target(dir: Vector2):
	var best = null
	var best_score := INF
	var cone := deg_to_rad(HOOK["cone"] * (1.4 if Fx.device == "touch" else 1.0))
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead:
			continue
		var to: Vector2 = e.global_position - global_position
		var d := to.length()
		if d > HOOK["range"] + e.radius or d < 4.0:
			continue
		var a := absf(dir.angle_to(to))
		if a > cone:
			continue
		var score := a * 120.0 + d
		if score < best_score:
			best_score = score
			best = e
	return best


func _hook_heavy(e) -> bool:
	return e.is_boss or e.miniboss or e.elite


## L'aggancio del pastorale (attacco caricato del flagello).
func _hook(dir: Vector2, base: float) -> void:
	var e = _hook_target(dir)
	hook_vis_t = 0.35
	atk_t = 0.16
	atk_cd = 0.3
	swing_index = 2
	spin_swing = false
	swing_range = 0.0
	Sfx.play("swing", 0.0)
	if e == null:
		# a vuoto: il pastorale si allunga e torna
		hook_red = false
		hook_to = global_position + Vector2(0, -8) + dir * HOOK["range"]
		return
	var heavy := _hook_heavy(e)
	hook_red = heavy
	hook_to = e.global_position
	var dmg: float = base * HOOK["mult"] * (1.0 + Run.val("flagello_bastet") / 100.0)
	var crit := Run.roll_crit(1.0 if Run.has("flagello_bastet") else Run.khopesh_crit_chance())
	if crit > 1.0:
		Fx.float_text(e.global_position + Vector2(0, -20), Lang.t("CRITICO"), Boons.god_color("bastet"))
		Sfx.play("crit")
	if Run.has("flagello_iside"):
		shield = maxf(shield, Run.val("flagello_iside"))       # Pastorale di Iside
	if Run.has("flagello_horus"):
		eye_charges = Run.eye_charges()                     # Pastorale del Falco: l'Occhio è di nuovo pronto
		eye_cd = 0.0
	if Run.has("nefti_veil") or Run.has("flagello_nefti"):
		e.mourn_t = 4.0
	Run.nefti_on_hit()
	var to_me: Vector2 = global_position - e.global_position
	e.take_hit(dmg * crit, to_me.normalized(), 0.0, Run.khopesh_burns())
	Fx.impact(e.global_position + Vector2(0, -e.radius), -to_me.normalized(), true)
	Fx.hitstop(0.06)
	Fx.shake(4.0)
	if e.dead:
		return
	if heavy:
		hook_pull_e = e
		hook_pull_t = 0.6
		invuln_t = maxf(invuln_t, 0.65)
		return
	# lanciato verso di te, o nella direzione in cui ti muovi (anche nelle trappole e nella sabbia nera)
	var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var fdir := to_me.normalized()
	var dist := maxf(0.0, to_me.length() - 28.0)
	if move.length() > 0.3:
		fdir = move.normalized()
		dist = HOOK["fling"]
	e.shu_push(fdir, clampf(sqrt(2.0 * 800.0 * dist), 140.0, 760.0), true)


## Le frustate del flagello: tutti i nemici in linea (la terza a ventaglio); più danni alla punta.
func _flail_swing() -> void:
	if combo_window <= 0.0:
		combo = 0
	var dash_atk := after_dash_t > 0.0
	var c: Dictionary = FLAIL_DASH if dash_atk else FLAIL[combo]
	swing_index = 3 if dash_atk else combo
	if not dash_atk:
		combo = (combo + 1) % FLAIL.size()
	spin_swing = false
	combo_window = 0.55
	atk_t = 0.16
	var cd: float = c["cd"] * Run.attack_speed_mult()
	var reach: float = c["range"] * (1.0 + Run.val("flagello_thoth") / 100.0)
	if Run.has("flagello_anubi"):
		cd *= 1.0 - Run.val("flagello_anubi") / 100.0       # Anubi: più rapide, ma più corte
		reach *= 0.8
	atk_cd = cd
	after_dash_t = 0.0
	var base_dir := aim
	if dash_atk and Fx.device != "mouse" and Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down").length() <= 0.3 and dash_dir != Vector2.ZERO:
		base_dir = dash_dir
	swing_dir = _assisted(base_dir, reach + 24.0)
	swing_range = reach
	swing_arc = deg_to_rad(c["arc"])
	lash_width = c["width"]
	knock = swing_dir * c["lunge"]
	var dmg: float = attack_damage * Run.khopesh_mult() * c["mult"] * Run.combo_mult(swing_index) * _aspect_damage()
	if divine_t > 0.0:
		dmg *= divine_damage_mult
	if dash_atk and Run.has("sekhmet_leap"):
		dmg *= 1.0 + Run.val("sekhmet_leap") / 100.0
	leap_ready = false
	Sfx.play("swing", 0.2)
	var burns: bool = Run.khopesh_burns() or (swing_index == 2 and Run.has("flagello_ra"))
	var hit_any := false
	for j in get_tree().get_nodes_in_group("breakables"):
		if not j.broken and _in_lash(j.global_position - global_position, 4.0) >= 0.0:
			j.smash()
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead:
			continue
		var to: Vector2 = e.global_position - global_position
		var proj := _in_lash(to, e.radius)
		if proj < 0.0:
			continue
		# alla punta i danni pieni, addosso al corpo la metà
		var tip_k := clampf((proj - 22.0) / maxf(1.0, swing_range * 0.7 - 22.0), 0.0, 1.0)
		var hit_dmg := dmg * lerpf(FLAIL_BODY, 1.0, tip_k)
		if tip_k >= 1.0 and Run.has("flagello_sekhmet"):
			hit_dmg *= 1.0 + Run.val("flagello_sekhmet") / 100.0
		var crit := Run.roll_crit(Run.khopesh_crit_chance())
		hit_dmg *= crit
		if Run.has("duo_ra_sekhmet") and e.burn_t > 0.0:
			hit_dmg *= 1.25
		if Run.has("duo_sobek_iside") and shield > 0.0:
			hit_dmg *= 1.25
		if e.mark_t > 0.0:
			hit_dmg *= 1.0 + Run.val("horus_mark") / 100.0
		if crit > 1.0:
			Fx.float_text(e.global_position + Vector2(0, -20), Lang.t("CRITICO"), Boons.god_color("bastet"))
			Sfx.play("crit")
			if Run.has("duo_sekhmet_bastet"):
				_shockwave.call_deferred(40.0, 12.0 * Run.all_damage_mult(), 150.0, Boons.god_color("duo"))
		if Run.has("nefti_veil"):
			e.mourn_t = 4.0
		Run.nefti_on_hit()
		# dopo lo scatto la frusta trascina avanti i nemici colpiti, insieme a te
		var kdir := swing_dir if dash_atk else to.normalized()
		e.take_hit(hit_dmg, kdir, c["knock"] * Run.knock_mult(), burns)
		Fx.impact(e.global_position + Vector2(0, -e.radius) - to.normalized() * e.radius * 0.6, to.normalized(), swing_index >= 2 or crit > 1.0)
		if not e.dead:
			if Run.has("flagello_sobek"):
				e.slow_t = 2.0                    # Frusta della Palude
			if swing_index == 2 and Run.has("shu_breath"):
				e.shu_push(to.normalized(), 330.0)
			if swing_index == 2 and Run.has("sobek_bite"):
				e.stagger_t = maxf(e.stagger_t, Run.val("sobek_bite") * (0.25 if e.is_boss else 1.0))
				e.sobek_stun_t = maxf(e.sobek_stun_t, Run.val("sobek_bite"))
			if Run.has("duo_anubi_sekhmet") and not e.is_boss and not e.miniboss and e.hp < e.max_hp * 0.15:
				Fx.float_text(e.global_position + Vector2(0, -24), Lang.t("GIUDIZIO"), Boons.god_color("duo"))
				e.die()
		hit_any = true
	if swing_index == 2 and Run.has("sekhmet_roar"):
		_shockwave(46.0, Run.val("sekhmet_roar") * Run.all_damage_mult(), 200.0, Boons.god_color("sekhmet"))
	if hit_any:
		var heavy := swing_index >= 2
		Fx.shake(3.0 if not heavy else 6.0)
		Fx.hitstop(0.045 if not heavy else 0.08)
		Fx.punch(swing_dir, 2.5 if not heavy else 5.0)


## Distanza lungo la frustata se `to` (dal giocatore) è dentro, altrimenti -1.
func _in_lash(to: Vector2, r: float) -> float:
	var proj := to.dot(swing_dir)
	if proj < -r or proj > swing_range + r:
		return -1.0
	if lash_width > 0.0:
		return proj if absf(to.dot(swing_dir.orthogonal())) <= lash_width + r else -1.0
	return to.length() if absf(swing_dir.angle_to(to)) <= swing_arc * 0.5 or to.length() < r + 6.0 else -1.0


func _swing() -> void:
	if Run.weapon == "arco":
		_bow_shot()
		return
	if Run.weapon == "flagello":
		_flail_swing()
		return
	if combo_window <= 0.0:
		combo = 0
	var spear := Run.weapon == "lancia"
	var table: Array = SPEAR if spear else COMBO
	var c: Dictionary = table[combo]
	swing_index = combo
	spin_swing = false
	# l'attacco in scatto (durante lo scatto o subito dopo): la lancia affonda in corsa e trapassa la
	# fila, il khopesh fa un fendente più largo e più lungo. Non fa avanzare la combo.
	var dash_atk := after_dash_t > 0.0
	var lunging := dash_atk and spear
	if dash_atk:
		c = SPEAR_LUNGE if spear else KHOPESH_DASH
		swing_index = 3
	else:
		combo = (combo + 1) % table.size()
	combo_window = 0.55
	atk_t = 0.14
	atk_cd = c["cd"] * Run.attack_speed_mult()
	swing_range = c["range"]
	swing_arc = deg_to_rad(c["arc"])
	var lunge: float = c["lunge"]
	var aspect_mult := _aspect_damage()
	if swing_index == 2 and Run.aspect == "montu":
		aspect_mult *= 1.0 + Run.aspect_val("montu") / 100.0
		swing_range += 8.0
		lunge *= 1.6
	if spear and swing_index < 2 and Run.aspect == "onuris":
		swing_range *= 1.0 + Run.aspect_val("onuris") / 100.0
	# doni delle armi
	var sweep := spear and swing_index == 2 and not lunging
	if not spear:
		if Run.has("ra_edge"):
			swing_range *= 1.0 + Run.val("ra_edge") / 100.0
			swing_arc += deg_to_rad(20.0)
		if swing_index < 2 and Run.has("sekhmet_crescent"):
			aspect_mult *= 1.0 + Run.val("sekhmet_crescent") / 100.0
		if Run.has("bastet_dance"):
			atk_cd /= 1.0 + Run.val("bastet_dance") / 100.0
	elif sweep and Run.has("sobek_tail"):
		aspect_mult *= 1.0 + Run.val("sobek_tail") / 100.0
	# Aspetto di Wepwawet: l'attacco in scatto del khopesh diventa un fendente circolare, più forte
	if dash_atk and not spear and Run.aspect == "wepwawet":
		swing_arc = TAU
		aspect_mult *= 1.0 + Run.aspect_val("wepwawet") / 100.0
		spin_swing = true
		Fx.burst(global_position + Vector2(0, -8), Color(0.62, 0.56, 0.92), 14, 90.0)
	elif dash_atk and not spear:
		Fx.burst(global_position + Vector2(0, -8) + aim * 16.0, Color(0.98, 0.86, 0.45), 8, 70.0)
	after_dash_t = 0.0
	# l'attacco in scatto va nella direzione dello scatto (con la mira automatica il nemico più
	# vicino può essere già alle tue spalle: lo scatto attraversa i nemici); mouse e levetta destra
	# decidono loro
	var base_dir := aim
	if dash_atk and Fx.device != "mouse" and Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down").length() <= 0.3 and dash_dir != Vector2.ZERO:
		base_dir = dash_dir
	swing_dir = _assisted(base_dir, swing_range + 24.0)
	Sfx.play("swing", 0.15)
	if lunging:
		# l'affondo dopo lo scatto si deve vedere: scia dorata lungo la lancia
		for i in range(4):
			Fx.burst(global_position + Vector2(0, -6) + swing_dir * (18.0 + i * 18.0), Color(0.98, 0.86, 0.45), 4, 50.0)
	knock = swing_dir * lunge

	var dmg: float = attack_damage * Run.khopesh_mult() * c["mult"] * Run.combo_mult(swing_index) * aspect_mult
	if divine_t > 0.0:
		dmg *= divine_damage_mult
	# Balzo della Leonessa: potenzia l'attacco in scatto
	if dash_atk and Run.has("sekhmet_leap"):
		dmg *= 1.0 + Run.val("sekhmet_leap") / 100.0
	leap_ready = false

	var hit_any := false
	# giare d'olio a portata di lama
	for j in get_tree().get_nodes_in_group("breakables"):
		var tj: Vector2 = j.global_position - global_position
		if not j.broken and tj.length() < swing_range + 8.0 and (absf(swing_dir.angle_to(tj)) <= swing_arc * 0.5 or tj.length() < 14.0):
			j.smash()
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead:
			continue
		var to: Vector2 = e.global_position - global_position
		var reach: float = swing_range + e.radius
		if to.length() > reach:
			continue
		if absf(swing_dir.angle_to(to)) <= swing_arc * 0.5 or to.length() < e.radius + 6.0:
			var crit_chance := Run.khopesh_crit_chance()
			if lunging and Run.has("bastet_point"):
				crit_chance += Run.val("bastet_point") / 100.0
			var crit := Run.roll_crit(crit_chance)
			var hit_dmg := dmg * crit
			if spear and not sweep and Run.has("horus_harpoon") and to.length() > swing_range * 0.5:
				hit_dmg *= 1.0 + Run.val("horus_harpoon") / 100.0
			if Run.has("duo_ra_sekhmet") and e.burn_t > 0.0:
				hit_dmg *= 1.25
			if Run.has("duo_sobek_iside") and shield > 0.0:
				hit_dmg *= 1.25
			if e.mark_t > 0.0:
				hit_dmg *= 1.0 + Run.val("horus_mark") / 100.0
			if crit > 1.0:
				Fx.float_text(e.global_position + Vector2(0, -20), Lang.t("CRITICO"), Boons.god_color("bastet"))
				Sfx.play("crit")
				if Run.has("duo_sekhmet_bastet"):
					_shockwave.call_deferred(40.0, 12.0 * Run.all_damage_mult(), 150.0, Boons.god_color("duo"))
			var kb: float = c["knock"] * Run.knock_mult() * (2.0 if sweep and Run.has("sobek_tail") else 1.0)
			if Run.has("nefti_veil"):
				e.mourn_t = 4.0                  # Velo del Lutto
			Run.nefti_on_hit()
			e.take_hit(hit_dmg, to.normalized(), kb, Run.khopesh_burns())
			# scintilla dove la lama tocca: sul bordo del nemico rivolto verso di te
			var heavy_hit := swing_index >= 2 or crit > 1.0
			Fx.impact(e.global_position + Vector2(0, -e.radius) - to.normalized() * e.radius * 0.6, to.normalized(), heavy_hit)
			if spear and swing_index == 2 and Run.aspect == "khonsu" and not e.dead:
				e.stagger_t = maxf(e.stagger_t, Run.aspect_val("khonsu") * (0.3 if (e.is_boss or e.miniboss) else 1.0))
			if not e.dead and not e.is_boss and not e.miniboss:
				# Giudizio della Leonessa (Anubi e Sekhmet): sotto il 15% della vita il nemico cade
				if Run.has("duo_anubi_sekhmet") and e.hp < e.max_hp * 0.15:
					Fx.float_text(e.global_position + Vector2(0, -24), Lang.t("GIUDIZIO"), Boons.god_color("duo"))
					e.die()
			# Arpione del Coccodrillo (Sobek e Horus): la punta della lancia stordisce
			if spear and not sweep and Run.has("duo_sobek_horus") and not e.dead and to.length() > swing_range * 0.5:
				e.stagger_t = maxf(e.stagger_t, 0.6 * (0.25 if (e.is_boss or e.miniboss) else 1.0))
			# Soffio di Shu: il colpo finale della combo spinge forte (lo schianto è in enemy.gd)
			if swing_index == 2 and Run.has("shu_breath") and not e.dead:
				e.shu_push(to.normalized(), 330.0)
			if swing_index == 2 and Run.has("sobek_bite") and not e.dead:
				var stun: float = Run.val("sobek_bite") * (0.25 if e.is_boss else 1.0)
				e.stagger_t = maxf(e.stagger_t, stun)
				e.sobek_stun_t = maxf(e.sobek_stun_t, Run.val("sobek_bite"))
			hit_any = true
	if swing_index == 2 and Run.has("sekhmet_roar"):
		_shockwave(46.0, Run.val("sekhmet_roar") * Run.all_damage_mult(), 200.0, Boons.god_color("sekhmet"))
	if hit_any:
		var heavy := swing_index >= 2
		Fx.shake(3.0 if not heavy else 6.0)
		Fx.hitstop(0.045 if not heavy else 0.08)
		Fx.punch(swing_dir, 2.5 if not heavy else 5.0)


func _shockwave(radius: float, dmg: float, kb: float, color: Color) -> void:
	Fx.burst(global_position + Vector2(0, -6), color, 30, radius * 3.0)
	Fx.shake(5.0)
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.dead and global_position.distance_to(e.global_position) < radius + e.radius:
			e.take_hit(dmg, (e.global_position - global_position).normalized(), kb)


func eye_ready() -> bool:
	return eye_charges > 0


func _fire_eye() -> void:
	eye_charges -= 1
	if eye_cd <= 0.0:
		eye_cd = eye_cd_max()
	Sfx.play("eye")
	var rays := Run.eye_rays()
	var base := aim.angle()
	for i in range(rays):
		var dir := Vector2.from_angle(base + (i - (rays - 1) / 2.0) * 0.22)
		var eye: Area2D = EyeScript.new()
		eye.direction = dir
		eye.damage = eye_damage * Run.eye_damage_mult() * (0.6 if rays > 1 else 1.0)
		eye.pierce_left = Run.eye_pierce()
		eye.explode_damage = Run.val("ra_disc") * Run.all_damage_mult()
		eye.seek = Run.has("horus_seek")
		eye.return_mult = Run.val("horus_return") / 100.0
		if Run.has("duo_shu_horus"):
			eye.return_mult = maxf(eye.return_mult, 0.7)     # Ali del Falco: il vento lo riporta indietro
		eye.mark = Run.has("horus_mark")
		eye.burns = Run.eye_burns() or Run.has("duo_ra_thoth")
		if Run.has("duo_ra_thoth"):
			eye.explode_damage = maxf(eye.explode_damage, 12.0 * Run.all_damage_mult())
		get_parent().add_child(eye)
		eye.global_position = global_position + Vector2(0, -8) + dir * 10.0


func _divine_form() -> void:
	Run.sekhem = 0.0
	Sfx.play("divine", 0.0)
	divine_t = divine_time
	Run.divine = true
	Fx.hitstop(0.12)
	_shockwave(divine_wave_radius, divine_wave_damage * Run.all_damage_mult(), 320.0, Color(1, 0.85, 0.4))
	Fx.shake(10.0)


## Sete Insaziabile (e la maledizione di Set "bleed"): perdi vita finché ci sono nemici,
## ma non può ucciderti.
func _heavy_drain(delta: float) -> void:
	# la Sete Insaziabile toglie 1 vita ogni 2 secondi, la maledizione di Set ogni 3
	var drains := float(Run.has("sekhmet_heavy")) + (0.67 if Run.cursed("bleed") else 0.0)
	if drains <= 0.0 or get_tree().get_nodes_in_group("enemies").is_empty():
		return
	drain_t -= delta * drains
	if drain_t <= 0.0:
		drain_t = 2.0
		if hp > 1.0:
			hp -= 1.0
			Run.hp = hp
			Fx.float_text(global_position, "-1", Color(0.9, 0.3, 0.3))
			health_changed.emit(hp, max_hp)


## Veleno (scorpione di Serket): 2 vita ogni 0,6 secondi. Non può ucciderti.
## Le punture si sommano: se sei già avvelenato il veleno dura di più (fino a 7 secondi).
var poison_src := "scorpion"              ## chi ti ha avvelenato (per i commenti di Anubi)

func poison(seconds: float, src: String = "scorpion") -> void:
	poison_src = src
	if poison_t > 0.0:
		poison_t = minf(7.0, poison_t + seconds * 0.5)
	else:
		poison_t = seconds


func _poison_update(delta: float) -> void:
	if poison_t <= 0.0:
		return
	poison_t -= delta
	poison_tick -= delta
	if poison_tick <= 0.0:
		poison_tick = 0.6
		if hp > 1.0:
			hp = maxf(1.0, hp - 2.0)
			Run.hp = hp
			Run.last_hit = poison_src
			Fx.float_text(global_position + Vector2(0, -16), "-2", Color(0.5, 1, 0.4))
			health_changed.emit(hp, max_hp)


## Restituisce true se il colpo è andato a segno (false se eri invulnerabile).
## `kind` dice chi ha colpito quando non c'è un nemico (per esempio il fuoco di Am-heh).
func take_damage(amount: float, from_pos: Vector2, attacker: Node = null, kind: String = "") -> bool:
	if dead or invuln_t > 0.0 or dash_t > 0.0:
		return false
	amount *= Run.damage_taken_mult()
	# Nodo di Iside: le trappole fanno meno male (spuntoni, grate, olio, statue dell'ureo)
	if Run.wears("iside") and attacker == null and kind in ["", "grata", "ureo", "olio"]:
		amount *= 1.0 - Amulets.val_of("iside") / 100.0
		if amount <= 0.05:
			invuln_t = 0.3
			Fx.float_text(global_position + Vector2(0, -14), Lang.t("Il nodo di Iside ti protegge"), Color(0.86, 0.32, 0.26))
			return false
	if Run.training:
		amount = minf(amount, hp - 1.0)       # nel Cortile di Neith i colpi si sentono, ma non uccidono
	if Run.chap("c151") and not Run.mask_used:
		Run.mask_used = true                 # la maschera attutisce il primo colpo della stanza
		amount *= 1.0 - Chapters.value("c151") / 100.0
	if shield > 0.0:
		var absorbed := minf(shield, amount)
		shield -= absorbed
		amount -= absorbed
		Fx.float_text(global_position + Vector2(0, -14), Lang.t("Scudo -%d") % int(absorbed), Boons.god_color("iside"))
		if amount <= 0.0:
			invuln_t = 0.4
			return true
	if divine_t > 0.0:
		amount *= divine_armor
	else:
		Run.add_sekhem(amount * 0.5)
		knock = (global_position - from_pos).normalized() * 230.0
	hp -= amount
	Run.room_hit = true
	Run.last_hit = "trappola"
	if attacker != null and attacker.scene_file_path != "":
		Run.last_hit = attacker.scene_file_path.get_file().get_basename()
	if kind != "":
		Run.last_hit = kind
	if Run.has("anubi_scale") and attacker != null and not attacker.dead:
		attacker.take_hit(amount * Run.val("anubi_scale") / 100.0, (attacker.global_position - global_position).normalized(), 120.0)
		Fx.burst(attacker.global_position + Vector2(0, -8), Boons.god_color("anubi"), 12, 80.0)
	invuln_t = hit_invuln
	flash_t = 0.15
	Sfx.play("hurt")
	Fx.vibrate(0.12 if amount < 12.0 else 0.22, clampf(amount / 20.0, 0.3, 1.0))   # Opzioni: vibrazione
	Fx.shake(7.0)
	Fx.hitstop(0.08)
	Fx.damage_number(global_position, amount, Color(1, 0.4, 0.3))
	if hp <= 0.0 and Run.chap("c30") and not Run.heart_used:
		Run.heart_used = true
		hp = maxf(1.0, roundf(max_hp * Chapters.value("c30") / 100.0))
		invuln_t = 1.5
		Fx.float_text(global_position + Vector2(0, -20), Lang.t("Il cuore non testimonia"), Color(0.62, 0.56, 0.92))
		Fx.burst(global_position + Vector2(0, -10), Color(0.62, 0.56, 0.92), 30, 140.0)
	if hp <= 0.0 and Run.has("bastet_lives") and not Run.revived:
		Run.revived = true
		hp = roundf(max_hp * Run.val("bastet_lives") / 100.0)
		invuln_t = 1.5
		Fx.burst(global_position + Vector2(0, -10), Boons.god_color("bastet"), 40, 160.0)
		Fx.float_text(global_position + Vector2(0, -20), Lang.t("Bastet ti protegge!"), Boons.god_color("bastet"))
	if hp <= 0.0:
		hp = 0.0
		dead = true
		Sfx.play("death", 0.0)
		divine_t = 0.0
		Run.divine = false
		Fx.burst(global_position, Color(0.9, 0.2, 0.15), 30, 160.0)
		queue_redraw()
		died.emit()
	Run.hp = hp
	health_changed.emit(hp, max_hp)
	return true


# ---------------------------------------------------------------- disegno provvisorio
# Forme semplici al posto degli sprite: servono solo a provare il combattimento.

## Il protagonista: crede di essere uno scriba (la tavolozza con i due pozzetti d'inchiostro alla
## cintura, gli occhi con il kohl, il gonnellino di lino) ma porta il khat a righe blu e oro, il
## copricapo della gente comune che ricorda il nemes dei faraoni, e un mantello scuro e logoro.
## Il collare blu e oro lo fa risaltare nella penombra. Nella Forma Divina il khat diventa per
## un attimo il nemes dorato con l'ureo sulla fronte: chi conosce l'Egitto capisce chi è davvero.
## Disegnato in scala 0,8: misura e colpi restano quelli di prima. `off` sposta tutto (le scie).
func _draw_hero(off: Vector2, a: float, bob: float) -> void:
	var divine := divine_t > 0.0
	var skin := Color(0.72, 0.46, 0.27, a)
	var linen := Color(0.95, 0.91, 0.8, a)
	var linen_d := Color(0.78, 0.72, 0.6, a)
	var gold := Color(0.94, 0.72, 0.3, a)
	var blue := Color(0.18, 0.33, 0.72, a)
	var cloak := Color(0.2, 0.17, 0.22, a)
	var ink := Color(0.08, 0.06, 0.05, a)
	var out := Color(0.12, 0.08, 0.05, a)
	if divine:
		cloak = Color(0.55, 0.38, 0.12, a)
		linen = Color(1, 0.94, 0.7, a)
	if poison_t > 0.0:
		skin = skin.lerp(Color(0.45, 0.9, 0.35, a), 0.45)
	if flash_t > 0.0:
		skin = Color(1, 1, 1, a); linen = skin; linen_d = skin; gold = skin; blue = skin; cloak = skin
	var moving := velocity.length() > 10.0
	var prof := absf(facing.x) > 0.55             # di profilo quando vai di lato
	var dir := -1.0 if facing.x < -0.05 else 1.0
	var w := sin(walk) if moving else 0.0
	draw_set_transform(off + Vector2(0, bob * 0.5), 0.0, Vector2(0.8 * dir, 0.8))
	# gambe (con i sandali): di profilo si alternano davanti e dietro
	var legs := [-1.5 + w * 2.5, 1.5 - w * 2.5] if prof else [-3.0 + w * 0.8, 3.0 - w * 0.8]
	for lx in legs:
		var lift := (absf(w) * 1.2) if moving else 0.0
		draw_rect(Rect2(lx - 1.6, -9, 3.2, 9 - lift * 0.3), out)
		draw_rect(Rect2(lx - 1.1, -9, 2.2, 8.5 - lift * 0.3), skin)
		draw_rect(Rect2(lx - 1.8, -1.2 - lift * 0.3, 3.8, 1.6), Color(0.55, 0.38, 0.2, a))
	# torso e gonnellino di lino con la cintura d'oro
	var torso := PackedVector2Array([Vector2(-5.5, -24), Vector2(5.5, -24), Vector2(4.5, -15), Vector2(-4.5, -15)])
	draw_colored_polygon(torso, skin)
	draw_polyline(torso + PackedVector2Array([torso[0]]), out, 0.8)
	var kilt := PackedVector2Array([Vector2(-5, -15.5), Vector2(5, -15.5), Vector2(6.5, -8), Vector2(-6.5, -8)])
	draw_colored_polygon(kilt, linen)
	draw_polyline(kilt + PackedVector2Array([kilt[0]]), out, 0.8)
	draw_line(Vector2(0.5, -15), Vector2(2.5, -8.5), linen_d, 0.8)
	draw_rect(Rect2(-5, -16.5, 10, 1.6), gold)
	# il mantello scuro e logoro sulle spalle (si muove un poco camminando)
	var flap := w * 0.8
	var cl := PackedVector2Array([Vector2(-6.5, -24), Vector2(6.5, -24), Vector2(7.5 - flap, -12), Vector2(4, -14), Vector2(0, -12 + flap), Vector2(-4, -14), Vector2(-7.5 + flap, -12)])
	draw_colored_polygon(cl, cloak)
	draw_polyline(cl + PackedVector2Array([cl[0]]), out, 0.8)
	# il collare usekh, blu e oro
	draw_arc(Vector2(0, -24.5), 4.5, 0.1, PI - 0.1, 10, blue, 2.2)
	draw_arc(Vector2(0, -24.5), 6.0, 0.15, PI - 0.15, 10, gold, 1.2)
	# braccia
	var swing := w * 1.5
	for sx in [-1.0, 1.0]:
		var hand_p := Vector2(sx * 7.0 + sx * swing * (1.0 if prof else 0.3), -15)
		draw_line(Vector2(sx * 6.0, -23), hand_p, out, 2.8)
		draw_line(Vector2(sx * 6.0, -23), hand_p, skin, 1.8)
	# la tavolozza da scriba alla cintura: legno chiaro, due pozzetti (nero e rosso), i calami
	draw_set_transform(off + Vector2(0, bob * 0.5) + Vector2(4.4 * dir, -11.2), 0.25 * dir, Vector2(0.8 * dir, 0.8))
	draw_rect(Rect2(-1.3, -0.2, 2.6, 8.5), out)
	draw_rect(Rect2(-0.9, 0.2, 1.8, 7.7), Color(0.82, 0.68, 0.42, a))
	draw_circle(Vector2(0, 1.4), 0.6, ink)
	draw_circle(Vector2(0, 2.9), 0.6, Color(0.75, 0.15, 0.1, a))
	draw_line(Vector2(0, 4.2), Vector2(0, 7.4), Color(0.4, 0.3, 0.18, a), 0.5)
	draw_set_transform(off + Vector2(0, bob * 0.5), 0.0, Vector2(0.8 * dir, 0.8))
	# testa
	var hc := Vector2(0, -29.5)
	draw_circle(hc, 4.6, out)
	draw_circle(hc, 4.0, skin)
	# il copricapo: khat a righe blu e oro; nella Forma Divina il nemes dorato con l'ureo
	var cloth := gold if divine else blue
	var stripe := blue if divine else gold
	var head := PackedVector2Array([Vector2(-5, -32.2), Vector2(0, -35.5), Vector2(5, -32.2), Vector2(5.4, -30.8), Vector2(-5.4, -30.8)])
	var flap_l := PackedVector2Array([Vector2(-5.4, -30.8), Vector2(-3.6, -30.8), Vector2(-3.4, -25.5), Vector2(-5.8, -26)])
	var flap_r := PackedVector2Array([Vector2(5.4, -30.8), Vector2(3.6, -30.8), Vector2(3.4, -25.5), Vector2(5.8, -26)])
	if prof:
		flap_l = PackedVector2Array([Vector2(-5.4, -30.8), Vector2(-1.5, -30.8), Vector2(-3.0, -24.5), Vector2(-5.8, -25.5)])
		flap_r = PackedVector2Array()
	for poly in [head, flap_l, flap_r]:
		if poly.size() < 3:
			continue
		draw_colored_polygon(poly, cloth)
		draw_polyline(poly + PackedVector2Array([poly[0]]), out, 0.6)
	# le righe solo sulla stoffa: due sul capo, tre sulle bande che scendono
	draw_line(Vector2(-4.2, -33.2), Vector2(4.2, -33.2), stripe, 0.6)
	draw_line(Vector2(-5.0, -31.8), Vector2(5.0, -31.8), stripe, 0.6)
	for k in range(3):
		var yy := -29.5 + k * 1.4
		draw_line(Vector2(-5.4, yy), Vector2(-3.6, yy), stripe, 0.5)
		if not prof:
			draw_line(Vector2(3.6, yy), Vector2(5.4, yy), stripe, 0.5)
	if divine:
		# l'ureo, il cobra d'oro sulla fronte del re
		draw_line(Vector2(0.8, -33.5), Vector2(1.4, -36.5), Color(0.95, 0.8, 0.35, a), 1.2)
		draw_circle(Vector2(1.5, -36.8), 0.9, Color(0.95, 0.8, 0.35, a))
	# occhi alla maniera egizia: bianco a mandorla, pupilla, il kohl allungato verso la tempia
	var eyes := [1.8] if prof else [1.8, -1.8]
	for ex in eyes:
		var back := 1.0 if ex > 0.0 else -1.0
		draw_colored_polygon(PackedVector2Array([Vector2(ex - 1.2 * back, -29.4), Vector2(ex, -30.1), Vector2(ex + 1.2 * back, -29.4), Vector2(ex, -28.9)]), Color(0.97, 0.95, 0.9, a))
		draw_circle(Vector2(ex + 0.2 * back, -29.45), 0.5, ink)
		draw_line(Vector2(ex - 1.3 * back, -29.5), Vector2(ex + 2.1 * back, -29.7), ink, 0.45)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Il khopesh: impugnatura di legno con la guardia d'oro, un tratto dritto e poi la lama a falce
## di bronzo, con il filo all'esterno. Contorno scuro: si legge anche sul telefono.
func _draw_khopesh(hand: Vector2, wdir: Vector2, sc: float, a: float) -> void:
	var n := wdir.orthogonal() * (-1.0 if wdir.x >= 0.0 else 1.0)    # la falce si apre verso l'alto
	var outline := Color(0.16, 0.1, 0.05, a)
	var bronze := Color(0.86, 0.7, 0.42, a)
	var edge := Color(1.0, 0.97, 0.88, a)
	var grip_a := hand - wdir * 3.0 * sc
	var grip_b := hand + wdir * 3.0 * sc
	draw_line(grip_a, grip_b, outline, 4.0)
	draw_line(grip_a, grip_b, Color(0.42, 0.26, 0.12, a), 2.4)
	draw_line(grip_b - n * 2.5, grip_b + n * 2.5, Color(0.94, 0.72, 0.3, a), 1.6)   # la guardia
	var shaft_end := grip_b + wdir * 6.0 * sc
	draw_line(grip_b, shaft_end, outline, 3.6)
	draw_line(grip_b, shaft_end, bronze, 2.0)
	# la falce: una mezzaluna attorno a un centro poco oltre il tratto dritto
	var c := shaft_end + wdir * 4.5 * sc + n * 1.5 * sc
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	var a0 := (shaft_end - c).angle()
	for i in range(9):
		var f := i / 8.0
		var ang := a0 + f * deg_to_rad(230.0) * (1.0 if n.cross(wdir) < 0.0 else -1.0)
		outer.append(c + Vector2.from_angle(ang) * 6.0 * sc)
		inner.append(c + Vector2.from_angle(ang) * lerpf(4.2, 1.2, f) * sc)
	var poly := outer.duplicate()
	for i in range(inner.size() - 1, -1, -1):
		poly.append(inner[i])
	draw_colored_polygon(poly, bronze)
	draw_polyline(poly + PackedVector2Array([poly[0]]), outline, 1.0)
	draw_polyline(outer, edge, 1.0)


## Le cariche dello scatto: due puntini sotto i piedi. Pieni = pronte, vuoti = in ricarica
## (si riempiono man mano che passa la pausa). Nella Sala non servono.
func _draw_dash_pips() -> void:
	if Run.in_hub:
		return
	var full := Color(0.95, 0.88, 0.62, 0.9)
	var empty := Color(0.1, 0.08, 0.06, 0.55)
	var fill := 1.0 - dash_cd / maxf(0.01, dash_cd_max()) if dash_charges < DASH_CHARGES else 1.0
	for i in range(DASH_CHARGES):
		var at := Vector2((i - (DASH_CHARGES - 1) / 2.0) * 7.0, 7.5)
		draw_circle(at, 2.4, empty)
		if i < dash_charges:
			draw_circle(at, 1.9, full)
		else:
			draw_arc(at, 2.0, -PI / 2.0, -PI / 2.0 + TAU * fill, 10, Color(full, 0.6), 1.0)
	if dash_ready_t > 0.0:
		draw_arc(Vector2(0, 7.5), 9.0 - dash_ready_t * 16.0, 0.0, TAU, 16, Color(1, 0.9, 0.6, dash_ready_t * 3.0), 1.2)


## Il cerchio sopra la testa: si riempie mentre carichi l'attacco caricato, lampeggia quando è
## pieno, e dopo l'uso mostra la ricarica (grigio che torna d'oro).
func _draw_charge() -> void:
	var c := Vector2(0, -36)
	var r := 6.0
	if charging and hold_t >= CHARGE_DELAY:
		draw_circle(c, r + 1.5, Color(0, 0, 0, 0.45))
		draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * charge_k, 24, Color(1.0, 0.85, 0.4, 0.95), 2.5)
		if charge_full:
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 60.0)
			draw_circle(c, r - 1.5, Color(1.0, 0.92, 0.6, 0.5 + 0.4 * pulse))
			draw_arc(c, r + 2.5 + pulse * 1.5, 0.0, TAU, 24, Color(1.0, 0.9, 0.5, 0.7), 1.2)
		if charge_flash_t > 0.0:
			draw_circle(c, r + 8.0 * (1.0 - charge_flash_t / 0.25), Color(1, 1, 0.8, charge_flash_t * 2.0))
	elif charge_cd > 0.0:
		var k := 1.0 - charge_cd / _charge_cd_max()
		draw_circle(c, r + 1.5, Color(0, 0, 0, 0.35))
		draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * k, 24, Color(0.6, 0.6, 0.65, 0.8), 2.0)


## Il pastorale: mentre carichi indica chi aggancerai (dorato = lo tiri a te, rosso = voli tu da lui);
## dopo il rilascio si allunga fino al nemico agganciato.
func _draw_hook(hand: Vector2, bob: float) -> void:
	var from := Vector2(0, -10 + bob)
	if hook_vis_t > 0.0:
		var to := hook_to - global_position + Vector2(0, -6)
		var col := FlailArt.RED if hook_red else FlailArt.GOLD
		var k := clampf(hook_vis_t / 0.35, 0.0, 1.0)
		draw_line(from, to, Color(col, 0.35 * k), 4.0)
		FlailArt.draw_crook(self, from, (to - from).normalized(), maxf(10.0, (to - from).length()), col)
		return
	var tgt = _hook_target(aim)
	if tgt != null:
		var col2 := FlailArt.RED if _hook_heavy(tgt) else FlailArt.GOLD
		var tp: Vector2 = tgt.global_position - global_position + Vector2(0, -6)
		var dirt := (tp - from).normalized()
		var dl := (tp - from).length()
		var dd := 0.0
		while dd < dl:
			draw_line(from + dirt * dd, from + dirt * minf(dd + 5.0, dl), Color(col2, 0.3 + 0.5 * charge_k), 1.2)
			dd += 10.0
		draw_arc(tp, tgt.radius + 5.0, 0.0, TAU, 20, Color(col2, 0.4 + 0.5 * charge_k), 1.5)
		FlailArt.draw_crook(self, hand, dirt, 16.0, col2)
	else:
		FlailArt.draw_crook(self, hand, aim, 16.0, FlailArt.GOLD)


func _draw() -> void:
	if dead:
		return
	var blink := invuln_t > 0.0 and dash_t <= 0.0 and divine_t <= 0.0 and Time.get_ticks_msec() % 120 < 60
	var a := 0.35 if blink else 1.0
	var bob := sin(walk) * 1.0

	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 9.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	_draw_dash_pips()
	_draw_charge()
	if shield > 0.0:
		draw_arc(Vector2(0, -12), 15.0, 0.0, TAU, 28, Color(Boons.god_color("iside"), 0.7), 1.5)
	if divine_t > 0.0:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 90.0)
		draw_circle(Vector2(0, -12), 18.0 + pulse * 3.0, Color(1, 0.8, 0.3, 0.18))
		draw_arc(Vector2(0, -12), 18.0 + pulse * 3.0, 0.0, TAU, 32, Color(1, 0.85, 0.4, 0.6), 1.5)

	# durante lo scatto: due scie del personaggio, sempre più trasparenti, dietro di lui
	if dash_t > 0.0:
		for k in [2, 1]:
			_draw_hero(-dash_dir * 7.0 * k, 0.18 * (3 - k), bob)
	_draw_hero(Vector2.ZERO, a, bob)

	# l'arma in mano: la lancia lungo la mira, il khopesh ricurvo accanto alla mano
	# durante il colpo l'arma si muove: il khopesh attraversa l'arco, la lancia affonda e torna
	var swing_k := clampf(1.0 - atk_t / 0.14, 0.0, 1.0) if atk_t > 0.0 else -1.0
	var wdir := aim
	if swing_k >= 0.0:
		wdir = swing_dir
		if Run.weapon == "khopesh" or (Run.weapon == "lancia" and swing_index == 2 and not spin_swing):
			var side_sign := -1.0 if swing_index % 2 == 0 else 1.0
			var half := minf(swing_arc, PI * 1.2) * 0.5
			wdir = swing_dir.rotated(side_sign * lerpf(-half, half, ease(swing_k, 0.4)))
	var hand := Vector2(0, -11 + bob) + wdir * 5.0
	if Run.weapon == "flagello":
		if charging or hook_vis_t > 0.0:
			_draw_hook(hand, bob)
		elif atk_t > 0.0:
			var lk := clampf(1.0 - atk_t / 0.16, 0.0, 1.0)
			var from := Vector2(0, -10 + bob) + swing_dir * 6.0
			var bright := Color(1, 0.85, 0.4) if divine_t > 0.0 else FlailArt.BEAD
			if lash_width > 0.0:
				FlailArt.draw_lash(self, from, swing_dir, swing_range, lk, bright)
			else:
				for k: float in [-0.5, 0.0, 0.5]:
					FlailArt.draw_lash(self, from, swing_dir.rotated(swing_arc * k * 0.85), swing_range, lk, bright)
		else:
			FlailArt.draw_flail(self, hand, aim, 1.0)
	elif Run.weapon == "arco":
		# l'arco teso verso la mira: la corda si tira mentre carichi, scatta dopo il tiro
		var bdir := swing_dir if atk_t > 0.0 else aim
		var pull := charge_k if charging else 0.0
		ArrowArt.draw_bow(self, Vector2(0, -11 + bob) + bdir * 9.0, bdir.angle(), 0.8, pull)
	elif Run.weapon == "lancia" and spear_thrown != null and is_instance_valid(spear_thrown):
		pass                                # la lancia è in volo: mano vuota
	elif Run.weapon == "lancia":
		var reach := 26.0
		if swing_k >= 0.0:
			reach = 26.0 + sin(swing_k * PI) * (swing_range - 26.0) * 0.6
		draw_line(hand - wdir * 8.0, hand + wdir * reach, Color(0.55, 0.38, 0.2, a), 1.6)
		var tipp := hand + wdir * reach
		draw_colored_polygon(PackedVector2Array([tipp + wdir * 6.0, tipp + wdir.orthogonal() * 2.2, tipp - wdir.orthogonal() * 2.2]), Color(0.85, 0.85, 0.9, a))
	else:
		_draw_khopesh(hand, wdir, 1.0 if swing_k < 0.0 else 1.15, a)
	# indicatore di mira
	var tip := Vector2(0, -8) + aim * 20.0
	var side := aim.orthogonal() * 4.0
	draw_colored_polygon(PackedVector2Array([tip + aim * 5.0, tip + side, tip - side]), Color(0.94, 0.72, 0.3, 0.8))

	# il colpo a giro dell'attacco caricato: un'onda d'oro che si allarga fino alla portata
	if atk_t > 0.0 and spin_swing and swing_arc >= TAU - 0.01:
		var k := 1.0 - atk_t / 0.2
		draw_arc(Vector2(0, -4), swing_range * (0.55 + 0.45 * k), 0.0, TAU, 40, Color(1.0, 0.85, 0.4, 0.9 * (1.0 - k)), 4.0)
		draw_arc(Vector2(0, -4), swing_range * (0.4 + 0.45 * k), 0.0, TAU, 40, Color(1.0, 0.97, 0.8, 0.6 * (1.0 - k)), 2.0)
	# fendente: la zona disegnata è esattamente quella che colpisce (l'arco non ha fendenti)
	if atk_t > 0.0 and Run.weapon != "arco" and Run.weapon != "flagello":
		var pts := PackedVector2Array()
		var steps := 14
		var base := swing_dir.angle()
		for i in range(steps + 1):
			var ang := base - swing_arc * 0.5 + swing_arc * float(i) / steps
			pts.append(Vector2.from_angle(ang) * swing_range)
		for i in range(steps, -1, -1):
			var ang := base - swing_arc * 0.5 + swing_arc * float(i) / steps
			pts.append(Vector2.from_angle(ang) * swing_range * 0.4)
		var col := Color(1.0, 0.75, 0.3, 0.6) if divine_t > 0.0 else Color(1.0, 0.88, 0.55, 0.18 + atk_t * 1.6)
		draw_colored_polygon(pts, col)
		# la scia: un filo luminoso sul bordo esterno che si apre con il movimento della lama
		var sk := clampf(1.0 - atk_t / 0.14, 0.0, 1.0)
		var trail := PackedVector2Array()
		var from_k := maxf(0.0, ease(sk, 0.4) - 0.65)
		var to_k := ease(sk, 0.4)
		var sgn := -1.0 if swing_index % 2 == 0 else 1.0
		for i in range(11):
			var f := lerpf(from_k, to_k, i / 10.0)
			var ang2 := base + sgn * (-swing_arc * 0.5 + swing_arc * f)
			trail.append(Vector2.from_angle(ang2) * swing_range * 0.94)
		var bright := Color(1, 0.97, 0.85, 0.95) if divine_t <= 0.0 else Color(1, 0.85, 0.4, 0.95)
		if swing_arc < deg_to_rad(60.0):
			# affondo: una scia dritta lungo la lancia, che corre fino alla punta
			var dpos := swing_dir * swing_range
			draw_line(swing_dir * swing_range * lerpf(0.3, 0.75, sk), dpos * lerpf(0.75, 1.0, sk), bright, 3.0)
			draw_line(swing_dir * swing_range * 0.3, dpos * lerpf(0.75, 1.0, sk), Color(bright, 0.35), 1.5)
		else:
			draw_polyline(trail, bright, 3.0 if swing_index == 2 else 2.0)
		if Fx.show_hitboxes:
			draw_polyline(pts, Color(1, 0.2, 0.2, 0.9), 1.0)
