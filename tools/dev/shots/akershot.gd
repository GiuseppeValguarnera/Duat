extends Node
## Aker alla porta dell'orizzonte: arena, presentazione, soffio, raggio dell'alba, pietre (e il riparo
## che ferma il raggio), fianchi contro teste, giro, tremito e divisione, Ieri e Domani a turno,
## eredità della mossa, l'ira di Aker (rinascita), vittoria con il sole che tremola.
## Uso: DUAT_REGION2=1 tools/dev/shot.sh akershot 1280 720 res://scenes/game.tscn [mobile]
var t := 0.0
var step := 0
var flag := 0
var once := {}
var measure := false
var hp0 := 0.0
var both_busy := 0
var frames := 0
var D := OS.get_environment("DUAT_SHOTS") + "/"
func L(x: String) -> void:
	print("LOG ", x)
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
func shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png(D + "aker_" + n + ".png")
func first(k: String) -> bool:
	if once.has(k):
		return false
	once[k] = true
	return true
func _boss(g):
	return g.boss if g.boss != null and is_instance_valid(g.boss) else null
func _lion(g, kind: String):
	for b in g.boss_group:
		if is_instance_valid(b) and not b.dead and b.get("kind") == kind:
			return b
	return null
func next(n: int) -> void:
	step = n; t = 0.0; flag = 0
