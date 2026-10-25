extends Node2D
## SpawnMarker
## (Era una classe interna di game.gd: spostata qui nel riordino del codice.)

var duration := 0.8
var t := 0.0

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

func _draw() -> void:
	var k := clampf(t / duration, 0.0, 1.0)
	draw_arc(Vector2.ZERO, 6.0 + (1.0 - k) * 18.0, 0.0, TAU, 24, Color(1, 0.3, 0.2, 0.4 + 0.5 * k), 2.0)


## Ascolta Tab/Select anche a gioco in pausa, per aprire e chiudere il menu dei doni.
