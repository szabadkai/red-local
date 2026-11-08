extends Node2D
## Standalone combat sandbox. World coordinates are a 640 x 450 pixel canvas.
const Deck = preload("res://Scripts/Poker/PokerDeck.gd")
const Hand = preload("res://Scripts/Poker/PokerHand.gd")
const CardView = preload("res://Scripts/Poker/PokerCard.gd")
const ORC = preload("res://Assets/0x72_DungeonTilesetII_v1.6.png")
const FLOOR := 322.0
const GOLD = Color("e5bb70")
const VIOLET = Color("ca95ff")
const EFFECTS = ["Bolt", "Heavy bolt", "Explosion", "Piercing lance", "Piercing beam",
	"Dark wave", "Twin dark waves", "Royal burst", "Royal burst + wave"]
const INK = Color("0a121c")
var deck = Deck.new()
var views: Dictionary = {}
var player := Vector2(180, FLOOR)
var velocity := Vector2.ZERO
var facing := 1.0
var health := 5
var enemies: Array = []
var particles: Array = []
var bolts: Array = []
var elapsed := 0.0
var sword_cd := 0.0
var cast_cd := 0.0
var hurt_cd := 0.0
var slash := 0.0
var spawn_cd := 0.0
var kills := 0
var notice := "Collect 3 embers and reach the lantern. Sword hits earn cards; K plays them."
var notice_time := 6.0
var paused := false
var motion := true
var frames: Array = []
var idle: Texture2D
var previous_size: Vector2i
var previous_aspect: int
var font: Font
var dark_time := 0.0
var transform_time := 0.0
var dark_frames: Array = []
var transform_frames: Array = []
var fx_frames: Array = []
var dark_idle: Texture2D
var rings: Array = []
var numbers: Array = []
var next_enemy_id := 0
var banner := ""
var banner_time := 0.0
var muted := false
var sounds: Dictionary = {}
var animations: Dictionary = {}
var platforms: Array = []
var embers: Array = []
var collected := 0
var completed := false
var practice := false
var grounded := true
var coyote := 0.1
var jump_buffer := 0.0
var drop_time := 0.0
var land_time := 0.0
var attack_time := 0.0
var cast_time := 0.0
var animation_clock := 0.0
var animation_state := "idle_blink"
const EXIT = Vector2(601, 166)
const ORC_FRAMES = [22, 54, 86, 150, 182, 214, 246]

func _ready() -> void:
	previous_size = get_window().content_scale_size
	previous_aspect = get_window().content_scale_aspect
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	get_window().content_scale_size = Vector2i(640, 450)
	font = ThemeDB.fallback_font
	idle = load("res://Assets/Light/idle_blink/idle_blink0.png")
	for i in range(10):
		frames.append(load("res://Assets/Light/run/run%d.png" % i))
	dark_idle = load("res://Assets/Dark/idle_blink/idle_blink0.png")
	for i in range(10):
		dark_frames.append(load("res://Assets/Dark/run/run%d.png" % i))
	for i in range(100):
		var path := "res://Assets/Light/transform/transform%d.png" % i
		if not ResourceLoader.exists(path):
			break
		transform_frames.append(load(path))
	for i in range(100):
		var path := "res://Assets/Dark/FX_dark/FX_dark%d.png" % i
		if not ResourceLoader.exists(path):
			break
		fx_frames.append(load(path))
	for sound in ["attack1", "attack3", "transform_dark", "meter_full"]:
		var path := "res://ridingHood-web/public/assets/audio/sfx/%s.ogg" % sound
		var stream := AudioStreamOggVorbis.load_from_file(path)
		if stream:
			var audio := AudioStreamPlayer.new()
			audio.stream = stream
			audio.volume_db = -14
			add_child(audio)
			sounds[sound] = audio
	for form in ["Light", "Dark"]:
		animations[form] = {}
		for state in ["idle_blink", "run", "jump", "fall", "attack1", "attack3"]:
			var clips: Array = []
			for i in range(40):
				var prefix: String = state + ("_" if state.begins_with("attack") else "")
				var index_text := "%02d" % i if form == "Light" and state == "attack3" else str(i)
				var path := "res://Assets/%s/%s/%s%s.png" % [form, state, prefix, index_text]
				if ResourceLoader.exists(path):
					clips.append(load(path))
			if clips.is_empty():
				clips.append(idle if form == "Light" else dark_idle)
			animations[form][state] = clips
	restart()

