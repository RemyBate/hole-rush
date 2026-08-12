class_name SafeViewportCapture
extends RefCounted

## Viewport texture capture that does not fail headless/dummy renderers.


static func is_headless() -> bool:
	return String(DisplayServer.get_name()).to_lower().contains("headless")


static func save_png(viewport: Viewport, path: String, tag: String = "CAPTURE") -> bool:
	if viewport == null:
		push_error("[%s] missing viewport for %s" % [tag, path])
		return false
	if is_headless():
		print("[%s] skip headless screenshot %s" % [tag, path])
		return true
	RenderingServer.force_draw()
	var tex := viewport.get_texture()
	if tex == null:
		push_error("[%s] viewport texture null for %s" % [tag, path])
		return false
	var img: Image = tex.get_image()
	if img == null:
		push_error("[%s] no image for %s" % [tag, path])
		return false
	var err := img.save_png(path)
	if err != OK:
		push_error("[%s] save_png failed %s err=%s" % [tag, path, err])
		return false
	print("[%s] screenshot=%s" % [tag, path])
	return true
