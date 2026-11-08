extends SceneTree
const Hand = preload("res://Scripts/Poker/PokerHand.gd")
const Deck = preload("res://Scripts/Poker/PokerDeck.gd")
var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		failures += 1

func _init() -> void:
	# Mixed suits unless testing flushes. Ace is rank 14.
	var cases := [
		[[12, 14, 29, 44, 8], 0, 1],
		[[5, 18, 29, 45, 8], 1, 2],
		[[5, 18, 8, 21, 40], 2, 4],
		[[5, 18, 31, 45, 8], 3, 3],
		[[0, 14, 28, 42, 4], 4, 5],
		[[0, 2, 5, 8, 11], 5, 5],
		[[5, 18, 31, 8, 21], 6, 5],
		[[5, 18, 31, 44, 8], 7, 4],
		[[0, 1, 2, 3, 4], 8, 5],
		[[12, 13, 27, 41, 3], 4, 5],
	]
	for c in cases:
		var result := Hand.evaluate(c[0])
		check(result.tier == c[1], "Wrong category: %s got %s" % [str(c[0]), result.name])
		check(result.indices.size() == c[2], "Wrong number of consumed cards")
	check(Hand.evaluate([]).damage == 0, "Empty hand must do zero damage")
	check(Hand.evaluate([1, 14]).tier == 1, "Partial hand pair")
	check(Hand.evaluate([11, 12, 13, 14, 15]).tier != 4, "No wrapping straights")
	var deck = Deck.new()
	deck.reset()
	check(deck.hand.size() == 5 and deck.pile.size() == 47, "Initial deal")
	deck.register_hit()
	deck.register_hit()
	check(not deck.banked, "No early draw")
	deck.register_hit()
	check(deck.banked and deck.hits == 0, "Full hand banks one draw")
	for i in range(9):
		deck.register_hit()
	check(deck.hits == 0, "Bank must cap draw credit")
	check(not deck.replace_card(-1) and deck.banked, "Invalid swap preserves bank")
	check(deck.replace_card(0) and not deck.banked and deck.hand.size() == 5, "Swap consumes bank")
	deck.hand = [5, 18, 2, 9, 24]
	deck.pile = [0, 1, 3, 4]
	deck.discard = []
	var result: Dictionary = deck.play()
	check(result.tier == 1 and deck.hand == [2, 9, 24], "Pair preserves unused cards")
	check(deck.discard.size() == 2, "Played cards discarded")
	for i in range(3):
		deck.register_hit()
	check(deck.hand.size() == 4, "Three hits fill one empty slot")
	deck.reset()
	for cycle in range(200):
		deck.play()
		for hit in range(15):
			deck.register_hit()
		var all_cards: Array = deck.hand + deck.pile + deck.discard
		var unique := {}
		for card in all_cards:
			unique[card] = true
		check(all_cards.size() == 52 and unique.size() == 52, "Card conservation through reshuffles")
		check(deck.hand.size() <= 5, "Hand cap")
	print("Poker rules and deck lifecycle: %d failures" % failures)
	quit(1 if failures else 0)
