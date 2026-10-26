extends Enemy
## Il Serpente della Porta: il guardiano a metà della Prima Ora (stanza 5).
## Nel Libro delle Porte ogni porta del Duat è custodita da un grande serpente.
##
## Mosse:
## - Affondo: si ritrae (avviso con la linea), poi scatta con la testa in linea retta.
## - Veleno: sputa un ventaglio di gocce verdi.
## - Sott'acqua: si immerge nelle acque di Wernes (non si può colpire), ti insegue e riemerge.
##   Nell'arena della Porta si tuffa solo dall'acqua alta al centro: quando ci va, sta per sparire.
##   dove eri. Un cerchio a terra avvisa dove uscirà: scatta via.
## Sotto metà vita si infuria: più rapido, ventaglio più largo, e gli affondi diventano doppi.
## Gli sputi, dove cadono, lasciano pozze di veleno per qualche secondo (Hazards.VenomPuddle).
## Con il Peso del Cuore "L'ira del Serpente" ha due mosse in più:
## - Doppia emersione: riemerso, si rituffa subito e riemerge una seconda volta sotto di te.
## - Pioggia di veleno: sputa in alto, e il veleno ricade su sei cerchi intorno a te.
## Combatte da solo.

@warning_ignore("unused_signal")
signal summon(kinds: Array)        # il gioco lo collega a ogni guardiano; questo non lo usa più

const BoltScript := preload("res://scripts/enemy_bolt.gd")

@export var strike_windup := 0.5
@export var strike_speed := 400.0
@export var strike_time := 0.32
@export var venom_count := 5
@export var venom_damage := 8.0
@export var burrow_time := 1.5
@export var erupt_warn := 0.65
@export var erupt_radius := 48.0
@export var erupt_damage := 18.0
@export var double_strike := true      ## infuriato: due affondi di fila

var state := "intro"
var st := 1.4
var aim := Vector2.DOWN
var enraged := false
var summoned := false
var trail: Array[Vector2] = []        # posizioni passate della testa: il corpo le segue
var erupt_at := Vector2.ZERO
var second_strike := false         # infuriato, dopo un affondo ne tenta subito un altro
var second_dive := false           # l'ira del Serpente: la seconda emersione
var ira := false                   # Peso del Cuore: l'ira del Serpente (due mosse in più)


func _ready() -> void:
	miniboss = true
	ira = Weights.rank("ira_serpente") > 0
	# finché non l'hai battuto una volta ha un quarto di vita in meno: il test con i tester
	# virtuali mostrava che il Serpente faceva smettere di giocare chi è alle prime armi
	# (30 su 40 si sono arresi lì). Chi è bravo non se ne accorge: lo batte comunque al primo colpo.
	if Meta.serpent_wins == 0:
		max_hp *= 0.75
	super._ready()
	for i in range(24):
		trail.append(global_position + Vector2(0, -i * 3.0))


func _rage() -> float:
	return 1.25 if enraged else 1.0


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta * _rage()
	if not enraged and hp < max_hp * 0.5:
		enraged = true
		Fx.shake(6.0)
		Fx.float_text(global_position + Vector2(0, -30), Lang.t("IL SERPENTE SI INFURIA"), Color(0.6, 1, 0.5))
		summoned = true                 # niente rinforzi: il guardiano combatte da solo
	_update_trail()
	match state:
		"intro":
			if st <= 0.0:
				_next(1.0)
			return Vector2.ZERO
		"chase":
			if to != Vector2.ZERO:
				aim = to.normalized()
			if st <= 0.0:
				_choose(to)
				return Vector2.ZERO
			var wiggle := aim.orthogonal() * sin(t * 5.0) * 0.5
			return (aim + wiggle).normalized() * speed * _rage()
		"windup":
			if st > strike_windup * 0.45 and to != Vector2.ZERO:
				aim = to.normalized()
			if st <= 0.0:
				state = "strike"
				st = strike_time
				Sfx.play_at("serpent_strike", global_position, 0.05)
			return -aim * 25.0
		"strike":
			if st <= 0.0:
				if enraged and double_strike and not second_strike:
					second_strike = true
					state = "windup"
					st = strike_windup * 0.7
					Sfx.play_at("serpent_hiss", global_position, 0.1)
					return Vector2.ZERO
				second_strike = false
				_next(0.7)
				state = "recover"
			return aim * strike_speed
		"spit":
			if st <= 0.0:
				_venom()
				state = "recover"
				st = 0.6
			return Vector2.ZERO
		"seek_deep":
			var dc := Run.deep_center - global_position
			if Run.in_deep(global_position + dc.normalized() * 30.0) and Run.in_deep(global_position) or st <= 0.0:
				state = "dive"
				st = 0.4
				Fx.burst(global_position, Color(0.55, 0.8, 0.95), 20, 90.0)
				return Vector2.ZERO
			aim = dc.normalized()
			return aim * speed * 1.4 * _rage()
		"dive":
			if st <= 0.0:
				state = "under"
				st = burrow_time
				_set_buried(true)
				Sfx.play_at("serpent_burrow", global_position, 0.1)
			return Vector2.ZERO
		"under":
			if st <= 0.0 or (to != Vector2.ZERO and to.length() < 10.0):
				state = "warn"
				st = erupt_warn * (0.75 if second_dive else 1.0)
				erupt_at = global_position
				return Vector2.ZERO
			if to == Vector2.ZERO:
				return Vector2.ZERO
			return to.normalized() * 150.0 * _rage()
		"warn":
			if st <= 0.0:
				_erupt()
				if ira and not second_dive:
					# l'ira: si rituffa subito e torna a cercarti, con un avviso più corto
					second_dive = true
					state = "dive"
					st = 0.35
					return Vector2.ZERO
				second_dive = false
				state = "recover"
				st = 0.9
			return Vector2.ZERO
		"rain":
			if st <= 0.0:
				_rain(to)
				state = "recover"
				st = 0.8
			return Vector2.ZERO
		"recover":
			if st <= 0.0:
				_next(0.9 + randf() * 0.7)
			return Vector2.ZERO
	return Vector2.ZERO


