extends RefCounted
## Cards are unique IDs: rank 2..Ace = id % 13 + 2, suit = id / 13.
const NAMES = ["High card", "Pair", "Two pair", "Three of a kind", "Straight", "Flush",
	"Full house", "Four of a kind", "Straight flush"]
const DAMAGE = [6, 14, 20, 26, 32, 40, 52, 64, 90]

static func evaluate(cards: Array) -> Dictionary:
	if cards.is_empty():
		return {"name": "Empty hand", "tier": -1, "damage": 0, "indices": []}
	var groups: Dictionary = {}
	for i in range(cards.size()):
		var rank: int = cards[i] % 13 + 2
		if not groups.has(rank):
			groups[rank] = []
		groups[rank].append(i)
	var ranks: Array = groups.keys()
	ranks.sort_custom(func(a, b):
		if groups[a].size() != groups[b].size():
			return groups[a].size() > groups[b].size()
		return a > b)
	var tier := 0
	var used: Array = [groups[ranks[0]][0]]
	var flush := cards.size() == 5
	for card in cards:
		if int(card / 13) != int(cards[0] / 13):
			flush = false
	var ordered: Array = groups.keys()
	ordered.sort()
	var straight: bool = ordered.size() == 5 and (ordered[4] - ordered[0] == 4 or ordered == [2, 3, 4, 5, 14])
	if straight and flush:
		tier = 8
	elif groups[ranks[0]].size() == 4:
		tier = 7
		used = groups[ranks[0]].duplicate()
	elif ranks.size() == 2 and groups[ranks[0]].size() == 3 and groups[ranks[1]].size() == 2:
		tier = 6
	elif flush:
		tier = 5
	elif straight:
		tier = 4
	elif groups[ranks[0]].size() == 3:
		tier = 3
		used = groups[ranks[0]].duplicate()
	elif groups[ranks[0]].size() == 2:
		tier = 1
		used = groups[ranks[0]].duplicate()
		if ranks.size() > 1 and groups[ranks[1]].size() == 2:
			tier = 2
			used.append_array(groups[ranks[1]])
	if tier in [4, 5, 6, 8]:
		used = range(cards.size())
	return {"name": NAMES[tier], "tier": tier, "damage": DAMAGE[tier], "indices": used}
