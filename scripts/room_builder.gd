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
		if spot_ok(p) and in_floor(p, 20.0):
			return p
		p = center + Vector2(randf_range(-80.0, 80.0), randf_range(-50.0, 50.0))
	# niente di libero lì vicino: un punto libero qualsiasi (prima tornava l'ultimo provato, che
	# vicino a un muro poteva cadere fuori dalla stanza)
	return free_spot()


## Dentro il pavimento, lontano almeno `margin` dai muri.
func in_floor(p: Vector2, margin: float) -> bool:
	return p.x > g.WALL + margin and p.x < g.ROOM.size.x - g.WALL - margin and p.y > g.TOP + margin and p.y < g.ROOM.size.y - g.WALL - margin


## Dove far ricomparire un nemico incastrato: verso il centro della stanza (la tasca contro il
## muro, per spot_ok, può sembrare libera), su un punto libero e dentro il pavimento.
func unstick_spot(from: Vector2) -> Vector2:
	var center := Vector2(g.ROOM.size.x / 2.0, (g.TOP + g.ROOM.size.y - g.WALL) / 2.0)
	for i in range(24):
		var k := 0.25 + 0.03 * i
		var p := from.lerp(center, minf(k, 0.95)) + Vector2(randf_range(-20.0, 20.0), randf_range(-14.0, 14.0))
		var far_from_you: bool = g.player == null or p.distance_to(g.player.global_position) > 70.0
		if p.distance_to(from) > 30.0 and far_from_you and spot_ok(p) and in_floor(p, 24.0):
			return p
	return free_spot()                 # lontano da te (oltre 160 pixel)


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
	if Run.region >= 3:
		_place_apep(r)
		return
	if Run.region == 2:
		_place_sokar(r)
		return
	# la Prima Ora sono le acque di Wernes: l'acqua c'è quasi sempre, e dalla terza stanza ci
	# vivono i coccodrilli
	var n_water := (1 if randf() < 0.5 else 0) if r <= 2 else 1 + (1 if r >= 5 and randf() < 0.5 else 0)
	for i in range(n_water):
		place_water(r >= 3 and randf() < 0.5)
	if r >= 6:
		var n_grates := 1 + (1 if r >= 9 else 0)
		for i in range(n_grates):
			if place_grate():
				g.grates_here += 1
	if r >= 3:
		for i in range(1 + (1 if randf() < 0.5 else 0)):
			place_jars()


## Il deserto di Sokar. Ogni stanza sceglie uno SCHEMA e 2-3 elementi, mai a caso:
##  - schemi: fiume orizzontale, fiume verticale, due fiumi ai lati (dalla stanza 3, più larghi
##    andando avanti), oppure solo trappole;
##  - ogni fiume ha almeno due attraversamenti (lastre) lontani tra loro, uno sulla strada di una
##    porta; una lastra può essere di quelle che crollano;
##  - le trappole (lastre che crollano, spuntoni) stanno vicino ai passaggi e sulla strada tra
##    l'entrata e le porte; il soffio della statua-falco taglia una zona di passaggio;
##  - le sabbie mobili in 2-3 macchie in parti diverse della stanza;
##  - mai trappole sull'entrata o davanti alle porte, e il centro resta libero (floor_ok).
## Il Banco di Apopi: pozze fisse di Isfet (2-4), spire di Apopi sotto il pavimento (1-3, dalla
## seconda stanza), spuntoni dalla quarta. Niente acqua né fiumi: qui il fiume l'ha bevuto il serpente.
func _place_apep(r: int) -> void:
	var spots: Array = []
	var n_pool := 2 + (1 if r >= 3 else 0) + (1 if r >= 6 and randf() < 0.6 else 0)
	for i in range(n_pool):
		var at := _apep_spot(spots, 70.0)
		if at == Vector2.INF:
			continue
		spots.append(at)
		var pool := Chaos.Isfet.new()
		pool.r = randf_range(20.0, 30.0)
		pool.position = at
		g.world.add_child(pool)
	var n_coil := 0 if r < 2 else (1 + (1 if r >= 4 else 0) + (1 if r >= 7 else 0))
	for i in range(n_coil):
		var at2 := _apep_spot(spots, 80.0)
		if at2 == Vector2.INF:
			continue
		spots.append(at2)
		var coil := Chaos.Coil.new()
		coil.period = maxf(4.0, 6.5 - 0.25 * r)
		coil.position = at2
		g.world.add_child(coil)
	if r >= 4:
		_place_spikes_near(spots, 2 + (1 if r >= 7 else 0))
	if r >= 3:
		place_jars()


