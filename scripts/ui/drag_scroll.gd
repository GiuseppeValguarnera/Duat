extends Node
## Trascinamento col dito (o col mouse) su TUTTO ciò che scorre: liste, pagine, finestre, carte.
## Prima su telefono le liste scorrevano solo toccando la barra laterale: i pulsanti dentro la
## lista si prendevano il tocco e lo ScrollContainer non lo vedeva mai.
## Qui il gesto si legge prima dell'interfaccia (_input): alla pressione si cerca lo ScrollContainer
## scorrevole sotto il dito (il più in alto e il più interno); se il dito si sposta oltre una soglia
## la lista scorre, e il rilascio viene consumato, così il pulsante sotto il dito non si preme.
## Un tocco breve, invece, arriva normalmente al pulsante.

const THRESHOLD := 7.0          ## pixel (del gioco) prima che un tocco diventi trascinamento

var target: ScrollContainer = null
var start := Vector2.ZERO
var start_v := 0
var dragging := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			target = _find(event.position)
			start = event.position
			start_v = target.scroll_vertical if target != null else 0
			dragging = false
		else:
			if dragging:
				get_viewport().set_input_as_handled()       # niente "clic" alla fine di un trascinamento
			target = null
			dragging = false
	elif event is InputEventMouseMotion and target != null and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		if not is_instance_valid(target) or not target.is_visible_in_tree():
			target = null
			return
		var dy: float = event.position.y - start.y
		if not dragging and absf(dy) > THRESHOLD:
			dragging = true
			start = event.position          # niente salto: si parte da dove la soglia è superata
			start_v = target.scroll_vertical
			dy = 0.0
		if dragging:
			target.scroll_vertical = start_v - int(dy / _scale(target))
			get_viewport().set_input_as_handled()


## La scala tra i pixel dello schermo e quelli dello ScrollContainer (finestre ingrandite).
func _scale(sc: Control) -> float:
	var s := sc.get_global_transform_with_canvas().get_scale().y
	return s if s > 0.01 else 1.0


## Lo ScrollContainer scorrevole sotto il punto: quello sul livello più alto, poi il più interno.
func _find(p: Vector2) -> ScrollContainer:
	var best: ScrollContainer = null
	var best_key := Vector2i(-100000, -1)
	for n in get_tree().root.find_children("*", "ScrollContainer", true, false):
		var sc := n as ScrollContainer
		if sc == null or not sc.is_visible_in_tree():
			continue
		var bar := sc.get_v_scroll_bar()
		if bar.max_value - bar.page <= 1.0:
			continue                                  # non c'è niente da scorrere
		var r := Rect2(sc.get_global_transform_with_canvas().origin, sc.size * sc.get_global_transform_with_canvas().get_scale())
		if not r.has_point(p):
			continue
		var key := Vector2i(_layer(sc), sc.get_path().get_name_count())
		if key.x > best_key.x or (key.x == best_key.x and key.y > best_key.y):
			best_key = key
			best = sc
	return best


func _layer(n: Node) -> int:
	var p := n.get_parent()
	while p != null:
		if p is CanvasLayer:
			return (p as CanvasLayer).layer
		p = p.get_parent()
	return 0


## Pad: la levetta destra scorre la lista più in alto sullo schermo (anche quelle di solo testo, dove
## non c'è niente da selezionare e quindi `follow_focus` non basta). La ricerca si fa solo mentre la
## levetta è spinta.
const STICK_DEAD := 0.35
const STICK_SPEED := 420.0      ## pixel al secondo a levetta piena
var stick_acc := 0.0


func _process(delta: float) -> void:
	var y := 0.0
	for pad in Input.get_connected_joypads():
		var v := Input.get_joy_axis(pad, JOY_AXIS_RIGHT_Y)
		if absf(v) > absf(y):
			y = v
	if absf(y) < STICK_DEAD:
		stick_acc = 0.0
		return
	var sc := _top_scroll()
	if sc == null:
		return
	stick_acc += y * STICK_SPEED * delta
	var step := int(stick_acc)
	if step != 0:
		stick_acc -= step
		sc.scroll_vertical += step


func _top_scroll() -> ScrollContainer:
	var best: ScrollContainer = null
	var best_key := Vector2i(-100000, -1)
	for n in get_tree().root.find_children("*", "ScrollContainer", true, false):
		var sc := n as ScrollContainer
		if sc == null or not sc.is_visible_in_tree():
			continue
		var bar := sc.get_v_scroll_bar()
		if bar.max_value - bar.page <= 1.0:
			continue
		var key := Vector2i(_layer(sc), sc.get_path().get_name_count())
		if key.x > best_key.x or (key.x == best_key.x and key.y > best_key.y):
			best_key = key
			best = sc
	return best
