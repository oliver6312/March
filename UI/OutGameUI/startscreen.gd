extends CanvasLayer



func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/OutGameUI/map selection.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_continue_game_pressed() -> void:
	SaveManager.load_game()


func _on_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/OutGameUI/tutorial/tutorial.tscn")