## Un punto libero sul pavimento, lontano dalle porte, dal centro (dove compare l'eroe) e dagli altri.
func _apep_spot(taken: Array, apart: float) -> Vector2:
	var fr := Rect2(g.WALL + 46.0, g.TOP + 46.0, g.ROOM.size.x - g.WALL * 2.0 - 92.0, g.ROOM.size.y - g.WALL - g.TOP - 92.0)
	var start := Vector2(g.ROOM.size.x / 2.0, g.ROOM.size.y - g.WALL - 40.0)
	for tries in range(30):
		var p := Vector2(randf_range(fr.position.x, fr.end.x), randf_range(fr.position.y, fr.end.y))
		if p.distance_to(start) < 80.0 or not spot_ok(p):
			continue
		var ok := true
		for q in taken:
			if p.distance_to(q) < apart:
				ok = false
		if ok:
			return p
	return Vector2.INF


func _place_sokar(r: int) -> void:
	var schemes := ["trappole"]
	if r >= 3:
		schemes = ["fiume_o", "fiume_v", "due_fiumi", "trappole"]
	var scheme: String = schemes.pick_random()
	var thick := clampf(26.0 + 4.0 * (r - 3), 26.0, 50.0)
	var crossings: Array = []            # i punti di passaggio, dove mettere le trappole
	match scheme:
		"fiume_o":
			crossings = _river_h(thick)
		"fiume_v":
			crossings = _river_v(thick, randf() < 0.5, 120.0)
		"due_fiumi":
			var t2 := thick * 0.75
			crossings = _river_v(t2, true, 66.0) + _river_v(t2, false, 66.0)
	# gli elementi oltre al fiume: 2-3 in tutto
	var extras := ["crolli", "falco", "mobili", "spuntoni"]
	extras.shuffle()
	var n_extra := (2 if scheme == "trappole" else 1) + (1 if r >= 4 and randf() < 0.6 else 0)
	for k in range(n_extra):
		match extras[k]:
			"crolli":
				_place_crumbles(crossings, 2 + (1 if r >= 5 else 0))
			"falco":
				_place_falcon(crossings)
			"mobili":
				_place_quicksands(randi_range(2, 3))
			"spuntoni":
				_place_spikes_near(crossings, 2 + (1 if r >= 6 else 0))
	if r >= 3 and randf() < 0.3:
		var storm := Hazards.Sandstorm.new()
		storm.room = Rect2(Vector2.ZERO, g.ROOM.size)
		g.world.add_child(storm)
	if r >= 3:
		place_jars()


## Un fiume che attraversa la stanza da parete a parete, nella parte alta (davanti alla porta nord
## c'è sempre una lastra). Due o tre attraversamenti, lontani tra loro.
func _river_h(thick: float) -> Array:
	var y := g.TOP + 62.0
	var rect := Rect2(g.WALL, y - thick / 2.0, g.ROOM.size.x - g.WALL * 2.0, thick)
	var cx := g.ROOM.size.x / 2.0
	var xs := [cx, g.WALL + 70.0 + randf() * 40.0 if randf() < 0.5 else g.ROOM.size.x - g.WALL - 110.0 + randf() * 40.0]
	return _add_river(rect, Vector2.RIGHT if randf() < 0.5 else Vector2.LEFT, xs, true)


