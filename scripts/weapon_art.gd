class_name WeaponArt
extends Node2D
## L'ARTE DELL'ARMA (blocco 23): il terzo attacco, sul tasto che prima non faceva nulla (B del pad,
## C / U / rotella premuta sulla tastiera, il pulsante ARTE sul telefono). Ogni arma ha la sua: un
## colpo ad area che sgombra lo spazio quando ti chiudono, con una ricarica lunga (ART_CD). Non è
## un'altra combo: è la risposta a «sono circondato», e per questo colpisce TUTTO quello che prende.
##
## Le evoluzioni dell'arma (Weapons.evo, comprate all'altare del Cortile) la cambiano:
##   I   l'Arte fa il 25% in più e si ricarica 1,5 s prima;
##   II  l'Arte prende la sua forma piena (vedi TWIST qui sotto);
##   III l'arma stessa si risveglia: +8% a tutti i suoi colpi, Arte ancora 1,5 s più rapida, la lama
##       brilla d'oro.
##
## Regole di leggibilità (le stesse dei nemici): le Arti a distanza (lancia, arco) segnano prima il
## punto d'impatto con un cerchio d'oro; quelle attorno a te partono subito ma non feriscono te.

const ART_CD := 9.0
const EVO_DMG := 0.25              ## evoluzione I
const EVO_CD := 1.5                ## evoluzione I e III
const EVO3_WEAPON := 0.08          ## evoluzione III: tutti i colpi dell'arma
const GOLD := Color(1.0, 0.86, 0.45)

## Nomi e testi in italiano (Lang.t alla lettura). "desc": cosa fa; "twist": la forma piena (evo II).
const DATA_IT := {
	"khopesh": {"name": "Mezzaluna del Faraone", "color": Color(1.0, 0.86, 0.45),
		"desc": "Due giri di lama: un'onda a mezzaluna si allarga attorno a te e scaglia lontano tutto ciò che tocca.",
		"twist": "L'onda torna indietro e colpisce una seconda volta, tirando i nemici verso di te."},
	"lancia": {"name": "Pioggia di Neith", "color": Color(0.95, 0.45, 0.38),
		"desc": "Le lance della dea cadono dove miri: un cerchio d'oro segna il punto, poi tutto ciò che c'è dentro resta inchiodato e rallentato.",
		"twist": "Le lance restano piantate per 2,5 s e feriscono chi resta nel cerchio."},
	"arco": {"name": "Cielo di Satet", "color": Color(0.55, 0.85, 1.0),
		"desc": "Tre raffiche di frecce cadono dal cielo sul punto che miri. Prendono anche chi vola.",
		"twist": "Una quarta raffica, e chi è colpito resta rallentato."},
	"flagello": {"name": "Mietitura di Osiride", "color": Color(0.45, 0.75, 0.95),
		"desc": "Una frustata a giro tutto attorno a te che strappa i nemici normali e li trascina ai tuoi piedi.",
		"twist": "Chi viene trascinato resta stordito per un attimo: pronto per la combo."},
	"artigli": {"name": "Furia delle Nove Vite", "color": Color(0.85, 0.62, 1.0),
		"desc": "Per quasi un secondo diventi un turbine di graffi: sei colpi rapidi attorno a te e niente ti tocca.",
		"twist": "Ogni graffio che va a segno ti restituisce un po' di vita."},
	"scettro": {"name": "Parola di Ptah", "color": Color(0.45, 0.9, 0.85),
		"desc": "Pianti lo scettro e pronunci il nome: un'onda di pietra si allarga e stordisce i nemici normali.",
		"twist": "Dove hai parlato resta il Cerchio del Dominio."},
}

