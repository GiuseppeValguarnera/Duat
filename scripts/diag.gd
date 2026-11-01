class_name Diag
## Registro di diagnosi per la versione web (i crash su iPhone: la scheda si chiude o la pagina si
## ricarica). A ogni stanza e a ogni cambio di scena il gioco scrive nel localStorage del browser
## gli ultimi eventi con i numeri della memoria. La pagina (web/shell.html) segna se il gioco era
## aperto e visibile: se al prossimo avvio risulta ancora "aperto", vuol dire che è morto senza
## chiudersi, e quel registro diventa l'"ultimo problema" che si legge nelle Opzioni.
## Niente dati personali: solo scena, regione, stanza, arma, memoria, oggetti e nodi.
## Ogni accesso al browser è dentro un try/catch: se il localStorage non c'è, non succede nulla.

const MAX_EVENTS := 12
static var _events: Array = []


static func _web() -> bool:
	return OS.has_feature("web")


## Un evento: "stanza 4", "boss", "Sala", "cambio scena"... con i numeri del momento.
static func record(what: String) -> void:
	var line := "%s | r%d s%d %s | mem %.0f MB · ogg %d · nodi %d · orfani %d" % [what, Run.region, Run.room, Run.weapon,
		OS.get_static_memory_usage() / 1048576.0,
		int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))]
	_events.append(line)
	while _events.size() > MAX_EVENTS:
		_events.pop_front()
	if not _web():
		return
	var payload := JSON.stringify({"t": Time.get_datetime_string_from_system(), "v": Updater.current(), "ev": _events})
	JavaScriptBridge.eval("try { localStorage.setItem('duat_diag_live', %s); } catch (e) {}" % JSON.stringify(payload), true)


## L'ultimo problema registrato ("" se nessuno): data, versione e gli ultimi eventi.
static func last_problem() -> String:
	if not _web():
		return ""
	var raw = JavaScriptBridge.eval("(function(){ try { return localStorage.getItem('duat_diag_last') || ''; } catch (e) { return ''; } })()", true)
	if not (raw is String) or raw == "":
		return ""
	var d = JSON.parse_string(raw)
	if not (d is Dictionary):
		return ""
	var ev: Array = d.get("ev", [])
	var out := Lang.t("Il %s (versione %s) il gioco si è chiuso da solo.") % [String(d.get("t", "?")).replace("T", " "), String(d.get("v", "?"))]
	if d.has("err") and String(d["err"]) != "":
		out += "\n" + Lang.t("Errore: %s") % d["err"]
	if not ev.is_empty():
		out += "\n" + Lang.t("Ultimo momento: %s") % ev[ev.size() - 1]
	return out


## Riassunto breve per la riga delle Opzioni: regione, stanza, arma, memoria.
static func last_problem_short() -> String:
	var full := last_problem()
	if full == "":
		return ""
	var i := full.find("| r")
	return full.substr(i + 2, 40).strip_edges() if i >= 0 else Lang.t("sì")


static func clear() -> void:
	if _web():
		JavaScriptBridge.eval("try { localStorage.removeItem('duat_diag_last'); } catch (e) {}", true)
