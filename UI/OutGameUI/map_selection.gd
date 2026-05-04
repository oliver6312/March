extends CanvasLayer

var Maps = [
	"res://PlayBoard/Fjord/Fjordboard.tscn",
	"res://PlayBoard/Split/SplitBoard.tscn",
	"res://PlayBoard/Bridge/bridgeBoard.tscn",
	"res://PlayBoard/Isle/IsleBoard.tscn"
]

func _on_fjord_pressed() -> void:
	SaveManager.is_loading_game = false
	get_tree().change_scene_to_file(Maps[0])
	


func _on_split_pressed() -> void:
	SaveManager.is_loading_game = false
	get_tree().change_scene_to_file(Maps[1])



func _on_randommap_pressed() -> void:
	SaveManager.is_loading_game = false
	
	randomize()
	var random_index = randi() % Maps.size()
	get_tree().change_scene_to_file(Maps[random_index])

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://UI/OutGameUI/Startscreen.tscn")


func _on_bridge_pressed() -> void:
	get_tree().change_scene_to_file(Maps[2])


func _on_isle_pressed() -> void:
	get_tree().change_scene_to_file(Maps[3])
