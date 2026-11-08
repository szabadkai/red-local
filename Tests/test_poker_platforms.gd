extends SceneTree
var failures := 0
var scene: Node

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func travel(target_x: float, jump: bool = false) -> void:
	if jump:
		scene.jump_buffer = 0.12
		scene.try_jump()
	for i in range(180):
		var distance: float = target_x - scene.player.x
		scene.velocity.x = clampf(distance * 60, -195, 195)
		scene.move_player(1.0 / 60)
		scene.update_animation(1.0 / 60)
		if absf(distance) < 1 and scene.grounded:
			return
	check(false, "Route failed to land at %s" % target_x)

func run() -> void:
	scene = load("res://Scenes/PokerPrototype.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_physics_process(false)
	scene.muted = true
	scene.enemies.clear()
	travel(105, true)
	check(scene.player.y == 270 and scene.collected == 1, "First ledge and ember reachable")
	travel(135)
	travel(225, true)
	check(scene.player.y == 218, "Second ledge reachable")
	travel(260)
	travel(350, true)
	check(scene.player.y == 166 and scene.collected == 2, "Upper ember reachable")
	travel(470, true)
	check(scene.player.y == 218, "Crossing to right ledge")
	travel(500)
	travel(580, true)
	check(scene.player.y == 166 and scene.collected == 3, "Third ember reachable")
	travel(601)
	check(scene.completed, "Entire authored route reaches lantern")
	scene.restart()
	scene.enemies.clear()
	scene.player = Vector2(105, 270)
	scene.velocity = Vector2.ZERO
	scene.grounded = true
	var event := InputEventKey.new()
	event.physical_keycode = KEY_S
	event.pressed = true
	scene._unhandled_key_input(event)
	for i in range(60):
		scene.move_player(1.0 / 60)
	check(scene.player.y == scene.FLOOR, "S drops through one-way platform")
	scene.player = Vector2(160, 270)
	scene.grounded = false
	scene.coyote = 0.08
	scene.jump_buffer = 0.1
	scene.try_jump()
	check(scene.velocity.y == -320, "Coyote jump")
	scene.coyote = 0
	scene.jump_buffer = 0.1
	scene.velocity.y = 100
	scene.try_jump()
	check(scene.velocity.y == 100, "No unlimited air jumps")
	scene.player = Vector2(105, 269)
	scene.move_player(1.0 / 60)
	check(scene.velocity.y == -320, "Buffered jump fires on landing")
	scene.enemies.clear()
	scene.spawn_enemy(230, 218, 187, 268)
	scene.spawn_enemy(230)
	scene.player = Vector2(200, 218)
	scene.sword_cd = 0
	var ground_hp: int = scene.enemies[1].hp
	var ledge_hp: int = scene.enemies[0].hp
	scene.sword_attack()
	check(scene.enemies[0].hp == ledge_hp - 2, "Sword hits ledge enemy")
	check(scene.enemies[1].hp == ground_hp, "Sword does not hit another floor")
	for form in ["Light", "Dark"]:
		for state in ["idle_blink", "run", "jump", "fall", "attack1", "attack3"]:
			check(scene.animations[form][state].size() > 1, "%s/%s has real animation frames" % [form, state])
	scene.practice_hand(1)
	check(scene.platforms.is_empty() and scene.practice and not scene.completed, "Practice remains flat sandbox")
	scene.queue_free()
	await process_frame
	print("Platform route, jumping, animation and elevated combat: %d failures" % failures)
	quit(1 if failures else 0)
