extends Node
## Bot di playtest: gioca davvero (niente invulnerabilità) con uno "stile" scelto da DUAT_PERSONA.
## Scrive una riga JSON con le metriche della discesa in DUAT_OUT.

const P := {
	"novizio":    {"reaction": 0.35, "dodge": 0.12, "eye": 0.2, "range": 26.0, "heal": 0.0, "set": 0.3, "heavy": 0.5, "pick": "first", "aim_err": 25.0, "panic": 0.25, "skill": 0.0},
	"casual":     {"reaction": 0.2, "dodge": 0.4, "eye": 0.5, "range": 28.0, "heal": 0.4, "set": 0.3, "heavy": 0.4, "pick": "random", "aim_err": 12.0, "panic": 0.1, "skill": 0.35},
	"veterano":   {"reaction": 0.08, "dodge": 0.85, "eye": 0.9, "range": 30.0, "heal": 0.55, "set": 0.4, "heavy": 0.5, "pick": "damage", "aim_err": 4.0, "panic": 0.0, "skill": 1.0},
	"speedrunner":{"reaction": 0.08, "dodge": 0.6, "eye": 0.9, "range": 24.0, "heal": 0.0, "set": 1.0, "heavy": 1.0, "pick": "damage", "aim_err": 6.0, "panic": 0.0, "skill": 0.7},
	"minmaxer":   {"reaction": 0.08, "dodge": 0.75, "eye": 0.9, "range": 30.0, "heal": 0.35, "set": 1.0, "heavy": 0.8, "pick": "value", "aim_err": 4.0, "panic": 0.0, "skill": 0.9},
	"prudente":   {"reaction": 0.1, "dodge": 0.7, "eye": 0.7, "range": 34.0, "heal": 0.9, "set": 0.0, "heavy": 0.0, "pick": "defense", "aim_err": 6.0, "panic": 0.0, "skill": 0.9},
	"cecchino":   {"reaction": 0.1, "dodge": 0.75, "eye": 1.0, "range": 120.0, "heal": 0.5, "set": 0.3, "heavy": 0.5, "pick": "eye", "aim_err": 5.0, "panic": 0.0, "skill": 0.9},
}

var persona := "veterano"
var cfg: Dictionary
var out_path := ""
var gt := 0.0                          # tempo di gioco
var decide_t := 0.0
var move_dir := Vector2.ZERO
var aim_dir := Vector2.RIGHT
var want_attack := false
var dash_now := false
var dash_release := false
var tap_special := false
var tap_super := false
var stuck_t := 0.0
var last_pos := Vector2.ZERO
var unstick := Vector2.ZERO
var unstick_t := 0.0
var last_hp := -1.0
var dmg := {}
var rooms := []
var last_room := 0
var room_start := 0.0
var choices := []
var dodges := 0
var heals := 0.0
var boss_time := 0.0
var done := false
var skip := ""                        # "guardian" o "ammit": salta direttamente a quello scontro
var skipped := false
var start_room_n := 0
var serpent_mod := {}
var modded := false
var interact_release := false
var shop_buys := []
var force_anubi := ""
var anubi_done := false
var force_god := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	persona = OS.get_environment("DUAT_PERSONA")
	if not P.has(persona):
		persona = "veterano"
	cfg = P[persona]
	out_path = OS.get_environment("DUAT_OUT")
	cfg = cfg.duplicate()
	# profilo su misura (beta tester): sovrascrive i parametri dello stile
	var custom := OS.get_environment("DUAT_CFG")
	if custom != "":
		var extra = JSON.parse_string(custom)
		if extra is Dictionary:
			for k in extra:
				cfg[k] = extra[k]
	var force_set := OS.get_environment("DUAT_SET")
	if force_set == "always":
		cfg["set"] = 1.0
	elif force_set == "never":
		cfg["set"] = 0.0
	var force_heavy := OS.get_environment("DUAT_HEAVY")
	if force_heavy == "always":
		cfg["heavy"] = 3.0
	elif force_heavy == "never":
		cfg["heavy"] = -3.0
	force_anubi = OS.get_environment("DUAT_ANUBI")
	skip = OS.get_environment("DUAT_SKIP")
	var sm := OS.get_environment("DUAT_SERPENT")
	if sm != "":
		serpent_mod = JSON.parse_string(sm)
	force_god = OS.get_environment("DUAT_GOD")
	var s := OS.get_environment("DUAT_SEED")
	seed(int(s) if s != "" else 1)


