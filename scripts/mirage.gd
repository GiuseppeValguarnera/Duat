class_name MirageEnemy
extends Enemy
## Il Miraggio: una donna velata, fatta di luce tremolante del deserto. Crea 2-3 copie di sé che si
## muovono come lei; solo la vera proietta un'ombra a terra. Colpire una copia la dissolve; colpire
## la vera dissolve tutte le copie. Dopo qualche secondo le richiama. Da lontano lancia baci di
## sabbia (solo la vera: le copie non fanno male).

const BoltScript := preload("res://scripts/enemy_bolt.gd")

@export var keep_min := 100.0
@export var keep_max := 170.0
@export var copy_every := 6.0
@export var cast_time := 0.6
@export var fire_every := 3.2
@export var bolt_damage := 10.0
const MIN_THROW := 72.0                  ## blocco 12: il bacio vola 160 px/s, da più vicino non darebbe 0,45 s per schivarlo

var copy_cd := 1.0
var casting := 0.0
var fire_cd := 2.0
var copies: Array = []
var facing := 1.0


func _behave(delta: float, to: Vector2) -> Vector2:
	copy_cd -= delta
	fire_cd -= delta
	copies = copies.filter(func(c) -> bool: return is_instance_valid(c))
	if casting > 0.0:
		casting -= delta
		if casting <= 0.0:
			_make_copies()
		return Vector2.ZERO
	if to == Vector2.ZERO:
		return Vector2.ZERO
	facing = 1.0 if to.x >= 0.0 else -1.0
	if copy_cd <= 0.0 and copies.size() < 2:
		casting = cast_time
		copy_cd = copy_every
		Sfx.play_at("soul", global_position, 0.1)
		return Vector2.ZERO
	if fire_cd <= 0.0 and to.length() < 260.0 and to.length() >= MIN_THROW:
		fire_cd = fire_every + randf() * 0.6
		_kiss(to.normalized())
	var d := to.length()
	var u := to / d
	var want := 0.0
	if d < keep_min:
		want = -1.0
	elif d > keep_max:
		want = 1.0
	var v := u * want + u.orthogonal() * sin(t * 1.1 + seed_offset) * 0.8
	if v.length() < 0.05:
		return Vector2.ZERO
	return _steer(v.normalized() * speed, delta)


## Le copie compaiono attorno a lei; a volte lei prende il posto di una di loro.
func _make_copies() -> void:
	var n := randi_range(2, 3) - copies.size()
	for i in range(n):
		var c := MirageCopy.new()
		c.real = self
		c.offset = Vector2.from_angle(randf() * TAU) * randf_range(40.0, 70.0)
		c.seed_offset = randf() * TAU
		get_parent().add_child(c)
		c.global_position = global_position + c.offset
		copies.append(c)
		Fx.burst(c.global_position + Vector2(0, -10), Color(0.95, 0.9, 0.8, 0.7), 8, 50.0)
	if not copies.is_empty() and randf() < 0.6:
		var other: Node2D = copies.pick_random()
		var here := global_position
		global_position = other.global_position
		other.global_position = here
		reset_physics_interpolation()


func _kiss(dir: Vector2) -> void:
	var bolt: Area2D = BoltScript.new()
	bolt.direction = dir
	bolt.speed = 160.0
	bolt.damage = bolt_damage
	bolt.shooter = self
	bolt.style = "sand"
	get_parent().add_child(bolt)
	bolt.global_position = global_position + Vector2(0, -12) + dir * 8.0


func _on_hit(_dmg: float) -> void:
	# colpita la vera, le copie svaniscono
	for c in copies:
		if is_instance_valid(c):
			c.vanish()
	copies.clear()
	copy_cd = maxf(copy_cd, 3.0)
	casting = 0.0


func die() -> void:
	for c in copies:
		if is_instance_valid(c):
			c.vanish()
	copies.clear()
	super.die()


func _draw_body(flash: bool) -> void:
	MirageEnemy.Mirage.draw_lady(self, t, seed_offset, facing, flash, casting > 0.0)


