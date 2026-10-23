extends Area2D
## Ricompensa che compare a stanza ripulita: dono di un dio, Ka o cura.

signal collected(pickup: Area2D)

var kind := "boon"                    # boon | ka | heal
var god := ""
var t := 0.0
var _taken := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2                # corpo del giocatore
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if _taken or not body.is_in_group("player"):
		return
	_taken = true
	collected.emit(self)


func color() -> Color:
	match kind:
		"boon":
			return Boons.god_color(god)
		"ka":
			return Color(0.94, 0.72, 0.3)
		_:
			return Color(0.95, 0.35, 0.3)


func label() -> String:
	match kind:
		"boon":
			return Boons.god_name(god)
		"ka":
			return "Ka"
		_:
			return "Cura"


func _draw() -> void:
	var bob := sin(t * 3.0) * 2.0
	var c := color()
	draw_set_transform(Vector2(0, 4), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 8.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2(0, -10 + bob), 11.0 + sin(t * 4.0), Color(c, 0.25))
	draw_circle(Vector2(0, -10 + bob), 7.0, c)
	draw_circle(Vector2(-2, -12 + bob), 2.0, Color(1, 1, 1, 0.8))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-30, -26 + bob), label(), HORIZONTAL_ALIGNMENT_CENTER, 60, 9, Color(1, 0.95, 0.85))
