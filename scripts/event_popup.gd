extends "res://scripts/home_modal.gd"

signal play_requested(event_id: String)

var _event_id: String = ""
var _event_title: String = ""


func open_event(event_id: String, title: String) -> void:
	_event_id = event_id
	_event_title = title
	open_modal(title.to_upper())


func refresh_content() -> void:
	clear_box(_content)
	clear_box(_footer)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(body, 20, 4)

	var note := Label.new()
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIStyles.apply_cartoon_label(note, 16, 3)
	note.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))

	match _event_id:
		"tournament":
			body.text = (
				"Local Tournament Preview\n\n"
				+ "Your best score: %d\n" % GameSettings.best_score
				+ "Season XP: %d\n\n" % GameSettings.reward_track_xp
				+ "Climb the local ladder by posting high scores.\n"
				+ "Rewards preview: coins & gems."
			)
			note.text = "Offline preview — no live online players."
		"treasure_hunt":
			body.text = (
				"Treasure Hunt\n\n"
				+ "Keys collected: %d\n" % GameSettings.total_keys
				+ "Milestones: 5 / 15 / 30 keys\n\n"
				+ "Swallow coins and key pickups in levels to advance."
			)
			note.text = "Progress uses your saved key total."
		"daily":
			var day_seed := _daily_seed()
			var need := 8 + (day_seed % 7)
			body.text = (
				"Daily Challenge\n\n"
				+ "Today's goal: collect %d mission items in one run.\n" % need
				+ "Reward preview: +50 coins\n\n"
				+ "Challenge resets with the calendar day."
			)
			note.text = "Local daily challenge — no internet required."
		"star":
			body.text = (
				"Star Event\n\n"
				+ "3-star clears: %d\n" % GameSettings.three_star_wins
				+ "Milestones: 1 / 5 / 15 three-star wins\n\n"
				+ "Finish levels with lots of time left for more stars."
			)
			note.text = "Uses your saved three-star win count."
		"coin_frenzy":
			body.text = (
				"Coin Frenzy\n\n"
				+ "Play with Double Coins for a frenzy boost.\n"
				+ "Owned Double Coins boosters: %d\n\n" % GameSettings.booster_double_coins
				+ "Select Double Coins on the level prep screen."
			)
			note.text = "Does not auto-spend coins. Uses existing booster stock."
		"special":
			body.text = (
				"Special Event\n\n"
				+ "Discover collectibles for the Collection album.\n"
				+ "Discovered fruits: %d\n\n" % GameSettings.discovered_fruit_ids.size()
				+ "Swallow new fruit images to unlock album pages."
			)
			note.text = "Local special objective — Collection progress."
		_:
			body.text = "Event preview"
			note.text = "Local preview"

	_content.add_child(body)
	_content.add_child(note)

	var play := Button.new()
	play.custom_minimum_size = Vector2(0, 64)
	play.text = "PLAY"
	UIStyles.style_primary_button(play, 28)
	play.pressed.connect(_on_play)
	_footer.add_child(play)


func _on_play() -> void:
	GameSettings.play_ui_click()
	play_requested.emit(_event_id)
	close_modal()


func _daily_seed() -> int:
	var dt := Time.get_datetime_dict_from_system()
	return int(dt.get("year", 2026)) * 372 + int(dt.get("month", 1)) * 31 + int(dt.get("day", 1))