## Il disegno della donna velata (lo stesso per la vera e per le copie).
class Mirage:
	static func draw_lady(ci: CanvasItem, t: float, seed_off: float, facing: float, flash: bool, casting: bool) -> void:
		var shimmer := 0.82 + 0.18 * sin(t * 5.0 + seed_off)
		var veil := Color(0.95, 0.93, 0.88, 0.9 * shimmer) if not flash else Color.WHITE
		var dress := Color(0.2, 0.36, 0.8, 0.9 * shimmer) if not flash else Color.WHITE
		var gold := Color(0.94, 0.72, 0.3, shimmer)
		var out := Color(0.12, 0.08, 0.05, 0.8)
		var bob := sin(t * 2.0 + seed_off) * 1.2
		ci.draw_set_transform(Vector2(0, bob - 2.0), 0.0, Vector2(facing, 1.0))
		# l'abito lungo e il velo che scende dalle spalle, mosso dal vento
		var wave := sin(t * 3.0 + seed_off) * 1.5
		var dress_p := PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(3.5, -16), Vector2(-3.5, -16)])
		ci.draw_colored_polygon(dress_p, dress)
		var veil_p := PackedVector2Array([Vector2(-4.5, -22), Vector2(4.5, -22), Vector2(7.0 + wave, -6), Vector2(-8.0 + wave, -4)])
		ci.draw_colored_polygon(veil_p, Color(veil, veil.a * 0.55))
		ci.draw_line(Vector2(-4, -12), Vector2(4, -12), gold, 1.2)
		# testa velata, con il diadema d'oro e solo gli occhi
		ci.draw_circle(Vector2(0, -22), 4.4, out)
		ci.draw_circle(Vector2(0, -22), 3.8, veil)
		ci.draw_line(Vector2(-3.8, -24.5), Vector2(3.8, -24.5), gold, 1.0)
		ci.draw_circle(Vector2(1.8, -22.2), 0.7, Color(0.2, 0.36, 0.8))
		if casting:
			for i in range(6):
				var a := t * 7.0 + i * TAU / 6.0
				ci.draw_circle(Vector2(0, -14) + Vector2.from_angle(a) * 10.0, 1.0, Color(1, 0.95, 0.8, 0.8))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Una copia del Miraggio: si muove come lei, NON ha l'ombra, non fa male. Colpita si dissolve. Non
## conta tra i nemici della stanza (la stanza si chiude senza doverle colpire).
class MirageCopy extends Enemy:
	var real: Node2D = null
	var offset := Vector2.ZERO
	var facing := 1.0

	func _ready() -> void:
		max_hp = 1.0
		radius = 7.0
		contact_damage = 0.0
		super._ready()
		collision_layer = 0
		collision_mask = 0

	func _behave(delta: float, to: Vector2) -> Vector2:
		if real == null or not is_instance_valid(real) or real.dead:
			vanish()
			return Vector2.ZERO
		if to != Vector2.ZERO:
			facing = 1.0 if to.x >= 0.0 else -1.0
		# ruota piano attorno alla vera, imitandone il passo
		offset = offset.rotated(0.4 * delta)
		var want: Vector2 = real.global_position + offset - global_position
		return want * 3.0

	func take_hit(_dmg: float, _dir: Vector2, _kb: float, _can_burn: bool = false) -> void:
		vanish()

	## Mai una morte vera (niente Ka, niente conto dei nemici della stanza): svanisce e basta.
	func die() -> void:
		vanish()

	func vanish() -> void:
		if dead:
			return
		dead = true
		Fx.burst(global_position + Vector2(0, -10), Color(0.95, 0.9, 0.8, 0.7), 10, 60.0)
		queue_free()

	func _unstick(_delta: float, _wanted: float) -> void:
		pass

	func _draw() -> void:
		# niente ombra: è così che si riconosce la vera
		MirageEnemy.Mirage.draw_lady(self, t, seed_offset, facing, false, false)
