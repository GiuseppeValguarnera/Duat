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
@export var dash_cooldown := 0.55

@export_group("Khopesh")
@export var attack_damage := 12.0
@export var aim_assist_degrees := 25.0

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
## Affondo dopo lo scatto (solo la lancia): lunghissimo e stretto.
const SPEAR_LUNGE := {"range": 78.0, "arc": 24.0, "mult": 1.5, "cd": 0.32, "lunge": 70.0, "knock": 160.0}

var hp := 0.0
var was_wet := false					# per lo schizzo quando entri in acqua
var after_dash_t := 0.0                 # subito dopo uno scatto: affondo della lancia o fendente di Wepwawet
var spin_swing := false                 # l'ultimo colpo è stato il fendente circolare
var dead := false
var facing := Vector2.RIGHT
var aim := Vector2.RIGHT

var dash_t := 0.0
var dash_cd := 0.0
var dash_dir := Vector2.ZERO
var dash_hit := {}
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

	if Input.is_action_just_pressed("dash") and dash_cd <= 0.0 and dash_t <= 0.0:
		_start_dash(move)
	if Input.is_action_pressed("attack") and atk_cd <= 0.0 and dash_t <= 0.0 and not Run.in_hub:
		_swing()
	if Input.is_action_just_pressed("special") and eye_ready() and not Run.in_hub:
		_fire_eye()
	if Input.is_action_just_pressed("super") and Run.sekhem_ready() and divine_t <= 0.0:
		_divine_form()

	if dash_t > 0.0:
		velocity = dash_dir * dash_speed
		_dash_damage()
	else:
		var s := speed * Run.move_mult() * (attack_slowdown if atk_t > 0.0 else 1.0)
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


func _tick(delta: float) -> void:
	after_dash_t = maxf(0.0, after_dash_t - delta)
	var dash_ending := dash_t > 0.0 and dash_t <= delta
	dash_t = maxf(0.0, dash_t - delta)
	if dash_ending:
		_dash_ended()
	dash_cd = maxf(0.0, dash_cd - delta)
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


## Mira: levetta destra se la usi, altrimenti mouse, altrimenti direzione di movimento.
func _update_aim(moving: bool = false) -> void:
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if stick.length() > 0.3:
		aim = stick.normalized()
	elif Fx.device == "touch" and (moving or not Meta.options.get("autoaim", true)):
		# sul telefono, mentre ti muovi colpisci dove vai (con l'aiuto alla mira, più largo che
		# su PC): così il bersaglio lo scegli camminandogli incontro
		aim = facing
	elif Fx.device == "touch":
		# da fermo la mira va da sola sul nemico più vicino (si può spegnere nelle Opzioni)
		var best = null
		var best_d := 260.0
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.dead:
				continue
			var d: float = global_position.distance_to(e.global_position)
			if d < best_d:
				best_d = d
				best = e
		aim = (best.global_position - global_position).normalized() if best != null else facing
	elif Fx.device == "mouse":
		var to := get_global_mouse_position() - (global_position + Vector2(0, -8))
		if to.length() > 4.0:
			aim = to.normalized()
	else:
		aim = facing


## Aiuto alla mira: se un nemico è entro pochi gradi, il colpo si orienta su di lui.
func _assisted(dir: Vector2, max_dist: float) -> Vector2:
	var best = null
	var best_angle := deg_to_rad(aim_assist_degrees * (1.6 if Fx.device == "touch" else 1.0))
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead:
			continue
		var to: Vector2 = e.global_position - global_position
		if to.length() > max_dist:
			continue
		var a := absf(dir.angle_to(to))
		if a < best_angle:
			best_angle = a
			best = to
	if best == null:
		return dir
	return (best as Vector2).normalized()


