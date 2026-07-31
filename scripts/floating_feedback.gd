class_name FloatingFeedback
extends Node2D

const DURATION: float = 1.1

var _text: String = ""
var _color: Color = Color.WHITE
var _elapsed: float = 0.0
var _float_offset: float = 0.0


static func spawn_text(parent: Node, world_position: Vector2, text: String, color: Color) -> void:
	if parent == null:
		return
	var fb := FloatingFeedback.new()
	fb._text = text
	fb._color = color
	fb.global_position = world_position
	fb.z_index = 80
	parent.add_child(fb)


static func spawn_coin_pop(parent: Node, world_position: Vector2, amount: int = 1) -> void:
	spawn_text(
		parent,
		world_position,
		"+%d" % amount,
		Color(1.0, 0.92, 0.28, 1.0)
	)


func _process(delta: float) -> void:
	_elapsed += delta
	_float_offset -= 42.0 * delta
	if _elapsed >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := clampf(_elapsed / DURATION, 0.0, 1.0)
	var alpha := 1.0 - t * t
	var font: Font = ThemeDB.fallback_font
	var font_size := 18 if _text.begins_with("+") else 15
	var text_size := font.get_string_size(_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var pos := Vector2(-text_size.x * 0.5, _float_offset - 8.0)

	var bg := Rect2(pos - Vector2(6.0, 4.0), text_size + Vector2(12.0, 8.0))
	draw_rect(bg, Color(0.05, 0.08, 0.14, 0.72 * alpha), true)

	var c := _color
	c.a = alpha
	draw_string(font, pos, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, c)
