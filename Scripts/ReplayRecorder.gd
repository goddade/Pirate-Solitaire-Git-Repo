extends Node
class_name ReplayRecorder

var _game_seed: int = 0
var _move_idx: int = 0
var _moves: Array = []

enum Action {
	GAME_START,
	GAME_WIN,
	DISCARD_BEAST,
	DOUBLE_CLICK,
	MOVE_TO_STACK,
	MOVE_TO_TRAIL,
	MOVE_TO_COLOR,
	MOVE_TO_GARBAGE
}

func _init():
	_moves = []
	_game_seed = 0
	_move_idx = 0

func start(game_seed: int) -> void:
	"""
	Initialize recorder for a new game.
	"""
	_init()
	_game_seed = game_seed
	record_move_dic({
		"act": Action.GAME_START,
		"seed": _game_seed,
		"time_utc": Time.get_unix_time_from_system(),
		"time": Time.get_ticks_msec()
	})

func record_move_dic(move: Dictionary) -> void:
	"""
	Append a move dictionary.
	"""
	move["i"] = _move_idx
	_move_idx += 1
	move["time"] = Time.get_ticks_msec()

	print("Replay record:", str(move))
	_moves.append(move)
	
func record_move(act: int, from_idx: int, to_idx: int, stack_size: int) -> void:
	"""
	Append a move record.
	"""
	var move = {"act": act, "f": from_idx, "t": to_idx, "s": stack_size}
	record_move_dic(move)

func record_beast_move(beast_idx: int, pirate1_idx: int, pirate2_idx: int) -> void:
	"""
	Append a move record.
	"""
	var move = {"act": Action.DISCARD_BEAST, "b": beast_idx, "p1": pirate1_idx, "p2": pirate2_idx}
	record_move_dic(move)

func save_replay() -> bool:
	"""
	Save current replay to user://replays/<seed>.replay
	"""
	var dir_path := "user://replays"
	var d := DirAccess.open("user://")
	if d == null:
		push_error("Cannot open user:// directory")
		return false

	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_absolute(dir_path)

	var fname_base := "game%d.rpl" % _game_seed
	var fname := "%s/%s" % [dir_path, fname_base]

	if FileAccess.file_exists(fname):
		fname = "%s/%s_%d" % [dir_path, fname_base, Time.get_unix_time_from_system()]

	var f := FileAccess.open(fname, FileAccess.WRITE)
	if f == null:
		push_error("Failed to open replay file: %s" % fname)
		return false

	record_move_dic({
		"act": Action.GAME_WIN,
		"time_utc": Time.get_unix_time_from_system(),
	})


	f.store_string(JSON.stringify(_moves))
	f.close()
	print("Replay saved:", fname)
	return true