func play_sound(sound: String) -> void:
	if not muted and sounds.has(sound):
		sounds[sound].play()

func _exit_tree() -> void:
	for sound in sounds.values():
		sound.stop()
	get_window().content_scale_size = previous_size
	get_window().content_scale_aspect = previous_aspect

func restart() -> void:
	deck.reset()
	for view in views.values():
		view.queue_free()
	views.clear()
	player = Vector2(35, FLOOR)
	velocity = Vector2.ZERO
	health = 5
	kills = 0
	completed = false
	practice = false
	grounded = true
	coyote = 0.1
	jump_buffer = 0
	drop_time = 0
	land_time = 0
	attack_time = 0
	cast_time = 0
	animation_clock = 0
	animation_state = "idle_blink"
	collected = 0
	platforms = [Rect2(55, 270, 100, 12), Rect2(175, 218, 105, 12),
		Rect2(300, 166, 100, 12), Rect2(425, 218, 95, 12), Rect2(540, 166, 90, 12)]
	embers = [Vector2(105, 252), Vector2(350, 148), Vector2(570, 148)]
	enemies.clear()
	bolts.clear()
	particles.clear()
	rings.clear()
	numbers.clear()
	dark_time = 0
	transform_time = 0
	banner_time = 0
	next_enemy_id = 0
	sword_cd = 0
	cast_cd = 0
	hurt_cd = 0
	spawn_cd = 1.5
	paused = false
	notice = "Collect 3 embers and reach the lantern. Sword hits earn cards; K plays them."
	notice_time = 6.0
	spawn_enemy(365)
	spawn_enemy(225, 218, 187, 268)
	spawn_enemy(580, 166, 552, 616)
	sync_cards()

func spawn_enemy(x: float, y: float = FLOOR, left: float = 24, right: float = 616) -> void:
	var tough := next_enemy_id % 3 == 2
	var hp := 56 if tough else 14
	enemies.append({"id": next_enemy_id, "x": x, "hp": hp, "max_hp": hp,
		"attack": 0.0, "stun": 0.4, "flash": 0.0, "tough": tough,
		"y": y, "left": left, "right": right, "walk": 0.0, "facing": -1.0})
	next_enemy_id += 1

func sync_cards() -> void:
	for id in views.keys():
		if not deck.hand.has(id):
			views[id].fly_out()
			views.erase(id)
	var combo: Dictionary = Hand.evaluate(deck.hand)
	for i in range(deck.hand.size()):
		var id: int = deck.hand[i]
		if not views.has(id):
			var card = CardView.new()
			card.card_id = id
			card.position = Vector2(650, 480)
			add_child(card)
			views[id] = card
		var view = views[id]
		view.slot = i
		view.target = Vector2(182 + i * 69, 421)
		view.highlighted = combo.indices.has(i)
		view.z_index = 10 + i
		view.set_process(motion and not paused and health > 0 and not completed)
		if not motion:
			view.position = view.target + Vector2(0, -8 if view.highlighted else 0)
			view.rotation = 0
		view.queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_ESCAPE:
			get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
		KEY_R:
			restart()
		KEY_P:
			paused = not paused
			sync_cards()
		KEY_N:
			muted = not muted
			if muted:
				for sound in sounds.values():
					sound.stop()
		KEY_M:
			motion = not motion
			sync_cards()
	if paused or health <= 0 or completed:
		return
	match event.physical_keycode:
		KEY_F1, KEY_F2, KEY_F3:
			practice_hand(event.physical_keycode - KEY_F1)
		KEY_SPACE:
			jump_buffer = 0.12
			try_jump()
		KEY_S, KEY_DOWN:
			if grounded and player.y < FLOOR:
				drop_time = 0.2
				grounded = false
				coyote = 0
				player.y += 2
		KEY_J:
			sword_attack()
		KEY_K:
			poker_attack()
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
			if deck.replace_card(event.physical_keycode - KEY_1):
				announce("Banked draw spent: replaced one card.")
				sync_cards()

