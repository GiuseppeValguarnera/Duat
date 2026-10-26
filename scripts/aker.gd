extends Enemy
## Aker, il dio dell'orizzonte: il boss di Sokar. Nei templi è dipinto come due leoni sdraiati
## schiena contro schiena, Ieri che guarda a ovest e Domani che guarda a est; la barca del sole
## di notte passa dentro il suo corpo. Qui porta sulla schiena il disco del sole spento.
##
## Fase 1, il leone doppio: due teste, una per lato. Non ha un "dietro": il punto debole sono i
## FIANCHI (sopra e sotto il corpo), dove i colpi fanno più male; sulle teste meno. Lui si sposta
## per avere sempre una testa davanti a te.
## - Testa di sabbia (Ieri): soffio a cono che ti spinge via e lascia sabbie mobili per poco.
## - Testa di fuoco (Domani): il raggio dell'alba (Hazards.DawnRay), una linea di fuoco che ruota.
## - Si gira: mezzo giro, le teste si scambiano. Il pericolo cambia lato.
## - Ruggito: dalle montagne cadono pietre (Hazards.FallingStone). Restano come riparo e FERMANO
##   il raggio dell'alba: la mossa che ti minaccia ti dà anche il riparo dalla prossima.
## A metà vita trema (1,8 s, non lo si può ferire, cadono pietre) e si divide in due: Ieri e Domani
## (aker_lion.gd), ognuno con metà della vita rimasta. La barra della vita resta una sola.

@warning_ignore("unused_signal")
signal summon(kinds: Array)        # il gioco lo collega a ogni boss: Aker non chiama rinforzi
signal split(lions: Array)          ## si divide: il gioco aggiunge i due leoni (game.gd)

const LionScene := preload("res://scenes/aker_lion.tscn")
const S := 1.8                        ## scala del disegno
const HEAD := Vector2(52, -22)        ## dove sono le teste rispetto al centro (x col segno del lato)
const SAND := Color(0.78, 0.62, 0.38)

@export var breath_windup := 0.65
@export var breath_time := 0.7
@export var breath_range := 160.0
@export var breath_angle := 64.0      ## ampiezza del cono, in gradi
@export var breath_damage := 8.0
@export var ray_sweep := 100.0
@export var ray_damage := 9.0
@export var roar_stones := 4
@export var flank_mult := 1.35        ## colpi sui fianchi
@export var head_mult := 0.8          ## colpi sulle teste

var state := "intro"
var st := 1.6
var swapped := false                  # false: sabbia a ovest (sinistra), fuoco a est
var side := -1.0                      # la testa che ti guarda (-1 ovest, +1 est)
var aim := Vector2.LEFT
var roar_cd := 5.0
var same_side := 0
var breath_hit := false
var ray: Node2D = null
var split_done := false
var turned := false
## Il pavimento dell'arena (game.gd, prima che entri in scena): dove possono cadere le pietre.
var floor_rect := Rect2(32, 64, 736, 384)


func _ready() -> void:
	is_boss = true
	super._ready()


func head_kind(sd: float) -> String:
	return "sand" if (sd < 0.0) != swapped else "fire"


func head_pos(sd: float) -> Vector2:
	return global_position + Vector2(HEAD.x * sd, HEAD.y)


