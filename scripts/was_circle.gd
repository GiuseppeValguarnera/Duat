class_name WasCircle
extends Node2D
## Il Cerchio del Dominio: l'attacco caricato dello Scettro di Ptah. Lo scettro si pianta a terra e per
## qualche secondo, in un cerchio, i nemici sono rallentati e presi da scariche a intervalli. Tu dentro
## colpisci più forte (e con il Cerchio di Iside subisci meno).

const R := 62.0
const LIFE := 4.0
const TICK := 0.5
const SLOW := 35.0               ## percento

var dmg := 5.0                   ## a scarica
var t := 0.0
var tick := 0.15
var player: Node2D = null


func _ready() -> void:
	add_to_group("was_circle")
	Hazards.ground.call_deferred(self)
	Sfx.play_at("divine", global_position, 0.2)


static func holds(p: Vector2, tree: SceneTree) -> bool:
	for c in tree.get_nodes_in_group("was_circle"):
		var d: Vector2 = (p - c.global_position) / Vector2(R, R * 0.62)
		if d.length() < 1.0:
			return true
	return false


func _inside(p: Vector2, extra: float = 0.0) -> bool:
	var d: Vector2 = (p - global_position) / Vector2(R + extra, (R + extra) * 0.62)
	return d.length() < 1.0


func _process(delta: float) -> void:
	t += delta
	tick -= delta
	if t >= LIFE:
		queue_free()
		return
	var zap := tick <= 0.0
	if zap:
		tick = TICK
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead or not _inside(e.global_position, e.radius):
			continue
		e.slow_t = maxf(e.slow_t, 0.3)
		e.slow_pct = maxf(e.slow_pct, SLOW)
		if zap:
			var to: Vector2 = e.global_position - global_position
			e.take_hit(dmg * Run.player_hit(e, false), to.normalized(), 0.0)
			Fx.burst(e.global_position + Vector2(0, -e.radius), ArmsArt.TURQ, 4, 60.0)
	queue_redraw()


func _draw() -> void:
	var a := clampf(t / 0.2, 0.0, 1.0) * clampf((LIFE - t) / 0.5, 0.0, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.62))
	draw_circle(Vector2.ZERO, R, Color(ArmsArt.TURQ, 0.1 * a))
	draw_arc(Vector2.ZERO, R, 0.0, TAU, 48, Color(ArmsArt.TURQ, 0.85 * a), 2.0)
	draw_arc(Vector2.ZERO, R - 5.0, t * 0.8, t * 0.8 + PI * 1.5, 32, Color(ArmsArt.GOLD, 0.6 * a), 1.2)
	# i tre segni di Ptah che girano: was, djed, ankh (stilizzati a tacche)
	for i in range(12):
		var ang := -t * 0.6 + TAU * i / 12.0
		var p := Vector2.from_angle(ang) * (R - 11.0)
		draw_line(p, p + Vector2.from_angle(ang) * 5.0, Color(ArmsArt.GOLD, 0.7 * a), 1.4 if i % 3 else 2.4)
	var pulse := 1.0 - tick / TICK
	draw_arc(Vector2.ZERO, R * pulse, 0.0, TAU, 40, Color(1, 1, 1, 0.35 * (1.0 - pulse) * a), 1.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# lo scettro piantato al centro
	ArmsArt.draw_sceptre(self, Vector2(0, -10), Vector2.UP, 1.0, 0.5 + 0.5 * sin(t * 8.0), a)
