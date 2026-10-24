class_name Traps
## Trappole da piramide. Si annunciano sempre prima di colpire e lo scatto le supera.
##  - Spuntoni: una lastra nel pavimento. I fori si illuminano, poi escono le punte.
##    Feriscono chiunque ci sia sopra, anche i nemici.
##  - Feritoia: una testa di serpente nella parete. Gli occhi si accendono, poi spara un dardo
##    che attraversa la stanza.

const BoltScript := preload("res://scripts/enemy_bolt.gd")


class Spikes extends Node2D:
	const SIZE := 28.0
	var idle := 2.2
	var warn := 0.6
	var up := 0.55
	var t := 0.0
	var player_damage := 10.0
	var enemy_damage := 14.0
	var _hit := {}

	func _ready() -> void:
		add_to_group("traps")

	func _physics_process(delta: float) -> void:
		var cycle := idle + warn + up
		var was := phase()
		t = fmod(t + delta, cycle)
		var now := phase()
		if now == "up" and was != "up":
			_hit.clear()
			Fx.burst(global_position, Color(0.85, 0.85, 0.9), 6, 50.0)
			Sfx.play("spikes")
		if now == "up":
			_strike()
		queue_redraw()

	func phase() -> String:
		if t < idle:
			return "idle"
		if t < idle + warn:
			return "warn"
		return "up"

	func _inside(pos: Vector2) -> bool:
		var h := SIZE / 2.0 + 3.0
		return absf(pos.x - global_position.x) < h and absf(pos.y - global_position.y) < h

	func _strike() -> void:
		var player = get_tree().get_first_node_in_group("player")
		if player != null and not player.dead and not _hit.has(player) and _inside(player.global_position):
			if player.take_damage(player_damage, global_position):
				_hit[player] = true
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.dead or e.is_boss or _hit.has(e) or not _inside(e.global_position):
				continue
			_hit[e] = true
			e.take_hit(enemy_damage, Vector2.UP, 40.0)

	func _draw() -> void:
		var h := SIZE / 2.0
		draw_rect(Rect2(-h, -h, SIZE, SIZE), Color(0.36, 0.27, 0.17))
		draw_rect(Rect2(-h, -h, SIZE, SIZE), Color(0.2, 0.14, 0.08), false, 1.5)
		var p := phase()
		for j in range(3):
			for i in range(3):
				var c := Vector2(-8 + i * 8, -8 + j * 8)
				if p == "idle":
					draw_circle(c, 1.5, Color(0.12, 0.08, 0.05))
				elif p == "warn":
					draw_circle(c, 2.0, Color(1, 0.6, 0.25, 0.6 + 0.4 * sin(t * 30.0)))
				else:
					draw_colored_polygon(PackedVector2Array([c + Vector2(-2.5, 2), c + Vector2(2.5, 2), c + Vector2(0, -7)]), Color(0.86, 0.86, 0.92))
		if Fx.show_hitboxes and p == "up":
			draw_rect(Rect2(-h - 3, -h - 3, SIZE + 6, SIZE + 6), Color(1, 0.2, 0.2, 0.9), false, 1.0)


class DartWall extends Node2D:
	var dir := Vector2.RIGHT              ## verso dove spara
	var every := 3.4
	var warn := 0.8
	var t := 0.0
	var damage := 10.0
	var _fired := false

	func _ready() -> void:
		add_to_group("traps")

	func _physics_process(delta: float) -> void:
		t += delta
		if t >= every:
			t = 0.0
			_fired = false
		if not _fired and t >= warn and t < warn + 0.1:
			_fire()
		queue_redraw()

	func _fire() -> void:
		_fired = true
		Sfx.play("dart")
		var bolt: Area2D = BoltScript.new()
		bolt.direction = dir
		bolt.speed = 230.0
		bolt.damage = damage
		bolt.style = "dart"
		get_parent().add_child(bolt)
		bolt.global_position = global_position + dir * 12.0

	func _draw() -> void:
		# testa di cobra scolpita nella parete
		var s := dir.x
		draw_rect(Rect2(-6, -9, 12, 18), Color(0.55, 0.42, 0.25))
		draw_rect(Rect2(-6, -9, 12, 18), Color(0.3, 0.22, 0.12), false, 1.0)
		draw_circle(Vector2(s * 3.0, 0), 4.0, Color(0.2, 0.45, 0.4))
		var glow := t < warn and not _fired
		var eye := Color(1, 0.3, 0.15, 0.6 + 0.4 * sin(t * 25.0)) if glow else Color(0.15, 0.1, 0.08)
		draw_circle(Vector2(s * 4.0, -2), 1.3, eye)
		draw_circle(Vector2(s * 4.0, 2), 1.3, eye)
		if glow:
			draw_line(Vector2(s * 8.0, 0), Vector2(s * 40.0, 0), Color(1, 0.3, 0.15, 0.25), 1.0)
