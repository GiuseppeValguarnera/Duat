class_name NeithArt
## Neith disegnata a mano: la usa il Cortile (armory.gd) e la Sala quando viene a offrirti l'arco (hub.gd).
## La dea guerriera con la corona rossa del Basso Egitto, l'arco nella mano e le frecce incrociate.

const NEITH_COLOR := Color(0.86, 0.32, 0.26)
const GOLD := Color(0.94, 0.72, 0.3)


static func draw(ci: CanvasItem, p: Vector2, t: float, talking: bool, face: float) -> void:
	var skin := Color(0.72, 0.47, 0.28)
	var linen := Color(0.93, 0.9, 0.82)
	var red := Color(0.72, 0.16, 0.14)
	var green := Color(0.18, 0.5, 0.36)
	var bob := sin(t * 1.5) * 0.6
	var pulse := 0.5 + 0.5 * sin(t * (5.0 if talking else 1.4))
	ci.draw_circle(p + Vector2(0, -30), 28.0 + 2.0 * pulse, Color(NEITH_COLOR, 0.05 + (0.08 if talking else 0.03) * pulse))
	ci.draw_set_transform(p + Vector2(0, 2), 0.0, Vector2(1.0, 0.35))
	ci.draw_circle(Vector2.ZERO, 20.0, Color(0, 0, 0, 0.4))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	ci.draw_rect(Rect2(p.x - 16, p.y - 4, 32, 6), Color(0.3, 0.22, 0.18))
	ci.draw_rect(Rect2(p.x - 16, p.y - 4, 32, 1.5), GOLD)
	ci.draw_set_transform(p, 0.0, Vector2(face, 1.0))
	var o := Vector2(0, -4)
	# arco nella mano dietro
	ci.draw_arc(o + Vector2(-12, -30 + bob), 16.0, -PI * 0.42, PI * 0.42, 16, Color(0.5, 0.33, 0.16), 2.0)
	ci.draw_line(o + Vector2(-12 + 16 * cos(-PI * 0.42), -30 + bob + 16 * sin(-PI * 0.42)), o + Vector2(-12 + 16 * cos(PI * 0.42), -30 + bob + 16 * sin(PI * 0.42)), Color(0.9, 0.85, 0.7, 0.8), 0.7)
	# veste lunga e aderente, con la rete a rombi
	var sh := -42.0 + bob
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-7, sh + 6), o + Vector2(7, sh + 6), o + Vector2(6, -14), o + Vector2(7, 0), o + Vector2(-6, 0), o + Vector2(-5, -14)]), linen)
	for i in range(4):
		ci.draw_line(o + Vector2(-5, sh + 12 + i * 8), o + Vector2(5, sh + 18 + i * 8), green.darkened(0.1), 0.7)
		ci.draw_line(o + Vector2(5, sh + 12 + i * 8), o + Vector2(-5, sh + 18 + i * 8), green.darkened(0.1), 0.7)
	ci.draw_rect(Rect2(o.x - 6, o.y + sh + 5, 12, 2), red)
	# spalle, braccia, collare
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-8, sh), o + Vector2(8, sh), o + Vector2(7, sh + 7), o + Vector2(-7, sh + 7)]), skin)
	for rr in range(3):
		ci.draw_arc(o + Vector2(0, sh - 1), 4.0 + rr * 2.2, 0.08 * PI, 0.92 * PI, 14, [GOLD, green, red][rr], 2.0)
	ci.draw_line(o + Vector2(-7, sh + 2), o + Vector2(-11, -28 + bob), skin, 2.8)
	var lift := (0.6 + 0.25 * sin(t * 3.0)) if talking else 0.0
	var shoulder := o + Vector2(7, sh + 2)
	var hand := shoulder + Vector2(3 + 9 * lift, 16 - 20 * lift)
	ci.draw_line(shoulder, hand, skin, 2.8)
	# due frecce incrociate nella mano davanti
	ci.draw_line(hand + Vector2(-3, 6), hand + Vector2(5, -8), Color(0.55, 0.38, 0.2), 1.2)
	ci.draw_line(hand + Vector2(3, 6), hand + Vector2(-3, -8), Color(0.55, 0.38, 0.2), 1.2)
	# testa: parrucca nera, occhio con il kohl, corona rossa con il ricciolo
	var hy := sh - 8.0
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-6, hy - 4), o + Vector2(3, hy - 6), o + Vector2(2, sh + 4), o + Vector2(-7, sh + 5)]), Color(0.08, 0.07, 0.1))
	ci.draw_circle(o + Vector2(1, hy), 5.0, skin)
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(4, hy - 2), o + Vector2(8, hy + 1), o + Vector2(5, hy + 2)]), skin)
	var eye := o + Vector2(3.5, hy - 1)
	ci.draw_circle(eye, 2.5 + pulse, Color(1, 0.5, 0.4, (0.25 if talking else 0.08) * pulse))
	ci.draw_colored_polygon(PackedVector2Array([eye + Vector2(-1.8, 0), eye + Vector2(0, -1), eye + Vector2(2, 0), eye + Vector2(0, 0.8)]), Color(0.98, 0.95, 0.88))
	ci.draw_circle(eye + Vector2(0.4, 0), 0.7, Color(0.05, 0.04, 0.06))
	ci.draw_line(eye + Vector2(-1.8, 0), eye + Vector2(-4.5, 0.5), Color(0.05, 0.04, 0.06), 0.8)
	# corona rossa (deshret): bassa davanti, alta dietro, con il ricciolo d'oro
	ci.draw_colored_polygon(PackedVector2Array([o + Vector2(-6, hy - 3), o + Vector2(-6, hy - 17), o + Vector2(-2, hy - 17), o + Vector2(-2, hy - 8), o + Vector2(6, hy - 8), o + Vector2(6, hy - 3)]), red)
	ci.draw_arc(o + Vector2(3, hy - 12), 3.0, PI * 0.5, PI * 1.9, 10, GOLD, 1.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