func _next(time: float) -> void:
	state = "chase"
	st = time


func _choose(to: Vector2) -> void:
	var d := to.length() if to != Vector2.ZERO else 999.0
	var r := randf()
	if ira and randf() < 0.22:
		state = "rain"
		st = 0.7
		Sfx.play_at("cobra_hiss", global_position, 0.05)
		Fx.float_text(global_position + Vector2(0, -34), Lang.t("PIOGGIA DI VELENO"), Color(0.6, 1, 0.5))
		return
	if d < 140.0 and r < 0.5:
		state = "windup"
		st = strike_windup
		Sfx.play_at("serpent_hiss", global_position, 0.05)
	elif r < 0.75:
		state = "spit"
		st = 0.55
		Sfx.play_at("cobra_hiss", global_position, 0.05)
	elif Run.deep_radii != Vector2.ZERO and not Run.in_deep(global_position):
		# si tuffa solo dall'acqua alta: prima ci va (ed è il tuo avviso)
		state = "seek_deep"
		st = 2.5
	else:
		state = "dive"
		st = 0.5
		Fx.burst(global_position, Color(0.55, 0.8, 0.95), 20, 90.0)


func _venom() -> void:
	Sfx.play_at("cobra_spit", global_position, 0.1)
	var n := venom_count + (2 if enraged else 0)
	var spread := deg_to_rad(70.0 if enraged else 55.0)
	for i in range(n):
		var a := -spread / 2.0 + spread * i / maxf(1.0, n - 1.0)
		var bolt: Area2D = BoltScript.new()
		bolt.direction = aim.rotated(a)
		bolt.speed = 165.0
		bolt.damage = venom_damage
		bolt.shooter = self
		bolt.style = "venom"
		bolt.life = randf_range(1.0, 1.5)        # lo sputo cade a terra e lascia la pozza
		get_parent().add_child(bolt)
		bolt.global_position = global_position + Vector2(0, -12) + aim * 12.0


## L'ira del Serpente: il veleno ricade su sei cerchi intorno a te, uno dopo l'altro.
func _rain(to: Vector2) -> void:
	Sfx.play_at("cobra_spit", global_position, 0.1)
	var center := global_position + to
	for i in range(6):
		var drop := Hazards.VenomDrop.new()
		drop.delay = i * 0.12
		drop.src = self
		get_parent().add_child(drop)
		var off := Vector2.ZERO if i == 0 else Vector2.from_angle(randf() * TAU) * randf_range(30.0, 85.0)
		drop.global_position = center + off


func _erupt() -> void:
	_set_buried(false)
	Fx.shake(8.0)
	Fx.burst(global_position, Color(0.6, 0.85, 1.0), 40, 180.0)
	Sfx.play_at("serpent_erupt", global_position, 0.05)
	var player = get_tree().get_first_node_in_group("player")
	if player != null and not player.dead and player.global_position.distance_to(global_position) < erupt_radius:
		player.take_damage(erupt_damage, global_position, self)


## Sott'acqua non lo si può colpire e non ferisce al contatto.
func _set_buried(on: bool) -> void:
	if on:
		remove_from_group("enemies")
		collision_layer = 0
		if contact != null:
			contact.monitoring = false
	else:
		add_to_group("enemies")
		collision_layer = 4
		if contact != null:
			contact.monitoring = true


func _update_trail() -> void:
	if trail.is_empty() or trail[0].distance_to(global_position) > 3.0:
		trail.push_front(global_position)
		if trail.size() > 24:
			trail.pop_back()


## Un serpente di quella stazza non barcolla e quasi non viene spinto.
func _stagger_time() -> float:
	return 0.0


func _on_hit(_dmg: float) -> void:
	knock *= 0.1


