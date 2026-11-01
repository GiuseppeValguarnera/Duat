extends Node2D
## Colonna d'Aria (Shu): il vortice dell'attacco caricato. Per 1,5 secondi risucchia verso il centro
## i nemici vicini (boss, guardiani ed élite appena appena). Chi è dentro conta come "appena spinto"
## per il Separatore del Cielo.

const LIFE := 1.5
const RADIUS := 85.0
const PULL := 150.0
var t := 0.0


func _ready() -> void:
	z_index = 2
	Sfx.play("dash", 0.1)


func _physics_process(delta: float) -> void:
	t += delta
	if t >= LIFE:
		queue_free()
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead or not SokarTerrain.grounded(e):
			continue
		var to: Vector2 = global_position - e.global_position
		var d := to.length()
		if d > RADIUS or d < 4.0:
			continue
		var heavy: bool = e.is_boss or e.miniboss or e.elite
		e.move_and_collide(to.normalized() * PULL * (0.2 if heavy else 1.0) * delta)
		e.shu_pushed_t = maxf(e.shu_pushed_t, 0.5)
	queue_redraw()


func _draw() -> void:
	var k := t / LIFE
	var fade := 1.0 - k * k
	var pearl := Color(0.97, 0.93, 0.82)
	var gold := Color(0.94, 0.78, 0.4)
	# spirali di vento che girano verso il centro, e la piuma di struzzo di Shu al centro
	for i in range(4):
		var pts := PackedVector2Array()
		var a0 := t * 7.0 + i * TAU / 4.0
		for s in range(14):
			var u := s / 13.0
			var r := RADIUS * (1.0 - u) * 0.9
			pts.append(Vector2.from_angle(a0 + u * 3.0) * r * Vector2(1.0, 0.55))
		draw_polyline(pts, Color(pearl, 0.55 * fade), 2.0)
	draw_arc(Vector2.ZERO, RADIUS * 0.95, 0.0, TAU, 40, Color(gold, 0.3 * fade), 1.2)
	draw_line(Vector2(0, 6), Vector2(2, -14), Color(gold, fade), 1.5)
	draw_colored_polygon(PackedVector2Array([Vector2(2, -14), Vector2(7, -8), Vector2(5, 2), Vector2(1, -2)]), Color(pearl, 0.9 * fade))
