extends SceneTree
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://Scenes/PokerPrototype.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_physics_process(false)
	scene.muted = true
	scene.next_enemy_id = 0
	scene.enemies.clear()
	scene.spawn_enemy(scene.player.x + 35)
	scene.sword_attack()
	check(scene.enemies[0].hp == 12 and scene.deck.hits == 1, "Sword damage earns credit")
	scene.sword_attack()
	check(scene.deck.hits == 1, "Cooldown prevents repeated hit credit")
	for i in range(2):
		scene.sword_cd = 0
		scene.enemies[0].x = scene.player.x + 35
		scene.sword_attack()
	check(scene.deck.banked, "Three landed swings bank a draw")
	scene.deck.banked = false
	scene.deck.hand = [5, 18, 2, 9, 24]
	scene.sync_cards()
	scene.enemies[0].x = scene.player.x + 60
	scene.enemies[0].hp = 30
	scene.poker_attack()
	check(scene.deck.hand.size() == 3, "Poker pair spends two cards")
	for i in range(10):
		scene._physics_process(1.0 / 60.0)
	check(scene.enemies[0].hp == 16, "Poker bolt applies pair damage")
	check(scene.deck.hits == 0, "Poker cannot earn its own replacement draws")
	scene.player.y = scene.FLOOR
	scene.enemies[0].x = scene.player.x + 15
	scene.enemies[0].stun = 0
	scene.enemies[0].attack = 0.01
	var before: Array = scene.deck.hand.duplicate()
	scene._physics_process(0.02)
	check(scene.health == 4 and scene.deck.hand == before, "Enemy hits cost health, preserve cards")
	scene.paused = true
	var position: Vector2 = scene.player
	scene._physics_process(1.0)
	check(scene.player == position, "Pause freezes world")
	scene.restart()
	check(scene.health == 5 and scene.deck.hand.size() == 5 and scene.kills == 0, "Restart clears combat state")
	var original_size: Vector2i = scene.previous_size
	scene.queue_free()
	await process_frame
	check(root.content_scale_size == original_size, "Leaving restores original viewport")
	var menu = load("res://Scenes/MainMenu.tscn").instantiate()
	root.add_child(menu)
	await process_frame
	var found := false
	for child in menu.get_node("VBoxContainer").get_children():
		if child is Button and child.text == "Poker Combat Prototype":
			found = true
	check(found, "Main menu exposes prototype entry")
	menu.queue_free()
	await process_frame
	print("Poker combat integration: %d failures" % failures)
	quit(1 if failures else 0)
