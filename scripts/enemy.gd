class_name Enemy
extends CharacterBody2D
## Base comune a tutti i nemici: vita, colpi subiti, spinta, bruciatura, danno
## da contatto e morte. Ogni nemico eredita da qui e cambia solo due cose:
## come si muove (_behave) e come si disegna (_draw_body).

signal killed(enemy: Enemy)

@export var max_hp := 30.0
@export var speed := 40.0
@export var contact_damage := 8.0
@export var ka_value := 1
@export var radius := 8.0

var hp := 0.0
var dead := false
var knock := Vector2.ZERO
var flash_t := 0.0
var burn_t := 0.0
var burn_tick := 0.0
var t := 0.0
var seed_offset := 0.0
var contact: Area2D
var is_boss := false
var miniboss := false                 ## guardiano a metà discesa: barra in alto invece che sopra la testa
var elite := false                     ## versione dorata: più grossa, più resistente, lascia più Ka
const HeartScript := preload("res://scripts/heart_drop.gd")
var stagger_t := 0.0
var mark_t := 0.0                     ## Sguardo del Falco: secondi in cui il khopesh fa più danni
var sobek_stun_t := 0.0                ## stordito dal Morso di Sobek (per la Forza del Fiume)                   ## dopo un colpo il nemico barcolla: non si muove e non ferisce


func _ready() -> void:
	if not is_boss:
		max_hp *= Run.enemy_hp_mult()
	if elite:
		max_hp *= 1.8
		contact_damage *= 1.3
		ka_value += 2
		scale = Vector2(1.2, 1.2)
	hp = max_hp
	add_to_group("enemies")
	t = randf() * 3.0
	seed_offset = randf() * TAU
	contact = get_node_or_null("ContactArea")


func _physics_process(delta: float) -> void:
	if dead:
		return
	t += delta
	flash_t = maxf(0.0, flash_t - delta)
	_update_burn(delta)
	if dead:
		return

	var player = get_tree().get_first_node_in_group("player")
	var to := Vector2.ZERO
	if player != null and not player.dead:
		to = player.global_position - global_position

	sobek_stun_t = maxf(0.0, sobek_stun_t - delta)
	mark_t = maxf(0.0, mark_t - delta)
	if stagger_t > 0.0:
		stagger_t -= delta
		velocity = knock
	else:
		velocity = _behave(delta, to) * Run.enemy_speed_mult() * _puddle_slow() + knock
	knock = knock.move_toward(Vector2.ZERO, 800.0 * delta)
	move_and_slide()

	if contact != null and contact.monitoring and stagger_t <= 0.0:
		for a in contact.get_overlapping_areas():
			var o = a.get_parent()
			if o.is_in_group("player"):
				o.take_damage(_contact_damage(), global_position, self)
	queue_redraw()


# --- da sovrascrivere nei singoli nemici ----------------------------------------

## Restituisce la velocità voluta. `to` è il vettore verso il giocatore (zero se non c'è).
func _behave(_delta: float, _to: Vector2) -> Vector2:
	return Vector2.ZERO


func _contact_damage() -> float:
	return contact_damage


## Chiamata dopo ogni colpo subito, per reazioni speciali.
func _on_hit(_dmg: float) -> void:
	pass


## Marea del Nilo: dentro una pozza il nemico rallenta. Anche l'acqua delle stanze rallenta
## (non i boss) e spegne le fiamme.
func _puddle_slow() -> float:
	if not is_boss and Hazards.in_water(get_tree(), global_position):
		burn_t = 0.0
		return Hazards.WATER_SLOW
	for p in get_tree().get_nodes_in_group("puddles"):
		if global_position.distance_to(p.global_position) < p.radius:
			return 1.0 - Run.val("sobek_tide") / 100.0
	return 1.0


## Dentro una pozza della Marea del Nilo (per la Forza del Fiume).
func _in_tide() -> bool:
	for p in get_tree().get_nodes_in_group("puddles"):
		if global_position.distance_to(p.global_position) < p.radius:
			return true
	return false


## Moltiplicatore dei danni ricevuti (per esempio un boss stordito).
func _damage_mult() -> float:
	return 1.0


## Quanto barcolla dopo un colpo. I nemici grossi possono barcollare meno.
func _stagger_time() -> float:
	return 0.35


func _draw_body(_flash: bool) -> void:
	pass


# --- disegno: lo stesso stile del protagonista --------------------------------------
# Contorno scuro attorno a ogni forma, colori della pittura egizia, occhi che si leggono:
# così nemici ed eroe sembrano dello stesso mondo e si distinguono anche sul telefono.

const OUT := Color(0.12, 0.08, 0.05)          ## il contorno, uguale a quello dell'eroe
const GOLD := Color(0.94, 0.72, 0.3)


## Una forma piena con il contorno scuro.
func _op(pts: PackedVector2Array, fill: Color, w: float = 0.8) -> void:
	draw_colored_polygon(pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, OUT, w)


