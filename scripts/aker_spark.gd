extends Enemy
## Scintilla dell'Alba (servitore di Aker, esce dalla porta dell'alba a est): un piccolo spirito di
## fuoco, veloce. Quando ti tocca o ti arriva vicino esplode in una breve fiammata e lascia una
## macchia di fuoco per qualche secondo. Se la abbatti prima, non esplode. Niente ricompense.
## Valori in cima (blocco 11).

const BLAST_REACH := 18.0              ## a questa distanza si accende
const BLAST_RADIUS := 26.0
const BLAST_DAMAGE := 10.0
const BLAST_FUSE := 0.45               ## un attimo di avviso (si gonfia e lampeggia) prima del botto
const PATCH_RADIUS := 15.0             ## macchie piccole: la schermata del telefono resta leggibile
const PATCH_LIFE := 4.0
const PATCH_DAMAGE := 4.0
const MAX_PATCHES := 2                 ## al massimo due macchie di fuoco delle scintille insieme

var fuse := -1.0


func _ready() -> void:
	no_reward = true
	add_to_group("aker_servants")
	super._ready()
	contact = null                         # non morde: esplode quando ti arriva vicino


func _behave(delta: float, to: Vector2) -> Vector2:
	if fuse >= 0.0:
		fuse += delta
		if fuse >= BLAST_FUSE:
			_blast()
		return Vector2.ZERO
	if to == Vector2.ZERO:
		return Vector2.ZERO
	if to.length() < BLAST_REACH:
		fuse = 0.0
		Sfx.play_at("fire_ignite", global_position, 0.2)
		return Vector2.ZERO
	# volteggia un poco mentre arriva
	var side := to.normalized().orthogonal() * sin(t * 5.0 + seed_offset) * 0.4
	return _steer((to.normalized() + side).normalized() * speed, delta)


func _blast() -> void:
	if dead:
		return
	Sfx.play_at("fire_whoosh", global_position, 0.2)
	Fx.burst(global_position + Vector2(0, -6), Color(1.0, 0.6, 0.2), 16, 110.0)
	var p = get_tree().get_first_node_in_group("player")
	if p != null and not p.dead and p.global_position.distance_to(global_position) < BLAST_RADIUS:
		p.take_damage(BLAST_DAMAGE, global_position, null, "aker_scintilla")
	# la macchia di fuoco: al massimo MAX_PATCHES insieme (la più vecchia si spegne)
	var mine: Array = []
	for c in get_parent().get_children():
		if c is Hazards.FirePatch and c.owner_kind == "aker_fuoco":
			mine.append(c)
	while mine.size() >= MAX_PATCHES:
		(mine.pop_front() as Node).queue_free()
	var f := Hazards.FirePatch.new()
	f.radius = PATCH_RADIUS
	f.life = PATCH_LIFE
	f.ignite = 0.15
	f.damage = PATCH_DAMAGE
	f.owner_kind = "aker_fuoco"
	f.position = global_position
	get_parent().add_child(f)
	die()


func _zones() -> void:
	draw_arc(Vector2.ZERO, BLAST_RADIUS, 0.0, TAU, 28, Color(1.0, 0.3, 0.2, 0.6), 1.0)


func _draw_body(flash: bool) -> void:
	if fuse >= 0.0:
		Enemy.warn_circle(self, Vector2.ZERO, BLAST_RADIUS, fuse / BLAST_FUSE)   # la fiammata vera
	var swell := 1.0 + (fuse / BLAST_FUSE) * 0.6 if fuse >= 0.0 else 1.0
	var blink := fuse >= 0.0 and int(fuse * 20.0) % 2 == 0
	var c := Vector2(0, -7.0 + sin(t * 8.0) * 1.0)
	var r := 4.5 * swell
	draw_circle(c, r + 3.0, Color(1.0, 0.45, 0.1, 0.25))
	draw_circle(c, r, Color.WHITE if flash or blink else Color(1.0, 0.55, 0.15))
	draw_circle(c + Vector2(-1, -1), r * 0.5, Color(1.0, 0.92, 0.6))
	for i in range(4):
		var ang := t * 6.0 + i * TAU / 4.0
		draw_line(c + Vector2.from_angle(ang) * (r + 1.0), c + Vector2.from_angle(ang) * (r + 4.0), Color(1.0, 0.75, 0.3, 0.8), 1.0)
