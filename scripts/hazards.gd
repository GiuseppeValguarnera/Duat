class_name Hazards
## Acqua e fuoco del Duat: le acque di Wernes, la Prima Ora.
## - Pozza d'acqua: rallenta chi la attraversa e spegne le fiamme. Il fuoco non vi entra.
## - Fuoco a terra: prima si accende (avviso), poi brucia chi ci sta sopra, nemici compresi.
## - Marea di fuoco: tutto il pavimento si incendia tranne l'acqua. Si sopravvive in una pozza,
##   oppure scattando nell'istante giusto.
## - Grata di fuoco: una fila di grate nel pavimento che si arroventano e poi sputano fiamme.
## - Giara d'olio: si rompe colpendola, l'olio prende fuoco poco dopo. Il fuoco ne accende altre.
## Le mummie, fasciate di lino, prendono il 50% di danni in più dal fuoco.

const WATER_SLOW := 0.7          ## velocità dentro l'acqua


## La pozza in cui si trova `p`, oppure null.
static func water_at(tree: SceneTree, p: Vector2) -> Node2D:
	for w in tree.get_nodes_in_group("water"):
		if w.contains(p):
			return w
	return null


static func in_water(tree: SceneTree, p: Vector2) -> bool:
	return water_at(tree, p) != null


## Danni del fuoco a un nemico: le bende delle mummie bruciano meglio.
static func fire_hit(e: Node, dmg: float) -> void:
	if String(e.scene_file_path).ends_with("mummy.tscn"):
		dmg *= 1.5
	e.take_hit(dmg, Vector2.ZERO, 0.0)
	e.burn_t = maxf(e.burn_t, 1.5)


## Rompe le giare d'olio entro `r` da `p` (il fuoco si propaga di giara in giara).
static func ignite_jars(tree: SceneTree, p: Vector2, r: float) -> void:
	for j in tree.get_nodes_in_group("breakables"):
		if not j.broken and j.global_position.distance_to(p) < r:
			j.smash.call_deferred(0.25)


## Pozza d'acqua nera, a forma di ellisse, con canne di papiro sul bordo.
## Con `rect` diverso da zero è un canale dritto, con il bordo di pietra.
class WaterPool extends Node2D:
	var radii := Vector2(40, 24)
	var rect := Vector2.ZERO
	var dry := 0.0               ## 0 = piena, 1 = prosciugata (Am-heh la fa evaporare)
	var drying := false
	var t := 0.0

	func _ready() -> void:
		add_to_group("water")

	func contains(p: Vector2) -> bool:
		if dry >= 0.95:
			return false
		var k := 1.0 - dry
		if rect != Vector2.ZERO:
			var q := p - global_position
			return absf(q.x) < rect.x / 2.0 * k and absf(q.y) < rect.y / 2.0 * k
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
		if rect != Vector2.ZERO:
			_draw_channel()
			return
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

	func _draw_channel() -> void:
		var k := 1.0 - dry
		var h := rect / 2.0
		draw_rect(Rect2(-h - Vector2(3, 3), rect + Vector2(6, 6)), Color(0.36, 0.27, 0.17))
		draw_rect(Rect2(-h - Vector2(3, 3), rect + Vector2(6, 6)), Color(0.2, 0.14, 0.08), false, 1.5)
		if k <= 0.02:
			return
		var hk := h * Vector2(1.0, k)
		draw_rect(Rect2(-hk, hk * 2.0), Color(0.1, 0.24, 0.38))
		draw_rect(Rect2(-hk + Vector2(0, 2), Vector2(hk.x * 2.0, 2)), Color(0.55, 0.8, 0.95, 0.25))
		# la corrente: trattini che scorrono lungo il canale
		var along := rect.x >= rect.y
		var n := int((rect.x if along else rect.y) / 18.0)
		for i in range(n):
			var f := fmod(i / float(n) + t * 0.08, 1.0)
			if along:
				var x := -h.x + f * rect.x
				draw_line(Vector2(x, sin(i * 1.7) * hk.y * 0.5), Vector2(x + 6, sin(i * 1.7) * hk.y * 0.5), Color(0.6, 0.85, 1.0, 0.35), 1.0)
			else:
				var y := -h.y + f * rect.y
				draw_line(Vector2(sin(i * 1.7) * h.x * 0.5, y), Vector2(sin(i * 1.7) * h.x * 0.5, y + 6), Color(0.6, 0.85, 1.0, 0.35), 1.0)