func _start_dash(move: Vector2) -> void:
	dash_dir = move.normalized() if move.length() > 0.15 else facing
	dash_t = dash_time
	dash_cd = dash_cd_max()
	invuln_t = maxf(invuln_t, dash_time + 0.05)
	knock = Vector2.ZERO
	dash_hit.clear()
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
		get_parent().add_child(pool)
		pool.global_position = global_position


## Corsa dell'Alba: lo scatto ferisce i nemici attraversati.
func _dash_damage() -> void:
	if not Run.has("ra_dawn"):
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead or dash_hit.has(e):
			continue
		if global_position.distance_to(e.global_position) < e.radius + 10.0:
			dash_hit[e] = true
			e.take_hit(Run.val("ra_dawn") * Run.all_damage_mult(), dash_dir, 60.0)
			e.burn_t = maxf(e.burn_t, 1.0)


func _swing() -> void:
	if combo_window <= 0.0:
		combo = 0
	var spear := Run.weapon == "lancia"
	var table: Array = SPEAR if spear else COMBO
	var c: Dictionary = table[combo]
	swing_index = combo
	spin_swing = false
	# subito dopo uno scatto: la lancia affonda lontanissimo, il khopesh di Wepwawet gira su se stesso
	var lunging := after_dash_t > 0.0 and spear
	if lunging:
		c = SPEAR_LUNGE
	combo = (combo + 1) % table.size()
	combo_window = 0.55
	atk_t = 0.14
	atk_cd = c["cd"] * Run.attack_speed_mult()
	swing_range = c["range"]
	swing_arc = deg_to_rad(c["arc"])
	var lunge: float = c["lunge"]
	var aspect_mult := 1.0 + Run.aspect_val("faraone") / 100.0 + Run.aspect_val("neith") / 100.0
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
	if after_dash_t > 0.0 and Run.aspect == "wepwawet":
		swing_arc = TAU
		swing_range = 42.0
		aspect_mult *= 1.0 + Run.aspect_val("wepwawet") / 100.0
		spin_swing = true
		Fx.burst(global_position + Vector2(0, -8), Color(0.62, 0.56, 0.92), 14, 90.0)
	after_dash_t = 0.0
	swing_dir = _assisted(aim, swing_range + 24.0)
	Sfx.play("swing", 0.15)
	if lunging:
		# l'affondo dopo lo scatto si deve vedere: scia dorata lungo la lancia
		for i in range(4):
			Fx.burst(global_position + Vector2(0, -6) + swing_dir * (18.0 + i * 18.0), Color(0.98, 0.86, 0.45), 4, 50.0)
	knock = swing_dir * lunge

	var dmg: float = attack_damage * Run.khopesh_mult() * c["mult"] * Run.combo_mult(swing_index) * aspect_mult
	if divine_t > 0.0:
		dmg *= divine_damage_mult
	if leap_ready:
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
				Fx.float_text(e.global_position + Vector2(0, -20), "CRITICO", Boons.god_color("bastet"))
				Sfx.play("crit")
				if Run.has("duo_sekhmet_bastet"):
					_shockwave.call_deferred(40.0, 12.0 * Run.all_damage_mult(), 150.0, Boons.god_color("duo"))
			var kb: float = c["knock"] * Run.knock_mult() * (2.0 if sweep and Run.has("sobek_tail") else 1.0)
			e.take_hit(hit_dmg, to.normalized(), kb, Run.khopesh_burns())
			# scintilla dove la lama tocca: sul bordo del nemico rivolto verso di te
			var heavy_hit := swing_index == 2 or lunging or crit > 1.0
			Fx.impact(e.global_position + Vector2(0, -e.radius) - to.normalized() * e.radius * 0.6, to.normalized(), heavy_hit)
			if spear and swing_index == 2 and Run.aspect == "khonsu" and not e.dead:
				e.stagger_t = maxf(e.stagger_t, Run.aspect_val("khonsu") * (0.3 if (e.is_boss or e.miniboss) else 1.0))
			if swing_index == 2 and Run.has("sobek_bite") and not e.dead:
				var stun: float = Run.val("sobek_bite") * (0.25 if e.is_boss else 1.0)
				e.stagger_t = maxf(e.stagger_t, stun)
				e.sobek_stun_t = maxf(e.sobek_stun_t, Run.val("sobek_bite"))
			hit_any = true
	if swing_index == 2 and Run.has("sekhmet_roar"):
		_shockwave(46.0, Run.val("sekhmet_roar") * Run.all_damage_mult(), 200.0, Boons.god_color("sekhmet"))
	if hit_any:
		var heavy := swing_index == 2 or lunging
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
func poison(seconds: float) -> void:
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
			Run.last_hit = "scorpion"
			Fx.float_text(global_position + Vector2(0, -16), "-2", Color(0.5, 1, 0.4))
			health_changed.emit(hp, max_hp)


