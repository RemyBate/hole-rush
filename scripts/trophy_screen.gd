class_name TrophyScreen
extends Control

signal closed

enum Tab { WEEKLY, ALL_TIME, REWARDS }

const LOCAL_RIVAL_COUNT := 9
const AVATARS := ["🕳️", "🍉", "🪙", "⭐", "🧲", "⚡", "🧁", "🏖️", "🧸", "🥕"]
const LOCAL_NAMES := [
	"HoleRunner", "FruitDash", "CoinSeeker", "StarBite", "RushNova",
	"GardenPro", "SnackAce", "BerryBot", "TropicTom", "PixelPit",
	"LevelLoop", "MissionMax", "KeyKeeper", "GemGlow", "FieldFox",
]

@onready var _bg: ColorRect = %Bg
@onready var _header: PanelContainer = %Header
@onready var _rank_pill: PanelContainer = %RankPill
@onready var _rank_info: Label = %RankInfo
@onready var _title: Label = %TitleLabel
@onready var _close_button: Button = %CloseButton
@onready var _tab_weekly: Button = %TabWeekly
@onready var _tab_all_time: Button = %TabAllTime
@onready var _tab_rewards: Button = %TabAchievements
@onready var _local_label: Label = %LocalLabel
@onready var _status: Label = %StatusLabel
@onready var _scroll: ScrollContainer = %Scroll
@onready var _content: VBoxContainer = %ContentBox
@onready var _continue_button: Button = %ContinueButton

var _tab: int = Tab.WEEKLY
var _player_rank: int = 0
var _busy: bool = false


func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_theme()
	_close_button.pressed.connect(_on_close_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_tab_weekly.pressed.connect(func(): _set_tab(Tab.WEEKLY))
	_tab_all_time.pressed.connect(func(): _set_tab(Tab.ALL_TIME))
	_tab_rewards.pressed.connect(func(): _set_tab(Tab.REWARDS))


func open_trophies() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_status.text = ""
	_busy = false
	_refresh_all()
	show()
	move_to_front()
	_scroll.scroll_vertical = 0
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.18)


func close_modal() -> void:
	close_trophies()


func close_trophies() -> void:
	if not visible:
		return
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.14)
	tween.tween_callback(_finish_close)


func _finish_close() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 1.0
	closed.emit()


func _apply_theme() -> void:
	var header_style := UIStyles.glossy_panel(
		Color(0.08, 0.26, 0.62, 1.0), 0, 0.0, Color(0.95, 0.78, 0.22, 1.0)
	)
	header_style.corner_radius_bottom_left = 20
	header_style.corner_radius_bottom_right = 20
	header_style.set_border_width_all(0)
	header_style.border_width_bottom = 5
	header_style.border_color = Color(0.95, 0.78, 0.22, 1.0)
	header_style.shadow_size = 12
	_header.add_theme_stylebox_override("panel", header_style)
	_rank_pill.add_theme_stylebox_override("panel", UIStyles.pill_panel())
	UIStyles.apply_dark_cartoon_label(_rank_info, 15)
	UIStyles.apply_cartoon_label(_title, 36, 7)
	UIStyles.apply_cartoon_label(_local_label, 14, 3)
	_local_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	UIStyles.apply_cartoon_label(_status, 15, 4)
	_status.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))

	var close_style := UIStyles.glossy_button(UIStyles.COLOR_DANGER, 999, Color(1, 1, 1, 0.75))
	_close_button.add_theme_stylebox_override("normal", close_style)
	_close_button.add_theme_stylebox_override("hover", UIStyles.glossy_button(Color(1.0, 0.42, 0.45), 999))
	_close_button.add_theme_stylebox_override("pressed", UIStyles.glossy_button(Color(0.78, 0.22, 0.28), 999))
	_close_button.add_theme_font_size_override("font_size", 28)
	_close_button.add_theme_color_override("font_color", Color.WHITE)
	UIStyles.bind_button(_close_button)
	UIStyles.style_primary_button(_continue_button, 24)
	_update_tab_styles()


func _set_tab(tab: int) -> void:
	GameSettings.play_ui_click()
	_tab = tab
	_status.text = ""
	_refresh_all()


