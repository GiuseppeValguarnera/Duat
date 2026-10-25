extends Area2D
## Cuore (ib) lasciato da un nemico abbattuto, con il capitolo 26 del Libro dei Morti.
## Cura chi lo raccoglie; dopo qualche secondo lampeggia e svanisce.

const LIFE := 9.0

var amount := 6.0
var t := 0.0
var _taken := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2                # corpo del giocatore
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	z_index = 1


func _process(delta: float) -> void:
	t += delta
	if t > LIFE:
		queue_free()
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if _taken or not body.is_in_group("player") or body.dead:
		return
	_taken = true
	body.heal(amount)
	Sfx.play("pickup", 0.1)
	Fx.burst(global_position + Vector2(0, -6), Color(0.95, 0.3, 0.3), 10, 60.0)
	queue_free()


func _draw() -> void:
	# negli ultimi secondi lampeggia
	if t > LIFE - 2.5 and fmod(t, 0.3) < 0.12:
		return
	var pop := minf(1.0, t * 5.0)
	var bob := sin(t * 4.0) * 1.5 - 7.0
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 5.0, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE * pop)
	draw_circle(Vector2.ZERO, 8.0 + sin(t * 6.0), Color(0.95, 0.3, 0.3, 0.22))
	# l'ib: il cuore egizio a forma di vaso, con le due anse
	var red := Color(0.86, 0.18, 0.2)
	var body := PackedVector2Array([Vector2(-3, -4), Vector2(3, -4), Vector2(5, -1), Vector2(4, 3), Vector2(0, 6), Vector2(-4, 3), Vector2(-5, -1)])
	draw_colored_polygon(body, red)
	draw_rect(Rect2(-2.5, -6, 5, 2), Color(0.94, 0.72, 0.3))
	draw_line(Vector2(-3, -4), Vector2(-6, -3), red.darkened(0.3), 1.2)
	draw_line(Vector2(3, -4), Vector2(6, -3), red.darkened(0.3), 1.2)
	draw_circle(Vector2(-1.5, -1), 1.2, Color(1, 0.8, 0.8, 0.8))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
