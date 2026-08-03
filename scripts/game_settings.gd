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
signal collectible_discovered(catalog_key: String)

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

## Persistent collection / trophy stats (additive; never resets existing progress).
var discovered_fruit_ids: Array = []
## Stable keys e.g. "fruits:4" — preferred discovery store (migrates from discovered_fruit_ids).
var discovered_collectibles: Array = []
var claimed_collection_rewards: Array = []
## Optional swallow counts by catalog key.
var collected_count_by_id: Dictionary = {}
var levels_won: int = 0
var lifetime_coins: int = 0
var three_star_wins: int = 0
var mission_items_collected: int = 0
var daily_offer_claimed_ymd: String = ""
var local_player_name: String = ""
var claimed_trophy_rewards: Array = []

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
	discovered_fruit_ids = _load_int_array(data.get("discovered_fruit_ids", []))
	discovered_collectibles = _load_string_array(data.get("discovered_collectibles", []))
	claimed_collection_rewards = _load_string_array(data.get("claimed_collection_rewards", []))
	collected_count_by_id = {}
	var counts_raw: Variant = data.get("collected_count_by_id", {})
	if counts_raw is Dictionary:
		for k in counts_raw.keys():
			collected_count_by_id[str(k)] = maxi(0, int(counts_raw[k]))
	# Migrate legacy fruit IDs → catalog keys without wiping progress.
	for fid in discovered_fruit_ids:
		var key := "fruits:%d" % int(fid)
		if not discovered_collectibles.has(key):
			discovered_collectibles.append(key)
	for key in discovered_collectibles:
		var parts := str(key).split(":")
		if parts.size() == 2 and parts[0] == "fruits":
			var id := int(parts[1])
			if id > 0 and not discovered_fruit_ids.has(id):
				discovered_fruit_ids.append(id)
	discovered_fruit_ids.sort()
	levels_won = maxi(0, int(data.get("levels_won", maxi(0, highest_unlocked_level - 1))))
	lifetime_coins = maxi(0, int(data.get("lifetime_coins", total_coins)))
	three_star_wins = maxi(0, int(data.get("three_star_wins", 0)))
	mission_items_collected = maxi(0, int(data.get("mission_items_collected", 0)))
	daily_offer_claimed_ymd = str(data.get("daily_offer_claimed_ymd", ""))
	local_player_name = str(data.get("local_player_name", ""))
	claimed_trophy_rewards = _load_string_array(data.get("claimed_trophy_rewards", []))
	if local_player_name.strip_edges() == "":
		local_player_name = _generate_local_player_name()
	tick_lives_regen()


func _load_int_array(raw: Variant) -> Array:
	var out: Array = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for v in raw:
		var id := int(v)
		if id > 0 and not out.has(id):
			out.append(id)
	out.sort()
	return out


func _load_string_array(raw: Variant) -> Array:
	var out: Array = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for v in raw:
		var s := str(v).strip_edges()
		if s != "" and not out.has(s):
			out.append(s)
	return out


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


func add_booster(id: int, amount: int = 1) -> void:
	amount = maxi(0, amount)
	match clampi(id, 0, 3):
		0:
			booster_lightning += amount
		1:
			booster_freeze += amount
		2:
			booster_magnet += amount
		3:
			booster_double_coins += amount
	_write_progress_file(0)
	profile_changed.emit()


func can_afford_coins(cost: int) -> bool:
	return total_coins >= maxi(0, cost)


func can_afford_gems(cost: int) -> bool:
	return total_gems >= maxi(0, cost)


func spend_coins(amount: int) -> bool:
	amount = maxi(0, amount)
	if total_coins < amount:
		return false
	total_coins -= amount
	_write_progress_file(0)
	profile_changed.emit()
	return true


func spend_gems(amount: int) -> bool:
	amount = maxi(0, amount)
	if total_gems < amount:
		return false
	total_gems -= amount
	_write_progress_file(0)
	profile_changed.emit()
	return true


