class_name Incisions
## Le incisioni di Ptah (blocco 26). A volte, dopo la prima vittoria sul Serpente, una porta ha il
## martello di Ptah: dietro, l'incudine. Scegli un'incisione su tre e il posto (1-3) in cui inciderla
## sull'arma. Due incisioni VICINE formano una lega, con un effetto in più: conta chi sta in mezzo.
## Le leghe scoperte restano nel Registro della bottega (Cortile di Neith); quelle mancanti si vedono
## come «???» con un indizio. Valgono per tutte le armi, finché dura la discesa. Niente nella Sfinge.
## Gli effetti passano dai punti comuni dei colpi (Run.player_hit / after_player_hit), dallo scatto,
## dalle uccisioni (game._on_enemy_killed) e dal Manager (veleno, cura del Fiore del Nilo).

const SLOTS := 3
const LAPIS_PER_ALLOY := 5                ## lapislazzuli per ogni lega scoperta
const REGISTRY_LAPIS := 30                ## registro completo (tutte e 12): una volta sola
## La porta del martello: sempre a caso, mai in momenti fissi.
const DOOR_CHANCE := 0.10                 ## probabilità a ogni scelta di porte
const DOOR_STEP := 0.03                   ## +3% a ogni scelta senza martello
const DOOR_MAX_REGION := 2                ## al massimo due incudini per regione
const DOOR_GAP := 2                       ## almeno due stanze tra un'incudine e l'altra
const COLOR := Color(1.0, 0.58, 0.22)     ## il bronzo rovente della fucina di Ptah

# --- numeri degli effetti (tarati come un dono di livello 1; le leghe come un dono doppio) ---
const LEONE_DMG := 0.30                   ## colpo finale +40%
const LEONE_AREA := 1.25                  ## e area +25%
const BALZO_REACH := 1.45                  ## Balzo del Leone: il colpo dopo lo scatto
const POOL_EVERY := 5                     ## una pozza ogni 5 colpi a segno
const POOL_GAP := 0.6
const POOL_MAX := 3
const POOL_R := 22.0
const POOL_BIG_R := 34.0
const POOL_LIFE := 4.0
const POOL_SLOW := 25.0                   ## percento
const DART_EVERY := 4
const DART_EVERY_FALCO := 3
const DART_DMG := 0.30                    ## del danno base dell'arma
const DART_SPEED := 380.0
const DART_LIFE := 0.6
const DART_BLAST_R := 22.0
const DART_BLAST_K := 0.35                ## Occhio di Ra: l'esplosione fa il 35% del dardo
const DART_PIERCE := 2                    ## Sguardo del Falco: il dardo trapassa al massimo 2 nemici
const SOLE_CRIT := 0.06
const SOLE_BURN := 3.0
const TRAIL_LIFE := 1.2
const TRAIL_DMG := 0.5
const TRAIL_GAP := 0.4
const TRAIL_R := 13.0
const POISON_K := 0.15                    ## del danno base, ogni mezzo secondo
const POISON_TIME := 2.0
const POISON_STACKS := 3
const FALCO_REACH := 1.15
const LOTO_ART := 0.25                    ## secondi tolti alla ricarica dell'Arte per uccisione
const MATTINO_K := 0.10                   ## Loto del mattino: per uccisione con l'Arte
const MATTINO_MAX := 0.30
const FIORE_HEAL := 1.0
const FIORE_MAX := 10.0
const VOLO_SPEED := 0.10
const VOLO_TIME := 2.0
const VOLO_STACKS := 3
const PIENA_PUSH := 220.0

