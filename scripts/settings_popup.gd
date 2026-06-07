class_name SettingsPopup
extends Control

signal opened
signal closed
signal save_progress_requested

const COLOR_CYAN := Color(0.22, 0.72, 0.95, 0.98)
const COLOR_CYAN_HI := Color(0.35, 0.82, 1.0, 0.98)
const COLOR_GREEN := Color(0.45, 0.82, 0.28, 0.98)
const COLOR_GREEN_HI := Color(0.55, 0.92, 0.35, 0.98)
const COLOR_SECTION := Color(0.12, 0.22, 0.4, 0.95)
const COLOR_SWITCH_ON := Color(0.42, 0.82, 0.32, 0.98)
const COLOR_SWITCH_OFF := Color(0.45, 0.48, 0.52, 0.98)

@onready var _dim: ColorRect = %Dim
@onready var _panel: PanelContainer = %Panel
@onready var _close_button: Button = %CloseButton
@onready var _music_button: Button = %MusicButton
@onready var _sound_button: Button = %SoundButton
@onready var _vibration_button: Button = %VibrationButton
@onready var _music_label: Label = %MusicLabel
@onready var _sound_label: Label = %SoundLabel
@onready var _vibration_label: Label = %VibrationLabel
@onready var _music_slash: Control = %MusicSlash
@onready var _sound_slash: Control = %SoundSlash
@onready var _vibration_slash: Control = %VibrationSlash
@onready var _notification_switch: Button = %NotificationSwitch
@onready var _notification_state_label: Label = %NotificationStateLabel
@onready var _notification_knob: Panel = %NotificationKnob
@onready var _inner_panel: PanelContainer = %InnerPanel
@onready var _toggle_section: PanelContainer = %ToggleSection
@onready var _notification_section: PanelContainer = %NotificationSection
@onready var _support_button: Button = %SupportButton
@onready var _save_button: Button = %SaveButton
@onready var _terms_button: Button = %TermsButton
@onready var _privacy_button: Button = %PrivacyButton
@onready var _info_popup: InfoPopup = %InfoPopup

var _open: bool = false


func _ready() -> void:
	hide()
	_panel.scale = Vector2(0.86, 0.86)
	_panel.modulate.a = 0.0
	_dim.modulate.a = 0.0
	_apply_ui_theme()
	_refresh_toggles()
	_dim.gui_input.connect(_on_dim_gui_input)

	_close_button.pressed.connect(_on_close_pressed)
	_music_button.pressed.connect(_on_music_pressed)
	_sound_button.pressed.connect(_on_sound_pressed)
	_vibration_button.pressed.connect(_on_vibration_pressed)
	_notification_switch.pressed.connect(_on_notification_pressed)
	_support_button.pressed.connect(_on_support_pressed)
	_save_button.pressed.connect(_on_save_pressed)
	_terms_button.pressed.connect(_on_terms_pressed)
	_privacy_button.pressed.connect(_on_privacy_pressed)
	GameSettings.settings_changed.connect(_refresh_toggles)


func open_popup() -> void:
	if _open:
		return
	show()
	_open = true
	_refresh_toggles()
	opened.emit()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_dim, "modulate:a", 1.0, 0.22)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.24)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close_popup() -> void:
	if not _open:
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_dim, "modulate:a", 0.0, 0.18)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.18)
	tween.tween_property(_panel, "scale", Vector2(0.88, 0.88), 0.18)
	tween.chain().tween_callback(_finish_close)


func _finish_close() -> void:
	_open = false
	hide()
	closed.emit()


func _refresh_toggles() -> void:
	_music_slash.visible = not GameSettings.music_enabled
	_sound_slash.visible = not GameSettings.sound_enabled
	_vibration_slash.visible = not GameSettings.vibration_enabled
	_update_notification_switch_visual()


func _update_notification_switch_visual() -> void:
	var on := GameSettings.notifications_enabled
	_notification_state_label.text = "On" if on else "Off"

	var track := _make_glossy_style(COLOR_SWITCH_ON if on else COLOR_SWITCH_OFF, 20)
	_notification_switch.add_theme_stylebox_override("normal", track)
	_notification_switch.add_theme_stylebox_override("hover", track.duplicate())
	_notification_switch.add_theme_stylebox_override("pressed", track.duplicate())

	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(0.88, 0.9, 0.94, 0.98)
	knob_style.set_corner_radius_all(16)
	knob_style.border_color = Color(1.0, 1.0, 1.0, 0.5)
	knob_style.set_border_width_all(2)
	knob_style.shadow_size = 3
	knob_style.shadow_offset = Vector2(0, 2)
	_notification_knob.add_theme_stylebox_override("panel", knob_style)

	_notification_knob.offset_left = 108.0 if on else 8.0
	_notification_knob.offset_right = _notification_knob.offset_left + 52.0
	_notification_knob.offset_top = 8.0
	_notification_knob.offset_bottom = 56.0

	var text_color := Color(0.12, 0.28, 0.1, 1.0) if on else Color(0.92, 0.94, 0.96, 1.0)
	_notification_state_label.add_theme_color_override("font_color", text_color)
	_notification_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if on else HORIZONTAL_ALIGNMENT_RIGHT
	_notification_state_label.offset_left = 16.0 if on else 8.0
	_notification_state_label.offset_right = -72.0 if on else -16.0


