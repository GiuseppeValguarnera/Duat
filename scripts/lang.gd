class_name Lang
extends RefCounted
## Le lingue del gioco: italiano (la lingua in cui è scritto) e inglese. Le traduzioni sono in
## i18n/duat_translations.csv, con la frase italiana esatta come chiave (vedi i18n/README.md).
##
## Regola per chi scrive codice: le frasi con un segnaposto si traducono PRIMA di riempirle,
## `Lang.t("Stanza %d/%d") % [a, b]`, mai dopo; i testi presi dai dizionari costanti (doni,
## capitoli, storie) si traducono dove si leggono. Le etichette con un testo fisso si traducono
## da sole (i nodi Control di Godot lo fanno in automatico).

const NAMES := {"it": "Italiano", "en": "English"}


## La frase nella lingua scelta (se manca la traduzione resta l'italiano).
static func t(s: String) -> String:
	if s == "":
		return s
	return String(TranslationServer.translate(s))


## "it" o "en".
static func code() -> String:
	return TranslationServer.get_locale().substr(0, 2)


static func is_en() -> bool:
	return code() == "en"


## Una copia tradotta di un dato costante (dizionari e liste annidati): si traducono i valori,
## mai le chiavi. Le frasi senza traduzione restano uguali, quindi gli id ("ra", "lancia") non
## cambiano.
static func deep(v: Variant) -> Variant:
	match typeof(v):
		TYPE_STRING:
			return t(v)
		TYPE_ARRAY:
			var out := []
			for x in v:
				out.append(deep(x))
			return out
		TYPE_DICTIONARY:
			var d := {}
			for k in v:
				d[k] = deep(v[k])
			return d
	return v


## Rifà le copie tradotte dei dati (doni, capitoli, storie, armi, pesi) nella lingua scelta.
static func refresh_data() -> void:
	Boons.refresh_lang()
	Chapters.refresh_lang()
	Lore.refresh_lang()
	Weapons.refresh_lang()
	Weights.refresh_lang()
	Restorations.refresh_lang()
	Amulets.refresh_lang()
	Challenges.refresh_lang()


## Applica la scelta delle Opzioni: "auto" segue la lingua del telefono o del computer
## (italiano per chi ce l'ha in italiano, inglese per tutti gli altri).
static func apply(choice: String) -> void:
	var c := choice
	if OS.get_environment("DUAT_LANG") != "":
		c = OS.get_environment("DUAT_LANG")      # per le prove automatiche (il bot legge l'italiano)
	if c == "" or c == "auto":
		c = "it" if OS.get_locale_language() == "it" else "en"
	TranslationServer.set_locale(c)
	refresh_data()
