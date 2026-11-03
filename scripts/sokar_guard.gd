extends Enemy
## Guardiano di Sokar: una mummia antica con lo scudo di bronzo e la lancia corta. Lenta e testarda.
## - lo scudo para i colpi che arrivano da davanti (quasi niente danno, una scintilla e un clang);
## - si gira piano: girandogli intorno, o scattandogli dietro, lo colpisci alle spalle;
## - ogni tanto alza lo scudo e carica (l'avviso: lo scudo si alza e brilla, poi la carica);
## - dopo la carica resta scoperto un attimo, con lo scudo abbassato: è il momento.
## Insegna a girare intorno. L'Occhio di Horus, che arriva da lontano, si para come la lama.

@export var turn_rate := 1.7                ## quanto in fretta si gira verso di te (radianti al secondo)
@export var charge_windup := 0.9            ## blocco 12: la direzione si blocca a metà, poi restano 0,45 s
@export var charge_speed := 230.0
@export var charge_time := 0.435           ## carica di 100 px
const CHARGE_FROM := 110.0                  ## comincia la preparazione solo da qui dentro
## Lo scudo ha una resistenza (blocco 12): i colpi parati la consumano col loro danno pieno (×2 per
## l'attacco caricato; la spinta di Shu conta come colpo pesante). A zero si rompe: il guardiano
## barcolla SHIELD_STAGGER s e resta scoperto SHIELD_DOWN s, poi lo scudo torna intero.
const SHIELD_FRAC := 0.4
const SHIELD_DOWN := 6.0
const SHIELD_STAGGER := 0.8
const SHIELD_SLAM := 1.0 / 3.0              ## caricando contro una colonna o un nemico lo scudo perde un terzo
var shield_max := 1.0
var shield_hp := 1.0
var shield_down_t := 0.0
@export var charge_damage := 12.0
@export var block := 0.85                   ## quanto danno toglie lo scudo

var state := "walk"
var st := 2.0
var facing := Vector2.DOWN
var charged_hit := false


func _ready() -> void:
	super._ready()
	shield_max = max_hp * SHIELD_FRAC
	shield_hp = shield_max


func _shield_up() -> bool:
	return state != "recover" and shield_down_t <= 0.0


## Lo scudo prende `amount` di resistenza; a zero si rompe.
func _shield_damage(amount: float) -> void:
	if shield_down_t > 0.0:
		return
	shield_hp -= amount
	if shield_hp <= 0.0:
		shield_hp = 0.0
		shield_down_t = SHIELD_DOWN
		stagger_t = maxf(stagger_t, SHIELD_STAGGER)
		Sfx.play_at("jar_break", global_position, 0.1)
		Fx.burst(global_position + facing * 10.0 + Vector2(0, -14), Color(0.95, 0.7, 0.35), 20, 120.0)
		Fx.float_text(global_position + Vector2(0, -34), Lang.t("SCUDO ROTTO"), Color(1.0, 0.75, 0.4))


