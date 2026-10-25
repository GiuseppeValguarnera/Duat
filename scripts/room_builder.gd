extends RefCounted
## La costruzione di una stanza della discesa: dove c'è posto libero, l'acqua, le grate di
## fuoco, le giare d'olio, gli spuntoni, i dardi, i muri. Prima stava in game.gd: è stato
## spostato qui nel riordino del codice, uguale. `g` è la partita (scripts/game.gd).

var g: Game


func _init(game: Game) -> void:
	g = game

func free_spot() -> Vector2:
	var p := Vector2.ZERO
	for i in range(50):
		p = Vector2(randf_range(g.WALL + 30.0, g.ROOM.size.x - g.WALL - 30.0), randf_range(g.TOP + 30.0, g.ROOM.size.y - g.WALL - 30.0))
		if spot_ok(p) and (g.player == null or p.distance_to(g.player.global_position) > 160.0):
			break
	return p


func free_spot_near(center: Vector2) -> Vector2:
	var p := center
	for i in range(30):
		if spot_ok(p):
			return p
		p = center + Vector2(randf_range(-80.0, 80.0), randf_range(-50.0, 50.0))
	return p


func spot_ok(p: Vector2) -> bool:
	for pl in g.pillars:
		if p.distance_to(pl) < 36.0:
			return false
	for r in g.obstacles:
		if (r as Rect2).grow(14.0).has_point(p):
			return false
	for tp in g.traps_pos:
		if p.distance_to(tp) < 26.0:
			return false
	for off in [Vector2.ZERO, Vector2(18, 0), Vector2(-18, 0), Vector2(0, 18), Vector2(0, -18)]:
		if Hazards.in_water(g.get_tree(), p + off):
			return false
	return true


## Un punto del pavimento libero: lontano dalla ricompensa, dal punto di partenza e dalle porte.
func floor_ok(p: Vector2) -> bool:
	var cx := g.ROOM.size.x / 2.0
	var mid_y := (g.TOP + g.ROOM.size.y - g.WALL) / 2.0
	if p.x < g.WALL + 20.0 or p.x > g.ROOM.size.x - g.WALL - 20.0 or p.y < g.TOP + 16.0 or p.y > g.ROOM.size.y - g.WALL - 16.0:
		return false
	if p.distance_to(Vector2(cx, mid_y + 20.0)) < 70.0:
		return false
	if p.distance_to(Vector2(cx, g.ROOM.size.y - g.WALL - 24.0)) < 100.0:
		return false
	if absf(p.x - cx) < 50.0 and p.y < g.TOP + 70.0:
		return false
	if absf(p.y - mid_y) < 60.0 and (p.x < g.WALL + 70.0 or p.x > g.ROOM.size.x - g.WALL - 70.0):
		return false
	return spot_ok(p)


## Le acque di Wernes nelle stanze della Prima Ora (vedi README, "Acqua e fuoco"):
## stanze 1-2 al massimo una pozza; dalla 3 acqua e giare d'olio; dalla 6 le grate di fuoco,
## che prendono il posto di altrettanti spuntoni.
func place_elements() -> void:
	var r := Run.room
	var n_water := (1 if randf() < 0.3 else 0) if r <= 2 else 1 + (1 if r >= 8 and randf() < 0.5 else 0)
	for i in range(n_water):
		place_water(r >= 3 and randf() < 0.4)
	if r >= 6:
		var n_grates := 1 + (1 if r >= 9 else 0)
		for i in range(n_grates):
			if place_grate():
				g.grates_here += 1
	if r >= 3:
		for i in range(1 + (1 if randf() < 0.5 else 0)):
			place_jars()


func place_water(channel: bool) -> void:
	for tries in range(40):
		var c := Vector2(randf_range(g.WALL + 90.0, g.ROOM.size.x - g.WALL - 90.0), randf_range(g.TOP + 60.0, g.ROOM.size.y - g.WALL - 70.0))
		var pool := Hazards.WaterPool.new()
		var probe: Array = []
		if channel:
			var along := randf() < 0.65
			pool.rect = Vector2(randf_range(150.0, 240.0), 30.0) if along else Vector2(30.0, randf_range(110.0, 170.0))
			var h := pool.rect / 2.0
			for k in range(7):
				probe.append(c + Vector2(lerpf(-h.x, h.x, k / 6.0), 0) if along else c + Vector2(0, lerpf(-h.y, h.y, k / 6.0)))
		else:
			pool.radii = Vector2(randf_range(34.0, 46.0), randf_range(20.0, 26.0))
			probe = [c, c + Vector2(pool.radii.x, 0), c - Vector2(pool.radii.x, 0), c + Vector2(0, pool.radii.y), c - Vector2(0, pool.radii.y)]
		if not probe.all(func(q): return floor_ok(q)):
			pool.free()
			continue
		var near_pillar := false
		for pl in g.pillars:
			for q in probe:
				if q.distance_to(pl) < 40.0:
					near_pillar = true
		if near_pillar:
			pool.free()
			continue
		pool.position = c
		g.world.add_child(pool)
		return


