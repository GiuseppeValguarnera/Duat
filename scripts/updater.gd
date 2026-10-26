class_name Updater
## Aggiornamenti della versione web (telefono e browser). La pagina (web/shell.html) controlla
## version.txt sul sito e scrive in window.duatUpdate il numero della versione nuova, se c'è.
## Qui lo si legge ogni qualche secondo, e "Aggiorna il gioco" chiama window.duatDoUpdate().

static var _cached := false
static var _checked_ms := -100000


## true solo nella versione web.
static func supported() -> bool:
	return OS.has_feature("web")


static func _js(expr: String) -> String:
	if not supported():
		return ""
	var v = JavaScriptBridge.eval(expr, true)
	return v if v is String else ""


## C'è una versione più nuova sul sito? (controllato al massimo ogni 5 secondi)
static func available() -> bool:
	if not supported():
		return false
	var now := Time.get_ticks_msec()
	if now - _checked_ms > 5000:
		_checked_ms = now
		_cached = _js("window.duatUpdate || ''") != ""
	return _cached


## "ok", "pending" (sta ancora controllando) o "error" (niente rete).
static func check_state() -> String:
	var s := _js("window.duatCheck || ''")
	return s if s != "" else "error"


## Chiede di nuovo al sito qual è l'ultima versione.
static func recheck() -> void:
	_checked_ms = -100000
	_js("(window.duatCheckUpdate && window.duatCheckUpdate(), '')")


static func current() -> String:
	return pretty(_js("window.DUAT_BUILD || ''"))


## Il numero di versione ("0.1.0"): lo stesso nel file VERSION del progetto.
static func version() -> String:
	var v := _js("window.DUAT_VERSION || ''")
	if v == "" or v.begins_with("__"):
		var f := FileAccess.open("res://VERSION", FileAccess.READ)
		v = f.get_as_text().strip_edges() if f != null else "?"
	return v


## "dev" (sviluppo, sul sito GitHub) o "stable" (la prova pubblica su itch.io).
static func channel() -> String:
	var c := _js("window.DUAT_CHANNEL || ''")
	return "stable" if c == "stable" else "dev"


## Versione da mostrare: "0.1.0 · sviluppo · 25/10 ore 20:02" o "0.1.0".
static func label() -> String:
	if channel() == "stable":
		return version()
	var b := current()
	return Lang.t("%s · sviluppo") % version() + ("" if b == "sconosciuta" or b == "" else " · " + b)


static func latest() -> String:
	return pretty(_js("window.duatLatest || ''"))


## Da "6133f22-20261025200258" a "25/10 ore 20:02". Il codice dopo il trattino è la data della pubblicazione.
static func pretty(build: String) -> String:
	var parts := build.split("-")
	if parts.size() < 2 or parts[1].length() < 12:
		return build if build != "" else "sconosciuta"
	var d := parts[1]
	return Lang.t("%s/%s ore %s:%s") % [d.substr(6, 2), d.substr(4, 2), d.substr(8, 2), d.substr(10, 2)]


## Salva, lascia al browser il tempo di scrivere il salvataggio, poi scarica la versione nuova.
static func update_now(tree: SceneTree) -> void:
	if not supported():
		return
	Meta.save()
	await tree.create_timer(0.6, true, false, true).timeout
	JavaScriptBridge.eval("window.duatDoUpdate()", true)
