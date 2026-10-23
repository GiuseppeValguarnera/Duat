extends Node2D
## Mirino che segue il mouse. Il cerchio turchese mostra la ricarica dell'Occhio di Horus.

func _process(_delta: float) -> void:
	position = get_viewport().get_mouse_position()
	queue_redraw()


func _draw() -> void:
	var gold := Color(0.94, 0.72, 0.3)
	draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 24, Color(0, 0, 0, 0.8), 3.0)
	draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 24, gold, 1.5)
	for i in range(4):
		var d := Vector2.from_angle(PI / 4.0 + i * PI / 2.0)
		draw_line(d * 4.0, d * 11.0, gold, 1.5)
	draw_rect(Rect2(-1, -1, 2, 2), Color(1, 0.95, 0.8))
	var player = get_tree().get_first_node_in_group("player")
	if player != null and is_instance_valid(player):
		var k: float = 1.0 - player.eye_cd / player.eye_cd_max()
		if k > 0.0:
			draw_arc(Vector2.ZERO, 13.0, -PI / 2.0, -PI / 2.0 + TAU * k, 32, Color(0.25, 0.75, 0.68), 2.0)