func busy() -> bool:
	return state != "stalk"


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta
	roar_cd -= delta
	if not split_done and state != "tremble" and hp <= max_hp * 0.5:
		_start_tremble()
	if to != Vector2.ZERO and state in ["stalk", "recover"]:
		side = -1.0 if to.x < 0.0 else 1.0
	match state:
		"intro":
			if st <= 0.0:
				_next(0.5)
			return Vector2.ZERO
		"stalk":
			if st <= 0.0:
				_choose(to)
				return Vector2.ZERO
			# si allinea con te (una testa davanti) e tiene la distanza giusta
			var v := Vector2.ZERO
			if absf(to.y) > 10.0:
				v.y = signf(to.y)
			if absf(to.x) < 100.0:
				v.x = -signf(to.x) if to.x != 0.0 else 1.0
			elif absf(to.x) > 210.0:
				v.x = signf(to.x)
			return _steer(v.normalized() * speed, delta) if v != Vector2.ZERO else Vector2.ZERO
		"breath_windup":
			if st > breath_windup * 0.5:
				_aim_breath(to)
			if st <= 0.0:
				state = "breath"
				st = breath_time
				breath_hit = false
				Sfx.play_at("fire_whoosh", global_position, 0.2)
				for k in [0.4, 0.75]:
					var q := Hazards.Quicksand.new()
					q.radii = Vector2(26, 15)
					q.life = 4.0
					q.position = head_pos(side) + aim * breath_range * float(k) + Vector2(0, 22)
					get_parent().add_child(q)
			return Vector2.ZERO
		"breath":
			_blast(delta)
			if st <= 0.0:
				state = "recover"
				st = 0.7
			return Vector2.ZERO
		"ray":
			if st <= 0.0:
				state = "recover"
				st = 0.6
			return Vector2.ZERO
		"turn":
			if st <= 0.35 and not turned:
				turned = true
				swapped = not swapped
			if st <= 0.0:
				turned = false
				state = "recover"
				st = 0.4
			return Vector2.ZERO
		"roar":
			if st <= 0.0:
				_drop_stones(roar_stones + (2 if hp < max_hp * 0.75 else 0))
				state = "recover"
				st = 0.8
			return Vector2.ZERO
		"tremble":
			if st <= 0.0:
				_split()
			return Vector2(sin(t * 60.0) * 30.0, 0.0)
		"recover":
			if st <= 0.0:
				_next(0.6 + randf() * 0.6)
			return Vector2.ZERO
	return Vector2.ZERO


func _next(time: float) -> void:
	state = "stalk"
	st = time


func _choose(to: Vector2) -> void:
	if roar_cd <= 0.0:
		state = "roar"
		st = 0.9
		roar_cd = randf_range(8.0, 10.0)
		Sfx.play_at("roar", global_position, 0.05)
		Fx.shake(5.0)
		return
	if same_side >= 2 and randf() < 0.55:
		state = "turn"
		st = 0.7
		same_side = 0
		Sfx.play_at("amheh_growl", global_position, 0.1)
		return
	same_side += 1
	if head_kind(side) == "sand":
		if absf(to.x) < breath_range + 30.0 and absf(to.y) < 90.0:
			state = "breath_windup"
			st = breath_windup
			_aim_breath(to)
			Sfx.play_at("amheh_growl", global_position, 0.1)
		else:
			_next(0.5)
		return
	_fire_ray(to, ray_sweep, ray_damage)


## Il cono del soffio esce dalla testa, verso di te ma mai all'indietro.
func _aim_breath(to: Vector2) -> void:
	var from := head_pos(side) - global_position
	var d := to - from
	if d == Vector2.ZERO or signf(d.x) != side:
		d = Vector2(side, 0.0)
	aim = d.normalized()
	if absf(aim.angle_to(Vector2(side, 0.0))) > deg_to_rad(55.0):
		aim = Vector2(side, 0.0).rotated(deg_to_rad(55.0) * signf(Vector2(side, 0.0).angle_to(aim)))


func _blast(delta: float) -> void:
	var p = get_tree().get_first_node_in_group("player")
	if p == null or p.dead or p.dash_t > 0.0:
		return
	var o := head_pos(side)
	var rel: Vector2 = p.global_position + Vector2(0, -6) - o
	if rel.length() < breath_range and absf(aim.angle_to(rel)) < deg_to_rad(breath_angle) * 0.5:
		p.move_and_collide(rel.normalized() * 190.0 * delta)
		if not breath_hit and p.take_damage(breath_damage, o, self):
			breath_hit = true
		if randf() < 0.4:
			Fx.burst(p.global_position, SAND, 2, 40.0)


