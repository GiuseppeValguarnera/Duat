extends Node2D
## Ushabti (Libro dei Morti, capitolo 6): statuetta servitrice che segue il giocatore
## e ogni 2 secondi lancia un piccolo raggio contro il nemico più vicino.

const EyeScript := preload("res://scripts/eye.gd")

var every := 2.0
var damage := 6.0
var reach := 170.0
var t := 0.0
var bob := 0.0


func _physics_process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null or player.dead:
		return
	bob += delta
	var target_pos: Vector2 = player.global_position + Vector2(-18.0 if player.facing.x >= 0.0 else 18.0, -6.0)
	global_position = global_position.lerp(target_pos, clampf(delta * 6.0, 0.0, 1.0))
	t += delta
	if t >= every:
		var best = null
		var best_d := reach
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.dead:
				continue
			var d := global_position.distance_to(e.global_position)
			if d < best_d:
				best_d = d
				best = e
		if best != null:
			t = 0.0
			var eye: Area2D = EyeScript.new()
			eye.direction = (best.global_position + Vector2(0, -6) - global_position).normalized()
			eye.damage = damage
			eye.speed = 260.0
			get_parent().add_child(eye)
			eye.global_position = global_position + Vector2(0, -6)
	queue_redraw()


func _draw() -> void:
	var y := sin(bob * 3.0) * 1.5
	draw_set_transform(Vector2(0, 4), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 4.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# statuina di faience turchese: corpo mummiforme, parrucca blu, braccia incrociate con gli attrezzi
	var faience := Color(0.25, 0.7, 0.66)
	var dark := Color(0.1, 0.2, 0.35)
	var out := Color(0.12, 0.08, 0.05)
	var body := PackedVector2Array([Vector2(-3.5, 0 + y), Vector2(3.5, 0 + y), Vector2(4, -9 + y), Vector2(2.8, -11 + y), Vector2(-2.8, -11 + y), Vector2(-4, -9 + y)])
	draw_colored_polygon(body, faience)
	var bc := body.duplicate()
	bc.append(body[0])
	draw_polyline(bc, out, 0.7)
	draw_circle(Vector2(0, -12.5 + y), 3.5, out)
	draw_circle(Vector2(0, -12.5 + y), 2.9, faience)
	draw_colored_polygon(PackedVector2Array([Vector2(-3.6, -14.5 + y), Vector2(3.6, -14.5 + y), Vector2(3.2, -9.5 + y), Vector2(1.8, -10 + y), Vector2(1.8, -13 + y), Vector2(-1.8, -13 + y), Vector2(-1.8, -10 + y), Vector2(-3.2, -9.5 + y)]), dark)
	draw_line(Vector2(-2.5, -8.5 + y), Vector2(2.5, -6.5 + y), dark, 0.9)
	draw_line(Vector2(2.5, -8.5 + y), Vector2(-2.5, -6.5 + y), dark, 0.9)
	for i in range(2):
		draw_line(Vector2(-1.2, -4 + i * 2 + y), Vector2(1.2, -4 + i * 2 + y), dark, 0.6)
	var k := clampf(t / every, 0.0, 1.0)
	if k > 0.8:
		draw_circle(Vector2(0, -6 + y), 2.0 + (k - 0.8) * 10.0, Color(0.6, 1, 0.9, 0.4))
