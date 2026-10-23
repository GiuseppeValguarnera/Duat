extends Area2D
## Occhio di Horus. Di base si ferma sul primo nemico che colpisce.
## Con lo Sguardo di Thoth ne trapassa altri; con il Disco di Ra esplode.

var direction := Vector2.RIGHT
var damage := 24.0
var speed := 320.0
var life := 1.2
var pierce_left := 0                  ## nemici in più che può attraversare
var explode_damage := 0.0             ## Disco di Ra: danni dell'esplosione (0 = niente)
var burns := false
var _hit := {}
var _done := false


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
		_finish()
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if _done:
		return
	if body.is_in_group("enemies"):
		if _hit.has(body) or body.dead:
			return
		_hit[body] = true
		body.take_hit(damage, direction, 60.0, burns)
		Fx.shake(2.0)
		if pierce_left > 0:
			pierce_left -= 1
		else:
			_finish()
	elif body is StaticBody2D:
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	if explode_damage > 0.0:
		Fx.burst(global_position, Color(1, 0.6, 0.15), 24, 150.0)
		Fx.shake(4.0)
		for e in get_tree().get_nodes_in_group("enemies"):
			if not e.dead and not _hit.has(e) and e.global_position.distance_to(global_position) < 34.0:
				e.take_hit(explode_damage, (e.global_position - global_position).normalized(), 90.0)
	else:
		Fx.burst(global_position, Color(0.5, 0.95, 0.88), 8, 80.0)
	queue_free()


func _draw() -> void:
	var core := Color(1, 0.75, 0.3) if (explode_damage > 0.0 or burns) else Color(0.5, 0.95, 0.88)
	draw_circle(Vector2.ZERO, 6.0, Color(core, 0.35))
	draw_circle(Vector2.ZERO, 3.5, core)
	draw_circle(Vector2.ZERO, 1.5, Color(1, 1, 1))
