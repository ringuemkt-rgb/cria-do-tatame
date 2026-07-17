extends RefCounted
class_name CriaVisualTheme

const BLACK := Color("0a0a0a")
const MATTE := Color("1a1a1a")
const GOLD := Color("b8860b")
const HONOR := Color("f2c230")
const OFF_WHITE := Color("f2f2f2")
const CONFLICT := Color("d92323")
const RIVER := Color("1e3a5f")
const MANGROVE := Color("2d5016")
const SHADOW := Color("4b0082")
const CYAN := Color("20a9c9")

static func panel_style(alpha: float = 0.94, border_color: Color = GOLD, border_width: int = 2, radius: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(MATTE, alpha)
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	style.shadow_color = Color(0, 0, 0, 0.48)
	style.shadow_size = 10
	return style

static func button_style(background: Color, border: Color, radius: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style

static func apply_primary_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", button_style(Color("171717"), GOLD))
	button.add_theme_stylebox_override("hover", button_style(Color("2a2415"), HONOR))
	button.add_theme_stylebox_override("pressed", button_style(Color("3b2d08"), HONOR))
	button.add_theme_stylebox_override("disabled", button_style(Color("101010"), Color("4a4230")))
	button.add_theme_color_override("font_color", OFF_WHITE)
	button.add_theme_color_override("font_hover_color", HONOR)
	button.add_theme_color_override("font_pressed_color", OFF_WHITE)
	button.add_theme_color_override("font_disabled_color", Color("77736a"))
	button.add_theme_font_size_override("font_size", 18)
	button.focus_mode = Control.FOCUS_ALL

static func apply_action_button(button: Button, accent: Color = GOLD) -> void:
	button.add_theme_stylebox_override("normal", button_style(Color("11151a"), Color(accent, 0.72), 10))
	button.add_theme_stylebox_override("hover", button_style(Color("24200f"), HONOR, 10))
	button.add_theme_stylebox_override("pressed", button_style(Color("3a2b08"), HONOR, 10))
	button.add_theme_stylebox_override("disabled", button_style(Color("0c0d0f"), Color("3b3b3b"), 10))
	button.add_theme_color_override("font_color", OFF_WHITE)
	button.add_theme_color_override("font_hover_color", HONOR)
	button.add_theme_color_override("font_disabled_color", Color("676767"))
	button.add_theme_font_size_override("font_size", 15)

static func style_progress(bar: ProgressBar, fill_color: Color) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color("08090b")
	background.border_color = Color("4b4230")
	background.set_border_width_all(1)
	background.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_color_override("font_color", OFF_WHITE)
	bar.add_theme_font_size_override("font_size", 11)
	bar.show_percentage = true

static func style_heading(label: Label, size: int = 28, color: Color = HONOR) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_font_size_override("font_size", size)