const ALL_IT := {
	"leone": {"name": "Leone", "desc": "Il colpo finale della serie fa il 30% di danni in più e prende un'area più larga del 25%. Con l'arco: ogni terza freccia."},
	"acqua": {"name": "Acqua", "desc": "Ogni 5 colpi a segno lasci una pozza che rallenta i nemici del 25% (al massimo 3 pozze)."},
	"occhio": {"name": "Occhio", "desc": "Ogni 4 colpi a segno parte un dardo dritto verso il nemico più vicino (30% del danno dell'arma). Non insegue."},
	"sole": {"name": "Sole", "desc": "+6% di probabilità di critico; i critici incendiano."},
	"scarabeo": {"name": "Scarabeo", "desc": "Lo scatto lascia una scia che ferisce i nemici che la toccano."},
	"serpente": {"name": "Serpente", "desc": "I colpi avvelenano per 2 secondi (fino a 3 dosi insieme)."},
	"falco": {"name": "Falco", "desc": "Portata e gittata +15%."},
	"loto": {"name": "Loto", "desc": "Ogni nemico abbattuto toglie un quarto di secondo alla ricarica dell'Arte."},
}

## Le leghe: la chiave è la coppia in ordine alfabetico ("a+b").
const ALLOYS_IT := {
	"occhio+sole": {"name": "Occhio di Ra", "desc": "I dardi dell'Occhio bruciano ed esplodono in un piccolo cerchio.", "hint": "Quando l'occhio fissa il sole…"},
	"acqua+serpente": {"name": "Palude", "desc": "Le tue pozze avvelenano chi ci passa sopra.", "hint": "Nell'acqua ferma qualcosa striscia."},
	"leone+sole": {"name": "Furia di Sekhmet", "desc": "Il colpo finale incendia tutto ciò che prende.", "hint": "La leonessa ha la criniera di fuoco."},
	"falco+occhio": {"name": "Sguardo del Falco", "desc": "Un dardo ogni 3 colpi invece di 4, e trapassa un nemico.", "hint": "Chi vola alto vede più lontano."},
	"scarabeo+sole": {"name": "Khepri all'alba", "desc": "La scia dello scatto brucia.", "hint": "Lo scarabeo spinge il disco all'orizzonte."},
	"acqua+loto": {"name": "Fiore del Nilo", "desc": "Dentro le tue pozze recuperi 1 vita al secondo (al massimo 10 a stanza).", "hint": "Il fiore si apre sull'acqua."},
	"falco+leone": {"name": "Balzo del Leone", "desc": "Il colpo subito dopo lo scatto conta come colpo finale e arriva il 45% più lontano.", "hint": "Il re delle belve impara a volare."},
	"scarabeo+serpente": {"name": "Sabbia velenosa", "desc": "La scia dello scatto avvelena.", "hint": "Sotto la sabbia, i denti."},
	"loto+sole": {"name": "Loto del mattino", "desc": "Ogni nemico abbattuto dall'Arte le restituisce il 10% della ricarica (al massimo il 30%).", "hint": "Al primo raggio il loto rinasce."},
	"occhio+serpente": {"name": "Sputo del cobra", "desc": "I dardi avvelenano e rallentano.", "hint": "Il cobra mira agli occhi."},
	"acqua+leone": {"name": "Piena", "desc": "Il colpo finale spinge via i nemici e lascia una pozza grande.", "hint": "Il fiume ruggisce quando sale."},
	"falco+loto": {"name": "Volo dell'anima", "desc": "Ogni nemico abbattuto: +10% di velocità per 2 secondi (fino a 3 volte).", "hint": "L'anima lascia il corpo e prende il volo."},
}

const ORDER := ["leone", "acqua", "occhio", "sole", "scarabeo", "serpente", "falco", "loto"]

static var ALL: Dictionary = Lang.deep(ALL_IT)
static var ALLOYS: Dictionary = Lang.deep(ALLOYS_IT)


static func refresh_lang() -> void:
	ALL = Lang.deep(ALL_IT)
	ALLOYS = Lang.deep(ALLOYS_IT)


## Le incisioni ci sono in questa discesa? (dopo la prima vittoria sul Serpente, mai nella Sfinge)
static func unlocked() -> bool:
	return Meta.serpent_wins >= 1 or OS.get_environment("DUAT_PTAH") != ""


static func key(a: String, b: String) -> String:
	return (a + "+" + b) if a < b else (b + "+" + a)


