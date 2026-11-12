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
var sand_shield := 0.0                ## scudo di sabbia del Sacerdote di Sokar: assorbe i colpi prima della vita
var shu_t := 0.0                      ## Shu: sta volando per una spinta (lo schianto vale solo ora)
var shu_pushed_t := 0.0               ## Shu, Separatore del Cielo: spinto da poco (2 s)
var spirit_depth := 0                 ## Guida delle Anime: 0 = ucciso da te, n = dall'n-esimo spirito della catena
var elite := false                     ## versione dorata: più grossa, più resistente, lascia più Ka
const HeartScript := preload("res://scripts/heart_drop.gd")
const KA_DROP_CHANCE := 0.4             ## quante volte un nemico lascia il suo Ka (vedi die())
var stagger_t := 0.0
var mourn_t := 0.0                    ## il marchio del Lutto di Nefti (secondi)
var mark_t := 0.0                     ## Sguardo del Falco: secondi in cui il khopesh fa più danni
var slow_pct := 0.0                    ## rallentamento "generico" in percento (Cerchio del Dominio), vale finché slow_t > 0
var slow_t := 0.0                      ## rallentato dalle Frecce della Palude o dalla Frusta della Palude (Sobek)
var hook_slam := false                 ## lanciato dal pastorale: lo schianto usa il Lancio del Vento (Shu)
var no_reward := false                 ## servitori di Aker: niente Ka e niente cuori
var sobek_stun_t := 0.0                ## stordito dal Morso di Sobek (per la Forza del Fiume)                   ## dopo un colpo il nemico barcolla: non si muove e non ferisce


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	if not is_boss:
		max_hp *= Run.enemy_hp_mult()
	if Meta.feather and not is_boss and not miniboss and not Run.in_hub and not Run.trial:
		speed *= 0.9                       # Piuma di Ma'at: nemici un po' più lenti
	if elite:
		max_hp *= 1.8
		contact_damage *= 1.3
		ka_value += 2
		scale = Vector2(1.3, 1.3)
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
		# Pilastro Djed: finché la statua sta in piedi, chi le è vicino insegue lei
		if Run.decoy_t > 0.0 and not is_boss and not miniboss and global_position.distance_to(Run.decoy_pos) < 220.0:
			to = Run.decoy_pos - global_position

	sobek_stun_t = maxf(0.0, sobek_stun_t - delta)
	slow_t = maxf(0.0, slow_t - delta)
	mark_t = maxf(0.0, mark_t - delta)
	mourn_t = maxf(0.0, mourn_t - delta)
	shu_pushed_t = maxf(0.0, shu_pushed_t - delta)
	if stagger_t > 0.0:
		stagger_t -= delta
		velocity = knock
	else:
		var gust := 0.7 if Run.shu_gust and player != null and to.length() < 90.0 else 1.0   # raffica di Shu
		# rallentamenti (pozze, acqua, Sobek, raffica di Shu, Thoth) insieme: mai sotto il 35%
		var slow := maxf(_puddle_slow() * gust * Run.thoth_time(), Run.MIN_ENEMY_SPEED)
		velocity = _behave(delta, to) * Run.enemy_speed_mult() * slow + knock
	var flying := knock
	knock = knock.move_toward(Vector2.ZERO, 800.0 * delta)
	var wanted := velocity.length()
	move_and_slide()
	if shu_t > 0.0:
		_shu_flight(delta, flying)
	_unstick(delta, wanted)

	if contact != null and contact.monitoring and stagger_t <= 0.0 and not _resting():
		for a in contact.get_overlapping_areas():
			var o = a.get_parent()
			if o.is_in_group("player"):
				o.take_damage(_contact_damage(), global_position, self)
	queue_redraw()