## I valori di ogni Arte (moltiplicatori del danno base dell'arma).
const KHOPESH := {"r0": 18.0, "r": 104.0, "grow": 0.32, "mult": 3.0, "back_mult": 1.2, "knock": 260.0, "back_time": 0.3}
const SPEAR := {"reach": 115.0, "r": 64.0, "warn": 0.42, "mult": 3.0, "slow": 50.0, "slow_t": 1.6, "field": 2.5, "field_mult": 0.35, "field_tick": 0.5}
const BOW := {"reach": 170.0, "r": 58.0, "first": 0.3, "gap": 0.3, "waves": 3, "mult": 1.15, "slow": 30.0, "slow_t": 2.0}
const FLAIL := {"r": 100.0, "mult": 2.6, "pull": 3.6, "stun": 0.6, "spin": 0.28}
const CLAWS := {"r": 52.0, "time": 0.9, "hits": 6, "mult": 0.75, "heal": 0.6}
const SCEPTRE := {"r": 124.0, "grow": 0.36, "mult": 2.8, "stun": 0.9}

var kind := "khopesh"
var player: Node2D = null
var base := 12.0                  ## danno base dell'arma (con i doni e l'aspetto)
var evo := 0
var dir := Vector2.RIGHT
var at := Vector2.ZERO            ## il punto d'impatto (lancia, arco) in coordinate del mondo
var t := 0.0
var hit_once := {}                ## istanza → già colpito (le onde colpiscono una volta)
var hit_back := {}
var wave := 0
var tick := 0.0
var claw_hits := 0
var claw_heal := 0.0
var done_impact := false


static func data(k: String) -> Dictionary:
	return DATA_IT.get(k, DATA_IT["khopesh"])


static func art_name(k: String) -> String:
	return Lang.t(String(data(k)["name"]))


static func art_desc(k: String) -> String:
	return Lang.t(String(data(k)["desc"]))


static func art_twist(k: String) -> String:
	return Lang.t(String(data(k)["twist"]))


static func color_of(k: String) -> Color:
	return data(k)["color"]


## La ricarica dell'Arte per l'arma impugnata, con le evoluzioni.
static func cooldown(k: String) -> float:
	var e := 0 if Run.trial else Weapons.evo(k)
	var cd := ART_CD
	if e >= 1:
		cd -= EVO_CD
	if e >= 3:
		cd -= EVO_CD
	return cd


static func damage_mult(k: String) -> float:
	return 1.0 + (EVO_DMG if not Run.trial and Weapons.evo(k) >= 1 else 0.0)


func _ready() -> void:
	z_index = 2
	evo = 0 if Run.trial else Weapons.evo(kind)       # nella prova della Sfinge le armi sono uguali per tutti
	match kind:
		"khopesh":
			Sfx.play("swing", 0.0)
			Sfx.play_at("crit", global_position, 0.1)
			Fx.shake(5.0)
		"lancia", "arco":
			Sfx.play("swing", 0.05)
		"flagello":
			Sfx.play("swing", 0.0)
			Sfx.play("dash", 0.05)
		"artigli":
			Sfx.play("dash", 0.05)
		"scettro":
			Sfx.play("divine", 0.05)
			Fx.shake(6.0)


## Colpisce un nemico con le regole di tutte le armi: critico, doni del colpo, fuoco, scudi.
func _hit(e, mult: float, from: Vector2, kb: float, crit_bonus: float = 0.0) -> bool:
	if e == null or not is_instance_valid(e) or e.dead:
		return false
	var to: Vector2 = e.global_position - from
	var d := to.normalized() if to.length() > 0.5 else dir
	var crit := Run.roll_crit(Run.khopesh_crit_chance() + crit_bonus)
	if crit > 1.0:
		Fx.float_text(e.global_position + Vector2(0, -22), Lang.t("CRITICO"), GOLD)
	Run.heavy_strike = true                 # l'Arte apre gli scudi come un attacco caricato
	Run.nefti_on_hit()
	e.take_hit(base * mult * damage_mult(kind) * crit * Run.player_hit(e), d, kb * Run.knock_mult(), Run.khopesh_burns())
	Run.after_player_hit(e, d)
	Run.heavy_strike = false
	Fx.impact(e.global_position + Vector2(0, -e.radius), d, crit > 1.0)
	return true


func _enemies_in(c: Vector2, r: float) -> Array:
	var out: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.dead and c.distance_to(e.global_position) < r + e.radius:
			out.append(e)
	return out


