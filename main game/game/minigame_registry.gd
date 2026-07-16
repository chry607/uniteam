extends Node
## Catalog of real minigames (from new games + sfx package).
## Autoload so GameState and MinigameHost share one source of truth.

const ENTRIES: Array[Dictionary] = [
	{
		"id": "cut_wires",
		"display_name": "Cut the Jumper Wires!",
		"intro": "Don't cut the wrong wire!",
		"scene": "res://minigames/cut-the-jumper-wires/game_wire.tscn",
	},
	{
		"id": "crossy_edsa",
		"display_name": "Crossy the EDSA!",
		"intro": "Survive the crossing!",
		"scene": "res://minigames/crossy-road/Main.tscn",
	},
	{
		"id": "lrt_balance",
		"display_name": "LRT Balance!",
		"intro": "Stay balanced on the train!",
		"scene": "res://minigames/lrt-balance/game_LRTbalance.tscn",
	},
]

var _last_index: int = -1
## Per-minigame difficulty (matches Uniteam manager challenge_levels).
var _challenge_levels: Array[int] = []
## Shuffled playlist of remaining games in the current 3-game block (no immediate repeats).
var _challenge_bag: Array[int] = []


func _ready() -> void:
	_challenge_levels.resize(ENTRIES.size())
	_challenge_levels.fill(0)


func size() -> int:
	return ENTRIES.size()


func get_entry(index: int) -> Dictionary:
	return ENTRIES[index]


func get_entry_by_id(id: String) -> Dictionary:
	for e in ENTRIES:
		if str(e.get("id", "")) == id:
			return e
	return {}


func pick_next() -> Dictionary:
	if ENTRIES.is_empty():
		return {}

	# Dynamic playlist: refill bag with a shuffled [0..n) when empty.
	if _challenge_bag.is_empty():
		var new_bag: Array[int] = []
		for i in range(ENTRIES.size()):
			new_bag.append(i)
		new_bag.shuffle()

		# Transition safeguard: if the first game of a new block matches the last
		# game of the previous block, swap it with the second entry.
		if _last_index != -1 and new_bag.size() > 1 and new_bag[0] == _last_index:
			var temp := new_bag[0]
			new_bag[0] = new_bag[1]
			new_bag[1] = temp

		_challenge_bag = new_bag

	var index: int = _challenge_bag.pop_front()
	_last_index = index
	var entry := ENTRIES[index].duplicate()
	entry["index"] = index
	entry["difficulty"] = get_difficulty_for_index(index)
	return entry


func get_difficulty_for_index(index: int) -> int:
	if index < 0 or index >= _challenge_levels.size():
		return 0
	return _challenge_levels[index]


func get_difficulty_for_entry(entry: Dictionary) -> int:
	var index := int(entry.get("index", -1))
	if index < 0:
		var id := str(entry.get("id", ""))
		for i in ENTRIES.size():
			if str(ENTRIES[i].get("id", "")) == id:
				index = i
				break
	return get_difficulty_for_index(index)


## Call after a minigame finishes successfully so the next play of that game is harder.
func advance_difficulty_for_entry(entry: Dictionary) -> void:
	var index := int(entry.get("index", -1))
	if index < 0:
		var id := str(entry.get("id", ""))
		for i in ENTRIES.size():
			if str(ENTRIES[i].get("id", "")) == id:
				index = i
				break
	if index < 0 or index >= _challenge_levels.size():
		return
	# Infinite scaling to match wire minigame set_difficulty clamp (0..100)
	_challenge_levels[index] = mini(_challenge_levels[index] + 1, 100)


func reset_difficulties() -> void:
	for i in _challenge_levels.size():
		_challenge_levels[i] = 0
	_challenge_bag.clear()
	_last_index = -1


func load_scene(entry: Dictionary) -> PackedScene:
	var path := str(entry.get("scene", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		push_error("MinigameRegistry: missing scene %s" % path)
		return null
	return load(path) as PackedScene
