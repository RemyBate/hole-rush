extends CanvasLayer

## Autoload: smooth fades between home and gameplay.

var _rect: ColorRect = null
var _busy: bool = false


func _ready() -> void:
	layer = 120
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.color = Color(0.04, 0.1, 0.22, 1.0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate.a = 0.0
	add_child(rect)
	_rect = rect
	hide()


func fade_out(duration: float = 0.28) -> void:
	if _busy:
		return
	_busy = true
	show()
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_rect, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func fade_in(duration: float = 0.32) -> void:
	var tween := create_tween()
	tween.tween_property(_rect, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_finish_fade_in)


func _finish_fade_in() -> void:
	_busy = false
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()