func practice_hand(kind: int) -> void:
	# Explicit sandbox tools: reset every card location so no duplicate IDs are introduced.
	restart()
	practice = true
	platforms.clear()
	embers.clear()
	player = Vector2(180, FLOOR)
	var presets := [[5, 18, 2, 9, 24], [0, 2, 5, 8, 11], [5, 18, 31, 44, 8]]
	deck.hand = presets[kind].duplicate()
	deck.pile.clear()
	deck.discard.clear()
	for card in range(52):
		if not deck.hand.has(card):
			deck.pile.append(card)
	deck.pile.shuffle()
	enemies.clear()
	for x in [260, 340, 420]:
		spawn_enemy(x)
	announce("PRACTICE DEAL · %s · press K" % Hand.evaluate(deck.hand).name)
	sync_cards()

func announce(message: String) -> void:
	notice = message
	notice_time = 3.0

func sword_attack() -> void:
	if sword_cd > 0:
		return
	sword_cd = 0.20
	slash = 0.16
	attack_time = 0.20
	play_sound("attack1")
	var landed := false
	for enemy in enemies:
		var distance: float = (enemy.x - player.x) * facing
		if distance >= -8 and distance < 66 and absf(player.y - enemy.y) < 43:
			damage_enemy(enemy, 4 if dark_time > 0 else 2, facing * 8)
			landed = true
	# A swing grants one hit credit, regardless of the number of targets.
	if landed:
		if deck.register_hit():
			play_sound("meter_full")
			announce("Draw banked! 1–5 replaces a card." if deck.banked else "Three hits — new card dealt!")
		sync_cards()
	remove_dead()

func poker_attack() -> void:
	if cast_cd > 0 or deck.hand.is_empty():
		return
	var result: Dictionary = deck.play()
	cast_cd = 0.4
	cast_time = 0.3
	var tier: int = result.tier
	banner = result.name.to_upper()
	banner_time = 1.1
	play_sound("attack3")
	if tier >= 5:
		dark_time = 6.0
		transform_time = 0.75
		hurt_cd = maxf(hurt_cd, 0.75)
		play_sound("transform_dark")
	if tier >= 7:
		blast(player + Vector2(0, -22), 270, result.damage, VIOLET)
	if tier < 7 or tier == 8:
		fire_bolt(result, facing)
	if tier == 6:
		fire_bolt(result, -facing)
	announce("%s · %d damage%s" % [EFFECTS[tier], result.damage,
		" · DARK RED: 6 seconds" if tier >= 5 else ""])
	remove_dead()
	sync_cards()

func fire_bolt(result: Dictionary, direction: float) -> void:
	bolts.append({"p": player + Vector2(direction * 20, -23), "dir": direction,
		"damage": result.damage, "life": 1.2, "tier": result.tier, "hit": []})

func blast(center: Vector2, radius: float, damage: int, color: Color) -> void:
	rings.append({"p": center, "radius": radius, "life": 0.45, "color": color})
	for enemy in enemies:
		if Vector2(enemy.x, enemy.y - 22).distance_to(center) <= radius:
			var direction := signf(enemy.x - center.x)
			damage_enemy(enemy, damage, direction * 40)

func damage_enemy(enemy: Dictionary, amount: int, push: float) -> void:
	enemy.hp -= amount
	enemy.x = clampf(enemy.x + push, enemy.left, enemy.right)
	enemy.stun = 0.25
	enemy.attack = 0.0
	enemy.flash = 0.15
	numbers.append({"p": Vector2(enemy.x - 8, enemy.y - 58), "text": str(amount), "life": 0.65})
	for i in range(8):
		particles.append({"p": Vector2(enemy.x, enemy.y - 22),
			"v": Vector2(randf_range(-65, 65), randf_range(-100, -20)), "life": 0.45})

