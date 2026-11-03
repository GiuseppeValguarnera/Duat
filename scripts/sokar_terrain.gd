class_name SokarTerrain
extends RefCounted
## Il terreno e le trappole del deserto di Sokar (la quarta ora).
##  - Fiume di sabbia nera: una fascia scura con striature che scorrono. Trascina giocatore e nemici
##    e ferisce poco alla volta (2 danni ogni 0,5 s). Si attraversa con lo scatto o sulle lastre di
##    pietra. Diverso dalle sabbie mobili (chiare, ferme, rallentano soltanto).
##  - Lastra che crolla: calpestata si crepa per 1 s, poi diventa una buca per qualche secondo; chi ci
##    cade si fa male e riappare sul bordo. Vale anche per i nemici.
##  - Statua-falco di Sokar: sul muro, soffia sabbia in linea a intervalli regolari, con la linea
##    d'avviso prima del soffio.
## La disposizione (schemi, attraversamenti, regole) è in room_builder.gd, `_place_sokar`.

const RIVER_DMG := 2.0
const RIVER_TICK := 0.5
const RIVER_DRAG := 55.0
const RIVER_AGAINST := 0.6     ## chi cammina contro corrente è trascinato fino al 60% in meno (esce sempre)
const RIM := Color(0.86, 0.68, 0.42)   ## il bordo chiaro del fiume: si vede sopra la sabbia e sopra il nero
const SAND_DARK := Color(0.17, 0.12, 0.11)
const SAND_DARK2 := Color(0.26, 0.19, 0.16)
const STONE := Color(0.62, 0.56, 0.48)
const OUTL := Color(0.1, 0.07, 0.05)


## Chi sta sul terreno (non chi vola: avvoltoi e simili hanno collision_mask 0) e non è un boss.
static func grounded(n: Node) -> bool:
	if not (n is CharacterBody2D):
		return false
	if n.collision_mask == 0:
		return false
	if "is_boss" in n and (n.is_boss or n.miniboss):
		return false
	return true