func add_coins(amount: int, count_lifetime: bool = true) -> void:
	amount = maxi(0, amount)
	if amount <= 0:
		return
	total_coins += amount
	if count_lifetime:
		lifetime_coins += amount
	_write_progress_file(0)
	profile_changed.emit()


func refill_one_life() -> bool:
	tick_lives_regen()
	if lives >= MAX_LIVES:
		return false
	lives += 1
	if lives >= MAX_LIVES:
		lives_regen_at = 0
	_write_progress_file(0)
	profile_changed.emit()
	return true


func add_lives(amount: int) -> int:
	tick_lives_regen()
	amount = maxi(0, amount)
	var before := lives
	lives = mini(MAX_LIVES, lives + amount)
	if lives >= MAX_LIVES:
		lives_regen_at = 0
	elif lives > before and lives_regen_at <= 0:
		lives_regen_at = int(Time.get_unix_time_from_system()) + LIFE_REGEN_SECONDS
	var gained := lives - before
	if gained > 0:
		_write_progress_file(0)
		profile_changed.emit()
	return gained


func today_ymd() -> String:
	var dt := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(dt.get("year", 2026)), int(dt.get("month", 1)), int(dt.get("day", 1))]


func can_claim_daily_offer() -> bool:
	return daily_offer_claimed_ymd != today_ymd()


func claim_daily_offer() -> bool:
	if not can_claim_daily_offer():
		return false
	daily_offer_claimed_ymd = today_ymd()
	_write_progress_file(0)
	profile_changed.emit()
	return true


func is_fruit_discovered(image_id: int) -> bool:
	return is_collectible_discovered("fruits:%d" % image_id)


func is_collectible_discovered(catalog_key: String) -> bool:
	catalog_key = catalog_key.strip_edges()
	if catalog_key == "":
		return false
	if discovered_collectibles.has(catalog_key):
		return true
	# Legacy fallback for fruit IDs.
	var parts := catalog_key.split(":")
	if parts.size() == 2 and parts[0] == "fruits":
		return discovered_fruit_ids.has(int(parts[1]))
	return false


func mark_fruit_discovered(image_id: int) -> bool:
	return mark_collectible_discovered("fruits:%d" % image_id)


func mark_collectible_discovered(catalog_key: String) -> bool:
	catalog_key = catalog_key.strip_edges()
	if catalog_key == "":
		return false
	var is_new := not discovered_collectibles.has(catalog_key)
	if not is_new:
		collected_count_by_id[catalog_key] = int(collected_count_by_id.get(catalog_key, 1)) + 1
		_write_progress_file(0)
		return false
	discovered_collectibles.append(catalog_key)
	collected_count_by_id[catalog_key] = maxi(1, int(collected_count_by_id.get(catalog_key, 0)) + 1)
	var parts := catalog_key.split(":")
	if parts.size() == 2 and parts[0] == "fruits":
		var id := int(parts[1])
		if id > 0 and not discovered_fruit_ids.has(id):
			discovered_fruit_ids.append(id)
			discovered_fruit_ids.sort()
	_write_progress_file(0)
	profile_changed.emit()
	collectible_discovered.emit(catalog_key)
	return true


func discovered_collectible_count() -> int:
	return discovered_collectibles.size()


