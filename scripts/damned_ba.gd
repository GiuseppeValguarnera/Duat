extends Enemy
## Ba dannato: l'anima-uccello di un morto che non ha superato il giudizio, persa nel buio di
## Sokar. Attraversa i muri e le colonne e viene verso di te ondeggiando. Quando ti è vicina si
## accende (l'avviso: brilla sempre di più e un cerchio mostra fin dove arriva) ed esplode.
## È fragile: un colpo e si spegne. Insegna la priorità: va abbattuta prima che arrivi.
## Se la colpisci mentre brilla si spegne senza esplodere.

@export var fuse := 0.9
@export var blast_radius := 36.0
@export var blast_damage := 12.0
@export var trigger := 40.0

var state := "drift"
var st := 0.0
var bob := 0.0


func _ready() -> void:
	super._ready()
	collision_layer = 0                    # un'anima: niente muri, niente colonne
	collision_mask = 0
	bob = randf() * TAU


func _behave(delta: float, to: Vector2) -> Vector2:
	st -= delta
	if to == Vector2.ZERO:
		return Vector2.ZERO
	match state:
		"drift":
			if to.length() < trigger:
				state = "fuse"
				st = fuse
				Sfx.play_at("soul", global_position, 0.2)
				return Vector2.ZERO
			var wob := to.normalized().orthogonal() * sin(t * 3.0 + bob) * 0.6
			return (to.normalized() + wob).normalized() * speed
		"fuse":
			if st <= 0.0:
				_blast()
			return to.normalized() * speed * 0.25
	return Vector2.ZERO


func _blast() -> void:
	state = "gone"
	Fx.burst(global_position + Vector2(0, -10), Color(0.62, 0.4, 0.95), 30, 160.0)
	Fx.shake(4.0)
	Sfx.play_at("jar_break", global_position, 0.1)
	var p = get_tree().get_first_node_in_group("player")
	if p != null and not p.dead and p.global_position.distance_to(global_position) < blast_radius:
		p.take_damage(blast_damage, global_position, self)
	die()


func _stagger_time() -> float:
	return 0.0


func _contact_damage() -> float:
	return 0.0


## L'anima-uccello con il volto umano, ma livida: viola e nera, trasparente, con gli occhi vuoti.
## Nell'avviso brilla sempre più forte e compare il cerchio dell'esplosione.
func _draw_body(flash: bool) -> void:
	var k := 0.0
	if state == "fuse":
		k = 1.0 - st / fuse
		var pulse := 0.5 + 0.5 * sin(t * (10.0 + 30.0 * k))
		draw_set_transform(Vector2(0, -2), 0.0, Vector2(1.0, 0.5))
		draw_arc(Vector2.ZERO, blast_radius, 0.0, TAU, 32, Color(0.75, 0.45, 1.0, 0.35 + 0.5 * k), 1.5)
		draw_circle(Vector2.ZERO, blast_radius * k, Color(0.6, 0.3, 0.95, 0.12 + 0.1 * pulse))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var y := -16.0 + sin(t * 4.0 + bob) * 2.0
	var a := 0.75
	var body := _f(Color(0.36, 0.2, 0.5, a), flash)
	var glow := Color(0.7, 0.45, 1.0, 0.18 + 0.5 * k)
	draw_circle(Vector2(0, y), 10.0 + 4.0 * k, glow)
	var flap := sin(t * 8.0 + bob) * 3.0
	for sx in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([Vector2(sx * 2, y), Vector2(sx * 11, y - 4 - flap), Vector2(sx * 9, y + 2 - flap * 0.5), Vector2(sx * 3, y + 3)]), _f(Color(0.22, 0.12, 0.32, a), flash))
	draw_set_transform(Vector2(0, y + 2), 0.0, Vector2(0.7, 1.0))
	draw_circle(Vector2.ZERO, 4.0, body)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_colored_polygon(PackedVector2Array([Vector2(-2, y + 5), Vector2(2, y + 5), Vector2(0, y + 11)]), body)
	# il volto umano, livido, con gli occhi vuoti che si accendono
	draw_circle(Vector2(0, y - 3), 3.0, _f(Color(0.55, 0.45, 0.6, a), flash))
	var eye := Color(1.0, 0.85, 1.0, 0.5 + 0.5 * k)
	draw_circle(Vector2(-1.1, y - 3.3), 0.7, eye)
	draw_circle(Vector2(1.1, y - 3.3), 0.7, eye)
