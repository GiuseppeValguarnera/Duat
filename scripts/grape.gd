class_name Grape
extends Enemy
## Dannato del torchio (un «grappolo»): le anime che Shezmu spreme. Piccolo, lento, compare solo nel suo
## scontro, a ondate di tre. Ti viene addosso e colpisce con un pugno corto (cerchio rosso, 0,5 s).
## Conta il TEMPO: se resta vivo più di 8 secondi Shezmu lo spreme e si cura; da 6,5 s diventa rosso.

const WINDUP := 0.5
const PUNCH_R := 20.0
const PUNCH := 6.0
const SQUEEZE_AT := 8.0             ## secondi di vita dopo cui Shezmu può spremerlo
const MARK_AT := 6.5

var state := "chase"
var st := 0.6
var age := 0.0
var squeezable := true              ## lo decide Shezmu (finite le spremiture: falso, niente rosso)


func _ready() -> void:
	no_reward = true
	super._ready()
	add_to_group("grapes")


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta
	age += delta
	if to == Vector2.ZERO:
		return Vector2.ZERO
	var d := to.length()
	match state:
		"chase":
			if st <= 0.0 and d < PUNCH_R + 2.0:
				state = "windup"
				st = WINDUP
				return Vector2.ZERO
			return _steer(to / d * speed, delta)
		"windup":
			if st <= 0.0:
				var p = get_tree().get_first_node_in_group("player")
				if p != null and not p.dead and p.global_position.distance_to(global_position) < PUNCH_R:
					p.take_damage(PUNCH, global_position, self)
				Sfx.play_at("swing", global_position, 0.4)
				state = "recover"
				st = 0.6
			return Vector2.ZERO
		"recover":
			if st <= 0.0:
				state = "chase"
				st = 0.5
			return Vector2.ZERO
	return Vector2.ZERO


func marked() -> bool:
	return squeezable and age >= MARK_AT


## Shezmu lo spreme: sparisce in una nuvola rossa (niente premio).
func squeeze() -> void:
	Fx.burst(global_position + Vector2(0, -8), Color(0.7, 0.08, 0.12), 26, 150.0)
	Sfx.play_at("splash", global_position, 0.2)
	die()


func bot_escape(pos: Vector2) -> Vector2:
	if state == "windup" and pos.distance_to(global_position) < PUNCH_R + 8.0:
		var v := pos - global_position
		return v.normalized() if v != Vector2.ZERO else Vector2.RIGHT
	return Vector2.ZERO


func _contact_damage() -> float:
	return 0.0


func _zones() -> void:
	draw_arc(Vector2.ZERO, PUNCH_R, 0.0, TAU, 20, Color(1.0, 0.3, 0.2, 0.6), 1.0)


## Un'anima rattrappita color vinaccia, legata con tralci di vite; gli occhi due buchi chiari. Quando
## sta per essere spremuta pulsa di rosso e un anello le si stringe attorno.
func _draw_body(flash: bool) -> void:
	if state == "windup":
		Enemy.warn_circle(self, Vector2.ZERO, PUNCH_R, 1.0 - st / WINDUP)
	var m := marked()
	var skin := _f(Color(0.42, 0.16, 0.3) if not m else Color(0.75, 0.14, 0.16).lerp(Color(0.42, 0.16, 0.3), 0.5 + 0.5 * sin(t * 12.0)), flash)
	var vine := _f(Color(0.3, 0.42, 0.2), flash)
	if m:
		var k := clampf((age - MARK_AT) / (SQUEEZE_AT - MARK_AT), 0.0, 1.0)
		draw_arc(Vector2(0, -8), 16.0 - 8.0 * k, 0.0, TAU, 18, Color(1.0, 0.25, 0.2, 0.9), 1.5)
	var step := sin(t * 9.0) * 1.5 if velocity.length() > 8.0 else 0.0
	_limb(Vector2(-2, -5), Vector2(-3.0 - step, 0), skin, 1.6)
	_limb(Vector2(2, -5), Vector2(3.0 + step, 0), skin, 1.6)
	_op(_ell(Vector2(0, -9), 5.0, 5.5, 10), skin)
	_op(_ell(Vector2(0, -16), 3.6, 3.4, 10), skin)
	draw_line(Vector2(-5, -11), Vector2(5, -8), vine, 1.3)
	draw_line(Vector2(-5, -7), Vector2(5, -10.5), vine, 1.3)
	draw_circle(Vector2(-1.4, -16.2), 0.9, Color(1, 0.95, 0.8))
	draw_circle(Vector2(1.4, -16.2), 0.9, Color(1, 0.95, 0.8))
	var up := 0.0
	if state == "windup":
		up = 1.0 - st / WINDUP
	_limb(Vector2(-4.5, -11), Vector2(-7.0, -8.0 - 6.0 * up), skin, 1.5)
	_limb(Vector2(4.5, -11), Vector2(7.0, -8.0 - 6.0 * up), skin, 1.5)
