extends Node
## Autoload `Loc`. Every player-facing text is a key (00_RULES.md §11, DOCS/ARCHITECTURE/
## LOCALIZATION.md, DECISIONS.md D61). Keys and their English / Vietnamese text live in one JSON
## file; they are loaded into Godot's TranslationServer, so `tr(key)` and Controls whose text is a
## key translate too. `Loc.t(key, {"name": value})` fills `{name}` placeholders.
## The chosen language is saved in user://settings.cfg; the first run follows the OS language.

signal locale_changed(locale: String)

const TRANSLATIONS_PATH := "res://data/i18n/translations.json"
const SETTINGS_PATH := "user://settings.cfg"
const LOCALES: Array[String] = ["en", "vi"]
## Shown in the language picker in their own language (never translated).
const LOCALE_NAMES := {"en": "English", "vi": "Tiếng Việt"}
const FALLBACK := "en"

var locale := FALLBACK
## key -> {"en": text, "vi": text}
var _entries: Dictionary = {}
var _translations: Array[Translation] = []
## Missing keys already reported (one warning each).
var _missing: Dictionary = {}


func _init() -> void:
	load_translations(TRANSLATIONS_PATH)
	_apply_locale(_saved_locale())


## (Re)loads the JSON file into the TranslationServer. Returns false if it is missing or broken.
func load_translations(path: String) -> bool:
	for translation in _translations:
		TranslationServer.remove_translation(translation)
	_translations.clear()
	_entries.clear()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Loc: cannot open %s" % path)
		return false
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not data is Dictionary:
		push_error("Loc: %s is not a JSON object" % path)
		return false
	_entries = data
	for code in LOCALES:
		var translation := Translation.new()
		translation.locale = code
		for key: String in _entries:
			var entry: Variant = _entries[key]
			if entry is Dictionary:
				var text: String = str(entry.get(code, entry.get(FALLBACK, key)))
				translation.add_message(key, text)
		TranslationServer.add_translation(translation)
		_translations.append(translation)
	return true


## Translated text of `key`, with `{placeholders}` filled from `args` (a Dictionary, or an Array
## for `{0}`, `{1}`…). A missing key is shown as the key itself (and reported once).
func t(key: String, args: Variant = null) -> String:
	if not _entries.has(key) and not _missing.has(key):
		_missing[key] = true
		push_warning("Loc: missing key '%s'" % key)
	var text := TranslationServer.translate(key)
	if args != null:
		text = text.format(args)
	return text


func has_key(key: String) -> bool:
	return _entries.has(key)


func get_keys() -> Array:
	return _entries.keys()


## The entry {"en": …, "vi": …} of a key (tests, tools).
func get_entry(key: String) -> Dictionary:
	return _entries.get(key, {})


## Switches the language. `persist` saves it to the settings file.
func set_locale(code: String, persist: bool = true) -> void:
	if not LOCALES.has(code):
		code = FALLBACK
	var changed := code != locale
	_apply_locale(code)
	if persist:
		var config := ConfigFile.new()
		config.load(SETTINGS_PATH)
		config.set_value("general", "locale", code)
		config.save(SETTINGS_PATH)
	if changed:
		locale_changed.emit(code)


func _apply_locale(code: String) -> void:
	locale = code if LOCALES.has(code) else FALLBACK
	TranslationServer.set_locale(locale)


## Saved choice, else the OS language when it is one we have, else English.
func _saved_locale() -> String:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		var saved := str(config.get_value("general", "locale", ""))
		if LOCALES.has(saved):
			return saved
	var os_code := OS.get_locale_language()
	return os_code if LOCALES.has(os_code) else FALLBACK