func _update_tab_styles() -> void:
	_style_tab(_tab_weekly, _tab == Tab.WEEKLY, Color(0.95, 0.62, 0.15))
	_style_tab(_tab_all_time, _tab == Tab.ALL_TIME, Color(0.55, 0.28, 0.38))
	_style_tab(_tab_rewards, _tab == Tab.REWARDS, Color(0.22, 0.55, 0.85))


func _style_tab(btn: Button, active: bool, active_color: Color) -> void:
	var bg := active_color if active else Color(0.16, 0.24, 0.42)
	var style := UIStyles.glossy_button(bg, 14, Color(1, 1, 1, 0.45 if active else 0.2))
	style.shadow_size = 6 if active else 2
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", UIStyles.glossy_button(bg.lightened(0.08), 14))
	btn.add_theme_stylebox_override("pressed", UIStyles.glossy_button(bg.darkened(0.1), 14))
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_constant_override("outline_size", 4)
	UIStyles.bind_button(btn)


func _refresh_all() -> void:
	_update_tab_styles()
	var score := GameSettings.compute_trophy_score()
	var entries := _build_rank_entries(_tab == Tab.WEEKLY)
	_player_rank = _find_player_rank(entries)
	_rank_info.text = "#%d" % _player_rank
	_title.text = "TROPHY"
	if _tab == Tab.WEEKLY:
		_local_label.text = "Local Weekly Ranking · Offline"
	elif _tab == Tab.ALL_TIME:
		_local_label.text = "Local All-Time Ranking · Offline"
	else:
		_local_label.text = "Trophy Rewards · Claim once"

	while _content.get_child_count() > 0:
		var child := _content.get_child(0)
		_content.remove_child(child)
		child.free()

	if _tab == Tab.REWARDS:
		_build_rewards_view(score)
	else:
		_build_ranking_view(entries, score)

	_continue_button.visible = true
	_continue_button.text = "Continue"


func _build_ranking_view(entries: Array, score: int) -> void:
	var summary := Label.new()
	summary.text = "%s · Score %d · Wins %d" % [
		GameSettings.get_player_display_name(),
		score,
		GameSettings.levels_won,
	]
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(summary, 15, 3)
	_content.add_child(summary)

	_content.add_child(_make_podium(entries))

	var list_title := Label.new()
	list_title.text = "Rankings"
	list_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(list_title, 18, 4)
	_content.add_child(list_title)

	for i in range(entries.size()):
		_content.add_child(_make_rank_row(entries[i], i + 1))

	var note := Label.new()
	note.text = "Comparison entries are local offline bots — not live players."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(note, 12, 2)
	note.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0, 0.85))
	_content.add_child(note)


func _build_rewards_view(score: int) -> void:
	var intro := Label.new()
	intro.text = "Your Trophy Score: %d" % score
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(intro, 18, 4)
	_content.add_child(intro)

	for def in GameSettings.trophy_reward_definitions():
		_content.add_child(_make_reward_card(def))


func _make_podium(entries: Array) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := UIStyles.glossy_panel(Color(0.14, 0.38, 0.78, 0.98), 20, 4.0, Color(0.55, 0.8, 1.0, 0.7))
	style.shadow_size = 12
	panel.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 10)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER

	var e2: Dictionary = entries[1] if entries.size() > 1 else {}
	var e1: Dictionary = entries[0] if entries.size() > 0 else {}
	var e3: Dictionary = entries[2] if entries.size() > 2 else {}

	row.add_child(_make_podium_card(e2, 2, false))
	row.add_child(_make_podium_card(e1, 1, true))
	row.add_child(_make_podium_card(e3, 3, false))
	margin.add_child(row)
	panel.add_child(margin)
	return panel


