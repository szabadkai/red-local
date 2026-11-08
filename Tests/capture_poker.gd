extends SceneTree
## Deterministic visual smoke capture. Run with a display, optionally --write-movie.
var scene: Node
var tick := 0

func _initialize() -> void:
	seed(27)
	call_deferred("start")

func start() -> void:
	scene = load("res://Scenes/PokerPrototype.tscn").instantiate()
	root.add_child(scene)
	scene.deck.hand = [5, 18, 2, 9, 24]
	scene.deck.pile.clear()
	for card in range(52):
		if not scene.deck.hand.has(card):
			scene.deck.pile.append(card)
	scene.deck.discard.clear()
	scene.sync_cards()
	scene.enemies[0].x = scene.player.x + 55

	await create_timer(1.0).timeout
	for i in range(3):
		scene.enemies[0].x = scene.player.x + 35
		scene.sword_attack()
		await create_timer(0.5).timeout
	scene.poker_attack()
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/card-concept/poker-prototype.png")
	await create_timer(2.0).timeout
	quit()
