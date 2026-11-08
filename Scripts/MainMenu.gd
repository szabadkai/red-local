extends Control

func _ready():
	var prototype_button := Button.new()
	prototype_button.text = "Poker Combat Prototype"
	$VBoxContainer.add_child(prototype_button)
	$VBoxContainer.move_child(prototype_button, 3)
	prototype_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://Scenes/PokerPrototype.tscn"))
	# Connect button signals
	$VBoxContainer/StartButton.pressed.connect(_on_start_button_pressed)
	$VBoxContainer/ExitButton.pressed.connect(_on_exit_button_pressed)

func _on_start_button_pressed():
	print("Starting game...")
	# Change to the main game scene
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _on_exit_button_pressed():
	print("Exiting game...")
	# Quit the game
	get_tree().quit() 