func _process(delta: float) -> void:
	if done:
		return
	var g = get_tree().current_scene
	if g == null or g.name != "Game" or g.player == null or not is_instance_valid(g.player):
		return
	var real := delta / maxf(Engine.time_scale, 0.0001)
	gt += real
	var p = g.player
	Fx.device = "pad"
	_metrics(g, p)
	if g.finished or gt > 900.0:
		_finish(g)
		return
	if interact_release:
		Input.action_release("interact")
		interact_release = false
	if skip != "" and not skipped and g.menu == null and not Run.boons.is_empty():
		skipped = true
		var n := 3 if skip == "guardian" else 7
		var pool := []
		for id in Boons.ALL:
			var gd: String = Boons.ALL[id].get("god", "")
			if gd in ["ra", "sekhmet", "thoth", "bastet", "sobek", "iside"] and not Boons.is_heavy(id):
				pool.append(id)
		pool.shuffle()
		for i in range(n):
			Run.add_boon(pool[i])
		if skip == "ammit":
			Run.add_boon(pool[0])
		var extra := OS.get_environment("DUAT_EXTRA")
		if extra != "":
			for i in range(n):
				if Run.has(extra):
					break
			if not Run.has(extra):
				Run.add_boon(extra)
		Run.room = 4 if skip == "guardian" else 10
		g.start_room({"kind": "guardian"} if skip == "guardian" else {"kind": "none"})
		start_room_n = Run.room
		var frac := OS.get_environment("DUAT_START_HP")
		if frac != "":
			Run.hp = Run.max_hp * float(frac)
			g.player.hp = Run.hp
		return
	if skip == "guardian" and skipped and Run.room == start_room_n and g.cleared and not done:
		_finish(g, "cleared")
		return
	if not serpent_mod.is_empty() and not modded and g.boss != null and is_instance_valid(g.boss) and g.boss.miniboss:
		modded = true
		var b = g.boss
		for k in serpent_mod:
			if k == "max_hp":
				b.max_hp = float(serpent_mod[k]) * Run.enemy_hp_mult()
				b.hp = b.max_hp
			else:
				b.set(k, serpent_mod[k])
	if dash_release:
		Input.action_release("dash")
		dash_release = false
	if g.menu != null and is_instance_valid(g.menu):
		_release_all()
		_menu(g)
		return
	decide_t -= real
	if decide_t <= 0.0:
		decide_t = cfg["reaction"]
		_decide(g, p)
	_apply(p, real)


# ------------------------------------------------------------------ decisioni