func remove_dead() -> void:
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].hp <= 0:
			enemies.remove_at(i)
			kills += 1

func try_jump() -> void:
	if jump_buffer > 0 and (grounded or coyote > 0):
		velocity.y = -320
		grounded = false
		coyote = 0
		jump_buffer = 0

func move_player(delta: float) -> void:
	jump_buffer = maxf(0, jump_buffer - delta)
	drop_time = maxf(0, drop_time - delta)
	coyote = 0.1 if grounded else maxf(0, coyote - delta)
	try_jump()
	var previous := player
	velocity.y += 850 * delta
	player += velocity * delta
	player.x = clampf(player.x, 18, 622)
	var surface := FLOOR
	if velocity.y >= 0 and drop_time <= 0:
		for platform in platforms:
			if player.x + 9 > platform.position.x and player.x - 9 < platform.end.x:
				if previous.y <= platform.position.y + 0.5 and player.y >= platform.position.y:
					surface = minf(surface, platform.position.y)
	var was_grounded := grounded
	grounded = velocity.y >= 0 and player.y >= surface
	if grounded:
		player.y = surface
		velocity.y = 0
		if not was_grounded:
			land_time = 0.12
		try_jump()
	for i in range(embers.size() - 1, -1, -1):
		if (player + Vector2(0, -18)).distance_to(embers[i]) < 24:
			embers.remove_at(i)
			collected += 1
			play_sound("meter_full")
			announce("Forest embers %d / 3 · carry them to the lantern" % collected)
	if not practice and collected == 3 and player.distance_to(EXIT) < 25:
		completed = true
		announce("The lantern is lit. The clearing is yours.")
		sync_cards()

func update_animation(delta: float) -> void:
	var state := "idle_blink"
	if attack_time > 0:
		state = "attack1"
	elif cast_time > 0:
		state = "attack3"
	elif not grounded:
		state = "jump" if velocity.y < 0 else "fall"
	elif absf(velocity.x) > 10:
		state = "run"
	if state != animation_state:
		animation_state = state
		animation_clock = 0
	else:
		animation_clock += delta

