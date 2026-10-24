extends Enemy
## Ammit, la Divoratrice: testa di coccodrillo, corpo di leone, zampe di ippopotamo.
## Nel mito divora il cuore di chi non supera la pesatura. È il boss della Prima Ora.
##
## Mosse (ognuna si annuncia prima di colpire):
##  - Carica: si ferma, una striscia rossa mostra la traiettoria, poi scatta in linea retta.
##    Se sbatte contro una colonna resta stordita e subisce il 50% di danni in più,
##    ma la colonna crolla: nell'arena ce ne sono solo 6. Travolge gli altri nemici.
##  - Sputo: un anello viola si stringe attorno a lei, poi lancia sfere in tutte le direzioni.
##  - Morso: quando sei vicino, un ventaglio rosso si accende davanti alle fauci, poi azzanna.
##  - Ruggito del Giudizio: si impenna, poi un'onda d'urto si allarga per tutta l'arena.
##    Si supera scattandoci attraverso.
## Sotto metà vita entra in furia: è più veloce, lancia più sfere, fa due onde di fila
## e chiama scarabei e un Sacerdote di Set.

signal summon(kinds: Array)
signal pillar_broken(body: StaticBody2D)

const BoltScript := preload("res://scripts/enemy_bolt.gd")

@export_group("Carica")
@export var charge_windup := 0.85
@export var charge_speed := 340.0
@export var charge_time := 0.7
@export var stun_time := 2.0
@export var trample_damage := 30.0     ## danni ai nemici travolti durante la carica

@export_group("Sputo")
@export var spit_windup := 0.65
@export var spit_count := 12
@export var bolt_damage := 16.0

@export_group("Morso")
@export var bite_range := 70.0         ## distanza sotto cui preferisce mordere
@export var bite_windup := 0.5
@export var bite_reach := 52.0
@export var bite_arc := 110.0          ## gradi
@export var bite_damage := 24.0

@export_group("Ruggito del Giudizio")
@export var roar_windup := 0.9
@export var wave_speed := 170.0
@export var wave_damage := 18.0

@export_group("Furia")
@export var summon_kinds := ["scarab", "scarab", "scarab", "scarab", "priest"]

var state := "intro"
var st := 1.0
var charge_dir := Vector2.DOWN
var enraged := false
var trampled := {}                     # nemici già travolti in questa carica
var waves_left := 0                    # onde ancora da lanciare in questo ruggito


func _ready() -> void:
	is_boss = true
	if Weights.rank("fame") > 0:
		max_hp *= 1.3                 # Peso del Cuore: la fame di Ammit
	super._ready()


func _rage() -> float:
	return 1.3 if enraged else 1.0


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta * _rage()
	if not enraged and hp < max_hp * 0.5:
		enraged = true
		state = "furia"
		st = 0.9
		Fx.shake(8.0)
		summon.emit(summon_kinds)
	match state:
		"intro", "furia":
			if st <= 0.0:
				state = "chase"
				st = 1.0
			return Vector2.ZERO
		"chase":
			if to != Vector2.ZERO:
				charge_dir = to.normalized()
			if st <= 0.0:
				_choose_attack(to)
				return Vector2.ZERO
			return charge_dir * speed * _rage()
		"windup":
			# mira fino a metà dell'avviso, poi la direzione resta fissa: è il momento di schivare
			if st > charge_windup * 0.45 and to != Vector2.ZERO:
				charge_dir = to.normalized()
			if st <= 0.0:
				state = "charge"
				st = charge_time
				Sfx.play("charge")
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
		"bite":
			if st > bite_windup * 0.5 and to != Vector2.ZERO:
				charge_dir = to.normalized()
			if st <= 0.0:
				_bite()
				state = "recover"
				st = 0.55
			return Vector2.ZERO
		"roar":
			if st <= 0.0:
				_shockwave()
				waves_left -= 1
				if waves_left > 0:
					st = 0.7
				else:
					state = "recover"
					st = 0.9
			return Vector2.ZERO
		"stunned", "recover":
			if st <= 0.0:
				state = "chase"
				st = 1.1 + randf() * 0.9
			return Vector2.ZERO
	return Vector2.ZERO


## Sceglie la prossima mossa: da vicino preferisce mordere, da lontano carica, sputa o ruggisce.
func _choose_attack(to: Vector2) -> void:
	var close := to != Vector2.ZERO and to.length() < bite_range
	var r := randf()
	if close and r < 0.55:
		state = "bite"
		st = bite_windup
	elif r < 0.6:
		state = "windup"
		st = charge_windup
	elif r < 0.82:
		state = "spit"
		st = spit_windup
		Sfx.play("priest_cast", 0.03)
	else:
		state = "roar"
		st = roar_windup
		waves_left = 2 if (enraged or Weights.rank("fame") > 0) else 1


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
	Sfx.play("orb", 0.05)
	var n := spit_count + (4 if enraged else 0)
	var off := randf() * TAU
	for i in range(n):
		var a := off + i * TAU / n
		var bolt: Area2D = BoltScript.new()
		bolt.direction = Vector2.from_angle(a)
		bolt.speed = 100.0 * _rage()
		bolt.damage = bolt_damage
		bolt.shooter = self
		get_parent().add_child(bolt)
		bolt.global_position = global_position + Vector2(0, -12)
	Fx.shake(4.0)


