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
var seek := false                     ## Volo del Falco: curva verso il nemico più vicino
var return_mult := 0.0                ## Ritorno del Falco: torna indietro con questa frazione dei danni
var mark := false                     ## Sguardo del Falco: chi viene colpito subisce di più dal khopesh
var returning := false
var _hit := {}
var _done := false
var _healed := false                ## Figlio di Iside: questo lancio ha già curato


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
	if returning:
		var player = get_tree().get_first_node_in_group("player")
		if player == null:
			queue_free()
			return
		var to: Vector2 = player.global_position + Vector2(0, -8) - global_position
		if to.length() < 12.0:
			queue_free()
			return
		direction = to.normalized()
	elif seek:
		var best = null
		var best_d := 170.0
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.dead or _hit.has(e):
				continue
			var d: float = global_position.distance_to(e.global_position)
			if d < best_d and direction.dot((e.global_position - global_position).normalized()) > -0.2:
				best_d = d
				best = e
		if best != null:
			var want: Vector2 = (best.global_position + Vector2(0, -6) - global_position).normalized()
			direction = direction.rotated(clampf(direction.angle_to(want), -7.0 * delta, 7.0 * delta))
	position += direction * speed * delta
	life -= delta
	if life <= 0.0:
		_finish()
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if _done:
		return
	if body.is_in_group("breakables"):
		body.smash()
	if body.is_in_group("enemies"):
		if _hit.has(body) or body.dead:
			return
		_hit[body] = true
		var crit := Run.roll_crit(Run.eye_crit_chance())
		if crit > 1.0:
			Fx.float_text(body.global_position + Vector2(0, -20), "CRITICO", Boons.god_color("bastet"))
			if Run.has("duo_thoth_bastet"):
				var player = get_tree().get_first_node_in_group("player")
				if player != null:
					player.eye_cd *= 0.5
		if "hit_by_eye" in body:
			body.hit_by_eye = true
		body.take_hit(damage * crit, direction, 60.0, burns)
		if mark:
			body.mark_t = 3.0
		_duo_effects(body)
		Fx.shake(2.0)
		if returning:
			return                    # al ritorno attraversa tutto
		if pierce_left > 0:
			pierce_left -= 1
		else:
			_finish()
	elif body is StaticBody2D and not returning:
		_finish()


## Doni Doppi legati all'Occhio: Occhio Risanato (Horus e Thoth), Figlio di Iside (Iside e Horus).
func _duo_effects(body: Node) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if Run.has("duo_horus_thoth") and body.dead:
		player.eye_cd = 0.0              # al prossimo istante torna una carica
		Fx.float_text(player.global_position + Vector2(0, -26), "Occhio pronto", Boons.god_color("duo"))
	if Run.has("duo_iside_horus") and not _healed:
		_healed = true                   # una cura per lancio, anche se trapassa più nemici
		player.heal(2.0)


func _finish() -> void:
	if _done:
		return
	if return_mult > 0.0 and not returning:
		# Ritorno del Falco: invece di sparire, torna da chi l'ha lanciato
		returning = true
		_hit.clear()
		damage *= return_mult
		life = 2.0
		if explode_damage > 0.0:
			_explode()
			explode_damage = 0.0
		return
	_done = true
	if explode_damage > 0.0:
		_explode()
	else:
		Fx.burst(global_position, Color(0.5, 0.95, 0.88), 8, 80.0)
	queue_free()


func _explode() -> void:
	Fx.burst(global_position, Color(1, 0.6, 0.15), 24, 150.0)
	Fx.shake(4.0)
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.dead and not _hit.has(e) and e.global_position.distance_to(global_position) < 34.0:
			e.take_hit(explode_damage, (e.global_position - global_position).normalized(), 90.0)


func _draw() -> void:
	var core := Color(1, 0.75, 0.3) if (explode_damage > 0.0 or burns) else Color(0.5, 0.95, 0.88)
	draw_circle(Vector2.ZERO, 6.0, Color(core, 0.35))
	draw_circle(Vector2.ZERO, 3.5, core)
	draw_circle(Vector2.ZERO, 1.5, Color(1, 1, 1))
