extends Enemy
## Mummia: lenta e resistente. Ti insegue, e quando sei vicino carica un affondo.
## Prima dell'affondo diventa rossa e mostra la direzione: è il segnale per schivare.

@export var lunge_range := 70.0
@export var windup_time := 0.5         ## quanto dura l'avviso prima dell'affondo
@export var lunge_speed := 260.0
@export var lunge_time := 0.28

var state := "chase"
var step_t := 0.0
var st := 0.0
var lunge_dir := Vector2.RIGHT


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta
	match state:
		"chase":
			if to == Vector2.ZERO:
				return Vector2.ZERO
			if to.length() < lunge_range and st <= 0.0:
				state = "windup"
				st = windup_time
				lunge_dir = to.normalized()
				Sfx.play_at("mummy_windup", global_position, 0.12)
				return Vector2.ZERO
			step_t -= delta
			if step_t <= 0.0:
				step_t = randf_range(0.45, 0.6)
				Sfx.play_at("mummy_step", global_position, 0.15)
			return to.normalized() * speed * (0.85 + 0.2 * sin(t * 3.0))
		"windup":
			# segue il giocatore solo nella prima parte dell'avviso, poi la direzione è fissa
			if st > windup_time * 0.4 and to != Vector2.ZERO:
				lunge_dir = to.normalized()
			if st <= 0.0:
				state = "lunge"
				st = lunge_time
				Sfx.play_at("mummy_lunge", global_position, 0.1)
			return Vector2.ZERO
		"lunge":
			if st <= 0.0:
				state = "recover"
				st = 0.6
			return lunge_dir * lunge_speed
		"recover":
			if st <= 0.0:
				state = "chase"
				st = 0.8
	return Vector2.ZERO


## Durante l'affondo non barcolla: o lo schivi, o lo subisci.
func _stagger_time() -> float:
	return 0.0 if state == "lunge" else 0.35


func _contact_damage() -> float:
	return contact_damage * (1.5 if state == "lunge" else 1.0)


func _on_hit(dmg: float) -> void:
	if state == "lunge":
		knock *= 0.3
	# un colpo pesante interrompe l'avviso: premia chi attacca al momento giusto
	if state == "windup" and dmg >= 20.0:
		state = "recover"
		st = 0.5


## La mummia: bende di lino invecchiato avvolte in diagonale, braccia tese in avanti, una benda
## che pende e ondeggia, occhi verdi nella fessura del volto. Strascica i piedi.
## Nell'avviso diventa rossa e mostra la direzione dell'affondo (si deve vedere bene).
func _draw_body(flash: bool) -> void:
	var linen := Color(0.84, 0.78, 0.62)
	var linen_d := Color(0.62, 0.54, 0.4)
	var dir := 1.0 if velocity.x >= 0.0 else -1.0
	if state == "windup":
		var k := 1.0 - st / windup_time
		linen = linen.lerp(Color(1, 0.3, 0.18), 0.4 + 0.5 * k)
		linen_d = linen_d.lerp(Color(0.7, 0.15, 0.1), 0.4 + 0.5 * k)
		draw_line(Vector2(0, -6), Vector2(0, -6) + lunge_dir * lunge_speed * lunge_time, Color(1, 0.2, 0.15, 0.5), 2.0)
		dir = 1.0 if lunge_dir.x >= 0.0 else -1.0
	elif state == "lunge":
		dir = 1.0 if lunge_dir.x >= 0.0 else -1.0
	linen = _f(linen, flash)
	linen_d = _f(linen_d, flash)
	var bob := sin(t * 6.0) * 1.0
	var w := sin(t * 6.0)
	draw_set_transform(Vector2(0, bob * 0.5), 0.0, Vector2(dir * 0.82, 0.82))
	# gambe fasciate che strisciano
	for lx in [-3.0 + w * 1.2, 3.0 - w * 1.2]:
		_op(PackedVector2Array([Vector2(lx - 2.4, -11), Vector2(lx + 2.4, -11), Vector2(lx + 2.2, 0), Vector2(lx - 2.6, 0)]), linen_d)
	# il busto, un po' curvo in avanti
	var body := PackedVector2Array([Vector2(-6.5, -25), Vector2(5.5, -26), Vector2(7.5, -17), Vector2(6.5, -10), Vector2(-6.5, -10), Vector2(-7.5, -18)])
	_op(body, linen)
	# le bende in diagonale, con qualche ombra
	for i in range(6):
		var y := -24.0 + i * 2.6
		draw_line(Vector2(-7, y + 1.8), Vector2(7, y - 0.4), linen_d, 0.9)
	# una benda che si scioglie e pende dietro
	var tail := PackedVector2Array([Vector2(-6, -20), Vector2(-9 - w, -15), Vector2(-11 - w * 1.5, -9), Vector2(-9.5 - w, -9), Vector2(-7.5, -15)])
	_op(tail, linen_d, 0.6)
	# braccia tese in avanti
	for k in [0.0, 1.0]:
		var sh := Vector2(4.0 - k * 2.0, -22.5 + k * 1.5)
		var hand := Vector2(13.0 - k * 1.5, -19.5 + k * 1.5 + w * 0.6)
		_limb(sh, hand, linen if k == 0.0 else linen_d, 3.0)
	# testa avvolta, con la fessura scura e gli occhi verdi
	_op(_ell(Vector2(1.0, -29.5), 5.2, 5.0, 14), linen)
	draw_line(Vector2(-4.0, -31.5), Vector2(5.5, -32.5), linen_d, 0.8)
	draw_line(Vector2(-4.5, -27.0), Vector2(5.5, -26.5), linen_d, 0.8)
	draw_colored_polygon(PackedVector2Array([Vector2(-1.0, -30.6), Vector2(6.0, -31.0), Vector2(6.0, -28.4), Vector2(-1.0, -28.4)]), Color(0.08, 0.06, 0.05))
	var eye := Color(0.6, 1.0, 0.45) if not flash else Color.WHITE
	draw_circle(Vector2(1.6, -29.6), 0.9, eye)
	draw_circle(Vector2(4.4, -29.7), 0.9, eye)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