## Morso: colpisce tutto quello che è nel ventaglio davanti alle fauci.
func _bite() -> void:
	Sfx.play("bite")
	Fx.shake(6.0)
	Fx.burst(global_position + Vector2(0, -12) + charge_dir * 30.0, Color(0.95, 0.9, 0.8), 14, 120.0)
	var player = get_tree().get_first_node_in_group("player")
	if player == null or player.dead:
		return
	var to: Vector2 = player.global_position - global_position
	if to.length() <= bite_reach + 6.0 and absf(charge_dir.angle_to(to)) <= deg_to_rad(bite_arc) * 0.5:
		player.take_damage(bite_damage, global_position, self)


## Ruggito del Giudizio: un anello che si allarga per tutta l'arena.
func _shockwave() -> void:
	Sfx.play("roar", 0.05)
	var wave := Shockwave.new()
	wave.speed = wave_speed * _rage()
	wave.damage = wave_damage
	wave.source = self
	get_parent().add_child(wave)
	wave.global_position = global_position
	Fx.shake(7.0)


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
	var skin := Color.WHITE if flash else Color(0.42, 0.35, 0.3)
	var mane := Color.WHITE if flash else Color(0.72, 0.53, 0.18)
	var croc := Color.WHITE if flash else Color(0.25, 0.42, 0.22)

	if state == "windup":
		var k := 1.0 - st / charge_windup
		var lane_len := charge_speed * charge_time * _rage()
		draw_set_transform(Vector2(0, -10), charge_dir.angle(), Vector2.ONE)
		draw_rect(Rect2(0, -radius, lane_len, radius * 2.0), Color(1, 0.2, 0.15, 0.12 + 0.2 * k))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if state == "spit":
		var k2 := 1.0 - st / spit_windup
		draw_arc(Vector2(0, -12), 40.0 - 22.0 * k2, 0.0, TAU, 40, Color(0.8, 0.4, 1.0, 0.3 + 0.5 * k2), 2.0)
	if state == "bite":
		var k3 := 1.0 - st / bite_windup
		var pts := PackedVector2Array([Vector2.ZERO])
		var half := deg_to_rad(bite_arc) * 0.5
		for i in range(13):
			pts.append(Vector2.from_angle(charge_dir.angle() - half + half * 2.0 * i / 12.0) * bite_reach)
		draw_colored_polygon(pts, Color(1, 0.2, 0.15, 0.12 + 0.3 * k3))
	if state == "roar":
		var k4 := clampf(1.0 - st / roar_windup, 0.0, 1.0)
		draw_arc(Vector2(0, -12), radius + 6.0 + 10.0 * k4, 0.0, TAU, 32, Color(1, 0.85, 0.4, 0.4 + 0.5 * k4), 3.0)
	if enraged:
		draw_circle(Vector2(0, -12), radius + 8.0, Color(1, 0.2, 0.1, 0.12))

	var jitter := Vector2(randf_range(-1, 1), 0) if state in ["windup", "roar"] else Vector2.ZERO
	var rear := Vector2(0, -4) if state == "roar" else Vector2.ZERO
	draw_set_transform(jitter + rear, 0.0, Vector2(dir, 1.0))
	# zampe e corpo di ippopotamo
	draw_rect(Rect2(-18, -6, 7, 8), skin)
	draw_rect(Rect2(-6, -6, 7, 8), skin)
	draw_rect(Rect2(-22, -24, 26, 20), skin)
	# criniera di leone
	draw_circle(Vector2(6, -18), 11.0, mane)
	draw_rect(Rect2(4, -6, 6, 8), mane)
	# testa di coccodrillo (le fauci si aprono durante il morso)
	var open := 4.0 if state == "bite" else 0.0
	draw_rect(Rect2(8, -24 - open, 22, 9), croc)
	draw_rect(Rect2(8, -15 + open, 20, 4), croc.darkened(0.2))
	for i in range(4):
		draw_rect(Rect2(12 + i * 4, -16 + open, 2, 2), Color(0.95, 0.92, 0.85))
	draw_rect(Rect2(14, -23 - open, 3, 3), Color(1, 0.25, 0.15))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if state == "stunned":
		var t2 := Time.get_ticks_msec() / 250.0
		for i in range(3):
			var a := t2 + i * TAU / 3.0
			draw_circle(Vector2(cos(a) * 12.0, -38 + sin(a) * 3.0), 2.0, Color(1, 0.85, 0.3))


## Onda d'urto del Ruggito: un anello che si allarga e ferisce una volta chi tocca.
## Lo scatto rende invulnerabili, quindi la si supera scattandoci attraverso.
class Shockwave extends Node2D:
	var speed := 170.0
	var damage := 18.0
	var source: Node = null
	var r := 12.0
	var max_r := 520.0
	var hit := false

	func _physics_process(delta: float) -> void:
		r += speed * delta
		if r > max_r:
			queue_free()
			return
		if not hit:
			var player = get_tree().get_first_node_in_group("player")
			if player != null and not player.dead:
				var d: float = player.global_position.distance_to(global_position)
				if absf(d - r) < 8.0:
					var src: Node = source if is_instance_valid(source) else null
					if player.take_damage(damage, global_position, src):
						hit = true
		queue_redraw()

	func _draw() -> void:
		var fade := clampf(1.0 - r / max_r, 0.2, 1.0)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(1, 0.8, 0.35, 0.8 * fade), 5.0)
		draw_arc(Vector2.ZERO, r - 5.0, 0.0, TAU, 64, Color(1, 0.5, 0.2, 0.35 * fade), 3.0)