## Restituisce true se il colpo è andato a segno (false se eri invulnerabile).
## `kind` dice chi ha colpito quando non c'è un nemico (per esempio il fuoco di Am-heh).
func take_damage(amount: float, from_pos: Vector2, attacker: Node = null, kind: String = "") -> bool:
	if dead or invuln_t > 0.0 or dash_t > 0.0:
		return false
	amount *= Run.damage_taken_mult()
	if Run.training:
		amount = minf(amount, hp - 1.0)       # nel Cortile di Neith i colpi si sentono, ma non uccidono
	if Run.chap("c151") and not Run.mask_used:
		Run.mask_used = true                 # la maschera attutisce il primo colpo della stanza
		amount *= 1.0 - Chapters.value("c151") / 100.0
	if shield > 0.0:
		var absorbed := minf(shield, amount)
		shield -= absorbed
		amount -= absorbed
		Fx.float_text(global_position + Vector2(0, -14), "Scudo -%d" % int(absorbed), Boons.god_color("iside"))
		if amount <= 0.0:
			invuln_t = 0.4
			return true
	if divine_t > 0.0:
		amount *= divine_armor
	else:
		Run.add_sekhem(amount * 0.5)
		knock = (global_position - from_pos).normalized() * 230.0
	hp -= amount
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
	Fx.shake(7.0)
	Fx.hitstop(0.08)
	Fx.damage_number(global_position, amount, Color(1, 0.4, 0.3))
	if hp <= 0.0 and Run.chap("c30") and not Run.heart_used:
		Run.heart_used = true
		hp = maxf(1.0, roundf(max_hp * Chapters.value("c30") / 100.0))
		invuln_t = 1.5
		Fx.float_text(global_position + Vector2(0, -20), "Il cuore non testimonia", Color(0.62, 0.56, 0.92))
		Fx.burst(global_position + Vector2(0, -10), Color(0.62, 0.56, 0.92), 30, 140.0)
	if hp <= 0.0 and Run.has("bastet_lives") and not Run.revived:
		Run.revived = true
		hp = roundf(max_hp * Run.val("bastet_lives") / 100.0)
		invuln_t = 1.5
		Fx.burst(global_position + Vector2(0, -10), Boons.god_color("bastet"), 40, 160.0)
		Fx.float_text(global_position + Vector2(0, -20), "Bastet ti protegge!", Boons.god_color("bastet"))
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