## Rete di sicurezza: un nemico normale che vuole muoversi ma resta fermo (incastrato in una tasca
## tra il muro e un oggetto) per 3 secondi ricompare nel punto libero più vicino. Il mega test ha
## trovato scarabei bloccati contro il muro in alto: la stanza non si chiudeva più, e chi combatte
## a distanza non riusciva a colpirli. Boss e guardiani no; chi sta fermo apposta non conta.
var _stuck_hist: Array[Vector2] = []   # dove era negli ultimi controlli (uno al secondo)
var _stuck_check := 1.0
var _stuck_want := 0.0                 # quanto ha "voluto" muoversi dall'ultimo controllo

func _unstick(delta: float, wanted: float) -> void:
	if is_boss or miniboss:
		return
	_stuck_check -= delta
	_stuck_want = maxf(_stuck_want, wanted)
	if _stuck_check > 0.0:
		return
	_stuck_check = 1.0
	# fuori dal pavimento (una spinta fortissima, un balzo oltre il muro): dentro subito
	var gs = get_tree().current_scene
	if gs != null and gs.has_method("_in_floor") and not gs._in_floor(global_position, -6.0):
		_stuck_hist.clear()
		_relocate(gs)
		return
	var pl = get_tree().get_first_node_in_group("player")
	var far: bool = pl == null or global_position.distance_to(pl.global_position) > 60.0
	if _stuck_want < 8.0 or not far:
		_stuck_hist.clear()                # sta fermo apposta, o è nella mischia: non è incastrato
		_stuck_want = 0.0
		return
	_stuck_want = 0.0
	_stuck_hist.append(global_position)
	if _stuck_hist.size() < 4:
		return
	# in 3 secondi non è uscito da un'area di 24 pixel: è incastrato (anche se zigzaga contro il muro)
	var stuck := true
	for q in _stuck_hist:
		if q.distance_to(global_position) > 24.0:
			stuck = false
	_stuck_hist.pop_front()
	if not stuck:
		return
	_stuck_hist.clear()
	_relocate(get_tree().current_scene)


func _relocate(g) -> void:
	if g == null or not g.has_method("_unstick_spot"):
		return
	Fx.burst(global_position, Color(0.8, 0.7, 0.5), 10, 60.0)
	global_position = g._unstick_spot(global_position)
	reset_physics_interpolation()
	Fx.burst(global_position, Color(0.8, 0.7, 0.5), 10, 60.0)


## Regola del 12/11 (sera): un boss o un guardiano che RIPRENDE FIATO non ferisce al contatto. La pausa
## dopo una mossa è il momento in cui il gioco ti invita ad avvicinarti: farti male proprio lì era la
## prima fonte di danni del Serpente (i bot: 342 su ~1500) e uccideva in 20 s chi stava addosso ad Aker.
const RESTING := ["recover", "stuck", "dizzy", "stunned", "punish"]

func _resting() -> bool:
	return (is_boss or miniboss) and "state" in self and str(get("state")) in RESTING


# --- da sovrascrivere nei singoli nemici ----------------------------------------

## Restituisce la velocità voluta. `to` è il vettore verso il giocatore (zero se non c'è).
func _behave(_delta: float, _to: Vector2) -> Vector2:
	return Vector2.ZERO


func _contact_damage() -> float:
	return contact_damage


## Aggira gli ostacoli: se la strada davanti è chiusa (una colonna, un vaso, un altro nemico)
## prova a girare di lato, dal lato che il nemico preferisce, e tiene la deviazione per un
## attimo così non trema avanti e indietro. Prima le mummie restavano incastrate sulle colonne.
var _detour := Vector2.ZERO
var _detour_t := 0.0
var _side := 1.0 if randf() < 0.5 else -1.0
## La strada davanti si controlla circa 8 volte al secondo, non a ogni fotogramma: test_move è una
## domanda al motore fisico, e farla sempre costava 0,14 ms per nemico (uno sciame di 100 scarabei
## da solo prendeva 14 ms, quasi tutto il fotogramma). Tra un controllo e l'altro il nemico tiene
## la decisione presa; se nel frattempo tocca un ostacolo, move_and_slide lo fa scivolare lungo.
var _steer_cd := randf() * 0.12
var _steer_dir := Vector2.ZERO