func _smash_jars(c: Vector2, r: float) -> void:
	for j in get_tree().get_nodes_in_group("breakables"):
		if not j.broken and c.distance_to(j.global_position) < r + 8.0:
			j.smash()


func _big(e) -> bool:
	return e.is_boss or e.miniboss or e.elite or e.stun_immune


func _process(delta: float) -> void:
	t += delta
	if player != null and is_instance_valid(player) and kind in ["khopesh", "flagello", "artigli", "scettro"]:
		global_position = player.global_position        # le Arti attorno a te ti seguono
	match kind:
		"khopesh":
			_khopesh()
		"lancia":
			_spear(delta)
		"arco":
			_bow()
		"flagello":
			_flail()
		"artigli":
			_claws(delta)
		"scettro":
			_sceptre()
	queue_redraw()


func _khopesh() -> void:
	var k := clampf(t / KHOPESH["grow"], 0.0, 1.0)
	var r := lerpf(KHOPESH["r0"], KHOPESH["r"], k)
	for e in _enemies_in(global_position, r):
		if not hit_once.has(e):
			hit_once[e] = true
			_hit(e, KHOPESH["mult"], global_position, KHOPESH["knock"])
	_smash_jars(global_position, r)
	if evo >= 2 and t > KHOPESH["grow"]:
		# forma piena: l'onda torna indietro
		var kb := clampf((t - KHOPESH["grow"]) / KHOPESH["back_time"], 0.0, 1.0)
		var rb := lerpf(KHOPESH["r"], KHOPESH["r0"], kb)
		for e in _enemies_in(global_position, KHOPESH["r"]):
			var dd: float = global_position.distance_to(e.global_position)
			if not hit_back.has(e) and dd > rb - e.radius:
				hit_back[e] = true
				_hit(e, KHOPESH["back_mult"], global_position, -120.0)
		if kb >= 1.0:
			queue_free()
	elif t > KHOPESH["grow"] + 0.2:
		queue_free()


func _spear(delta: float) -> void:
	if not done_impact and t >= SPEAR["warn"]:
		done_impact = true
		Sfx.play_at("amheh_land", at, 0.2)
		Sfx.play_at("hit", at, 0.2)
		Fx.shake(5.0)
		Fx.burst(at, GOLD, 22, 140.0)
		_smash_jars(at, SPEAR["r"])
		var any := false
		for e in _enemies_in(at, SPEAR["r"]):
			if _hit(e, SPEAR["mult"], at, 60.0):
				any = true
				e.slow_t = maxf(e.slow_t, SPEAR["slow_t"])
				e.slow_pct = maxf(e.slow_pct, SPEAR["slow"])
		if any:
			Fx.hitstop(0.06)
	if done_impact:
		var field: float = SPEAR["field"] if evo >= 2 else 0.25
		if evo >= 2:
			tick -= delta
			if tick <= 0.0:
				tick = SPEAR["field_tick"]
				for e in _enemies_in(at, SPEAR["r"]):
					_hit(e, SPEAR["field_mult"], at, 0.0)
		if t > SPEAR["warn"] + field:
			queue_free()


func _bow() -> void:
	var waves: int = BOW["waves"] + (1 if evo >= 2 else 0)
	while wave < waves and t >= BOW["first"] + BOW["gap"] * wave:
		wave += 1
		Sfx.play_at("swing", at, 0.3)
		Fx.burst(at, Color(0.85, 0.95, 1.0), 10, 90.0)
		for e in _enemies_in(at, BOW["r"]):
			Run.arrow_hit = true                  # frecce dal cielo: prendono anche gli avvoltoi in volo
			var landed := _hit(e, BOW["mult"], at + Vector2(0, -40), 20.0)
			Run.arrow_hit = false
			if landed and evo >= 2 and is_instance_valid(e):
				e.slow_t = maxf(e.slow_t, BOW["slow_t"])
				e.slow_pct = maxf(e.slow_pct, BOW["slow"])
	if wave >= waves and t > BOW["first"] + BOW["gap"] * (waves - 1) + 0.25:
		queue_free()


