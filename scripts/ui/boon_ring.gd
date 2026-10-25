extends Node2D
## Anello di luce che si allarga attorno al giocatore quando prende un dono.
## (Era una classe interna di game.gd: spostata qui nel riordino del codice.)

var color := Color.WHITE
var t := 0.0

func _ready() -> void:
	z_index = 3
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	t += delta
	if t > 0.7:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var k := t / 0.7
	draw_arc(Vector2.ZERO, 8.0 + 70.0 * k, 0.0, TAU, 48, Color(color, 1.0 - k), 4.0 * (1.0 - k) + 1.0)
	draw_arc(Vector2.ZERO, 4.0 + 40.0 * k, 0.0, TAU, 32, Color(1, 0.95, 0.8, 0.8 * (1.0 - k)), 2.0)
	for i in range(8):
		var a := TAU * i / 8.0 + k
		draw_line(Vector2.from_angle(a) * (10.0 + 30.0 * k), Vector2.from_angle(a) * (20.0 + 60.0 * k), Color(color, 0.7 * (1.0 - k)), 2.0)



## Frecce sul bordo dello schermo verso le porte aperte che non si vedono: con il colore
## e il nome della ricompensa, così si capisce subito che le uscite sono più di una.
