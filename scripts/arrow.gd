extends Node2D
## Una freccia dell'Arco di Satet (player.gd, `_bow_shot` e `_charged_attack`).
## Le frecce normali si fermano sul primo nemico (Freccia Sapiente di Thoth: ne trapassano uno);
## il tiro carico trapassa tutta la fila. Muri e colonne le fermano sempre.
## Origine dei colpi: "freccia" (Boons.acts_on): le frecce ricevono solo i doni dell'arco e quelli
## generali, mai quelli dell'Occhio di Horus.
## Ricochet del Falco (Horus): quando la freccia si ferma su un nemico rimbalza sul più vicino non
## ancora colpito (entro un quarto dello schermo, visuale libera). Niente curve, niente previsione.

var player: Node2D = null
var dir := Vector2.RIGHT
var dmg := 7.0
var speed := 430.0
var max_dist := 240.0
var knock := 35.0
var pierce := 0                       ## nemici che può ancora trapassare (-1 = tutti)
var pierce_mult := 1.0                ## danni sui nemici colpiti dopo il primo (Freccia Sapiente)
var crit_chance := 0.0
var charged := false                  ## il tiro carico: più grande, trapassa, doni dedicati
var bounces := 0                      ## Ricochet del Falco: rimbalzi rimasti
var bounce_k := 0.6                   ## danni di un rimbalzo (frazione dei danni della freccia)
var bounced := false                  ## questa freccia ha già rimbalzato (i danni sono quelli del rimbalzo)
var big := 1.0
var travelled := 0.0
var hit := {}
var trail: Array = []


func _ready() -> void:
	z_index = 3


func _physics_process(delta: float) -> void:
	var from := global_position
	var step := dir * speed * delta
	# muri e colonne fermano la freccia (lo strato 1 è il mondo)
	var q := PhysicsRayQueryParameters2D.create(from, from + step, 1)
	var wall := get_world_2d().direct_space_state.intersect_ray(q)
	var to: Vector2 = wall["position"] if not wall.is_empty() else from + step
	global_position = to
	travelled += step.length()
	if _hit_along(from, to):
		return
	var g = get_tree().current_scene
	var out_of_room: bool = g != null and g.has_method("_in_floor") and not g._in_floor(global_position, 2.0)
	if not wall.is_empty() or travelled >= max_dist or out_of_room:
		if not wall.is_empty():
			Fx.burst(global_position, Color(0.85, 0.75, 0.55), 4, 40.0)
		queue_free()
		return
	trail.push_front(global_position)
	if trail.size() > (7 if charged else 3):
		trail.pop_back()
	queue_redraw()


## Ricochet del Falco: la freccia ferma su un nemico riparte verso il più vicino non ancora colpito.
## True se ha rimbalzato (la freccia continua), false se deve fermarsi.
func _ricochet() -> bool:
	if bounces <= 0:
		return false
	var reach := 160.0
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		reach = get_viewport().get_visible_rect().size.x / cam.zoom.x * 0.25
	var best = null
	var best_d := reach
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead or hit.has(e):
			continue
		var d := global_position.distance_to(e.global_position + Vector2(0, -6))
		if d >= best_d:
			continue
		var q := PhysicsRayQueryParameters2D.create(global_position, e.global_position + Vector2(0, -6), 1)
		if not get_world_2d().direct_space_state.intersect_ray(q).is_empty():
			continue
		best_d = d
		best = e
	if best == null:
		return false
	bounces -= 1
	bounced = true
	dir = (best.global_position + Vector2(0, -6) - global_position).normalized()
	travelled = 0.0
	max_dist = best_d + 24.0
	trail.clear()
	Fx.burst(global_position, Color(1.0, 0.82, 0.3), 8, 60.0)      # lampo dorato sul rimbalzo
	return true


## Colpisce chi sta sul tratto percorso in questo fotogramma. True se la freccia si è fermata.
func _hit_along(a: Vector2, b: Vector2) -> bool:
	for j in get_tree().get_nodes_in_group("breakables"):
		if not j.broken and Geometry2D.get_closest_point_to_segment(j.global_position, a, b).distance_to(j.global_position) < 10.0:
			j.smash()
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead or hit.has(e):
			continue
		var c: Vector2 = e.global_position + Vector2(0, -6)
		if Geometry2D.get_closest_point_to_segment(c, a, b).distance_to(c) > e.radius + 4.0 * big:
			continue
		Run.last_arrow_dmg = dmg
		Run.heavy_strike = charged
		var parried: bool = e.has_method("blocks") and e.blocks(dir)
		Run.heavy_strike = false
		if parried:
			# lo scudo del guardiano di Sokar: la freccia si spezza, niente danni
			Sfx.play_at("hit", e.global_position, 0.3)
			Fx.burst(e.global_position + Vector2(0, -12) - dir * 8.0, Color(1.0, 0.85, 0.45), 6, 60.0)
			Fx.float_text(e.global_position + Vector2(0, -30), Lang.t("PARATO"), Color(0.95, 0.85, 0.55))
			queue_free()
			return true
		_strike(e)
		if pierce == 0:
			if _ricochet():
				return true                     # riparte da qui il prossimo fotogramma
			queue_free()
			return true
		if pierce > 0:
			pierce -= 1
	return false


