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
	var basin := false           ## vasca sacra rettangolare con i gradini (l'arena di Am-heh)
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

	var warn_t := 0.0            ## prima di evaporare ribolle e fuma: l'avviso per chi ci sta dentro

	func evaporate(warning: float = 0.0) -> void:
		if warning <= 0.0:
			drying = true
		else:
			warn_t = warning

	func _process(delta: float) -> void:
		t += delta
		if warn_t > 0.0:
			warn_t -= delta
			if randf() < 0.6:
				Fx.burst(global_position + Vector2(randf_range(-radii.x, radii.x) * 0.7, randf_range(-radii.y, radii.y) * 0.7), Color(0.9, 0.9, 0.95, 0.7), 2, 50.0)
			if warn_t <= 0.0:
				drying = true
		if drying and dry < 1.0:
			dry = minf(1.0, dry + delta / 2.2)
			if randf() < 0.5:
				Fx.burst(global_position + Vector2(randf_range(-radii.x, radii.x), randf_range(-radii.y, radii.y)) * (1.0 - dry), Color(0.85, 0.85, 0.9, 0.6), 2, 40.0)
			if dry >= 1.0:
				remove_from_group("water")
		queue_redraw()

	func _draw() -> void:
		var k := 1.0 - dry
		if basin:
			_draw_basin()
			return
		if rect != Vector2.ZERO:
			_draw_channel()
			return
		# fango secco dove l'acqua se n'è andata
		draw_set_transform(Vector2.ZERO, 0.0, radii / radii.x)
		draw_circle(Vector2.ZERO, radii.x + 3.0, Color(0.24, 0.18, 0.12, 0.6))
		if k > 0.02:
			draw_circle(Vector2.ZERO, (radii.x + 1.0) * k, Color(0.12, 0.2, 0.3))
			draw_circle(Vector2.ZERO, radii.x * k - 3.0, Color(0.1, 0.26, 0.4))
			# sta per evaporare: l'acqua bolle, rossa di calore
			if warn_t > 0.0:
				var boil := 0.5 + 0.5 * sin(t * 18.0)
				draw_circle(Vector2.ZERO, radii.x * k - 3.0, Color(0.9, 0.4, 0.2, 0.18 + 0.15 * boil))
				for i in range(6):
					var bp := Vector2(sin(i * 2.3 + t * 3.0), cos(i * 1.7 + t * 2.0)) * radii.x * 0.6
					draw_circle(bp, 2.0 + 1.5 * absf(sin(t * 9.0 + i)), Color(0.85, 0.95, 1.0, 0.6))
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

	## La vasca sacra: bordo di pietra chiara, gradini che scendono, acqua azzurra che brilla di
	## luce fredda (l'unica cosa fresca nel Lago di Fuoco), fiori di loto. Prosciugandosi l'acqua
	## si ritira verso il centro e restano i gradini asciutti.
	func _draw_basin() -> void:
		var k := 1.0 - dry
		var h := rect / 2.0
		var rim := Color(0.78, 0.7, 0.58)
		draw_rect(Rect2(-h - Vector2(7, 7), rect + Vector2(14, 14)), Color(0.12, 0.08, 0.07))
		draw_rect(Rect2(-h - Vector2(6, 6), rect + Vector2(12, 12)), rim)
		draw_rect(Rect2(-h - Vector2(6, 6), Vector2(rect.x + 12, 2)), rim.lightened(0.2))
		# i gradini, uno dentro l'altro
		for s in range(3):
			var g := Rect2(-h + Vector2(s * 4.0, s * 3.0), rect - Vector2(s * 8.0, s * 6.0))
			draw_rect(g, rim.darkened(0.18 + s * 0.12))
			draw_rect(Rect2(g.position, Vector2(g.size.x, 1.2)), rim.darkened(0.05 + s * 0.1))
		if k <= 0.02:
			return
		var wr := Rect2(-h * k + Vector2(2, 2) * k, (rect - Vector2(4, 4)) * k)
		var pulse := 0.5 + 0.5 * sin(t * 2.0)
		draw_rect(wr.grow(3.0), Color(0.4, 0.8, 1.0, 0.18 + 0.08 * pulse))
		draw_rect(wr, Color(0.16, 0.48, 0.66))
		draw_rect(Rect2(wr.position, Vector2(wr.size.x, wr.size.y * 0.4)), Color(0.3, 0.66, 0.84, 0.6))
		for i in range(4):
			var f := fmod(t * 0.15 + i * 0.25, 1.0)
			draw_line(Vector2(wr.position.x + 4, wr.position.y + f * wr.size.y), Vector2(wr.position.x + wr.size.x * 0.4, wr.position.y + f * wr.size.y), Color(0.85, 0.97, 1.0, 0.3), 1.0)
		if warn_t > 0.0:
			var boil := 0.5 + 0.5 * sin(t * 18.0)
			draw_rect(wr, Color(0.9, 0.4, 0.2, 0.2 + 0.15 * boil))
		if k > 0.5:
			for j in range(3):
				var lp := Vector2(lerpf(-h.x * 0.6, h.x * 0.6, j / 2.0), sin(j * 2.1) * h.y * 0.3) * k
				draw_set_transform(lp, 0.0, Vector2(1.0, 0.6))
				draw_circle(Vector2.ZERO, 5.0, Color(0.18, 0.45, 0.3))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				if j != 1:
					draw_circle(lp + Vector2(1, -2), 2.4, Color(0.98, 0.8, 0.88))
					draw_circle(lp + Vector2(1, -2), 0.9, Color(1.0, 0.85, 0.4))

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


