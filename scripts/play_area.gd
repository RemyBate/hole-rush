extends Node2D

var _bounds: Rect2 = Rect2()
var _theme: int = LevelTheme.Id.FRUIT_GARDEN


func setup(bounds: Rect2, theme: int = LevelTheme.Id.FRUIT_GARDEN) -> void:
	_bounds = bounds
	_theme = theme
	queue_redraw()


func _draw() -> void:
	if _bounds.size == Vector2.ZERO:
		return
	ThemeBackground.draw(self, _bounds, _theme)