func collection_reward_definitions(total_available: int = -1) -> Array:
	var discovered := discovered_collectible_count()
	var total := total_available
	if total < 0:
		ItemCatalog.ensure_loaded(ItemCatalog.CATEGORY_FRUITS)
		total = ItemCatalog.valid_entries(ItemCatalog.CATEGORY_FRUITS).size()
	var defs: Array = [
		{
			"id": "col_5",
			"icon": "🌱",
			"title": "First Finds",
			"requirement": "Discover 5 collectibles",
			"target": 5,
			"reward_label": "50 coins",
			"reward_coins": 50,
		},
		{
			"id": "col_10",
			"icon": "🧺",
			"title": "Growing Shelf",
			"requirement": "Discover 10 collectibles",
			"target": 10,
			"reward_label": "Magnet ×1",
			"reward_booster": BoosterData.Id.MAGNET,
			"reward_booster_amount": 1,
		},
		{
			"id": "col_15",
			"icon": "⭐",
			"title": "Half Way",
			"requirement": "Discover 15 collectibles",
			"target": 15,
			"reward_label": "100 coins + Freeze",
			"reward_coins": 100,
			"reward_booster": BoosterData.Id.FREEZE_TIME,
			"reward_booster_amount": 1,
		},
		{
			"id": "col_20",
			"icon": "🎁",
			"title": "Almost Full",
			"requirement": "Discover 20 collectibles",
			"target": 20,
			"reward_label": "3 gems",
			"reward_gems": 3,
		},
		{
			"id": "col_all",
			"icon": "🏆",
			"title": "Full Collection",
			"requirement": "Discover all collectibles",
			"target": maxi(1, total),
			"reward_label": "200 coins + Lightning",
			"reward_coins": 200,
			"reward_booster": BoosterData.Id.LIGHTNING,
			"reward_booster_amount": 1,
		},
	]
	for d in defs:
		var id := str(d.get("id", ""))
		var t := maxi(1, int(d.get("target", 1)))
		var claimed := claimed_collection_rewards.has(id)
		d["progress"] = discovered
		d["unlocked"] = discovered >= t
		d["claimed"] = claimed
		d["claimable"] = (discovered >= t) and not claimed
	return defs


func claim_collection_reward(reward_id: String) -> bool:
	reward_id = reward_id.strip_edges()
	if reward_id == "" or claimed_collection_rewards.has(reward_id):
		return false
	ItemCatalog.ensure_loaded(ItemCatalog.CATEGORY_FRUITS)
	var total := ItemCatalog.valid_entries(ItemCatalog.CATEGORY_FRUITS).size()
	var found: Dictionary = {}
	for def in collection_reward_definitions(total):
		if str(def.get("id", "")) == reward_id:
			found = def
			break
	if found.is_empty() or not bool(found.get("claimable", false)):
		return false
	var coins := int(found.get("reward_coins", 0))
	var gems := int(found.get("reward_gems", 0))
	var lives_n := int(found.get("reward_lives", 0))
	if coins > 0:
		add_coins(coins)
	if gems > 0:
		total_gems += gems
	if lives_n > 0:
		add_lives(lives_n)
	if found.has("reward_booster"):
		add_booster(int(found.get("reward_booster", 0)), int(found.get("reward_booster_amount", 1)))
	claimed_collection_rewards.append(reward_id)
	_write_progress_file(0)
	profile_changed.emit()
	return true


func register_mission_item_collected() -> void:
	mission_items_collected += 1
	_write_progress_file(0)


