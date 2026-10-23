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

	velocity = _behave(delta, to) + knock
	knock = knock.move_toward(Vector2.ZERO, 800.0 * delta)
	move_and_slide()

	if contact != null:
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


func _draw_body(_flash: bool) -> void:
	pass


# --- comune -----------------------------------------------------------------------

func take_hit(dmg: float, dir: Vector2, kb: float, can_burn: bool = false) -> void:
	if dead:
		return
	hp -= dmg
	flash_t = 0.1
	knock = dir * kb
	if can_burn:
		burn_t = 2.0
	_on_hit(dmg)
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
		hp -= 5.0
		Fx.damage_number(global_position, 5.0, Color(1, 0.6, 0.2))
		if hp <= 0.0:
			die()


func die() -> void:
	if dead:
		return
	dead = true
	Run.ka += ka_value
	Fx.float_text(global_position + Vector2(0, -12), "+%d Ka" % ka_value, Color(0.94, 0.72, 0.3))
	if Run.has("sekhmet_blood"):
		var player = get_tree().get_first_node_in_group("player")
		if player != null and not player.dead:
			player.heal(3.0)
	Fx.burst(global_position + Vector2(0, -radius), Color(0.94, 0.72, 0.3), 18, 130.0)
	killed.emit(self)
	queue_free()


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
