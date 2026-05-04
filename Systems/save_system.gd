extends Node
class_name SaveSystem

const SAVE_PATH := "user://savegame.json"
var is_loading_game: bool = false

func save_game(board: Node) -> bool:
	if board == null:
		push_error("SaveSystem.save_game: board is null")
		return false

	var map_scene_path := ""
	var current_scene := get_tree().current_scene

	if current_scene != null and current_scene.scene_file_path != "":
		map_scene_path = current_scene.scene_file_path
	else:
		push_error("Current scene has no scene_file_path.")
		return false

	print("BOARD NAME: ", board.name)
	print("CURRENT SCENE NAME: ", current_scene.name)
	print("CURRENT SCENE PATH: ", current_scene.scene_file_path)

	var save_data := {
		"meta": {
			"version": 1,
			"saved_at_unix": Time.get_unix_time_from_system(),
			"map_scene_path": map_scene_path
		},
		"turn_state": _build_turn_state_data(),
		"board_state": _build_board_state_data(board),
		"settlements": _build_settlement_data()
	}

	var json_text := JSON.stringify(save_data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error("Could not open save file for writing: %s" % SAVE_PATH)
		return false

	file.store_string(json_text)
	file.close()

	print("Game saved to: %s" % SAVE_PATH)
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)

func load_game() -> bool:
	if not has_save():
		push_error("No save file found.")
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open save file for reading.")
		return false

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(text)
	if parse_result != OK:
		push_error("Save file JSON parse error.")
		return false

	var data: Dictionary = json.data
	var meta: Dictionary = data.get("meta", {})
	var map_scene_path: String = meta.get("map_scene_path", "")

	if map_scene_path == "":
		push_error("Save file does not contain map_scene_path.")
		return false

	is_loading_game = true
	call_deferred("_deferred_load_game", data, map_scene_path)
	return true


func _deferred_load_game(data: Dictionary, map_scene_path: String) -> void:
	var tree := get_tree()
	if tree == null:
		push_error("SceneTree not available.")
		is_loading_game = false
		return

	var change_result := tree.change_scene_to_file(map_scene_path)
	if change_result != OK:
		push_error("Failed to change scene to saved map: %s" % map_scene_path)
		is_loading_game = false
		return

	await tree.process_frame
	await tree.process_frame

	var board := _find_board_in_current_scene()
	if board == null:
		push_error("Could not find board node in loaded map scene.")
		is_loading_game = false
		return

	_apply_turn_state_data(data.get("turn_state", {}))
	_apply_settlement_data(data.get("settlements", []))
	_apply_board_state_data(board, data.get("board_state", {}))
	_refresh_loaded_game(board)

	is_loading_game = false
	print("Game loaded from: %s" % SAVE_PATH)

func _find_board_in_current_scene() -> Node:
	var root := get_tree().current_scene
	if root == null:
		return null

	if root.is_in_group("board"):
		return root

	var boards := get_tree().get_nodes_in_group("board")
	if boards.size() > 0:
		return boards[0]

	return root.find_child("Board", true, false)


func _build_turn_state_data() -> Dictionary:
	return {
		"turn_index": TurnState.turn_index,
		"current_turn": int(TurnState.current_turn),
		"round": TurnState.round,

		"season_index": TurnState.season_index,
		"current_season": TurnState.current_season,
		"season_extended_this_round": TurnState.season_extended_this_round,
		"elves_extended_season_this_season": TurnState.elves_extended_season_this_season,

		"elf_serenity": TurnState.elf_serenity,
		"elf_magic": TurnState.elf_magic,
		"gold": TurnState.gold.duplicate(true),
		"armor": TurnState.armor.duplicate(true),

		"orc_current_dark_lord": TurnState.orc_current_dark_lord,
		"orc_dead_dark_lords": TurnState.orc_dead_dark_lords.duplicate(true),

		"dwarf_gold_action_assignments": TurnState.dwarf_gold_action_assignments.duplicate(true)
	}


func _build_board_state_data(board: Node) -> Dictionary:
	var data := {
		"draft_mode": false,
		"draft_phase": 0,
		"draft_picks_remaining": 0,
		"selected_settlement_id": "",
		"pending_target_id": "",
		"pending_is_attack": false
	}

	if "draft_mode" in board:
		data["draft_mode"] = board.draft_mode
	if "draft_phase" in board:
		data["draft_phase"] = board.draft_phase
	if "draft_picks_remaining" in board:
		data["draft_picks_remaining"] = board.draft_picks_remaining

	if "selected" in board and board.selected != null:
		data["selected_settlement_id"] = board.selected.settlement_id

	if "pending_target" in board and board.pending_target != null:
		data["pending_target_id"] = board.pending_target.settlement_id

	if "pending_is_attack" in board:
		data["pending_is_attack"] = board.pending_is_attack

	return data


func _build_settlement_data() -> Array:
	var result: Array = []

	for settlement: Settlement in get_tree().get_nodes_in_group("settlements"):
		result.append({
			"settlement_id": settlement.settlement_id,
			"settlement_name": settlement.settlement_name,
			"faction": int(settlement.faction),
			"soldiers": settlement.soldiers,
			"building_slot_count": settlement.building_slot_count,
			"building_slots": settlement.building_slots.duplicate(),
			"mercenaries_hired_this_turn": settlement.mercenaries_hired_this_turn,
			"infiltration_faction": settlement.infiltration_faction,
			"has_orc_dark_lord_token": settlement.has_orc_dark_lord(),
			"is_orc_war_promise": settlement.is_orc_war_promise
		})

	return result


