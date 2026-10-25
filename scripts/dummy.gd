extends Enemy
## Fantoccio dell'addestramento: un palo di legno avvolto nel lino. Non attacca e non si muove.
## - `eye_only`: dipinto con l'Occhio, si rompe solo con l'Occhio di Horus.
## - `lunger`: la mummia d'addestramento. Diventa rossa, poi scatta verso di te; non fa danni,
##   ma conta se l'hai schivata scattando attraverso di lei.

signal dodged

var eye_only := false
var ushabti := false                   ## bersaglio del Cortile di Neith: statuina d'argilla che si ricompone
var lunger := false
var hit_by_eye := false
var state := "rest"
var st := 1.6
var lunge_dir := Vector2.ZERO
var _dodge_counted := false


func _ready() -> void:
	collision_layer = 4
	collision_mask = 5
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 7.0
	shape.shape = c
	add_child(shape)
	max_hp = 999.0 if lunger else (24.0 if eye_only else 30.0)
	if ushabti:
		max_hp = 180.0
	contact_damage = 0.0
	ka_value = 0
	radius = 8.0
	super._ready()
	hp = max_hp                         # il fantoccio non risente dei Pesi o delle maledizioni


func _behave(delta: float, to: Vector2) -> Vector2:
	if not lunger:
		return Vector2.ZERO
	st -= delta
	match state:
		"rest":
			if st <= 0.0 and to != Vector2.ZERO and to.length() < 170.0:
				state = "windup"
				st = 0.8
				Sfx.play_at("mummy_windup", global_position, 0.05)
			return Vector2.ZERO
		"windup":
			if to != Vector2.ZERO:
				lunge_dir = to.normalized()
			if st <= 0.0:
				state = "lunge"
				st = 0.4
				_dodge_counted = false
				Sfx.play_at("mummy_lunge", global_position, 0.05)
			return Vector2.ZERO
		"lunge":
			var player = get_tree().get_first_node_in_group("player")
			if player != null and not _dodge_counted and global_position.distance_to(player.global_position) < 26.0:
				_dodge_counted = true
				if player.dash_t > 0.0:
					Fx.float_text(global_position + Vector2(0, -24), "Schivata!", Color(0.6, 1, 0.6))
					dodged.emit()
				else:
					Fx.float_text(global_position + Vector2(0, -24), "Colpito! Scatta mentre arriva", Color(1, 0.5, 0.4))
					Fx.shake(2.0)
			if st <= 0.0:
				state = "rest"
				st = 1.4
			return lunge_dir * 260.0
	return Vector2.ZERO


func take_hit(dmg: float, dir: Vector2, _kb: float, can_burn: bool = false) -> void:
	if lunger:
		flash_t = 0.1
		Sfx.play("hit", 0.15)
		return
	if eye_only and not hit_by_eye:
		flash_t = 0.1
		Fx.float_text(global_position + Vector2(0, -22), "Solo l'Occhio", Color(0.55, 0.75, 1.0))
		return
	hit_by_eye = false
	super.take_hit(dmg, dir, 0.0, can_burn)


func _stagger_time() -> float:
	return 0.0


func _draw_body(flash: bool) -> void:
	if ushabti:
		# statuina mummiforme di faience azzurra, con le braccia incrociate e i geroglifici
		var faience := Color.WHITE if flash else Color(0.3, 0.68, 0.72)
		var dark := Color(0.08, 0.2, 0.28)
		var cracks := 1.0 - hp / max_hp
		draw_colored_polygon(PackedVector2Array([Vector2(-5, 0), Vector2(5, 0), Vector2(6, -14), Vector2(4, -20), Vector2(-4, -20), Vector2(-6, -14)]), faience)
		draw_circle(Vector2(0, -23), 5.0, faience)
		draw_colored_polygon(PackedVector2Array([Vector2(-6, -26), Vector2(6, -26), Vector2(5, -17), Vector2(-5, -17)]), dark)
		draw_circle(Vector2(0, -22), 3.0, faience.lightened(0.15))
		draw_line(Vector2(-4, -15), Vector2(4, -12), dark, 1.2)
		draw_line(Vector2(4, -15), Vector2(-4, -12), dark, 1.2)
		for i in range(3):
			draw_line(Vector2(-1.5, -9 + i * 3), Vector2(1.5, -9 + i * 3), dark, 0.8)
		# crepe man mano che si rompe
		if cracks > 0.3:
			draw_line(Vector2(-3, -18), Vector2(1, -8), dark, 0.8)
		if cracks > 0.6:
			draw_line(Vector2(3, -20), Vector2(-2, -4), dark, 0.8)
		return
	if lunger:
		var red := state == "windup"
		var linen := Color.WHITE if flash else (Color(0.95, 0.35, 0.3) if red else Color(0.86, 0.8, 0.66))
		draw_rect(Rect2(-6, -22, 12, 22), linen)
		draw_circle(Vector2(0, -25), 6.0, linen)
		for i in range(5):
			draw_line(Vector2(-6, -20 + i * 4), Vector2(6, -18 + i * 4), linen.darkened(0.25), 1.0)
		draw_circle(Vector2(-2, -26), 1.2, Color(1, 0.85, 0.3))
		draw_circle(Vector2(2, -26), 1.2, Color(1, 0.85, 0.3))
		return
	var wood := Color(0.45, 0.3, 0.16)
	var straw := Color.WHITE if flash else (Color(0.78, 0.7, 0.95) if eye_only else Color(0.88, 0.78, 0.52))
	draw_rect(Rect2(-1.5, -6, 3, 8), wood)
	draw_line(Vector2(-9, -16), Vector2(9, -16), wood, 2.5)
	draw_circle(Vector2(0, -16), 8.0, straw)
	draw_arc(Vector2(0, -16), 8.0, 0, TAU, 20, straw.darkened(0.35), 1.0)
	if eye_only:
		# l'Occhio dipinto sul fantoccio
		draw_arc(Vector2(0, -16), 3.5, PI, TAU, 10, Color(0.16, 0.3, 0.68), 1.5)
		draw_circle(Vector2(0, -15.5), 1.5, Color(0.16, 0.3, 0.68))
		draw_line(Vector2(0, -14), Vector2(-1, -10), Color(0.16, 0.3, 0.68), 1.2)
	else:
		draw_arc(Vector2(0, -16), 4.0, 0, TAU, 14, Color(0.7, 0.2, 0.15), 1.5)
		draw_circle(Vector2(0, -16), 1.5, Color(0.7, 0.2, 0.15))