func shu_push(dir: Vector2, force: float, hooked: bool = false) -> void:
	if _shield_up() and dir != Vector2.ZERO and facing.dot(-dir.normalized()) > 0.35:
		_shield_damage(Run.shu_slam_damage() * 2.0)      # la spinta di Shu: un colpo pesante sullo scudo
	super.shu_push(dir, force, hooked)


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta
	if shield_down_t > 0.0:
		shield_down_t -= delta
		if shield_down_t <= 0.0:
			shield_hp = shield_max                         # lo scudo torna intero
			Fx.burst(global_position + Vector2(0, -16), Color(0.95, 0.8, 0.45), 10, 60.0)
	if to == Vector2.ZERO:
		return Vector2.ZERO
	var d := to.length()
	var u := to / d
	if state != "charge" and not (state == "windup" and st < charge_windup * 0.5):
		var turn := turn_rate * (0.4 if state == "recover" else 1.0) * delta
		facing = facing.rotated(clampf(facing.angle_to(u), -turn, turn))
	match state:
		"walk":
			if st <= 0.0 and d < CHARGE_FROM and absf(facing.angle_to(u)) < 0.5:
				state = "windup"
				st = charge_windup
				Sfx.play_at("mummy_windup", global_position, 0.15)
				return Vector2.ZERO
			return _steer(facing * speed, delta) if d > 20.0 else Vector2.ZERO
		"windup":
			if st <= 0.0:
				state = "charge"
				st = charge_time
				charged_hit = false
				Sfx.play_at("mummy_lunge", global_position, 0.15)
			return Vector2.ZERO
		"charge":
			var pl = get_tree().get_first_node_in_group("player")
			if not charged_hit and pl != null and touches(pl):
				charged_hit = true
				pl.take_damage(charge_damage, global_position, self)
			if get_slide_collision_count() > 0:
				var col = get_slide_collision(0).get_collider()
				if col is Enemy or (col is Node and col.is_in_group("pillars")):
					_shield_damage(shield_max * SHIELD_SLAM)
			if st <= 0.0 or get_slide_collision_count() > 0:
				state = "recover"
				st = 1.1
				Fx.burst(global_position, Color(0.78, 0.64, 0.42), 10, 60.0)
			return facing * charge_speed
		"recover":
			if st <= 0.0:
				state = "walk"
				st = randf_range(2.0, 3.2)
			return Vector2.ZERO
	return Vector2.ZERO


## Lo scudo ferma del tutto le frecce che arrivano da davanti (arrow.gd), anche il tiro carico.
func blocks(dir: Vector2) -> bool:
	if not dead and _shield_up() and dir != Vector2.ZERO and facing.dot(-dir.normalized()) > 0.35:
		_shield_damage(Run.last_arrow_dmg * (2.0 if Run.heavy_strike else 1.0))
		return true
	return false


## Lo scudo para da davanti, tranne quando è abbassato dopo la carica. `dir` è la direzione del
## colpo (dall'eroe verso di lui): se arriva contro la faccia dello scudo, è parato.
func take_hit(dmg: float, dir: Vector2, kb: float, can_burn: bool = false) -> void:
	if dead:
		return
	if _shield_up() and dir != Vector2.ZERO and facing.dot(-dir.normalized()) > 0.35:
		_shield_damage(dmg * (2.0 if Run.heavy_strike else 1.0))     # il danno pieno, prima dello scudo
		Sfx.play_at("hit", global_position, 0.3)
		Fx.burst(global_position + facing * 10.0 + Vector2(0, -12), Color(1.0, 0.85, 0.45), 8, 70.0)
		Fx.float_text(global_position + Vector2(0, -30), Lang.t("PARATO"), Color(0.95, 0.85, 0.55))
		super.take_hit(dmg * (1.0 - block), dir, kb * 0.2, false)
		return
	super.take_hit(dmg, dir, kb * 0.5, can_burn)


func _stagger_time() -> float:
	return 0.15 if state == "recover" else 0.0


func _contact_damage() -> float:
	return contact_damage if state == "charge" else contact_damage * 0.5