## Le leghe attive con questi posti: le coppie vicine 1-2 e 2-3.
static func alloys_of(slots: Array) -> Array:
	var out := []
	for i in range(slots.size() - 1):
		var a: String = slots[i]
		var b: String = slots[i + 1]
		if a == "" or b == "" or a == b:
			continue
		var k := key(a, b)
		if ALLOYS_IT.has(k) and not out.has(k):
			out.append(k)
	return out


static func has(id: String) -> bool:
	return not Run.trial and Run.incisions.has(id)


static func alloy(name_key: String) -> bool:
	if Run.trial:
		return false
	match name_key:
		"ra": return Run.alloys.has("occhio+sole")
		"palude": return Run.alloys.has("acqua+serpente")
		"sekhmet": return Run.alloys.has("leone+sole")
		"falco": return Run.alloys.has("falco+occhio")
		"khepri": return Run.alloys.has("scarabeo+sole")
		"fiore": return Run.alloys.has("acqua+loto")
		"balzo": return Run.alloys.has("falco+leone")
		"sabbia": return Run.alloys.has("scarabeo+serpente")
		"mattino": return Run.alloys.has("loto+sole")
		"cobra": return Run.alloys.has("occhio+serpente")
		"piena": return Run.alloys.has("acqua+leone")
		"volo": return Run.alloys.has("falco+loto")
	return false


## Tre incisioni da offrire: diverse tra loro; preferisce quelle che non hai.
static func offers() -> Array:
	var fresh: Array = []
	var known: Array = []
	for id in ORDER:
		if Run.incisions.has(id):
			known.append(id)
		else:
			fresh.append(id)
	fresh.shuffle()
	known.shuffle()
	return (fresh + known).slice(0, 3)


## Che leghe formerei mettendo `id` nel posto `slot`.
static func preview(id: String, slot: int) -> Array:
	var s: Array = Run.incisions.duplicate()
	s[slot] = id
	return alloys_of(s)


## Incide `id` nel posto `slot`; restituisce le leghe NUOVE per il registro.
static func engrave(id: String, slot: int) -> Array:
	Run.incisions[slot] = id
	Run.alloys = alloys_of(Run.incisions)
	var discovered := []
	for k in Run.alloys:
		if not Meta.alloys_found.has(k):
			Meta.alloys_found.append(k)
			discovered.append(k)
	Meta.save()
	return discovered


static func reach_mult() -> float:
	return FALCO_REACH if has("falco") else 1.0


static func crit_bonus() -> float:
	return SOLE_CRIT if has("sole") else 0.0


## Il colpo che sta andando a segno è il "colpo finale" (terzo della serie o, col Balzo, dopo lo scatto)?
static func finisher() -> bool:
	return Run.inc_finisher_frame == Engine.get_physics_frames()


static func mark_finisher() -> void:
	Run.inc_finisher_frame = Engine.get_physics_frames()


## Il danno base dell'arma (come per l'Arte): dardi, scie, veleno ne prendono una parte.
static func base_damage() -> float:
	var tree := Engine.get_main_loop() as SceneTree
	var p = tree.get_first_node_in_group("player") if tree != null else null
	if p == null or not p.has_method("inc_base"):
		return 10.0
	return p.inc_base()


# --- gli effetti, chiamati da run.gd --------------------------------------------------------

## Prima del colpo: il moltiplicatore.
static func hit_mult(_e: Node) -> float:
	if Run.trial or Run.incisions.is_empty():
		return 1.0
	var m := 1.0
	if has("leone") and finisher():
		m *= 1.0 + LEONE_DMG
	return m