## Il grande serpente delle porte: scaglie verde scuro a fasce d'oro, ventre chiaro, la testa
## larga col cappuccio dipinto e gli occhi che si accendono di rosso nella furia.
func _draw_body(flash: bool) -> void:
	var skin := _f(Color(0.2, 0.4, 0.28), flash)
	var skin_d := _f(Color(0.12, 0.26, 0.18), flash)
	var belly := _f(Color(0.88, 0.76, 0.45), flash)
	var band := _f(GOLD, flash)
	if state == "under" or state == "warn":
		# sott'acqua: un'ombra scura, due occhi che brillano e la scia a V che si allarga dietro
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, 12.0, Color(0.02, 0.08, 0.06, 0.55))
		for i in range(3):
			var rr := fmod(t * 22.0 + i * 8.0, 24.0)
			draw_arc(Vector2.ZERO, rr, 0.0, TAU, 20, Color(0.7, 0.9, 1.0, 0.35 * (1.0 - rr / 24.0)), 1.2)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var back := -velocity.normalized() if velocity.length() > 5.0 else Vector2.DOWN
		for sx in [-1.0, 1.0]:
			draw_line(Vector2.ZERO, back.rotated(sx * 0.45) * 26.0, Color(0.75, 0.92, 1.0, 0.45), 1.2)
		draw_circle(Vector2(-2.5, -1), 1.1, Color(1.0, 0.85, 0.3))
		draw_circle(Vector2(2.5, -1), 1.1, Color(1.0, 0.85, 0.3))
		if state == "warn":
			var k := 1.0 - st / erupt_warn
			draw_arc(Vector2.ZERO, erupt_radius, 0.0, TAU, 40, Color(1, 0.3, 0.2, 0.5 + 0.4 * k), 2.0)
			draw_circle(Vector2.ZERO, erupt_radius * k, Color(1, 0.3, 0.2, 0.18))
		return
	# il corpo lungo la scia, dalla coda alla testa: prima tutti i contorni, poi le scaglie
	var n := trail.size()
	for pass_i in range(2):
		for i in range(n - 1, 0, -2):
			var p: Vector2 = trail[i] - global_position + Vector2(0, -6)
			var r := lerpf(10.0, 3.5, float(i) / n)
			if pass_i == 0:
				draw_circle(p, r + 1.0, OUT)
				continue
			var seg := int(i / 2.0)
			draw_circle(p, r, skin_d if seg % 2 == 0 else skin)
			draw_circle(p + Vector2(0, r * 0.45), r * 0.55, belly)
			if seg % 3 == 0:
				draw_arc(p, r * 0.8, PI * 1.1, PI * 1.9, 8, band, 1.4)
			draw_circle(p + Vector2(-r * 0.3, -r * 0.35), r * 0.18, Color(1, 1, 1, 0.18))
	# la testa col cappuccio, girata dove guarda
	var h := Vector2(0, -12)
	if state == "windup":
		h -= aim * 6.0
		draw_line(Vector2(0, -12), Vector2(0, -12) + aim * strike_speed * strike_time, Color(1, 0.2, 0.15, 0.5), 3.0)
	draw_set_transform(h, aim.angle(), Vector2.ONE)
	var hood := PackedVector2Array([Vector2(-9, 0), Vector2(-6, -12), Vector2(1, -14), Vector2(5, -8), Vector2(5, 8), Vector2(1, 14), Vector2(-6, 12)])
	_op(hood, skin_d, 1.0)
	# il disegno sul cappuccio: due occhi finti d'oro e le fasce
	for sy in [-1.0, 1.0]:
		_op(_ell(Vector2(-2.5, 7.5 * sy), 2.4, 2.0, 10), band, 0.6)
		draw_circle(Vector2(-2.3, 7.5 * sy), 0.9, OUT)
	draw_line(Vector2(-6, -9), Vector2(-6, 9), band, 1.0)
	# la testa: larga dietro, muso arrotondato in avanti
	var head := PackedVector2Array([Vector2(-1, -7), Vector2(7, -6.5), Vector2(14, -3.5), Vector2(16, 0), Vector2(14, 3.5), Vector2(7, 6.5), Vector2(-1, 7)])
	_op(head, skin, 1.0)
	draw_line(Vector2(3, 0), Vector2(14, 0), skin_d, 0.8)
	for k in range(3):
		draw_arc(Vector2(2.0 + k * 3.0, 0), 4.5, -0.9, 0.9, 5, skin_d, 0.6)
	var glow := Color(1, 0.25, 0.15) if enraged else Color(1, 0.85, 0.3)
	if flash:
		glow = Color.WHITE
	for sy in [-1.0, 1.0]:
		draw_circle(Vector2(9.0, 4.0 * sy), 2.2, OUT)
		draw_circle(Vector2(9.0, 4.0 * sy), 1.6, glow)
		draw_line(Vector2(8.0, 4.0 * sy), Vector2(10.0, 4.0 * sy), OUT, 0.5)
	if state == "spit":
		_op(PackedVector2Array([Vector2(13, -2.5), Vector2(19, -3.5), Vector2(19, 3.5), Vector2(13, 2.5)]), Color(0.7, 0.15, 0.15), 0.6)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if state == "spit":
		draw_circle(h + aim * 18.0, 3.0 + (0.55 - st) * 6.0, Color(0.5, 1, 0.4, 0.6))