## Un fiume verticale a sinistra o a destra, a `inset` pixel dal muro. Una lastra davanti alla porta
## di quel lato (a metà altezza) e una in alto o in basso.
func _river_v(thick: float, left: bool, inset: float) -> Array:
	var x := g.WALL + inset if left else g.ROOM.size.x - g.WALL - inset
	var rect := Rect2(x - thick / 2.0, g.TOP, thick, g.ROOM.size.y - g.WALL - g.TOP)
	var mid_y := (g.TOP + g.ROOM.size.y - g.WALL) / 2.0
	var ys := [mid_y, g.TOP + 40.0 if randf() < 0.5 else g.ROOM.size.y - g.WALL - 40.0]
	return _add_river(rect, Vector2.DOWN if randf() < 0.5 else Vector2.UP, ys, false)


func _add_river(rect: Rect2, flow: Vector2, at: Array, horizontal: bool) -> Array:
	var river := SokarTerrain.SandRiver.new()
	river.rect = rect
	river.flow = flow
	var points: Array = []
	for v in at:
		var pr: Rect2
		if horizontal:
			pr = Rect2(float(v) - 14.0, rect.position.y - 3.0, 28.0, rect.size.y + 6.0)
		else:
			pr = Rect2(rect.position.x - 3.0, float(v) - 14.0, rect.size.x + 6.0, 28.0)
		river.plates.append(pr)
		points.append(pr.get_center())
	g.world.add_child(river)
	return points


## Lastre che crollano vicino ai passaggi e sulla strada tra l'entrata e le porte.
func _place_crumbles(crossings: Array, n: int) -> void:
	var targets := _path_points(crossings)
	var placed := 0
	for c in targets:
		if placed >= n:
			break
		for tries in range(12):
			var p: Vector2 = c + Vector2(randf_range(-40.0, 40.0), randf_range(-34.0, 34.0))
			p = Vector2(snappedf(p.x, 4.0), snappedf(p.y, 4.0))
			if not floor_ok(p) or _in_river(p):
				continue
			var tile := SokarTerrain.CrumbleTile.new()
			tile.position = p
			g.world.add_child(tile)
			g.traps_pos.append(p)
			placed += 1
			break


## Spuntoni vicino ai passaggi.
func _place_spikes_near(crossings: Array, n: int) -> void:
	var targets := _path_points(crossings)
	var placed := 0
	for c in targets:
		if placed >= n:
			break
		for tries in range(12):
			var p: Vector2 = c + Vector2(randf_range(-46.0, 46.0), randf_range(-38.0, 38.0))
			if not floor_ok(p) or _in_river(p):
				continue
			var sp := Traps.Spikes.new()
			sp.t = randf() * 2.0
			sp.position = p
			g.world.add_child(sp)
			g.traps_pos.append(p)
			placed += 1
			break


## I punti dove passa chi cammina: gli attraversamenti dei fiumi, e la strada tra l'entrata (in basso
## al centro) e le porte (nord, ovest, est), a metà strada. In ordine casuale, gli attraversamenti prima.
func _path_points(crossings: Array) -> Array:
	var start := Vector2(g.ROOM.size.x / 2.0, g.ROOM.size.y - g.WALL - 24.0)
	var mid_y := (g.TOP + g.ROOM.size.y - g.WALL) / 2.0
	var doors := [Vector2(g.ROOM.size.x / 2.0, g.TOP + 20.0), Vector2(g.WALL + 20.0, mid_y), Vector2(g.ROOM.size.x - g.WALL - 20.0, mid_y)]
	var pts := crossings.duplicate()
	pts.shuffle()
	var road: Array = []
	for d in doors:
		road.append(start.lerp(d, 0.55))
		road.append(start.lerp(d, 0.75))
	road.shuffle()
	return pts + road