func _decide(g, p) -> void:
	var pos: Vector2 = p.global_position
	var enemies := []
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.dead:
			enemies.append(e)
	want_attack = false
	tap_special = false
	tap_super = false
	# 1. minacce
	var threat := _threat(g, pos, enemies)
	if threat != Vector2.ZERO and randf() < cfg["dodge"] and p.dash_cd <= 0.0:
		move_dir = threat
		dash_now = true
		dodges += 1
		return
	if cfg["panic"] > 0.0 and randf() < cfg["panic"] * cfg["reaction"] and not enemies.is_empty():
		move_dir = Vector2.RIGHT.rotated(randf() * TAU)
		dash_now = true
		return
	# 2. combattimento
	if not enemies.is_empty():
		var target = enemies[0]
		var best := 1e9
		for e in enemies:
			var d: float = pos.distance_to(e.global_position)
			if d < best:
				best = d
				target = e
		var to: Vector2 = target.global_position - pos
		var dist := to.length()
		aim_dir = to.normalized().rotated(deg_to_rad(randf_range(-cfg["aim_err"], cfg["aim_err"])))
		var want_range: float = cfg["range"]
		var skill: float = cfg["skill"]
		var crowd := 0
		for e in enemies:
			if pos.distance_to(e.global_position) < 44.0:
				crowd += 1
		if target.is_boss or target.miniboss:
			# con Ammit e con il Serpente: addosso solo quando è stordita o si sta riprendendo, altrimenti a distanza
			var open_window: bool = target.state in ["stunned", "recover", "intro", "furia", "dive"]
			want_range = 34.0 if (open_window or randf() > skill) else 125.0
		if dist > want_range + 6.0:
			move_dir = to.normalized()
		elif dist < want_range - 18.0:
			move_dir = -to.normalized()
		else:
			move_dir = to.normalized().orthogonal() * (1.0 if int(gt) % 4 < 2 else -1.0) * 0.6
		# accerchiato: chi è bravo colpisce e indietreggia, o scatta fuori
		if crowd >= 3 and randf() < skill:
			var away := Vector2.ZERO
			for e in enemies:
				var rel: Vector2 = pos - e.global_position
				if rel.length() < 60.0:
					away += rel.normalized()
			move_dir = away.normalized()
			if crowd >= 4 and p.dash_cd <= 0.0 and randf() < skill * 0.5:
				dash_now = true
		# trappole: chi è bravo le evita sempre, gli altri solo quando si accendono
		for trap in get_tree().get_nodes_in_group("traps"):
			if not trap.has_method("phase"):
				continue
			var near_trap: bool = pos.distance_to(trap.global_position) < 26.0
			if near_trap and (randf() < skill or (trap.phase() != "idle" and randf() < cfg["dodge"])):
				move_dir = (move_dir + (pos - trap.global_position).normalized() * 1.5).normalized()
		if dist < 46.0 and (not (target.is_boss or target.miniboss) or want_range < 100.0):
			want_attack = true
		if dist < 300.0 and randf() < cfg["eye"]:
			tap_special = true
		if Run.sekhem_ready() and (enemies.size() >= 3 or target.is_boss):
			tap_super = true
		return
	# 3. fuori dal combattimento: negozio, ricompense, poi porte
	if not g.shop_items.is_empty():
		var want = null
		for it in g.shop_items:
			if not is_instance_valid(it) or it.sold or Run.ka < it.price:
				continue
			if it.kind == "heal" and Run.hp / Run.max_hp < 0.6:
				want = it
				break
			if it.kind != "heal" and want == null and randf() < float(cfg.get("spend", 0.8)):
				want = it
		if want != null:
			if pos.distance_to(want.global_position) < 16.0:
				Input.action_press("interact")
				interact_release = true
				shop_buys.append(want.kind)
			move_dir = (want.global_position - pos).normalized()
			return
	for c in g.world.get_children():
		if c.has_signal("collected"):
			move_dir = (c.global_position - pos).normalized()
			return
	if not g.doors.is_empty():
		var d = _pick_door(g)
		if d != null:
			var target_pos: Vector2 = d.global_position
			move_dir = (target_pos - pos).normalized()
			return
	move_dir = Vector2.ZERO


func _threat(g, pos: Vector2, enemies: Array) -> Vector2:
	# sfere e dardi in arrivo
	for c in g.world.get_children():
		if c is Area2D and "direction" in c and "style" in c:
			var rel: Vector2 = pos - c.global_position
			var along: float = rel.dot(c.direction)
			if along > 0.0 and along < 90.0:
				var perp: float = absf(rel.dot(c.direction.orthogonal()))
				if perp < 12.0:
					return c.direction.orthogonal() * (1.0 if rel.dot(c.direction.orthogonal()) > 0.0 else -1.0)
	for e in enemies:
		var rel: Vector2 = pos - e.global_position
		var d := rel.length()
		if "lunge_dir" in e and e.state == "windup" and d < 90.0 and e.st < 0.25:
			return e.lunge_dir.orthogonal()
		if "sting_dir" in e and e.state == "windup" and d < 48.0 and e.st < 0.25:
			return rel.normalized()
		if "strike_speed" in e:
			if e.state == "windup" and e.st < 0.3 and absf(rel.normalized().dot(e.aim.orthogonal())) < 0.4:
				return e.aim.orthogonal()
			if e.state == "warn" and d < e.erupt_radius + 12.0:
				return rel.normalized() if rel != Vector2.ZERO else Vector2.RIGHT
		if e.is_boss:
			if e.state == "windup" and e.st < 0.3 and absf(rel.normalized().dot(e.charge_dir.orthogonal())) < 0.35:
				return e.charge_dir.orthogonal()
			if e.state == "bite" and e.st < 0.25 and d < 75.0:
				return rel.normalized()
	# onde d'urto di Ammit: attraversale scattando verso il centro
	for c in g.world.get_children():
		if "max_r" in c and "r" in c and not c.hit:
			var d: float = pos.distance_to(c.global_position)
			if c.r < d and d - c.r < 34.0:
				return (c.global_position - pos).normalized()
	return Vector2.ZERO


