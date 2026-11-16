class_name RaLight
## La luce di Ra nel Banco di Apopi (blocco 21). La barca del sole è arenata, ma la sua luce filtra
## ancora: un FASCIO dorato attraversa ogni stanza di combattimento. Non ferisce nessuno. I nemici con
## le SCAGLIE (un terzo della stanza, mai tutti) fuori dalla luce subiscono il 10% dei colpi; dentro il
## fascio, per 3 s dopo che li ha toccati, o legati a un palo di Serket, le scaglie si aprono (dorate)
## e subiscono tutto. Il Divoratore di luce inghiotte il fascio finché vive; il Portatore del velo
## tiene chiuse le scaglie di chi gli sta vicino.

const WIDTH := 90.0                ## larghezza della fascia
const EVERY := 12.0                ## un passaggio ogni 12 s circa
const EVERY_BOAT := 6.5            ## Corridoio della barca: avanti e indietro
const CROSS := 3.0                 ## secondi per attraversare la stanza
const WARN := 1.2                  ## avviso sul bordo da cui entra
const OPEN_TIME := 3.0             ## le scaglie restano aperte dopo il fascio
const SCALE_MULT := 0.1            ## danni con le scaglie chiuse
const VEIL_R := 70.0
const BIND_TIME := 2.6
const STAKE_REACH := 16.0
const STAKE_REGROW := 8.0
const SHIFT_EVERY := 8.0           ## Pozze di Isfet: cambiano posto
const SHIFT_WARN := 1.0
const GOLD := Color(1.0, 0.86, 0.45)


static func lit(pos: Vector2, tree: SceneTree) -> bool:
	for b in tree.get_nodes_in_group("ra_beam"):
		if b.covers(pos):
			return true
	return false


static func veiled(pos: Vector2, tree: SceneTree) -> bool:
	for v in tree.get_nodes_in_group("veils"):
		if is_instance_valid(v) and not v.dead and pos.distance_to(v.global_position) < VEIL_R:
			return true
	return false


## Un Divoratore di luce è vivo: il fascio non attraversa la stanza.
static func eaten(tree: SceneTree) -> bool:
	for e in tree.get_nodes_in_group("light_eaters"):
		if is_instance_valid(e) and not e.dead:
			return true
	return false


## Per l'HUD: "" niente fascio in questa stanza, "wait", "warn", "cross", "eaten".
static func status(tree: SceneTree) -> String:
	var b = tree.get_first_node_in_group("ra_beam")
	if b == null:
		return ""
	if b.blocked:
		return "eaten"
	return "wait" if b.phase == "" else String(b.phase)


## Il disegno delle scaglie sopra il corpo di un nemico e il segno sopra la testa.
## `open_t` > 0: aperte (oro, con l'arco del tempo che resta); altrimenti chiuse (scure).
static func draw_scales(ci: CanvasItem, radius: float, open_t: float, t: float) -> void:
	var c := Vector2(0, -radius)
	var top := Vector2(0, -radius * 2.0 - 15.0)
	if open_t > 0.0:
		var pulse := 0.5 + 0.5 * sin(t * 10.0)
		ci.draw_arc(c, radius + 3.0, 0.0, TAU, 20, Color(GOLD, 0.55 + 0.35 * pulse), 1.6)
		for i in range(5):
			var a := -PI * 0.9 + PI * 0.8 * i / 4.0
			var q := c + Vector2.from_angle(a) * (radius + 1.0)
			ci.draw_line(q, q + Vector2.from_angle(a) * 4.0, Color(GOLD, 0.9), 1.4)
		# il sole aperto sopra la testa, con l'arco del tempo che resta
		ci.draw_circle(top, 4.6, Color(0.1, 0.07, 0.03))
		ci.draw_circle(top, 3.4, GOLD)
		for i in range(8):
			var ra := TAU * i / 8.0 + t
			ci.draw_line(top + Vector2.from_angle(ra) * 4.6, top + Vector2.from_angle(ra) * 6.6, GOLD, 1.0)
		ci.draw_arc(top, 8.4, -PI / 2.0, -PI / 2.0 + TAU * clampf(open_t / OPEN_TIME, 0.0, 1.0), 16, Color(1, 1, 1, 0.85), 1.2)
		return
	# chiuse: file di scaglie scure sul corpo e uno scudo viola sopra la testa
	for row in range(3):
		var y := -radius * 0.4 - row * radius * 0.55
		var n := 3 - (row % 2)
		for i in range(n):
			var x := (i - (n - 1) / 2.0) * radius * 0.62
			ci.draw_arc(Vector2(x, y), radius * 0.34, PI * 0.1, PI * 0.9, 6, Color(0.08, 0.04, 0.14, 0.95), 2.0)
			ci.draw_arc(Vector2(x, y), radius * 0.34, PI * 0.1, PI * 0.9, 6, Color(0.55, 0.35, 0.8, 0.8), 0.8)
	var sh := PackedVector2Array([top + Vector2(-4.5, -4), top + Vector2(4.5, -4), top + Vector2(4.5, 1), top + Vector2(0, 5.5), top + Vector2(-4.5, 1)])
	ci.draw_colored_polygon(sh, Color(0.1, 0.05, 0.16))
	sh.append(sh[0])
	ci.draw_polyline(sh, Color(0.7, 0.45, 1.0), 1.2)
	ci.draw_arc(top + Vector2(0, -0.5), 2.0, PI * 0.1, PI * 0.9, 5, Color(0.7, 0.45, 1.0), 1.0)