## Dopo il colpo (il nemico ha già preso i danni).
static func after_hit(e: Node, dir: Vector2, fx: bool) -> void:
	if Run.trial or Run.incisions.is_empty() or e == null or not is_instance_valid(e):
		return
	var tree: SceneTree = e.get_tree()
	var fin := finisher()
	if has("sole") and Run.last_crit_frame == Engine.get_physics_frames() and not e.dead:
		e.burn_t = maxf(e.burn_t, SOLE_BURN)
	if fin and alloy("sekhmet") and not e.dead:
		e.burn_t = maxf(e.burn_t, SOLE_BURN)
	if has("serpente") and fx and not Run.inc_dart_hit and not e.dead:
		poison(e)
	if fin and alloy("piena"):
		if not e.dead and dir != Vector2.ZERO:
			e.shu_push(dir.normalized(), PIENA_PUSH)
		if Run.inc_piena_frame != Engine.get_physics_frames():
			Run.inc_piena_frame = Engine.get_physics_frames()
			add_pool(tree, e.global_position, POOL_BIG_R)
	if has("acqua") and not Run.inc_dart_hit:
		Run.inc_pool_hits += 1
		var now := Time.get_ticks_msec()
		if Run.inc_pool_hits >= POOL_EVERY and now - Run.inc_pool_msec > int(POOL_GAP * 1000.0):
			Run.inc_pool_hits = 0
			Run.inc_pool_msec = now
			add_pool(tree, e.global_position, POOL_R)
	if has("occhio") and not Run.inc_dart_hit:          # anche le frecce senza effetti (fx): contano tutte
		Run.inc_hits += 1
		var every := DART_EVERY_FALCO if alloy("falco") else DART_EVERY
		if Run.inc_hits >= every:
			Run.inc_hits = 0
			_fire_dart(tree)


## Una dose di veleno (fino a POISON_STACKS insieme; il Manager fa i tick).
static func poison(e: Node) -> void:
	if e == null or not is_instance_valid(e) or e.dead:
		return
	var now := Time.get_ticks_msec()
	var doses: Array = e.get_meta("inc_psn", []) if e.has_meta("inc_psn") else []
	var keep: Array = []
	for d in doses:
		if int(d) > now:
			keep.append(d)
	if keep.size() >= POISON_STACKS:
		keep.sort()
		keep.pop_front()
	keep.append(now + int(POISON_TIME * 1000.0))
	e.set_meta("inc_psn", keep)
	if not e.is_in_group("inc_poisoned"):
		e.add_to_group("inc_poisoned")


static func add_pool(tree: SceneTree, at: Vector2, r: float) -> void:
	var g = tree.current_scene
	if g == null or not ("world" in g) or g.world == null:
		return
	var pools := tree.get_nodes_in_group("inc_pools")
	if pools.size() >= POOL_MAX + (1 if r > POOL_R else 0):
		var oldest = pools[0]
		for pl in pools:
			if pl.age > oldest.age:
				oldest = pl
		oldest.queue_free()
	var pool := Pool.new()
	pool.r = r
	pool.position = at
	g.world.add_child(pool)
	Hazards.ground(pool)


static func _fire_dart(tree: SceneTree) -> void:
	var p = tree.get_first_node_in_group("player")
	if p == null or not is_instance_valid(p) or p.dead:
		return
	var best = null
	var bd := 1e9
	for e in tree.get_nodes_in_group("enemies"):
		if e.dead or ("alt" in e and e.alt > 0.5):
			continue
		var d: float = e.global_position.distance_to(p.global_position)
		if d < bd and d < DART_SPEED * DART_LIFE + 20.0:
			bd = d
			best = e
	if best == null:
		return
	var dart := Dart.new()
	dart.dir = (best.global_position - p.global_position).normalized()
	dart.position = p.global_position + Vector2(0, -8) + dart.dir * 10.0
	dart.dmg = base_damage() * DART_DMG
	dart.pierce = alloy("falco")
	p.get_parent().add_child(dart)
	Sfx.play("eye", 0.1, -6.0)


## La scia dello scarabeo: la crea player.gd all'inizio di ogni scatto.
static func start_trail(p: Node2D) -> void:
	if Run.trial or not has("scarabeo"):
		return
	var trail := Trail.new()
	trail.player = p
	p.get_parent().add_child(trail)
	Hazards.ground(trail)