func _pick_door(g):
	var hp_ratio: float = Run.hp / Run.max_hp
	var best = null
	var best_score := -1e9
	for d in g.doors:
		if not is_instance_valid(d):
			continue
		var k: String = d.reward.get("kind", "")
		var score := randf()
		match k:
			"heal":
				score += 3.0 if hp_ratio < cfg["heal"] else -1.0
			"set":
				score += 2.0 if randf() < cfg["set"] else -2.0
			"boon":
				score += 1.0
				if force_god != "" and d.reward.get("god", "") == force_god:
					score += 6.0
			"ka":
				score += 0.3
			"boss", "guardian":
				score += 10.0
			"shop":
				score += 1.2 if Run.ka >= 45 else -1.5
		if score > best_score:
			best_score = score
			best = d
	return best


# ------------------------------------------------------------------ menu dei doni

func _menu(g) -> void:
	var btns: Array = g.menu.find_children("*", "Button", true, false)
	if btns.is_empty():
		return
	var best = btns[0]
	var best_score := -1e9
	if force_anubi != "" and Run.room <= 1 and Run.boons.is_empty():
		if force_anubi == "nessuno" and not anubi_done:
			anubi_done = true
			choices.append("anubi:nessuno")
			g._close_choice()
			return
		for id in Boons.ALL:
			if Boons.ALL[id]["name"] == force_anubi:
				choices.append("anubi:" + force_anubi)
				g._choose_start_boon(id)
				return
	for b in btns:
		var s := _score_card(_card_text(b))
		if s > best_score:
			best_score = s
			best = b
	var lines := _card_text(best).split("\n")
	choices.append(lines[0] + " / " + (lines[1] if lines.size() > 1 else ""))
	best.pressed.emit()


func _card_text(b: Button) -> String:
	return str(b.get_meta("text", b.text))


func _score_card(text: String) -> float:
	var pick: String = cfg["pick"]
	var heavy := text.begins_with("DONO PESANTE")
	var low := text.to_lower()
	var s := randf() * 0.5
	match pick:
		"first":
			return 0.0
		"random":
			return randf()
		"damage":
			for w in ["danni", "danno", "critic", "brucia", "fiamme"]:
				if low.find(w) >= 0:
					s += 1.0
		"defense":
			for w in ["vita", "cura", "scudo", "subisci", "meno"]:
				if low.find(w) >= 0:
					s += 1.0
		"eye":
			for w in ["occhio"]:
				if low.find(w) >= 0:
					s += 2.0
		"value":
			for w in ["danni", "%", "critic", "vita massima"]:
				if low.find(w) >= 0:
					s += 0.7
			if low.find("prezzo") >= 0:
				s -= 0.3
	if heavy:
		s += 2.0 * cfg["heavy"] - 0.8
	return s


# ------------------------------------------------------------------ input

