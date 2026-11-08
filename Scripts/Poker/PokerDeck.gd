extends RefCounted
const Hand = preload("res://Scripts/Poker/PokerHand.gd")
const HITS_PER_DRAW := 3
var hand: Array = []
var pile: Array = []
var discard: Array = []
var hits := 0
var banked := false

func reset() -> void:
	hand.clear()
	discard.clear()
	pile = range(52)
	pile.shuffle()
	hits = 0
	banked = false
	for i in range(5):
		draw_card()

func draw_card() -> void:
	if hand.size() >= 5:
		return
	if pile.is_empty():
		pile = discard.duplicate()
		discard.clear()
		pile.shuffle()
	if not pile.is_empty():
		hand.append(pile.pop_back())

func register_hit() -> bool:
	if banked:
		return false
	hits += 1
	if hits < HITS_PER_DRAW:
		return false
	hits = 0
	if hand.size() < 5:
		draw_card()
	else:
		banked = true
	return true

func play() -> Dictionary:
	var result: Dictionary = Hand.evaluate(hand)
	var indices: Array = result.indices.duplicate()
	indices.sort()
	indices.reverse()
	for index in indices:
		discard.append(hand[index])
		hand.remove_at(index)
	if banked and hand.size() < 5:
		banked = false
		draw_card()
	return result

func replace_card(index: int) -> bool:
	if not banked or index < 0 or index >= hand.size():
		return false
	discard.append(hand[index])
	hand.remove_at(index)
	banked = false
	draw_card()
	return true
