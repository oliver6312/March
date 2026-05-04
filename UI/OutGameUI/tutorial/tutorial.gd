extends Node2D

@onready var page_image: TextureRect = $PageImage
@onready var next_button: Button = $NextButton
@onready var previous_button: Button = $PreviousButton
var page := 0

var pages: Array[Texture2D] = [
	preload("res://UI/OutGameUI/tutorial/pages/turutale part 1_page-0001.jpg"),
	preload("res://UI/OutGameUI/tutorial/pages/To win, you must increase your land control to above 50. (1)_page-0001.jpg"),
	preload("res://UI/OutGameUI/tutorial/pages/turutale part 1_page-0003.jpg"),
	preload("res://UI/OutGameUI/tutorial/pages/turutale part 1_page-0004.jpg"),
	preload("res://UI/OutGameUI/tutorial/pages/turutale part 1_page-0005.jpg"),
	preload("res://UI/OutGameUI/tutorial/pages/turutale part 1_page-0006.jpg"),
	preload("res://UI/OutGameUI/tutorial/pages/turale part 2_page-0001.jpg"),
	preload("res://UI/OutGameUI/tutorial/pages/turale part 2_page-0002.jpg"),
	preload("res://UI/OutGameUI/tutorial/pages/turale part 2_page-0003.jpg"),
	preload("res://UI/OutGameUI/tutorial/pages/turale part 2_page-0004.jpg"),
	preload("res://UI/OutGameUI/tutorial/pages/turale part 2_page-0005.jpg"),
	preload("res://UI/OutGameUI/tutorial/pages/turale part 2_page-0006.jpg")
]

func _ready():
	
	update_page()

func open_tutorial():
	page = 0
	show()
	update_page()

func update_page():
	page_image.texture = pages[page]

	previous_button.disabled = page == 0

	if page == pages.size() - 1:
		next_button.text = "Finish"
	else:
		next_button.text = "Next"

func _on_next_button_pressed():
	
	if page == pages.size() - 1:
		get_tree().change_scene_to_file("res://UI/OutGameUI/Startscreen.tscn")
	else:
		page += 1
		update_page()

func _on_previous_button_pressed():
	if page > 0:
		page -= 1
		update_page()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://UI/OutGameUI/Startscreen.tscn")