## Fuoco a terra. `owner_kind` è chi l'ha acceso (per i commenti di Anubi).
class FirePatch extends Node2D:
	var ignite := 0.45
	var radius := 16.0
	var life := 4.0
	var damage := 5.0
	var owner_kind := "amheh_fuoco"
	var t := 0.0
	var tick := 0.0
	var _lit := false

	func _ready() -> void:
		add_to_group("fire")
		z_index = 0

	func burning() -> bool:
		return t >= ignite

	func _physics_process(delta: float) -> void:
		t += delta
		if t > life:
			queue_free()
			return
		if not burning():
			queue_redraw()
			return
		if not _lit:
			_lit = true
			Sfx.play_at("fire_ignite", global_position, 0.15)
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
					Hazards.fire_hit(e, damage + 2.0)
			Hazards.ignite_jars(get_tree(), global_position, radius + 8.0)
		queue_redraw()

	func _draw() -> void:
		var fade := clampf((life - t) / 0.6, 0.0, 1.0)
		if not burning():
			# avviso: un cerchio di braci che si allarga
			var k := t / ignite
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
	var _burst := false
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
		if t >= warn and not _burst:
			_burst = true
			Sfx.play("flood_burst", 0.05)
			Fx.shake(6.0)
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


## Fila di grate nel pavimento: a ciclo si arroventano (avviso), poi sputano fiamme.
## `cells` grate in fila lungo `dir` (orizzontale o verticale), ognuna di 28 px.
class FireGrate extends Node2D:
	const CELL := 28.0
	var cells := 3
	var dir := Vector2.RIGHT
	var idle := 2.4
	var warn := 0.9
	var burn := 0.9
	var player_damage := 9.0
	var enemy_damage := 10.0
	var t := 0.0
	var _hit := {}

	func _ready() -> void:
		add_to_group("traps")

	func phase() -> String:
		if t < idle:
			return "idle"
		if t < idle + warn:
			return "warn"
		return "up"

	## Centri delle grate, in coordinate del mondo.
	func centers() -> Array:
		var out := []
		for i in range(cells):
			out.append(global_position + dir * (i - (cells - 1) / 2.0) * CELL)
		return out

	## Per i bot: la distanza dalla grata più vicina.
	func near(p: Vector2) -> float:
		var best := 1e9
		for c in centers():
			best = minf(best, p.distance_to(c))
		return best

	func _inside(p: Vector2) -> bool:
		var h := CELL / 2.0 + 3.0
		for c in centers():
			if absf(p.x - c.x) < h and absf(p.y - c.y) < h:
				return true
		return false

	func _physics_process(delta: float) -> void:
		var was := phase()
		t = fmod(t + delta, idle + warn + burn)
		var now := phase()
		if now == "up" and was != "up":
			_hit.clear()
			Sfx.play("fire_whoosh", 0.1)
			for c in centers():
				Hazards.ignite_jars(get_tree(), c, CELL)
		if now == "up":
			var player = get_tree().get_first_node_in_group("player")
			if player != null and not player.dead and not _hit.has(player) and _inside(player.global_position):
				if player.take_damage(player_damage, global_position, null, "grata"):
					_hit[player] = true
			for e in get_tree().get_nodes_in_group("enemies"):
				if e.dead or e.is_boss or _hit.has(e) or not _inside(e.global_position):
					continue
				_hit[e] = true
				Hazards.fire_hit(e, enemy_damage)
		queue_redraw()

	func _draw() -> void:
		var ph := phase()
		var h := CELL / 2.0
		for i in range(cells):
			var c := dir * (i - (cells - 1) / 2.0) * CELL
			draw_rect(Rect2(c - Vector2(h, h), Vector2(CELL, CELL)), Color(0.14, 0.11, 0.1))
			var bar := Color(0.32, 0.28, 0.26)
			if ph == "warn":
				var k := (t - idle) / warn
				bar = bar.lerp(Color(1, 0.45, 0.1), 0.4 + 0.6 * k * (0.7 + 0.3 * sin(t * 30.0)))
			elif ph == "idle":
				bar = bar.lerp(Color(0.8, 0.3, 0.1), 0.12 + 0.08 * sin(t * 2.0 + i))
			else:
				bar = Color(1, 0.6, 0.2)
			for k2 in range(4):
				var x := -h + 4.0 + k2 * 7.0
				draw_rect(Rect2(c + Vector2(x, -h + 3.0), Vector2(3, CELL - 6.0)), bar)
			draw_rect(Rect2(c - Vector2(h, h), Vector2(CELL, CELL)), Color(0.08, 0.06, 0.05), false, 1.5)
			if ph == "up":
				var fk := clampf(1.0 - (t - idle - warn) / burn, 0.0, 1.0)
				for j in range(4):
					var fx := -9.0 + j * 6.0
					var fh := 16.0 + 7.0 * sin(t * 22.0 + j * 1.9 + i)
					draw_colored_polygon(PackedVector2Array([c + Vector2(fx - 4, 8), c + Vector2(fx + 4, 8), c + Vector2(fx + sin(t * 15.0 + j) * 2.0, 8 - fh)]), Color(1, 0.5, 0.1, 0.9 * fk))
					draw_colored_polygon(PackedVector2Array([c + Vector2(fx - 2, 8), c + Vector2(fx + 2, 8), c + Vector2(fx, 8 - fh * 0.55)]), Color(1, 0.9, 0.45, fk))
			if Fx.show_hitboxes and ph == "up":
				draw_rect(Rect2(c - Vector2(h + 3, h + 3), Vector2(CELL + 6, CELL + 6)), Color(1, 0.2, 0.2, 0.9), false, 1.0)


