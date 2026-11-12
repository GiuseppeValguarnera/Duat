extends Enemy
## Shetyu, la tartaruga del caos (nemica di Ra: «Viva Ra, muoia la tartaruga»). Lenta e corazzata:
## nel guscio i colpi fanno metà danno. Poi si ritira nel guscio (striscia rossa lunga, 0,7 s) e parte
## come una trottola: rimbalza tre volte sui muri. Quando si ferma resta SUL DORSO per 1,8 s e i colpi
## fanno una volta e mezza: schiva la trottola, poi puniscila.

const WINDUP := 0.7
const SPIN_SPEED := 250.0
const SPIN_MAX := 2.4
const BOUNCES := 3
const SPIN_DMG := 12.0
const DIZZY := 1.8
const SHELL := 0.5
const SOFT := 1.5

var state := "walk"
var st := 0.0
var aim := Vector2.RIGHT
var bounces := 0
var hit_cd := 0.0


func _ready() -> void:
	super._ready()
	st = randf_range(1.5, 3.0)


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta
	hit_cd = maxf(0.0, hit_cd - delta)
	if to == Vector2.ZERO:
		return Vector2.ZERO
	var u := to.normalized()
	match state:
		"walk":
			aim = u
			if st <= 0.0 and to.length() < 230.0:
				state = "windup"
				st = WINDUP
				Sfx.play_at("scorpion_windup", global_position, 0.3)
				return Vector2.ZERO
			return _steer(u * speed, delta)
		"windup":
			if st > WINDUP * 0.5:
				aim = u
			if st <= 0.0:
				state = "spin"
				st = SPIN_MAX
				bounces = 0
				Sfx.play_at("dash", global_position, 0.3)
			return Vector2.ZERO
		"spin":
			# rimbalzo: la collisione del fotogramma prima dà la normale
			for i in range(get_slide_collision_count()):
				var col := get_slide_collision(i)
				if col.get_collider() is StaticBody2D and aim.dot(col.get_normal()) < -0.1:
					aim = aim.bounce(col.get_normal()).normalized()
					bounces += 1
					Fx.burst(global_position, Color(0.6, 0.5, 0.7), 6, 70.0)
					Sfx.play_at("hit", global_position, 0.3)
					break
			var p = get_tree().get_first_node_in_group("player")
			if hit_cd <= 0.0 and p != null and touches(p):
				if p.take_damage(SPIN_DMG, global_position, self):
					hit_cd = 0.6
			if st <= 0.0 or bounces >= BOUNCES:
				state = "dizzy"
				st = DIZZY
			return aim * SPIN_SPEED
		"dizzy":
			if st <= 0.0:
				state = "walk"
				st = randf_range(2.5, 4.0)
			return Vector2.ZERO
	return Vector2.ZERO


func take_hit(dmg: float, dir: Vector2, kb: float, can_burn: bool = false) -> void:
	var k := SOFT if state == "dizzy" else SHELL
	if state != "dizzy" and not dead:
		Fx.float_text(global_position + Vector2(0, -22), Lang.t("GUSCIO"), Color(0.7, 0.75, 0.85))
	super.take_hit(dmg * k, dir, kb * (0.2 if state == "spin" else 1.0), can_burn)


func _contact_damage() -> float:
	return 0.0


func _stagger_time() -> float:
	return 0.0 if state == "spin" or state == "windup" else 0.2


func _strip(k: float) -> void:
	Enemy.warn_strip(self, Vector2.ZERO, aim, 150.0, touch_dist(), k)


func _zones() -> void:
	_strip(0.0)


## Guscio scuro a placche con venature viola, testa e zampe che spuntano; nell'avviso rientrano, in
## trottola gira, da stordita è a pancia in su (ventre chiaro) con le zampe che scalciano.
func _draw_body(flash: bool) -> void:
	if state == "windup":
		_strip(1.0 - st / WINDUP)
	var shell := _f(Color(0.2, 0.22, 0.3), flash)
	var plate := _f(Color(0.34, 0.3, 0.46), flash)
	var skin := _f(Color(0.36, 0.42, 0.3), flash)
	var c := Vector2(0, -7)
	if state == "dizzy":
		for i in range(4):
			var a := PI * 0.25 + i * PI * 0.5
			var kick := sin(t * 14.0 + i) * 2.0
			_limb(c + Vector2.from_angle(a) * 7.0, c + Vector2.from_angle(a) * (12.0 + kick), skin, 2.0)
		_op(_ell(c, 11.0, 7.5, 16), _f(Color(0.78, 0.72, 0.5), flash))
		draw_line(c + Vector2(-8, 0), c + Vector2(8, 0), Color(0.5, 0.45, 0.3), 0.8)
		draw_line(c + Vector2(0, -6), c + Vector2(0, 6), Color(0.5, 0.45, 0.3), 0.8)
		for i in range(3):
			var sa := t * 4.0 + i * TAU / 3.0
			UiStyle.star4(self, c + Vector2(cos(sa) * 9.0, -11.0 + sin(sa) * 2.5), 1.6, Color(1, 0.9, 0.5))
		return
	var inside := state == "windup" or state == "spin"
	var rot := t * 22.0 if state == "spin" else 0.0
	if not inside:
		var dir := 1.0 if aim.x >= 0.0 else -1.0
		var walk := sin(t * 5.0) * 1.5
		for lx in [-7.0, 6.0]:
			_limb(c + Vector2(lx, 4), c + Vector2(lx + walk * (1.0 if lx > 0 else -1.0), 8), skin, 2.2)
		_op(_ell(c + Vector2(dir * 12.0, 1.0), 3.6, 2.8, 10), skin)
		draw_circle(c + Vector2(dir * 13.2, 0.2), 0.8, Color(1.0, 0.85, 0.3))
	_op(_ell(c, 11.0, 7.5, 16), shell)
	for i in range(6):
		var a := rot + TAU * i / 6.0
		draw_circle(c + Vector2(cos(a) * 6.0, sin(a) * 3.8), 2.4, plate)
	draw_circle(c, 2.8, plate)
	draw_arc(c, 9.0, rot, rot + PI * 1.2, 10, Color(0.65, 0.35, 0.9, 0.7), 1.0)
	if state == "spin":
		draw_arc(c, 13.5, rot * 0.5, rot * 0.5 + PI, 12, Color(1, 1, 1, 0.35), 1.2)
