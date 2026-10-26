extends Node2D
## Pozza della Marea del Nilo: rallenta i nemici che ci passano sopra per qualche secondo.
## Acqua turchese con il bordo che brilla, increspature che si allargano e una piccola luce
## azzurra: deve vedersi bene, perché è lì che vuoi attirare i nemici. Prima era disegnata
## sotto il pavimento e si vedeva appena.

var radius := 32.0
var life := 3.0
var t := 0.0
var light: PointLight2D


func _ready() -> void:
	add_to_group("puddles")
	z_index = 0
	light = Atmos.add_light(self, Vector2.ZERO, radius * 2.6, Color(0.35, 0.8, 1.0), 0.9, false)
	light.set_process(false)
	Fx.burst(global_position + Vector2(0, -4), Color(0.5, 0.85, 1.0), 14, 80.0)
	Sfx.play_at("splash", global_position, 0.15)


func _process(delta: float) -> void:
	t += delta
	if t >= life:
		queue_free()
		return
	var fade := clampf((life - t) / 0.5, 0.0, 1.0) * clampf(t / 0.12, 0.0, 1.0)
	light.energy = 0.9 * fade
	queue_redraw()


func _draw() -> void:
	var fade := clampf((life - t) / 0.5, 0.0, 1.0)
	var grow := clampf(t / 0.15, 0.3, 1.0)       # si allarga quando compare
	var r := radius * grow
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, r, Color(0.1, 0.45, 0.62, 0.62 * fade))
	draw_circle(Vector2.ZERO, r * 0.7, Color(0.18, 0.62, 0.78, 0.5 * fade))
	# increspature che partono dal centro
	for k in range(3):
		var f := fmod(t * 0.9 + k / 3.0, 1.0)
		draw_arc(Vector2.ZERO, r * (0.25 + f * 0.7), 0.0, TAU, 28, Color(0.75, 0.95, 1.0, 0.45 * (1.0 - f) * fade), 1.2)
	# il bordo che brilla, con un luccichio che gira
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 36, Color(0.6, 0.92, 1.0, 0.85 * fade), 2.0)
	var sp := t * 2.2
	draw_arc(Vector2.ZERO, r, sp, sp + 0.6, 8, Color(1, 1, 1, 0.9 * fade), 2.4)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