## Gli effetti dei doni (fiamme, rallentamento, Lutto, spinta, ruggito dei critici, cure di Nefti)
## scattano al massimo una volta ogni FX_GAP secondi per nemico, non a ogni freccia: vale per tutte
## le frecce insieme, anche quelle della Faretra dello Sciacallo.
const FX_GAP := 500
const O := "freccia"
const FAR_DIST := 120.0               ## blocco 13: oltre questa distanza dal giocatore la freccia fa +20%
const FAR_BONUS := 1.2                  ## l'origine di questi colpi (Boons.acts_on)


static func _fx_ready(e) -> bool:
	var now := Time.get_ticks_msec()
	if now - int(e.get_meta("arrow_fx", -100000)) < FX_GAP:
		return false
	e.set_meta("arrow_fx", now)
	return true


func _strike(e) -> void:
	var first := hit.is_empty()
	hit[e] = true
	var fx := _fx_ready(e)
	var crit := Run.roll_crit(crit_chance)
	var d := dmg * crit * (bounce_k if bounced else (1.0 if first else pierce_mult))
	if player != null and is_instance_valid(player) and player.global_position.distance_to(e.global_position) > FAR_DIST:
		d *= FAR_BONUS                     # colpo da lontano: l'arco premia chi tiene la distanza
	if Run.hit_has("duo_ra_sekhmet", O) and e.burn_t > 0.0:
		d *= 1.25
	if Run.hit_has("duo_sobek_iside", O) and player != null and is_instance_valid(player) and player.shield > 0.0:
		d *= 1.25
	if e.mark_t > 0.0 and Run.hit_has("horus_mark", O):
		d *= 1.0 + Run.val("horus_mark") / 100.0
	if crit > 1.0:
		Fx.float_text(e.global_position + Vector2(0, -20), Lang.t("CRITICO"), Boons.god_color("bastet"))
		Sfx.play("crit")
		if Run.hit_has("duo_sekhmet_bastet", O) and fx:
			# Caccia delle Leonesse: il ruggito parte da dove colpisce la freccia
			Fx.burst(e.global_position + Vector2(0, -6), Boons.god_color("duo"), 20, 110.0)
			for o in get_tree().get_nodes_in_group("enemies"):
				if o != e and not o.dead and o.global_position.distance_to(e.global_position) < 40.0 + o.radius:
					o.take_hit(12.0 * Run.all_damage_mult(), (o.global_position - e.global_position).normalized(), 150.0)
	if fx and (Run.has("nefti_veil") or (charged and Run.has("arco_nefti"))):
		e.mourn_t = 4.0                    # Velo del Lutto, o la Freccia del Lutto del tiro carico
	if fx:
		Run.nefti_on_hit()
	d *= Run.player_hit(e, fx)
	Run.arrow_hit = true
	e.take_hit(d, dir, knock * Run.knock_mult(), (Run.hit_has("arco_ra", O) or Run.has("ra_heavy")) and fx)
	Run.arrow_hit = false
	Run.after_player_hit(e, dir, fx)
	if not e.dead and fx:
		if Run.hit_has("arco_sobek", O):
			e.slow_t = 2.0           # Frecce della Palude
		if charged and Run.hit_has("arco_shu", O):
			e.shu_push(dir, 300.0)         # Freccia del Vento: spinge, e lo schianto fa il resto
		if Run.hit_has("duo_anubi_sekhmet", O) and not e.is_boss and not e.miniboss and e.hp < e.max_hp * 0.15:
			Fx.float_text(e.global_position + Vector2(0, -24), Lang.t("GIUDIZIO"), Boons.god_color("duo"))
			e.die()
	Fx.impact(e.global_position + Vector2(0, -e.radius), dir, charged or crit > 1.0)
	if charged:
		Fx.hitstop(0.05)


func _draw() -> void:
	# la scia (dorata e più lunga per il tiro carico), poi la freccia
	var col := Color(1.0, 0.86, 0.45) if charged else Color(0.95, 0.92, 0.8)
	for i in range(1, trail.size()):
		var p0: Vector2 = trail[i - 1] - global_position
		var p1: Vector2 = trail[i] - global_position
		draw_line(p0, p1, Color(col, (0.6 if charged else 0.35) * (1.0 - float(i) / trail.size())), 3.0 * big)
	if charged:
		draw_circle(Vector2.ZERO, 6.0 * big, Color(1.0, 0.85, 0.4, 0.25))
	ArrowArt.draw_arrow(self, Vector2.ZERO, dir, big, 1.0)