## Le statue dell'ureo nell'arena del Serpente della Porta: il cobra che sputa fuoco e proteggeva
## il faraone. Quattro teste di cobra: due sulle pareti laterali, due sul muro in alto (così sul
## telefono se ne vede sempre qualcuna). A turno una si accende (gli occhi rossi e una fila di
## braci sul pavimento: l'avviso), poi sputa una lingua di fuoco attraverso la stanza, fino alla
## prima colonna. Brucia te, il Serpente e i suoi scarabei: farcelo passare sopra è una
## strategia, ripararsi dietro una colonna un'altra. Si spengono quando il guardiano cade.
class UraeusStatues extends Node2D:
	const WARN := 0.9
	const FIRE := 0.45
	const BAND := 10.0                    ## mezza larghezza della lingua di fuoco
	var room := Rect2()
	var wall := 32.0
	var top := 64.0
	var pillars: Array = []
	var statues: Array = []               ## [posizione della bocca, direzione del fuoco]
	var current := -1
	var last := -1
	var phase := "idle"
	var t := 0.0
	var wait := 4.0                       ## la prima vampata arriva dopo qualche secondo
	var hit_player := false
	var hit_enemies := {}
	var reach := Vector2.ZERO             ## dove finisce il fuoco (la parete o la prima colonna)
	var seen_guardian := false            ## il Serpente è già uscito (se poi sparisce, è caduto)

	func setup(room_rect: Rect2, wall_w: float, top_y: float, pillar_list: Array) -> void:
		room = room_rect
		wall = wall_w
		top = top_y
		pillars = pillar_list
		var y0 := top
		var y1 := room.size.y - wall
		var x0 := wall
		var x1 := room.size.x - wall
		# nei corridoi liberi tra le colonne dell'arena (al 30% e al 70%, in alto e in basso):
		# allineate alle colonne, le lingue di fuoco si fermavano dopo pochi passi
		statues.append([Vector2(wall + 6.0, lerpf(y0, y1, 0.53)), Vector2.RIGHT])
		statues.append([Vector2(room.size.x - wall - 6.0, lerpf(y0, y1, 0.88)), Vector2.LEFT])
		statues.append([Vector2(lerpf(x0, x1, 0.42), top - 6.0), Vector2.DOWN])
		statues.append([Vector2(lerpf(x0, x1, 0.58), top - 6.0), Vector2.DOWN])
		add_to_group("uraeus")

	## La striscia in pericolo adesso (anche per il bot di playtest), o un rettangolo vuoto.
	func danger() -> Rect2:
		if current < 0 or (phase != "warn" and phase != "fire"):
			return Rect2()
		var m: Vector2 = statues[current][0]
		var d: Vector2 = statues[current][1]
		var r := Rect2(m, Vector2.ZERO).expand(reach)
		return r.grow_individual(BAND if d.y != 0.0 else 0.0, BAND if d.x != 0.0 else 0.0, BAND if d.y != 0.0 else 0.0, BAND if d.x != 0.0 else 0.0)

	## Direzione per uscire dalla striscia (per il bot di playtest).
	func escape_dir(p: Vector2) -> Vector2:
		var d: Vector2 = statues[current][1]
		var m: Vector2 = statues[current][0]
		var side := d.orthogonal()
		return side if (p - m).dot(side) >= 0.0 else -side

	func _physics_process(delta: float) -> void:
		var game = get_tree().current_scene
		var guardian = game.boss if game != null and "boss" in game else null
		var gone: bool = guardian == null or not is_instance_valid(guardian)
		if gone and not seen_guardian:
			return                        # il Serpente non è ancora uscito dall'acqua
		seen_guardian = true
		# caduto il guardiano le statue si spengono, anche a metà di una vampata. Prima, se il
		# Serpente spariva (liberato) invece di restare "morto", la lingua di fuoco restava
		# disegnata a schermo per sempre.
		if gone or guardian.dead:
			phase = "idle"
			current = -1
			queue_redraw()
			set_physics_process(false)
			return
		t += delta
		match phase:
			"idle":
				if t >= wait:
					current = randi() % statues.size()
					if current == last:
						current = (current + 1) % statues.size()
					last = current
					reach = _reach(current)
					phase = "warn"
					t = 0.0
					Sfx.play_at("fire_ignite", statues[current][0], 0.1)
			"warn":
				if t >= WARN:
					phase = "fire"
					t = 0.0
					hit_player = false
					hit_enemies.clear()
					Sfx.play_at("fire_whoosh", statues[current][0], 0.1)
					Fx.shake(2.0)
			"fire":
				_burn(guardian)
				if t >= FIRE:
					phase = "idle"
					t = 0.0
					# il Serpente infuriato (sotto metà vita) fa sputare le statue più spesso
					var angry: bool = guardian.hp < guardian.max_hp * 0.5
					wait = randf_range(1.6, 2.2) if angry else randf_range(2.3, 3.0)
		queue_redraw()

	## La lingua di fuoco si ferma contro la parete opposta o la prima colonna sulla sua strada.
	## Le colonne sono alte: contano anche un po' sopra la base.
	func _reach(i: int) -> Vector2:
		var m: Vector2 = statues[i][0]
		var d: Vector2 = statues[i][1]
		if d.y != 0.0:
			var end_y := room.size.y - wall
			for p in pillars:
				if absf(p.x - m.x) < 13.0 + BAND and p.y > m.y and p.y - 58.0 < end_y:
					end_y = maxf(m.y + 20.0, p.y - 58.0)
			return Vector2(m.x, end_y)
		var end_x := room.size.x - wall if d.x > 0.0 else wall
		for p in pillars:
			if m.y > p.y - 58.0 and m.y < p.y + 7.0 + BAND:
				if d.x > 0.0 and p.x > m.x and p.x - 13.0 < end_x:
					end_x = p.x - 13.0
				elif d.x < 0.0 and p.x < m.x and p.x + 13.0 > end_x:
					end_x = p.x + 13.0
		return Vector2(end_x, m.y)

	func _in_band(p: Vector2, extra: float) -> bool:
		var r := danger()
		return r.size != Vector2.ZERO and r.grow(extra).has_point(p)

	func _burn(guardian: Node) -> void:
		var player = get_tree().get_first_node_in_group("player")
		if not hit_player and player != null and not player.dead and _in_band(player.global_position, 2.0):
			if player.take_damage(9.0, statues[current][0], null, "ureo"):
				hit_player = true
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.dead or hit_enemies.has(e):
				continue
			if e == guardian and ("state" in e) and (e.state == "under" or e.state == "warn" or e.state == "dive"):
				continue                  # sottoterra il fuoco non lo raggiunge
			if _in_band(e.global_position, e.radius * 0.6):
				hit_enemies[e] = true
				e.take_hit(26.0 if e == guardian else 14.0, statues[current][1], 40.0, true)
				Fx.float_text(e.global_position + Vector2(0, -22), Lang.t("Ureo!"), Color(1, 0.6, 0.2))

	func _draw() -> void:
		for i in range(statues.size()):
			_draw_statue(statues[i][0], statues[i][1], i == current and phase != "idle")
		if current < 0:
			return
		var m: Vector2 = statues[current][0]
		var d: Vector2 = statues[current][1]
		var start := m + d * 8.0
		var end := reach
		var side := d.orthogonal()
		if phase == "warn":
			# l'avviso: braci sul pavimento lungo la striscia, sempre più fitte
			var k := t / WARN
			var length := start.distance_to(end)
			var dist := 0.0
			while dist < length:
				var at := start + d * dist
				var a := 0.15 + 0.5 * k * (0.6 + 0.4 * sin(dist * 0.7 + t * 18.0))
				draw_circle(at + Vector2(0, 4.0 if d.y == 0.0 else 0.0), 1.6 + k * 1.4, Color(1.0, 0.45, 0.1, a))
				dist += 14.0
			draw_line(start + side * BAND, end + side * BAND, Color(1, 0.4, 0.1, 0.25 * k), 1.0)
			draw_line(start - side * BAND, end - side * BAND, Color(1, 0.4, 0.1, 0.25 * k), 1.0)
		elif phase == "fire":
			var fade := 1.0 - maxf(0.0, (t - FIRE * 0.6) / (FIRE * 0.4))
			var flick := 0.85 + 0.15 * sin(t * 60.0)
			draw_line(start, end, Color(1.0, 0.35, 0.05, 0.55 * fade), BAND * 2.0 * flick)
			draw_line(start, end, Color(1.0, 0.7, 0.2, 0.75 * fade), BAND * 1.2 * flick)
			draw_line(start, end, Color(1.0, 0.95, 0.7, 0.85 * fade), BAND * 0.45)
			draw_circle(end, BAND * 1.1 * flick, Color(1.0, 0.55, 0.15, 0.5 * fade))

	## Una testa di cobra di pietra con il cappuccio dipinto, sporgente dalla parete verso `d`.
	func _draw_statue(m: Vector2, d: Vector2, lit: bool) -> void:
		var stone := Color(0.62, 0.52, 0.36)
		var side := d.orthogonal()
		var base := m - d * 4.0
		# lo zoccolo nella parete
		var b0 := base - side * 5.0 - d * 6.0
		draw_colored_polygon(PackedVector2Array([b0, b0 + side * 10.0, b0 + side * 10.0 + d * 8.0, b0 + d * 8.0]), stone.darkened(0.35))
		# il cappuccio, aperto ai lati della testa
		var hood := PackedVector2Array([base - d * 4.0 - side * 3.0, base + d * 2.0 - side * 7.0, base + d * 8.0 - side * 4.0, base + d * 8.0 + side * 4.0, base + d * 2.0 + side * 7.0, base - d * 4.0 + side * 3.0])
		draw_colored_polygon(hood, Color(0.18, 0.5, 0.48))
		draw_polyline(hood + PackedVector2Array([hood[0]]), Color(0.9, 0.7, 0.3), 1.0)
		# la testa con la bocca
		var head := base + d * 9.0
		draw_circle(head, 3.2, stone)
		var eye := Color(1.0, 0.25, 0.1) if lit else Color(0.2, 0.12, 0.08)
		draw_circle(head - d * 1.0 + side * 1.6, 1.0, eye)
		draw_circle(head - d * 1.0 - side * 1.6, 1.0, eye)
		if lit:
			draw_circle(head + d * 3.0, 4.0 + 2.0 * sin(t * 20.0), Color(1, 0.5, 0.15, 0.35))



