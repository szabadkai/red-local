extends Node2D
const SHEET = preload("res://Assets/Pixel_Playing_Card_Set_YEWBI.png")
var card_id := 0
var slot := 0
var target := Vector2.ZERO
var clock := 0.0
var highlighted := false
var departing := false

func _process(delta: float) -> void:
	if departing:
		return
	clock += delta
	var wiggle := sin(clock * 2.3 + card_id) * 0.025
	# Occasional bigger, individual wiggles echo the original bouncing hand.
	var pulse := pow(maxf(0.0, sin(clock * 1.5 + slot * 1.7)), 12.0)
	rotation = (slot - 2) * 0.035 + wiggle + sin(clock * 19.0) * pulse * 0.10
	var lift := -8.0 if highlighted else 0.0
	position = position.lerp(target + Vector2(0, sin(clock * 2.0 + slot) * 2 + lift), 1 - exp(-delta * 14))
	queue_redraw()

func _draw() -> void:
	if highlighted:
		draw_style_box(_border(), Rect2(-33, -49, 66, 98))
	var rank := card_id % 13 + 2
	if rank == 14:
		rank = 1
	var suit := int(card_id / 13)
	# Sprite sheet suit order: spades, diamonds, clubs, hearts.
	var region := Rect2(32 + (int((rank - 1) / 3) * 4 + suit) * 32, 32 + ((rank - 1) % 3) * 48, 32, 48)
	draw_texture_rect_region(SHEET, Rect2(-32, -48, 64, 96), region)

func _border() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("e5bb70")
	box.shadow_color = Color(0.9, 0.6, 0.2, 0.25)
	box.shadow_size = 5
	return box

func fly_out() -> void:
	departing = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(90, -120), 0.25).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "rotation", 0.65, 0.25)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)
