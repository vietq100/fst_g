extends TestCase
## Every player-facing text is a key with English and Vietnamese (00_RULES.md §11b, D61).

const PLACEHOLDER := "\\{[a-zA-Z0-9_]+\\}"


func after_each() -> void:
	Loc.set_locale("en", false)


func test_every_key_has_both_languages_and_the_same_placeholders() -> void:
	var regex := RegEx.create_from_string(PLACEHOLDER)
	assert_true(Loc.get_keys().size() > 400, "translations loaded")
	for key: String in Loc.get_keys():
		var entry := Loc.get_entry(key)
		for code in Loc.LOCALES:
			assert_true(str(entry.get(code, "")) != "", "%s has %s" % [key, code])
		var en := _placeholders(regex, str(entry.get("en", "")))
		var vi := _placeholders(regex, str(entry.get("vi", "")))
		assert_eq(vi, en, "placeholders of %s" % key)


func test_keys_used_in_code_and_data_exist() -> void:
	var regex := RegEx.create_from_string("Loc\\.t\\(\\s*\"([^\"%]+)\"")
	var data_regex := RegEx.create_from_string("(?m)^(?:display_name|description) = \"([^\"]+)\"")
	var missing: Array[String] = []
	for path in _files("res://", [".gd"]):
		if path.begins_with("res://tests/"):
			continue
		for match in regex.search_all(FileAccess.get_file_as_string(path)):
			if not Loc.has_key(match.get_string(1)):
				missing.append("%s: %s" % [path, match.get_string(1)])
	for path in _files("res://data/", [".tres"]):
		for match in data_regex.search_all(FileAccess.get_file_as_string(path)):
			if not Loc.has_key(match.get_string(1)):
				missing.append("%s: %s" % [path, match.get_string(1)])
	assert_eq(missing, [] as Array[String])


func test_switching_language_translates_data_and_ui() -> void:
	var item := DataRegistry.get_item(&"iron_sword")
	assert_eq(item.get_name_key(), "item.iron_sword.name")
	var english := item.display_name
	Loc.set_locale("vi", false)
	assert_true(item.display_name != english and item.display_name != "item.iron_sword.name", "Vietnamese name")
	assert_eq(Loc.t("ui.common.needs_gold", {"gold": 5}), "Cần 5 vàng")
	Loc.set_locale("en", false)
	assert_eq(item.display_name, english)
	assert_eq(Loc.t("ui.common.needs_gold", {"gold": 5}), "Needs 5 gold")


func _placeholders(regex: RegEx, text: String) -> Array[String]:
	var found: Array[String] = []
	for match in regex.search_all(text):
		found.append(match.get_string())
	found.sort()
	return found


func _files(folder: String, extensions: Array) -> Array[String]:
	var result: Array[String] = []
	for file in DirAccess.get_files_at(folder):
		for extension: String in extensions:
			if file.ends_with(extension):
				result.append(folder.path_join(file))
	for directory in DirAccess.get_directories_at(folder):
		if directory.begins_with("."):
			continue
		result.append_array(_files(folder.path_join(directory), extensions))
	return result
