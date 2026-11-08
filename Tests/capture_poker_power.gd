extends SceneTree
## Scripted capture of a flush transformation followed by a four-of-a-kind burst.
func _initialize() -> void:
	seed(27)
	call_deferred("run")

func run() -> void:
	var scene = load("res://Scenes/PokerPrototype.tscn").instantiate()
	root.add_child(scene)
	scene.practice_hand(1)
	await create_timer(0.8).timeout
	scene.poker_attack()
	await create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/card-concept/poker-transform.png")
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/card-concept/poker-dark.png")
	await create_timer(1.0).timeout
	scene.practice_hand(2)
	await create_timer(0.8).timeout
	scene.poker_attack()
	await create_timer(2.0).timeout
	quit()
