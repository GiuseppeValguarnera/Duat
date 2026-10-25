extends Control
## Triangolo del riassunto delle carte (▲ vantaggio, ▼ prezzo).
## (Era una classe interna di game.gd: spostata qui nel riordino del codice.)

var up := true
var color := Color.WHITE

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	# triangolo di lato fisso, centrato nello spazio (che può essere alto quanto una riga)
	var k := minf(size.x, size.y)
	var o := Vector2((size.x - k) / 2.0, (size.y - k) / 2.0)
	var pts := PackedVector2Array([o + Vector2(k / 2.0, 0), o + Vector2(k, k), o + Vector2(0, k)]) if up else PackedVector2Array([o, o + Vector2(k, 0), o + Vector2(k / 2.0, k)])
	draw_colored_polygon(pts, color)
