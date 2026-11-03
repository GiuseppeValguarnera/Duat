class_name AkerArena
extends RefCounted
## L'arena di Aker, la porta dell'orizzonte (blocco 11): le parti vive.
##  - Stele dell'orizzonte: quattro, al posto delle rocce negli angoli. Fermano il raggio dell'alba
##    e i colpi, ma si spezzano: dopo STELE_PASSES passaggi del raggio o con una carica di Ieri.
##    Spezzate non tornano.
##  - Crepe di fuoco (metà est, il terreno spaccato dell'alba): eruttano ogni CRACK_EVERY secondi,
##    con CRACK_WARN secondi di avviso.
##  - Le due porte (Gates): evocano i servitori di Aker. Fase 1 (Aker intero): ogni porta uno ogni
##    PHASE1_EVERY s, al massimo PHASE1_MAX vivi in tutto. Fase 2: ogni PHASE2_EVERY s, al massimo
##    PHASE2_MAX; Ieri ha la porta del tramonto (ovest, Ombre di Sabbia), Domani quella dell'alba (est,
##    Scintille). Quando un leone cade la sua porta crolla e non evoca più.
## Le sabbie mobili fisse della metà ovest sono Hazards.Quicksand (game.gd, _build_arena).

const STELE_PASSES := 3
const STELE_R := 9.0
const CRACK_EVERY := 6.0
const CRACK_WARN := 1.0
const CRACK_BURN := 0.4
const CRACK_DAMAGE := 12.0
const CRACK_WIDTH := 12.0                ## mezza larghezza della fiammata
const PHASE1_EVERY := 10.0
const PHASE1_MAX := 2
const PHASE2_EVERY := 7.0
const PHASE2_MAX := 3
const GATE_FIRST := [3.0, 8.0]          ## il primo servitore di ogni porta (ovest, est): sfalsati
const SPAWN_DELAY := 0.8                ## il cerchio d'avviso dove compare (SpawnMarker)


## Una stele dell'orizzonte: pietra scritta con il sole tra due montagne.
class Stele extends StaticBody2D:
	var passes := 0
	var broken := false
	var fall := -1.0
	var shake := 0.0

	func _ready() -> void:
		collision_layer = 1                # come un muro: blocca te, i nemici, le frecce e il raggio
		collision_mask = 0
		z_index = 1
		var shape := CollisionShape2D.new()
		var c := RectangleShape2D.new()
		c.size = Vector2(AkerArena.STELE_R * 2.0, 10.0)
		shape.shape = c
		add_child(shape)
		add_to_group("aker_stones")
		add_to_group("horizon_stele")

	## Il raggio dell'alba ci si è fermato contro (una volta per raggio, hazards.gd DawnRay).
	func ray_pass() -> void:
		passes += 1
		shake = 0.3
		Fx.burst(global_position + Vector2(0, -14), Color(0.75, 0.62, 0.45), 6, 50.0)
		if passes >= AkerArena.STELE_PASSES:
			smash()

	## Spezzata (dal raggio o dalla carica di Ieri): crolla e non torna.
	func smash() -> void:
		if broken:
			return
		broken = true
		fall = 0.0
		collision_layer = 0
		remove_from_group("aker_stones")
		Fx.burst(global_position + Vector2(0, -16), Color(0.7, 0.58, 0.42), 22, 120.0)
		Fx.shake(3.0)
		Sfx.play_at("amheh_land", global_position, 0.2)
		Fx.float_text(global_position + Vector2(0, -36), Lang.t("La stele si spezza"), Color(0.95, 0.85, 0.65))

	func ray_hit(a: Vector2, b: Vector2) -> float:
		if broken:
			return -1.0
		var c := global_position + Vector2(0, -8)
		var d := b - a
		var f := a - c
		var r := AkerArena.STELE_R + 2.0
		var aa := d.dot(d)
		var bb := 2.0 * f.dot(d)
		var cc := f.dot(f) - r * r
		var disc := bb * bb - 4.0 * aa * cc
		if disc < 0.0 or aa < 0.001:
			return -1.0
		var k := (-bb - sqrt(disc)) / (2.0 * aa)
		return k if k >= 0.0 and k <= 1.0 else -1.0

	func _process(delta: float) -> void:
		shake = maxf(0.0, shake - delta)
		if fall >= 0.0:
			fall += delta
		if fall >= 0.0 or shake > 0.0:
			queue_redraw()

	func _draw() -> void:
		var stone := Color(0.62, 0.54, 0.42)
		var dark := Color(0.16, 0.11, 0.07)
		draw_set_transform(Vector2(3, 2), 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, AkerArena.STELE_R + 3.0, Color(0, 0, 0, 0.3))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if broken:
			# i pezzi a terra
			for i in range(5):
				var p := Vector2(-8.0 + i * 4.0, -2.0 + sin(i * 2.3) * 2.0)
				draw_circle(p, 3.0 - (i % 2), stone.darkened(0.15 * (i % 3)))
			if fall < 0.6:
				var k := fall / 0.6
				draw_circle(Vector2(0, -12.0 + k * 10.0), 9.0 * (1.0 - k), Color(0.7, 0.6, 0.45, 1.0 - k))
			return
		var sx := sin(shake * 60.0) * 1.5 if shake > 0.0 else 0.0
		var r := Rect2(-AkerArena.STELE_R + sx, -30.0, AkerArena.STELE_R * 2.0, 30.0)
		draw_rect(r.grow(1.2), dark)
		draw_rect(r, stone)
		# la cima arrotondata e il geroglifico akhet inciso
		draw_circle(Vector2(sx, -30.0), AkerArena.STELE_R, stone)
		draw_arc(Vector2(sx, -30.0), AkerArena.STELE_R + 0.6, PI, TAU, 12, dark, 1.2)
		draw_arc(Vector2(sx - 3.5, -18.0), 3.5, PI, TAU, 8, dark, 1.0)
		draw_arc(Vector2(sx + 3.5, -18.0), 3.5, PI, TAU, 8, dark, 1.0)
		draw_circle(Vector2(sx, -21.0), 2.0, Color(0.85, 0.45, 0.2))
		# le crepe dei passaggi del raggio
		for i in range(passes):
			draw_line(Vector2(sx - 6.0 + i * 5.0, -28.0), Vector2(sx - 3.0 + i * 4.0, -8.0), dark, 1.0)