## Il fascio. Sta nel mondo della stanza (coordinate della stanza), sopra le creature ma trasparente.
class Beam extends Node2D:
	var room := Rect2()            ## il pavimento
	var every := RaLight.EVERY
	var ping := false              ## Corridoio della barca: solo ovest↔est, avanti e indietro
	var wait := 4.0
	var phase := ""                ## "" (attesa) → "warn" → "cross"
	var st := 0.0
	var step := 0
	var dir := 0                   ## 0 ovest→est, 1 nord→sud, 2 est→ovest, 3 sud→nord: alterna, mai a caso
	var t := 0.0
	var blocked := false

	func _ready() -> void:
		add_to_group("ra_beam")
		z_index = 3

	func _horizontal() -> bool:
		return dir % 2 == 0

	## Il centro della fascia lungo il suo asse (in coordinate della stanza).
	func _center() -> float:
		var k := 1.0 - st / RaLight.CROSS
		var a := room.position.x if _horizontal() else room.position.y
		var b := room.end.x if _horizontal() else room.end.y
		var from := a - RaLight.WIDTH / 2.0
		var to := b + RaLight.WIDTH / 2.0
		if dir >= 2:
			return lerpf(to, from, k)
		return lerpf(from, to, k)

	func covers(pos: Vector2) -> bool:
		if phase != "cross":
			return false
		var v := pos.x if _horizontal() else pos.y
		return absf(v - _center()) < RaLight.WIDTH / 2.0

	func _process(delta: float) -> void:
		t += delta
		blocked = RaLight.eaten(get_tree())
		if blocked:
			if phase != "":
				phase = ""                      # il Divoratore l'ha inghiottito
				wait = 2.0
			wait = maxf(wait, 2.0)
			queue_redraw()
			return
		match phase:
			"":
				wait -= delta
				if wait <= 0.0:
					dir = (step % 2) * 2 if ping else step % 4
					step += 1
					phase = "warn"
					st = RaLight.WARN
					Sfx.play("divine", 0.05, -12.0)
			"warn":
				st -= delta
				if st <= 0.0:
					phase = "cross"
					st = RaLight.CROSS
			"cross":
				st -= delta
				if st <= 0.0:
					phase = ""
					wait = maxf(1.5, every - RaLight.CROSS - RaLight.WARN)
		queue_redraw()

	func _draw() -> void:
		if phase == "warn":
			# il bordo da cui entra: una barra d'oro che si riempie e tre punte verso l'interno
			var k := 1.0 - st / RaLight.WARN
			var edge: Rect2
			var inward := Vector2.RIGHT
			match dir:
				0:
					edge = Rect2(room.position.x, room.position.y, 8.0, room.size.y)
				1:
					edge = Rect2(room.position.x, room.position.y, room.size.x, 8.0)
					inward = Vector2.DOWN
				2:
					edge = Rect2(room.end.x - 8.0, room.position.y, 8.0, room.size.y)
					inward = Vector2.LEFT
				_:
					edge = Rect2(room.position.x, room.end.y - 8.0, room.size.x, 8.0)
					inward = Vector2.UP
			draw_rect(edge, Color(RaLight.GOLD, 0.25 + 0.55 * k))
			draw_rect(edge.grow(6.0), Color(RaLight.GOLD, 0.12 * k))
			for i in range(3):
				var c := edge.get_center() + inward.orthogonal() * (i - 1) * (edge.size.x + edge.size.y) * 0.28 + inward * (16.0 + 8.0 * sin(t * 8.0))
				var o := inward.orthogonal() * 7.0
				draw_colored_polygon(PackedVector2Array([c + inward * 10.0, c - o, c + o]), Color(RaLight.GOLD, 0.5 + 0.4 * k))
		elif phase == "cross":
			var c0 := _center()
			var h := RaLight.WIDTH / 2.0
			for i in range(4):
				var w := h * (1.0 - i * 0.22)
				var r: Rect2
				if _horizontal():
					r = Rect2(c0 - w, room.position.y, w * 2.0, room.size.y)
				else:
					r = Rect2(room.position.x, c0 - w, room.size.x, w * 2.0)
				draw_rect(r.intersection(room), Color(RaLight.GOLD, 0.07))
			# i due bordi veri della fascia, netti: dentro o fuori si deve capire
			for s in [-1.0, 1.0]:
				var e: float = c0 + s * h
				if _horizontal() and e > room.position.x and e < room.end.x:
					draw_line(Vector2(e, room.position.y), Vector2(e, room.end.y), Color(RaLight.GOLD, 0.75), 1.6)
				elif not _horizontal() and e > room.position.y and e < room.end.y:
					draw_line(Vector2(room.position.x, e), Vector2(room.end.x, e), Color(RaLight.GOLD, 0.75), 1.6)


