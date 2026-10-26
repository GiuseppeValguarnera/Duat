extends Node
## Prova di caricamento: Serket, la nube e il tempio compilano con gli avvisi trattati come errori.
var t := 0.0
func _process(dt: float) -> void:
	t += dt
	if t < 1.0:
		return
	var sc: PackedScene = load("res://scenes/serket.tscn")
	var e = sc.instantiate()
	var c = Hazards.VenomCloud.new()
	print("LOG serket=", e != null, " cloud=", c != null, " mounds=", Arenas.temple_mounds(Rect2(0, 0, 800, 480), 64.0, 32.0).size())
	e.free(); c.free()
	get_tree().quit()