## Un nemico è caduto (game._on_enemy_killed).
static func on_kill(_e: Node, tree: SceneTree) -> void:
	if Run.trial or Run.incisions.is_empty():
		return
	var p = tree.get_first_node_in_group("player")
	if p == null or not is_instance_valid(p):
		return
	if has("loto") and "art_cd" in p:
		p.art_cd = maxf(0.0, p.art_cd - LOTO_ART)
		if alloy("mattino") and Run.art_striking and Run.inc_mattino < MATTINO_MAX:
			var k := minf(MATTINO_K, MATTINO_MAX - Run.inc_mattino)
			Run.inc_mattino += k
			p.art_cd = maxf(0.0, p.art_cd - p.art_cd_max() * k)
	if alloy("volo"):
		var now := Time.get_ticks_msec()
		var keep: Array = []
		for t in Run.inc_volo:
			if int(t) > now:
				keep.append(t)
		if keep.size() >= VOLO_STACKS:
			keep.sort()
			keep.pop_front()
		keep.append(now + int(VOLO_TIME * 1000.0))
		Run.inc_volo = keep


## Velocità in più del Volo dell'anima (Run.move_mult).
static func speed_mult() -> float:
	if Run.inc_volo.is_empty():
		return 1.0
	var now := Time.get_ticks_msec()
	var n := 0
	for t in Run.inc_volo:
		if int(t) > now:
			n += 1
	return 1.0 + VOLO_SPEED * n


## Il simbolo inciso (anche nell'HUD, sulle carte e sulla porta del martello).
static func draw_glyph(ci: CanvasItem, id: String, c: Vector2, s: float, col: Color) -> void:
	var w := 1.4 * s
	match id:
		"leone":
			# testa di leone: muso tondo con la criniera a raggi
			for i in range(10):
				var a := TAU * i / 10.0
				ci.draw_line(c + Vector2.from_angle(a) * 3.2 * s, c + Vector2.from_angle(a) * 5.6 * s, col, w)
			ci.draw_circle(c, 3.4 * s, col)
			ci.draw_circle(c + Vector2(-1.2, -0.6) * s, 0.6 * s, Color(0.1, 0.06, 0.03))
			ci.draw_circle(c + Vector2(1.2, -0.6) * s, 0.6 * s, Color(0.1, 0.06, 0.03))
		"acqua":
			for k in range(3):
				var y := (k - 1) * 2.6 * s
				var pts := PackedVector2Array()
				for i in range(9):
					pts.append(c + Vector2((i - 4) * 1.4 * s, y + (1.0 if i % 2 == 0 else -1.0) * 0.9 * s))
				ci.draw_polyline(pts, col, w)
		"occhio":
			var up := PackedVector2Array()
			var dn := PackedVector2Array()
			for i in range(9):
				var x := (i - 4) * 1.2 * s
				up.append(c + Vector2(x, -sin(PI * i / 8.0) * 2.4 * s))
				dn.append(c + Vector2(x, sin(PI * i / 8.0) * 1.6 * s))
			ci.draw_polyline(up, col, w)
			ci.draw_polyline(dn, col, w)
			ci.draw_circle(c, 1.3 * s, col)
			ci.draw_line(c + Vector2(-0.6, 1.6) * s, c + Vector2(-1.4, 4.6) * s, col, w)
			ci.draw_line(c + Vector2(1.2, 1.4) * s, c + Vector2(3.4, 3.8) * s, col, w)
		"sole":
			ci.draw_circle(c, 3.2 * s, col)
			ci.draw_arc(c, 4.6 * s, 0.0, TAU, 20, col, w * 0.8)
		"scarabeo":
			ci.draw_circle(c + Vector2(0, -3.2) * s, 1.4 * s, col)
			var body := PackedVector2Array()
			for i in range(14):
				var a := TAU * i / 14.0
				body.append(c + Vector2(cos(a) * 2.6, sin(a) * 3.4 + 0.6) * s)
			ci.draw_colored_polygon(body, col)
			ci.draw_line(c + Vector2(0, -2.6) * s, c + Vector2(0, 4.0) * s, Color(0.1, 0.06, 0.03), 0.8 * s)
			for sx in [-1.0, 1.0]:
				ci.draw_line(c + Vector2(2.4 * sx, -0.6) * s, c + Vector2(4.6 * sx, -2.2) * s, col, w * 0.8)
				ci.draw_line(c + Vector2(2.4 * sx, 2.0) * s, c + Vector2(4.6 * sx, 3.6) * s, col, w * 0.8)
		"serpente":
			var sp := PackedVector2Array()
			for i in range(12):
				var y := (i - 6) * 0.9 * s
				sp.append(c + Vector2(sin(i * 0.9) * 2.4 * s, -y))
			ci.draw_polyline(sp, col, w)
			ci.draw_circle(sp[sp.size() - 1], 1.3 * s, col)
		"falco":
			# falco di profilo: corpo e ala, coda a ventaglio
			ci.draw_circle(c + Vector2(1.2, -3.0) * s, 1.4 * s, col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(2.6, -3.0) * s, c + Vector2(4.0, -2.4) * s, c + Vector2(2.4, -2.0) * s]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0.2, -2.0) * s, c + Vector2(2.2, -1.6) * s, c + Vector2(1.6, 3.2) * s, c + Vector2(-0.6, 4.8) * s, c + Vector2(-1.6, 2.0) * s]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.6, 4.4) * s, c + Vector2(1.8, 4.4) * s, c + Vector2(0.8, 6.0) * s]), col)
		"loto":
			for a in [-0.55, 0.0, 0.55]:
				var dir := Vector2.from_angle(-PI / 2.0 + a)
				var tip := c + Vector2(0, 2.4) * s + dir * 6.0 * s
				var side := dir.orthogonal() * 1.6 * s
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, 2.4) * s, tip - dir * 3.0 * s + side, tip, tip - dir * 3.0 * s - side]), col)
			ci.draw_line(c + Vector2(-3.4, 3.4) * s, c + Vector2(3.4, 3.4) * s, col, w)
		_:
			ci.draw_arc(c, 3.0 * s, 0.0, TAU, 16, Color(col, 0.5), w)


