extends Node2D

@onready var page_image: TextureRect = $PageImage
@onready var next_button: Button = $NextButton
@onready var previous_button: Button = $PreviousButton
var page := 0

var page_paths := [
	"res://UI/OutGameUI/tutorial/guide martch/match_page-0001.jpg",
	"res://UI/OutGameUI/tutorial/guide martch/match_page-0002.jpg",
	"res://UI/OutGameUI/tutorial/guide martch/match_page-0003.jpg",
	"res://UI/OutGameUI/tutorial/guide martch/match_page-0004.jpg",
	"res://UI/OutGameUI/tutorial/guide martch/match_page-0005.jpg",
	"res://UI/OutGameUI/tutorial/guide martch/match_page-0006.jpg",
	"res://UI/OutGameUI/tutorial/guide martch/martch_page-0007.jpg",
	"res://UI/OutGameUI/tutorial/guide martch/march_page-0008.jpg",
	"res://UI/OutGameUI/tutorial/guide martch/martch_page-0009.jpg",
	"res://UI/OutGameUI/tutorial/guide martch/martch_page-0010.jpg",
	"res://UI/OutGameUI/tutorial/guide martch/martch_page-0011.jpg",
	"res://UI/OutGameUI/tutorial/guide martch/martch_page-0012.jpg",
	"res://UI/OutGameUI/tutorial/guide martch/page 13.jpg",
	"res://UI/OutGameUI/tutorial/guide martch/march_page-0014.jpg",
	"res://UI/OutGameUI/tutorial/guide martch/march_page-0015.jpg",
	"res://UI/OutGameUI/tutorial/guide martch/march_page-0016.jpg",
	"res://UI/OutGameUI/tutorial/guide martch/march_page-0017.jpg"
]

var pages: Array[Texture2D] = []

func _ready():
	pages.resize(page_paths.size())

	for i in range(min(3, page_paths.size())):
		pages[i] = load(page_paths[i])

	update_page()

func open_tutorial():
	page = 0
	show()
	update_page()

func ensure_page_loaded(index: int):
	if pages[index] == null:
		pages[index] = load(page_paths[index])
		

func update_page():
	ensure_page_loaded(page)
	page_image.texture = pages[page]

	if page + 1 < page_paths.size():
		ensure_page_loaded(page + 1)

	previous_button.disabled = page == 0

	if page == page_paths.size() - 1:
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
	elif event.is_action_pressed("ui_right"):
		_on_next_button_pressed()
	elif event.is_action_pressed("ui_left"):
		_on_previous_button_pressed()