class SandRiver extends Node2D:
	var rect := Rect2()                 ## in coordinate della stanza
	var flow := Vector2.RIGHT           ## verso dove scorre
	var plates: Array = []              ## Rect2 delle lastre di pietra (attraversamenti)
	var t := 0.0
	var _ticks := {}                    ## corpo -> secondi al prossimo danno

	func _ready() -> void:
		add_to_group("river")
		z_index = 0

	func on_plate(p: Vector2) -> bool:
		for r in plates:
			if (r as Rect2).grow(2.0).has_point(p):
				return true
		return false

	func contains(p: Vector2) -> bool:
		return rect.has_point(p) and not on_plate(p)

	func _physics_process(delta: float) -> void:
		t += delta
		var bodies: Array = get_tree().get_nodes_in_group("enemies")
		var pl = get_tree().get_first_node_in_group("player")
		if pl != null:
			bodies.append(pl)
		for b in bodies:
			if not is_instance_valid(b) or b.dead or not SokarTerrain.grounded(b):
				continue
			if not contains(b.global_position):
				_ticks.erase(b)
				continue
			if b == pl and b.dash_t > 0.0:
				# lo scatto supera il fiume, e all'arrivo non scatta subito un tick
				_ticks[b] = maxf(float(_ticks.get(b, 0.0)), SokarTerrain.RIVER_TICK * 0.5)
				continue
			var drag := SokarTerrain.RIVER_DRAG
			if b == pl and b.velocity.length() > 5.0:
				# contro corrente il trascinamento cala: chi spinge per uscire esce
				drag *= 1.0 - SokarTerrain.RIVER_AGAINST * clampf(-b.velocity.normalized().dot(flow), 0.0, 1.0)
			b.move_and_collide(flow * drag * delta)
			var left: float = _ticks.get(b, SokarTerrain.RIVER_TICK * 0.5) - delta
			if left <= 0.0:
				left = SokarTerrain.RIVER_TICK
				if b == pl:
					# poco danno, ma senza l'invulnerabilità di un colpo vero
					if b.take_damage(SokarTerrain.RIVER_DMG, b.global_position, null, "fiume"):
						b.invuln_t = 0.0
				else:
					b.take_hit(SokarTerrain.RIVER_DMG, flow, 0.0)
			_ticks[b] = left
		queue_redraw()

	func _draw() -> void:
		# la sabbia nera, con il bordo più scuro e le striature che corrono nel verso del fiume
		draw_rect(rect.grow(3.0), SokarTerrain.OUTL)
		draw_rect(rect, SokarTerrain.SAND_DARK)
		# il bordo chiaro che pulsa piano: dove comincia il fiume si legge anche sul telefono
		var rim_a := 0.55 + 0.25 * sin(t * 3.0)
		draw_rect(rect.grow(1.0), Color(SokarTerrain.RIM, rim_a), false, 1.5)
		draw_rect(rect.grow(-2.5), Color(SokarTerrain.SAND_DARK2.lightened(0.15), 0.8), false, 1.0)
		var along := flow.abs()
		var length := rect.size.x if along.x > 0.5 else rect.size.y
		var across := rect.size.y if along.x > 0.5 else rect.size.x
		var rng := RandomNumberGenerator.new()
		rng.seed = int(rect.position.x * 7.0 + rect.position.y)
		for i in range(int(across / 5.0)):
			var off := rng.randf_range(2.0, across - 2.0)
			var seg := rng.randf_range(10.0, 26.0)
			var sp := rng.randf_range(0.7, 1.3) * 40.0
			var base := fposmod(rng.randf() * length + t * sp, length + seg) - seg
			var a := clampf(base, 0.0, length)
			var b := clampf(base + seg, 0.0, length)
			if b - a < 2.0:
				continue
			var forward := flow.x > 0.0 or flow.y > 0.0
			if not forward:
				a = length - a
				b = length - b
			var p0: Vector2
			var p1: Vector2
			if along.x > 0.5:
				p0 = rect.position + Vector2(a, off)
				p1 = rect.position + Vector2(b, off)
			else:
				p0 = rect.position + Vector2(off, a)
				p1 = rect.position + Vector2(off, b)
			draw_line(p0, p1, Color(SokarTerrain.SAND_DARK2, 0.9), 1.3)
		# piccole frecce di sabbia chiara: il verso della corrente si legge a colpo d'occhio
		for k in range(int(length / 70.0)):
			var u := fposmod(k * 70.0 + t * 30.0 * (1.0 if (flow.x > 0.0 or flow.y > 0.0) else -1.0), length)
			var c := rect.position + (Vector2(u, across / 2.0) if along.x > 0.5 else Vector2(across / 2.0, u))
			var side := flow.orthogonal() * 3.0
			draw_polyline(PackedVector2Array([c - flow * 4.0 + side, c, c - flow * 4.0 - side]), Color(0.55, 0.42, 0.3, 0.6), 1.2)
		# le lastre di pietra
		for r in plates:
			var pr := r as Rect2
			draw_rect(pr.grow(1.5), SokarTerrain.OUTL)
			draw_rect(pr, SokarTerrain.STONE)
			draw_rect(Rect2(pr.position, Vector2(pr.size.x, 2.0)), SokarTerrain.STONE.lightened(0.2))
			draw_line(pr.position + pr.size * Vector2(0.5, 0.0), pr.position + pr.size * Vector2(0.5, 1.0), SokarTerrain.STONE.darkened(0.25), 1.0)