## Il colore di un'incisione (per le carte e l'HUD): tutte bronzo, la luce le distingue dal simbolo.
static func glyph_color(id: String) -> Color:
	match id:
		"acqua":
			return Color(0.5, 0.8, 1.0)
		"sole":
			return Color(1.0, 0.78, 0.3)
		"serpente":
			return Color(0.55, 0.85, 0.4)
		"loto":
			return Color(0.95, 0.65, 0.85)
		"occhio":
			return Color(0.5, 0.65, 1.0)
		"falco":
			return Color(0.85, 0.75, 0.55)
		"scarabeo":
			return Color(0.4, 0.8, 0.75)
	return Color(1.0, 0.6, 0.3)


# --- i nodi -------------------------------------------------------------------------------

## La pozza dell'Acqua: rallenta (Palude: avvelena; Fiore del Nilo: ti cura).
class Pool extends Node2D:
	var r := 22.0
	var age := 0.0
	var tick := 0.0

	func _ready() -> void:
		add_to_group("inc_pools")
		z_index = 0

	func _process(delta: float) -> void:
		age += delta
		if age >= Incisions.POOL_LIFE:
			queue_free()
			return
		tick -= delta
		var slow_now := tick <= 0.0
		if slow_now:
			tick = 0.25
			for e in get_tree().get_nodes_in_group("enemies"):
				if e.dead or e.global_position.distance_to(global_position) > r + e.radius * 0.5:
					continue
				e.slow_t = maxf(e.slow_t, 0.3)
				e.slow_pct = maxf(e.slow_pct, Incisions.POOL_SLOW)
				if Incisions.alloy("palude"):
					var last := int(e.get_meta("inc_palude_t", 0))
					if Time.get_ticks_msec() - last > 500:
						e.set_meta("inc_palude_t", Time.get_ticks_msec())
						Incisions.poison(e)
		queue_redraw()

	func contains(p: Vector2) -> bool:
		return p.distance_to(global_position) <= r

	func _draw() -> void:
		var k := clampf(minf(age / 0.25, (Incisions.POOL_LIFE - age) / 0.6), 0.0, 1.0)
		var col := Color(0.35, 0.75, 1.0) if not Incisions.alloy("palude") else Color(0.45, 0.85, 0.4)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.62))
		draw_circle(Vector2.ZERO, r, Color(col, 0.22 * k))
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, Color(col.lightened(0.3), 0.6 * k), 1.2)
		draw_arc(Vector2.ZERO, r * (0.45 + 0.4 * fmod(age * 0.7, 1.0)), 0.0, TAU, 22, Color(1, 1, 1, 0.25 * k), 0.8)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Il dardo dell'Occhio: dritto, non insegue; muri e colonne lo fermano.