## Giara d'olio: si rompe colpendola (lama, Occhio, fuoco). L'olio si sparge e, dopo un
## momento per allontanarsi, prende fuoco. Il fuoco accende le giare vicine.
class OilJar extends StaticBody2D:
	var broken := false
	var t := 0.0

	func _ready() -> void:
		add_to_group("breakables")
		collision_layer = 1
		collision_mask = 0
		var shape := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 8.0
		shape.shape = c
		shape.position = Vector2(0, -2)
		add_child(shape)
		t = randf() * 3.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	## `delay` > 0 quando la rompe il fuoco: una piccola attesa fa vedere la catena.
	func smash(delay: float = 0.0) -> void:
		if broken:
			return
		broken = true
		if delay > 0.0:
			await get_tree().create_timer(delay, false).timeout
		if not is_inside_tree():
			return
		Sfx.play("jar_break", 0.12)
		Fx.burst(global_position + Vector2(0, -6), Color(0.6, 0.4, 0.25), 12, 90.0)
		var f := FirePatch.new()
		f.radius = 28.0
		f.life = 4.2
		f.ignite = 0.6
		f.damage = 5.0
		f.owner_kind = "olio"
		get_parent().add_child(f)
		f.global_position = global_position
		queue_free()

	func _draw() -> void:
		# ombra, anfora rosso-bruna con le anse, goccia d'olio sul collo
		draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.4, 0.55))
		draw_circle(Vector2.ZERO, 7.0, Color(0, 0, 0, 0.3))
		# più grande dei vasi di decoro: si deve capire subito che è un oggetto da colpire
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.4, 1.4))
		var clay := Color(0.66, 0.28, 0.14)
		draw_colored_polygon(PackedVector2Array([Vector2(-3, -16), Vector2(3, -16), Vector2(7, -9), Vector2(6, -2), Vector2(2, 2), Vector2(-2, 2), Vector2(-6, -2), Vector2(-7, -9)]), clay)
		draw_rect(Rect2(-3.5, -18, 7, 3), clay.darkened(0.25))
		draw_arc(Vector2(-6, -12), 2.5, PI * 0.5, PI * 1.5, 6, clay.darkened(0.3), 1.2)
		draw_arc(Vector2(6, -12), 2.5, -PI * 0.5, PI * 0.5, 6, clay.darkened(0.3), 1.2)
		draw_line(Vector2(-6, -7), Vector2(6, -7), Color(0.9, 0.75, 0.4, 0.7), 1.0)
		var drip := fmod(t * 0.6, 1.0)
		draw_circle(Vector2(2, -15 + drip * 8.0), 1.2, Color(0.95, 0.8, 0.3, 0.9 * (1.0 - drip)))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