class CrumbleTile extends Node2D:
	const SIZE := 28.0
	const CRACK := 1.0
	const HOLE := 5.0
	var state := "idle"                 ## idle → crack → hole → idle
	var st := 0.0
	var t := 0.0
	var player_damage := 8.0
	var enemy_damage := 12.0

	func _ready() -> void:
		add_to_group("traps")

	func _inside(p: Vector2, grow: float = 0.0) -> bool:
		var h := SIZE / 2.0 + grow
		return absf(p.x - global_position.x) < h and absf(p.y - global_position.y) < h

	func _physics_process(delta: float) -> void:
		t += delta
		st -= delta
		var bodies: Array = get_tree().get_nodes_in_group("enemies")
		var pl = get_tree().get_first_node_in_group("player")
		if pl != null:
			bodies.append(pl)
		match state:
			"idle":
				for b in bodies:
					if is_instance_valid(b) and not b.dead and SokarTerrain.grounded(b) and _inside(b.global_position):
						state = "crack"
						st = CRACK
						Sfx.play_at("spikes", global_position, 0.1)
						break
			"crack":
				if st <= 0.0:
					state = "hole"
					st = HOLE
					Fx.burst(global_position, Color(0.7, 0.55, 0.35), 18, 70.0)
					Fx.shake(2.0)
			"hole":
				for b in bodies:
					if not is_instance_valid(b) or b.dead or not SokarTerrain.grounded(b) or not _inside(b.global_position, -2.0):
						continue
					if b == pl and b.dash_t > 0.0:
						continue
					_fall(b, b == pl)
				if st <= 0.0:
					state = "idle"
		queue_redraw()

	## Chi cade nella buca si fa male e riappare sul bordo più vicino.
	func _fall(b: Node2D, is_player: bool) -> void:
		var out := b.global_position - global_position
		if out.length() < 1.0:
			out = Vector2.DOWN
		var edge := global_position + out.normalized() * (SIZE * 0.5 + 12.0)
		Fx.burst(b.global_position, Color(0.6, 0.45, 0.3), 12, 60.0)
		if is_player:
			b.take_damage(player_damage, global_position, null, "buca")
		else:
			b.take_hit(enemy_damage, out.normalized(), 0.0)
		if is_instance_valid(b):
			b.global_position = edge
			b.reset_physics_interpolation()

	func _draw() -> void:
		var h := SIZE / 2.0
		if state == "hole":
			draw_rect(Rect2(-h - 1, -h - 1, SIZE + 2, SIZE + 2), SokarTerrain.OUTL)
			draw_rect(Rect2(-h, -h, SIZE, SIZE), Color(0.05, 0.04, 0.04))
			draw_rect(Rect2(-h, -h, SIZE, 5.0), Color(0.22, 0.16, 0.11))
			for i in range(4):
				var a := t * 2.0 + i * 1.6
				draw_circle(Vector2(cos(a) * 6.0, sin(a) * 4.0 + 2.0), 1.0, Color(0.6, 0.45, 0.3, 0.6))
			return
		var stone := Color(0.66, 0.55, 0.4)
		draw_rect(Rect2(-h - 1, -h - 1, SIZE + 2, SIZE + 2), SokarTerrain.OUTL)
		draw_rect(Rect2(-h, -h, SIZE, SIZE), stone)
		draw_rect(Rect2(-h, -h, SIZE, 2.0), stone.lightened(0.15))
		# sempre una crepa sottile (si impara a riconoscerle); quando si crepa, si allarga e trema
		var k := 0.0 if state == "idle" else 1.0 - st / CRACK
		var shake := Vector2(sin(t * 60.0), cos(t * 53.0)) * (1.2 * k)
		var col := Color(0.25, 0.17, 0.1) if state == "idle" else Color(0.12, 0.06, 0.03)
		var w := 1.0 + 2.0 * k
		var pts := [Vector2(-h + 3, -2), Vector2(-4, 1), Vector2(1, -5), Vector2(6, 2), Vector2(h - 3, 0)]
		for i in range(pts.size() - 1):
			draw_line(pts[i] + shake, pts[i + 1] + shake, col, w)
		if k > 0.0:
			draw_line(Vector2(-4, 1) + shake, Vector2(-7, h - 3) + shake, col, w * 0.8)
			draw_line(Vector2(1, -5) + shake, Vector2(3, -h + 3) + shake, col, w * 0.8)
			draw_line(Vector2(6, 2) + shake, Vector2(9, h - 4) + shake, col, w * 0.8)
			draw_rect(Rect2(-h, -h, SIZE, SIZE), Color(1.0, 0.5, 0.2, 0.15 + 0.15 * sin(t * 25.0)))