func place_grate() -> bool:
	for tries in range(40):
		var gx := randi_range(2, int((g.ROOM.size.x - g.WALL * 2.0) / 32.0) - 3)
		var gy := randi_range(1, int((g.ROOM.size.y - g.WALL - g.TOP) / 32.0) - 2)
		var c := Vector2(g.WALL + 16.0 + gx * 32.0, g.TOP + 16.0 + gy * 32.0)
		var dir := Vector2.RIGHT if randf() < 0.6 else Vector2.DOWN
		var ok := true
		var cs: Array = []
		for i in range(3):
			var q: Vector2 = c + dir * (i - 1) * Hazards.FireGrate.CELL
			cs.append(q)
			if not floor_ok(q):
				ok = false
		if not ok:
			continue
		var gr := Hazards.FireGrate.new()
		gr.dir = dir
		gr.cells = 3
		gr.t = randf() * 2.0
		g.world.add_child(gr)
		gr.position = c
		g.traps_pos.append_array(cs)
		return true
	return false


func place_jars() -> void:
	for tries in range(30):
		var c := Vector2(randf_range(g.WALL + 40.0, g.ROOM.size.x - g.WALL - 40.0), randf_range(g.TOP + 30.0, g.ROOM.size.y - g.WALL - 30.0))
		if not floor_ok(c):
			continue
		var far := true
		for trap in g.get_tree().get_nodes_in_group("traps"):
			if trap is Hazards.FireGrate and trap.near(c) < 56.0:
				far = false
		if not far:
			continue
		var n := randi_range(2, 3)
		for k in range(n):
			var j := Hazards.OilJar.new()
			g.world.add_child(j)
			j.position = c + Vector2((k - (n - 1) / 2.0) * 14.0, randf_range(-4.0, 4.0))
		g.traps_pos.append(c)
		return


## Trappole da piramide: lastre con spuntoni e, più avanti, feritoie che sparano dardi.
func place_traps() -> void:
	var cx := g.ROOM.size.x / 2.0
	var mid_y := (g.TOP + g.ROOM.size.y - g.WALL) / 2.0
	var spikes := maxi(1, clampi(Run.room, 2, 4) - g.grates_here) + 2 * Weights.rank("sabbie")
	var tries := 0
	var placed := 0
	while placed < spikes and tries < 80:
		tries += 1
		var gx := randi_range(1, int((g.ROOM.size.x - g.WALL * 2.0) / 32.0) - 2)
		var gy := randi_range(1, int((g.ROOM.size.y - g.WALL - g.TOP) / 32.0) - 2)
		var p := Vector2(g.WALL + 16.0 + gx * 32.0, g.TOP + 16.0 + gy * 32.0)
		if p.distance_to(Vector2(cx, mid_y + 20.0)) < 70.0:
			continue                      # lì compare la ricompensa
		if p.distance_to(Vector2(cx, g.ROOM.size.y - g.WALL - 24.0)) < 100.0:
			continue                      # punto di partenza del giocatore
		if absf(p.x - cx) < 50.0 and p.y < g.TOP + 70.0:
			continue
		if absf(p.y - mid_y) < 60.0 and (p.x < g.WALL + 70.0 or p.x > g.ROOM.size.x - g.WALL - 70.0):
			continue
		if not spot_ok(p):
			continue
		g.traps_pos.append(p)
		placed += 1
		var s := Traps.Spikes.new()
		s.t = randf() * 2.0
		g.world.add_child(s)
		s.position = p
	if Run.room >= g.TRAPS_FROM_ROOM + 1 - Weights.rank("sabbie"):
		for i in range(randi_range(1, 2)):
			var left := randf() < 0.5
			var y := randf_range(g.TOP + 40.0, g.ROOM.size.y - g.WALL - 40.0)
			if absf(y - mid_y) < 60.0:
				y += 80.0 if y >= mid_y else -80.0
			var d := Traps.DartWall.new()
			d.dir = Vector2.RIGHT if left else Vector2.LEFT
			d.t = randf() * 2.0
			g.world.add_child(d)
			d.position = Vector2(g.WALL - 2.0 if left else g.ROOM.size.x - g.WALL + 2.0, y)


func build_walls() -> void:
	var r := g.ROOM
	solid(Rect2(r.position.x, r.position.y, r.size.x, g.TOP))
	solid(Rect2(r.position.x, r.end.y - g.WALL, r.size.x, g.WALL))
	solid(Rect2(r.position.x, r.position.y, g.WALL, r.size.y))
	solid(Rect2(r.end.x - g.WALL, r.position.y, g.WALL, r.size.y))
	for p in g.pillars:
		solid(Rect2(p.x - 13.0, p.y - 7.0, 26.0, 14.0)).add_to_group("g.pillars")


func solid(rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.add_child(shape)
	body.position = rect.get_center()
	g.world.add_child(body)
	return body