func trophy_definitions() -> Array:
	var completed_levels := maxi(levels_won, maxi(0, highest_unlocked_level - 1))
	var defs: Array = [
		{"id": "first_level", "icon": "🏁", "title": "First Clear", "requirement": "Complete 1 level", "progress": completed_levels, "target": 1},
		{"id": "levels_5", "icon": "5️⃣", "title": "On a Roll", "requirement": "Complete 5 levels", "progress": completed_levels, "target": 5},
		{"id": "levels_10", "icon": "🔟", "title": "Dedicated", "requirement": "Complete 10 levels", "progress": completed_levels, "target": 10},
		{"id": "levels_25", "icon": "🌟", "title": "Veteran", "requirement": "Complete 25 levels", "progress": completed_levels, "target": 25},
		{"id": "coins_100", "icon": "🪙", "title": "Coin Starter", "requirement": "Earn 100 lifetime coins", "progress": lifetime_coins, "target": 100},
		{"id": "coins_1000", "icon": "💰", "title": "Coin Bank", "requirement": "Earn 1,000 lifetime coins", "progress": lifetime_coins, "target": 1000},
		{"id": "score_500", "icon": "⭐", "title": "Half Thousand", "requirement": "Best score 500+", "progress": best_score, "target": 500},
		{"id": "score_1000", "icon": "🏅", "title": "High Scorer", "requirement": "Best score 1,000+", "progress": best_score, "target": 1000},
		{"id": "three_star", "icon": "✨", "title": "Perfect Timing", "requirement": "Win with 3 stars once", "progress": three_star_wins, "target": 1},
		{"id": "missions_50", "icon": "🎯", "title": "Mission Hunter", "requirement": "Collect 50 mission items", "progress": mission_items_collected, "target": 50},
		{"id": "collection_5", "icon": "🖼️", "title": "Collector", "requirement": "Discover 5 fruit images", "progress": discovered_collectible_count(), "target": 5},
	]
	for d in defs:
		var p := int(d.get("progress", 0))
		var t := maxi(1, int(d.get("target", 1)))
		d["unlocked"] = p >= t
	return defs


func completed_level_count() -> int:
	return maxi(levels_won, maxi(0, highest_unlocked_level - 1))


## Composite local Trophy Score from real save fields only.
func compute_trophy_score() -> int:
	var completed := completed_level_count()
	var score := completed * 12
	score += levels_won * 8
	score += three_star_wins * 30
	score += mini(best_score / 20, 200)
	score += mini(lifetime_coins / 25, 150)
	score += mini(mission_items_collected, 100)
	score += discovered_collectible_count() * 8
	for def in trophy_definitions():
		if bool(def.get("unlocked", false)):
			score += 20
	return maxi(0, score)


func get_player_display_name() -> String:
	if local_player_name.strip_edges() == "":
		local_player_name = _generate_local_player_name()
		_write_progress_file(0)
	return local_player_name


func _generate_local_player_name() -> String:
	var seed_n: int = abs(int(hash(str(Time.get_unix_time_from_system()) + str(best_score) + str(levels_won))))
	return "Player%d" % (1000 + seed_n % 9000)


func weekly_rank_seed() -> int:
	var dt := Time.get_datetime_dict_from_system()
	var year := int(dt.get("year", 2026))
	var month := int(dt.get("month", 1))
	var day := int(dt.get("day", 1))
	return year * 100 + (month - 1) * 5 + int((day - 1) / 7)