func _apply_ui_theme() -> void:
	var outer := _make_glossy_style(Color(0.16, 0.38, 0.78, 0.98), 26)
	outer.shadow_size = 12
	_panel.add_theme_stylebox_override("panel", outer)

	var inner := _make_glossy_style(Color(0.1, 0.16, 0.32, 0.98), 22)
	_inner_panel.add_theme_stylebox_override("panel", inner)

	_toggle_section.add_theme_stylebox_override("panel", _make_glossy_style(COLOR_SECTION, 18))
	_notification_section.add_theme_stylebox_override("panel", _make_glossy_style(COLOR_SECTION, 18))

	for label in [_music_label, _sound_label, _vibration_label]:
		_style_cartoon_label(label, 24)

	_style_cartoon_label(%NotificationLabel, 28)

	var cyan := _make_glossy_style(COLOR_CYAN, 16)
	for btn in [_music_button, _sound_button, _vibration_button]:
		btn.add_theme_stylebox_override("normal", cyan.duplicate())
		btn.add_theme_stylebox_override("hover", cyan.duplicate())
		btn.add_theme_stylebox_override("pressed", cyan.duplicate())
		(btn.get_theme_stylebox("hover") as StyleBoxFlat).bg_color = COLOR_CYAN_HI
		(btn.get_theme_stylebox("pressed") as StyleBoxFlat).bg_color = Color(0.18, 0.55, 0.82)
		UIStyles.bind_button(btn)

	UIStyles.style_action_button(_support_button, Color(0.18, 0.7, 0.94, 0.98), COLOR_CYAN_HI, 30)
	UIStyles.style_action_button(_save_button, Color(0.38, 0.78, 0.28, 0.98), COLOR_GREEN_HI, 30)

	var legal := _make_glossy_style(COLOR_GREEN, 16)
	for btn in [_terms_button, _privacy_button]:
		btn.add_theme_stylebox_override("normal", legal.duplicate())
		btn.add_theme_stylebox_override("hover", legal.duplicate())
		btn.add_theme_stylebox_override("pressed", legal.duplicate())
		(btn.get_theme_stylebox("hover") as StyleBoxFlat).bg_color = COLOR_GREEN_HI
		_style_cartoon_label(btn, 22)
		UIStyles.bind_button(btn)

	UIStyles.style_action_button(_close_button, Color(0.9, 0.24, 0.3, 0.98), Color(1.0, 0.45, 0.5), 28)
	UIStyles.bind_button(_notification_switch)


func _style_cartoon_label(label: Control, font_size: int) -> void:
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.1, 0.2, 0.95))
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_font_size_override("font_size", font_size)


func show_info_message(title: String, message: String) -> void:
	_info_popup.open(title, message)


func _make_glossy_style(bg: Color, corner: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(corner)
	s.border_color = Color(1.0, 1.0, 1.0, 0.38)
	s.set_border_width_all(3)
	s.shadow_color = Color(0.02, 0.06, 0.14, 0.5)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 4)
	# Gloss highlight along top edge.
	s.draw_center = true
	return s


func _on_close_pressed() -> void:
	GameSettings.play_ui_click()
	close_popup()


func _on_music_pressed() -> void:
	GameSettings.play_ui_click()
	GameSettings.set_music_enabled(not GameSettings.music_enabled)
	_refresh_toggles()


func _on_sound_pressed() -> void:
	GameSettings.set_sound_enabled(not GameSettings.sound_enabled)
	GameSettings.play_ui_click()
	_refresh_toggles()


func _on_vibration_pressed() -> void:
	GameSettings.set_vibration_enabled(not GameSettings.vibration_enabled)
	GameSettings.vibrate(50)
	_refresh_toggles()


func _on_notification_pressed() -> void:
	GameSettings.play_ui_click()
	GameSettings.set_notifications_enabled(not GameSettings.notifications_enabled)
	_refresh_toggles()


func _on_support_pressed() -> void:
	GameSettings.play_ui_click()
	_info_popup.open(
		"Support",
		(
			"Need help with Hole Rush?\n\n"
			+ "Email: %s\n\n"
			+ "Include your device model and a short description of the issue. "
			+ "We usually reply within 24 hours."
		) % GameConstants.SUPPORT_EMAIL
	)


func _on_save_pressed() -> void:
	GameSettings.play_ui_click()
	GameSettings.vibrate(35)
	save_progress_requested.emit()


func _on_terms_pressed() -> void:
	GameSettings.play_ui_click()
	_info_popup.open(
		"Terms of Service",
		(
			"Hole Rush — Terms of Service\n"
			+ "Last updated: %s\n\n"
			+ "By downloading or playing Hole Rush, you agree to these terms.\n\n"
			+ "• Hole Rush is a free offline arcade game for personal entertainment.\n"
			+ "• Game progress and settings are stored locally on your device.\n"
			+ "• Do not reverse engineer, cheat, or misuse the app.\n"
			+ "• The game is provided \"as is\" without warranties.\n"
			+ "• We may update the app and these terms from time to time.\n\n"
			+ "Questions: %s"
		) % [GameConstants.LEGAL_LAST_UPDATED, GameConstants.SUPPORT_EMAIL]
	)


func _on_privacy_pressed() -> void:
	GameSettings.play_ui_click()
	if OS.shell_open(GameConstants.PRIVACY_POLICY_URL) == OK:
		return
	_info_popup.open(
		"Privacy Policy",
		(
			"Hole Rush — Privacy Policy\n"
			+ "Last updated: %s\n\n"
			+ "• Progress and settings are saved locally on your device.\n"
			+ "• We do not require an account.\n"
			+ "• We do not show ads or sell your data.\n"
			+ "• We do not collect location, contacts, or payment info.\n"
			+ "• Optional vibration is used for haptic feedback.\n"
			+ "• Uninstalling the app removes local save data.\n\n"
			+ "Full policy:\n%s\n\n"
			+ "Contact: %s"
		) % [GameConstants.LEGAL_LAST_UPDATED, GameConstants.PRIVACY_POLICY_URL, GameConstants.SUPPORT_EMAIL]
	)


func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_close_pressed()
