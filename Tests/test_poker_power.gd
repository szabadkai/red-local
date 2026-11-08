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
	check(not scene.transform_frames.is_empty() and not scene.fx_frames.is_empty(), "Transformation assets loaded")
	scene.practice_hand(1)
	check(scene.Hand.evaluate(scene.deck.hand).tier == 5, "F2 deals a flush")
	var all_cards: Array = scene.deck.hand + scene.deck.pile + scene.deck.discard
	var unique := {}
	for card in all_cards:
		unique[card] = true
	check(all_cards.size() == 52 and unique.size() == 52, "Practice preserves unique deck")
	for enemy in scene.enemies:
		enemy.hp = 200
	scene.poker_attack()
	check(scene.dark_time == 6 and scene.transform_time == 0.75, "Flush transforms immediately")
	check(scene.deck.hand.is_empty(), "Flush consumes five cards")
	for i in range(40):
		scene._physics_process(1.0 / 60)
	for enemy in scene.enemies:
		check(enemy.hp == 160, "Flush pierces each enemy exactly once")
	check(scene.deck.hits == 0, "Wave does not earn draws")
	check(scene.dark_time > 5, "Dark mode persists beyond cast")
	scene.enemies.clear()
	scene.spawn_enemy(scene.player.x + 35)
	scene.enemies[0].hp = 100
	scene.sword_cd = 0
	scene.sword_attack()
	check(scene.enemies[0].hp == 96 and scene.deck.hits == 1, "Dark sword doubles damage and earns credit")
	scene.dark_time = 0.01
	scene._physics_process(0.02)
	check(scene.dark_time == 0, "Dark mode expires")
	scene.practice_hand(2)
	scene.enemies.clear()
	scene.spawn_enemy(scene.player.x - 80)
	scene.spawn_enemy(scene.player.x + 80)
	scene.spawn_enemy(600)
	for enemy in scene.enemies:
		enemy.hp = 100
	scene.poker_attack()
	check(scene.enemies[0].hp == 36 and scene.enemies[1].hp == 36, "Four of a kind bursts both directions")
	check(scene.enemies[2].hp == 100, "Burst respects radius")
	check(scene.deck.hand.size() == 1 and scene.dark_time == 6, "Four of a kind preserves kicker and transforms")
	scene.restart()
	check(scene.dark_time == 0 and scene.transform_time == 0 and scene.rings.is_empty(), "Restart clears powers")
	scene.player = Vector2(180, scene.FLOOR)
	scene.deck.hand = [5, 18, 8, 21, 0]
	scene.enemies.clear()
	for x in [240, 290, 580]:
		scene.spawn_enemy(x)
	for enemy in scene.enemies:
		enemy.hp = 100
	scene.poker_attack()
	for i in range(12):
		scene._physics_process(1.0 / 60)
	check(scene.enemies[0].hp == 80 and scene.enemies[1].hp == 80, "Two pair explodes across nearby enemies")
	check(scene.enemies[2].hp == 100, "Explosion does not hit distant enemy")
	check(scene.dark_time == 0, "Common hands do not transform")
	scene.restart()
	scene.deck.hand = [5, 18, 31, 8, 21]
	scene.enemies.clear()
	for x in [scene.player.x - 60, scene.player.x + 60]:
		scene.spawn_enemy(x)
	for enemy in scene.enemies:
		enemy.hp = 100
	scene.poker_attack()
	check(scene.bolts.size() == 2, "Full house fires in both directions")
	for i in range(20):
		scene._physics_process(1.0 / 60)
	check(scene.enemies[0].hp == 48 and scene.enemies[1].hp == 48, "Both full-house waves connect once")
	scene.practice_hand(0)
	scene.enemies.clear()
	scene.spawn_enemy(scene.player.x + 100)
	scene.enemies[0].hp = 100
	scene.poker_attack()
	scene._physics_process(0.3)
	check(scene.enemies[0].hp == 86, "Swept collision catches a target during a long frame")
	scene.queue_free()
	await process_frame
	print("Poker powers and transformation: %d failures" % failures)
	quit(1 if failures else 0)
