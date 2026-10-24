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


func _draw_body(flash: bool) -> void:
	var body := Color(0.86, 0.81, 0.67)
	if state == "windup":
		var k := 1.0 - st / windup_time
		body = body.lerp(Color(1, 0.25, 0.15), 0.4 + 0.5 * k)
		draw_line(Vector2(0, -6), Vector2(0, -6) + lunge_dir * lunge_speed * lunge_time, Color(1, 0.2, 0.15, 0.5), 2.0)
	if flash:
		body = Color.WHITE
	var bob := sin(t * 6.0) * 1.0
	draw_rect(Rect2(-8, -24 + bob, 16, 24), body)
	for i in range(5):
		draw_line(Vector2(-8, -20 + i * 5 + bob), Vector2(8, -17 + i * 5 + bob), Color(0.45, 0.35, 0.2, 0.5), 1.0)
	draw_rect(Rect2(-4, -19 + bob, 2, 2), Color(0.65, 1, 0.45))
	draw_rect(Rect2(2, -19 + bob, 2, 2), Color(0.65, 1, 0.45))
