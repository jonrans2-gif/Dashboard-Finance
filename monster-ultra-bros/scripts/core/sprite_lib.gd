class_name SpriteLib
## Builds (and caches) SpriteFrames from the generated sprite sheets.
## Each sheet `assets/sprites/<name>.png` has a `<name>.json` describing
## frame size, column count and animations.

static var _cache: Dictionary = {}
static var _textures: Dictionary = {}


static func frames(sheet: String) -> SpriteFrames:
	if _cache.has(sheet):
		return _cache[sheet]
	var base := "res://assets/sprites/%s" % sheet
	if sheet.begins_with("ui/"):
		base = "res://assets/%s" % sheet
	var tex: Texture2D = load(base + ".png")
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base + ".json"))
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var fw := int(meta.frame_w)
	var fh := int(meta.frame_h)
	var cols := int(meta.cols)
	for anim_name in meta.animations.keys():
		var a: Dictionary = meta.animations[anim_name]
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, float(a.fps))
		sf.set_animation_loop(anim_name, bool(a.loop))
		for idx in a.frames:
			var at := AtlasTexture.new()
			at.atlas = tex
			var i := int(idx)
			at.region = Rect2((i % cols) * fw, (i / cols) * fh, fw, fh)
			sf.add_frame(anim_name, at)
	_cache[sheet] = sf
	return sf


static func texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path)
	return _textures[path]


## Single frame of an animation as a texture (for icons).
static func frame_texture(sheet: String, anim: String, index := 0) -> Texture2D:
	return frames(sheet).get_frame_texture(anim, index)


static func make_sprite(sheet: String, anim: String, centered := true) -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = frames(sheet)
	s.centered = centered
	s.play(anim)
	return s
