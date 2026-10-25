class_name Updater
## Aggiornamenti della versione web (telefono e browser). La pagina (web/shell.html) controlla
## version.txt sul sito e scrive in window.duatUpdate il numero della versione nuova, se c'è.
## Qui lo si legge ogni qualche secondo, e "Aggiorna il gioco" chiama window.duatDoUpdate().

static var _cached := false
static var _checked_ms := -100000


## true solo nella versione web.
static func supported() -> bool:
	return OS.has_feature("web")


## C'è una versione più nuova sul sito? (controllato al massimo ogni 5 secondi)
static func available() -> bool:
	if not supported():
		return false
	var now := Time.get_ticks_msec()
	if now - _checked_ms > 5000:
		_checked_ms = now
		var v = JavaScriptBridge.eval("window.duatUpdate || ''", true)
		_cached = v is String and v != ""
	return _cached


## Salva, lascia al browser il tempo di scrivere il salvataggio, poi scarica la versione nuova.
static func update_now(tree: SceneTree) -> void:
	if not supported():
		return
	Meta.save()
	await tree.create_timer(0.6, true, false, true).timeout
	JavaScriptBridge.eval("window.duatDoUpdate()", true)
