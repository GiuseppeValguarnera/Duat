class_name ArmsArt
extends RefCounted
## Disegno delle due armi del blocco del 12/11: gli Artigli di Bastet e lo Scettro di Ptah.

const GOLD := Color(0.94, 0.72, 0.3)
const BLADE := Color(0.9, 0.9, 0.96)
const OUT := Color(0.12, 0.08, 0.05)
const TURQ := Color(0.25, 0.8, 0.75)


## Gli artigli: un bracciale d'oro con tre lame ricurve. `open` 0 → 1 allarga le lame (nel colpo).
static func draw_claws(ci: CanvasItem, hand: Vector2, dir: Vector2, s: float, open: float, a: float = 1.0) -> void:
	var o := dir.orthogonal()
	ci.draw_line(hand - dir * 2.0 * s - o * 3.0 * s, hand - dir * 2.0 * s + o * 3.0 * s, Color(OUT, a), 4.4 * s)
	ci.draw_line(hand - dir * 2.0 * s - o * 3.0 * s, hand - dir * 2.0 * s + o * 3.0 * s, Color(GOLD, a), 3.0 * s)
	for k: float in [-1.0, 0.0, 1.0]:
		var d := dir.rotated(k * (0.22 + 0.25 * open))
		var base := hand + o * k * 2.2 * s
		var mid := base + d * 6.0 * s + d.orthogonal() * 1.4 * s
		var tip := base + d * (10.0 + 3.0 * open) * s
		ci.draw_polyline(PackedVector2Array([base, mid, tip]), Color(OUT, a), 2.6 * s)
		ci.draw_polyline(PackedVector2Array([base, mid, tip]), Color(BLADE, a), 1.4 * s)


## Lo scettro: asta lunga d'oro e lapis, in cima la testa dell'animale di Set stilizzata (il was) con
## dentro il pilastro djed e l'ankh di Ptah; in fondo la forcella. `glow` accende la gemma.
static func draw_sceptre(ci: CanvasItem, hand: Vector2, dir: Vector2, s: float, glow: float, a: float = 1.0) -> void:
	var o := dir.orthogonal()
	var foot := hand - dir * 12.0 * s
	var top := hand + dir * 20.0 * s
	ci.draw_line(foot, top, Color(OUT, a), 3.2 * s)
	ci.draw_line(foot, top, Color(GOLD, a), 1.8 * s)
	for i in range(3):
		var p := hand + dir * (2.0 + i * 5.0) * s
		ci.draw_line(p - o * 1.6 * s, p + o * 1.6 * s, Color(0.2, 0.36, 0.78, a), 1.6 * s)
	# forcella
	ci.draw_line(foot, foot - dir * 3.0 * s + o * 2.2 * s, Color(GOLD, a), 1.4 * s)
	ci.draw_line(foot, foot - dir * 3.0 * s - o * 2.2 * s, Color(GOLD, a), 1.4 * s)
	# testa del was: muso obliquo e orecchie
	var head := PackedVector2Array([top - o * 2.0 * s, top + dir * 3.0 * s - o * 2.5 * s, top + dir * 5.0 * s + o * 6.0 * s, top + dir * 1.0 * s + o * 3.0 * s])
	ci.draw_colored_polygon(head, Color(GOLD, a))
	head.append(head[0])
	ci.draw_polyline(head, Color(OUT, a), 0.9 * s)
	ci.draw_line(top + dir * 3.0 * s - o * 2.0 * s, top + dir * 7.5 * s - o * 3.5 * s, Color(GOLD, a), 1.5 * s)
	var gem := top + dir * 2.4 * s + o * 0.8 * s
	if glow > 0.0:
		ci.draw_circle(gem, (3.0 + 3.0 * glow) * s, Color(TURQ, 0.3 * glow * a))
	ci.draw_circle(gem, 1.5 * s, Color(TURQ.lerp(Color.WHITE, 0.6 * glow), a))
