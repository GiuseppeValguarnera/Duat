class_name Hazards
## Acqua e fuoco del Duat: le acque di Wernes, la Prima Ora.
## - Pozza d'acqua: rallenta chi la attraversa e spegne le fiamme. Il fuoco non vi entra.
## - Fuoco a terra: prima si accende (avviso), poi brucia chi ci sta sopra, nemici compresi.
## - Marea di fuoco: tutto il pavimento si incendia tranne l'acqua. Si sopravvive in una pozza,
##   oppure scattando nell'istante giusto.

const WATER_SLOW := 0.7          ## velocità dentro l'acqua


## La pozza in cui si trova `p`, oppure null.
static func water_at(tree: SceneTree, p: Vector2) -> Node2D:
	for w in tree.get_nodes_in_group("water"):
		if w.contains(p):
			return w
	return null


static func in_water(tree: SceneTree, p: Vector2) -> bool:
	return water_at(tree, p) != null


## Pozza d'acqua nera, a forma di ellisse, con canne di papiro sul bordo.
class WaterPool extends Node2D:
	var radii := Vector2(40, 24)
	var dry := 0.0               ## 0 = piena, 1 = prosciugata (Am-heh la fa evaporare)
	var drying := false
	var t := 0.0

	func _ready() -> void:
		add_to_group("water")

	func contains(p: Vector2) -> bool:
		if dry >= 0.95:
			return false
		var k := 1.0 - dry
		var d := (p - global_position) / (radii * k)
		return d.length() < 1.0

	func evaporate() -> void:
		drying = true

	func _process(delta: float) -> void:
		t += delta
		if drying and dry < 1.0:
			dry = minf(1.0, dry + delta / 2.2)
			if randf() < 0.5:
				Fx.burst(global_position + Vector2(randf_range(-radii.x, radii.x), randf_range(-radii.y, radii.y)) * (1.0 - dry), Color(0.85, 0.85, 0.9, 0.6), 2, 40.0)
			if dry >= 1.0:
				remove_from_group("water")
		queue_redraw()

	func _draw() -> void:
		var k := 1.0 - dry
		# fango secco dove l'acqua se n'è andata
		draw_set_transform(Vector2.ZERO, 0.0, radii / radii.x)
		draw_circle(Vector2.ZERO, radii.x + 3.0, Color(0.24, 0.18, 0.12, 0.6))
		if k > 0.02:
			draw_circle(Vector2.ZERO, (radii.x + 1.0) * k, Color(0.12, 0.2, 0.3))
			draw_circle(Vector2.ZERO, radii.x * k - 3.0, Color(0.1, 0.26, 0.4))
			# increspature
			for i in range(3):
				var rr := fmod(t * 9.0 + i * 13.0, radii.x * k)
				draw_arc(Vector2.ZERO, rr, 0.0, TAU, 28, Color(0.55, 0.8, 0.95, 0.25 * (1.0 - rr / (radii.x * k))), 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if k > 0.3:
			# canne di papiro sul bordo
			for i in range(5):
				var a := -2.4 + i * 0.35
				var base := Vector2(cos(a) * radii.x * k, sin(a) * radii.y * k)
				var sway := sin(t * 1.5 + i) * 1.5
				draw_line(base, base + Vector2(sway, -12), Color(0.35, 0.55, 0.25), 1.0)
				draw_circle(base + Vector2(sway, -13), 2.0, Color(0.55, 0.7, 0.3))


## Fuoco a terra. `owner_kind` è chi l'ha acceso (per i commenti di Anubi).
class FirePatch extends Node2D:
	const IGNITE := 0.45
	var radius := 16.0
	var life := 4.0
	var damage := 5.0
	var owner_kind := "amheh_fuoco"
	var t := 0.0
	var tick := 0.0

	func _ready() -> void:
		add_to_group("fire")
		z_index = 0

	func burning() -> bool:
		return t >= IGNITE

	func _physics_process(delta: float) -> void:
		t += delta
		if t > life:
			queue_free()
			return
		if not burning():
			queue_redraw()
			return
		tick -= delta
		if tick <= 0.0:
			tick = 0.5
			var player = get_tree().get_first_node_in_group("player")
			if player != null and not player.dead and player.global_position.distance_to(global_position) < radius + 4.0:
				player.take_damage(damage, global_position, null, owner_kind)
			for e in get_tree().get_nodes_in_group("enemies"):
				if e.dead or e.is_boss:
					continue
				if e.global_position.distance_to(global_position) < radius + e.radius:
					e.take_hit(damage + 2.0, Vector2.ZERO, 0.0)
					e.burn_t = maxf(e.burn_t, 1.0)
		queue_redraw()

	func _draw() -> void:
		var fade := clampf((life - t) / 0.6, 0.0, 1.0)
		if not burning():
			# avviso: un cerchio di braci che si allarga
			var k := t / IGNITE
			draw_circle(Vector2.ZERO, radius * k, Color(1, 0.5, 0.1, 0.18 + 0.2 * k))
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 20, Color(1, 0.6, 0.2, 0.5 * k), 1.0)
			return
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
		draw_circle(Vector2.ZERO, radius, Color(0.9, 0.25, 0.05, 0.35 * fade))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# lingue di fuoco
		for i in range(5):
			var a := float(i) / 5.0 * TAU + t * 0.6
			var p := Vector2(cos(a) * radius * 0.55, sin(a) * radius * 0.33)
			var h := 7.0 + 4.0 * sin(t * 11.0 + i * 1.7)
			var c1 := Color(1.0, 0.55, 0.1, 0.85 * fade)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-3, 0), p + Vector2(3, 0), p + Vector2(sin(t * 9.0 + i) * 2.0, -h)]), c1)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-1.5, 0), p + Vector2(1.5, 0), p + Vector2(0, -h * 0.55)]), Color(1, 0.9, 0.4, 0.9 * fade))


