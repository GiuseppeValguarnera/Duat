extends Enemy
## Il Serpente della Porta: il guardiano a metà della Prima Ora (stanza 5).
## Nel Libro delle Porte ogni porta del Duat è custodita da un grande serpente.
##
## Mosse:
## - Affondo: si ritrae (avviso con la linea), poi scatta con la testa in linea retta.
## - Veleno: sputa un ventaglio di gocce verdi.
## - Sotto la sabbia: si inabissa (non si può colpire), ti insegue sotto terra e riemerge
##   dove eri. Un cerchio a terra avvisa dove uscirà: scatta via.
## Sotto metà vita si infuria: più rapido, ventaglio più largo, e chiama gli scarabei una volta.

signal summon(kinds: Array)

const BoltScript := preload("res://scripts/enemy_bolt.gd")

@export var strike_windup := 0.6
@export var strike_speed := 400.0
@export var strike_time := 0.32
@export var venom_count := 5
@export var venom_damage := 10.0
@export var burrow_time := 1.5
@export var erupt_warn := 0.65
@export var erupt_radius := 48.0
@export var erupt_damage := 16.0

var state := "intro"
var st := 1.4
var aim := Vector2.DOWN
var enraged := false
var summoned := false
var trail: Array[Vector2] = []        # posizioni passate della testa: il corpo le segue
var erupt_at := Vector2.ZERO


func _ready() -> void:
	miniboss = true
	super._ready()
	for i in range(24):
		trail.append(global_position + Vector2(0, -i * 3.0))


func _rage() -> float:
	return 1.25 if enraged else 1.0


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta * _rage()
	if not enraged and hp < max_hp * 0.5:
		enraged = true
		Fx.shake(6.0)
		Fx.float_text(global_position + Vector2(0, -30), "IL SERPENTE SI INFURIA", Color(0.6, 1, 0.5))
		if not summoned:
			summoned = true
			summon.emit(["scarab", "scarab", "scarab", "scarab"])
	_update_trail()
	match state:
		"intro":
			if st <= 0.0:
				_next(1.0)
			return Vector2.ZERO
		"chase":
			if to != Vector2.ZERO:
				aim = to.normalized()
			if st <= 0.0:
				_choose(to)
				return Vector2.ZERO
			var wiggle := aim.orthogonal() * sin(t * 5.0) * 0.5
			return (aim + wiggle).normalized() * speed * _rage()
		"windup":
			if st > strike_windup * 0.45 and to != Vector2.ZERO:
				aim = to.normalized()
			if st <= 0.0:
				state = "strike"
				st = strike_time
				Sfx.play_at("mummy_lunge", global_position, 0.05)
			return -aim * 25.0
		"strike":
			if st <= 0.0:
				_next(0.7)
				state = "recover"
			return aim * strike_speed
		"spit":
			if st <= 0.0:
				_venom()
				state = "recover"
				st = 0.6
			return Vector2.ZERO
		"dive":
			if st <= 0.0:
				state = "under"
				st = burrow_time
				_set_buried(true)
			return Vector2.ZERO
		"under":
			if st <= 0.0 or (to != Vector2.ZERO and to.length() < 10.0):
				state = "warn"
				st = erupt_warn
				erupt_at = global_position
				return Vector2.ZERO
			if to == Vector2.ZERO:
				return Vector2.ZERO
			return to.normalized() * 150.0 * _rage()
		"warn":
			if st <= 0.0:
				_erupt()
				state = "recover"
				st = 0.9
			return Vector2.ZERO
		"recover":
			if st <= 0.0:
				_next(0.9 + randf() * 0.7)
			return Vector2.ZERO
	return Vector2.ZERO


func _next(time: float) -> void:
	state = "chase"
	st = time


func _choose(to: Vector2) -> void:
	var d := to.length() if to != Vector2.ZERO else 999.0
	var r := randf()
	if d < 140.0 and r < 0.5:
		state = "windup"
		st = strike_windup
		Sfx.play_at("mummy_windup", global_position, 0.05)
	elif r < 0.75:
		state = "spit"
		st = 0.55
		Sfx.play_at("priest_cast", global_position, 0.05)
	else:
		state = "dive"
		st = 0.5
		Fx.burst(global_position, Color(0.85, 0.72, 0.45), 20, 90.0)


