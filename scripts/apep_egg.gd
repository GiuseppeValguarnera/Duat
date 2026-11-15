extends Enemy
## Uovo di Apopi: non si muove e non attacca. Ogni 5,5 secondi si crepa (un anello viola lo annuncia)
## e ne esce una serpe; dopo quattro schiuse si svuota da solo. È il bersaglio da scegliere per primo:
## finché resta in piedi la stanza non finisce di riempirsi. Solo nel Banco di Apopi.

const HATCH_EVERY := 5.5
const HATCH_WARN := 0.9
const HATCHES := 4
const MAX_ALIVE := 2               ## serpi di quest'uovo vive insieme

var st := 3.0
var hatched := 0
var brood: Array = []


func _behave(delta: float, _to: Vector2) -> Vector2:
	st -= delta
	brood = brood.filter(func(b) -> bool: return is_instance_valid(b) and not b.dead)
	if st <= 0.0:
		st = HATCH_EVERY
		if brood.size() < MAX_ALIVE:
			_hatch()
	return Vector2.ZERO


func _hatch() -> void:
	hatched += 1
	Sfx.play_at("serpent_erupt", global_position, 0.35)
	Fx.burst(global_position + Vector2(0, -8), Color(0.5, 0.2, 0.7), 14, 90.0)
	var g = get_tree().current_scene
	if g != null and g.has_method("_on_boss_summon"):
		var at := global_position + Vector2.from_angle(randf() * TAU) * 22.0
		if g.has_method("_in_floor") and not g._in_floor(at, 8.0):
			at = global_position
		var before: Array = get_tree().get_nodes_in_group("enemies")
		g._on_boss_summon([["apep_spawn", at]])
		# la serpe compare tra poco: la riconosco al prossimo giro (quelle nuove vicine all'uovo)
		get_tree().create_timer(1.3, false).timeout.connect(func() -> void:
			if not is_instance_valid(self):
				return
			for e in get_tree().get_nodes_in_group("enemies"):
				if e not in before and e != self and e.global_position.distance_to(global_position) < 60.0 and e not in brood:
					brood.append(e))
	if hatched >= HATCHES:
		no_reward = true
		die()


func take_hit(dmg: float, dir: Vector2, _kb: float, can_burn: bool = false) -> void:
	super.take_hit(dmg, dir, 0.0, can_burn)


func shu_push(_dir: Vector2, _force: float, _hook: bool = false) -> void:
	pass                             # è piantato nella roccia


func _contact_damage() -> float:
	return 0.0


func _stagger_time() -> float:
	return 0.0


## Un uovo nero alto quanto l'eroe, con vene viola che pulsano sempre più in fretta prima della schiusa
## e crepe che si allargano a ogni serpe uscita.
func _draw_body(flash: bool) -> void:
	var k := clampf(1.0 - st / HATCH_WARN, 0.0, 1.0) if st < HATCH_WARN else 0.0
	if k > 0.0:
		draw_arc(Vector2(0, -2), 16.0 + 8.0 * k, 0.0, TAU, 24, Color(0.75, 0.4, 1.0, 0.7 * k), 1.5)
	var c := Vector2(0, -12)
	var shell := _f(Color(0.09, 0.06, 0.12), flash)
	var beat := 0.5 + 0.5 * sin(t * (3.0 + 9.0 * k))
	_op(_ell(c, 9.5 + beat * 0.6, 13.0 + beat * 0.6, 18), shell, 1.2)
	draw_arc(c + Vector2(-2, -2), 6.0, PI * 1.1, PI * 1.7, 8, Color(0.4, 0.3, 0.5, 0.7), 1.4)
	for i in range(4):
		var a := -1.2 + i * 0.8
		var p0 := c + Vector2(cos(a) * 3.0, sin(a) * 4.0)
		var p1 := c + Vector2(cos(a + 0.3) * 8.0, sin(a + 0.3) * 11.0)
		draw_line(p0, p1, Color(0.7, 0.35, 1.0, 0.45 + 0.5 * beat), 1.2)
	for i in range(hatched):
		var x := -6.0 + i * 4.0
		draw_polyline(PackedVector2Array([c + Vector2(x, -10), c + Vector2(x + 2, -5), c + Vector2(x - 1, -1), c + Vector2(x + 1, 4)]), Color(1.0, 0.85, 0.5, 0.9), 1.0)
	# le schiuse rimaste: puntini sotto l'uovo
	for i in range(HATCHES - hatched):
		draw_circle(Vector2(-4.5 + i * 3.0, 4.0), 1.0, Color(0.75, 0.4, 1.0))