## La mummia antica: bende scure e consunte, il copricapo a strisce, lo scudo rotondo di bronzo
## con il disco del sole e la lancia corta. Avviso: lo scudo si alza e brilla.
func _draw_body(flash: bool) -> void:
	var band := _f(Color(0.62, 0.55, 0.42), flash)
	var band_d := _f(Color(0.42, 0.36, 0.26), flash)
	var bronze := _f(Color(0.72, 0.5, 0.22), flash)
	var bronze_l := _f(Color(0.95, 0.75, 0.38), flash)
	var stripe := _f(Color(0.16, 0.3, 0.68), flash)
	var side := 1.0 if facing.x >= 0.0 else -1.0
	var front := facing.y > 0.0
	var step := sin(t * 5.0) * 1.2 if state == "walk" else 0.0
	# gambe
	_limb(Vector2(-2.5, -9), Vector2(-2.5 + step, 0), band_d, 2.6)
	_limb(Vector2(2.5, -9), Vector2(2.5 - step, 0), band_d, 2.6)
	# lancia dietro, se lo scudo è davanti
	var spear_x := -side * 7.0
	_limb(Vector2(spear_x, -26), Vector2(spear_x, -2), Color(0.45, 0.3, 0.16), 1.2)
	draw_colored_polygon(PackedVector2Array([Vector2(spear_x - 1.8, -26), Vector2(spear_x + 1.8, -26), Vector2(spear_x, -32)]), bronze_l)
	# corpo bendato
	_op(PackedVector2Array([Vector2(-6, -24), Vector2(6, -24), Vector2(5.5, -8), Vector2(-5.5, -8)]), band)
	for k in range(5):
		draw_line(Vector2(-5.5, -21 + k * 3), Vector2(5.5, -22 + k * 3 + (1 if k % 2 == 0 else -1)), band_d, 0.8)
	# testa con il copricapo a strisce (nemes consunto)
	_op(_ell(Vector2(0, -29), 4.5, 4.5, 12), band)
	_op(PackedVector2Array([Vector2(-6, -31), Vector2(6, -31), Vector2(6.5, -24), Vector2(-6.5, -24)]), stripe)
	for k in range(3):
		draw_line(Vector2(-6, -29 + k * 2), Vector2(6, -29 + k * 2), Color(0.94, 0.72, 0.3, 0.8), 0.7)
	draw_circle(Vector2(1.5 * side, -29), 0.9, Color(1.0, 0.45, 0.2) if state == "windup" else Color(0.3, 0.9, 0.6))
	# lo scudo: davanti se ti guarda, di lato altrimenti; alzato e lucente nell'avviso
	var lift := 0.0
	if state == "windup":
		lift = 1.0 - st / charge_windup
	elif state == "charge":
		lift = 1.0
	var sc := Vector2(side * (2.0 if front else 7.0), -16.0 - lift * 4.0)
	var sr := 8.0
	if state == "recover":
		sc = Vector2(side * 8.0, -8.0)                 # abbassato: scoperto
	if shield_down_t > 0.0:
		# rotto: due pezzi a terra, il guardiano è scoperto
		draw_circle(Vector2(side * 9.0, -2.0), 3.5, bronze.darkened(0.3))
		draw_circle(Vector2(side * 4.0, -1.0), 2.5, bronze.darkened(0.2))
		sr = 0.0
	draw_set_transform(sc, 0.0, Vector2(1.0 if front else 0.55, 1.0))
	if sr > 0.0:
		draw_circle(Vector2.ZERO, sr + 0.8, OUT)
		draw_circle(Vector2.ZERO, sr, bronze)
		draw_arc(Vector2.ZERO, sr - 1.5, 0, TAU, 20, bronze_l, 1.0)
		draw_circle(Vector2.ZERO, 2.6, Color(0.86, 0.28, 0.12))
		if shield_hp < shield_max * 0.5:
			# crepato: le linee spezzate sul bronzo
			draw_polyline(PackedVector2Array([Vector2(-6, -3), Vector2(-2, 0), Vector2(1, -4), Vector2(5, 1)]), OUT, 1.2)
			draw_polyline(PackedVector2Array([Vector2(-3, 5), Vector2(0, 1), Vector2(4, 5)]), OUT, 1.0)
	if lift > 0.0 and sr > 0.0:
		draw_circle(Vector2.ZERO, sr + 3.0, Color(1.0, 0.8, 0.4, 0.15 + 0.3 * lift))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if state == "windup":
		_charge_strip(1.0 - st / charge_windup)


## La zona vera della carica: 100 px di percorso più il contatto, larga quanto le sagome che si toccano.
func _charge_strip(k: float) -> void:
	Enemy.warn_strip(self, Vector2.ZERO, facing, charge_speed * charge_time + touch_dist(), touch_dist(), k)


func _zones() -> void:
	_charge_strip(0.0)
