extends Node2D
## Pozza della Marea del Nilo: rallenta i nemici che ci passano sopra per qualche secondo.

var radius := 32.0
var life := 3.0
var t := 0.0


func _ready() -> void:
	add_to_group("puddles")
	z_index = -1


func _process(delta: float) -> void:
	t += delta
	if t >= life:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var fade := clampf((life - t) / 0.5, 0.0, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, radius, Color(0.25, 0.55, 0.7, 0.35 * fade))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(0.5, 0.8, 0.9, 0.5 * fade), 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
