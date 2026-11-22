extends Area2D
## Ricompensa che compare a stanza ripulita: dono di un dio, Ka o cura.

signal collected(pickup: Area2D)

var kind := "boon"                    # boon | set | ka | heal
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
		"set":
			return Boons.god_color("set")
		"ka":
			return Color(0.94, 0.72, 0.3)
		"lapis":
			return Restorations.LAPIS_COLOR
		_:
			return Color(0.95, 0.35, 0.3)


func label() -> String:
	match kind:
		"boon":
			return Boons.god_name(god)
		"set":
			return Lang.t("Patto di Set")
		"ka":
			return Lang.t("Ka")
		"lapis":
			return Lang.t("Lapislazzuli")
		_:
			return Lang.t("Cura")


func _draw() -> void:
	var bob := sin(t * 3.0) * 2.0
	var c := color()
	# blocco 23: una colonna di luce del colore della ricompensa e raggi che girano a terra: si vede
	# da tutta la stanza, anche sul telefono e in mezzo alle pozze
	var pulse := 0.5 + 0.5 * sin(t * 2.6)
	for i in range(3):
		var w := 9.0 - i * 3.0
		draw_rect(Rect2(-w / 2.0, -64.0, w, 60.0), Color(c, (0.05 + 0.04 * pulse) * (1.0 + i * 0.5)))
	draw_set_transform(Vector2(0, 4), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 8.0, Color(0, 0, 0, 0.35))
	for i in range(6):
		var a := t * 0.9 + TAU * i / 6.0
		draw_line(Vector2.from_angle(a) * 11.0, Vector2.from_angle(a) * (19.0 + 3.0 * pulse), Color(c, 0.5), 2.0)
	draw_arc(Vector2.ZERO, 14.0 + 2.0 * pulse, 0.0, TAU, 24, Color(c, 0.55), 1.2)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2(0, -10 + bob), 11.0 + sin(t * 4.0), Color(c, 0.25))
	if kind == "lapis":
		Restorations.draw_gem(self, Vector2(0, -10 + bob), 1.3)
	else:
		draw_circle(Vector2(0, -10 + bob), 7.0, c)
		draw_circle(Vector2(-2, -12 + bob), 2.0, Color(1, 1, 1, 0.8))
	var font := UiStyle.body_font()
	draw_string_outline(font, Vector2(-40, -26 + bob), label(), HORIZONTAL_ALIGNMENT_CENTER, 80, 9, 3, Color(0.04, 0.03, 0.06, 0.85))
	draw_string(font, Vector2(-40, -26 + bob), label(), HORIZONTAL_ALIGNMENT_CENTER, 80, 9, Color(1, 0.95, 0.85))