## Pozza di veleno del Serpente della Porta: resta dove cade uno sputo, per qualche secondo.
## Chi ci passa sopra (senza scattare) viene avvelenato, come dagli scorpioni.
class VenomPuddle extends Node2D:
	var life := 3.0
	var t := 0.0
	var r := 14.0
	var cool := 0.0

	func _ready() -> void:
		# nell'acqua alta della Porta il veleno si scioglie: niente pozza
		if Run.in_deep(global_position):
			Fx.burst(global_position, Color(0.55, 0.95, 0.3, 0.6), 6, 40.0)
			queue_free()
			return
		Sfx.play_at("orb_pop", global_position, 0.2)
		_under.call_deferred()

	## Sopra il pavimento, sotto l'eroe e i nemici (z_index negativo finiva sotto il pavimento).
	func _under() -> void:
		var par := get_parent()
		if par == null:
			return
		for i in range(par.get_child_count()):
			if par.get_child(i).has_method("rebake"):          # l'arredamento con il pavimento
				par.move_child(self, i + 1)
				return

	func _process(delta: float) -> void:
		t += delta
		cool = maxf(0.0, cool - delta)
		if t >= life:
			queue_free()
			return
		var p = get_tree().get_first_node_in_group("player")
		if p != null and not p.dead and cool <= 0.0 and p.dash_t <= 0.0:
			var d: Vector2 = (p.global_position - global_position) / Vector2(r, r * 0.55)
			if d.length() < 1.0:
				p.poison(2.0)
				cool = 0.5
				Run.last_hit = "serpent"
		queue_redraw()

	func _draw() -> void:
		var a := clampf(t / 0.15, 0.0, 1.0) * clampf((life - t) / 0.6, 0.0, 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, r + 2.5, Color(0.25, 0.08, 0.3, 0.6 * a))          # bordo viola: è veleno
		draw_circle(Vector2.ZERO, r, Color(0.55, 0.95, 0.15, 0.65 * a))
		draw_circle(Vector2(-3, -3), r * 0.4, Color(0.7, 1.0, 0.5, 0.35 * a))
		for i in range(3):
			var bp := Vector2(sin(i * 2.1 + t * 2.0), cos(i * 1.3 + t * 2.5)) * r * 0.5
			draw_circle(bp, 1.2 + absf(sin(t * 6.0 + i)), Color(0.8, 1.0, 0.6, 0.6 * a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Pioggia di veleno (Peso del Cuore, l'ira del Serpente): un cerchio d'avviso, poi la goccia
## cade e lascia la pozza. Ferisce chi è sotto quando cade.
class VenomDrop extends Node2D:
	var delay := 0.0
	var warn := 0.85
	var damage := 8.0
	var t := 0.0
	var src: Node = null

	func _process(delta: float) -> void:
		t += delta
		if t < delay:
			return
		if t >= delay + warn:
			var p = get_tree().get_first_node_in_group("player")
			if p != null and not p.dead and p.global_position.distance_to(global_position) < 16.0:
				p.take_damage(damage, global_position, src if is_instance_valid(src) else null)
			Fx.burst(global_position, Color(0.4, 1.0, 0.35), 10, 70.0)
			var pud := Hazards.VenomPuddle.new()
			pud.position = position                 # prima di entrare in scena: _ready guarda dov'è (acqua alta)
			get_parent().add_child(pud)
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		if t < delay:
			return
		var k := clampf((t - delay) / warn, 0.0, 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.55))
		draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 24, Color(0.5, 1.0, 0.4, 0.8), 1.5)
		draw_circle(Vector2.ZERO, 16.0 * k, Color(0.4, 0.9, 0.3, 0.25))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# la goccia che scende dall'alto
		var y := -120.0 * (1.0 - k)
		draw_circle(Vector2(0, y), 3.5, Color(0.35, 0.85, 0.25, k))


## Anello di fuoco (Peso del Cuore, l'ira di Am-heh): si allarga da lui con un solo varco.
## Lo si passa nel varco, o attraversandolo con lo scatto.
class FireRing extends Node2D:
	var gap_dir := Vector2.RIGHT
	var gap := deg_to_rad(55.0)
	var max_r := 300.0
	var dur := 1.7
	var damage := 10.0
	var t := 0.0
	var hit := false

	func _ready() -> void:
		z_index = 1
		Sfx.play("fire_whoosh", 0.05)

	func radius() -> float:
		return 18.0 + (max_r - 18.0) * clampf(t / dur, 0.0, 1.0)

	func _process(delta: float) -> void:
		t += delta
		if t >= dur:
			queue_free()
			return
		var p = get_tree().get_first_node_in_group("player")
		if p != null and not p.dead and not hit:
			var to: Vector2 = p.global_position - global_position
			var ell := Vector2(to.x, to.y / 0.6)
			if absf(ell.length() - radius()) < 9.0 and absf(gap_dir.angle_to(ell)) > gap * 0.5:
				if p.take_damage(damage, global_position, null, "amheh_fuoco"):
					hit = true
		queue_redraw()

	func _draw() -> void:
		var r := radius()
		var a := clampf((dur - t) / 0.4, 0.0, 1.0)
		var start := gap_dir.angle() + gap * 0.5
		var span := TAU - gap
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.6))
		draw_arc(Vector2.ZERO, r, start, start + span, 72, Color(1.0, 0.45, 0.1, 0.35 * a), 14.0)
		draw_arc(Vector2.ZERO, r, start, start + span, 72, Color(1.0, 0.8, 0.3, 0.9 * a), 4.0)
		for i in range(18):
			var ang := start + span * (i + 0.5) / 18.0 + sin(t * 9.0 + i) * 0.02
			var fp := Vector2.from_angle(ang) * r
			draw_circle(fp + Vector2(0, -4 - 3 * absf(sin(t * 12.0 + i))), 3.0, Color(1.0, 0.7, 0.2, 0.8 * a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
