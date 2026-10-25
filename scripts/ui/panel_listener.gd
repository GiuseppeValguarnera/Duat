extends Node
## Ascolta Tab/Select anche a gioco in pausa, per aprire e chiudere il menu dei doni.
## (Era una classe interna di game.gd: spostata qui nel riordino del codice.)

var game: Node

func _process(_delta: float) -> void:
	# a gioco in pausa (schermata della morte) il tasto R / Start arriva solo da qui
	if game.finished and game.can_leave and get_tree().paused and Input.is_action_just_pressed("restart"):
		_leave()

func _leave() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/hub.tscn")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if game.pause_menu != null:
		var on_audio: bool = game.pause_menu.get_node_or_null("Audio") != null
		if on_audio and event.is_action_pressed("ui_cancel") and not event.is_action_pressed("pause"):
			game._close_audio_menu()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
			game._toggle_pause()
			get_viewport().set_input_as_handled()
		return
	# sul telefono: un tocco chiude il pannello dei doni, e a fine discesa riporta alla Sala
	if event is InputEventScreenTouch and event.pressed:
		if game.panel != null and game.menu == null:
			game._toggle_boons_panel()
			get_viewport().set_input_as_handled()
			return
		if game.finished and game.can_leave:
			_leave()
			return
	if event.is_action_pressed("pause") and not game.finished:
		game._toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("boons_menu") or (game.panel != null and event.is_action_pressed("ui_cancel")):
		game._toggle_boons_panel()
		get_viewport().set_input_as_handled()

# durante la scelta dei doni Tab arriverebbe prima ai pulsanti (cambia la selezione): lo prendiamo qui
func _input(event: InputEvent) -> void:
	if game.menu != null and game.pause_menu == null and not game.finished:
		if event.is_action_pressed("boons_menu") or (game.panel != null and event.is_action_pressed("ui_cancel")):
			game._toggle_boons_panel()
			get_viewport().set_input_as_handled()



## HUD in alto a sinistra, in stile egizio: riquadro scuro con il bordo d'oro, l'ankh accanto
## alla vita (con la scia rossa del danno appena subito), il segno del Ka con il suo numero,
## la stanza, e l'Occhio di Horus che si riempie mentre si ricarica (con un pallino per carica).
