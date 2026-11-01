extends Node2D
## La lancia di Neith lanciata (attacco caricato): vola dritta, trapassa tutti i nemici che incontra,
## poi torna nella mano dell'eroe colpendo di nuovo chi trova sulla via del ritorno. Finché non
## torna l'eroe è disarmato (player.gd, `spear_thrown`).

var dir := Vector2.RIGHT
var player: Node2D = null
var dmg_out := 30.0
var dmg_back := 15.0
var speed := 430.0
var max_dist := 210.0
var knock := 150.0
var back := false
var travelled := 0.0
var life := 0.0
var hit_out := {}
var hit_back := {}
var trail: Array = []


func _ready() -> void:
	z_index = 3


func _physics_process(delta: float) -> void:
	life += delta
	if player == null or not is_instance_valid(player):
		queue_free()
		return
	var step := speed * delta
	if not back:
		global_position += dir * step
		travelled += step
		var g = get_tree().current_scene
		var out_of_room: bool = g != null and g.has_method("_in_floor") and not g._in_floor(global_position, 4.0)
		if travelled >= max_dist or out_of_room:
			back = true
	else:
		var to: Vector2 = player.global_position + Vector2(0, -8) - global_position
		if to.length() < 14.0 or life > 3.0:
			_caught()
			return
		dir = to.normalized()
		global_position += dir * minf(step * 1.15, to.length())
	_hit(hit_back if back else hit_out, dmg_back if back else dmg_out)
	trail.push_front(global_position)
	if trail.size() > 6:
		trail.pop_back()
	queue_redraw()


func _hit(done: Dictionary, dmg: float) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead or done.has(e):
			continue
		if global_position.distance_to(e.global_position + Vector2(0, -6)) < e.radius + 9.0:
			done[e] = true
			if Run.has("nefti_veil"):
				e.mourn_t = 4.0                # Velo del Lutto: anche la lancia lanciata marchia
			Run.nefti_on_hit()
			e.take_hit(dmg, dir, knock * (0.5 if back else 1.0))
			Fx.impact(e.global_position + Vector2(0, -e.radius), dir, true)
	for j in get_tree().get_nodes_in_group("breakables"):
		if not j.broken and global_position.distance_to(j.global_position) < 14.0:
			j.smash()


func _caught() -> void:
	if player != null and is_instance_valid(player):
		player.spear_thrown = null
		Sfx.play("pickup", 0.1)
		Fx.burst(player.global_position + Vector2(0, -10), Color(0.95, 0.85, 0.55), 8, 60.0)
	queue_free()


func _draw() -> void:
	# la scia, poi la lancia lungo la direzione del volo
	for i in range(1, trail.size()):
		var p0: Vector2 = trail[i - 1] - global_position
		var p1: Vector2 = trail[i] - global_position
		draw_line(p0, p1, Color(1.0, 0.9, 0.55, 0.5 * (1.0 - float(i) / trail.size())), 3.0)
	var d := dir if not back else -dir
	draw_line(-d * 16.0, d * 12.0, Color(0.12, 0.08, 0.05), 3.0)
	draw_line(-d * 16.0, d * 12.0, Color(0.6, 0.42, 0.22), 1.8)
	var tip := d * 12.0
	draw_colored_polygon(PackedVector2Array([tip + d * 7.0, tip + d.orthogonal() * 2.6, tip - d.orthogonal() * 2.6]), Color(0.9, 0.9, 0.95))
