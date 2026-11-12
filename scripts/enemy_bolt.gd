extends Area2D
## Sfera del Sacerdote di Set. Si ferma sui muri e su di te.
## Se stai scattando ti attraversa senza farti nulla.

var direction := Vector2.RIGHT
var speed := 150.0
var damage := 12.0
var life := 4.0
var shooter: Node = null              ## chi l'ha lanciata (per la Bilancia Giusta)
var deflected := false                ## Shu l'ha rimandato indietro: ora ferisce i nemici
var age := 0.0                        ## secondi in volo (registro dei colpi)
var style := "orb"                    ## "orb" = sfera magica, "dart" = dardo di una trappola


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 8            # mondo + hurtbox del giocatore
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	add_child(shape)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta * Run.thoth_time()     # Thoth: Clessidra e Tempo Rubato
	age += delta
	life -= delta
	if life <= 0.0:
		_land()
		queue_free()
	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	if deflected:
		return
	var p = area.get_parent()
	var src: Node = shooter if is_instance_valid(shooter) else null
	# Shu: il Muro di Vento (ogni qualche secondo) e la raffica del Signore delle Tempeste rimandano
	# indietro il proiettile prima che ti tocchi
	if p.is_in_group("player") and not p.dead and style != "dart":
		var wall: bool = Run.has("shu_wall") and p.wind_wall_cd <= 0.0
		if wall or Run.shu_gust:
			if wall:
				p.wind_wall_cd = Run.val("shu_wall")
			_deflect(src)
			return
	if p.is_in_group("player"):
		p.hit_age = age
	if p.is_in_group("player") and p.take_damage(damage, global_position, src):
		queue_free()


func _deflect(src: Node) -> void:
	deflected = true
	direction = (src.global_position - global_position).normalized() if src != null else -direction
	speed = maxf(speed, 220.0)
	life = 2.5
	collision_mask = 1 | 4                # ora il mondo e i nemici
	Fx.burst(global_position, Boons.god_color("shu"), 10, 80.0)
	Sfx.play_at("orb_pop", global_position, 0.2)


func _on_body_entered(body: Node) -> void:
	if deflected and body is Enemy and not body.dead:
		body.take_hit(damage * Run.all_damage_mult(), direction, 80.0)
		queue_free()
		return
	if body is StaticBody2D:
		Fx.burst(global_position, Color(0.85, 0.4, 1.0), 6, 60.0)
		if style != "dart" and style != "javelin" and style != "knife":
			Sfx.play_at("orb_pop", global_position, 0.2)
		_land()
		queue_free()


## Lo sputo del Serpente, dove cade, lascia una pozza di veleno.
func _land() -> void:
	if style != "venom" or not is_inside_tree():
		return
	var pud := Hazards.VenomPuddle.new()
	get_parent().add_child.call_deferred(pud)
	pud.position = position - direction * 4.0


func _draw() -> void:
	if Run.show_zones():
		draw_arc(Vector2.ZERO, 4.0, 0.0, TAU, 12, Color(1.0, 0.3, 0.2, 0.9), 1.0)
	if style == "javelin":
		# il giavellotto del deserto: asta lunga, punta di bronzo, piume rosse in coda
		var tail := -direction * 18.0
		draw_line(tail, direction * 2.0, Color(0.12, 0.08, 0.05), 2.6)
		draw_line(tail, direction * 2.0, Color(0.62, 0.44, 0.24), 1.6)
		draw_colored_polygon(PackedVector2Array([direction * 8.0, direction * 1.0 + direction.orthogonal() * 2.5, direction * 1.0 - direction.orthogonal() * 2.5]), Color(0.8, 0.55, 0.25))
		draw_line(tail, tail + direction * 3.0 + direction.orthogonal() * 3.0, Color(0.85, 0.25, 0.15), 1.5)
		draw_line(tail, tail + direction * 3.0 - direction.orthogonal() * 3.0, Color(0.85, 0.25, 0.15), 1.5)
		return
	if style == "knife":
		# il coltello dei demoni di Apopi: lama di selce che gira, con una scia viola
		var kd := Vector2.from_angle(age * 22.0)
		draw_line(-direction * 10.0, Vector2.ZERO, Color(0.6, 0.3, 0.9, 0.35), 3.0)
		draw_colored_polygon(PackedVector2Array([kd * 7.0, kd.orthogonal() * 2.0, -kd * 4.0, -kd.orthogonal() * 2.0]), Color(0.1, 0.06, 0.1))
		draw_colored_polygon(PackedVector2Array([kd * 6.0, kd.orthogonal() * 1.2, -kd * 1.0, -kd.orthogonal() * 1.2]), Color(0.86, 0.84, 0.92))
		draw_line(-kd * 1.0, -kd * 4.0, Color(0.6, 0.35, 0.2), 1.8)
		return
	if style == "isfet":
		draw_circle(Vector2.ZERO, 6.5, Color(0.6, 0.25, 0.9, 0.3))
		draw_circle(Vector2.ZERO, 4.0, Color(0.1, 0.03, 0.16))
		draw_arc(Vector2.ZERO, 4.0, 0.0, TAU, 12, Color(0.8, 0.45, 1.0), 1.0)
		return
	if style == "sand":
		draw_circle(Vector2.ZERO, 6.0, Color(0.95, 0.8, 0.5, 0.3))
		draw_circle(Vector2.ZERO, 3.5, Color(0.9, 0.72, 0.42))
		draw_circle(Vector2.ZERO, 1.5, Color(1, 0.97, 0.85))
		return
	if style == "dart":
		var back := -direction * 12.0
		draw_line(back, Vector2.ZERO, Color(0.55, 0.4, 0.22), 2.0)
		draw_colored_polygon(PackedVector2Array([direction * 4.0, direction.orthogonal() * 2.5, -direction.orthogonal() * 2.5]), Color(0.85, 0.85, 0.9))
		draw_line(back, back + direction * 3.0 + direction.orthogonal() * 3.0, Color(0.9, 0.3, 0.2), 1.5)
		draw_line(back, back + direction * 3.0 - direction.orthogonal() * 3.0, Color(0.9, 0.3, 0.2), 1.5)
		return
	if style == "venom":
		draw_circle(Vector2.ZERO, 6.0, Color(0.4, 1.0, 0.35, 0.3))
		draw_circle(Vector2.ZERO, 3.5, Color(0.35, 0.85, 0.25))
		draw_circle(Vector2.ZERO, 1.5, Color(0.9, 1, 0.8))
		return
	draw_circle(Vector2.ZERO, 6.0, Color(0.85, 0.4, 1.0, 0.3))
	draw_circle(Vector2.ZERO, 3.5, Color(0.75, 0.3, 1.0))
	draw_circle(Vector2.ZERO, 1.5, Color(1, 0.9, 1))
