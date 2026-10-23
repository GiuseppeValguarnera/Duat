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
var stagger_t := 0.0                   ## dopo un colpo il nemico barcolla: non si muove e non ferisce


func _ready() -> void:
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

	if stagger_t > 0.0:
		stagger_t -= delta
		velocity = knock
	else:
		velocity = _behave(delta, to) * Run.enemy_speed_mult() + knock
	knock = knock.move_toward(Vector2.ZERO, 800.0 * delta)
	move_and_slide()

	if contact != null and stagger_t <= 0.0:
		for a in contact.get_overlapping_areas():
			var o = a.get_parent()
			if o.is_in_group("player"):
				o.take_damage(_contact_damage(), global_position)
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


## Quanto barcolla dopo un colpo. I nemici grossi possono barcollare meno.
func _stagger_time() -> float:
	return 0.35


func _draw_body(_flash: bool) -> void:
	pass


# --- comune -----------------------------------------------------------------------

func take_hit(dmg: float, dir: Vector2, kb: float, can_burn: bool = false) -> void:
	if dead:
		return
	if Run.has("anubi_jackal") and hp < max_hp * 0.5:
		dmg *= 1.0 + Run.val("anubi_jackal") / 100.0
	hp -= dmg
	flash_t = 0.1
	stagger_t = maxf(stagger_t, _stagger_time())
	knock = dir * kb
	if can_burn:
		burn_t = 2.0
	_on_hit(dmg)
	Run.add_sekhem(dmg * 0.15)
	Fx.damage_number(global_position, dmg)
	Fx.burst(global_position + Vector2(0, -radius), Color(1, 0.9, 0.6), 5, 70.0)
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
	var ka := roundi(ka_value * Run.ka_mult())
	Run.ka += ka
	Fx.float_text(global_position + Vector2(0, -12), "+%d Ka" % ka, Color(0.94, 0.72, 0.3))
	if Run.has("sekhmet_blood"):
		var player = get_tree().get_first_node_in_group("player")
		if player != null and not player.dead:
			player.heal(Run.val("sekhmet_blood"))
	Fx.burst(global_position + Vector2(0, -radius), Color(0.94, 0.72, 0.3), 18, 130.0)
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
	var target: Enemy = best
	var dmg := Run.val("anubi_guide")
	var tree := get_tree()
	Fx.burst(from + Vector2(0, -8), Boons.god_color("anubi"), 10, 60.0)
	tree.create_timer(0.2).timeout.connect(func():
		if is_instance_valid(target) and not target.dead:
			Fx.burst(target.global_position + Vector2(0, -8), Boons.god_color("anubi"), 12, 80.0)
			target.take_hit(dmg, (target.global_position - from).normalized(), 60.0))


func _draw() -> void:
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, radius + 3.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_body(flash_t > 0.0)
	if burn_t > 0.0:
		draw_circle(Vector2(0, -radius), radius + 3.0, Color(1, 0.5, 0.1, 0.25))
	if hp < max_hp:
		var w := radius * 2.5
		draw_rect(Rect2(-w / 2.0, -radius * 3.0 - 6.0, w, 3), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(-w / 2.0, -radius * 3.0 - 6.0, w * hp / max_hp, 3), Color(0.85, 0.2, 0.15))