func _flail() -> void:
	if not done_impact and t >= FLAIL["spin"] * 0.5:
		done_impact = true
		Fx.shake(4.0)
		_smash_jars(global_position, FLAIL["r"])
		var any := false
		for e in _enemies_in(global_position, FLAIL["r"]):
			var to: Vector2 = e.global_position - global_position
			if _hit(e, FLAIL["mult"], global_position, 0.0):
				any = true
				if not _big(e) and not e.dead:
					# strappati ai tuoi piedi: la spinta li porta fino a ~30 px da te
					var dist := maxf(0.0, to.length() - 30.0)
					e.knock = -to.normalized() * dist * FLAIL["pull"]
					if evo >= 2:
						e.gift_stun(FLAIL["stun"])
		if any:
			Fx.hitstop(0.07)
	if t > FLAIL["spin"] + 0.12:
		queue_free()


func _claws(delta: float) -> void:
	if player != null and is_instance_valid(player):
		player.invuln_t = maxf(player.invuln_t, 0.08)
	tick -= delta
	if tick <= 0.0 and claw_hits < CLAWS["hits"]:
		tick = CLAWS["time"] / CLAWS["hits"]
		claw_hits += 1
		Sfx.play_at("swing", global_position, 0.3)
		var landed := 0
		for e in _enemies_in(global_position, CLAWS["r"]):
			if _hit(e, CLAWS["mult"], global_position, 40.0, 0.05):
				landed += 1
		if landed > 0 and evo >= 2 and player != null and claw_heal < 4.0:
			player.heal(CLAWS["heal"])
			claw_heal += CLAWS["heal"]
	if t > CLAWS["time"] + 0.05:
		queue_free()


func _sceptre() -> void:
	var k := clampf(t / SCEPTRE["grow"], 0.0, 1.0)
	var r := lerpf(10.0, SCEPTRE["r"], k)
	for e in _enemies_in(global_position, r):
		if not hit_once.has(e):
			hit_once[e] = true
			if _hit(e, SCEPTRE["mult"], global_position, 140.0) and not e.dead:
				e.gift_stun(SCEPTRE["stun"])
	_smash_jars(global_position, r)
	if t > SCEPTRE["grow"] + 0.18:
		if evo >= 2 and player != null and is_instance_valid(player):
			var wc := WasCircle.new()
			wc.dmg = base * 0.42
			wc.player = player
			get_parent().add_child(wc)
			wc.global_position = global_position
		queue_free()


# ---------------------------------------------------------------- disegno