## La statua-falco sul muro ovest o est: soffia in orizzontale lungo una zona di passaggio (la riga di
## un attraversamento, o a metà strada tra il centro e la porta nord). Mai all'altezza delle porte
## laterali né dell'entrata.
func _place_falcon(crossings: Array) -> void:
	var mid_y := (g.TOP + g.ROOM.size.y - g.WALL) / 2.0
	var ys: Array = []
	for c in crossings:
		if absf(c.y - mid_y) > 46.0 and c.y < g.ROOM.size.y - g.WALL - 70.0:
			ys.append(c.y + randf_range(-6.0, 6.0))
	if ys.is_empty():
		ys = [g.TOP + 96.0 + randf() * 20.0, mid_y + 70.0]
	var y: float = ys.pick_random()
	if absf(y - mid_y) < 46.0:
		y = mid_y + (60.0 if y > mid_y else -60.0)
	var left := randf() < 0.5
	var f := SokarTerrain.FalconStatue.new()
	f.dir = Vector2.RIGHT if left else Vector2.LEFT
	f.position = Vector2(g.WALL + 2.0 if left else g.ROOM.size.x - g.WALL - 2.0, y)
	f.length = g.ROOM.size.x - g.WALL * 2.0 - 4.0
	f.t = randf() * 2.0
	g.world.add_child(f)


## Sabbie mobili in 2-3 macchie, in parti diverse della stanza (una per spicchio).
func _place_quicksands(n: int) -> void:
	var cx := g.ROOM.size.x / 2.0
	var mid_y := (g.TOP + g.ROOM.size.y - g.WALL) / 2.0
	var zones := [Rect2(g.WALL + 40.0, g.TOP + 30.0, cx - g.WALL - 90.0, mid_y - g.TOP - 50.0),
		Rect2(cx + 50.0, g.TOP + 30.0, cx - g.WALL - 90.0, mid_y - g.TOP - 50.0),
		Rect2(g.WALL + 40.0, mid_y + 30.0, cx - g.WALL - 110.0, g.ROOM.size.y - g.WALL - mid_y - 70.0),
		Rect2(cx + 70.0, mid_y + 30.0, cx - g.WALL - 110.0, g.ROOM.size.y - g.WALL - mid_y - 70.0)]
	zones.shuffle()
	var placed := 0
	for z in zones:
		if placed >= n:
			break
		for tries in range(20):
			var c := Vector2(randf_range(z.position.x, z.end.x), randf_range(z.position.y, z.end.y))
			if not floor_ok(c) or _in_river(c):
				continue
			var q := Hazards.Quicksand.new()
			q.radii = Vector2(randf_range(30.0, 42.0), randf_range(18.0, 24.0))
			q.position = c
			g.world.add_child(q)
			placed += 1
			break


func _in_river(p: Vector2) -> bool:
	for rv in g.get_tree().get_nodes_in_group("river"):
		if (rv.rect as Rect2).grow(16.0).has_point(p):
			return true
	return false


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
	var spikes := maxi(1, clampi(Run.trap_depth(), 2, 4) - g.grates_here) + 2 * Weights.rank("sabbie")
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
	if Run.trap_depth() >= g.TRAPS_FROM_ROOM + 1 - Weights.rank("sabbie"):
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
	g.top_wall = solid(Rect2(r.position.x, r.position.y, r.size.x, g.TOP))   # il serdab lo apre
	solid(Rect2(r.position.x, r.end.y - g.WALL, r.size.x, g.WALL))
	solid(Rect2(r.position.x, r.position.y, g.WALL, r.size.y))
	solid(Rect2(r.end.x - g.WALL, r.position.y, g.WALL, r.size.y))
	for p in g.pillars:
		solid(Rect2(p.x - 13.0, p.y - 7.0, 26.0, 14.0)).add_to_group("pillars")


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
