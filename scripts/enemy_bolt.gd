extends Area2D
## Sfera del Sacerdote di Set. Si ferma sui muri e su di te.
## Se stai scattando ti attraversa senza farti nulla.

var direction := Vector2.RIGHT
var speed := 150.0
var damage := 12.0
var life := 4.0
var shooter: Node = null              ## chi l'ha lanciata (per la Bilancia Giusta)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 8            # mondo + hurtbox del giocatore
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	add_child(shape)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	life -= delta
	if life <= 0.0:
		queue_free()
	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	var p = area.get_parent()
	var src: Node = shooter if is_instance_valid(shooter) else null
	if p.is_in_group("player") and p.take_damage(damage, global_position, src):
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body is StaticBody2D:
		Fx.burst(global_position, Color(0.85, 0.4, 1.0), 6, 60.0)
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color(0.85, 0.4, 1.0, 0.3))
	draw_circle(Vector2.ZERO, 3.5, Color(0.75, 0.3, 1.0))
	draw_circle(Vector2.ZERO, 1.5, Color(1, 0.9, 1))