func _venom() -> void:
	Sfx.play_at("orb", global_position, 0.1)
	var n := venom_count + (2 if enraged else 0)
	var spread := deg_to_rad(70.0 if enraged else 55.0)
	for i in range(n):
		var a := -spread / 2.0 + spread * i / maxf(1.0, n - 1.0)
		var bolt: Area2D = BoltScript.new()
		bolt.direction = aim.rotated(a)
		bolt.speed = 165.0
		bolt.damage = venom_damage
		bolt.shooter = self
		bolt.style = "venom"
		get_parent().add_child(bolt)
		bolt.global_position = global_position + Vector2(0, -12) + aim * 12.0


func _erupt() -> void:
	_set_buried(false)
	Fx.shake(8.0)
	Fx.burst(global_position, Color(0.85, 0.72, 0.45), 40, 180.0)
	Sfx.play_at("charge", global_position, 0.05)
	var player = get_tree().get_first_node_in_group("player")
	if player != null and not player.dead and player.global_position.distance_to(global_position) < erupt_radius:
		player.take_damage(erupt_damage, global_position, self)


## Sotto la sabbia non lo si può colpire e non ferisce al contatto.
func _set_buried(on: bool) -> void:
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


func _update_trail() -> void:
	if trail.is_empty() or trail[0].distance_to(global_position) > 3.0:
		trail.push_front(global_position)
		if trail.size() > 24:
			trail.pop_back()


## Un serpente di quella stazza non barcolla e quasi non viene spinto.
func _stagger_time() -> float:
	return 0.0


func _on_hit(_dmg: float) -> void:
	knock *= 0.1


func _draw_body(flash: bool) -> void:
	var skin := Color.WHITE if flash else Color(0.25, 0.45, 0.3)
	var belly := Color.WHITE if flash else Color(0.85, 0.75, 0.45)
	var band := Color(0.94, 0.72, 0.3)
	if state == "under" or state == "warn":
		# sotto la sabbia: solo un solco che si muove, e il cerchio d'avviso
		for i in range(4):
			var p: Vector2 = Vector2(sin(t * 9.0 + i) * 6.0, cos(t * 7.0 + i * 2.0) * 3.0)
			draw_circle(p, 3.0, Color(0.75, 0.62, 0.4, 0.8))
		if state == "warn":
			var k := 1.0 - st / erupt_warn
			draw_arc(Vector2.ZERO, erupt_radius, 0.0, TAU, 40, Color(1, 0.3, 0.2, 0.5 + 0.4 * k), 2.0)
			draw_circle(Vector2.ZERO, erupt_radius * k, Color(1, 0.3, 0.2, 0.18))
		return
	# corpo: cerchi lungo la scia, dalla coda alla testa
	for i in range(trail.size() - 1, 0, -2):
		var p: Vector2 = trail[i] - global_position
		var r := lerpf(10.0, 4.0, float(i) / trail.size())
		draw_circle(p + Vector2(0, -6), r, skin.darkened(0.15 if int(i / 2.0) % 2 == 0 else 0.0))
		if int(i / 2.0) % 3 == 0:
			draw_arc(p + Vector2(0, -6), r, 0.0, TAU, 12, band, 1.0)
	# testa con il cappuccio
	var h := Vector2(0, -12)
	if state == "windup":
		h -= aim * 6.0
		draw_line(Vector2(0, -12), Vector2(0, -12) + aim * strike_speed * strike_time, Color(1, 0.2, 0.15, 0.5), 3.0)
	draw_circle(h, 13.0, skin)
	draw_circle(h + aim * 6.0, 8.0, skin.lightened(0.1))
	draw_circle(h + Vector2(0, 4), 6.0, belly)
	var eye_side := aim.orthogonal() * 4.0
	var glow := Color(1, 0.25, 0.15) if enraged else Color(1, 0.85, 0.3)
	draw_circle(h + aim * 9.0 + eye_side, 1.8, glow)
	draw_circle(h + aim * 9.0 - eye_side, 1.8, glow)
	if state == "spit":
		draw_circle(h + aim * 14.0, 3.0 + (0.55 - st) * 6.0, Color(0.5, 1, 0.4, 0.6))
