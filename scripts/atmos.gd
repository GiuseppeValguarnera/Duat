class_name Atmos
extends RefCounted
## L'atmosfera: luce vera (Light2D di Godot) al posto degli aloni disegnati. Una penombra di
## fondo (CanvasModulate), torce e bracieri che fanno pozze di luce e tremolano, le colonne che
## fanno ombra, i bordi dello schermo che sfumano nel buio e la polvere sospesa nell'aria.
## Il buio è atmosfera, non un ostacolo: la penombra resta leggera e ciò che conta è illuminato.

## Quanto è buia la penombra: stanze della discesa (calda) e Sala del Giudizio (notte blu).
const AMBIENT_ROOM := Color(0.58, 0.52, 0.58)
const AMBIENT_HUB := Color(0.45, 0.46, 0.64)
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


## Una luce in `pos` (coordinate di `parent`) con raggio in pixel.
static func add_light(parent: Node, pos: Vector2, radius: float, color: Color, energy: float, shadows: bool) -> PointLight2D:
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


## Un'ombra: il rettangolo blocca la luce (la base di una colonna).
static func occluder(parent: Node, rect: Rect2) -> void:
	var o := LightOccluder2D.new()
	var poly := OccluderPolygon2D.new()
	poly.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	o.occluder = poly
	parent.add_child(o)


## I bordi dello schermo che sfumano nel buio (sopra il gioco, sotto l'interfaccia).
static func vignette(parent: Node, strength: float) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 4
	parent.add_child(layer)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.12 * strength), Color(0.02, 0.01, 0.04, 0.75 * strength)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.05, 0.5)
	var r := TextureRect.new()
	r.texture = tex
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(r)


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
