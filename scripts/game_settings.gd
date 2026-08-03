extends Node

## Autoload: GameSettings — persistent options + progress + meta currencies.

const SETTINGS_PATH: String = "user://settings.save"
const PROGRESS_PATH: String = "user://progress.save"

const REWARD_MILESTONES: Array[int] = [100, 120, 200, 120, 100]
const REWARD_TRACK_MAX: int = 640
const MAX_LIVES: int = 5
const LIFE_REGEN_SECONDS: int = 30 * 60
const META_GOAL_XP: int = 800

signal settings_changed
signal progress_saved
signal profile_changed

var music_enabled: bool = true
var sound_enabled: bool = true
var vibration_enabled: bool = true
var notifications_enabled: bool = true

var current_level: int = 1
var highest_unlocked_level: int = 1
var best_score: int = 0
var last_score: int = 0

var total_coins: int = 0
var total_keys: int = 0
var total_gems: int = 0
var reward_track_xp: int = 0
var lives: int = MAX_LIVES
var lives_regen_at: int = 0

var booster_lightning: int = 9
var booster_freeze: int = 6
var booster_magnet: int = 3
var booster_double_coins: int = 3

var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
## Small rotating pool so rapid collects do not cut each other off.
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0
var _stream_cache: Dictionary = {}
var _collect_pitch_rng := RandomNumberGenerator.new()


func _ready() -> void:
	load_settings()
	load_progress()
	_setup_audio()
	_collect_pitch_rng.randomize()


## Level shown on home Play / launched into a match.
func get_play_level() -> int:
	return highest_unlocked_level


## Clamp a requested launch level to a valid campaign level.
func resolve_play_level(requested_level: int) -> int:
	return clampi(requested_level, 1, LevelTheme.MAX_LEVEL)


func _setup_audio() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Master"
	add_child(_music_player)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SfxPlayer"
	_sfx_player.bus = "Master"
	add_child(_sfx_player)

	_sfx_pool.clear()
	for i in 4:
		var player := AudioStreamPlayer.new()
		player.name = "SfxPool_%d" % i
		player.bus = "Master"
		add_child(player)
		_sfx_pool.append(player)

	var music := _load_audio_stream("res://audio/music_loop")
	if music != null:
		_set_stream_loop(music, true)
		_music_player.stream = music
	_apply_music_state()


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return
	file.close()
	var data: Variant = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		return
	music_enabled = bool(data.get("music_enabled", true))
	sound_enabled = bool(data.get("sound_enabled", true))
	vibration_enabled = bool(data.get("vibration_enabled", true))
	notifications_enabled = bool(data.get("notifications_enabled", true))


func save_settings() -> void:
	var data := {
		"music_enabled": music_enabled,
		"sound_enabled": sound_enabled,
		"vibration_enabled": vibration_enabled,
		"notifications_enabled": notifications_enabled,
	}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	file.close()
	settings_changed.emit()


func load_progress() -> void:
	if not FileAccess.file_exists(PROGRESS_PATH):
		return
	var file := FileAccess.open(PROGRESS_PATH, FileAccess.READ)
	if file == null:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return
	file.close()
	var data: Variant = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		return
	current_level = clampi(int(data.get("current_level", 1)), 1, LevelTheme.MAX_LEVEL)
	highest_unlocked_level = clampi(
		int(data.get("highest_unlocked_level", current_level)),
		1,
		LevelTheme.MAX_LEVEL
	)
	best_score = maxi(0, int(data.get("best_score", 0)))
	last_score = maxi(0, int(data.get("last_score", 0)))
	total_coins = maxi(0, int(data.get("total_coins", 0)))
	total_keys = maxi(0, int(data.get("total_keys", 0)))
	total_gems = maxi(0, int(data.get("total_gems", 0)))
	reward_track_xp = maxi(0, int(data.get("reward_track_xp", 0)))
	lives = clampi(int(data.get("lives", MAX_LIVES)), 0, MAX_LIVES)
	lives_regen_at = int(data.get("lives_regen_at", 0))
	booster_lightning = maxi(0, int(data.get("booster_lightning", 9)))
	booster_freeze = maxi(0, int(data.get("booster_freeze", 6)))
	booster_magnet = maxi(0, int(data.get("booster_magnet", 3)))
	booster_double_coins = maxi(0, int(data.get("booster_double_coins", 3)))
	tick_lives_regen()


func tick_lives_regen() -> void:
	if lives >= MAX_LIVES:
		lives_regen_at = 0
		return
	var now := int(Time.get_unix_time_from_system())
	if lives_regen_at <= 0:
		lives_regen_at = now + LIFE_REGEN_SECONDS
		return
	while lives < MAX_LIVES and now >= lives_regen_at:
		lives += 1
		if lives < MAX_LIVES:
			lives_regen_at += LIFE_REGEN_SECONDS
		else:
			lives_regen_at = 0