## Un'ellisse come poligono (per corpi e gusci).
func _ell(c: Vector2, rx: float, ry: float, n: int = 14) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## Un arto: una linea col contorno.
func _limb(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	draw_line(a, b, OUT, w + 1.0)
	draw_line(a, b, col, w)


## Un cerchio col contorno.
func _dot(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c, r + 0.6, OUT)
	draw_circle(c, r, col)


## Il colore, o bianco nel lampo del colpo.
func _f(c: Color, flash: bool) -> Color:
	return Color(1, 1, 1, c.a) if flash else c


# --- comune -----------------------------------------------------------------------

func take_hit(dmg: float, dir: Vector2, kb: float, can_burn: bool = false) -> void:
	if dead:
		return
	dmg *= Run.jackal_mult(hp / max_hp) * _damage_mult()
	if Run.has("sobek_river") and (sobek_stun_t > 0.0 or _in_tide()):
		dmg *= 1.0 + Run.val("sobek_river") / 100.0
	hp -= dmg
	Run.damage_dealt += dmg
	flash_t = 0.1
	stagger_t = maxf(stagger_t, _stagger_time())
	knock = dir * kb
	if can_burn:
		burn_t = 2.0
	_on_hit(dmg)
	Run.add_sekhem(dmg * 0.15)
	Fx.damage_number(global_position, dmg, Color(1, 0.95, 0.8), 11 if dmg < 25.0 else 14)
	Fx.burst(global_position + Vector2(0, -radius), Color(1, 0.9, 0.6), 5, 70.0)
	Sfx.play("hit", 0.15)
	if hp <= 0.0:
		die()


func _update_burn(delta: float) -> void:
	if burn_t <= 0.0:
		return
	burn_t -= delta
	burn_tick -= delta
	if burn_tick <= 0.0:
		burn_tick = 0.5
		var b := Run.burn_tick_damage()
		hp -= b
		Fx.damage_number(global_position, b, Color(1, 0.6, 0.2))
		if hp <= 0.0:
			die()


func die() -> void:
	if dead:
		return
	dead = true
	Run.kills += 1
	Sfx.play("kill")
	# solo i nemici più grossi lasciano un po' di Ka: il grosso arriva dai tesori
	var ka := roundi(ka_value * Run.ka_mult())
	if ka > 0:
		Run.ka += ka
		Fx.float_text(global_position + Vector2(0, -12), Lang.t("+%d Ka") % ka, Color(0.94, 0.72, 0.3))
	if Run.has("sekhmet_blood"):
		Run.blood_kills += 1
		if Run.blood_kills >= 5:
			Run.blood_kills = 0
			var player = get_tree().get_first_node_in_group("player")
			if player != null and not player.dead:
				player.heal(Run.val("sekhmet_blood"))
	Fx.burst(global_position + Vector2(0, -radius), Color(0.94, 0.72, 0.3), 18, 130.0)
	if not is_boss:
		Fx.soul(global_position + Vector2(0, -radius))
	# capitolo 26: a volte il nemico lascia un cuore che cura
	var heart_chance := Chapters.value("c26")
	if heart_chance > 0.0 and not Run.training and not is_boss and randf() * 100.0 < heart_chance:
		var heart := HeartScript.new()
		heart.amount = Chapters.heart_heal()
		get_parent().add_child.call_deferred(heart)
		heart.position = global_position
	if Run.has("anubi_guide"):
		_release_spirit()
	killed.emit(self)
	queue_free()


## Guida delle Anime: lo spirito del nemico abbattuto colpisce il nemico più vicino.
func _release_spirit() -> void:
	var from := global_position
	var best = null
	var best_d := 140.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e == self or e.dead:
			continue
		var d := from.distance_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	if best == null:
		return
	var ref: WeakRef = weakref(best)            # il bersaglio potrebbe morire prima che arrivi lo spirito
	var dmg := Run.val("anubi_guide")
	Fx.burst(from + Vector2(0, -8), Boons.god_color("anubi"), 10, 60.0)
	get_tree().create_timer(0.2).timeout.connect(func():
		var target = ref.get_ref()
		if target != null and not target.dead:
			Fx.burst(target.global_position + Vector2(0, -8), Boons.god_color("anubi"), 12, 80.0)
			target.take_hit(dmg, (target.global_position - from).normalized(), 60.0))


func _draw() -> void:
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, radius + 3.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if elite:
		var pulse := 0.5 + 0.5 * sin(t * 4.0)
		draw_circle(Vector2(0, -radius), radius + 6.0, Color(1, 0.8, 0.3, 0.1 + 0.08 * pulse))
		draw_arc(Vector2(0, -radius), radius + 6.0, 0.0, TAU, 24, Color(1, 0.82, 0.35, 0.55), 1.0)
	_draw_body(flash_t > 0.0)
	if burn_t > 0.0:
		draw_circle(Vector2(0, -radius), radius + 3.0, Color(1, 0.5, 0.1, 0.25))
	if mark_t > 0.0:
		# il segno del falco sopra il nemico
		var mp := Vector2(0, -radius * 2.6 - 6.0)
		draw_arc(mp, 4.0, PI * 1.1, PI * 1.9, 8, Boons.god_color("horus"), 1.5)
		draw_circle(mp + Vector2(0, -1), 1.5, Boons.god_color("horus"))
	if hp < max_hp and not is_boss and not miniboss:
		var w := radius * 2.5
		draw_rect(Rect2(-w / 2.0, -radius * 3.0 - 6.0, w, 3), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(-w / 2.0, -radius * 3.0 - 6.0, w * hp / max_hp, 3), Color(0.85, 0.2, 0.15))