func _make_podium_card(entry: Dictionary, rank: int, dominant: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 168 if dominant else 148)
	var bg: Color
	match rank:
		1:
			bg = Color(0.98, 0.82, 0.22, 0.98)
		2:
			bg = Color(0.78, 0.84, 0.92, 0.98)
		_:
			bg = Color(0.88, 0.62, 0.38, 0.98)
	var style := UIStyles.glossy_panel(bg, 16, 4.0 if dominant else 3.0, Color(1, 1, 1, 0.65))
	style.shadow_size = 10 if dominant else 6
	card.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 8)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.alignment = BoxContainer.ALIGNMENT_CENTER

	var crown := Label.new()
	crown.text = "👑" if rank == 1 else ("🥈" if rank == 2 else "🥉")
	crown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(crown, 22 if dominant else 18, 3)

	var avatar := Label.new()
	avatar.text = str(entry.get("avatar", "🕳️"))
	avatar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(avatar, 28 if dominant else 24, 4)

	var name_l := Label.new()
	name_l.text = str(entry.get("name", "—"))
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyles.apply_dark_cartoon_label(name_l, 12 if not dominant else 13)

	var chest := Label.new()
	chest.text = "🏆" if rank == 1 else "🎁"
	chest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(chest, 20, 3)

	var wins := Label.new()
	wins.text = "Score %d" % int(entry.get("score", 0))
	wins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_dark_cartoon_label(wins, 11)

	var medal := Label.new()
	medal.text = str(rank)
	medal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(medal, 18, 4)
	medal.add_theme_color_override("font_color", Color(0.15, 0.2, 0.35))

	col.add_child(crown)
	col.add_child(avatar)
	col.add_child(name_l)
	col.add_child(chest)
	col.add_child(wins)
	col.add_child(medal)
	margin.add_child(col)
	card.add_child(margin)
	if bool(entry.get("is_player", false)):
		var tag := Label.new()
		# subtle tint via modulate on card edge
		card.modulate = Color(1.05, 1.08, 1.0)
	return card


func _make_rank_row(entry: Dictionary, rank: int) -> PanelContainer:
	var is_player := bool(entry.get("is_player", false))
	var card := PanelContainer.new()
	var bg := Color(0.35, 0.82, 0.45, 0.98) if is_player else Color(0.96, 0.97, 1.0, 0.98)
	if rank <= 3 and not is_player:
		bg = Color(1.0, 0.94, 0.78, 0.98)
	var style := UIStyles.glossy_panel(bg, 16, 3.0, Color(0.2, 0.35, 0.55, 0.35) if not is_player else Color(0.95, 0.85, 0.2, 0.9))
	style.shadow_size = 8
	card.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var rank_l := Label.new()
	rank_l.text = str(rank)
	rank_l.custom_minimum_size = Vector2(28, 0)
	rank_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if is_player:
		UIStyles.apply_cartoon_label(rank_l, 22, 4)
	else:
		UIStyles.apply_dark_cartoon_label(rank_l, 20)

	var avatar := Label.new()
	avatar.text = str(entry.get("avatar", "🕳️"))
	avatar.custom_minimum_size = Vector2(36, 0)
	avatar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(avatar, 24, 3)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_l := Label.new()
	var suffix := " · You" if is_player else " · Local"
	name_l.text = str(entry.get("name", "Player")) + suffix
	if is_player:
		UIStyles.apply_cartoon_label(name_l, 16, 3)
	else:
		UIStyles.apply_dark_cartoon_label(name_l, 15)
	var sub := Label.new()
	sub.text = "Wins %d" % int(entry.get("wins", 0))
	if is_player:
		UIStyles.apply_cartoon_label(sub, 12, 2)
	else:
		UIStyles.apply_dark_cartoon_label(sub, 12)
	col.add_child(name_l)
	col.add_child(sub)

	var score_l := Label.new()
	score_l.text = "🏆 %d" % int(entry.get("score", 0))
	score_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if is_player:
		UIStyles.apply_cartoon_label(score_l, 16, 3)
	else:
		UIStyles.apply_dark_cartoon_label(score_l, 15)

	row.add_child(rank_l)
	row.add_child(avatar)
	row.add_child(col)
	row.add_child(score_l)
	margin.add_child(row)
	card.add_child(margin)
	return card