func trophy_reward_definitions() -> Array:
	var score := compute_trophy_score()
	var completed := completed_level_count()
	var defs: Array = [
		{
			"id": "reward_score_100",
			"icon": "🏆",
			"title": "Score 100",
			"requirement": "Reach Trophy Score 100",
			"progress": score,
			"target": 100,
			"reward_label": "50 coins",
			"reward_coins": 50,
		},
		{
			"id": "reward_score_500",
			"icon": "🥇",
			"title": "Score 500",
			"requirement": "Reach Trophy Score 500",
			"progress": score,
			"target": 500,
			"reward_label": "120 coins + Magnet",
			"reward_coins": 120,
			"reward_booster": BoosterData.Id.MAGNET,
			"reward_booster_amount": 1,
		},
		{
			"id": "reward_score_1000",
			"icon": "💎",
			"title": "Score 1,000",
			"requirement": "Reach Trophy Score 1,000",
			"progress": score,
			"target": 1000,
			"reward_label": "5 gems",
			"reward_gems": 5,
		},
		{
			"id": "reward_levels_10",
			"icon": "🔟",
			"title": "10 Clears",
			"requirement": "Complete 10 levels",
			"progress": completed,
			"target": 10,
			"reward_label": "Freeze ×1",
			"reward_booster": BoosterData.Id.FREEZE_TIME,
			"reward_booster_amount": 1,
		},
		{
			"id": "reward_levels_25",
			"icon": "🌟",
			"title": "25 Clears",
			"requirement": "Complete 25 levels",
			"progress": completed,
			"target": 25,
			"reward_label": "200 coins",
			"reward_coins": 200,
		},
		{
			"id": "reward_wins_5",
			"icon": "🏁",
			"title": "5 Wins",
			"requirement": "Win 5 times",
			"progress": levels_won,
			"target": 5,
			"reward_label": "Lightning ×1",
			"reward_booster": BoosterData.Id.LIGHTNING,
			"reward_booster_amount": 1,
		},
		{
			"id": "reward_wins_20",
			"icon": "🏅",
			"title": "20 Wins",
			"requirement": "Win 20 times",
			"progress": levels_won,
			"target": 20,
			"reward_label": "1 gem + Double Coins",
			"reward_gems": 1,
			"reward_booster": BoosterData.Id.DOUBLE_COINS,
			"reward_booster_amount": 1,
		},
		{
			"id": "reward_stars_1",
			"icon": "✨",
			"title": "Perfect Clear",
			"requirement": "Earn a 3-star win",
			"progress": three_star_wins,
			"target": 1,
			"reward_label": "+1 life",
			"reward_lives": 1,
		},
	]
	for d in defs:
		var id := str(d.get("id", ""))
		var p := int(d.get("progress", 0))
		var t := maxi(1, int(d.get("target", 1)))
		var claimed := claimed_trophy_rewards.has(id)
		d["unlocked"] = p >= t
		d["claimed"] = claimed
		d["claimable"] = (p >= t) and not claimed
	return defs


func claim_trophy_reward(reward_id: String) -> bool:
	reward_id = reward_id.strip_edges()
	if reward_id == "" or claimed_trophy_rewards.has(reward_id):
		return false
	var found: Dictionary = {}
	for def in trophy_reward_definitions():
		if str(def.get("id", "")) == reward_id:
			found = def
			break
	if found.is_empty() or not bool(found.get("claimable", false)):
		return false
	var coins := int(found.get("reward_coins", 0))
	var gems := int(found.get("reward_gems", 0))
	var lives_n := int(found.get("reward_lives", 0))
	if coins > 0:
		add_coins(coins)
	if gems > 0:
		total_gems += gems
	if lives_n > 0:
		add_lives(lives_n)
	if found.has("reward_booster"):
		add_booster(int(found.get("reward_booster", 0)), int(found.get("reward_booster_amount", 1)))
	claimed_trophy_rewards.append(reward_id)
	_write_progress_file(0)
	profile_changed.emit()
	return true


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
	lifetime_coins += maxi(0, coins_earned)
	total_keys += maxi(0, keys_earned)
	total_gems += maxi(0, gems_earned)
	reward_track_xp += maxi(
		0,
		coins_earned + keys_earned * 5 + gems_earned * 8 + trophy_points * 3
	)
	levels_won += 1
	current_level = clampi(next_level, 1, LevelTheme.MAX_LEVEL)
	highest_unlocked_level = maxi(highest_unlocked_level, current_level)
	last_score = maxi(0, score)
	best_score = maxi(best_score, last_score)
	_write_progress_file(collected)
	vibrate(60)


func register_three_star_win() -> void:
	three_star_wins += 1


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
		"discovered_fruit_ids": discovered_fruit_ids,
		"discovered_collectibles": discovered_collectibles,
		"claimed_collection_rewards": claimed_collection_rewards,
		"collected_count_by_id": collected_count_by_id,
		"levels_won": levels_won,
		"lifetime_coins": lifetime_coins,
		"three_star_wins": three_star_wins,
		"mission_items_collected": mission_items_collected,
		"daily_offer_claimed_ymd": daily_offer_claimed_ymd,
		"local_player_name": local_player_name,
		"claimed_trophy_rewards": claimed_trophy_rewards,
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