func _draw() -> void:
	var col := color_of(kind)
	match kind:
		"khopesh":
			var k := clampf(t / KHOPESH["grow"], 0.0, 1.0)
			var r := lerpf(KHOPESH["r0"], KHOPESH["r"], k)
			if evo >= 2 and t > KHOPESH["grow"]:
				r = lerpf(KHOPESH["r"], KHOPESH["r0"], clampf((t - KHOPESH["grow"]) / KHOPESH["back_time"], 0.0, 1.0))
			var a := clampf(1.2 - t / (KHOPESH["grow"] + 0.35), 0.0, 1.0)
			_ring(Vector2(0, -6), r, Color(col, 0.18 * a), Color(col, 0.9 * a), 5.0)
			# le due lame che girano dentro l'onda
			for i in range(2):
				var ang := t * 22.0 + PI * i
				draw_arc(Vector2(0, -6), r * 0.72, ang, ang + 1.6, 10, Color(1, 1, 1, 0.75 * a), 2.4)
		"lancia":
			var lp := to_local(at)
			if not done_impact:
				var k2 := clampf(t / SPEAR["warn"], 0.0, 1.0)
				_target(lp, SPEAR["r"], k2, col)
				# le lance che cadono: ombre che si stringono e aste che scendono
				for i in range(7):
					var sp := lp + (Vector2.ZERO if i == 0 else Vector2.from_angle(TAU * i / 6.0) * SPEAR["r"] * 0.62)
					var h := (1.0 - k2) * 90.0
					draw_circle(sp, 2.0 + 3.0 * k2, Color(0, 0, 0, 0.35))
					draw_line(sp + Vector2(0, -h - 22.0), sp + Vector2(0, -h), Color(0.9, 0.85, 0.75, 0.9), 2.0)
					draw_colored_polygon(PackedVector2Array([sp + Vector2(0, -h + 4), sp + Vector2(-2.5, -h - 3), sp + Vector2(2.5, -h - 3)]), GOLD)
			else:
				var fade := 1.0
				if evo < 2:
					fade = clampf(1.0 - (t - SPEAR["warn"]) / 0.25, 0.0, 1.0)
				else:
					fade = clampf((SPEAR["warn"] + SPEAR["field"] - t) / 0.4, 0.0, 1.0)
					_ring(lp, SPEAR["r"], Color(col, 0.08 * fade), Color(col, 0.45 * fade), 1.4)
				for i in range(7):
					var sp2 := lp + (Vector2.ZERO if i == 0 else Vector2.from_angle(TAU * i / 6.0) * SPEAR["r"] * 0.62)
					draw_line(sp2 + Vector2(-2, -20), sp2, Color(0.9, 0.85, 0.75, fade), 2.0)
					draw_circle(sp2, 3.0, Color(0, 0, 0, 0.3 * fade))
		"arco":
			var lp3 := to_local(at)
			var waves: int = BOW["waves"] + (1 if evo >= 2 else 0)
			var end_t: float = BOW["first"] + BOW["gap"] * (waves - 1)
			var fade3 := clampf((end_t + 0.25 - t) / 0.25, 0.0, 1.0)
			_target(lp3, BOW["r"], clampf(t / BOW["first"], 0.0, 1.0), col, fade3)
			var rng := RandomNumberGenerator.new()
			rng.seed = 77 + int(t * 20.0)
			for i in range(9):
				var q := lp3 + Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.7, 0.7)) * BOW["r"]
				var fall := fmod(t * 6.0 + i * 0.13, 1.0)
				var top := q + Vector2(-8, -60) * (1.0 - fall)
				draw_line(top + Vector2(-4, -12), top, Color(0.92, 0.95, 1.0, 0.85 * fade3), 1.5)
		"flagello":
			var k4 := clampf(t / FLAIL["spin"], 0.0, 1.0)
			var a4 := clampf(1.4 - k4, 0.0, 1.0)
			var spin := k4 * TAU * 1.15
			# le tre code del flagello che girano: una spirale di perline
			for tail in range(3):
				var off := tail * 0.18
				var pts := PackedVector2Array()
				for s in range(14):
					var u := s / 13.0
					pts.append(Vector2(0, -8) + Vector2.from_angle(spin - off - u * 0.9) * FLAIL["r"] * (0.25 + 0.75 * u))
				draw_polyline(pts, Color(col, 0.85 * a4), 2.0)
				draw_circle(pts[pts.size() - 1], 3.0, Color(GOLD, a4))
			_ring(Vector2(0, -6), FLAIL["r"], Color(col, 0.06 * a4), Color(col, 0.35 * a4), 1.2)
		"artigli":
			var a5 := clampf((CLAWS["time"] + 0.05 - t) / 0.2, 0.0, 1.0)
			_ring(Vector2(0, -8), CLAWS["r"], Color(col, 0.1 * a5), Color(col, 0.5 * a5), 1.5)
			for i in range(5):
				var ang5 := t * 26.0 + i * TAU / 5.0
				var p0 := Vector2(0, -8) + Vector2.from_angle(ang5) * CLAWS["r"] * 0.35
				var p1 := Vector2(0, -8) + Vector2.from_angle(ang5 + 0.7) * CLAWS["r"] * 0.95
				draw_line(p0, p1, Color(1, 0.95, 1.0, 0.8 * a5), 2.0)
				draw_line(p0 + Vector2(3, 3), p1 + Vector2(3, 3), Color(col, 0.6 * a5), 1.4)
		"scettro":
			var k6 := clampf(t / SCEPTRE["grow"], 0.0, 1.0)
			var r6 := lerpf(10.0, SCEPTRE["r"], k6)
			var a6 := clampf(1.25 - k6, 0.0, 1.0)
			_ring(Vector2.ZERO, r6, Color(col, 0.16 * a6), Color(col, 0.95 * a6), 4.0)
			# schegge di pietra sollevate dall'onda
			for i in range(12):
				var ang6 := TAU * i / 12.0
				var sp6 := Vector2.from_angle(ang6) * r6
				draw_rect(Rect2(sp6 + Vector2(-2, -5), Vector2(4, 5)), Color(0.55, 0.5, 0.45, a6))


