class_name GameState
extends RefCounted

## Authoritative Living Town simulation. The engine owns this data.
## LLM cognition is not used here. Deterministic rules apply changes.

const SAVE_VERSION := 1
const SAVE_PATH := "user://living_town_v1.json"

var player_name := ""
var player_location := "square"
var player_inventory: PackedStringArray = PackedStringArray()
var day := 1
var hour := 8
var next_event_id := 1
var events: Array[Dictionary] = []
var npcs: Dictionary = {}
var flags: Dictionary = {}


func create_character(p_name: String) -> void:
	player_name = p_name.strip_edges()
	if player_name.is_empty():
		player_name = "Traveler"
	player_location = "square"
	player_inventory = PackedStringArray()
	day = 1
	hour = 8
	next_event_id = 1
	events.clear()
	flags = {
		"returned_doll": false,
		"doll_sold": false,
		"inn_gift_ready": false,
	}
	npcs = {
		"elara": _make_npc(
			"elara",
			"Elara",
			"innkeeper",
			"inn",
			["find_mira_doll"],
			{"morning": "inn", "afternoon": "inn", "evening": "inn", "night": "inn"}
		),
		"tomas": _make_npc(
			"tomas",
			"Tomas",
			"merchant",
			"shop",
			["turn_a_profit"],
			{"morning": "shop", "afternoon": "shop", "evening": "inn", "night": "shop"}
		),
		"brann": _make_npc(
			"brann",
			"Brann",
			"guard",
			"gate",
			["keep_the_gate"],
			{"morning": "gate", "afternoon": "gate", "evening": "square", "night": "gate"}
		),
	}
	npcs["tomas"]["inventory"] = ["mira_doll"]
	_apply_schedules()
	_record("character_created", "player", "", "square", {"name": player_name})


func time_label() -> String:
	return "Day %d, %02d:00" % [day, hour]


func period() -> String:
	if hour >= 6 and hour < 12:
		return "morning"
	if hour >= 12 and hour < 17:
		return "afternoon"
	if hour >= 17 and hour < 21:
		return "evening"
	return "night"


func npc_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for id in npcs.keys():
		ids.append(str(id))
	ids.sort()
	return ids


func talk(npc_id: String) -> Dictionary:
	var npc := _npc(npc_id)
	if npc.is_empty():
		return {"text": "No one there.", "options": []}
	_record("talk", "player", npc_id, str(npc.get("location", "")), {})
	return {"text": _dialogue_text(npc_id), "options": _dialogue_options(npc_id)}


func choose(npc_id: String, option_id: String) -> Dictionary:
	match option_id:
		"take_doll":
			_take_doll(npc_id)
		"return_doll":
			_return_doll(npc_id)
		"ask_mira":
			_remember(npc_id, "Told %s that Mira lost her doll." % player_name)
		"ask_town":
			_remember(npc_id, "Asked %s about the town." % player_name)
		_:
			pass
	return talk(npc_id)


func leave_town() -> void:
	_record("player_left", "player", "", player_location, {"hours": 24})
	player_location = "away"
	for _i in 24:
		_tick_hour()
	player_location = "gate"
	_record("player_returned", "player", "", "gate", {"day": day, "hour": hour})
	_apply_schedules()


