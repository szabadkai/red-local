extends SceneTree
## Scripted traversal capture with enemies removed to isolate the jump route.
var scene: Node

func _initialize() -> void:
	seed(27)
	call_deferred("run")

func travel(target_x: float, jump: bool = false) -> void:
	if jump:
		scene.jump_buffer = 0.12
		scene.try_jump()
	for i in range(180):
		await physics_frame
		var delta := 1.0 / 60
		var distance: float = target_x - scene.player.x
		scene.velocity.x = clampf(distance * 60, -195, 195)
		if scene.velocity.x != 0:
			scene.facing = signf(scene.velocity.x)
		scene.elapsed += delta
		scene.land_time = maxf(0, scene.land_time - delta)
		scene.move_player(delta)
		scene.update_animation(delta)
		scene.queue_redraw()
		if absf(distance) < 1 and scene.grounded:
			return

func run() -> void:
	scene = load("res://Scenes/PokerPrototype.tscn").instantiate()
	root.add_child(scene)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/card-concept/platform-clearing.png")
	scene.set_physics_process(false)
	scene.enemies.clear()
	await travel(105, true)
	await travel(135)
	await travel(225, true)
	await travel(260)
	await travel(350, true)
	await travel(470, true)
	await travel(500)
	await travel(580, true)
	await travel(601)
	await create_timer(0.8).timeout
	quit()
