class_name Atmos
extends RefCounted
## L'atmosfera: luce vera (Light2D di Godot) al posto degli aloni disegnati. Una penombra di
## fondo (CanvasModulate), torce e bracieri che fanno pozze di luce e tremolano, le colonne che
## fanno ombra, i bordi dello schermo che sfumano nel buio e la polvere sospesa nell'aria.
## Il buio è atmosfera, non un ostacolo: la penombra resta leggera e ciò che conta è illuminato.

## Quanto è buia la penombra: stanze della discesa (calda) e Sala del Giudizio (notte blu).
const AMBIENT_ROOM := Color(0.7, 0.63, 0.67)
const AMBIENT_HUB := Color(0.58, 0.59, 0.76)
const TORCH := Color(1.0, 0.62, 0.32)

static var _tex: GradientTexture2D = null


static func light_tex() -> GradientTexture2D:
	if _tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.35, 0.7, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.6), Color(1, 1, 1, 0.18), Color(1, 1, 1, 0)])
		_tex = GradientTexture2D.new()
		_tex.gradient = g
		_tex.fill = GradientTexture2D.FILL_RADIAL
		_tex.fill_from = Vector2(0.5, 0.5)
		_tex.fill_to = Vector2(1.0, 0.5)
		_tex.width = 256
		_tex.height = 256
	return _tex


## Una luce che tremola come una fiamma (o ferma, con set_process(false)).
class Flicker extends PointLight2D:
	var base := 1.0
	var t := 0.0
	var seed_f := 0.0

	func _process(delta: float) -> void:
		t += delta
		energy = base * (0.88 + 0.08 * sin(t * 9.0 + seed_f) + 0.05 * sin(t * 23.0 + seed_f * 2.0))


## Una luce finta: un alone sommato alla scena (un solo quadrato da disegnare). Le luci vere di
## Godot ridisegnano tutto ciò che toccano una volta per ogni luce: con dieci torce in una stanza
## il telefono rallentava. Quasi tutte le luci del gioco sono finte; le vere restano ai bracieri
## e alle lampade della Sala, solo dove la scheda grafica regge (vedi real_lights()).
class Glow extends Sprite2D:
	var base := 1.0
	var energy := 1.0:
		set(v):
			energy = v
			modulate.a = clampf(v * base_alpha, 0.0, 1.0)
	var base_alpha := 0.3
	var t := 0.0
	var seed_f := 0.0

	func _process(delta: float) -> void:
		t += delta
		energy = base * (0.9 + 0.07 * sin(t * 9.0 + seed_f) + 0.04 * sin(t * 23.0 + seed_f * 2.0))


static var _add_mat: CanvasItemMaterial = null
static var _premult_mat: CanvasItemMaterial = null


static func premult_mat() -> CanvasItemMaterial:
	if _premult_mat == null:
		_premult_mat = CanvasItemMaterial.new()
		_premult_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	return _premult_mat


## Le luci vere (con le ombre) solo nella Sala e solo sul computer: altrove sono tutte finte.
static func real_lights() -> bool:
	return not Fx.mobile


## Una luce in `pos` (coordinate di `parent`) con raggio in pixel. Con `real` falso (o sul
## telefono) è una luce finta, vedi Glow: costa quasi niente e non fa ombra.
static func add_light(parent: Node, pos: Vector2, radius: float, color: Color, energy: float, shadows: bool, real := false) -> Node2D:
	if not real or not real_lights():
		return add_glow(parent, pos, radius, color, energy)
	var l := Flicker.new()
	l.texture = light_tex()
	l.texture_scale = radius / 128.0
	l.color = color
	l.base = energy
	l.energy = energy
	l.seed_f = pos.x * 0.37 + pos.y
	l.shadow_enabled = shadows
	l.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	l.shadow_color = Color(0, 0, 0, 0.75)
	l.position = pos
	parent.add_child(l)
	return l


## La luce finta: un alone colorato, sommato a ciò che c'è sotto.
static func add_glow(parent: Node, pos: Vector2, radius: float, color: Color, energy: float) -> Node2D:
	if _add_mat == null:
		_add_mat = CanvasItemMaterial.new()
		_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var g := Glow.new()
	g.texture = light_tex()
	g.material = _add_mat
	g.scale = Vector2.ONE * radius / 128.0
	g.self_modulate = Color(color.r, color.g, color.b)
	g.base = energy
	g.seed_f = pos.x * 0.37 + pos.y
	g.energy = energy
	g.position = pos
	parent.add_child(g)
	return g


## Un'ombra: il rettangolo blocca la luce (la base di una colonna).
static func occluder(parent: Node, rect: Rect2) -> void:
	var o := LightOccluder2D.new()
	var poly := OccluderPolygon2D.new()
	poly.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	o.occluder = poly
	parent.add_child(o)


## I bordi dello schermo che sfumano nel buio (sopra il gioco, sotto l'interfaccia). Si disegna
## solo la cornice, non il centro: un rettangolo sfumato grande quanto lo schermo costava al
## telefono quanto mezza stanza.
static func vignette(parent: Node, strength: float) -> void:
	if Fx.mobile:
		return              # sul telefono niente: lo schermo è piccolo, scuriva e costava
	var layer := CanvasLayer.new()
	layer.layer = 4
	parent.add_child(layer)
	var v := Vignette.new()
	v.strength = strength
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(v)


class Vignette extends Control:
	var strength := 1.0
	const N := 40

	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		# come la vecchia sfumatura radiale (allungata sullo schermo): trasparente al centro,
		# 0.12 a metà strada, 0.75 a 1.05 volte la metà dello schermo
		var c := size / 2.0
		var dark := Color(0.02, 0.01, 0.04)
		for i in range(N):
			var u0 := Vector2.from_angle(TAU * i / N)
			var u1 := Vector2.from_angle(TAU * (i + 1) / N)
			var e0 := 1.0 / maxf(absf(u0.x), absf(u0.y))
			var e1 := 1.0 / maxf(absf(u1.x), absf(u1.y))
			var pts := PackedVector2Array([c + c * u0 * 0.45, c + c * u1 * 0.45, c + c * u1 * 0.58, c + c * u0 * 0.58])
			var cols := PackedColorArray([Color(dark, 0.0), Color(dark, 0.0), Color(dark, _alpha(0.58)), Color(dark, _alpha(0.58))])
			draw_polygon(pts, cols)
			pts = PackedVector2Array([c + c * u0 * 0.58, c + c * u1 * 0.58, c + c * u1 * e1, c + c * u0 * e0])
			cols = PackedColorArray([Color(dark, _alpha(0.58)), Color(dark, _alpha(0.58)), Color(dark, _alpha(e1)), Color(dark, _alpha(e0))])
			draw_polygon(pts, cols)

	func _alpha(r: float) -> float:
		var k := r / 1.05
		if k <= 0.55:
			return 0.12 * strength * k / 0.55
		return lerpf(0.12, 0.75, clampf((k - 0.55) / 0.45, 0.0, 1.0)) * strength


## Polvere sospesa che sale piano, nella luce.
static func dust(parent: Node, area: Rect2) -> void:
	var p := CPUParticles2D.new()
	p.amount = 60
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = area.size / 2.0
	p.position = area.get_center()
	p.direction = Vector2(0.3, -1)
	p.spread = 60.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 7.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	p.color = Color(1.0, 0.9, 0.7, 0.35)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	p.z_index = 15
	parent.add_child(p)