## Marea di fuoco: il pavimento si incendia una piastrella alla volta, partendo da `origin`,
## tranne le piastrelle nell'acqua. Prima l'avviso, poi la vampata.
class FireFlood extends Node2D:
	var area := Rect2()
	var origin := Vector2.ZERO
	var warn := 1.5
	var burn := 0.7
	var damage := 22.0
	var owner_kind := "amheh_marea"
	var t := 0.0
	var hit := false
	var cells: Array = []        ## [centro, distanza dall'origine]
	var max_d := 1.0

	func setup() -> void:
		var y := area.position.y
		while y < area.end.y:
			var x := area.position.x
			while x < area.end.x:
				var c := Vector2(x + 16.0, y + 16.0)
				if not Hazards.in_water(get_tree(), c):
					var d := c.distance_to(origin)
					cells.append([c, d])
					max_d = maxf(max_d, d)
				x += 32.0
			y += 32.0

	func _physics_process(delta: float) -> void:
		t += delta
		if t > warn + burn:
			queue_free()
			return
		# ferisce solo nell'istante della vampata: le fiamme che restano sono solo da guardare
		if t >= warn and t < warn + 0.15 and not hit:
			var player = get_tree().get_first_node_in_group("player")
			if player != null and not player.dead and not Hazards.in_water(get_tree(), player.global_position):
				if player.take_damage(damage, origin, null, owner_kind):
					hit = true
			for e in get_tree().get_nodes_in_group("enemies"):
				if not e.dead and not e.is_boss and not Hazards.in_water(get_tree(), e.global_position):
					e.take_hit(damage, Vector2.ZERO, 0.0)
					e.burn_t = maxf(e.burn_t, 2.0)
		queue_redraw()

	func _draw() -> void:
		if t < warn:
			# avviso: le piastrelle si accendono di rosso a ondata, dalla bestia verso i bordi
			var front := (t / warn) * max_d * 1.15
			var blink := 0.5 + 0.5 * sin(t * 18.0)
			for c in cells:
				if c[1] <= front:
					var a := 0.1 + 0.16 * (t / warn) + 0.08 * blink * (t / warn)
					draw_rect(Rect2(c[0] - Vector2(15, 15), Vector2(30, 30)), Color(1, 0.25, 0.08, a))
			return
		var fade := clampf(1.0 - (t - warn) / burn, 0.0, 1.0)
		for c in cells:
			draw_rect(Rect2(c[0] - Vector2(16, 16), Vector2(32, 32)), Color(1, 0.45, 0.1, 0.45 * fade))
			var h := 10.0 + 6.0 * sin(t * 20.0 + c[0].x * 0.1)
			draw_colored_polygon(PackedVector2Array([c[0] + Vector2(-6, 8), c[0] + Vector2(6, 8), c[0] + Vector2(0, 8 - h)]), Color(1, 0.8, 0.3, 0.7 * fade))