func _draw() -> void:
	if dead:
		return
	var blink := invuln_t > 0.0 and dash_t <= 0.0 and divine_t <= 0.0 and Time.get_ticks_msec() % 120 < 60
	var a := 0.35 if blink else 1.0
	var bob := sin(walk) * 1.0

	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 9.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if shield > 0.0:
		draw_arc(Vector2(0, -12), 15.0, 0.0, TAU, 28, Color(Boons.god_color("iside"), 0.7), 1.5)
	if divine_t > 0.0:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 90.0)
		draw_circle(Vector2(0, -12), 18.0 + pulse * 3.0, Color(1, 0.8, 0.3, 0.18))
		draw_arc(Vector2(0, -12), 18.0 + pulse * 3.0, 0.0, TAU, 32, Color(1, 0.85, 0.4, 0.6), 1.5)

	var skin := Color(0.75, 0.48, 0.25, a)
	var linen := Color(0.94, 0.89, 0.76, a)
	var blue := Color(0.19, 0.35, 0.77, a)
	var gold := Color(0.94, 0.72, 0.3, a)
	if divine_t > 0.0:
		linen = Color(1, 0.92, 0.6)
		blue = Color(0.95, 0.75, 0.25)
	if flash_t > 0.0:
		skin = Color(1, 1, 1, a); linen = skin; blue = skin; gold = skin
	if dash_t > 0.0:
		linen = Color(linen, 0.5)
	if poison_t > 0.0:
		skin = skin.lerp(Color(0.45, 0.9, 0.35, a), 0.45)

	draw_rect(Rect2(-6, -8 + bob, 12, 8), linen)
	draw_rect(Rect2(-5, -15 + bob, 10, 8), skin)
	draw_rect(Rect2(-6, -9 + bob, 12, 2), gold)
	draw_circle(Vector2(0, -20 + bob), 5.0, skin)
	draw_rect(Rect2(-6, -25 + bob, 12, 4), blue)
	draw_rect(Rect2(-7, -22 + bob, 3, 8), blue)
	draw_rect(Rect2(4, -22 + bob, 3, 8), blue)
	draw_circle(Vector2(facing.x * 2.0 + 1.5, -20 + bob), 1.0, Color(0, 0, 0, a))

	# l'arma in mano: la lancia lungo la mira, il khopesh ricurvo accanto alla mano
	# durante il colpo l'arma si muove: il khopesh attraversa l'arco, la lancia affonda e torna
	var swing_k := clampf(1.0 - atk_t / 0.14, 0.0, 1.0) if atk_t > 0.0 else -1.0
	var wdir := aim
	if swing_k >= 0.0:
		wdir = swing_dir
		if Run.weapon != "lancia" or (swing_index == 2 and not spin_swing):
			var side_sign := -1.0 if swing_index % 2 == 0 else 1.0
			var half := minf(swing_arc, PI * 1.2) * 0.5
			wdir = swing_dir.rotated(side_sign * lerpf(-half, half, ease(swing_k, 0.4)))
	var hand := Vector2(0, -11 + bob) + wdir * 5.0
	if Run.weapon == "lancia":
		var reach := 26.0
		if swing_k >= 0.0:
			reach = 26.0 + sin(swing_k * PI) * (swing_range - 26.0) * 0.6
		draw_line(hand - wdir * 8.0, hand + wdir * reach, Color(0.55, 0.38, 0.2, a), 1.6)
		var tipp := hand + wdir * reach
		draw_colored_polygon(PackedVector2Array([tipp + wdir * 6.0, tipp + wdir.orthogonal() * 2.2, tipp - wdir.orthogonal() * 2.2]), Color(0.85, 0.85, 0.9, a))
	else:
		var blade := PackedVector2Array()
		var bl := 10.0 if swing_k < 0.0 else 13.0
		for i in range(7):
			var k := i / 6.0
			blade.append(hand + wdir * (4.0 + bl * k) + wdir.orthogonal() * (sin(k * PI) * -3.0 - k * 2.0))
		draw_line(hand - wdir * 1.0, hand + wdir * 4.0, gold, 2.0)
		draw_polyline(blade, Color(0.82, 0.82, 0.88, a), 2.0)
	# indicatore di mira
	var tip := Vector2(0, -8) + aim * 20.0
	var side := aim.orthogonal() * 4.0
	draw_colored_polygon(PackedVector2Array([tip + aim * 5.0, tip + side, tip - side]), Color(0.94, 0.72, 0.3, 0.8))

	# fendente: la zona disegnata è esattamente quella che colpisce
	if atk_t > 0.0:
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