## Una crepa di fuoco nel terreno spaccato dell'est: brace sottile, poi l'avviso, poi la fiammata.
class FireCrack extends Node2D:
	var length := 90.0
	var dir := Vector2.RIGHT
	var t := 0.0
	var _hit := false
	var pts := PackedVector2Array()

	func _ready() -> void:
		z_index = 0
		var rng := RandomNumberGenerator.new()
		rng.seed = int(global_position.x * 13.0 + global_position.y)
		for i in range(8):
			var u := float(i) / 7.0
			pts.append(dir * (u - 0.5) * length + dir.orthogonal() * rng.randf_range(-4.0, 4.0))

	func phase() -> String:
		var c := fmod(t, AkerArena.CRACK_EVERY)
		if c < AkerArena.CRACK_EVERY - AkerArena.CRACK_WARN - AkerArena.CRACK_BURN:
			return "idle"
		if c < AkerArena.CRACK_EVERY - AkerArena.CRACK_BURN:
			return "warn"
		return "burn"

	func _physics_process(delta: float) -> void:
		var was := phase()
		t += delta
		var now := phase()
		if now == "warn" and was == "idle":
			_hit = false
			Sfx.play_at("fire_ignite", global_position, 0.2)
		if now == "burn":
			if was != "burn":
				Sfx.play_at("fire_whoosh", global_position, 0.2)
				Fx.shake(2.0)
			if not _hit:
				var p = get_tree().get_first_node_in_group("player")
				if p != null and not p.dead and _near(p.global_position):
					if p.take_damage(AkerArena.CRACK_DAMAGE, global_position, null, "aker_crepa"):
						_hit = true
		queue_redraw()

	func _near(p: Vector2) -> bool:
		var a := global_position - dir * length * 0.5
		var b := global_position + dir * length * 0.5
		return Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p) < AkerArena.CRACK_WIDTH

	func _draw() -> void:
		var ph := phase()
		var c := fmod(t, AkerArena.CRACK_EVERY)
		draw_polyline(pts, Color(0.1, 0.05, 0.03), 4.0)
		var glow := 0.35 + 0.1 * sin(t * 3.0)
		if ph == "warn":
			var k := (c - (AkerArena.CRACK_EVERY - AkerArena.CRACK_WARN - AkerArena.CRACK_BURN)) / AkerArena.CRACK_WARN
			glow = 0.5 + 0.5 * k
			# l'avviso: la fascia che brucerà, rossa
			var side := dir.orthogonal() * AkerArena.CRACK_WIDTH
			var a := -dir * length * 0.5
			var b := dir * length * 0.5
			draw_colored_polygon(PackedVector2Array([a + side, b + side, b - side, a - side]), Color(1.0, 0.2, 0.1, 0.12 + 0.2 * k))
		draw_polyline(pts, Color(1.0, 0.45, 0.12, glow), 1.6)
		if ph == "burn":
			for i in range(pts.size()):
				var h := 10.0 + 6.0 * sin(t * 30.0 + i)
				var p: Vector2 = pts[i]
				draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 0), p + Vector2(4, 0), p + Vector2(sin(t * 20.0 + i) * 2.0, -h)]), Color(1.0, 0.55, 0.1, 0.9))
				draw_colored_polygon(PackedVector2Array([p + Vector2(-2, 0), p + Vector2(2, 0), p + Vector2(0, -h * 0.55)]), Color(1.0, 0.9, 0.4, 0.9))