## Un palo di Serket in una stanza (l'Anello dei pali): un nemico con le scaglie che ci finisce contro
## resta legato 2,6 s con le scaglie aperte. Il palo serve una volta e ricresce dopo 8 s.
class RingStake extends Chaos.Stake:
	var regrow_t := 0.0

	func _ready() -> void:
		add_to_group("ra_stakes")
		z_index = 1

	func usable() -> bool:
		return alive and grow >= 1.0

	func bind(e: Node2D) -> void:
		spend()
		regrow_t = RaLight.STAKE_REGROW
		Sfx.play_at("hit", global_position, 0.2)
		Fx.float_text(e.global_position + Vector2(0, -34), Lang.t("LEGATO"), Color(1.0, 0.85, 0.4))

	func _process(delta: float) -> void:
		super._process(delta)
		if not alive:
			regrow_t -= delta
			if regrow_t <= 0.0:
				regrow()


## Pozze di Isfet che cambiano posto: ogni 8 s i posti nuovi si annunciano per 1 s (cerchi), poi le
## pozze vecchie svaniscono e le nuove salgono. Sempre visibili, sempre schivabili.
class Shifting extends Node2D:
	var count := 3
	var pick: Callable                  ## func(presi: Array) -> Vector2 (Vector2.INF se non trova)
	var pools: Array = []
	var next: Array = []
	var wait := 0.0
	var warn := 0.0
	var t := 0.0

	func _ready() -> void:
		Hazards.ground.call_deferred(self)
		_place.call_deferred(_choose())
		wait = RaLight.SHIFT_EVERY

	func _choose() -> Array:
		var out: Array = []
		var p = get_tree().get_first_node_in_group("player")
		for i in range(count):
			for tries in range(6):
				var at: Vector2 = pick.call(out)
				if at == Vector2.INF:
					continue
				if p != null and at.distance_to(p.global_position) < 46.0:
					continue                    # mai sotto i piedi
				out.append(at)
				break
		return out

	func _place(spots: Array) -> void:
		for pl in pools:
			if is_instance_valid(pl):
				pl.life = pl.t + 0.7            # svanisce
		pools.clear()
		for at in spots:
			var pool := Chaos.Isfet.new()
			pool.r = 26.0
			pool.position = at
			get_parent().add_child(pool)
			pools.append(pool)

	func peril(p: Vector2) -> bool:
		for at in next:
			if p.distance_to(at) < 40.0:
				return true
		return false

	func _process(delta: float) -> void:
		t += delta
		var g = get_tree().current_scene
		if g != null and g.get("cleared") == true:
			next.clear()
			queue_redraw()
			return                              # stanza ripulita: le pozze restano dove sono
		if warn > 0.0:
			warn -= delta
			if warn <= 0.0:
				_place(next)
				next = []
				wait = RaLight.SHIFT_EVERY
		else:
			wait -= delta
			if wait <= 0.0:
				next = _choose()
				warn = RaLight.SHIFT_WARN
				Sfx.play("serpent_burrow", 0.05, -8.0)
		queue_redraw()

	func _draw() -> void:
		if warn <= 0.0:
			return
		var k := 1.0 - warn / RaLight.SHIFT_WARN
		for at in next:
			var lp: Vector2 = to_local(at)
			draw_set_transform(lp, 0.0, Vector2(1.0, 0.6))
			draw_circle(Vector2.ZERO, 26.0 * k, Color(0.5, 0.2, 0.7, 0.3))
			draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 28, Color(0.85, 0.5, 1.0, 0.5 + 0.4 * k), 1.6)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