func _fire_ray(to: Vector2, sweep_deg: float, dmg: float) -> void:
	state = "ray"
	var r := Hazards.DawnRay.new()
	var o := head_pos(side)
	var tp := global_position + to + Vector2(0, -6)
	var sw := deg_to_rad(sweep_deg) * (1.0 if randf() < 0.5 else -1.0)
	r.angle = (tp - o).angle() - sw * 0.5
	r.sweep = sw
	r.damage = dmg
	r.src = self
	r.position = o
	get_parent().add_child(r)
	ray = r
	st = r.warn + r.dur + 0.1


## Il ruggito: le pietre cadono dalle montagne. Una sempre dove sei tu, le altre sparse.
func _drop_stones(n: int) -> void:
	var p = get_tree().get_first_node_in_group("player")
	var spots: Array[Vector2] = []
	if p != null and not p.dead:
		spots.append(p.global_position + Vector2(randf_range(-10, 10), randf_range(-6, 6)))
	var area := floor_rect.grow(-30.0)
	var tries := 0
	while spots.size() < n and tries < 80:
		tries += 1
		var c := Vector2(randf_range(area.position.x, area.end.x), randf_range(area.position.y, area.end.y))
		if c.distance_to(global_position) < 70.0:
			continue
		var ok := true
		for o in spots:
			if o.distance_to(c) < 40.0:
				ok = false
				break
		if ok:
			spots.append(c)
	for i in range(spots.size()):
		var stone := Hazards.FallingStone.new()
		stone.position = spots[i]
		stone.warn = 0.9 + i * 0.08
		get_parent().add_child(stone)


func _start_tremble() -> void:
	state = "tremble"
	st = 1.8
	if ray != null and is_instance_valid(ray):
		ray.queue_free()
	hp = max_hp * 0.5
	Fx.shake(10.0)
	Fx.float_text(global_position + Vector2(0, -60), Lang.t("AKER TREMA"), Color(1, 0.85, 0.5))
	Sfx.play_at("roar", global_position, 0.0)
	_drop_stones(6)


## Si divide: Ieri (sabbia) dalla testa di ovest... o di est, se si è girato; Domani dall'altra.
func _split() -> void:
	split_done = true
	var ieri: Enemy = LionScene.instantiate()
	var domani: Enemy = LionScene.instantiate()
	ieri.set("kind", "ieri")
	domani.set("kind", "domani")
	var sand_side := -1.0 if not swapped else 1.0
	ieri.position = global_position + Vector2(sand_side * 30.0, 4.0)
	domani.position = global_position + Vector2(-sand_side * 30.0, 4.0)
	ieri.set("partner", domani)
	domani.set("partner", ieri)
	ieri.set("floor_rect", floor_rect)
	domani.set("floor_rect", floor_rect)
	Fx.shake(12.0)
	Fx.burst(global_position + Vector2(0, -30), Color(0.6, 0.6, 0.62), 30, 160.0)      # il disco spento si spezza
	Fx.burst(global_position, SAND, 40, 200.0)
	Sfx.play_at("serpent_erupt", global_position, 0.0)
	split.emit([ieri, domani])
	dead = true
	remove_from_group("enemies")
	queue_free()


## I fianchi sono il punto debole; sulle teste i colpi fanno meno. Mentre trema non lo si ferisce.
func take_hit(dmg: float, dir: Vector2, kb: float, can_burn: bool = false) -> void:
	if dead:
		return
	if state == "tremble" or split_done:
		Fx.burst(global_position + Vector2(0, -20), Color(1, 0.9, 0.6), 4, 40.0)
		return
	var m := 1.0
	var p = get_tree().get_first_node_in_group("player")
	if p != null:
		var rel: Vector2 = p.global_position - global_position
		m = flank_mult if absf(rel.y) > absf(rel.x) * 0.55 else head_mult
	super.take_hit(dmg * m, dir, kb, can_burn)
	if not dead and hp < max_hp * 0.5:
		hp = max_hp * 0.5              # il colpo che porta a metà vita non va oltre: tocca ai due leoni