func _steer(v: Vector2, delta: float) -> Vector2:
	var sp := v.length()
	if sp < 1.0:
		return v
	_detour_t -= delta
	_steer_cd -= delta
	var dir := v / sp
	if _detour_t > 0.0 and _detour.dot(dir) > -0.2:
		return _detour * sp
	if _steer_cd > 0.0 and _steer_dir.dot(dir) > 0.95:
		return v
	_steer_cd = 0.12
	_steer_dir = dir
	if not test_move(global_transform, dir * 12.0):
		return v
	for a in [0.7, 1.2, 1.7]:
		for s in [_side, -_side]:
			var d := dir.rotated(a * s)
			if not test_move(global_transform, d * 12.0):
				_detour = d
				_detour_t = 0.45
				_side = s
				return d * sp
	return v


## Chiamata dopo ogni colpo subito, per reazioni speciali.
func _on_hit(_dmg: float) -> void:
	pass


## Marea del Nilo: dentro una pozza il nemico rallenta. Anche l'acqua delle stanze rallenta
## (non i boss) e spegne le fiamme.
func _puddle_slow() -> float:
	if slow_t > 0.0:
		return (1.0 - maxf(maxf(maxf(Run.val("arco_sobek"), Run.val("flagello_sobek")), maxf(Run.val("sf_gaze"), Run.val("artigli_sobek"))), slow_pct) / 100.0) * _water_tide_slow()
	slow_pct = 0.0
	return _water_tide_slow()


func _water_tide_slow() -> float:
	# le sabbie mobili (l'arena di Aker, le scie): rallentano anche i nemici, non i boss e i servitori di Aker
	if not is_boss and not miniboss and not is_in_group("aker_servants"):
		for q in get_tree().get_nodes_in_group("quicksand"):
			if q.contains(global_position):
				return 0.6
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
const ELITE_GOLD := Color(1.0, 0.82, 0.32)
const ELITE_RIM := Color(0.62, 0.4, 0.08)        ## il bordo degli élite: oro scuro, si legge sul pavimento


## Una forma piena con il contorno scuro.
func _op(pts: PackedVector2Array, fill: Color, w: float = 0.8) -> void:
	draw_colored_polygon(pts, fill)
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, _out(), w * (1.5 if elite else 1.0))