func _apply(p, real: float) -> void:
	var pos: Vector2 = p.global_position
	var dir := move_dir
	if dir != Vector2.ZERO:
		if pos.distance_to(last_pos) < 0.6:
			stuck_t += real
		else:
			stuck_t = 0.0
		if stuck_t > 0.8:
			unstick = dir.orthogonal() * (1.0 if randf() < 0.5 else -1.0)
			unstick_t = 0.5
			stuck_t = 0.0
	last_pos = pos
	if unstick_t > 0.0:
		unstick_t -= real
		dir = (dir * 0.3 + unstick).normalized()
	_axis("move_left", "move_right", dir.x)
	_axis("move_up", "move_down", dir.y)
	_axis("aim_left", "aim_right", aim_dir.x)
	_axis("aim_up", "aim_down", aim_dir.y)
	if want_attack:
		Input.action_press("attack")
	else:
		Input.action_release("attack")
	if dash_now:
		Input.action_press("dash")
		dash_now = false
		dash_release = true
	if tap_special:
		Input.action_press("special")
		tap_special = false
	else:
		Input.action_release("special")
	if tap_super:
		Input.action_press("super")
		tap_super = false
	else:
		Input.action_release("super")


func _axis(neg: String, pos_action: String, v: float) -> void:
	if v < -0.05:
		Input.action_press(neg, -v)
		Input.action_release(pos_action)
	elif v > 0.05:
		Input.action_press(pos_action, v)
		Input.action_release(neg)
	else:
		Input.action_release(neg)
		Input.action_release(pos_action)


func _release_all() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down", "aim_left", "aim_right", "aim_up", "aim_down", "attack", "special", "super", "dash"]:
		Input.action_release(a)


# ------------------------------------------------------------------ metriche

func _metrics(g, _p) -> void:
	if last_hp >= 0.0 and Run.hp < last_hp - 0.01:
		var src: String = Run.last_hit if Run.last_hit != "" else "?"
		if src == "ammit" and g.boss != null and is_instance_valid(g.boss):
			var kind: String = g.boss.state
			for c in g.world.get_children():
				if "max_r" in c and "r" in c:
					kind = "ruggito"
				elif c is Area2D and "style" in c and c.global_position.distance_to(_p.global_position) < 20.0:
					kind = "sputo"
			src = "ammit_" + kind
		dmg[src] = float(dmg.get(src, 0.0)) + (last_hp - Run.hp)
	elif last_hp >= 0.0 and Run.hp > last_hp + 0.01:
		heals += Run.hp - last_hp
	last_hp = Run.hp
	if Run.room != last_room:
		if last_room > 0:
			rooms.append({"room": last_room, "time": snappedf(gt - room_start, 0.1), "hp_end": int(Run.hp), "next": str(g.current_reward.get("kind", "")) + ":" + str(g.current_reward.get("god", ""))})
		last_room = Run.room
		room_start = gt
	if Run.room > Run.ROOMS_PER_RUN:
		boss_time += get_process_delta_time() / maxf(Engine.time_scale, 0.0001)


func _finish(g, forced: String = "") -> void:
	done = true
	var result := "timeout"
	if g.finished:
		result = "win" if not g.player.dead else "death"
	if forced != "":
		result = forced
	var boss_hp := -1.0
	if g.boss != null and is_instance_valid(g.boss):
		boss_hp = snappedf(g.boss.hp / g.boss.max_hp, 0.01)
	var data := {
		"persona": persona, "exp": OS.get_environment("DUAT_EXP"), "tester": OS.get_environment("DUAT_TESTER"), "run_n": OS.get_environment("DUAT_RUN"), "seed": OS.get_environment("DUAT_SEED"), "result": result, "room": Run.room,
		"time": snappedf(gt, 0.1), "boss_time": snappedf(boss_time, 0.1), "boss_hp_left": boss_hp,
		"max_hp": Run.max_hp, "hp": Run.hp, "dmg_taken": dmg, "healed": snappedf(heals, 1),
		"kills": Run.kills, "dmg_dealt": int(Run.damage_dealt), "ka": Run.ka,
		"boons": Run.boons, "blessings": Run.blessings, "curses_left": Run.curses, "choices": choices,
		"rooms": rooms, "dodges": dodges, "shop": shop_buys, "killer": Run.last_hit,
	}
	var f := FileAccess.open(out_path, FileAccess.READ_WRITE if FileAccess.file_exists(out_path) else FileAccess.WRITE)
	f.seek_end()
	f.store_line(JSON.stringify(data))
	f.close()
	get_tree().quit()
