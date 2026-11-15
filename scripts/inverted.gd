extends Enemy
## Il Capovolto: nel Duat i dannati camminano a testa in giù, sulle mani, e tutto per loro va al
## contrario. Questo sta SEMPRE dalla parte opposta della stanza rispetto a te (specchiato sul centro):
## se lo insegui scappa, se vai al CENTRO viene lui da te. Da lontano lancia la propria ombra in linea
## (striscia rossa, 0,7 s). Si batte capendo la regola, non correndo. Solo nel Banco di Apopi.

const BoltScript := preload("res://scripts/enemy_bolt.gd")
const WINDUP := 0.7
const SHOT_SPEED := 165.0
const SHOT_LIFE := 2.6
const SHOT_DMG := 9.0

var state := "mirror"
var st := 0.0
var aim := Vector2.RIGHT
var center := Vector2.ZERO


func _ready() -> void:
	super._ready()
	st = randf_range(2.0, 3.2)
	var g = get_tree().current_scene
	if g != null and "ROOM" in g:
		center = Vector2(g.ROOM.size.x / 2.0, (g.TOP + g.ROOM.size.y - g.WALL) / 2.0)
	else:
		center = global_position


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta
	if to == Vector2.ZERO:
		return Vector2.ZERO
	var u := to.normalized()
	match state:
		"mirror":
			aim = u
			if st <= 0.0 and to.length() > 70.0:
				state = "windup"
				st = WINDUP
				Sfx.play_at("soul", global_position, 0.3)
				return Vector2.ZERO
			var p_pos: Vector2 = global_position + to
			var want: Vector2 = center * 2.0 - p_pos
			var g = get_tree().current_scene
			if g != null and g.has_method("_in_floor") and not g._in_floor(want, 12.0):
				want = center + (want - center) * 0.8
			var d: Vector2 = want - global_position
			if d.length() < 6.0:
				return Vector2.ZERO
			return _steer(d.normalized() * speed * clampf(d.length() / 30.0, 0.3, 1.0), delta)
		"windup":
			if st > WINDUP * 0.45:
				aim = u
			if st <= 0.0:
				_shoot()
				state = "recover"
				st = 0.6
			return Vector2.ZERO
		"recover":
			if st <= 0.0:
				state = "mirror"
				st = randf_range(2.8, 3.8)
			return Vector2.ZERO
	return Vector2.ZERO


func _shoot() -> void:
	Sfx.play_at("cobra_spit", global_position, 0.2)
	var bolt: Area2D = BoltScript.new()
	bolt.direction = aim
	bolt.speed = SHOT_SPEED
	bolt.damage = SHOT_DMG
	bolt.shooter = self
	bolt.style = "isfet"
	bolt.life = SHOT_LIFE
	get_parent().add_child(bolt)
	bolt.global_position = global_position + Vector2(0, -8) + aim * 10.0


func bot_escape(pos: Vector2) -> Vector2:
	var v := pos - global_position
	if state == "windup" and st < 0.35 and absf(v.dot(aim.orthogonal())) < 16.0 and v.dot(aim) > 0.0:
		return aim.orthogonal() * (1.0 if v.dot(aim.orthogonal()) >= 0.0 else -1.0)
	return Vector2.ZERO


func _contact_damage() -> float:
	return 0.0


func _zones() -> void:
	Enemy.warn_strip(self, Vector2(0, -8), aim, SHOT_SPEED * SHOT_LIFE, 6.0, 0.0)


## Un uomo capovolto: cammina sulle mani, le gambe in aria che ondeggiano, la testa in basso con gli
## occhi bianchi. Pelle grigio cenere, bende viola. Un filo d'ombra lo lega al centro della stanza
## (appena visibile): è l'indizio della regola dello specchio.
func _draw_body(flash: bool) -> void:
	if state == "windup":
		Enemy.warn_strip(self, Vector2(0, -8) + aim * 10.0, aim, SHOT_SPEED * SHOT_LIFE, 6.0, 1.0 - st / WINDUP)
	var cl := to_local(center)
	draw_line(Vector2(0, -2), cl, Color(0.6, 0.35, 0.9, 0.16), 1.0)
	var skin := _f(Color(0.5, 0.48, 0.52), flash)
	var bands := _f(Color(0.4, 0.22, 0.6), flash)
	var step := sin(t * 9.0) * 2.0 if velocity.length() > 8.0 else 0.0
	var sway := sin(t * 2.5) * 2.0
	# braccia (fanno da gambe)
	_limb(Vector2(-3, -9), Vector2(-4.0 - step, 0), skin, 1.8)
	_limb(Vector2(3, -9), Vector2(4.0 + step, 0), skin, 1.8)
	# testa in basso, tra le braccia
	_op(_ell(Vector2(0, -5.5), 3.4, 3.2, 10), skin)
	var eye := Color(1.0, 0.3, 0.15) if state == "windup" else Color(1, 1, 1)
	draw_circle(Vector2(-1.4, -5.0), 0.9, eye)
	draw_circle(Vector2(1.4, -5.0), 0.9, eye)
	# torso e bende
	_op(PackedVector2Array([Vector2(-4, -9), Vector2(4, -9), Vector2(4.5, -19), Vector2(-4.5, -19)]), skin)
	draw_line(Vector2(-4, -12), Vector2(4, -13.5), bands, 1.6)
	draw_line(Vector2(-4.3, -16), Vector2(4.3, -17.5), bands, 1.6)
	# gambe in aria
	_limb(Vector2(-2.5, -19), Vector2(-4.0 + sway, -29), skin, 1.8)
	_limb(Vector2(2.5, -19), Vector2(4.5 + sway * 0.6, -28), skin, 1.8)