func save_to_path(path: String = SAVE_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write save: %s" % path)
		return false
	file.store_string(JSON.stringify(to_dict(), "\t"))
	return true


func load_from_path(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Save is not a dictionary: %s" % path)
		return false
	return from_dict(parsed)


static func save_exists(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)


func to_dict() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"player_name": player_name,
		"player_location": player_location,
		"player_inventory": Array(player_inventory),
		"day": day,
		"hour": hour,
		"next_event_id": next_event_id,
		"events": events.duplicate(true),
		"npcs": npcs.duplicate(true),
		"flags": flags.duplicate(true),
	}


func from_dict(data: Dictionary) -> bool:
	var version := int(data.get("save_version", 0))
	if version != SAVE_VERSION:
		push_error("Unsupported save version %s" % version)
		return false
	player_name = str(data.get("player_name", "Traveler"))
	player_location = str(data.get("player_location", "square"))
	player_inventory = PackedStringArray(data.get("player_inventory", []))
	day = int(data.get("day", 1))
	hour = int(data.get("hour", 8))
	next_event_id = int(data.get("next_event_id", 1))
	events.clear()
	for item in data.get("events", []):
		if item is Dictionary:
			events.append(item)
	npcs = data.get("npcs", {})
	flags = data.get("flags", {})
	return true


func debug_npc(npc_id: String) -> String:
	var npc := _npc(npc_id)
	if npc.is_empty():
		return "Unknown NPC"
	var lines: PackedStringArray = PackedStringArray()
	lines.append("NPC: %s" % npc["name"])
	lines.append("OCCUPATION %s" % npc["occupation"])
	lines.append("LOCATION %s" % npc["location"])
	lines.append("GOALS %s" % ", ".join(PackedStringArray(npc["goals"])))
	lines.append("RELATIONSHIPS player: %+0.2f" % float(npc["relationships"].get("player", 0.0)))
	lines.append("INVENTORY %s" % ", ".join(PackedStringArray(npc["inventory"])))
	lines.append("RECENT MEMORIES")
	var memories: Array = npc["memories"]
	var start := maxi(0, memories.size() - 4)
	if memories.is_empty():
		lines.append("  (none)")
	else:
		for i in range(start, memories.size()):
			lines.append("  - %s" % str(memories[i]))
	return "\n".join(lines)


func _make_npc(
	id: String,
	p_name: String,
	occupation: String,
	location: String,
	goals: Array,
	schedule: Dictionary
) -> Dictionary:
	return {
		"id": id,
		"name": p_name,
		"occupation": occupation,
		"location": location,
		"personality": {"warmth": 0.5, "caution": 0.5},
		"goals": goals.duplicate(),
		"beliefs": [],
		"memories": [],
		"relationships": {"player": 0.05},
		"knowledge": [],
		"inventory": [],
		"schedule": schedule.duplicate(),
	}


func _npc(npc_id: String) -> Dictionary:
	if not npcs.has(npc_id):
		return {}
	return npcs[npc_id]


func _set_rel(npc_id: String, delta: float) -> void:
	var npc := _npc(npc_id)
	if npc.is_empty():
		return
	var rels: Dictionary = npc["relationships"]
	rels["player"] = clampf(float(rels.get("player", 0.0)) + delta, -1.0, 1.0)


func _remember(npc_id: String, text: String) -> void:
	var npc := _npc(npc_id)
	if npc.is_empty():
		return
	var memories: Array = npc["memories"]
	memories.append("Day %d %02d:00 — %s" % [day, hour, text])


func _has_item(who: String, item: String) -> bool:
	if who == "player":
		return player_inventory.has(item)
	var npc := _npc(who)
	if npc.is_empty():
		return false
	return PackedStringArray(npc["inventory"]).has(item)


func _remove_item(who: String, item: String) -> void:
	if who == "player":
		var next := PackedStringArray()
		for existing in player_inventory:
			if existing != item:
				next.append(existing)
		player_inventory = next
		return
	var npc := _npc(who)
	if npc.is_empty():
		return
	var next_inv: Array = []
	for existing in npc["inventory"]:
		if str(existing) != item:
			next_inv.append(existing)
	npc["inventory"] = next_inv


func _add_item(who: String, item: String) -> void:
	if who == "player":
		if not player_inventory.has(item):
			player_inventory.append(item)
		return
	var npc := _npc(who)
	if npc.is_empty():
		return
	var inv: Array = npc["inventory"]
	if not inv.has(item):
		inv.append(item)


func _take_doll(npc_id: String) -> void:
	if npc_id != "tomas" or not _has_item("tomas", "mira_doll"):
		return
	_remove_item("tomas", "mira_doll")
	_add_item("player", "mira_doll")
	_set_rel("tomas", -0.05)
	_remember("tomas", "%s took Mira's doll from the stall." % player_name)
	_record("item_taken", "player", "tomas", "shop", {"item": "mira_doll"})


func _return_doll(npc_id: String) -> void:
	if npc_id != "elara" or not _has_item("player", "mira_doll"):
		return
	_remove_item("player", "mira_doll")
	_add_item("elara", "mira_doll")
	flags["returned_doll"] = true
	_set_rel("elara", 0.35)
	_remember("elara", "%s brought Mira's doll home." % player_name)
	var npc := _npc("elara")
	var next_goals: Array = []
	for goal in npc["goals"]:
		if str(goal) != "find_mira_doll":
			next_goals.append(goal)
	next_goals.append("repay_kindness")
	npc["goals"] = next_goals
	_record("npc_helped", "player", "elara", "inn", {"item": "mira_doll"})


func _dialogue_text(npc_id: String) -> String:
	match npc_id:
		"elara":
			if flags.get("inn_gift_ready", false):
				return "Elara smiles. 'You came back. I kept breakfast warm. Mira slept with her doll.'"
			if flags.get("returned_doll", false):
				return "Elara squeezes your hand. 'Mira has her doll. The inn feels whole again.'"
			if flags.get("doll_sold", false):
				return "Elara's eyes are tired. 'Someone told me Tomas sold a child's toy to a traveler. Mira cried until dawn.'"
			if _has_item("player", "mira_doll"):
				return "Elara looks at the doll in your hands and forgets to breathe. 'That's Mira's.'"
			return "Elara wipes a mug. 'Mira lost her doll near the stall. If you see Tomas, ask. I can't leave the inn.'"
		"tomas":
			if _has_item("tomas", "mira_doll"):
				return "Tomas taps a crate. 'Found a doll under the stall. Cute. It'll sell if nobody claims it.'"
			if flags.get("doll_sold", false):
				return "Tomas shrugs. 'The doll? Sold it yesterday. Business is business.'"
			if _has_item("player", "mira_doll"):
				return "Tomas eyes the doll. 'You took it. Fine. I wasn't going to get much anyway.'"
			return "Tomas counts coins. 'If you're buying, say so. If not, don't block the stall.'"
		"brann":
			if flags.get("returned_doll", false):
				return "Brann nods at you. 'Elara's in better spirits. Town notices that.'"
			if flags.get("doll_sold", false):
				return "Brann watches the road. 'Heard crying from the inn last night. Not my post. Still heard it.'"
			return "Brann stands at the gate. 'Welcome to Millbrook. Gate's that way when you want a day on the road.'"
		_:
			return "..."


func _dialogue_options(npc_id: String) -> Array:
	var options: Array = [{"id": "leave", "label": "That's all for now."}]
	match npc_id:
		"elara":
			if not flags.get("returned_doll", false) and not flags.get("doll_sold", false):
				options.push_front({"id": "ask_mira", "label": "Tell me about Mira's doll."})
			if _has_item("player", "mira_doll"):
				options.push_front({"id": "return_doll", "label": "This is Mira's. Take it."})
		"tomas":
			if _has_item("tomas", "mira_doll"):
				options.push_front({"id": "take_doll", "label": "That's a child's doll. I'm taking it to Elara."})
		"brann":
			options.push_front({"id": "ask_town", "label": "Anything I should know?"})
	return options


func _tick_hour() -> void:
	hour += 1
	if hour >= 24:
		hour = 0
		day += 1
	_apply_schedules()
	if hour == 6 and _has_item("tomas", "mira_doll") and not flags.get("returned_doll", false):
		_remove_item("tomas", "mira_doll")
		flags["doll_sold"] = true
		_set_rel("elara", -0.2)
		_remember("elara", "A rumor: Tomas sold a child's toy while the traveler was away.")
		_remember("tomas", "Sold the unclaimed doll at dawn.")
		_record("item_sold", "tomas", "elara", "shop", {"item": "mira_doll"})
	if hour == 7 and flags.get("returned_doll", false):
		flags["inn_gift_ready"] = true
		_remember("elara", "Set aside breakfast for %s." % player_name)


func _apply_schedules() -> void:
	var slot := period()
	for id in npcs.keys():
		var npc: Dictionary = npcs[id]
		var schedule: Dictionary = npc["schedule"]
		npc["location"] = str(schedule.get(slot, npc["location"]))


func _record(type: String, actor: String, target: String, location: String, metadata: Dictionary) -> void:
	var event := {
		"eventId": "event_%d" % next_event_id,
		"type": type,
		"timestamp": day * 24 + hour,
		"day": day,
		"hour": hour,
		"actor": actor,
		"target": target,
		"location": location,
		"metadata": metadata,
	}
	next_event_id += 1
	events.append(event)