func _stagger_time() -> float:
	return 0.0


func _on_hit(_dmg: float) -> void:
	knock = Vector2.ZERO


# ---------------------------------------------------------------- disegno

func _draw() -> void:
	# l'ombra larga dei due corpi (quella della base è tonda)
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, 62.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_body(flash_t > 0.0)
	_draw_warnings()


func _draw_body(flash: bool) -> void:
	var fx := 1.0
	if state == "turn":
		fx = absf(cos((1.0 - st / 0.7) * PI))
	var shake := Vector2(sin(t * 70.0) * 2.0, 0.0) if state == "tremble" else Vector2.ZERO
	draw_set_transform(shake, 0.0, Vector2(maxf(fx, 0.05), 1.0))
	var west: Dictionary = AkerArt.IERI if not swapped else AkerArt.DOMANI
	var east: Dictionary = AkerArt.DOMANI if not swapped else AkerArt.IERI
	var mouth_w := 0.0
	var mouth_e := 0.0
	var k := 0.0
	if state in ["breath_windup", "breath", "ray"]:
		k = 1.0 if state != "breath_windup" else 1.0 - st / breath_windup
		if side < 0.0:
			mouth_w = k
		else:
			mouth_e = k
	elif state in ["roar", "tremble"]:
		mouth_w = 1.0
		mouth_e = 1.0
	var fire_glow := 0.4 + (0.6 if state == "ray" else 0.0)
	AkerArt.lion(self, Vector2(-22, 0), -1.0, S, west, "lying", t, mouth_w, fire_glow if west == AkerArt.DOMANI else 0.0, flash, false)
	AkerArt.lion(self, Vector2(22, 0), 1.0, S, east, "lying", t, mouth_e, fire_glow if east == AkerArt.DOMANI else 0.0, flash, false)
	# il disco del sole spento portato sulla schiena, tra i due leoni
	var dc := Vector2(0, -38)
	draw_circle(dc, 11.0, OUT)
	draw_circle(dc, 10.0, Color(0.4, 0.4, 0.44) if not flash else Color.WHITE)
	draw_circle(dc + Vector2(-2, -2), 6.0, Color(0.5, 0.5, 0.54) if not flash else Color.WHITE)
	if state == "tremble":
		var kk := 1.0 - st / 1.8
		for i in range(5):
			var a := i * 1.3
			draw_line(dc, dc + Vector2.from_angle(a) * 10.0 * kk, Color(1, 0.85, 0.5), 1.2)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_warnings() -> void:
	if state == "breath_windup" or state == "breath":
		var o := head_pos(side) - global_position
		var half := deg_to_rad(breath_angle) * 0.5
		var k := 1.0 if state == "breath" else 1.0 - st / breath_windup
		var pts := PackedVector2Array([o])
		for i in range(13):
			pts.append(o + aim.rotated(-half + half * 2.0 * i / 12.0) * breath_range)
		var col := Color(0.95, 0.75, 0.4, 0.12 + 0.2 * k) if state == "breath_windup" else Color(0.85, 0.68, 0.4, 0.4)
		draw_colored_polygon(pts, col)
		var edge := pts.slice(1)
		draw_polyline(edge, Color(1, 0.35, 0.15, 0.5 + 0.4 * k), 2.0)
		if state == "breath":
			for i in range(8):
				var f := fmod(t * 3.0 + i * 0.125, 1.0)
				var dd := aim.rotated((i - 3.5) * half / 4.0) * breath_range * f
				draw_circle(o + dd, 2.0 + 3.0 * f, Color(0.9, 0.75, 0.48, 0.7 * (1.0 - f)))