func _physics_process(delta: float) -> void:
	if paused or health <= 0 or completed:
		queue_redraw()
		return
	elapsed += delta
	attack_time = maxf(0, attack_time - delta)
	cast_time = maxf(0, cast_time - delta)
	land_time = maxf(0, land_time - delta)
	dark_time = maxf(0, dark_time - delta)
	transform_time = maxf(0, transform_time - delta)
	banner_time = maxf(0, banner_time - delta)
	for i in range(rings.size() - 1, -1, -1):
		rings[i].life -= delta
		if rings[i].life <= 0:
			rings.remove_at(i)
	for i in range(numbers.size() - 1, -1, -1):
		numbers[i].p.y -= 30 * delta
		numbers[i].life -= delta
		if numbers[i].life <= 0:
			numbers.remove_at(i)
	sword_cd = maxf(0, sword_cd - delta)
	cast_cd = maxf(0, cast_cd - delta)
	hurt_cd = maxf(0, hurt_cd - delta)
	slash = maxf(0, slash - delta)
	notice_time -= delta
	var axis := float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))
	axis -= float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	var speed := 230 if dark_time > 0 else 195
	velocity.x = move_toward(velocity.x, axis * speed, delta * 1600)
	if axis != 0:
		facing = axis
	if Input.is_physical_key_pressed(KEY_J):
		sword_attack()
	move_player(delta)
	update_animation(delta)
	if completed:
		queue_redraw()
		return
	for enemy in enemies:
		enemy.stun = maxf(0, enemy.stun - delta)
		enemy.flash = maxf(0, enemy.flash - delta)
		var distance: float = player.x - enemy.x
		if enemy.stun > 0:
			continue
		if enemy.attack > 0:
			enemy.attack -= delta
			if enemy.attack <= 0 and absf(distance) < 43 and absf(player.y - enemy.y) < 32 and hurt_cd <= 0:
				health -= 1
				hurt_cd = 1.0
				player.x = clampf(player.x + signf(distance) * 25, 18, 622)
				if health <= 0:
					sync_cards()
			if enemy.attack <= 0:
				enemy.stun = 0.6
		elif absf(distance) < 32 and absf(player.y - enemy.y) < 40:
			enemy.attack = 0.55
		else:
			var old_x: float = enemy.x
			enemy.x = clampf(enemy.x + signf(distance) * (42 if enemy.tough else 57) * delta,
				enemy.left, enemy.right)
			if absf(enemy.x - old_x) > 0.1:
				enemy.walk += delta
				enemy.facing = signf(distance)
	for i in range(bolts.size() - 1, -1, -1):
		var bolt: Dictionary = bolts[i]
		var old_x: float = bolt.p.x
		bolt.p.x += bolt.dir * 600 * delta
		bolt.life -= delta
		for enemy in enemies:
			var in_sweep: bool = enemy.x >= minf(old_x, bolt.p.x) - 24
			in_sweep = in_sweep and enemy.x <= maxf(old_x, bolt.p.x) + 24
			var reach := 65 if bolt.tier >= 5 else 30
			if not in_sweep or absf(enemy.y - 23 - bolt.p.y) >= reach or bolt.hit.has(enemy.id):
				continue
			bolt.hit.append(enemy.id)
			if bolt.tier == 2:
				blast(Vector2(enemy.x, enemy.y - 22), 100, bolt.damage, GOLD)
			else:
				damage_enemy(enemy, bolt.damage, bolt.dir * (30 + bolt.tier * 5))
			if bolt.tier < 3:
				bolt.life = 0
				break
		if bolt.life <= 0:
			bolts.remove_at(i)
	remove_dead()
	spawn_cd -= delta
	if spawn_cd <= 0 and enemies.size() < 5:
		spawn_enemy(580 if player.x < 320 else 60)
		spawn_cd = 2.2
	for i in range(particles.size() - 1, -1, -1):
		particles[i].p += particles[i].v * delta
		particles[i].v.y += 200 * delta
		particles[i].life -= delta
		if particles[i].life <= 0:
			particles.remove_at(i)
	queue_redraw()