## Un'ellisse come poligono (per corpi e gusci).
func _ell(c: Vector2, rx: float, ry: float, n: int = 14) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## Un arto: una linea col contorno.
func _limb(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	draw_line(a, b, _out(), w + (1.6 if elite else 1.0))
	draw_line(a, b, col, w)


## Un cerchio col contorno.
func _dot(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c, r + (0.9 if elite else 0.6), _out())
	draw_circle(c, r, col)


## Il colore, o bianco nel lampo del colpo. Gli élite hanno una patina d'oro che luccica: il loro
## corpo è dorato, ma gli avvisi degli attacchi (rosso, verde) restano dei loro colori.
func _f(c: Color, flash: bool) -> Color:
	if flash:
		return Color(1, 1, 1, c.a)
	if elite:
		var shine := 0.3 + 0.08 * sin(t * 3.0 + seed_offset)
		return Color(c.lerp(ELITE_GOLD, shine), c.a)
	return c


## Il contorno: scuro, o d'oro per gli élite.
func _out() -> Color:
	return ELITE_RIM if elite else OUT


# --- comune -----------------------------------------------------------------------

## Shu: una spinta vera. Boss, guardiani ed élite si spostano appena. Per qualche istante il nemico
## vola: se sbatte contro un muro, una colonna o un altro nemico subisce lo schianto; se finisce nella
## sabbia nera o in una buca ci cade dentro (e con Sopra la Terra, se è un nemico normale, muore).
func shu_push(dir: Vector2, force: float, hooked: bool = false) -> void:
	if dead or dir == Vector2.ZERO:
		return
	hook_slam = hooked
	var heavy := is_boss or miniboss or elite
	knock = dir.normalized() * force * (0.2 if heavy else 1.0)
	shu_t = 0.5 if not heavy else 0.0
	shu_pushed_t = 2.0


func _shu_flight(delta: float, flying: Vector2) -> void:
	shu_t -= delta
	# Sopra la Terra: spinto nei pericoli del deserto, un nemico normale non si rialza
	if Run.has("shu_above") and not (is_boss or miniboss or elite) and SokarTerrain.grounded(self):
		var into := false
		for r in get_tree().get_nodes_in_group("river"):
			if r.contains(global_position):
				into = true
		for tr2 in get_tree().get_nodes_in_group("traps"):
			if tr2 is SokarTerrain.CrumbleTile and tr2.state == "hole" and tr2._inside(global_position, -2.0):
				into = true
		if into:
			Fx.burst(global_position, Color(0.97, 0.93, 0.82), 16, 90.0)
			Fx.float_text(global_position + Vector2(0, -22), Lang.t("SOPRA LA TERRA"), Boons.god_color("shu"))
			die()
			return
	if flying.length() < 70.0 or get_slide_collision_count() == 0:
		return
	shu_t = 0.0
	var dmg := Run.shu_slam_damage()
	if hook_slam and Run.has("flagello_shu"):
		dmg = maxf(dmg, Run.val("flagello_shu") * Run.all_damage_mult())   # Lancio del Vento
	hook_slam = false
	Fx.burst(global_position + Vector2(0, -radius), Boons.god_color("shu"), 14, 100.0)
	Fx.float_text(global_position + Vector2(0, -24), Lang.t("SCHIANTO"), Boons.god_color("shu"))
	Fx.shake(3.0)
	if Run.has("duo_shu_ra"):
		burn_t = maxf(burn_t, 2.0)        # Vento Ardente: gli schianti incendiano
	if Run.has("shu_heavy"):
		dmg *= 2.0                         # Il Cielo Cade: schianti doppi
	take_hit(dmg, -flying.normalized(), 0.0)


func take_hit(dmg: float, dir: Vector2, kb: float, can_burn: bool = false) -> void:
	if dead:
		return
	dmg *= Run.jackal_mult(hp / max_hp) * _damage_mult()
	if shu_pushed_t > 0.0 and Run.has("shu_divide"):
		dmg *= 1.0 + Run.val("shu_divide") / 100.0      # Separatore del Cielo: chi è appena stato spinto
	if Run.has("sobek_river") and (sobek_stun_t > 0.0 or slow_t > 0.0 or _in_tide()):
		dmg *= 1.0 + Run.val("sobek_river") / 100.0
	if mourn_t > 0.0 and Run.has("nefti_lament"):
		dmg *= 1.0 + Run.val("nefti_lament") / 100.0      # Lamento: i marchiati soffrono di più
	if sand_shield > 0.0:
		# lo scudo di sabbia del Sacerdote di Sokar prende il colpo per primo
		var absorbed := minf(sand_shield, dmg)
		sand_shield -= absorbed
		dmg -= absorbed
		Fx.burst(global_position + Vector2(0, -radius), Color(0.85, 0.7, 0.45), 8, 60.0)
		if sand_shield <= 0.0:
			Sfx.play_at("orb_pop", global_position, 0.1)
		if dmg <= 0.0:
			flash_t = 0.06
			return
	hp -= dmg
	Run.damage_dealt += dmg
	flash_t = 0.1
	stagger_t = maxf(stagger_t, _stagger_time())
	knock = dir * kb
	shu_t = 0.0                            # un colpo normale non è una spinta di Shu: niente schianto
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
	Challenges.on_kill(scene_file_path)
	Sfx.play("kill")
	# solo i nemici più grossi lasciano un po' di Ka, e non sempre (il 40% delle volte; di più con
	# il capitolo 105 del Libro). Il grosso arriva dai tesori: prima si arrivava al Traghettatore
	# con Ka per comprare tutto, e al boss con doni troppo alti e troppa cura.
	var ka := 0 if no_reward or Run.trial else roundi(ka_value * Run.ka_mult())     # nella prova della Sfinge niente Ka
	var ka_chance := KA_DROP_CHANCE if not Run.chap("c105") else Chapters.value("c105") / 100.0
	if not (is_boss or miniboss or elite) and randf() >= ka_chance:
		ka = 0
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
	if heart_chance > 0.0 and not no_reward and not Run.training and Run.feather_halff(Chapters.heart_heal()) > 0.0 and not is_boss and randf() * 100.0 < heart_chance:
		var heart := HeartScript.new()
		heart.amount = Run.feather_halff(Chapters.heart_heal())
		get_parent().add_child.call_deferred(heart)
		heart.position = global_position
	Run.nefti_on_kill(self)                     # Nefti: il Lutto, il Banchetto, l'Ala del Nibbio
	Run.last_kill_depth = spirit_depth          # statistiche (bot): la catena degli spiriti
	if spirit_depth > 0:
		Run.spirit_kills += 1
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
	# la funzione è statica: il nemico che libera lo spirito sparisce subito, e una funzione
	# legata a lui (una lambda) dopo 0,2 secondi trovava i suoi dati già liberati
	get_tree().create_timer(0.2).timeout.connect(Enemy._spirit_strike.bind(ref, from, dmg, spirit_depth + 1))


static func _spirit_strike(ref: WeakRef, from: Vector2, dmg: float, depth: int) -> void:
	var target = ref.get_ref()
	if target != null and not target.dead:
		Fx.burst(target.global_position + Vector2(0, -8), Boons.god_color("anubi"), 12, 80.0)
		target.spirit_depth = depth
		if Run.has("duo_nefti_anubi"):
			target.mourn_t = 4.0              # Corteo delle Anime: lo spirito marchia col Lutto
		if Run.has("duo_thoth_anubi"):
			dmg *= Run.first_word(target)     # Registro dei Morti: anche lo spirito dice la Prima Parola
		target.take_hit(dmg, (target.global_position - from).normalized(), 60.0)
		if is_instance_valid(target) and not target.dead:
			target.spirit_depth = 0


## Regola unica dei colpi (blocco 12): un colpo "di corpo" va a segno solo se le sagome si toccano,
## cioè se la distanza tra i centri è minore di raggio del nemico + raggio del giocatore + 2 px.
const PLAYER_R := 6.0
const TOUCH_PAD := 2.0
## L'unico colore degli avvisi: rosso semitrasparente che si riempie durante la preparazione.
const WARN := Color(1.0, 0.2, 0.15)


func touch_dist(r: float = -1.0) -> float:
	return (radius if r < 0.0 else r) + PLAYER_R + TOUCH_PAD


func touches(p: Node2D, r: float = -1.0, at: Vector2 = Vector2.INF) -> bool:
	var c := global_position if at == Vector2.INF else at
	return p != null and p.global_position.distance_to(c) < touch_dist(r)


## Una striscia d'avviso a terra: lunga `length`, larga 2 × `half` (le misure vere del colpo), che si
## riempie dal nemico verso la punta con `k` (0 → 1 durante la preparazione).
static func warn_strip(ci: CanvasItem, from: Vector2, dir: Vector2, length: float, half: float, k: float) -> void:
	var side := dir.orthogonal() * half
	var a := from
	var b := from + dir * length
	ci.draw_colored_polygon(PackedVector2Array([a + side, b + side, b - side, a - side]), Color(WARN, 0.12))
	var f := a + dir * length * clampf(k, 0.0, 1.0)
	if k > 0.02:
		ci.draw_colored_polygon(PackedVector2Array([a + side, f + side, f - side, a - side]), Color(WARN, 0.18 + 0.17 * k))
	ci.draw_polyline(PackedVector2Array([a + side, b + side, b - side, a - side, a + side]), Color(WARN, 0.55 + 0.35 * k), 1.5)


## Un cerchio d'avviso (zona vera), che si riempie dal centro.
static func warn_circle(ci: CanvasItem, c: Vector2, r: float, k: float) -> void:
	ci.draw_circle(c, r, Color(WARN, 0.1))
	ci.draw_circle(c, r * clampf(k, 0.0, 1.0), Color(WARN, 0.16 + 0.15 * k))
	ci.draw_arc(c, r, 0.0, TAU, 32, Color(WARN, 0.55 + 0.35 * k), 1.5)


## "Mostra aree di danno": il corpo (azzurro) e la distanza di contatto (rosso); i nemici con zone
## speciali (salti, cariche, esplosioni) aggiungono le loro in `_zones()`.
func _draw_zones() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 20, Color(0.3, 0.8, 1.0, 0.9), 1.0)
	draw_arc(Vector2.ZERO, touch_dist(), 0.0, TAU, 28, Color(1.0, 0.3, 0.2, 0.6), 1.0)
	_zones()