class Dart extends Node2D:
	var dir := Vector2.RIGHT
	var dmg := 5.0
	var pierce := false
	var life := 0.0
	var hit: Array = []

	func _ready() -> void:
		z_index = 4
		add_to_group("inc_darts")

	func _physics_process(delta: float) -> void:
		life += delta
		if life > Incisions.DART_LIFE:
			queue_free()
			return
		var step := dir * Incisions.DART_SPEED * delta
		var space := get_world_2d().direct_space_state
		var q := PhysicsRayQueryParameters2D.create(global_position, global_position + step, 1)
		if not space.intersect_ray(q).is_empty():
			_end()
			return
		position += step
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.dead or hit.has(e) or ("alt" in e and e.alt > 0.5):
				continue
			if e.global_position.distance_to(global_position + Vector2(0, 8)) < e.radius + 5.0:
				hit.append(e)
				_strike(e)
				if not pierce or hit.size() >= Incisions.DART_PIERCE:
					_end()
					return
		queue_redraw()

	func _strike(e: Node) -> void:
		Run.inc_dart_hit = true
		e.take_hit(dmg * Run.player_hit(e, false), dir, 40.0)
		if not e.dead:
			if Incisions.alloy("cobra"):
				Incisions.poison(e)
				e.slow_t = maxf(e.slow_t, 1.5)
				e.slow_pct = maxf(e.slow_pct, 30.0)
			if Incisions.alloy("ra"):
				e.burn_t = maxf(e.burn_t, Incisions.SOLE_BURN)
		Run.inc_dart_hit = false
		if Incisions.alloy("ra"):
			Fx.burst(global_position, Color(1.0, 0.6, 0.2), 12, 90.0)
			for o in get_tree().get_nodes_in_group("enemies"):
				if o == e or o.dead or o.global_position.distance_to(global_position) > Incisions.DART_BLAST_R + o.radius:
					continue
				Run.inc_dart_hit = true
				o.take_hit(dmg * Incisions.DART_BLAST_K, (o.global_position - global_position).normalized(), 60.0, true)
				Run.inc_dart_hit = false

	func _end() -> void:
		Fx.burst(global_position, Color(0.6, 0.75, 1.0), 6, 50.0)
		queue_free()

	func _draw() -> void:
		var col := Color(1.0, 0.65, 0.25) if Incisions.alloy("ra") else (Color(0.55, 0.9, 0.4) if Incisions.alloy("cobra") else Color(0.6, 0.78, 1.0))
		draw_line(-dir * 12.0, Vector2.ZERO, Color(col, 0.35), 3.0)
		draw_line(-dir * 6.0, Vector2.ZERO, col, 2.0)
		draw_circle(Vector2.ZERO, 2.4, Color(1, 1, 0.95))


