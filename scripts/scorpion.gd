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


func _draw_body(flash: bool) -> void:
	var shell := Color.WHITE if flash else Color(0.55, 0.3, 0.18)
	var dark := Color.WHITE if flash else Color(0.3, 0.15, 0.08)
	var dir := 1.0 if velocity.x >= 0.0 else -1.0
	if state == "windup" or state == "strike":
		dir = 1.0 if sting_dir.x >= 0.0 else -1.0
	# zampe
	for i in range(3):
		var lx := -4.0 + i * 4.0
		var w := sin(t * 18.0 + i) * 1.5
		draw_line(Vector2(lx, -3), Vector2(lx - 3 + w, 1), dark, 1.0)
		draw_line(Vector2(lx, -3), Vector2(lx + 3 - w, 1), dark, 1.0)
	draw_set_transform(Vector2(0, -4), 0.0, Vector2(1.0, 0.65))
	draw_circle(Vector2.ZERO, 6.5, shell)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# chele
	draw_circle(Vector2(8 * dir, -4), 2.5, dark)
	draw_circle(Vector2(8 * dir, -1), 2.0, dark)
	# coda: si alza durante l'avviso
	var raise := 0.0
	if state == "windup":
		raise = 1.0 - st / sting_windup
	elif state == "strike":
		raise = 1.0
	var base := Vector2(-6 * dir, -4)
	var mid := base + Vector2(-4 * dir, -6 - raise * 4.0)
	var tip := mid + Vector2(3 * dir + raise * 6.0 * dir, -5 - raise * 3.0)
	draw_line(base, mid, shell, 2.5)
	draw_line(mid, tip, shell, 2.0)
	var tip_col := Color(0.6, 1, 0.4) if raise > 0.0 else dark
	draw_circle(tip, 2.0 + raise * 1.5, tip_col)