func _zones() -> void:
	pass


func _draw() -> void:
	if Run.show_zones():
		_draw_zones()
	draw_set_transform(Vector2(0, 2), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, radius + 3.0, Color(0, 0, 0, 0.5 if Run.region >= 2 else 0.35))     # sul deserto chiaro di Sokar l'ombra stacca i nemici dalla sabbia
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_body(flash_t > 0.0)
	if elite:
		# qualche scintilla d'oro che si stacca dal corpo, al posto dell'alone di prima
		var k := fmod(t * 0.9 + seed_offset, 1.0)
		var sp := Vector2(sin(seed_offset * 7.0 + floorf(t * 0.9) * 2.3) * radius, -radius * (1.0 + 1.6 * k))
		UiStyle.star4(self, sp, 2.0 * (1.0 - k) + 0.6, Color(1.0, 0.9, 0.5, 0.9 * (1.0 - k)))
	if burn_t > 0.0:
		draw_circle(Vector2(0, -radius), radius + 3.0, Color(1, 0.5, 0.1, 0.25))
	if sand_shield > 0.0:
		# lo scudo di sabbia: granelli che girano attorno al nemico
		draw_arc(Vector2(0, -radius), radius + 5.0, 0.0, TAU, 20, Color(0.9, 0.75, 0.45, 0.55), 1.6)
		for i in range(6):
			var a := t * 2.5 + i * TAU / 6.0
			draw_circle(Vector2(0, -radius) + Vector2.from_angle(a) * (radius + 5.0), 1.2, Color(0.95, 0.82, 0.55))
	if mourn_t > 0.0:
		# il Lutto di Nefti: una lacrima d'argento sopra il nemico
		var lp := Vector2(-6, -radius * 2.6 - 6.0)
		draw_circle(lp + Vector2(0, 1.5), 2.2, Boons.god_color("nefti"))
		draw_colored_polygon(PackedVector2Array([lp + Vector2(-2.0, 1.0), lp + Vector2(2.0, 1.0), lp + Vector2(0, -3.5)]), Boons.god_color("nefti"))
		draw_circle(lp + Vector2(0.6, 1.4), 0.8, Color(0.12, 0.16, 0.36))
	if mark_t > 0.0:
		# il segno del falco sopra il nemico
		var mp := Vector2(0, -radius * 2.6 - 6.0)
		draw_arc(mp, 4.0, PI * 1.1, PI * 1.9, 8, Boons.god_color("horus"), 1.5)
		draw_circle(mp + Vector2(0, -1), 1.5, Boons.god_color("horus"))
	if hp < max_hp and not is_boss and not miniboss:
		var w := radius * 2.5
		draw_rect(Rect2(-w / 2.0, -radius * 3.0 - 6.0, w, 3), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(-w / 2.0, -radius * 3.0 - 6.0, w * hp / max_hp, 3), Color(0.85, 0.2, 0.15))
