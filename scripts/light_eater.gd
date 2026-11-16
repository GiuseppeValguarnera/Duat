extends Enemy
## Divoratore di luce (blocco 21): una bestia tozza che ha inghiottito il fascio di Ra. Finché vive il
## fascio NON attraversa la stanza (le scaglie degli altri restano chiuse). Davanti è corazzato (i colpi
## fanno il 50%), sul dorso la luce inghiottita traspare: i colpi DA DIETRO fanno ×1,5.
## Mosse: MORSO in linea (striscia rossa, 0,55 s) e CARICA corta (striscia, 0,5 s). Dopo ogni mossa
## resta fermo: è il momento di girargli dietro. Al massimo uno per stanza.

const BITE_WARN := 0.55
const BITE_LEN := 62.0
const BITE_HALF := 13.0
const BITE_DMG := 10.0
const CHARGE_WARN := 0.5
const CHARGE_SPEED := 300.0
const CHARGE_TIME := 0.42
const CHARGE_HALF := 12.0
const CHARGE_DMG := 11.0
const REST := 1.1
const FRONT_MULT := 0.5
const BACK_MULT := 1.5
const BACK_DOT := 0.35             ## il colpo arriva "da dietro" se va nel verso in cui guarda

var state := "chase"
var st := 1.0
var face := Vector2.RIGHT
var charge_hit := false
var msg_t := 0.0


func _ready() -> void:
	super._ready()
	add_to_group("light_eaters")
	Fx.float_text(global_position + Vector2(0, -36), Lang.t("LA LUCE È INGHIOTTITA"), Color(1.0, 0.86, 0.45))


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta
	msg_t = maxf(0.0, msg_t - delta)
	if to == Vector2.ZERO:
		return Vector2.ZERO
	var d := to.length()
	var u := to / d
	match state:
		"chase":
			face = face.slerp(u, clampf(delta * 5.0, 0.0, 1.0)).normalized() if face.dot(u) > -0.98 else u
			if st <= 0.0:
				if d < BITE_LEN * 0.8:
					state = "bite_warn"
					st = BITE_WARN
					face = u
					Sfx.play_at("amheh_growl", global_position, 0.4)
					return Vector2.ZERO
				if d < CHARGE_SPEED * CHARGE_TIME + 20.0:
					state = "charge_warn"
					st = CHARGE_WARN
					face = u
					Sfx.play_at("mummy_windup", global_position, 0.3)
					return Vector2.ZERO
			return _steer(u * speed, delta)
		"bite_warn":
			if st <= 0.0:
				var p = get_tree().get_first_node_in_group("player")
				if p != null and not p.dead:
					var v: Vector2 = p.global_position - global_position
					var along := v.dot(face)
					if along > -PLAYER_R and along < BITE_LEN + PLAYER_R and absf(v.dot(face.orthogonal())) < BITE_HALF + PLAYER_R:
						p.take_damage(BITE_DMG, global_position, self)
				Sfx.play_at("bite", global_position, 0.2)
				state = "recover"
				st = REST
			return Vector2.ZERO
		"charge_warn":
			if st <= 0.0:
				state = "charge"
				st = CHARGE_TIME
				charge_hit = false
				Sfx.play_at("dash", global_position, 0.3)
			return -face * 12.0
		"charge":
			var p2 = get_tree().get_first_node_in_group("player")
			if not charge_hit and p2 != null and touches(p2, CHARGE_HALF - radius):
				charge_hit = p2.take_damage(CHARGE_DMG, global_position, self)
			if st <= 0.0:
				state = "recover"
				st = REST
			return face * CHARGE_SPEED
		"recover":
			if st <= 0.0:
				state = "chase"
				st = randf_range(0.8, 1.4)
			return Vector2.ZERO
	return Vector2.ZERO


