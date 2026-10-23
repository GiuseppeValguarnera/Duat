extends Node2D
## Mirino che segue il mouse. L'arco turchese mostra la ricarica dell'Occhio di Horus.

func _process(_delta: float) -> void:
	position = get_viewport().get_mouse_position()
	queue_redraw()


func _draw() -> void:
	var gold := Color(0.94, 0.72, 0.3)
	draw_arc(Vector2.ZERO, 4.5, 0.0, TAU, 20, Color(0, 0, 0, 0.8), 2.5)
	draw_arc(Vector2.ZERO, 4.5, 0.0, TAU, 20, gold, 1.0)
	for i in range(4):
		var d := Vector2.from_angle(PI / 4.0 + i * PI / 2.0)
		draw_line(d * 2.5, d * 7.0, gold, 1.0)
	draw_rect(Rect2(-0.5, -0.5, 1, 1), Color(1, 0.95, 0.8))
	var player = get_tree().get_first_node_in_group("player")
	if player != null and is_instance_valid(player):
		var k: float = 1.0 - player.eye_cd / player.eye_cd_max()
		if k > 0.0 and k < 1.0:
			draw_arc(Vector2.ZERO, 8.5, -PI / 2.0, -PI / 2.0 + TAU * k, 28, Color(0.25, 0.75, 0.68), 1.5)
		elif k >= 1.0:
			draw_arc(Vector2.ZERO, 8.5, 0.0, TAU, 28, Color(0.25, 0.75, 0.68, 0.5), 1.0)
