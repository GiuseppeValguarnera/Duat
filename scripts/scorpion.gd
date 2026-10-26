extends Enemy
## Scorpione di Serket: veloce, ti gira intorno e punge con la coda.
## Avviso: la coda si alza e si illumina. La puntura avvelena: perdi vita per qualche
## secondo (il veleno non può ucciderti, ma ti lascia scoperto al resto).
## Quando punge scatta in avanti: allontanarsi di un passo non basta, bisogna scattare di lato.
## Più punture si sommano: il veleno dura di più.
## Serket era la dea scorpione che proteggeva dai veleni... e li sapeva usare.

@export var sting_range := 38.0
@export var sting_windup := 0.38
@export var sting_damage := 8.0
@export var poison_time := 3.5
@export var strike_speed := 260.0        ## velocità del balzo con cui punge
@export var strike_time := 0.12

var state := "chase"
var st := 0.0
var circle_dir := 1.0
var sting_dir := Vector2.RIGHT
var step_t := 0.0


func _ready() -> void:
	super._ready()
	circle_dir = 1.0 if randf() < 0.5 else -1.0


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta
	if to == Vector2.ZERO:
		return Vector2.ZERO
	var d := to.length()
	var u := to / d
	match state:
		"chase":
			step_t -= delta
			if step_t <= 0.0:
				step_t = randf_range(0.2, 0.32)
				Sfx.play_at("scorpion_step", global_position, 0.3)
			if d < sting_range and st <= 0.0:
				state = "windup"
				st = sting_windup
				sting_dir = u
				Sfx.play_at("scorpion_windup", global_position, 0.2)
				return Vector2.ZERO
			# da vicino gira intorno al giocatore, da lontano si avvicina
			if d < 70.0:
				return (u * 0.6 + u.orthogonal() * circle_dir).normalized() * speed
			return u * speed
		"windup":
			if st > sting_windup * 0.4:
				sting_dir = u
			if st <= 0.0:
				state = "strike"
				st = strike_time
			return Vector2.ZERO
		"strike":
			# balzo in avanti con la coda tesa: la puntura arriva alla fine del balzo
			if st <= 0.0 or d < 14.0:
				_sting(to)
				state = "recover"
				st = 0.45
				return Vector2.ZERO
			return sting_dir * strike_speed
		"recover":
			if st <= 0.0:
				state = "chase"
				st = 0.6
				circle_dir = -circle_dir
			return -u * speed * 0.4
	return Vector2.ZERO


func _sting(to: Vector2) -> void:
	Sfx.play_at("scorpion_sting", global_position, 0.2)
	# da vicinissimo la puntura prende sempre; più in là solo davanti alla coda
	if to.length() > sting_range + 8.0 or (to.length() > 16.0 and absf(sting_dir.angle_to(to)) > deg_to_rad(60.0)):
		return
	var player = get_tree().get_first_node_in_group("player")
	if player != null and not player.dead and player.take_damage(sting_damage, global_position, self):
		player.poison(poison_time)


## Lo scorpione di Serket: corazza ambrata a segmenti con le fasce turchesi della dea, otto zampe,
## le chele aperte davanti e la coda a cinque anelli che finisce nel pungiglione ricurvo.
## Avviso: la coda si alza e il pungiglione si accende di verde.
func _draw_body(flash: bool) -> void:
	var shell := _f(Color(0.62, 0.36, 0.17), flash)
	var shell_l := _f(Color(0.86, 0.56, 0.27), flash)
	var shell_d := _f(Color(0.36, 0.18, 0.08), flash)
	var band := _f(Color(0.2, 0.6, 0.6), flash)
	var dir := 1.0 if velocity.x >= 0.0 else -1.0
	if state == "windup" or state == "strike":
		dir = 1.0 if sting_dir.x >= 0.0 else -1.0
	var raise := 0.0
	if state == "windup":
		raise = 1.0 - st / sting_windup
	elif state == "strike":
		raise = 1.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(dir, 1.0))
	# otto zampe sottili, a passi alternati
	for i in range(4):
		var lx := -4.5 + i * 3.0
		var w := sin(t * 18.0 + i * 1.7) * 1.4
		_limb(Vector2(lx, -4.0), Vector2(lx - 2.0 + w, -6.5), shell_d, 0.7)
		_limb(Vector2(lx - 2.0 + w, -6.5), Vector2(lx - 3.0 + w, -0.5), shell_d, 0.7)
		_limb(Vector2(lx, -3.0), Vector2(lx + 1.5 - w, 0.8), shell_d, 0.8)
	# corpo a segmenti
	_op(_ell(Vector2(-0.5, -4.2), 6.8, 3.6, 16), shell)
	for k in range(3):
		var x := -4.0 + k * 2.6
		draw_line(Vector2(x, -7.2), Vector2(x - 0.4, -1.4), shell_d, 0.7)
	draw_line(Vector2(-5.5, -5.5), Vector2(3.5, -5.5), band, 0.8)
	draw_arc(Vector2(-1.0, -5.2), 4.0, PI * 1.1, PI * 1.6, 6, shell_l, 0.8)
	# le chele: braccio e pinza aperta
	for k in [0.0, 1.0]:
		var base := Vector2(5.0, -5.0 + k * 2.0)
		var elbow := Vector2(8.0, -7.0 + k * 4.0)
		_limb(base, elbow, shell, 1.3)
		var claw := PackedVector2Array([elbow, elbow + Vector2(3.4, -1.6), elbow + Vector2(4.4, -0.2), elbow + Vector2(2.2, 0.2), elbow + Vector2(3.8, 1.4), elbow + Vector2(1.2, 1.6)])
		_op(claw, shell_l, 0.6)
	# la coda: cinque anelli che salgono ad arco sopra il dorso
	var seg := PackedVector2Array()
	for k in range(6):
		var u := k / 5.0
		var ang := lerpf(PI * 0.95, PI * (0.35 - raise * 0.2), u)
		var r := 7.0 + raise * 3.0
		seg.append(Vector2(-7.0, -4.0) + Vector2(cos(ang) * r * 0.6 + u * (4.0 + raise * 4.0), -sin(ang) * r - u * (3.0 + raise * 3.0)))
	for k in range(5):
		_limb(seg[k], seg[k + 1], shell, 2.4 - k * 0.25)
	for k in range(1, 5):
		draw_circle(seg[k], 0.5, shell_l)
	# il pungiglione ricurvo
	var tip: Vector2 = seg[5]
	var lit := raise > 0.0
	var sting := Color(0.6, 1.0, 0.4) if lit else shell_d
	if flash:
		sting = Color.WHITE
	if lit:
		draw_circle(tip, 3.0 + raise * 2.0, Color(0.6, 1.0, 0.4, 0.25))
	_op(PackedVector2Array([tip + Vector2(-1.4, -1.0), tip + Vector2(1.6, -1.2), tip + Vector2(2.6, 1.6), tip + Vector2(0.6, 0.6), tip + Vector2(-1.0, 1.2)]), sting, 0.6)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