func _make_reward_card(def: Dictionary) -> PanelContainer:
	var claimable := bool(def.get("claimable", false))
	var claimed := bool(def.get("claimed", false))
	var unlocked := bool(def.get("unlocked", false))
	var bg := Color(0.22, 0.55, 0.35, 0.98) if claimable else (Color(0.28, 0.35, 0.48, 0.95) if claimed else Color(0.16, 0.24, 0.4, 0.96))
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIStyles.glossy_panel(bg, 16, 3.0, Color(0.95, 0.78, 0.28, 0.7)))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var icon := Label.new()
	icon.text = str(def.get("icon", "🏆"))
	icon.custom_minimum_size = Vector2(40, 0)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(icon, 26, 4)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = str(def.get("title", "Reward"))
	UIStyles.apply_cartoon_label(title, 17, 3)
	var req := Label.new()
	req.text = "%s\n%s" % [str(def.get("requirement", "")), str(def.get("reward_label", ""))]
	req.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIStyles.apply_cartoon_label(req, 12, 2)
	var prog := Label.new()
	var p := int(def.get("progress", 0))
	var t := int(def.get("target", 1))
	if claimed:
		prog.text = "Claimed"
		prog.add_theme_color_override("font_color", Color(0.7, 1.0, 0.75))
	elif claimable:
		prog.text = "Ready to claim"
		prog.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
	else:
		prog.text = "Progress %d / %d" % [mini(p, t), t]
		prog.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	UIStyles.apply_cartoon_label(prog, 13, 2)
	col.add_child(title)
	col.add_child(req)
	col.add_child(prog)

	row.add_child(icon)
	row.add_child(col)

	if claimable:
		var btn := Button.new()
		btn.text = "Claim"
		btn.custom_minimum_size = Vector2(88, 48)
		btn.focus_mode = Control.FOCUS_NONE
		UIStyles.style_primary_button(btn, 18)
		btn.pressed.connect(_on_claim_pressed.bind(str(def.get("id", "")), btn))
		row.add_child(btn)
	elif claimed:
		var done := Label.new()
		done.text = "✓"
		done.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UIStyles.apply_cartoon_label(done, 24, 4)
		row.add_child(done)
	elif not unlocked:
		var lock := Label.new()
		lock.text = "🔒"
		lock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UIStyles.apply_cartoon_label(lock, 22, 3)
		row.add_child(lock)

	margin.add_child(row)
	card.add_child(margin)
	return card


func _build_rank_entries(weekly: bool) -> Array:
	var player_score := GameSettings.compute_trophy_score()
	var player_wins := GameSettings.levels_won
	var player_name := GameSettings.get_player_display_name()
	var seed_n := GameSettings.weekly_rank_seed() if weekly else 90210
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_n * 9973 + (13 if weekly else 71)

	var entries: Array = []
	entries.append({
		"name": player_name,
		"score": player_score,
		"wins": player_wins,
		"avatar": "🕳️",
		"is_player": true,
		"is_local": false,
	})

	for i in range(LOCAL_RIVAL_COUNT):
		var base := 40 + i * 35
		var jitter := rng.randi_range(0, 90)
		var score := base + jitter + (rng.randi_range(20, 120) if weekly else rng.randi_range(50, 220))
		# Keep all-time rivals stable relative to seed; weekly shifts with week seed.
		if not weekly:
			score = 60 + ((seed_n + i * 137) % 40) + i * 55
		var wins := maxi(0, score / 18 + rng.randi_range(0, 4))
		var name_i := (seed_n + i * 3) % LOCAL_NAMES.size()
		entries.append({
			"name": LOCAL_NAMES[name_i],
			"score": score,
			"wins": wins,
			"avatar": AVATARS[i % AVATARS.size()],
			"is_player": false,
			"is_local": true,
		})

	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var sa := int(a.get("score", 0))
		var sb := int(b.get("score", 0))
		if sa == sb:
			return bool(a.get("is_player", false)) and not bool(b.get("is_player", false))
		return sa > sb
	)
	return entries


func _find_player_rank(entries: Array) -> int:
	for i in range(entries.size()):
		if bool(entries[i].get("is_player", false)):
			return i + 1
	return entries.size()


func _on_claim_pressed(reward_id: String, btn: Button) -> void:
	if _busy:
		return
	_busy = true
	GameSettings.play_ui_click()
	if btn:
		btn.disabled = true
	var ok := GameSettings.claim_trophy_reward(reward_id)
	if ok:
		GameSettings.play_coin_collect_sfx()
		_status.text = "Reward claimed!"
		_refresh_all()
	else:
		GameSettings.play_lose_sfx()
		_status.text = "Could not claim reward."
		if btn:
			btn.disabled = false
	_busy = false


func _on_continue_pressed() -> void:
	GameSettings.play_ui_click()
	close_trophies()


func _on_close_pressed() -> void:
	GameSettings.play_ui_click()
	close_trophies()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close_trophies()
		get_viewport().set_input_as_handled()