func label_at(pos: Vector2, text: String, color := Color("c3c8c5"), size := 12) -> void:
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 450), INK)
	# Quiet silhouettes keep the card hand and combat legible.
	for i in range(13):
		var x := float(i * 57 - 20)
		draw_rect(Rect2(x, 65 + i % 3 * 17, 9, 260), Color("14222a"))
		draw_line(Vector2(x + 4, 125), Vector2(x - 18, 95), Color("14222a"), 5)
		draw_line(Vector2(x + 4, 145), Vector2(x + 28, 110), Color("14222a"), 4)
	draw_circle(Vector2(520, 78), 22, Color("354544"))
	label_at(Vector2(20, 24), "RED / THE GAMBLER'S CLEARING", GOLD, 16)
	label_at(Vector2(20, 43), "A/D move   SPACE jump  S drop  HOLD J sword   K poker attack", Color("a7b5b7"), 12)
	label_at(Vector2(20, 61), "R restart   P pause   M motion   N sound   ESC menu", Color("718b90"), 11)
	label_at(Vector2(475, 24), "HEALTH %d/5   KOs %d" % [health, kills], GOLD, 12)
	draw_rect(Rect2(0, FLOOR, 640, 20), Color("263832"))
	draw_rect(Rect2(0, FLOOR, 640, 3), Color("76935e"))
	for i in range(40):
		draw_rect(Rect2(i * 17, FLOOR + 8 + i % 2 * 6, 11, 3), Color("354b40"))
	for platform in platforms:
		draw_rect(platform, Color("344a46"))
		draw_rect(Rect2(platform.position, Vector2(platform.size.x, 3)), Color("86a25d"))
		for x in range(int(platform.position.x) + 4, int(platform.end.x), 16):
			draw_rect(Rect2(x, platform.position.y + 5, 10, 4), Color("50635b"))
			draw_line(Vector2(x, platform.position.y + 12), Vector2(x - 3, platform.position.y + 20),
				Color("304b3e"), 2)
	for enemy in enemies:
		var tint := Color.WHITE
		if enemy.flash > 0:
			tint = GOLD
		elif enemy.attack > 0:
			tint = Color("ff7964")
		var body := Rect2(enemy.x - 22, enemy.y - 60, 44, 60) if enemy.tough else Rect2(enemy.x - 17, enemy.y - 48, 34, 48)
		var frame_x: int = ORC_FRAMES[int(enemy.walk * 10) % ORC_FRAMES.size()]
		if enemy.attack > 0:
			body.position.x += sin(enemy.attack * 35) * 2
		draw_set_transform(Vector2(enemy.x, 0), 0, Vector2(enemy.facing, 1))
		body.position.x -= enemy.x
		draw_texture_rect_region(ORC, body, Rect2(frame_x, 386, 21, 30), tint)
		draw_set_transform(Vector2.ZERO)
		draw_rect(Rect2(enemy.x - 16, enemy.y - 54, 32, 3), Color("382d35"))
		draw_rect(Rect2(enemy.x - 16, enemy.y - 54, 32 * maxf(0, enemy.hp) / enemy.max_hp, 3), Color("bd766b"))
		if enemy.attack > 0:
			label_at(Vector2(enemy.x - 3, enemy.y - 60), "!", Color("ff7964"), 17)
	for ember in embers:
		var at: Vector2 = ember + Vector2(0, sin(elapsed * 4 + ember.x) * 3)
		draw_circle(at, 9, Color(1, 0.7, 0.3, 0.15))
		draw_circle(at, 4, GOLD)
	if not practice:
		draw_line(EXIT, EXIT + Vector2(0, -40), Color("819077"), 3)
		draw_rect(Rect2(EXIT + Vector2(-7, -42), Vector2(14, 18)), GOLD if collected == 3 else Color("53616b"))
		label_at(Vector2(390, 62), "EMBERS %d/3 → LANTERN" % collected, GOLD, 11)
	var form := "Dark" if dark_time > 0 else "Light"
	var clips: Array = animations[form][animation_state]
	var frame_index := int(animation_clock * 14) % clips.size()
	if animation_state == "attack1":
		frame_index = mini(int((1.0 - attack_time / 0.20) * clips.size()), clips.size() - 1)
	elif animation_state == "attack3":
		frame_index = mini(int((1.0 - cast_time / 0.30) * clips.size()), clips.size() - 1)
	var texture: Texture2D = clips[maxi(0, frame_index)]
	var tint := Color.WHITE
	if hurt_cd > 0 and int(elapsed * 16) % 2 == 0:
		tint = Color("fa9d96")
	draw_set_transform(player + Vector2(0, -21), 0, Vector2(facing, 1))
	if dark_time > 0:
		draw_arc(Vector2(0, 16), 24, 0, TAU, 24, VIOLET, 2)
	if transform_time > 0 and not transform_frames.is_empty():
		var progress := 1.0 - transform_time / 0.75
		var index := mini(int(progress * transform_frames.size()), transform_frames.size() - 1)
		var transform: Texture2D = transform_frames[index]
		var size := Vector2(transform.get_size()) * 2
		draw_texture_rect(transform, Rect2(Vector2(-size.x / 2, 21 - size.y), size), false, tint)
		if not fx_frames.is_empty():
			var fx_index := mini(int(progress * fx_frames.size()), fx_frames.size() - 1)
			var fx: Texture2D = fx_frames[fx_index]
			var fx_size := Vector2(fx.get_size()) * 2
			draw_texture_rect(fx, Rect2(Vector2(-fx_size.x / 2, 21 - fx_size.y), fx_size), false)
	else:
		var size := Vector2(texture.get_size()) * 2
		var anchor_x := -size.x / 2
		if animation_state.begins_with("attack"):
			anchor_x = -36
		if land_time > 0:
			size.y *= 0.9
		draw_texture_rect(texture, Rect2(Vector2(anchor_x, 21 - size.y), size), false, tint)
	if slash > 0:
		draw_arc(Vector2(12, 0), 41, -1.2, 1.2, 14, VIOLET if dark_time > 0 else GOLD, 6)
	draw_set_transform(Vector2.ZERO)
	for bolt in bolts:
		var color: Color = VIOLET if bolt.tier >= 5 else GOLD
		var length: float = 70 + bolt.tier * 12
		draw_line(bolt.p - Vector2(bolt.dir * length, 0), bolt.p, Color(color, 0.3), 12 + bolt.tier * 3)
		draw_line(bolt.p - Vector2(bolt.dir * length, 0), bolt.p, color, 4 + bolt.tier)
		draw_circle(bolt.p, 6 + bolt.tier * 2, Color("fff3cd"))
		if bolt.tier >= 5:
			draw_arc(bolt.p - Vector2(bolt.dir * 25, 0), 56, -1.4, 1.4, 24, color, 5)
	for ring in rings:
		var progress: float = 1.0 - ring.life / 0.45
		draw_arc(ring.p, maxf(1, ring.radius * progress), 0, TAU, 64,
			Color(ring.color, 1.0 - progress), 8 * (1.0 - progress) + 1)
	for number in numbers:
		label_at(number.p, number.text, GOLD, 19)
	for particle in particles:
		draw_rect(Rect2(particle.p, Vector2(3, 3)), GOLD)
	draw_set_transform(Vector2(0, 90))
	draw_rect(Rect2(0, 253, 640, 107), Color("0e1822"))
	draw_line(Vector2(15, 253), Vector2(625, 253), Color("39413e"))
	var combo: Dictionary = Hand.evaluate(deck.hand)
	label_at(Vector2(20, 274), "K / " + combo.name.to_upper(), GOLD, 12)
	label_at(Vector2(20, 293), "%d damage" % combo.damage, Color("c3c8c5"), 12)
	label_at(Vector2(20, 324), "HITS %d / 3" % deck.hits, GOLD, 12)
	for i in range(3):
		draw_rect(Rect2(20 + i * 31, 333, 26, 5), GOLD if i < deck.hits else Color("344249"))
	label_at(Vector2(510, 275), "DECK %02d" % deck.pile.size(), Color("a7b5b7"), 12)
	label_at(Vector2(510, 293), "SPENT %02d" % deck.discard.size(), Color("a7b5b7"), 12)
	label_at(Vector2(510, 320), "REPLACE READY" if deck.banked else "3 hits = 1 draw", GOLD, 11)
	label_at(Vector2(510, 338), "Press 1–5 or K" if deck.banked else "Dealt automatically", Color("a7b5b7"), 11)
	for i in range(5):
		draw_rect(Rect2(150 + i * 69, 292, 64, 96), Color("1c2931"), false, 1)
		label_at(Vector2(178 + i * 69, 288), str(i + 1), Color("83918c"), 10)
	draw_set_transform(Vector2.ZERO)
	if notice_time > 0:
		label_at(Vector2(20, 90), notice, GOLD, 12)
	label_at(Vector2(20, 108), "Practice deals: F1 pair · F2 flush · F3 four of a kind", Color("8a9fa4"), 11)
	if dark_time > 0:
		label_at(Vector2(390, 130), "DARK RED  %.1fs · 2x sword" % dark_time, VIOLET, 13)
		draw_rect(Rect2(390, 137, 220 * dark_time / 6.0, 4), VIOLET)
	if banner_time > 0:
		label_at(Vector2(20, 150), banner, VIOLET if dark_time > 0 else GOLD, 24)
	if paused or health <= 0 or completed:
		draw_rect(Rect2(110, 116, 420, 75), Color("111c27"))
		label_at(Vector2(145, 145), "CLEARING COMPLETE" if completed else ("PAUSED" if paused else "THE FOREST WINS THIS HAND"), GOLD, 20)
		var help := "P to resume · R to restart" if paused else "R for a fresh run · ESC menu"
		label_at(Vector2(145, 170), help, Color.WHITE, 13)