## Le due porte dell'arena: evocano i servitori e, quando il loro leone cade, crollano.
class Gates extends Node2D:
	var game: Node = null
	var west := Vector2.ZERO               ## dove escono (appena dentro la porta)
	var east := Vector2.ZERO
	var up := [true, true]                 ## ovest, est
	var fall := [-1.0, -1.0]
	var timer := [0.0, 0.0]
	var had_lions := false
	var pending := 0.0                     ## servitori annunciati ma non ancora usciti (stima)
	var t := 0.0

	func _ready() -> void:
		z_index = 1
		timer = AkerArena.GATE_FIRST.duplicate()

	func _physics_process(delta: float) -> void:
		t += delta
		pending = maxf(0.0, pending - delta / AkerArena.SPAWN_DELAY)
		for i in range(2):
			if fall[i] >= 0.0:
				fall[i] += delta
		if game == null:
			return
		var aker = null
		var lions := {}
		for b in game.boss_group:
			if b == null or not is_instance_valid(b) or b.dead:
				continue
			if "split_done" in b:
				if not b.split_done:
					aker = b
			elif "kind" in b:
				lions[b.kind] = b
		if not lions.is_empty():
			had_lions = true
		if had_lions:
			if not lions.has("ieri") and up[0]:
				_collapse(0)
			if not lions.has("domani") and up[1]:
				_collapse(1)
		var phase2 := aker == null and not lions.is_empty()
		if aker == null and not phase2:
			return
		if aker != null and String(aker.state) in ["intro", "tremble"]:
			return
		var every := AkerArena.PHASE2_EVERY if phase2 else AkerArena.PHASE1_EVERY
		var cap := AkerArena.PHASE2_MAX if phase2 else AkerArena.PHASE1_MAX
		for i in range(2):
			if not up[i]:
				continue
			timer[i] -= delta
			if timer[i] > 0.0:
				continue
			timer[i] = every
			if _servants() + int(ceil(pending)) >= cap:
				continue
			pending += 1.0
			var kind := "aker_shade" if i == 0 else "aker_spark"
			game._on_boss_summon([[kind, west if i == 0 else east]])
		queue_redraw()

	func _servants() -> int:
		var n := 0
		for e in get_tree().get_nodes_in_group("aker_servants"):
			if not e.dead:
				n += 1
		return n

	func _collapse(i: int) -> void:
		up[i] = false
		fall[i] = 0.0
		var at: Vector2 = west if i == 0 else east
		Fx.burst(at + Vector2(0, -20), Color(0.6, 0.5, 0.38), 30, 140.0)
		Fx.shake(5.0)
		Sfx.play_at("amheh_land", at, 0.1)
		Fx.float_text(at + Vector2(0, -50), Lang.t("La porta del tramonto crolla") if i == 0 else Lang.t("La porta dell'alba crolla"), Color(0.95, 0.85, 0.65))

	func _draw() -> void:
		for i in range(2):
			var at: Vector2 = west if i == 0 else east
			var col := Color(0.35, 0.5, 1.0) if i == 0 else Color(1.0, 0.4, 0.15)
			if up[i]:
				# la porta che si prepara: un bagliore che cresce nell'ultimo secondo prima dell'uscita
				var soon := clampf(1.0 - timer[i], 0.0, 1.0)
				if soon > 0.0:
					draw_circle(at, 10.0 + 14.0 * soon, Color(col, 0.12 + 0.25 * soon))
				continue
			# crollata: massi che cadono, poi un mucchio di macerie davanti alla porta
			var k := clampf(fall[i] / 0.8, 0.0, 1.0)
			for j in range(6):
				var sgn := 1.0 if i == 0 else -1.0
				var p := at + Vector2(float(j % 3 - 1) * 8.0 * sgn - 8.0 * sgn, -6.0 + floorf(j / 3.0) * 9.0)
				var y := -60.0 * (1.0 - k * k)
				draw_circle(p + Vector2(0, y), 6.0 - j % 2, Color(0.4, 0.32, 0.24))
				draw_circle(p + Vector2(-1.5, y - 1.5), 2.5, Color(0.55, 0.45, 0.34))