## La scia dello scarabeo: segue l'eroe finché scatta, poi resta TRAIL_LIFE secondi.
class Trail extends Node2D:
	var player: Node2D
	var pts: PackedVector2Array = PackedVector2Array()
	var age := 0.0
	var following := true
	var last_hit := {}

	func _ready() -> void:
		z_index = 0
		add_to_group("inc_trails")

	func _physics_process(delta: float) -> void:
		age += delta
		if following and player != null and is_instance_valid(player) and player.dash_t > 0.0:
			var at: Vector2 = player.global_position - global_position
			if pts.is_empty() or pts[pts.size() - 1].distance_to(at) > 5.0:
				pts.append(at)
		else:
			if following:
				following = false
				age = 0.0
		if not following and age > Incisions.TRAIL_LIFE:
			queue_free()
			return
		if pts.size() >= 2:
			var now := Time.get_ticks_msec()
			for e in get_tree().get_nodes_in_group("enemies"):
				if e.dead or ("alt" in e and e.alt > 0.5):
					continue
				var id := e.get_instance_id()
				if last_hit.has(id) and now - int(last_hit[id]) < int(Incisions.TRAIL_GAP * 1000.0):
					continue
				var lp: Vector2 = e.global_position - global_position
				var near := false
				for i in range(pts.size() - 1):
					var cp := Geometry2D.get_closest_point_to_segment(lp, pts[i], pts[i + 1])
					if cp.distance_to(lp) < Incisions.TRAIL_R + e.radius * 0.6:
						near = true
						break
				if not near:
					continue
				last_hit[id] = now
				Run.inc_dart_hit = true
				e.take_hit(Incisions.base_damage() * Incisions.TRAIL_DMG * Run.player_hit(e, false), Vector2.ZERO, 0.0, Incisions.alloy("khepri"))
				Run.inc_dart_hit = false
				if not e.dead:
					if Incisions.alloy("khepri"):
						e.burn_t = maxf(e.burn_t, Incisions.SOLE_BURN)
					if Incisions.alloy("sabbia"):
						Incisions.poison(e)
		queue_redraw()

	func _draw() -> void:
		if pts.size() < 2:
			return
		var k := 1.0 if following else clampf(1.0 - age / Incisions.TRAIL_LIFE, 0.0, 1.0)
		var col := Color(0.4, 0.85, 0.75)
		if Incisions.alloy("khepri"):
			col = Color(1.0, 0.62, 0.25)
		elif Incisions.alloy("sabbia"):
			col = Color(0.6, 0.85, 0.35)
		draw_polyline(pts, Color(col, 0.25 * k), Incisions.TRAIL_R * 1.6)
		draw_polyline(pts, Color(col.lightened(0.3), 0.7 * k), 2.0)


## Il veleno delle incisioni e la cura del Fiore del Nilo: un nodo solo per stanza (game.gd).
class Manager extends Node:
	var tick := 0.0
	var room_key := ""
	var fiore_done := 0.0
	var fiore_t := 0.0

	func _process(delta: float) -> void:
		if get_tree().paused:
			return
		var rk := "%d-%d" % [Run.region, Run.room]
		if rk != room_key:
			room_key = rk
			fiore_done = 0.0
		tick -= delta
		if tick <= 0.0:
			tick = 0.5
			var now := Time.get_ticks_msec()
			var per := maxf(1.0, Incisions.base_damage() * Incisions.POISON_K)
			for e in get_tree().get_nodes_in_group("inc_poisoned"):
				if not is_instance_valid(e) or e.dead:
					continue
				var doses: Array = e.get_meta("inc_psn", [])
				var n := 0
				for d in doses:
					if int(d) > now:
						n += 1
				if n == 0:
					e.remove_from_group("inc_poisoned")
					continue
				Run.inc_dart_hit = true
				e.take_hit(per * n, Vector2.ZERO, 0.0)
				Run.inc_dart_hit = false
				Fx.burst(e.global_position + Vector2(0, -10), Color(0.5, 0.9, 0.35), 3, 30.0)
		if Incisions.alloy("fiore") and fiore_done < Incisions.FIORE_MAX:
			var p = get_tree().get_first_node_in_group("player")
			if p != null and is_instance_valid(p) and not p.dead:
				var inside := false
				for pl in get_tree().get_nodes_in_group("inc_pools"):
					if pl.contains(p.global_position):
						inside = true
						break
				if inside:
					fiore_t += delta
					if fiore_t >= 1.0:
						fiore_t = 0.0
						fiore_done += Incisions.FIORE_HEAL
						p.heal(Incisions.FIORE_HEAL)
				else:
					fiore_t = 0.0