func _process(dt: float) -> void:
	t += dt
	var g = get_tree().current_scene
	if g == null or g.name != "Game" or g.player == null or not is_instance_valid(g.player):
		return
	var p = g.player
	if not measure:
		p.invuln_t = 0.0
		p.hp = p.max_hp
		Run.hp = p.max_hp
	if g.menu != null and is_instance_valid(g.menu) and t > 0.6:
		g._close_choice()
	match step:
		0:
			if t > 1.0:
				Meta.ammit_wins = maxi(Meta.ammit_wins, 1)
				Meta.weights = {"ira_aker": 1}
				Run.region = 2; Run.room = 10
				g.start_room({"kind": "none"}); next(1)
		1:
			if t > 1.0 and first("ingresso"):
				shot("00_ingresso")
				p.get_node("Camera").zoom = Vector2(0.6, 0.6)
			if t > 1.3 and first("intero"):
				shot("01_orizzonte_intero")
				p.get_node("Camera").zoom = Vector2.ONE
			if t > 2.6 and first("intro"):
				shot("02_presentazione")
			if not get_tree().paused and t > 5.0 and _boss(g) != null:
				var b = _boss(g)
				L("aker hp=%d boss_full=%d floor=%s rocce solide=%d" % [b.max_hp, g.boss_full, str(b.floor_rect), Arenas.horizon_rocks(g.ROOM, g.TOP, g.WALL).size()])
				b.global_position = Vector2(400, 260)
				b.roar_cd = 99.0
				next(2)
		2:
			# il soffio di sabbia (testa di ovest)
			var b = _boss(g)
			if first("soffio"):
				p.global_position = b.global_position + Vector2(-110, 0)
				b.side = -1.0
				b.state = "breath_windup"; b.st = b.breath_windup
				b._aim_breath(p.global_position - b.global_position)
				measure = true; hp0 = p.hp; p.invuln_t = 0.0
			if t > 0.45 and first("s1"):
				shot("03_soffio_avviso")
			if t > 0.9 and first("s2"):
				shot("04_soffio")
			if t > 1.6:
				L("soffio: danno %.0f, spinto a x=%.0f (era %.0f), sabbie mobili=%d" % [hp0 - p.hp, p.global_position.x, b.global_position.x - 110.0, get_tree().get_nodes_in_group("quicksand").size()])
				measure = false
				next(3)
		3:
			# il raggio dell'alba (testa di est)
			var b = _boss(g)
			if first("raggio"):
				b.state = "recover"; b.st = 0.1
				b.global_position = Vector2(400, 260)
				p.global_position = b.global_position + Vector2(150, 10)
				b.side = 1.0
				b._fire_ray(p.global_position - b.global_position, 100.0, 9.0)
				measure = true; hp0 = p.hp; p.invuln_t = 0.0
			if t > 0.4 and first("r1"):
				shot("05_raggio_avviso")
			if t > 1.4 and first("r2"):
				shot("06_raggio")
			if t > 2.5:
				L("raggio allo scoperto: danno %.0f" % (hp0 - p.hp))
				measure = false
				next(4)
		4:
			# le pietre del ruggito, poi il raggio con te dietro una pietra
			var b = _boss(g)
			if first("pietre"):
				b.state = "roar"; b.st = 0.9
				p.global_position = Vector2(560, 200)
			if t > 1.2 and first("p1"):
				shot("07_pietre_avviso")
			if t > 2.4 and first("p2"):
				shot("08_pietre_cadute")
				var stones := get_tree().get_nodes_in_group("aker_stones")
				L("pietre a terra (solide): %d" % stones.size())
				# mettiti dietro la pietra più vicina alla testa di est, sulla linea del raggio
				b.state = "recover"; b.st = 5.0
				var head: Vector2 = b.head_pos(1.0)
				var best = null
				for s in stones:
					if s.global_position.x > head.x + 40.0 and (best == null or s.global_position.distance_to(head) < best.global_position.distance_to(head)):
						best = s
				if best != null:
					var dir: Vector2 = (best.global_position + Vector2(0, -6) - head).normalized()
					p.global_position = best.global_position + Vector2(0, -6) + dir * 26.0 + Vector2(0, 6)
					b.side = 1.0
					b._fire_ray(p.global_position - b.global_position, 0.01, 9.0)      # raggio fermo, dritto su di te
					measure = true; hp0 = p.hp; p.invuln_t = 0.0
					flag = 1
				else:
					L("nessuna pietra a est della testa: salto la prova del riparo")
			if flag == 1 and t > 3.6 and first("p3"):
				shot("09_riparo")
			if t > 5.0:
				if flag == 1:
					L("raggio con la pietra in mezzo: danno %.0f (deve essere 0)" % (hp0 - p.hp))
				measure = false
				next(5)
		5:
			# fianchi contro teste
			var b = _boss(g)
			if first("fianchi"):
				b.state = "recover"; b.st = 3.0
				b.global_position = Vector2(400, 260)
				p.global_position = b.global_position + Vector2(0, -60)
				var h0: float = b.hp
				b.take_hit(20.0, Vector2.DOWN, 0.0)
				var flank: float = h0 - b.hp
				p.global_position = b.global_position + Vector2(-90, 0)
				var h1: float = b.hp
				b.take_hit(20.0, Vector2.RIGHT, 0.0)
				L("colpo da 20: sul fianco %.1f, sulla testa %.1f" % [flank, h1 - b.hp])
				b.state = "turn"; b.st = 0.7
			if t > 0.4 and first("giro"):
				shot("10_si_gira")
			if t > 1.2:
				L("dopo il giro: scambiato=%s" % str(b.swapped))
				next(6)
		6:
			# metà vita: trema, poi si divide
			var b = _boss(g)
			if first("trema") and b != null:
				b.take_hit(b.hp, Vector2.UP, 0.0)
				L("dopo il colpo enorme: hp=%.0f di %.0f, stato=%s" % [b.hp, b.max_hp, b.state])
			if t > 0.8 and first("t1"):
				shot("11_trema")
			if t > 2.6 and first("t2"):
				L("divisi: leoni=%d alive=%d boss_group=%d barra=%.2f" % [g._bosses_alive(), g.alive, g.boss_group.size(), g.boss_fill.size.x / g.boss_bar.size.x])
			if t > 3.4:
				shot("12_ieri_e_domani")
				next(7)
		7:
			# a turno: mai due mosse grandi insieme
			frames += 1
			var ie = _lion(g, "ieri")
			var dm = _lion(g, "domani")
			if ie != null and dm != null and ie.busy() and dm.busy():
				both_busy += 1
			if t > 1.5 and first("turni1"):
				shot("13_turni")
			if t > 3.0 and first("turni2"):
				shot("14_turni")
			if t > 7.0:
				L("turni: fotogrammi con tutti e due all'attacco = %d su %d" % [both_busy, frames])
				next(8)
		8:
			# cade Domani: Ieri prende il fuoco; con l'ira, Domani rinasce dopo 8 s
			var dm = _lion(g, "domani")
			if first("cade") and dm != null:
				dm.take_hit(dm.hp + 1.0, Vector2.UP, 0.0)
			var ie = _lion(g, "ieri")
			if t > 0.6 and first("c1") and ie != null:
				shot("15_ieri_solo")
				L("Ieri solo=%s, conto per la rinascita=%.1f" % [str(ie.alone), ie.revive_t])
			if t > 4.0 and first("c2"):
				shot("16_conto_rinascita")
			if t > 9.0:
				L("dopo 9 s: leoni vivi=%d (con l'ira: 2), Domani rinato con vita %.0f" % [g._bosses_alive(), _lion(g, "domani").hp if _lion(g, "domani") != null else -1.0])
				shot("17_rinato")
				next(9)
		9:
			if first("fine"):
				for b in g.boss_group.duplicate():
					if is_instance_valid(b) and not b.dead:
						b.take_hit(b.hp + 1.0, Vector2.UP, 0.0)
			if t > 1.6 and first("sole"):
				shot("18_sole_tremola")
			if t > 7.0:
				shot("19_vittoria")
				L("vittoria: aker_wins=%d finito=%s" % [Meta.aker_wins, str(g.finished)])
				get_tree().quit()