func can_play() -> bool:
	tick_lives_regen()
	return lives > 0


func spend_life() -> void:
	tick_lives_regen()
	if lives <= 0:
		return
	lives -= 1
	if lives < MAX_LIVES and lives_regen_at <= 0:
		lives_regen_at = int(Time.get_unix_time_from_system()) + LIFE_REGEN_SECONDS
	_write_progress_file(0)
	profile_changed.emit()


func lives_status_text() -> String:
	tick_lives_regen()
	if lives >= MAX_LIVES:
		return "FULL"
	var now := int(Time.get_unix_time_from_system())
	var remain := maxi(0, lives_regen_at - now)
	var mins := remain / 60
	var secs := remain % 60
	return "%02d:%02d" % [mins, secs]


func get_booster_count(id: int) -> int:
	match id:
		0:
			return booster_lightning
		1:
			return booster_freeze
		2:
			return booster_magnet
		3:
			return booster_double_coins
	return 0


func consume_boosters(ids: Array) -> void:
	for id in ids:
		match int(id):
			0:
				booster_lightning = maxi(0, booster_lightning - 1)
			1:
				booster_freeze = maxi(0, booster_freeze - 1)
			2:
				booster_magnet = maxi(0, booster_magnet - 1)
			3:
				booster_double_coins = maxi(0, booster_double_coins - 1)
	_write_progress_file(0)
	profile_changed.emit()


func meta_progress_text() -> String:
	return "%d/%d" % [reward_track_xp % META_GOAL_XP, META_GOAL_XP]


func meta_progress_ratio() -> float:
	return clampf(float(reward_track_xp % META_GOAL_XP) / float(META_GOAL_XP), 0.0, 1.0)


func level_objective_lines(level: int) -> Array[String]:
	var theme := LevelTheme.theme_for_level(level)
	var lines: Array[String] = []
	var missions := MissionFactory.create_missions(theme, level)
	for mission in missions:
		var m := mission as Mission
		if m == null:
			continue
		# Image-only missions: quantity only (prep UI can also show textures).
		lines.append("Collect %d" % m.target)
	return lines


func save_profile() -> void:
	_write_progress_file(0)


func save_progress(level: int, score: int, collected: int) -> void:
	current_level = clampi(level, 1, LevelTheme.MAX_LEVEL)
	highest_unlocked_level = maxi(highest_unlocked_level, current_level)
	last_score = maxi(0, score)
	best_score = maxi(best_score, last_score)
	_write_progress_file(collected)


func apply_victory_continue(
	next_level: int,
	coins_earned: int,
	keys_earned: int,
	gems_earned: int,
	trophy_points: int,
	score: int,
	collected: int
) -> void:
	total_coins += maxi(0, coins_earned)
	total_keys += maxi(0, keys_earned)
	total_gems += maxi(0, gems_earned)
	reward_track_xp += maxi(
		0,
		coins_earned + keys_earned * 5 + gems_earned * 8 + trophy_points * 3
	)
	current_level = clampi(next_level, 1, LevelTheme.MAX_LEVEL)
	highest_unlocked_level = maxi(highest_unlocked_level, current_level)
	last_score = maxi(0, score)
	best_score = maxi(best_score, last_score)
	_write_progress_file(collected)
	vibrate(60)


func _write_progress_file(collected: int) -> void:
	var data := {
		"current_level": current_level,
		"highest_unlocked_level": highest_unlocked_level,
		"best_score": best_score,
		"last_score": last_score,
		"collected": collected,
		"total_coins": total_coins,
		"total_keys": total_keys,
		"total_gems": total_gems,
		"reward_track_xp": reward_track_xp,
		"lives": lives,
		"lives_regen_at": lives_regen_at,
		"booster_lightning": booster_lightning,
		"booster_freeze": booster_freeze,
		"booster_magnet": booster_magnet,
		"booster_double_coins": booster_double_coins,
		"saved_at": Time.get_unix_time_from_system(),
	}
	var file := FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	file.close()
	progress_saved.emit()
	profile_changed.emit()


static func stars_for_time_left(time_left: float, max_time: float) -> int:
	var ratio := time_left / maxf(max_time, 1.0)
	if ratio >= 0.45:
		return 3
	if ratio >= 0.2:
		return 2
	return 1


static func banner_for_stars(stars: int) -> String:
	match stars:
		3:
			return "Excellent"
		2:
			return "Great"
		_:
			return "Good"


static func track_fill_ratio(xp: int) -> float:
	return clampf(float(xp % REWARD_TRACK_MAX) / float(REWARD_TRACK_MAX), 0.0, 1.0)


static func trophy_points_for_score(score: int) -> int:
	return maxi(1, score / 25)


