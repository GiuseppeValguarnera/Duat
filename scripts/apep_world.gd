class_name Chaos
extends RefCounted
## La terza regione, «il Banco di Apopi» (la settima ora): i pericoli della caverna del serpente.
## - Isfet: pozze di caos nero-viola. Chi ci sta dentro perde vita a piccoli morsi (danno da terreno).
##   Fisse nella stanza, oppure lasciate dai Figli di Apopi quando muoiono (durano pochi secondi).
## - Coil: una spira di Apopi sotto il pavimento. Ogni tanto il pavimento si crepa (cerchio rosso, 1 s)
##   e la spira esce di colpo: chi è nel cerchio viene colpito. Stessa regola degli altri avvisi.
## - Darkness: «Apopi inghiotte la luce». Un anello di buio attorno all'eroe: si vede bene vicino,
##   poco lontano. Gli avvisi dei colpi restano sopra il buio (li disegna il boss, che sta più in alto).

const ISFET_DMG := 3.0          ## a morso
const ISFET_TICK := 0.5
const ISFET_COL := Color(0.42, 0.16, 0.6)
const COIL_DMG := 12.0
const COIL_R := 30.0
const COIL_WARN := 1.0
const COIL_UP := 0.55


class Isfet extends Node2D:
	var r := 18.0
	var life := -1.0               ## secondi; negativo = resta per tutta la stanza
	var t := 0.0
	var cool := 0.0
	var seed_k := 0.0

	func _ready() -> void:
		seed_k = randf() * 10.0
		add_to_group("isfet")
		Hazards.ground.call_deferred(self)

	func inside(p: Vector2) -> bool:
		var d: Vector2 = (p - global_position) / Vector2(r, r * 0.6)
		return d.length() < 1.0

	func _process(delta: float) -> void:
		t += delta
		cool = maxf(0.0, cool - delta)
		if life > 0.0 and t >= life:
			queue_free()
			return
		var p = get_tree().get_first_node_in_group("player")
		if p != null and not p.dead and cool <= 0.0 and p.dash_t <= 0.0 and t > 0.5 and inside(p.global_position):
			p.take_damage(Chaos.ISFET_DMG, global_position, null, "isfet")
			cool = Chaos.ISFET_TICK
		queue_redraw()

	func _draw() -> void:
		var a := clampf(t / 0.5, 0.0, 1.0)
		if life > 0.0:
			a *= clampf((life - t) / 0.7, 0.0, 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
		# bordo che ribolle: una corona di cerchi che pulsano, così la forma vera si legge
		for i in range(10):
			var ang := TAU * i / 10.0 + seed_k
			var rr := r * (0.28 + 0.08 * sin(t * 2.2 + i * 1.7))
			draw_circle(Vector2.from_angle(ang) * r * 0.8, rr, Color(0.3, 0.1, 0.42, 0.55 * a))
		draw_circle(Vector2.ZERO, r * 0.92, Color(0.06, 0.02, 0.1, 0.92 * a))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, Color(0.75, 0.4, 1.0, (0.55 + 0.25 * sin(t * 4.0)) * a), 1.4)
		# occhi che si aprono nel buio: il caos guarda
		for i in range(2):
			var k := fmod(t * 0.35 + i * 0.5 + seed_k, 1.0)
			var open := sin(k * PI)
			var ep := Vector2(sin(seed_k + i * 3.0) * r * 0.45, cos(seed_k * 1.3 + i * 2.0) * r * 0.4)
			draw_line(ep + Vector2(-3, 0), ep + Vector2(3, 0), Color(0.85, 0.3, 0.3, 0.8 * a * open), 1.0 + 1.6 * open)
			draw_circle(ep, 0.9 * open, Color(1.0, 0.85, 0.3, a * open))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


