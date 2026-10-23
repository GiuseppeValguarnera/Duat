extends Area2D
## Occhio di Horus: raggio che attraversa i nemici e si ferma sui muri.

var direction := Vector2.RIGHT
var damage := 24.0
var speed := 320.0
var life := 1.2
var _hit := {}


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 4            # mondo + nemici
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	life -= delta
	if life <= 0.0:
		queue_free()
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies"):
		if _hit.has(body) or body.dead:
			return
		_hit[body] = true
		body.take_hit(damage, direction, 60.0)
		Fx.shake(2.0)
	elif body is StaticBody2D:
		Fx.burst(global_position, Color(0.5, 0.95, 0.88), 8, 80.0)
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color(0.35, 0.9, 0.85, 0.35))
	draw_circle(Vector2.ZERO, 3.5, Color(0.5, 0.95, 0.88))
	draw_circle(Vector2.ZERO, 1.5, Color(1, 1, 1))