func take_hit(dmg: float, dir: Vector2, kb: float, can_burn: bool = false) -> void:
	var back := dir != Vector2.ZERO and dir.normalized().dot(face) > BACK_DOT
	if back and msg_t <= 0.0 and not dead:
		msg_t = 1.0
		Fx.float_text(global_position + Vector2(0, -30), Lang.t("ALLE SPALLE"), Color(1.0, 0.86, 0.45))
	super.take_hit(dmg * (BACK_MULT if back else FRONT_MULT), dir, kb * 0.5, can_burn)


func _contact_damage() -> float:
	return 0.0


func bot_escape(pos: Vector2) -> Vector2:
	if state in ["bite_warn", "charge_warn", "charge"]:
		var v := pos - global_position
		if absf(v.dot(face.orthogonal())) < 28.0 and v.dot(face) > -10.0:
			return face.orthogonal() * (1.0 if v.dot(face.orthogonal()) >= 0.0 else -1.0)
	return Vector2.ZERO


func _zones() -> void:
	draw_arc(Vector2.ZERO, CHARGE_HALF, 0.0, TAU, 16, Color(1.0, 0.3, 0.2, 0.6), 1.0)


## Corpo basso e largo, nero-viola, con la testa enorme e la bocca piena di luce; sul dorso una
## chiazza d'oro che pulsa (il punto debole), sempre dalla parte opposta a dove guarda.
func _draw_body(flash: bool) -> void:
	match state:
		"bite_warn":
			Enemy.warn_strip(self, Vector2.ZERO, face, BITE_LEN, BITE_HALF, 1.0 - st / BITE_WARN)
		"charge_warn":
			Enemy.warn_strip(self, Vector2.ZERO, face, CHARGE_SPEED * CHARGE_TIME + CHARGE_HALF, CHARGE_HALF, 1.0 - st / CHARGE_WARN)
	var hide_c := _f(Color(0.16, 0.1, 0.24), flash)
	var dark := _f(Color(0.07, 0.04, 0.12), flash)
	var gold := Color(1.0, 0.86, 0.45)
	var c := Vector2(0, -9)
	var fx := face.x
	var step := sin(t * 9.0) * 1.6 if velocity.length() > 8.0 else 0.0
	for sx in [-1.0, 1.0]:
		_limb(c + Vector2(sx * 6.0, 2), Vector2(sx * 8.0 + step * sx, 0), dark, 2.6)
	# il dorso: dalla parte opposta allo sguardo, con la luce che traspare
	var back := c - Vector2(face.x * 7.0, face.y * 3.5)
	var head := c + Vector2(face.x * 7.0, face.y * 3.5)
	var parts := [[back, 8.5, true], [head, 7.5, false]]
	if face.y <= 0.0:
		parts.reverse()                   # guarda in alto: la testa sta dietro il dorso, si disegna prima
	for pr in parts:
		var at: Vector2 = pr[0]
		_op(_ell(at, pr[1], pr[1] * 0.8, 12), hide_c, 1.0)
		if pr[2]:
			var pulse := 0.6 + 0.4 * sin(t * 5.0)
			draw_circle(at + Vector2(0, -1), 5.0, Color(gold, 0.35 * pulse))
			draw_circle(at + Vector2(0, -1), 3.0, Color(gold, 0.9))
			draw_arc(at + Vector2(0, -1), 6.5, 0.0, TAU, 12, Color(gold, 0.5 * pulse), 1.0)
		else:
			# placche scure sulla fronte e la bocca luminosa
			draw_arc(at, pr[1] - 1.5, -PI * 0.9, -PI * 0.1, 8, dark, 2.4)
			var open := 1.0
			if state == "bite_warn":
				open = 1.0 + 1.5 * (1.0 - st / BITE_WARN)
			draw_circle(at + Vector2(fx * 3.0, 2.0), 2.2 * open, Color(gold, 0.9))
			draw_circle(at + Vector2(fx * 1.0 - 2.5, -2.5), 1.1, Color(1.0, 0.4, 0.3))
			draw_circle(at + Vector2(fx * 1.0 + 2.5, -2.5), 1.1, Color(1.0, 0.4, 0.3))
