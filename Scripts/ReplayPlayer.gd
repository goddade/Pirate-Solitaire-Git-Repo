extends Node
class_name ReplayPlayer

var _moves: Array = []
var _index: int = 0
var _move_interval: float = 1 # seconds per move
var _playing: bool = false
var _discarding: bool = false

func load_replay(game_seed: int) -> bool:
	var fname = Recorder.fname_base % game_seed

	if not FileAccess.file_exists(fname):
		push_error("Replay file not found: %s" % fname)
		return false

	var f = FileAccess.open(fname, FileAccess.READ)
	if f == null:
		push_error("Cannot open replay file: %s" % fname)
		return false

	var result = JSON.parse_string(f.get_as_text())
	f.close()

	_moves = result
	_index = 0
	_playing = false
	_discarding = false
	return true

func play_replay() -> void:
	if _moves.size() == 0:
		push_warning("No moves to play")
		return
	_playing = true
	Recorder.disable()
	#TODO: disable user input
	await get_tree().create_timer(3).timeout
	_play_next_move()

func _play_next_move() -> void:
	if _index >= _moves.size() - 1:
		_playing = false
		print("No more moves")
		return

	_index += 1
	var move = _moves[_index]

	_discarding = true
	_execute_move(move)
	while _discarding:
		await get_tree().process_frame
	if _playing:
		_play_next_move()

func _execute_move(move: Dictionary) -> void:
	print("Executing move:", move)
	var act = move.get("act", -1) as Recorder.Action
	match act:
		Recorder.Action.GAME_START:
			pass
		Recorder.Action.GAME_WIN:
			_playing = false
			print("Replay finished")
		Recorder.Action.DISCARD_BEAST:
			_discard_beast(move)
		Recorder.Action.MOVE_TO_STACK:
			_move_to_stack(move)
		Recorder.Action.MOVE_TO_TRAIL:
			_move_to_trail(move)
		Recorder.Action.DOUBLE_CLICK, Recorder.Action.MOVE_TO_COLOR:
			_move_to_color(move)
		Recorder.Action.MOVE_TO_GARBAGE:
			pass
		_:
			print("Unknown move action:", move)

func _get_position_from_index(idx: int, size: int) -> Vector2:
	if idx < CardManager._card_stacks.size():
		var stack = CardManager._card_stacks[idx]
		if stack.size() < size:
			var slot = CardManager._stack_slots[idx] as Slot
			return slot.position
		var card = stack[stack.size() - size] as Card
		return card.position - Vector2(0, 8) # -8 for wired bug.
	else:
		var trail_idx = idx - CardManager._card_stacks.size()
		var slot = CardManager._trail_slots[trail_idx] as Slot
		return slot.position


func _click_beast_button(b_name: String) -> void:
	for b in CardManager._beasts_button_group.get_buttons():
		if b.name == b_name:
			b.button_pressed=true

func _touch_at_position(pos: Vector2, idx: int, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.position = pos
	ev.pressed = pressed
	ev.index = idx
	CardManager._unhandled_input(ev)

func _double_click_at_position(pos: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.position = pos
	ev.double_click= true
	CardManager._unhandled_input(ev)

func _discard_beast(move: Dictionary) -> void:
	var idx = move.get("i", 0)
	var b_name = move.get("b", "")
	var p1_idx = move.get("p1", -1)
	var p2_idx = move.get("p2", -1)

	_click_beast_button(b_name)

	if CardManager._pirates_index.size() > 2:
		var p1_pos = _get_position_from_index(p1_idx, 1)
		_touch_at_position(p1_pos,idx , true)
		var p2_pos = _get_position_from_index(p2_idx, 1)
		_touch_at_position(p2_pos,idx , true)

	await get_tree().create_timer(_move_interval).timeout


func _move_to_stack(move: Dictionary) -> void:
	var idx = move.get("i", 0)
	var from_idx = move.get("f", -1)
	var to_idx = move.get("t", -1)
	var stack_size = move.get("s", 0)
	var f_pos = _get_position_from_index(from_idx, stack_size)
	var t_pos = _get_position_from_index(to_idx, 1)
	_touch_at_position(f_pos, idx, true)
	await get_tree().create_timer(_move_interval).timeout
	_touch_at_position(t_pos, idx, false)

func _move_to_trail(move: Dictionary) -> void:
	var idx = move.get("i", 0)
	var from_idx = move.get("f", -1)
	var to_idx = move.get("t", -1)
	var f_pos = _get_position_from_index(from_idx, 1)
	var t_pos = _get_position_from_index(to_idx, 1)
	_touch_at_position(f_pos, idx, true)
	await get_tree().create_timer(_move_interval).timeout
	_touch_at_position(t_pos, idx, false)

func _move_to_color(move: Dictionary) -> void:
	var from_idx = move.get("f", -1)
	var pos = _get_position_from_index(from_idx, 1)
	_double_click_at_position(pos)
	await get_tree().create_timer(_move_interval).timeout