func _ring(c: Vector2, r: float, fill: Color, edge: Color, w: float) -> void:
	draw_circle(c, r, fill)
	draw_arc(c, r, 0.0, TAU, 48, edge, w)


## Il cerchio d'oro del punto d'impatto (lancia, arco): si riempie fino al colpo.
func _target(c: Vector2, r: float, k: float, col: Color, fade: float = 1.0) -> void:
	draw_circle(c, r, Color(col, 0.08 * fade))
	draw_circle(c, r * k, Color(col, 0.14 * fade))
	draw_arc(c, r, 0.0, TAU, 40, Color(GOLD, 0.85 * fade), 1.6)
	for i in range(4):
		var a := TAU * i / 4.0 + t * 2.0
		draw_line(c + Vector2.from_angle(a) * (r - 7.0), c + Vector2.from_angle(a) * (r + 3.0), Color(GOLD, 0.9 * fade), 1.6)


## L'icona dell'Arte (HUD, pulsante del telefono, altare): un segno per arma.
static func draw_icon(ci: CanvasItem, k: String, c: Vector2, s: float, col: Color) -> void:
	match k:
		"khopesh":
			ci.draw_arc(c + Vector2(1, 0) * s, 6.0 * s, PI * 0.6, PI * 1.9, 12, col, 2.0 * s)
			ci.draw_arc(c + Vector2(1, 0) * s, 3.0 * s, PI * 0.6, PI * 1.9, 8, Color(col, 0.6), 1.2 * s)
		"lancia":
			for i in range(3):
				var x := (i - 1) * 4.0 * s
				ci.draw_line(c + Vector2(x, -6.0 * s), c + Vector2(x, 4.0 * s), col, 1.4 * s)
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(x, 7.0 * s), c + Vector2(x - 2.0 * s, 3.0 * s), c + Vector2(x + 2.0 * s, 3.0 * s)]), col)
		"arco":
			ci.draw_arc(c + Vector2(0, 3) * s, 6.0 * s, PI, TAU, 10, col, 1.4 * s)
			for i in range(3):
				var x2 := (i - 1) * 3.5 * s
				ci.draw_line(c + Vector2(x2 - 2.0 * s, -6.0 * s), c + Vector2(x2 + 1.0 * s, 2.0 * s), col, 1.2 * s)
		"flagello":
			for i in range(3):
				var a := i * TAU / 3.0
				ci.draw_arc(c + Vector2.from_angle(a) * 2.0 * s, 5.0 * s, a, a + 2.2, 8, col, 1.4 * s)
			ci.draw_circle(c, 1.6 * s, col)
		"artigli":
			for i in range(3):
				var x3 := (i - 1) * 3.6 * s
				ci.draw_line(c + Vector2(x3 - 2.0 * s, -6.0 * s), c + Vector2(x3 + 2.0 * s, 6.0 * s), col, 1.6 * s)
		_:
			ci.draw_line(c + Vector2(0, -7) * s, c + Vector2(0, 3) * s, col, 1.6 * s)
			ci.draw_arc(c + Vector2(0, 5) * s, 6.0 * s, PI * 1.05, PI * 1.95, 10, col, 1.4 * s)
			ci.draw_arc(c + Vector2(0, 5) * s, 3.2 * s, PI * 1.05, PI * 1.95, 8, Color(col, 0.6), 1.0 * s)