class FalconStatue extends Node2D:
	var dir := Vector2.RIGHT            ## verso dove soffia (dal muro verso la stanza)
	var length := 600.0                 ## fin dove arriva il soffio (fino al muro opposto)
	var every := 4.5
	var warn := 1.0
	var blow := 0.45
	var t := 0.0
	var width := 18.0
	var player_damage := 8.0
	var enemy_damage := 10.0
	var push := 140.0
	var _hit := {}

	func _ready() -> void:
		add_to_group("traps")
		z_index = 2

	func phase() -> String:
		if t < every - warn - blow:
			return "idle"
		if t < every - blow:
			return "warn"
		return "blow"

	func _physics_process(delta: float) -> void:
		var was := phase()
		t = fmod(t + delta, every)
		var now := phase()
		if now == "blow" and was != "blow":
			_hit.clear()
			Sfx.play_at("fire_whoosh", global_position, 0.2)
		if now == "blow":
			_strike(delta)
		queue_redraw()

	func _in_line(p: Vector2) -> bool:
		var rel := p - global_position
		var a := rel.dot(dir)
		var o := absf(rel.dot(dir.orthogonal()))
		return a > 8.0 and a < length and o < width * 0.5          # blocco 12: esattamente la striscia dell'avviso

	func _strike(delta: float) -> void:
		var pl = get_tree().get_first_node_in_group("player")
		if pl != null and not pl.dead and _in_line(pl.global_position) and pl.dash_t <= 0.0:
			pl.move_and_collide(dir * push * delta)
			if not _hit.has(pl) and pl.take_damage(player_damage, global_position, null, "falco"):
				_hit[pl] = true
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.dead or not SokarTerrain.grounded(e) or not _in_line(e.global_position):
				continue
			e.move_and_collide(dir * push * delta)
			if not _hit.has(e):
				_hit[e] = true
				e.take_hit(enemy_damage, dir, 40.0)

	func _draw() -> void:
		var p := phase()
		var side := dir.orthogonal()
		if p == "warn":
			# la linea d'avviso: sabbia che comincia a correre lungo la riga, e i bordi rossi
			var k := (t - (every - warn - blow)) / warn
			Enemy.warn_strip(self, dir * 8.0, dir, length - 8.0, width * 0.5, k)
		elif p == "blow":
			var rng := RandomNumberGenerator.new()
			rng.seed = 5
			draw_colored_polygon(PackedVector2Array([dir * 8.0 + side * width * 0.5, dir * length + side * width * 0.5, dir * length - side * width * 0.5, dir * 8.0 - side * width * 0.5]), Color(0.85, 0.7, 0.45, 0.45))
			for i in range(18):
				var u := fposmod(rng.randf() * length + t * 700.0, length)
				var o := rng.randf_range(-width * 0.45, width * 0.45)
				draw_line(dir * u + side * o, dir * (u - 22.0) + side * o, Color(0.95, 0.85, 0.6, 0.8), 1.2)
		# la statua: testa di falco scolpita nel muro, con il disco del sole; il becco verso la stanza
		var out := Color(0.12, 0.08, 0.05)
		draw_circle(Vector2.ZERO, 9.5, out)
		draw_circle(Vector2.ZERO, 8.5, Color(0.6, 0.52, 0.42))
		draw_colored_polygon(PackedVector2Array([dir * 6.0 + side * 3.0, dir * 14.0, dir * 6.0 - side * 3.0]), out)
		draw_colored_polygon(PackedVector2Array([dir * 6.5 + side * 2.2, dir * 12.5, dir * 6.5 - side * 2.2]), Color(0.85, 0.64, 0.26))
		var eye := Color(1.0, 0.35, 0.2, 0.6 + 0.4 * sin(t * 25.0)) if p == "warn" else Color(0.2, 0.36, 0.8)
		draw_circle(dir * 2.0 + side * 3.0, 1.6, eye)
		draw_circle(-dir * 8.0, 4.0, Color(0.94, 0.72, 0.3))