func _apply_turn_state_data(data: Dictionary) -> void:
	TurnState.turn_index = data.get("turn_index", 0)
	TurnState.current_turn = data.get("current_turn", Faction.Type.ORC)
	TurnState.round = data.get("round", 1)

	TurnState.season_index = data.get("season_index", 0)
	TurnState.current_season = data.get("current_season", TurnState.Season.SPRING)
	TurnState.season_extended_this_round = data.get("season_extended_this_round", false)
	TurnState.elves_extended_season_this_season = data.get("elves_extended_season_this_season", false)

	TurnState.elf_serenity = data.get("elf_serenity", 2)
	TurnState.elf_magic = data.get("elf_magic", 8)

	TurnState.gold = _restore_int_keyed_dict(data.get("gold", {}))
	TurnState.armor = _restore_int_keyed_dict(data.get("armor", {}))

	TurnState.orc_current_dark_lord = data.get("orc_current_dark_lord", TurnState.ORC_LORD_NONE)
	TurnState.orc_dead_dark_lords = data.get("orc_dead_dark_lords", {}).duplicate(true)

	TurnState.dwarf_gold_action_assignments = _restore_int_keyed_dict(
	data.get("dwarf_gold_action_assignments", {})
)


func _apply_settlement_data(saved_settlements: Array) -> void:
	var settlement_lookup := {}

	for settlement: Settlement in get_tree().get_nodes_in_group("settlements"):
		settlement_lookup[settlement.settlement_id] = settlement
		print("MAP SETTLEMENT FOUND: ", settlement.name, " id=", settlement.settlement_id)

	for entry in saved_settlements:
		var settlement_id: String = entry.get("settlement_id", "")
		print("SAVE ENTRY ID: ", settlement_id)

		if settlement_id == "":
			print("Skipped saved settlement because id is empty")
			continue

		if not settlement_lookup.has(settlement_id):
			push_warning("Saved settlement id not found in current map: %s" % settlement_id)
			continue

		var settlement: Settlement = settlement_lookup[settlement_id]
		print("Applying save to settlement: ", settlement.name)

		settlement.set_building_slot_count(entry.get("building_slot_count", settlement.building_slot_count))
		settlement.clear_buildings()

		settlement.set_faction(entry.get("faction", Faction.Type.NEUTRAL))
		settlement.set_soldiers(entry.get("soldiers", 0))

		var saved_buildings: Array = entry.get("building_slots", [])
		for i in range(min(saved_buildings.size(), settlement.building_slots.size())):
			settlement.set_building_in_slot(i, saved_buildings[i])

		settlement.mercenaries_hired_this_turn = entry.get("mercenaries_hired_this_turn", false)

		var infiltration_faction: int = entry.get("infiltration_faction", Faction.Type.NEUTRAL)
		if infiltration_faction == Faction.Type.NEUTRAL:
			settlement.clear_infiltration()
		else:
			settlement.set_infiltration(infiltration_faction)

		settlement.set_orc_dark_lord_present(entry.get("has_orc_dark_lord_token", false))
		settlement.set_orc_war_promise(entry.get("is_orc_war_promise", false))

func _apply_board_state_data(board: Node, data: Dictionary) -> void:
	if "draft_mode" in board:
		board.draft_mode = data.get("draft_mode", false)
	if "draft_phase" in board:
		board.draft_phase = data.get("draft_phase", 0)
	if "draft_picks_remaining" in board:
		board.draft_picks_remaining = data.get("draft_picks_remaining", 0)
	if "pending_is_attack" in board:
		board.pending_is_attack = data.get("pending_is_attack", false)

	var selected_id: String = data.get("selected_settlement_id", "")
	var pending_target_id: String = data.get("pending_target_id", "")

	var settlement_lookup := {}
	for settlement: Settlement in get_tree().get_nodes_in_group("settlements"):
		settlement_lookup[settlement.settlement_id] = settlement

	if "selected" in board:
		board.selected = settlement_lookup.get(selected_id, null)

	if "pending_target" in board:
		board.pending_target = settlement_lookup.get(pending_target_id, null)


func _refresh_loaded_game(board: Node) -> void:
	TurnState.turn_changed.emit(TurnState.current_turn)
	TurnState.round_changed.emit(TurnState.round)
	TurnState.resources_changed.emit()
	TurnState.season_changed.emit(TurnState.current_season)

	if board.has_method("update_draft_label") and "draft_mode" in board and board.draft_mode:
		board.update_draft_label()

	var has_selected := false
	if "selected" in board:
		has_selected = board.selected != null

	if board.has_method("_show_deselect_button"):
		board._show_deselect_button(has_selected)

	if "selected" in board and board.selected != null:
		if board.has_method("_apply_selection_visuals"):
			board._apply_selection_visuals()

		if "ui" in board and board.ui != null:
			board.ui.show_settlement_details(board.selected)
	elif "ui" in board and board.ui != null:
		board.ui.hide_settlement_details()
	if board.has_method("update_land_control_ui"):
		board.update_land_control_ui()


func _restore_int_keyed_dict(source: Dictionary) -> Dictionary:
	var result := {}
	for key in source.keys():
		result[int(key)] = source[key]
	return result
	
