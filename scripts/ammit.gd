extends Enemy
## Ammit, la Divoratrice: testa di coccodrillo, corpo di leone, zampe di ippopotamo.
## Nel mito divora il cuore di chi non supera la pesatura. È il boss della Prima Ora.
##
## Mosse (ognuna si annuncia prima di colpire):
##  - Carica: si ferma, una striscia rossa mostra la traiettoria, poi scatta in linea retta.
##    Se sbatte contro una colonna resta stordita e subisce il 50% di danni in più,
##    ma la colonna crolla: nell'arena ce ne sono solo 6.
##  - Sputo: un anello viola si stringe attorno a lei, poi lancia sfere in tutte le direzioni.
## Sotto metà vita entra in furia: è più veloce, lancia più sfere e chiama uno sciame di scarabei.

signal summon(count: int)
signal pillar_broken(body: StaticBody2D)

const BoltScript := preload("res://scripts/enemy_bolt.gd")

@export var charge_windup := 0.85
@export var charge_speed := 330.0
@export var charge_time := 0.7
@export var spit_windup := 0.65
@export var spit_count := 10
@export var stun_time := 2.0
@export var summon_count := 4
@export var trample_damage := 30.0     ## danni ai nemici travolti durante la carica

var state := "intro"
var st := 1.0
var charge_dir := Vector2.DOWN
var enraged := false
var trampled := {}                     # nemici già travolti in questa carica


func _ready() -> void:
	super._ready()
	is_boss = true


func _rage() -> float:
	return 1.3 if enraged else 1.0


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta * _rage()
	if not enraged and hp < max_hp * 0.5:
		enraged = true
		state = "roar"
		st = 0.9
		Fx.shake(8.0)
		summon.emit(summon_count)
	match state:
		"intro", "roar":
			if st <= 0.0:
				state = "chase"
				st = 1.2
			return Vector2.ZERO
		"chase":
			if to != Vector2.ZERO:
				charge_dir = to.normalized()
			if st <= 0.0:
				if randf() < 0.6:
					state = "windup"
					st = charge_windup
				else:
					state = "spit"
					st = spit_windup
				return Vector2.ZERO
			return charge_dir * speed * _rage()
		"windup":
			# mira fino a metà dell'avviso, poi la direzione resta fissa: è il momento di schivare
			if st > charge_windup * 0.45 and to != Vector2.ZERO:
				charge_dir = to.normalized()
			if st <= 0.0:
				state = "charge"
				st = charge_time
				trampled.clear()
			return Vector2.ZERO
		"charge":
			_trample()
			if _hit_wall():
				return Vector2.ZERO
			if st <= 0.0:
				state = "recover"
				st = 0.6
			return charge_dir * charge_speed * _rage()
		"spit":
			if st <= 0.0:
				_spit()
				state = "recover"
				st = 0.7
			return Vector2.ZERO
		"stunned", "recover":
			if st <= 0.0:
				state = "chase"
				st = 1.4 + randf() * 1.0
			return Vector2.ZERO
	return Vector2.ZERO


## Durante la carica controlla se ha sbattuto: contro una colonna resta stordita.
func _hit_wall() -> bool:
	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		var body := col.get_collider()
		if body is StaticBody2D:
			Fx.shake(9.0)
			Fx.burst(global_position, Color(0.8, 0.65, 0.4), 24, 140.0)
			if body.is_in_group("pillars"):
				state = "stunned"
				st = stun_time
				Fx.float_text(global_position + Vector2(0, -30), "STORDITA", Color(1, 0.85, 0.3))
				body.remove_from_group("pillars")
				pillar_broken.emit(body)
			else:
				state = "recover"
				st = 0.9
			return true
	return false


## Durante la carica travolge gli altri nemici sulla sua strada e li scaglia di lato.
func _trample() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or e.dead or trampled.has(e):
			continue
		if global_position.distance_to(e.global_position) < radius + e.radius + 4.0:
			trampled[e] = true
			var side := charge_dir.orthogonal()
			if side.dot(e.global_position - global_position) < 0.0:
				side = -side
			e.take_hit(trample_damage, (side + charge_dir * 0.5).normalized(), 280.0)
			Fx.burst(e.global_position + Vector2(0, -6), Color(0.9, 0.3, 0.2), 10, 110.0)
			Fx.shake(3.0)


func _spit() -> void:
	var n := spit_count + (4 if enraged else 0)
	var off := randf() * TAU
	for i in range(n):
		var a := off + i * TAU / n
		var bolt: Area2D = BoltScript.new()
		bolt.direction = Vector2.from_angle(a)
		bolt.speed = 95.0 * _rage()
		bolt.damage = 12.0
		bolt.shooter = self
		get_parent().add_child(bolt)
		bolt.global_position = global_position + Vector2(0, -12)
	Fx.shake(4.0)


func _contact_damage() -> float:
	return contact_damage * (1.5 if state == "charge" else 1.0)


func _damage_mult() -> float:
	return 1.5 if state == "stunned" else 1.0


func _stagger_time() -> float:
	return 0.0


func _on_hit(_dmg: float) -> void:
	knock *= 0.08


func _draw_body(flash: bool) -> void:
	var dir := -1.0 if charge_dir.x < 0.0 else 1.0
	var hide := Color.WHITE if flash else Color(0.42, 0.35, 0.3)
	var mane := Color.WHITE if flash else Color(0.72, 0.53, 0.18)
	var croc := Color.WHITE if flash else Color(0.25, 0.42, 0.22)

	if state == "windup":
		var k := 1.0 - st / charge_windup
		var len := charge_speed * charge_time * _rage()
		draw_set_transform(Vector2(0, -10), charge_dir.angle(), Vector2.ONE)
		draw_rect(Rect2(0, -radius, len, radius * 2.0), Color(1, 0.2, 0.15, 0.12 + 0.2 * k))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if state == "spit":
		var k2 := 1.0 - st / spit_windup
		draw_arc(Vector2(0, -12), 40.0 - 22.0 * k2, 0.0, TAU, 40, Color(0.8, 0.4, 1.0, 0.3 + 0.5 * k2), 2.0)
	if enraged:
		draw_circle(Vector2(0, -12), radius + 8.0, Color(1, 0.2, 0.1, 0.12))

	var jitter := Vector2(randf_range(-1, 1), 0) if state == "windup" else Vector2.ZERO
	draw_set_transform(jitter, 0.0, Vector2(dir, 1.0))
	# zampe e corpo di ippopotamo
	draw_rect(Rect2(-18, -6, 7, 8), hide)
	draw_rect(Rect2(-6, -6, 7, 8), hide)
	draw_rect(Rect2(-22, -24, 26, 20), hide)
	# criniera di leone
	draw_circle(Vector2(6, -18), 11.0, mane)
	draw_rect(Rect2(4, -6, 6, 8), mane)
	# testa di coccodrillo
	draw_rect(Rect2(8, -24, 22, 9), croc)
	draw_rect(Rect2(8, -15, 20, 4), croc.darkened(0.2))
	for i in range(4):
		draw_rect(Rect2(12 + i * 4, -16, 2, 2), Color(0.95, 0.92, 0.85))
	draw_rect(Rect2(14, -23, 3, 3), Color(1, 0.25, 0.15))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if state == "stunned":
		var t2 := Time.get_ticks_msec() / 250.0
		for i in range(3):
			var a := t2 + i * TAU / 3.0
			draw_circle(Vector2(cos(a) * 12.0, -38 + sin(a) * 3.0), 2.0, Color(1, 0.85, 0.3))