static func completion_key_bonus(missions_done: int, collected: int) -> int:
	return missions_done * 2 + collected / 8


func _apply_music_state() -> void:
	if _music_player == null:
		return
	if music_enabled and _music_player.stream != null:
		if not _music_player.playing:
			_music_player.play()
	else:
		_music_player.stop()


func set_music_enabled(value: bool) -> void:
	music_enabled = value
	_apply_music_state()
	save_settings()


func set_sound_enabled(value: bool) -> void:
	sound_enabled = value
	save_settings()


func set_vibration_enabled(value: bool) -> void:
	vibration_enabled = value
	save_settings()


func set_notifications_enabled(value: bool) -> void:
	notifications_enabled = value
	save_settings()


func play_ui_click() -> void:
	play_sfx()


func play_sfx() -> void:
	_play_named_sfx("res://audio/ui_click", _play_generated_blip)


## Soft swallow for non-target items (or already-completed targets).
func play_collect_normal_sfx() -> void:
	var pitch := _collect_pitch_rng.randf_range(0.96, 1.04)
	_play_pooled_sfx("res://audio/collect_normal", pitch, -2.0, _play_generated_collect_normal)


## Brighter success sound for unfinished mission-target items.
func play_collect_target_sfx() -> void:
	var pitch := _collect_pitch_rng.randf_range(1.02, 1.08)
	_play_pooled_sfx("res://audio/collect_target", pitch, -1.0, _play_generated_collect_target)


func play_item_collect_sfx(is_unfinished_mission_target: bool) -> void:
	if is_unfinished_mission_target:
		play_collect_target_sfx()
	else:
		play_collect_normal_sfx()


func play_coin_collect_sfx() -> void:
	_play_named_sfx("res://audio/coin_collect", _play_generated_coin_chime)


func play_win_sfx() -> void:
	_play_named_sfx("res://audio/win_jingle", _fallback_win_sfx)


func play_lose_sfx() -> void:
	_play_named_sfx("res://audio/lose_tone", _fallback_lose_sfx)


func _fallback_win_sfx() -> void:
	_play_generated_tone(1200, 10.0, 80.0)


func _fallback_lose_sfx() -> void:
	_play_generated_tone(500, 4.0, 75.0)


func _play_named_sfx(path_base: String, fallback: Callable) -> void:
	if not sound_enabled:
		return
	var stream := _load_audio_stream(path_base)
	if stream != null:
		_play_on_player(_next_sfx_player(), stream, 1.0, 0.0)
	else:
		fallback.call()


func _play_pooled_sfx(path_base: String, pitch: float, volume_db: float, fallback: Callable) -> void:
	if not sound_enabled:
		return
	var stream := _load_audio_stream(path_base)
	if stream != null:
		_play_on_player(_next_sfx_player(), stream, pitch, volume_db)
	else:
		fallback.call()


func _next_sfx_player() -> AudioStreamPlayer:
	if _sfx_pool.is_empty():
		return _sfx_player
	var player := _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % _sfx_pool.size()
	return player


func _play_on_player(player: AudioStreamPlayer, stream: AudioStream, pitch: float, volume_db: float) -> void:
	if player == null or stream == null:
		return
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()


func _load_audio_stream(path_base: String) -> AudioStream:
	if _stream_cache.has(path_base):
		return _stream_cache[path_base] as AudioStream
	for ext in ["wav", "ogg"]:
		var path := "%s.%s" % [path_base, ext]
		if ResourceLoader.exists(path):
			var stream := load(path) as AudioStream
			_stream_cache[path_base] = stream
			return stream
	return null


func _set_stream_loop(stream: AudioStream, loop: bool) -> void:
	if not loop:
		return
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true


func _play_generated_blip() -> void:
	_play_generated_tone(900, 6.0, 70.0)


func _play_generated_coin_chime() -> void:
	_play_generated_tone(640, 14.0, 90.0)


func _play_generated_collect_normal() -> void:
	_play_generated_tone(700, 5.0, 58.0)


func _play_generated_collect_target() -> void:
	_play_generated_tone(1100, 12.0, 78.0)


func _play_generated_tone(sample_count: int, wave_cycles: float, volume: float) -> void:
	if not sound_enabled:
		return
	var wav := AudioStreamWAV.new()
	wav.mix_rate = 22050
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.stereo = false
	var data := PackedByteArray()
	data.resize(sample_count)
	for i in sample_count:
		var t := float(i) / float(sample_count)
		var env := (1.0 - t) * sin(t * TAU * wave_cycles)
		data[i] = int(clampf(128.0 + env * volume, 0.0, 255.0))
	wav.data = data
	_play_on_player(_next_sfx_player(), wav, 1.0, 0.0)


func vibrate(duration_ms: int = 40) -> void:
	if not vibration_enabled:
		return
	Input.vibrate_handheld(duration_ms)