class Coil extends Node2D:
	var period := 6.0
	var t := 0.0
	var st := 0.0
	var state := "sleep"            ## sleep → warn → up → sleep
	var hit := false
	var seed_k := 0.0

	func _ready() -> void:
		seed_k = randf() * TAU
		st = randf_range(1.5, period)
		Hazards.ground.call_deferred(self)

	func _process(delta: float) -> void:
		t += delta
		st -= delta
		match state:
			"sleep":
				if st <= 0.0:
					state = "warn"
					st = Chaos.COIL_WARN
					Sfx.play_at("serpent_burrow", global_position, 0.2)
			"warn":
				if st <= 0.0:
					state = "up"
					st = Chaos.COIL_UP
					hit = false
					Sfx.play_at("serpent_erupt", global_position, 0.2)
					Fx.burst(global_position, Color(0.3, 0.12, 0.4), 14, 110.0)
			"up":
				var p = get_tree().get_first_node_in_group("player")
				if not hit and p != null and not p.dead and p.global_position.distance_to(global_position) < Chaos.COIL_R:
					if p.take_damage(Chaos.COIL_DMG, global_position, null, "spira"):
						hit = true
				# anche i nemici normali vengono sbalzati: la spira non distingue
				if st <= 0.0:
					state = "sleep"
					st = period * randf_range(0.8, 1.2)
		queue_redraw()

	func _draw() -> void:
		# la crepa nel pavimento: sempre visibile, così sai dove dorme la spira
		for i in range(5):
			var a := seed_k + TAU * i / 5.0
			var p1 := Vector2.from_angle(a) * 5.0
			var p2 := Vector2.from_angle(a + 0.3) * (13.0 + 4.0 * sin(i * 2.0))
			draw_line(p1 * Vector2(1, 0.6), p2 * Vector2(1, 0.6), Color(0.04, 0.02, 0.06, 0.9), 1.6)
		draw_circle(Vector2.ZERO, 3.0, Color(0.5, 0.2, 0.7, 0.5 + 0.3 * sin(t * 3.0)))
		if state == "warn":
			Enemy.warn_circle(self, Vector2.ZERO, Chaos.COIL_R, 1.0 - st / Chaos.COIL_WARN)
		elif state == "up":
			var k := sin(clampf(1.0 - st / Chaos.COIL_UP, 0.0, 1.0) * PI)
			# la spira: un arco di serpente che esce e rientra
			var pts := PackedVector2Array()
			for i in range(15):
				var u := i / 14.0
				pts.append(Vector2(lerpf(-20.0, 20.0, u), -sin(u * PI) * 34.0 * k))
			if k > 0.05:
				draw_polyline(pts, Color(0.05, 0.03, 0.06), 13.0)
				draw_polyline(pts, Color(0.22, 0.1, 0.3), 10.0)
				for i in range(1, 14, 2):
					draw_circle(pts[i], 2.4, Color(0.6, 0.25, 0.25))
				draw_polyline(pts, Color(0.75, 0.6, 0.3, 0.5), 1.2)
			draw_arc(Vector2.ZERO, Chaos.COIL_R, 0.0, TAU, 28, Color(Enemy.WARN, 0.8), 1.5)


## Il buio di Apopi: un anello scuro centrato sull'eroe. `amount` 0 → 1 (lo muove chi lo crea).
class Darkness extends Node2D:
	var amount := 0.0
	var target := 0.0
	var inner := 78.0

	func _ready() -> void:
		z_index = 5

	func _process(delta: float) -> void:
		amount = move_toward(amount, target, delta * 1.2)
		var p = get_tree().get_first_node_in_group("player")
		if p != null:
			global_position = p.global_position
		queue_redraw()

	func _draw() -> void:
		if amount <= 0.01:
			return
		var steps := 20
		var rings := [[inner, 0.0], [inner + 34.0, 0.45], [inner + 80.0, 0.74], [900.0, 0.8]]
		for k in range(rings.size() - 1):
			var r0: float = rings[k][0]
			var r1: float = rings[k + 1][0]
			var a0: float = float(rings[k][1]) * amount
			var a1: float = float(rings[k + 1][1]) * amount
			for i in range(steps):
				var u0 := Vector2.from_angle(TAU * i / steps)
				var u1 := Vector2.from_angle(TAU * (i + 1) / steps)
				draw_polygon(PackedVector2Array([u0 * r0, u1 * r0, u1 * r1, u0 * r1]),
					PackedColorArray([Color(0.02, 0.0, 0.04, a0), Color(0.02, 0.0, 0.04, a0), Color(0.02, 0.0, 0.04, a1), Color(0.02, 0.0, 0.04, a1)]))
