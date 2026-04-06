## Main game scene: advanced weapon system with power-ups, weapon levels, and combos.
##
## Weapon levels (up to 8):
##   1  Single shot
##   2  Dual shot
##   3  Triple spread
##   4  Double dual (4 bullets)
##   5  Fan spread + side shots
##   6  Wide fan (7 bullets)
##   7  Dual fan + missiles
##   8  Mega spread (9 bullets + faster fire rate)
##
## Power-ups drop from enemies and give: weapon up, HP heal, shield, bomb
## WASD/Arrow keys = move, Q = launch missile, R = bomb, T = shield
##
## Combo system: kill enemies quickly to build a multiplier (up to 5x).
## I-frames: brief invincibility after being hit.
## Boss spawns every 3 waves.

extends Node2D

const VW := 960
const VH := 1200

const PLAYER_SPEED := 300.0
const BULLET_SPEED := 600.0
const E_BULLET_SPEED := 350.0
const FIRE_BASE := 0.15
const MAX_HP := 100
const PICKUP_LIFE := 10.0
const INVINCIBLE_TIME := 2.0
const COMBO_WINDOW := 2.0
const MAX_COMBO := 5
const MAX_WPN_LEVEL := 8
const WAVE_INTERVAL := 40.0

# --- Boss ---
var _boss: BossData = null
var _boss_warning := 0.0

class BossData:
	var pos: Vector2 = Vector2.ZERO
	var hp: int = 200
	var max_hp: int = 200
	var phase: float = 0.0
	var attack: int = 0
	var fire_cd: float = 0.0
	var fire_rate: float = 0.8
	var w: float = 120.0
	var h: float = 80.0
	var col: Color = Color(1.0, 0.0, 0.4)
	var hit_flash: float = 0.0
	var entering: bool = true
	var pattern: int = 0
	var pattern_timer: float = 0.0
	var scale: float = 1.0
	var visual: Node3D

# --- Homing missiles ---
const MISSILE_COOLDOWN := 10.0
const MISSILE_SPEED := 450.0
const MISSILE_TURN_RATE := 3.0
const MISSILE_DMG := 3
const MISSILE_LIFE := 5.0
const MAX_MISSILES := 10
var _missile_cd := 0.0
var _missiles: int = 5

class HomingMissile:
	var pos: Vector2
	var angle: float = 0.0
	var speed: float
	var dmg: int
	var life: float
	var smoke: PackedVector2Array = []
	var visual: Node3D

# --- Stored pickups ---
const MAX_PICKUP_STORE := 10
var _stored_pickups: Array[int] = []

# --- Wingmen ---
var _wingmen: Array[Wingman] = []

class Wingman:
	var offset: Vector2
	var missile_cd: float = 0.0
	var visual: Node3D

enum PickupType { WEAPON, HEAL, SHIELD, BOMB, MISSILE }
enum BossAttack { STRAIGHT, SPREAD, BURST }

# --- Player ---
var _player: Rect2
var _player_alive := false
var _has_shield := false
var _shield_flash := 0.0
var _invincible := 0.0
var _player_bank := 0.0

# --- State ---
var _score: int = 0
var _display_score: int = 0
var _hp: int = MAX_HP
var _fire_cd := 0.0
var _elapsed := 0.0
var _running := false
var _paused := false
var _game_over_elapsed := 0.0
var _high_score: int = 0
var _edge_warning := 0.0

# --- Combo ---
var _combo: int = 0
var _combo_timer := 0.0
var _combo_display_timer := 0.0
var _combo_bar := 0.0  # Visual bar width for combo timer

# --- Weapon ---
var _wpn_level: int = 1
var _fire_rate := FIRE_BASE
var _weapon_up_flash := 0.0  # Brief screen flash on weapon upgrade

# --- Spawn ---
const _SPAWN_INTERVAL_MIN := 0.20
const _SPAWN_INTERVAL_BASE := 1.5
const _SPAWN_ACCEL := 0.008
var _spawn_cd := 0.0

# --- Difficulty waves ---
var _wave_timer := 0.0
var _wave_number: int = 0
var _wave_warning := 0.0  # Countdown display for "WAVE X INCOMING"

# --- Screen shake ---
var _shake := 0.0
var _shake_intensity := 60.0

class StarPoint:
	var pos: Vector2
	var speed: float
	var size: float
	var alpha: float
	var phase: float

class Nebula:
	var pos: Vector2
	var radius: float
	var drift: Vector2
	var alpha: float
	var col: Color
	var phase: float

# --- Background ---
var _stars: Array[StarPoint] = []
var _nebulae: Array[Nebula] = []

# --- Entity pools ---
var _pbullets: Array[Bullet] = []
var _ebullets: Array[EnemyBullet] = []
var _missile_pool: Array[HomingMissile] = []
var _enemies: Array[EnemyData] = []

class Bullet:
	var pos: Vector2
	var vel: Vector2
	var col: Color
	var dmg: int
	var trail: bool
	var visual: Node3D

class EnemyBullet:
	var pos: Vector2
	var vel: Vector2
	var visual: Node3D

# --- Pickups ---
var _pickups: Array[Pickup] = []

class Pickup:
	var pos: Vector2
	var type: int
	var life: float
	var bob: float
	var rot: float
	var visual: Node3D

# --- FX ---
var _explosions: Array[Explosion] = []
var _sparks: Array[Spark] = []
var _text_fx: Array[TextFX] = []
var _ring_fx: Array[RingFX] = []  # Expanding ring effect

class Explosion:
	var pos: Vector2
	var radius: float
	var max_radius: float
	var col: Color
	var visual: Node3D

class Spark:
	var pos: Vector2
	var vel: Vector2
	var life: float
	var max_life: float
	var col: Color
	var visual: Node3D

class TextFX:
	var pos: Vector2
	var text: String
	var life: float
	var max_life: float
	var vel: Vector2
	var col: Color = Color(1.0, 1.0, 0.6, 1.0)

class RingFX:
	var pos: Vector2
	var radius: float
	var max_radius: float
	var col: Color
	var line_width: float
	var visual: Node3D

# --- Enemy data ---
class EnemyData:
	var pos: Vector2
	var hp: int
	var max_hp: int
	var spd: float
	var score: int
	var fire_cd: float
	var fire_rate: float
	var w: float
	var h: float
	var col: Color
	var phase: float
	var boss_attack: int
	var hit_flash: float
	var visual: Node3D
	var lane_x: float
	var lane_band: float

# --- Enemy stats: [hp, speed, score, fire_rate, width, height, color] ---
const _ENEMY_STATS = [
	[1, 150.0, 100, 0.0, 20.0, 20.0, Color(1.0, 0.2, 0.25)],
	[3, 100.0, 300, 1.5, 32.0, 32.0, Color(1.0, 0.55, 0.15)],
	[20, 50.0, 5000, 0.5, 52.0, 48.0, Color(0.65, 0.0, 0.95)],
]

# --- UI ---
var _ui_score: Label
var _ui_hp: Label
var _ui_wpn: Label
var _ui_shield: Label
var _ui_missiles: Label
var _ui_wave: Label
var _ui_start: Control
var _ui_over: Control
var _ui_game_over_score: Label
var _ui_game_over_high: Label
var _ui_store: Label

# --- 3D World ---
var _use_3d := true
const MODEL_PLAYER_PATH := "res://assets/models/player_ship.glb"
const MODEL_WINGMAN_PATH := "res://assets/models/wingman_drone.glb"
const MODEL_ENEMY_LIGHT_PATH := "res://assets/models/enemy_light.glb"
const MODEL_ENEMY_MID_PATH := "res://assets/models/enemy_mid.glb"
const MODEL_ENEMY_HEAVY_PATH := "res://assets/models/enemy_heavy.glb"
const MODEL_BOSS_PATH := "res://assets/models/boss_flagship.glb"
const MODEL_PLAYER_BULLET_PATH := "res://assets/models/player_bullet.glb"
const MODEL_ENEMY_BULLET_PATH := "res://assets/models/enemy_bullet.glb"
const MODEL_MISSILE_PATH := "res://assets/models/homing_missile.glb"
const PICKUP_MODEL_PATHS := {
	PickupType.WEAPON: "res://assets/models/pickup_weapon.glb",
	PickupType.HEAL: "res://assets/models/pickup_heal.glb",
	PickupType.SHIELD: "res://assets/models/pickup_shield.glb",
	PickupType.BOMB: "res://assets/models/pickup_bomb.glb",
	PickupType.MISSILE: "res://assets/models/pickup_missile.glb",
}
const WORLD_SCALE := 0.05
const WORLD_HALF_WIDTH := VW * WORLD_SCALE * 0.5
const WORLD_HALF_HEIGHT := VH * WORLD_SCALE * 0.5
const GROUND_HALF_LENGTH := 120.0
const GROUND_HALF_WIDTH := 36.0
const PLAYER_SAFE_MARGIN_X_3D := 150.0
const PLAYER_SAFE_MARGIN_TOP_3D := 70.0
const PLAYER_SAFE_MARGIN_BOTTOM_3D := 170.0
var _world_root: Node3D
var _camera_3d: Camera3D
var _entity_root_3d: Node3D
var _player_root_3d: Node3D
var _wingmen_root_3d: Node3D
var _bullets_root_3d: Node3D
var _enemy_bullets_root_3d: Node3D
var _enemies_root_3d: Node3D
var _pickups_root_3d: Node3D
var _missiles_root_3d: Node3D
var _boss_root_3d: Node3D
var _ground_root_3d: Node3D
var _fx_root_3d: Node3D
var _player_visual_3d: Node3D
var _shield_visual_3d: MeshInstance3D
var _ground_lines_3d: Array[MeshInstance3D] = []
var _ground_center_markers_3d: Array[MeshInstance3D] = []
var _ground_safe_guides_3d: Array[MeshInstance3D] = []
var _model_scene_cache: Dictionary = {}
var _camera_focus_3d := Vector3.ZERO
var _camera_focus_ready := false


func _input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_SPACE:
		if _ui_start.visible:
			_start_game()
		elif _ui_over.visible and not _running:
			_restart()
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		if _running:
			_pause()
		elif _paused:
			_unpause()
	if ev is InputEventKey and ev.pressed:
		match ev.keycode:
			KEY_Q: _release_stored(PickupType.MISSILE)
			KEY_R: _release_stored(PickupType.BOMB)
			KEY_T: _release_stored(PickupType.SHIELD)


func _ready() -> void:
	_ui_score = $UI/ScoreLabel
	_ui_hp = $UI/HPLabel
	_ui_wpn = $UI/WpnLabel
	_ui_shield = $UI/ShieldLabel
	_ui_missiles = $UI/MissileCount
	_ui_wave = $UI/WaveLabel
	_ui_start = $UI/StartScreen
	_ui_over = $UI/GameOver
	_ui_game_over_score = $UI/GameOver/ScoreText
	_ui_game_over_high = $UI/GameOver/HighText
	_ui_store = $UI/StoreLabel
	_ui_over.visible = false
	_ui_start.visible = true
	if _use_3d:
		_setup_3d_world()
	_setup_background()
	_ui_update()


func _setup_background() -> void:
	_stars.clear()
	_nebulae.clear()

	for _i in 160:
		var star := StarPoint.new()
		star.pos = Vector2(randf_range(0, VW), randf_range(0, VH))
		star.speed = randf_range(18.0, 180.0)
		star.size = randf_range(0.8, 2.4)
		star.alpha = randf_range(0.2, 0.85)
		star.phase = randf_range(0.0, TAU)
		_stars.append(star)

	var nebula_palette := [
		Color(0.12, 0.45, 0.9),
		Color(0.2, 0.7, 1.0),
		Color(0.55, 0.18, 0.9),
		Color(1.0, 0.35, 0.55),
	]
	for i in 6:
		var nebula := Nebula.new()
		nebula.pos = Vector2(randf_range(40.0, VW - 40.0), randf_range(120.0, VH - 120.0))
		nebula.radius = randf_range(70.0, 170.0)
		nebula.drift = Vector2(randf_range(-6.0, 6.0), randf_range(8.0, 18.0))
		nebula.alpha = randf_range(0.08, 0.22)
		nebula.col = nebula_palette[i % nebula_palette.size()]
		nebula.phase = randf_range(0.0, TAU)
		_nebulae.append(nebula)


func _start_game() -> void:
	_ui_start.visible = false
	_running = true
	_score = 0
	_display_score = 0
	_hp = MAX_HP
	_wpn_level = 1
	_elapsed = 0.0
	_fire_cd = 0.0
	_spawn_cd = 1.0
	_shield_flash = 0.0
	_has_shield = false
	_invincible = 0.0
	_combo = 0
	_combo_timer = 0.0
	_combo_display_timer = 0.0
	_combo_bar = 0.0
	_shake = 0.0
	_wave_timer = 0.0
	_wave_number = 0
	_wave_warning = 0.0
	_boss_warning = 0.0
	_boss = null
	_weapon_up_flash = 0.0
	_player = Rect2(VW / 2.0 - 12.0, VH - 120.0, 24.0, 32.0)
	_player_alive = true
	_player_bank = 0.0
	_fire_rate = FIRE_BASE
	_pbullets.clear()
	_ebullets.clear()
	_missile_pool.clear()
	_enemies.clear()
	_explosions.clear()
	_sparks.clear()
	_pickups.clear()
	_text_fx.clear()
	_ring_fx.clear()
	_missile_cd = 0.0
	_missiles = 5
	_stored_pickups.clear()
	_wingmen.clear()
	if _use_3d:
		_clear_3d_dynamic_visuals()
	_ui_update()


func _restart() -> void:
	_ui_over.visible = false
	_start_game()


func _physics_process(delta: float) -> void:
	if _paused:
		queue_redraw()
		return

	if not _running:
		if _game_over_elapsed > 0.0:
			_game_over_elapsed += delta
			if _display_score < _score:
				_display_score = mini(int(_game_over_elapsed * 2000.0), _score)
				_ui_score.text = "SCORE  " + str(_display_score)
			if _display_score >= _score:
				_game_over_elapsed = 0.0
			queue_redraw()
		return

	_elapsed += delta
	_game_over_elapsed = 0.0

	if _player_alive:
		_move_player(delta)
		_fire_cd -= delta
		if _fire_cd <= 0.0:
			_player_shoot()
			_fire_cd = _fire_rate
		_invincible = maxf(_invincible - delta, 0.0)

	if _shield_flash > 0.0:
		_shield_flash = maxf(_shield_flash - delta * 3.0, 0.0)

	if _wave_warning > 0.0:
		_wave_warning -= delta

	if _weapon_up_flash > 0.0:
		_weapon_up_flash -= delta * 4.0

	# Combo
	if _combo_timer > 0.0:
		_combo_timer -= delta
		_combo_bar = _combo_timer / COMBO_WINDOW
		if _combo_timer <= 0.0:
			_combo = 0
			_combo_bar = 0.0
	if _combo_display_timer > 0.0:
		_combo_display_timer -= delta

	# Shake
	if _shake > 0.0:
		_shake = maxf(_shake - delta * 8.0, 0.0)

	# Waves
	_wave_timer += delta
	if _wave_timer >= WAVE_INTERVAL:
		_wave_timer = 0.0
		_wave_warning = 2.0
		_trigger_wave()

	# Background drift
	for star in _stars:
		star.pos.y += star.speed * delta
		if star.pos.y > VH + 8.0:
			star.pos.y = -8.0
			star.pos.x = randf_range(0.0, VW)

	for nebula in _nebulae:
		nebula.pos += nebula.drift * delta
		nebula.phase += delta * 0.2
		if nebula.pos.y - nebula.radius > VH:
			nebula.pos.y = -nebula.radius
			nebula.pos.x = randf_range(50.0, VW - 50.0)
		if nebula.pos.x < -nebula.radius:
			nebula.pos.x = VW + nebula.radius
		elif nebula.pos.x > VW + nebula.radius:
			nebula.pos.x = -nebula.radius

	# Player bullets
	for b in _pbullets:
		b.pos += b.vel * delta

	# Enemy bullets
	for eb in _ebullets:
		eb.pos += eb.vel * delta

	# Homing missiles
	_missile_cd = maxf(_missile_cd - delta, 0.0)
	_update_missiles(delta)
	_update_wingmen(delta)

	# Spawn
	_spawn_cd -= delta
	if _spawn_cd <= 0.0:
		_do_spawn()
		_spawn_cd = maxf(_SPAWN_INTERVAL_MIN, _SPAWN_INTERVAL_BASE - _elapsed * _SPAWN_ACCEL)

	# Enemies
	for e in _enemies:
		_move_enemy(e, delta)
		if e.fire_rate > 0.0:
			e.fire_cd -= delta
			if e.fire_cd <= 0.0:
				_spawn_enemy_bullet(e)
				e.fire_cd = e.fire_rate
		if e.hit_flash > 0.0:
			e.hit_flash -= delta * 5.0

	# Boss
	if _boss != null:
		_update_boss(delta)

	if _boss_warning > 0.0:
		_boss_warning -= delta

	# Pickups
	for pu in _pickups:
		pu.life -= delta
		pu.bob += delta * 4.0
		pu.rot += delta * 3.0
		pu.pos.y += 40.0 * delta
	_pickups = _pickups.filter(func(p): return p.life > 0.0)

	if _player_alive:
		_collect_pickups()

	# FX
	for ex in _explosions:
		ex.radius += 400.0 * delta
	for s in _sparks:
		s.pos += s.vel * delta
		s.life -= delta
	for tfx in _text_fx:
		tfx.pos += tfx.vel * delta
		tfx.life -= delta
	for rfx in _ring_fx:
		rfx.radius += 500.0 * delta

	# Collisions
	_collide_pbullets_vs_enemies()
	_collide_missiles_vs_enemies()
	if _player_alive:
		_collide_bullets_vs_boss()
		_collide_missiles_vs_boss()
	if _player_alive:
		_collide_ebullets_vs_player()
		_collide_enemies_vs_player()

	# Cull
	_pbullets = _pbullets.filter(func(b):
		var p: Vector2 = b.pos
		return p.y > -30 and p.y < VH + 30 and p.x > -30 and p.x < VW + 30
	)
	_ebullets = _ebullets.filter(func(b): return b.pos.y < VH + 30)
	_missile_pool = _missile_pool.filter(func(m): return m.life > 0.0)
	_enemies = _enemies.filter(func(e): return e.pos.y < VH + 60)
	_explosions = _explosions.filter(func(ex): return ex.radius < ex.max_radius)
	_sparks = _sparks.filter(func(s): return s.life > 0.0)
	_text_fx = _text_fx.filter(func(t): return t.life > 0.0)
	_ring_fx = _ring_fx.filter(func(r): return r.radius < r.max_radius)

	_ui_update()
	if _use_3d:
		_sync_3d_world(delta)
	queue_redraw()


func _move_player(dt: float) -> void:
	var d := Vector2.ZERO
	d.x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	d.y = int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up"))
	# Direct arrow key fallback
	if Input.is_key_pressed(KEY_UP): d.y -= 1
	if Input.is_key_pressed(KEY_DOWN): d.y += 1
	if Input.is_key_pressed(KEY_LEFT): d.x -= 1
	if Input.is_key_pressed(KEY_RIGHT): d.x += 1
	if d.length() > 0:
		d = d.normalized()
		_player.position += d * PLAYER_SPEED * dt
	_player_bank = lerpf(_player_bank, d.x * 0.5, 0.12)
	var min_x := 0.0
	var max_x := VW - _player.size.x
	var min_y := 0.0
	var max_y := VH - _player.size.y
	if _use_3d:
		min_x = PLAYER_SAFE_MARGIN_X_3D
		max_x = VW - _player.size.x - PLAYER_SAFE_MARGIN_X_3D
		min_y = PLAYER_SAFE_MARGIN_TOP_3D
		max_y = VH - _player.size.y - PLAYER_SAFE_MARGIN_BOTTOM_3D
	_player.position.x = clampf(_player.position.x, min_x, max_x)
	_player.position.y = clampf(_player.position.y, min_y, max_y)
	var left_margin := _player.position.x - min_x
	var right_margin := max_x - _player.position.x
	var edge_dist := minf(left_margin, right_margin)
	var edge_ratio := clampf(1.0 - edge_dist / 72.0, 0.0, 1.0)
	_edge_warning = lerpf(_edge_warning, edge_ratio, 0.18)


func _get_safe_lane_centers() -> Array[float]:
	var left := 30.0
	var right := VW - 30.0
	if _use_3d:
		left = PLAYER_SAFE_MARGIN_X_3D + 30.0
		right = VW - PLAYER_SAFE_MARGIN_X_3D - 30.0
	var mid := (left + right) * 0.5
	var span := (right - left) * 0.32
	return [mid - span, mid, mid + span]


func _lane_band_for_enemy(enemy_hp: int) -> float:
	if enemy_hp <= 1:
		return 54.0
	if enemy_hp <= 3:
		return 38.0
	return 22.0


func _setup_enemy_lane(e: EnemyData, lane_x: float) -> void:
	e.lane_x = lane_x
	e.lane_band = _lane_band_for_enemy(e.max_hp)
	e.pos.x = clampf(lane_x + randf_range(-e.lane_band * 0.3, e.lane_band * 0.3), e.w / 2.0, VW - e.w / 2.0)


func _trigger_wave() -> void:
	_wave_number += 1
	var count := mini(_wave_number * 2 + 3, 15)
	var tier := 0 if _wave_number < 3 else 1
	var s: Array = _ENEMY_STATS[tier]
	var lanes := _get_safe_lane_centers()

	# Boss every 3 waves
	if _wave_number % 3 == 0 and _boss == null:
		_spawn_boss()
		_boss_warning = 3.0

	for _i in count:
		var e := EnemyData.new()
		var lane_x := lanes[_i % lanes.size()]
		e.pos = Vector2(lane_x, randf_range(-VH, -s[5]))
		e.w = s[4]; e.h = s[5]
		e.hp = s[0]; e.max_hp = s[0]
		e.spd = s[1]; e.score = s[2]
		e.fire_cd = randf_range(0.0, s[3])
		e.fire_rate = s[3]; e.col = s[6]
		e.phase = randf_range(0, TAU)
		e.boss_attack = 0; e.hit_flash = 0.0
		_setup_enemy_lane(e, lane_x)
		_enemies.append(e)

	# Wave ring effect
	_make_ring(Vector2(VW / 2.0, 0), Color(0.8, 0.2, 1.0))
	for lane_x in lanes:
		_make_ring(Vector2(lane_x, 40.0), Color(0.18, 0.72, 1.0))


func _move_enemy(e: EnemyData, dt: float) -> void:
	e.phase += dt
	e.pos.y += e.spd * dt

	match int(e.max_hp):
		1:
			var target_x := e.lane_x + sin(e.phase * 2.8 + e.pos.y * 0.02) * e.lane_band
			e.pos.x += (target_x - e.pos.x) * 2.8 * dt
		3:
			var target_x := e.lane_x + sin(e.phase * 1.8 + e.pos.y * 0.01) * e.lane_band
			e.pos.x += (target_x - e.pos.x) * 2.2 * dt
		_:
			var target_x := e.lane_x + sin(e.phase * 0.7) * e.lane_band
			e.pos.x += (target_x - e.pos.x) * 1.8 * dt

	e.pos.x = clampf(e.pos.x, e.w / 2.0, VW - e.w / 2.0)


func _player_shoot() -> void:
	var cx := _player.position.x + _player.size.x / 2.0
	var ty := _player.position.y - 6

	match _wpn_level:
		1:
			_add_bullet(Vector2(cx, ty), Vector2.UP * BULLET_SPEED, Color(0.3, 0.8, 1.0), 1, false)
		2:
			_add_bullet(Vector2(cx - 6, ty + 4), Vector2.UP * BULLET_SPEED, Color(0.3, 0.85, 1.0), 1, false)
			_add_bullet(Vector2(cx + 6, ty + 4), Vector2.UP * BULLET_SPEED, Color(0.3, 0.85, 1.0), 1, false)
		3:
			_add_bullet(Vector2(cx, ty), Vector2.UP * BULLET_SPEED, Color(0.35, 0.9, 1.0), 1, false)
			_add_bullet(Vector2(cx - 8, ty + 2), Vector2(-0.025, -1.0).normalized() * BULLET_SPEED, Color(0.35, 0.9, 1.0), 1, false)
			_add_bullet(Vector2(cx + 8, ty + 2), Vector2(0.025, -1.0).normalized() * BULLET_SPEED, Color(0.35, 0.9, 1.0), 1, false)
		4:
			_add_bullet(Vector2(cx - 6, ty + 4), Vector2.UP * BULLET_SPEED, Color(0.4, 0.95, 1.0), 1, false)
			_add_bullet(Vector2(cx + 6, ty + 4), Vector2.UP * BULLET_SPEED, Color(0.4, 0.95, 1.0), 1, false)
			_add_bullet(Vector2(cx - 12, ty + 6), Vector2(-0.033, -1.0).normalized() * BULLET_SPEED, Color(0.9, 0.6, 1.0), 1, false)
			_add_bullet(Vector2(cx + 12, ty + 6), Vector2(0.033, -1.0).normalized() * BULLET_SPEED, Color(0.9, 0.6, 1.0), 1, false)
		_:
			for i in range(-2, 3):
				var angle := -PI / 2 + i * (PI / 10.0)
				var dir := Vector2(cos(angle), sin(angle))
				_add_bullet(Vector2(cx + i * 5, ty), dir * BULLET_SPEED, Color(1.0, 0.8, 0.4), 1, true)


func _add_bullet(pos: Vector2, vel: Vector2, col: Color, dmg: int, trail: bool) -> void:
	var b := Bullet.new()
	b.pos = pos; b.vel = vel; b.col = col; b.dmg = dmg; b.trail = trail
	_pbullets.append(b)


# --- Homing missiles ---
func _fire_player_missile() -> void:
	if _missiles <= 0 or _missile_cd > 0.0 or _missile_pool.size() >= MAX_MISSILES:
		return
	_missiles -= 1
	_missile_cd = MISSILE_COOLDOWN
	var m := HomingMissile.new()
	m.pos = _player.get_center()
	m.angle = -PI / 2
	m.speed = MISSILE_SPEED
	m.dmg = MISSILE_DMG
	m.life = MISSILE_LIFE
	_missile_pool.append(m)


func _update_missiles(dt: float) -> void:
	for m in _missile_pool:
		var nearest := _find_nearest_enemy(m.pos)
		if nearest != Vector2.INF:
			var desired := atan2(nearest.y - m.pos.y, nearest.x - m.pos.x)
			var diff := desired - m.angle
			while diff < -PI:
				diff += TAU
			while diff > PI:
				diff -= TAU
			m.angle += clampf(diff, -MISSILE_TURN_RATE * dt, MISSILE_TURN_RATE * dt)
		m.speed += 100.0 * dt
		m.pos += Vector2.from_angle(m.angle) * m.speed * dt
		m.life -= dt
		# Smoke trail
		if randf() < 0.6:
			m.smoke.append(m.pos)
			if m.smoke.size() > 10:
				m.smoke.remove_at(0)


func _find_nearest_enemy(pos: Vector2) -> Vector2:
	var min_dist := INF
	var target := Vector2.INF
	for e in _enemies:
		var d := pos.distance_squared_to(e.pos)
		if d < min_dist:
			min_dist = d
			target = e.pos
	return target


func _collide_missiles_vs_enemies() -> void:
	for mi in range(_missile_pool.size() - 1, -1, -1):
		var m := _missile_pool[mi]
		for ei in range(_enemies.size() - 1, -1, -1):
			var e := _enemies[ei]
			var mr := Rect2(m.pos.x - 4, m.pos.y - 4, 8, 8)
			var er := Rect2(e.pos.x - e.w / 2.0, e.pos.y - e.h / 2.0, e.w, e.h)
			if mr.intersects(er):
				e.hp -= m.dmg
				e.hit_flash = 0.6
				_make_explosion(e.pos, Color(1.0, 0.5, 0.1), 25)
				_make_ring(e.pos, Color(1.0, 0.4, 0.2))
				_make_text_popup(e.pos, str(m.dmg), Color(1.0, 0.5, 0.2))
				if e.hp <= 0:
					_add_combo_score(e.score, e.pos)
					_make_explosion(e.pos, e.col, e.w)
					_make_ring(e.pos, e.col * Color(1, 1, 1, 0.6))
					_drop_pickup(e.pos, e.max_hp)
					_enemies.remove_at(ei)
				_missile_pool.remove_at(mi)
				_shake = 0.15
				break



func _upgrade_weapon() -> void:
	if _wpn_level < MAX_WPN_LEVEL:
		_wpn_level += 1
		_fire_rate = FIRE_BASE * pow(0.85, _wpn_level - 1)
		_weapon_up_flash = 1.0
		# Ring effect at player
		_make_ring(_player.get_center(), Color(0.4, 1.0, 0.8))


func _spawn_enemy_bullet(e: EnemyData) -> void:
	match int(e.max_hp):
		1, 3:
			_add_enemy_bullet_at(e.pos + Vector2(0, e.h / 2.0 + 4), Vector2.DOWN * E_BULLET_SPEED)
		_:
			_e_boss_attack(e)


func _add_enemy_bullet_at(pos: Vector2, vel: Vector2) -> void:
	var b := EnemyBullet.new()
	b.pos = pos; b.vel = vel
	_ebullets.append(b)


# --- Boss ---
func _spawn_boss() -> void:
	var b := BossData.new()
	b.pos = Vector2(VW / 2.0, -100)
	b.scale = 1.0 + float(_wave_number) * 0.1
	b.max_hp = 200 + _wave_number * 50
	b.hp = b.max_hp
	b.fire_rate = maxf(0.3, 0.8 - float(_wave_number) * 0.05)
	b.pattern = 0
	b.pattern_timer = 3.0
	_boss = b
	_make_ring(Vector2(VW / 2.0, 56.0), Color(1.0, 0.28, 0.48))
	_make_ring(Vector2(VW / 2.0, 84.0), Color(0.24, 0.78, 1.0))


func _update_boss(dt: float) -> void:
	var b := _boss
	if b.entering:
		b.pos.y += 80.0 * dt
		if b.pos.y >= 100:
			b.entering = false
		return

	b.phase += dt
	b.pattern_timer -= dt
	if b.pattern_timer <= 0.0:
		b.pattern = (b.pattern + 1) % 4
		b.pattern_timer = 5.0 + randf_range(-1.0, 1.0)
		b.fire_rate = maxf(0.25, 0.8 - float(_wave_number) * 0.04)

	# Horizontal movement
	var target_x := VW / 2.0 + sin(b.phase * 0.6) * (VW * 0.3)
	b.pos.x += (target_x - b.pos.x) * 2.0 * dt
	b.hit_flash = maxf(b.hit_flash - dt * 4.0, 0.0)

	# Fire
	b.fire_cd -= dt
	if b.fire_cd <= 0.0:
		_boss_attack(b)
		b.fire_cd = b.fire_rate


func _collide_bullets_vs_boss() -> void:
	if _boss == null or _boss.entering:
		return
	for bi in range(_pbullets.size() - 1, -1, -1):
		if bi >= _pbullets.size(): break
		var b := _pbullets[bi]
		var bs := _boss.scale
		var br := Rect2(b.pos.x - 3, b.pos.y - 6, 6, 12)
		var boss_rect := Rect2(_boss.pos.x - _boss.w / 2.0 * bs, _boss.pos.y - _boss.h / 2.0 * bs, _boss.w * bs, _boss.h * bs)
		if br.intersects(boss_rect):
			_pbullets.remove_at(bi)
			_boss.hp -= b.dmg
			_boss.hit_flash = 0.5
			_make_hit_spark(b.pos, b.col)
			if _boss.hp <= 0:
				_kill_boss()
			return


func _collide_missiles_vs_boss() -> void:
	if _boss == null or _boss.entering:
		return
	for mi in range(_missile_pool.size() - 1, -1, -1):
		var m := _missile_pool[mi]
		var bs := _boss.scale
		var mr := Rect2(m.pos.x - 4, m.pos.y - 4, 8, 8)
		var boss_rect := Rect2(_boss.pos.x - _boss.w / 2.0 * bs, _boss.pos.y - _boss.h / 2.0 * bs, _boss.w * bs, _boss.h * bs)
		if mr.intersects(boss_rect):
			_boss.hp -= m.dmg
			_boss.hit_flash = 0.6
			_make_explosion(m.pos, Color(1.0, 0.5, 0.1), 25)
			_make_text_popup(m.pos, str(m.dmg), Color(1.0, 0.5, 0.2))
			_missile_pool.remove_at(mi)
			_shake = 0.15
			if _boss.hp <= 0:
				_kill_boss()
			return


func _kill_boss() -> void:
	_score += 10000
	_make_explosion(_boss.pos, _boss.col, 80)
	_make_explosion(_boss.pos, Color(1.0, 0.8, 0.3), 120)
	_make_ring(_boss.pos, Color(1.0, 0.3, 0.5))
	_make_ring(_boss.pos, Color(1.0, 0.8, 0.2))
	_boss = null
	_shake = 0.8


func _boss_attack(b: BossData) -> void:
	var cx := b.pos.x
	var cy := b.pos.y + b.h / 2.0 * b.scale

	match b.pattern:
		0: # Spread rain
			for i in range(-5, 6):
				var angle := PI / 2 + float(i) * (PI / 7.0)
				var dir := Vector2(cos(angle), sin(angle))
				_add_enemy_bullet_at(Vector2(cx, cy), dir * E_BULLET_SPEED)
		1: # Aimed burst
			var target := _player.get_center() if _player_alive else Vector2(cx, VH)
			var dir := (target - Vector2(cx, cy)).normalized()
			for j in range(5):
				var spread := dir.rotated(float(j - 2) * 0.15)
				_add_enemy_bullet_at(Vector2(cx, cy) + spread * 8, spread * E_BULLET_SPEED)
		2: # Spiral
			for j in 4:
				var angle := b.phase * 2.0 + float(j) * (PI / 2.0)
				var dir := Vector2(cos(angle), sin(angle))
				_add_enemy_bullet_at(Vector2(cx, cy), dir * E_BULLET_SPEED)
		_: # Ring burst
			for i in 8:
				var angle := TAU * float(i) / 8.0 + b.phase * 0.5
				var dir := Vector2(cos(angle), sin(angle))
				_add_enemy_bullet_at(Vector2(cx, cy), dir * E_BULLET_SPEED)


func _e_boss_attack(e: EnemyData) -> void:
	var cx := e.pos.x
	var cy := e.pos.y + e.h / 2.0 + 4

	match e.boss_attack:
		BossAttack.STRAIGHT:
			_add_enemy_bullet_at(Vector2(cx, cy), Vector2.DOWN * E_BULLET_SPEED)
		BossAttack.SPREAD:
			for i in range(-2, 3):
				var angle := PI / 2 + i * (PI / 8.0)
				var dir := Vector2(cos(angle), sin(angle))
				_add_enemy_bullet_at(Vector2(cx, cy), dir * E_BULLET_SPEED)
		BossAttack.BURST:
			for j in range(3):
				var target := _player.get_center() if _player_alive else Vector2(cx, VH)
				var dir := (target - Vector2(cx, cy)).normalized()
				var spread := dir.rotated(float(j - 1) * 0.2)
				_add_enemy_bullet_at(Vector2(cx, cy) + spread * 10, spread * E_BULLET_SPEED)

	e.boss_attack = (e.boss_attack + 1) % 3


func _drop_pickup(pos: Vector2, enemy_max_hp: int) -> void:
	if _wpn_level >= MAX_WPN_LEVEL and randf() < 0.5:
		_do_drop_pickup(pos, PickupType.HEAL)
		return

	var ptype := _pick_type_for_enemy(enemy_max_hp)
	if ptype >= 0:
		_do_drop_pickup(pos, ptype)


func _do_drop_pickup(pos: Vector2, ptype: int) -> void:
	var pu := Pickup.new()
	pu.pos = pos; pu.life = PICKUP_LIFE; pu.bob = 0.0; pu.rot = 0.0; pu.type = ptype
	_pickups.append(pu)


func _pick_type_for_enemy(ehp: int) -> int:
	var chance := 0.0
	if ehp <= 1: chance = 0.08
	elif ehp <= 3: chance = 0.25
	elif ehp <= 5: chance = 0.4
	else: chance = 1.0

	if randf() > chance:
		return -1

	var r := randf()
	if r < 0.50: return PickupType.WEAPON
	elif r < 0.72: return PickupType.HEAL
	elif r < 0.88: return PickupType.SHIELD
	elif r < 0.96: return PickupType.BOMB
	else: return PickupType.MISSILE


func _collect_pickups() -> void:
	for i in range(_pickups.size() - 1, -1, -1):
		var p := _pickups[i]
		var pr := Rect2(p.pos.x - 8, p.pos.y - 8 + sin(p.bob) * 3, 16, 16)
		if _player.intersects(pr):
			_store_pickup(p.type)
			_pickups.remove_at(i)


func _store_pickup(ptype: int) -> void:
	# Weapon and heal auto-apply
	match ptype:
		PickupType.WEAPON:
			_upgrade_weapon()
			return
		PickupType.HEAL:
			_hp = mini(_hp + 5, MAX_HP)
			return
	if _stored_pickups.size() >= MAX_PICKUP_STORE:
		return
	_stored_pickups.push_back(ptype)
	var tfx := TextFX.new()
	tfx.pos = _player.get_center()
	tfx.text = "+" + _pickup_name(ptype)
	tfx.life = 0.8
	tfx.max_life = 0.8
	tfx.vel = Vector2.UP * 60.0
	tfx.col = Color(1.0, 0.9, 0.45, 1.0)
	_text_fx.append(tfx)


func _pickup_name(t: int) -> String:
	match t:
		PickupType.WEAPON: return "武器"
		PickupType.HEAL: return "HP"
		PickupType.SHIELD: return "盾"
		PickupType.BOMB: return "炸弹"
		PickupType.MISSILE: return "导弹"
	return "?"


func _release_stored(ptype: int) -> void:
	if not _running or _paused or not _player_alive:
		return
	var idx := _stored_pickups.find(ptype)
	if idx == -1:
		return
	var found := _stored_pickups[idx]
	match found:
		PickupType.HEAL: _hp = mini(_hp + 5, MAX_HP)
		PickupType.MISSILE: _missiles += 3
		PickupType.BOMB: _activate_bomb()
		PickupType.SHIELD:
			_has_shield = true
			_shield_flash = 1.0
	_stored_pickups.remove_at(idx)
	_make_ring(_player.get_center(), Color(1.0, 0.8, 0.3))
	_make_text_popup(_player.get_center(), _pickup_name(found), Color(1.0, 0.8, 0.3))


func _apply_pickup_immediate(ptype: int) -> void:
	match ptype:
		PickupType.WEAPON: _upgrade_weapon()
		PickupType.HEAL: _hp = mini(_hp + 2, MAX_HP)
		PickupType.SHIELD:
			_has_shield = true
			_shield_flash = 1.0
		PickupType.BOMB: _activate_bomb()
		PickupType.MISSILE: _missiles += 3


func _activate_bomb() -> void:
	for e in _enemies:
		_make_explosion(e.pos, e.col, e.w)
		_score += e.score
	_enemies.clear(); _ebullets.clear()
	_shake = 1.0
	var ex := Explosion.new()
	ex.pos = Vector2(VW / 2.0, VH / 2.0)
	ex.radius = 10.0
	ex.max_radius = maxf(VW, VH)
	ex.col = Color(1.0, 1.0, 1.0)
	_explosions.push_front(ex)
	_make_ring(Vector2(VW / 2.0, VH / 2.0), Color(1.0, 0.5, 0.2))


func _do_spawn() -> void:
	var r := randf()
	var tier := 0
	if _elapsed > 60.0 and r > 0.95: tier = 2
	elif _elapsed > 30.0 and r > 0.7: tier = 1

	var s: Array = _ENEMY_STATS[tier]
	var lanes := _get_safe_lane_centers()
	var lane_x := lanes[randi() % lanes.size()]
	var e := EnemyData.new()
	e.pos = Vector2(lane_x, -s[5])
	e.w = s[4]; e.h = s[5]
	e.hp = s[0]; e.max_hp = s[0]
	e.spd = s[1]; e.score = s[2]
	e.fire_cd = randf_range(0.0, s[3])
	e.fire_rate = s[3]; e.col = s[6]
	e.phase = randf_range(0, TAU)
	e.boss_attack = 0; e.hit_flash = 0.0
	_setup_enemy_lane(e, lane_x)
	_enemies.append(e)


func _collide_pbullets_vs_enemies() -> void:
	var dead_enemies: Array[int] = []

	for bi in range(_pbullets.size() - 1, -1, -1):
		if bi >= _pbullets.size():
			break
		var b := _pbullets[bi]
		var br := Rect2(b.pos.x - 3, b.pos.y - 6, 6, 12)
		for ei in range(_enemies.size() - 1, -1, -1):
			var e := _enemies[ei]
			var er := Rect2(e.pos.x - e.w / 2.0, e.pos.y - e.h / 2.0, e.w, e.h)
			if br.intersects(er):
				_pbullets.remove_at(bi)
				e.hp -= b.dmg
				e.hit_flash = 0.4
				# Small hit spark
				_make_hit_spark(b.pos, b.col)
				if e.hp <= 0 and not dead_enemies.has(ei):
					dead_enemies.append(ei)
					_add_combo_score(e.score, e.pos)
					_make_explosion(e.pos, e.col, e.w)
					_make_ring(e.pos, e.col * Color(1, 1, 1, 0.6))
					_drop_pickup(e.pos, e.max_hp)
				break

	dead_enemies.sort()
	for i in range(dead_enemies.size() - 1, -1, -1):
		_enemies.remove_at(dead_enemies[i])


func _make_hit_spark(pos: Vector2, col: Color) -> void:
	for i in 3:
		var s := Spark.new()
		s.pos = pos
		var angle := randf_range(0, TAU)
		var sp := randf_range(50, 150)
		s.vel = Vector2(cos(angle), sin(angle)) * sp
		s.life = randf_range(0.1, 0.25)
		s.max_life = s.life
		s.col = col
		_sparks.append(s)


func _make_ring(pos: Vector2, col: Color) -> void:
	var rfx := RingFX.new()
	rfx.pos = pos
	rfx.radius = 5.0
	rfx.max_radius = 50.0
	rfx.col = col
	rfx.line_width = 2.0
	_ring_fx.append(rfx)


func _add_combo_score(base_score: int, pos: Vector2) -> void:
	if _combo_timer > 0.0:
		_combo = mini(_combo + 1, MAX_COMBO)
	else:
		_combo = 1
	_combo_timer = COMBO_WINDOW
	_combo_display_timer = 1.5

	var multiplier := maxi(_combo, 1)
	var gained := base_score * multiplier
	_score += gained

	var tfx := TextFX.new()
	tfx.pos = pos
	tfx.text = str(gained)
	if multiplier > 1:
		tfx.text += " x" + str(multiplier)
	tfx.life = 1.0; tfx.max_life = 1.0
	tfx.vel = Vector2.UP * 60.0
	tfx.col = Color(1.0, 0.92, 0.45, 1.0)
	_text_fx.append(tfx)


func _collide_ebullets_vs_player() -> void:
	if not _player_alive or _invincible > 0.0:
		return
	for i in range(_ebullets.size() - 1, -1, -1):
		var dot := Rect2(_ebullets[i].pos.x - 3, _ebullets[i].pos.y - 3, 6, 6)
		if _player.intersects(dot):
			_ebullets.remove_at(i)
			_player_hit()
			if not _player_alive:
				return


func _collide_enemies_vs_player() -> void:
	if not _player_alive or _invincible > 0.0:
		return
	for i in range(_enemies.size() - 1, -1, -1):
		var e := _enemies[i]
		var er := Rect2(e.pos.x - e.w / 2.0, e.pos.y - e.h / 2.0, e.w, e.h)
		if _player.intersects(er):
			_enemies.remove_at(i)
			_add_combo_score(e.score, e.pos)
			_make_explosion(e.pos, e.col, e.w)
			_player_hit()
			if not _player_alive:
				return


func _player_hit() -> void:
	if _has_shield:
		_has_shield = false
		_shield_flash = 1.0
		_shake = 0.2
		return
	_invincible = INVINCIBLE_TIME
	_hp -= 1
	_shake = 0.4
	if _hp <= 0:
		_player_alive = false
		_running = false
		_ui_over.visible = true
		_game_over_elapsed = 0.01
		if _score > _high_score:
			_high_score = _score
		_ui_game_over_score.text = "SCORE  " + str(_score)
		_ui_game_over_high.text = "HI-SCORE  " + str(_high_score)
		_make_explosion(_player.get_center(), Color(0.2, 0.7, 1.0), 40)
		_make_ring(_player.get_center(), Color(0.2, 0.7, 1.0))


func _pause() -> void:
	_paused = true

func _unpause() -> void:
	_paused = false

func _ui_update() -> void:
	_ui_score.text = "SCORE  " + str(_score)
	_ui_hp.text = "HP  " + str(_hp) + " / " + str(MAX_HP)
	if _ui_missiles:
		var cd_txt := "" if _missile_cd <= 0.0 else " (" + str(snapped(_missile_cd, 0.1)) + "s)"
		_ui_missiles.text = "MISSILE  " + str(_missiles) + cd_txt
	if _ui_wpn:
		var stars = ""
		for _i in _wpn_level:
			stars += "★"
		_ui_wpn.text = "WPN  " + str(_wpn_level) + " " + stars
	if _ui_shield:
		_ui_shield.text = "[盾]" if _has_shield else ""
	if _ui_wave:
		var next_wave := maxi(int(ceil(maxf(WAVE_INTERVAL - _wave_timer, 0.0))), 0)
		_ui_wave.text = "BOSS  " + str(_boss.hp) + " / " + str(_boss.max_hp) if _boss != null else "WAVE  " + str(maxi(_wave_number, 1)) + "  NEXT " + str(next_wave) + "s"
	if _ui_store:
		var counts := {"盾": 0, "炸弹": 0, "导弹": 0}
		for p in _stored_pickups:
			match p:
				PickupType.SHIELD: counts["盾"] += 1
				PickupType.BOMB: counts["炸弹"] += 1
				PickupType.MISSILE: counts["导弹"] += 1
		_ui_store.text = "自动拾取: 武器 / HP   Q导弹:" + str(counts["导弹"]) + "   R炸弹:" + str(counts["炸弹"]) + "   T护盾:" + str(counts["盾"])


func _make_explosion(pos: Vector2, col: Color, size: float) -> void:
	var ex := Explosion.new()
	ex.pos = pos; ex.radius = 4.0
	ex.max_radius = size * 2.5; ex.col = col
	_explosions.append(ex)

	var spark_count := 8 + int(size / 5)
	for i in spark_count:
		var s := Spark.new()
		s.pos = pos
		var angle := TAU * float(i) / spark_count + randf_range(-0.3, 0.3)
		var sp := randf_range(80, 300)
		s.vel = Vector2(cos(angle), sin(angle)) * sp
		s.life = randf_range(0.2, 0.6); s.max_life = s.life; s.col = col
		_sparks.append(s)


func _draw() -> void:
	var offset := _get_shake_offset()
	if not _use_3d:
		_draw_background(offset)
		_draw_grid(offset)

		if _player_alive:
			_draw_player(offset)
			_draw_wingmen(offset)

		for b in _pbullets:
			_draw_bullet(b, offset)

		# Bullet trails
		for b in _pbullets:
			if b.trail:
				draw_circle(b.pos + offset - b.vel.normalized() * 8, 3.0, Color(b.col, 0.1))

		for e in _enemies:
			_draw_enemy(e, offset)

		if _boss != null:
			_draw_boss(offset)

		for eb in _ebullets:
			_draw_enemy_bullet(eb.pos, offset)

		# Homing missiles
		for m in _missile_pool:
			_draw_missile(m, offset)

	if not _use_3d:
		# Explosion rings
		for ex in _explosions:
			var ratio := ex.radius / ex.max_radius
			var alpha := 1.0 - ratio
			draw_circle(ex.pos + offset, ex.radius, ex.col * Color(1, 1, 1, alpha * 0.6))
			draw_arc(ex.pos + offset, ex.radius, 0, TAU, 16, Color(1, 1, 1, alpha * 0.8), 1.5)

		for s in _sparks:
			var ratio := s.life / s.max_life
			draw_circle(s.pos + offset, 2.0 * ratio + 1.0, s.col * Color(1, 1, 1, ratio))

	if not _use_3d:
		for p in _pickups:
			_draw_pickup(p, offset)

	for tfx in _text_fx:
		var alpha := tfx.life / tfx.max_life
		var draw_pos := tfx.pos + offset
		if _use_3d:
			draw_pos = _project_world_to_screen(tfx.pos, 1.6)
			if draw_pos == Vector2.INF:
				continue
		draw_string(
			ThemeDB.fallback_font, draw_pos,
			tfx.text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16,
			tfx.col * Color(1, 1, 1, alpha)
		)

	if not _use_3d:
		# Ring FX
		for rfx in _ring_fx:
			var ratio := rfx.radius / rfx.max_radius
			var alpha := 1.0 - ratio
			draw_arc(rfx.pos + offset, rfx.radius, 0, TAU, 24,
				rfx.col * Color(1, 1, 1, alpha), rfx.line_width * alpha)

	_draw_hud_chrome()
	_draw_boundary_warning()

	# Combo display
	if _combo > 1 and _combo_display_timer > 0.0:
		var combo_alpha := minf(_combo_display_timer * 2.0, 1.0)
		var combo_text := str(_combo) + "x COMBO!"
		draw_string(ThemeDB.fallback_font,
			Vector2(VW / 2.0 - 40, 92), combo_text,
			HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(1.0, 0.9, 0.3, combo_alpha))

		# Combo timer bar
		if _combo_bar > 0.0:
			var bar_w := 140.0
			var bar_x := VW / 2.0 - bar_w / 2.0
			var bar_y := 118.0
			draw_rect(Rect2(bar_x, bar_y, bar_w, 3), Color(0.2, 0.2, 0.2, 0.5))
			draw_rect(Rect2(bar_x, bar_y, bar_w * _combo_bar, 3),
				Color(1.0, 0.9, 0.3, combo_alpha))

	# Wave warning
	if _wave_warning > 0.0:
		var alpha := sin(_wave_warning * 8.0) * 0.5 + 0.5
		draw_rect(Rect2(0.0, VH / 2.0 - 28.0, VW, 56.0), Color(0.3, 0.04, 0.08, alpha * 0.18))
		draw_string(ThemeDB.fallback_font,
			Vector2(VW / 2.0 - 70, VH / 2.0),
			"WAVE " + str(_wave_number) + " INCOMING!",
			HORIZONTAL_ALIGNMENT_CENTER, -1, 22,
			Color(1.0, 0.3, 0.3, alpha))

	if _boss_warning > 0.0:
		var boss_alpha := sin(_boss_warning * 10.0) * 0.35 + 0.65
		draw_rect(Rect2(0.0, VH / 2.0 - 40.0, VW, 80.0), Color(0.45, 0.02, 0.08, boss_alpha * 0.2))
		draw_string(ThemeDB.fallback_font,
			Vector2(VW / 2.0 - 140.0, VH / 2.0 + 6.0),
			"WARNING // BOSS APPROACHING",
			HORIZONTAL_ALIGNMENT_CENTER, -1, 26,
			Color(1.0, 0.45, 0.45, boss_alpha))

	# Weapon upgrade flash
	if _weapon_up_flash > 0.0:
		var alpha := _weapon_up_flash * 0.15
		draw_rect(Rect2(Vector2.ZERO, Vector2(VW, VH)), Color(0.3, 1.0, 0.8, alpha))

	# Paused overlay
	if _paused:
		draw_rect(Rect2(Vector2.ZERO, Vector2(VW, VH)), Color(0, 0, 0, 0.5))
		draw_string(ThemeDB.fallback_font,
			Vector2(VW / 2.0 - 40, VH / 2.0 - 20),
			"已暂停",
			HORIZONTAL_ALIGNMENT_CENTER, -1, 32,
			Color(0.3, 0.8, 1.0, 0.9))
		draw_string(ThemeDB.fallback_font,
			Vector2(VW / 2.0 - 80, VH / 2.0 + 30),
			"按 ESC 继续",
			HORIZONTAL_ALIGNMENT_CENTER, -1, 18,
			Color(0.7, 0.7, 0.7, 0.8))


func _draw_boundary_warning() -> void:
	var base_alpha := 0.06 + _edge_warning * 0.2
	var pulse := 0.65 + 0.35 * sin(_elapsed * 8.0)
	var edge_alpha := base_alpha * pulse

	var safe_left := 0.0
	var safe_right := float(VW)
	if _use_3d:
		safe_left = PLAYER_SAFE_MARGIN_X_3D
		safe_right = VW - PLAYER_SAFE_MARGIN_X_3D

	draw_rect(Rect2(0.0, 0.0, safe_left, VH), Color(0.04, 0.09, 0.16, edge_alpha * 0.55))
	draw_rect(Rect2(safe_right, 0.0, VW - safe_right, VH), Color(0.04, 0.09, 0.16, edge_alpha * 0.55))

	draw_rect(Rect2(safe_left - 3.0, 0.0, 3.0, VH), Color(0.12, 0.45, 0.9, edge_alpha))
	draw_rect(Rect2(safe_right, 0.0, 3.0, VH), Color(0.12, 0.45, 0.9, edge_alpha))

	for i in range(10):
		var y := 120.0 + float(i) * 92.0
		var seg_alpha := edge_alpha * (0.65 + 0.35 * sin(_elapsed * 6.0 + float(i)))
		draw_rect(Rect2(safe_left - 8.0, y, 8.0, 36.0), Color(0.32, 0.85, 1.0, seg_alpha))
		draw_rect(Rect2(safe_right + 3.0, y, 8.0, 36.0), Color(0.32, 0.85, 1.0, seg_alpha))

	if _use_3d:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(VW / 2.0 - 52.0, VH - 18.0),
			"安全航道",
			HORIZONTAL_ALIGNMENT_CENTER, -1, 14,
			Color(0.4, 0.86, 1.0, 0.28 + edge_alpha * 0.5)
		)

	if _edge_warning > 0.08:
		var warn_alpha := _edge_warning * pulse
		draw_string(
			ThemeDB.fallback_font,
			Vector2(VW / 2.0 - 44.0, VH - 34.0),
			"边界警示",
			HORIZONTAL_ALIGNMENT_CENTER, -1, 16,
			Color(0.45, 0.9, 1.0, warn_alpha)
		)


func _get_shake_offset() -> Vector2:
	if _shake <= 0.0: return Vector2.ZERO
	return Vector2(
		randf_range(-1.0, 1.0) * _shake * _shake_intensity,
		randf_range(-1.0, 1.0) * _shake * _shake_intensity
	)


func _setup_3d_world() -> void:
	if _world_root != null and is_instance_valid(_world_root):
		return

	_world_root = Node3D.new()
	_world_root.name = "World3D"
	add_child(_world_root)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.025, 0.055)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.5, 0.7)
	env.ambient_light_energy = 1.1

	var env_node := WorldEnvironment.new()
	env_node.environment = env
	_world_root.add_child(env_node)

	_camera_3d = Camera3D.new()
	_camera_3d.name = "Camera3D"
	_camera_3d.projection = Camera3D.PROJECTION_PERSPECTIVE
	_camera_3d.fov = 37.0
	_camera_3d.position = Vector3(0.0, 58.0, 58.0)
	_world_root.add_child(_camera_3d)
	_camera_3d.look_at(Vector3(0.0, 0.5, 0.0), Vector3.UP)
	_camera_3d.current = true

	var sun := DirectionalLight3D.new()
	sun.light_energy = 2.0
	sun.light_color = Color(0.9, 0.95, 1.0)
	sun.rotation_degrees = Vector3(-58.0, -25.0, 0.0)
	_world_root.add_child(sun)

	var fill := OmniLight3D.new()
	fill.position = Vector3(0.0, 10.0, 12.0)
	fill.omni_range = 80.0
	fill.light_energy = 0.8
	fill.light_color = Color(0.25, 0.55, 1.0)
	_world_root.add_child(fill)

	_ground_root_3d = Node3D.new()
	_ground_root_3d.name = "Ground3D"
	_world_root.add_child(_ground_root_3d)

	var floor := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(GROUND_HALF_WIDTH * 2.0, 0.25, GROUND_HALF_LENGTH * 2.0)
	floor.mesh = floor_mesh
	floor.position = Vector3(0.0, -0.8, 0.0)
	floor.material_override = _make_material(Color(0.03, 0.06, 0.11), Color(0.0, 0.08, 0.14), 0.08, 0.92)
	_ground_root_3d.add_child(floor)

	var border_material := _make_material(Color(0.06, 0.16, 0.26), Color(0.0, 0.3, 0.5), 0.05, 0.55)
	for side in [-1.0, 1.0]:
		var border := MeshInstance3D.new()
		var border_mesh := BoxMesh.new()
		border_mesh.size = Vector3(1.1, 0.08, GROUND_HALF_LENGTH * 2.0)
		border.mesh = border_mesh
		border.position = Vector3(side * (WORLD_HALF_WIDTH + 0.2), -0.58, 0.0)
		border.material_override = border_material
		_ground_root_3d.add_child(border)

		for beacon_z in [-96.0, -72.0, -48.0, -24.0, 0.0, 24.0, 48.0, 72.0, 96.0]:
			var beacon := _make_box_part(Vector3(0.22, 1.6, 0.22), Color(0.12, 0.24, 0.34), Color(0.0, 0.18, 0.28), 0.08, 0.42)
			beacon.position = Vector3(side * (WORLD_HALF_WIDTH - 0.9), 0.0, beacon_z)
			_ground_root_3d.add_child(beacon)

			var beacon_cap := _make_sphere_part(0.18, Color(0.32, 0.82, 1.0), Color(0.12, 0.6, 1.0), 0.0, 0.08)
			beacon_cap.position = Vector3(side * (WORLD_HALF_WIDTH - 0.9), 0.95, beacon_z)
			_ground_root_3d.add_child(beacon_cap)

	_ground_lines_3d.clear()
	for i in range(42):
		var strip := MeshInstance3D.new()
		var strip_mesh := BoxMesh.new()
		strip_mesh.size = Vector3(GROUND_HALF_WIDTH - 8.0, 0.03, 0.35)
		strip.mesh = strip_mesh
		strip.position = Vector3(0.0, -0.56, float(i) * 6.0 - GROUND_HALF_LENGTH)
		strip.material_override = _make_material(Color(0.15, 0.28, 0.4), Color(0.02, 0.2, 0.35), 0.05, 0.4)
		_ground_root_3d.add_child(strip)
		_ground_lines_3d.append(strip)

	_ground_center_markers_3d.clear()
	for i in range(24):
		var center_marker := MeshInstance3D.new()
		var center_mesh := BoxMesh.new()
		center_mesh.size = Vector3(1.2, 0.04, 2.2)
		center_marker.mesh = center_mesh
		center_marker.position = Vector3(0.0, -0.54, float(i) * 10.0 - GROUND_HALF_LENGTH)
		center_marker.material_override = _make_material(Color(0.55, 0.62, 0.72), Color(0.18, 0.3, 0.42), 0.02, 0.24)
		_ground_root_3d.add_child(center_marker)
		_ground_center_markers_3d.append(center_marker)

	var safe_left_world := _to_world(Vector2(PLAYER_SAFE_MARGIN_X_3D, VH * 0.5), -0.52).x
	var safe_right_world := _to_world(Vector2(VW - PLAYER_SAFE_MARGIN_X_3D, VH * 0.5), -0.52).x
	_ground_safe_guides_3d.clear()
	for x_pos in [safe_left_world, safe_right_world]:
		var guide := MeshInstance3D.new()
		var guide_mesh := BoxMesh.new()
		guide_mesh.size = Vector3(0.55, 0.04, GROUND_HALF_LENGTH * 2.0)
		guide.mesh = guide_mesh
		guide.position = Vector3(x_pos, -0.52, 0.0)
		guide.material_override = _make_material(Color(0.2, 0.7, 1.0), Color(0.08, 0.45, 0.8), 0.0, 0.18)
		_ground_root_3d.add_child(guide)
		_ground_safe_guides_3d.append(guide)

	_entity_root_3d = Node3D.new()
	_entity_root_3d.name = "Entities3D"
	_world_root.add_child(_entity_root_3d)

	_player_root_3d = Node3D.new()
	_player_root_3d.name = "Player3D"
	_entity_root_3d.add_child(_player_root_3d)

	_wingmen_root_3d = Node3D.new()
	_wingmen_root_3d.name = "Wingmen3D"
	_entity_root_3d.add_child(_wingmen_root_3d)

	_bullets_root_3d = Node3D.new()
	_bullets_root_3d.name = "PlayerBullets3D"
	_entity_root_3d.add_child(_bullets_root_3d)

	_enemy_bullets_root_3d = Node3D.new()
	_enemy_bullets_root_3d.name = "EnemyBullets3D"
	_entity_root_3d.add_child(_enemy_bullets_root_3d)

	_enemies_root_3d = Node3D.new()
	_enemies_root_3d.name = "Enemies3D"
	_entity_root_3d.add_child(_enemies_root_3d)

	_pickups_root_3d = Node3D.new()
	_pickups_root_3d.name = "Pickups3D"
	_entity_root_3d.add_child(_pickups_root_3d)

	_fx_root_3d = Node3D.new()
	_fx_root_3d.name = "FX3D"
	_entity_root_3d.add_child(_fx_root_3d)

	_missiles_root_3d = Node3D.new()
	_missiles_root_3d.name = "Missiles3D"
	_entity_root_3d.add_child(_missiles_root_3d)

	_boss_root_3d = Node3D.new()
	_boss_root_3d.name = "Boss3D"
	_entity_root_3d.add_child(_boss_root_3d)

	_clear_3d_dynamic_visuals()
	_camera_focus_ready = false
	_sync_3d_world(0.0)


func _clear_children(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	for child in node.get_children():
		child.queue_free()


func _clear_3d_dynamic_visuals() -> void:
	for root in [_player_root_3d, _wingmen_root_3d, _bullets_root_3d, _enemy_bullets_root_3d, _enemies_root_3d, _pickups_root_3d, _fx_root_3d, _missiles_root_3d, _boss_root_3d]:
		_clear_children(root)
	_player_visual_3d = null
	_shield_visual_3d = null
	_camera_focus_ready = false


func _to_world(pos: Vector2, height: float = 0.0) -> Vector3:
	return Vector3((pos.x - VW * 0.5) * WORLD_SCALE, height, (pos.y - VH * 0.5) * WORLD_SCALE)


func _project_world_to_screen(pos: Vector2, height: float = 1.0) -> Vector2:
	if _camera_3d == null or not is_instance_valid(_camera_3d):
		return Vector2.INF
	var world_pos := _to_world(pos, height)
	if _camera_3d.is_position_behind(world_pos):
		return Vector2.INF
	return _camera_3d.unproject_position(world_pos)


func _prune_container(root: Node3D, active_ids: Dictionary) -> void:
	if root == null or not is_instance_valid(root):
		return
	for child in root.get_children():
		var entity_id := str(child.get_meta("entity_id", ""))
		if entity_id == "" or not active_ids.has(entity_id):
			child.queue_free()


func _make_material(albedo: Color, emission: Color = Color.BLACK, metallic: float = 0.18, roughness: float = 0.35) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.metallic = metallic
	material.roughness = roughness
	material.emission_enabled = emission != Color.BLACK
	material.emission = emission
	material.emission_energy_multiplier = 1.2
	if albedo.a < 0.999:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.no_depth_test = false
	return material


func _make_box_part(size: Vector3, color: Color, emission: Color = Color.BLACK, metallic: float = 0.22, roughness: float = 0.32) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = _make_material(color, emission, metallic, roughness)
	return part


func _make_sphere_part(radius: float, color: Color, emission: Color = Color.BLACK, metallic: float = 0.18, roughness: float = 0.28) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = _make_material(color, emission, metallic, roughness)
	return part


func _make_cylinder_part(radius: float, height: float, color: Color, emission: Color = Color.BLACK, metallic: float = 0.25, roughness: float = 0.3) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = _make_material(color, emission, metallic, roughness)
	return part


func _make_capsule_part(radius: float, height: float, color: Color, emission: Color = Color.BLACK, metallic: float = 0.2, roughness: float = 0.25) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = _make_material(color, emission, metallic, roughness)
	return part


func _instantiate_model_scene(path: String) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var scene = _model_scene_cache.get(path)
	if scene == null:
		var loaded = load(path)
		if loaded is PackedScene:
			scene = loaded
			_model_scene_cache[path] = scene
	if scene is PackedScene:
		var instance = scene.instantiate()
		if instance is Node3D:
			return instance
	return null


func _make_player_model() -> Node3D:
	var asset := _instantiate_model_scene(MODEL_PLAYER_PATH)
	if asset != null:
		return asset
	var root := Node3D.new()

	var body := _make_box_part(Vector3(0.85, 0.36, 2.6), Color(0.08, 0.14, 0.2), Color(0.0, 0.2, 0.35))
	body.position = Vector3(0.0, 0.18, 0.0)
	root.add_child(body)

	var nose := _make_box_part(Vector3(0.46, 0.24, 0.9), Color(0.22, 0.52, 0.75), Color(0.1, 0.35, 0.6), 0.1, 0.18)
	nose.position = Vector3(0.0, 0.28, -1.35)
	root.add_child(nose)

	var wing := _make_box_part(Vector3(2.25, 0.08, 1.05), Color(0.1, 0.22, 0.34), Color(0.0, 0.14, 0.22), 0.22, 0.32)
	wing.position = Vector3(0.0, 0.08, 0.18)
	root.add_child(wing)

	for side in [-1.0, 1.0]:
		var tail_fin := _make_box_part(Vector3(0.2, 0.48, 0.68), Color(0.12, 0.2, 0.3), Color(0.0, 0.16, 0.24))
		tail_fin.position = Vector3(side * 0.32, 0.4, 0.92)
		root.add_child(tail_fin)

		var engine := _make_cylinder_part(0.13, 0.55, Color(0.2, 0.24, 0.3), Color(0.0, 0.2, 0.28))
		engine.rotation_degrees.x = 90.0
		engine.position = Vector3(side * 0.28, 0.05, 0.92)
		root.add_child(engine)

	var canopy := _make_sphere_part(0.22, Color(0.45, 0.88, 1.0, 0.72), Color(0.15, 0.4, 0.7), 0.05, 0.1)
	canopy.position = Vector3(0.0, 0.32, -0.35)
	root.add_child(canopy)

	var core := _make_sphere_part(0.12, Color(0.6, 0.95, 1.0), Color(0.2, 0.8, 1.0), 0.0, 0.05)
	core.position = Vector3(0.0, 0.18, 0.2)
	root.add_child(core)

	return root


func _make_wingman_model() -> Node3D:
	var asset := _instantiate_model_scene(MODEL_WINGMAN_PATH)
	if asset != null:
		return asset
	var root := Node3D.new()
	var body := _make_box_part(Vector3(0.46, 0.2, 1.0), Color(0.08, 0.2, 0.32), Color(0.0, 0.15, 0.24))
	body.position = Vector3(0.0, 0.12, 0.0)
	root.add_child(body)
	var wing := _make_box_part(Vector3(1.0, 0.05, 0.44), Color(0.14, 0.3, 0.42), Color(0.0, 0.1, 0.18))
	wing.position = Vector3(0.0, 0.06, 0.1)
	root.add_child(wing)
	var eye := _make_sphere_part(0.1, Color(0.6, 0.95, 1.0), Color(0.15, 0.8, 0.55), 0.0, 0.05)
	eye.position = Vector3(0.0, 0.18, -0.32)
	root.add_child(eye)
	return root


func _make_enemy_model(enemy_hp: int) -> Node3D:
	var asset_path := MODEL_ENEMY_HEAVY_PATH
	if enemy_hp <= 1:
		asset_path = MODEL_ENEMY_LIGHT_PATH
	elif enemy_hp <= 3:
		asset_path = MODEL_ENEMY_MID_PATH
	var asset := _instantiate_model_scene(asset_path)
	if asset != null:
		return asset
	var root := Node3D.new()
	match enemy_hp:
		1:
			var body := _make_box_part(Vector3(0.62, 0.22, 1.15), Color(0.36, 0.08, 0.12), Color(0.5, 0.1, 0.08), 0.18, 0.38)
			body.position = Vector3(0.0, 0.12, 0.0)
			root.add_child(body)
			var wing := _make_box_part(Vector3(1.15, 0.04, 0.34), Color(0.55, 0.14, 0.16), Color(0.4, 0.06, 0.02), 0.16, 0.42)
			wing.position = Vector3(0.0, 0.06, 0.12)
			root.add_child(wing)
			var eye := _make_sphere_part(0.11, Color(1.0, 0.8, 0.35), Color(1.0, 0.5, 0.1), 0.0, 0.05)
			eye.position = Vector3(0.0, 0.18, -0.28)
			root.add_child(eye)
		3:
			var body_mid := _make_box_part(Vector3(0.95, 0.28, 1.75), Color(0.4, 0.18, 0.08), Color(0.45, 0.18, 0.04), 0.2, 0.34)
			body_mid.position = Vector3(0.0, 0.15, 0.0)
			root.add_child(body_mid)
			var wing_mid := _make_box_part(Vector3(1.8, 0.06, 0.75), Color(0.7, 0.26, 0.1), Color(0.5, 0.12, 0.02), 0.2, 0.4)
			wing_mid.position = Vector3(0.0, 0.06, 0.1)
			root.add_child(wing_mid)
			for side in [-1.0, 1.0]:
				var nacelle := _make_cylinder_part(0.12, 0.45, Color(0.28, 0.18, 0.12), Color(0.35, 0.15, 0.08))
				nacelle.rotation_degrees.x = 90.0
				nacelle.position = Vector3(side * 0.62, 0.1, 0.44)
				root.add_child(nacelle)
			var visor := _make_box_part(Vector3(0.34, 0.14, 0.5), Color(1.0, 0.74, 0.3), Color(1.0, 0.5, 0.12), 0.0, 0.06)
			visor.position = Vector3(0.0, 0.24, -0.52)
			root.add_child(visor)
		_:
			var hull := _make_box_part(Vector3(1.55, 0.4, 2.5), Color(0.22, 0.06, 0.3), Color(0.35, 0.08, 0.45), 0.26, 0.32)
			hull.position = Vector3(0.0, 0.22, 0.0)
			root.add_child(hull)
			var wing_heavy := _make_box_part(Vector3(2.7, 0.08, 1.35), Color(0.45, 0.08, 0.55), Color(0.25, 0.02, 0.4), 0.24, 0.36)
			wing_heavy.position = Vector3(0.0, 0.08, 0.12)
			root.add_child(wing_heavy)
			for side in [-1.0, 1.0]:
				var cannon := _make_cylinder_part(0.16, 0.75, Color(0.28, 0.12, 0.32), Color(0.25, 0.1, 0.34))
				cannon.rotation_degrees.x = 90.0
				cannon.position = Vector3(side * 0.86, 0.14, -0.22)
				root.add_child(cannon)
			var core := _make_sphere_part(0.18, Color(1.0, 0.72, 0.35), Color(1.0, 0.45, 0.12), 0.0, 0.04)
			core.position = Vector3(0.0, 0.28, -0.38)
			root.add_child(core)
	return root


func _make_boss_model() -> Node3D:
	var asset := _instantiate_model_scene(MODEL_BOSS_PATH)
	if asset != null:
		return asset
	var root := Node3D.new()
	var hull := _make_box_part(Vector3(4.8, 0.85, 6.0), Color(0.22, 0.06, 0.16), Color(0.22, 0.02, 0.08), 0.28, 0.3)
	hull.position = Vector3(0.0, 0.45, 0.0)
	root.add_child(hull)
	var wing := _make_box_part(Vector3(7.4, 0.12, 2.0), Color(0.36, 0.08, 0.18), Color(0.24, 0.02, 0.08), 0.3, 0.34)
	wing.position = Vector3(0.0, 0.14, 0.4)
	root.add_child(wing)
	var armor := _make_box_part(Vector3(2.0, 0.42, 2.8), Color(0.42, 0.1, 0.24), Color(0.3, 0.04, 0.14), 0.18, 0.24)
	armor.position = Vector3(0.0, 0.82, -0.4)
	root.add_child(armor)
	for side in [-1.0, 1.0]:
		var blade := _make_box_part(Vector3(1.2, 0.22, 2.3), Color(0.48, 0.08, 0.18), Color(0.24, 0.02, 0.04), 0.24, 0.3)
		blade.position = Vector3(side * 2.35, 0.18, 0.55)
		blade.rotation_degrees.z = side * 20.0
		root.add_child(blade)
		var thruster := _make_cylinder_part(0.28, 0.72, Color(0.3, 0.12, 0.16), Color(0.8, 0.18, 0.08))
		thruster.rotation_degrees.x = 90.0
		thruster.position = Vector3(side * 2.1, 0.22, 2.15)
		root.add_child(thruster)
	var canopy := _make_sphere_part(0.52, Color(0.34, 0.76, 1.0, 0.75), Color(0.25, 0.7, 1.0), 0.02, 0.08)
	canopy.position = Vector3(0.0, 0.9, -1.15)
	root.add_child(canopy)
	var core := _make_sphere_part(0.42, Color(1.0, 0.82, 0.9), Color(1.0, 0.25, 0.55), 0.0, 0.04)
	core.position = Vector3(0.0, 0.68, -0.15)
	root.add_child(core)
	return root


func _make_bullet_model(col: Color) -> Node3D:
	var asset := _instantiate_model_scene(MODEL_PLAYER_BULLET_PATH)
	if asset != null:
		return asset
	var root := Node3D.new()
	var shot := _make_capsule_part(0.08, 0.5, col, col.lightened(0.4), 0.0, 0.08)
	shot.rotation_degrees.x = 90.0
	root.add_child(shot)
	return root


func _make_enemy_bullet_model() -> Node3D:
	var asset := _instantiate_model_scene(MODEL_ENEMY_BULLET_PATH)
	if asset != null:
		return asset
	var root := Node3D.new()
	var shot := _make_sphere_part(0.14, Color(1.0, 0.35, 0.18), Color(1.0, 0.55, 0.1), 0.0, 0.06)
	root.add_child(shot)
	return root


func _make_pickup_model(pickup_type: int) -> Node3D:
	var asset := _instantiate_model_scene(PICKUP_MODEL_PATHS.get(pickup_type, ""))
	if asset != null:
		return asset
	var root := Node3D.new()
	match pickup_type:
		PickupType.WEAPON:
			var weapon := _make_box_part(Vector3(0.45, 0.45, 0.45), Color(1.0, 0.82, 0.25), Color(1.0, 0.7, 0.18), 0.0, 0.18)
			weapon.rotation_degrees = Vector3(45.0, 0.0, 45.0)
			root.add_child(weapon)
		PickupType.HEAL:
			var h1 := _make_box_part(Vector3(0.25, 0.8, 0.25), Color(0.3, 1.0, 0.45), Color(0.15, 0.7, 0.2), 0.0, 0.1)
			var h2 := _make_box_part(Vector3(0.8, 0.25, 0.25), Color(0.3, 1.0, 0.45), Color(0.15, 0.7, 0.2), 0.0, 0.1)
			root.add_child(h1)
			root.add_child(h2)
		PickupType.SHIELD:
			var shield := _make_sphere_part(0.34, Color(0.3, 0.65, 1.0, 0.42), Color(0.2, 0.6, 1.0), 0.0, 0.08)
			root.add_child(shield)
		PickupType.BOMB:
			var bomb := _make_sphere_part(0.28, Color(1.0, 0.2, 0.2), Color(1.0, 0.3, 0.12), 0.0, 0.08)
			root.add_child(bomb)
		PickupType.MISSILE:
			var missile := _make_capsule_part(0.12, 0.5, Color(1.0, 0.55, 0.22), Color(1.0, 0.35, 0.12), 0.0, 0.08)
			missile.rotation_degrees.x = 90.0
			root.add_child(missile)
	return root


func _make_missile_model() -> Node3D:
	var asset := _instantiate_model_scene(MODEL_MISSILE_PATH)
	if asset != null:
		return asset
	var root := Node3D.new()
	var body := _make_capsule_part(0.11, 0.65, Color(0.95, 0.58, 0.22), Color(1.0, 0.34, 0.12), 0.0, 0.08)
	body.rotation_degrees.x = 90.0
	root.add_child(body)
	for side in [-1.0, 1.0]:
		var fin := _make_box_part(Vector3(0.05, 0.18, 0.24), Color(0.95, 0.52, 0.2), Color(0.8, 0.24, 0.08), 0.0, 0.12)
		fin.position = Vector3(side * 0.12, 0.0, 0.18)
		root.add_child(fin)
	return root


func _make_explosion_fx_model(col: Color) -> Node3D:
	var root := Node3D.new()
	var outer := _make_sphere_part(0.42, col * Color(1, 1, 1, 0.35), col.lightened(0.2), 0.0, 0.08)
	root.add_child(outer)
	var core := _make_sphere_part(0.22, col.lightened(0.35), col.lightened(0.45), 0.0, 0.04)
	core.position.y = 0.06
	root.add_child(core)
	var ring := _make_cylinder_part(0.32, 0.08, col * Color(1, 1, 1, 0.3), col, 0.0, 0.08)
	ring.position.y = -0.02
	root.add_child(ring)
	return root


func _make_ring_fx_model(col: Color) -> Node3D:
	var root := Node3D.new()
	var ring := _make_cylinder_part(0.45, 0.04, col * Color(1, 1, 1, 0.45), col, 0.0, 0.08)
	root.add_child(ring)
	return root


func _make_spark_fx_model(col: Color) -> Node3D:
	var root := Node3D.new()
	var core := _make_capsule_part(0.05, 0.42, col.lightened(0.25), col.lightened(0.4), 0.0, 0.05)
	core.rotation_degrees.x = 90.0
	root.add_child(core)
	return root


func _sync_ground_3d() -> void:
	for i in _ground_lines_3d.size():
		var strip := _ground_lines_3d[i]
		if strip == null or not is_instance_valid(strip):
			continue
		var scroll_speed := 8.0 + minf(_elapsed * 0.18, 8.0) + float(_wave_number) * 0.4
		strip.position.z = fmod(float(i) * 6.0 + _elapsed * scroll_speed, GROUND_HALF_LENGTH * 2.0) - GROUND_HALF_LENGTH
		strip.scale.x = 1.0 + sin(_elapsed * 1.8 + float(i)) * 0.06

	for i in _ground_center_markers_3d.size():
		var marker := _ground_center_markers_3d[i]
		if marker == null or not is_instance_valid(marker):
			continue
		var center_speed := 11.0 + minf(_elapsed * 0.22, 10.0) + float(_wave_number) * 0.55
		marker.position.z = fmod(float(i) * 10.0 + _elapsed * center_speed, GROUND_HALF_LENGTH * 2.0) - GROUND_HALF_LENGTH
		marker.scale = Vector3.ONE * (1.0 + sin(_elapsed * 2.6 + float(i) * 0.35) * 0.04)


func _sync_3d_world(_delta: float) -> void:
	if not _use_3d or _world_root == null or not is_instance_valid(_world_root):
		return

	_sync_ground_3d()
	_sync_camera_3d()
	_sync_player_3d()
	_sync_wingmen_3d()
	_sync_bullets_3d()
	_sync_enemy_bullets_3d()
	_sync_enemies_3d()
	_sync_pickups_3d()
	_sync_fx_3d()
	_sync_missiles_3d()
	_sync_boss_3d()


func _sync_camera_3d() -> void:
	if _camera_3d == null or not is_instance_valid(_camera_3d):
		return
	var player_center := _player.get_center() if _player_alive else Vector2(VW * 0.5, VH * 0.72)
	var target_world := _to_world(player_center, 0.0)
	var desired_focus := Vector3(target_world.x * 0.42, 0.45, target_world.z - 2.0)
	if not _camera_focus_ready:
		_camera_focus_3d = desired_focus
		_camera_focus_ready = true
	else:
		_camera_focus_3d = _camera_focus_3d.lerp(desired_focus, 0.055)
	var shake_x := sin(_elapsed * 28.0) * _shake * 1.25
	var shake_y := cos(_elapsed * 24.0) * _shake * 0.8
	var cam_pos := Vector3(_camera_focus_3d.x * 0.98 + shake_x, 62.0 + shake_y, 68.0 + absf(_player_bank) * 1.1 - clampf(_elapsed * 0.015, 0.0, 1.2))
	_camera_3d.position = _camera_3d.position.lerp(cam_pos, 0.08)
	_camera_3d.fov = lerpf(_camera_3d.fov, 36.0 + _shake * 2.6 + clampf(absf(_player_bank) * 1.2, 0.0, 0.8), 0.08)
	_camera_3d.look_at(_camera_focus_3d + Vector3(0.0, 0.0, -_shake * 0.12), Vector3.UP)


func _sync_player_3d() -> void:
	if _player_root_3d == null or not is_instance_valid(_player_root_3d):
		return

	if _player_alive:
		if _player_visual_3d == null or not is_instance_valid(_player_visual_3d):
			_player_visual_3d = _make_player_model()
			_player_root_3d.add_child(_player_visual_3d)
			_shield_visual_3d = _make_sphere_part(0.7, Color(0.3, 0.65, 1.0, 0.16), Color(0.22, 0.65, 1.0), 0.0, 0.05)
			_shield_visual_3d.position = Vector3(0.0, 0.18, 0.0)
			_player_visual_3d.add_child(_shield_visual_3d)
		_player_visual_3d.visible = true
		_player_visual_3d.position = _to_world(_player.get_center(), 1.25 + sin(_elapsed * 8.0) * 0.04)
		_player_visual_3d.rotation = Vector3(_player_bank * 0.08, 0.0, -_player_bank * 0.55)
		_player_visual_3d.scale = Vector3.ONE * (1.0 + _weapon_up_flash * 0.08)
		if _shield_visual_3d != null and is_instance_valid(_shield_visual_3d):
			_shield_visual_3d.visible = _has_shield or _shield_flash > 0.0
			var shield_scale := 1.0 + _shield_flash * 0.35
			_shield_visual_3d.scale = Vector3.ONE * shield_scale
	elif _player_visual_3d != null and is_instance_valid(_player_visual_3d):
		_player_visual_3d.visible = false


func _sync_wingmen_3d() -> void:
	if _wingmen_root_3d == null or not is_instance_valid(_wingmen_root_3d):
		return

	var active_ids := {}
	var base_center := _player.get_center()
	for wm in _wingmen:
		var entity_id := str(wm.get_instance_id())
		active_ids[entity_id] = true
		if wm.visual == null or not is_instance_valid(wm.visual):
			wm.visual = _make_wingman_model()
			wm.visual.set_meta("entity_id", entity_id)
			_wingmen_root_3d.add_child(wm.visual)
		var bob := sin(_elapsed * 6.0 + wm.offset.x * 0.04) * 0.06
		wm.visual.position = _to_world(base_center + wm.offset, 1.0 + bob)
		wm.visual.rotation = Vector3(0.0, sin(_elapsed * 3.0 + wm.offset.x * 0.01) * 0.12, -_player_bank * 0.35)
	_prune_container(_wingmen_root_3d, active_ids)


func _sync_bullets_3d() -> void:
	var active_ids := {}
	for b in _pbullets:
		var entity_id := str(b.get_instance_id())
		active_ids[entity_id] = true
		if b.visual == null or not is_instance_valid(b.visual):
			b.visual = _make_bullet_model(b.col)
			b.visual.set_meta("entity_id", entity_id)
			_bullets_root_3d.add_child(b.visual)
		b.visual.position = _to_world(b.pos, 0.8)
		var dir := Vector3(b.vel.x, 0.0, b.vel.y).normalized()
		if dir.length() > 0.0:
			b.visual.look_at(b.visual.position + dir, Vector3.UP, true)
	_prune_container(_bullets_root_3d, active_ids)


func _sync_enemy_bullets_3d() -> void:
	var active_ids := {}
	for eb in _ebullets:
		var entity_id := str(eb.get_instance_id())
		active_ids[entity_id] = true
		if eb.visual == null or not is_instance_valid(eb.visual):
			eb.visual = _make_enemy_bullet_model()
			eb.visual.set_meta("entity_id", entity_id)
			_enemy_bullets_root_3d.add_child(eb.visual)
		eb.visual.position = _to_world(eb.pos, 0.65)
		var dir := Vector3(eb.vel.x, 0.0, eb.vel.y).normalized()
		if dir.length() > 0.0:
			eb.visual.look_at(eb.visual.position + dir, Vector3.UP, true)
	_prune_container(_enemy_bullets_root_3d, active_ids)


func _sync_enemies_3d() -> void:
	var active_ids := {}
	for e in _enemies:
		var entity_id := str(e.get_instance_id())
		active_ids[entity_id] = true
		if e.visual == null or not is_instance_valid(e.visual):
			e.visual = _make_enemy_model(e.max_hp)
			e.visual.set_meta("entity_id", entity_id)
			_enemies_root_3d.add_child(e.visual)
		var hover := sin(e.phase * 2.0 + float(e.max_hp)) * 0.08
		e.visual.position = _to_world(e.pos, 1.0 + float(e.max_hp) * 0.015 + hover)
		e.visual.rotation = Vector3(0.0, PI + sin(e.phase * 0.7) * 0.08, sin(e.phase * 2.0) * 0.12)
		e.visual.scale = Vector3.ONE * (1.0 + e.hit_flash * 0.08)
	_prune_container(_enemies_root_3d, active_ids)


func _sync_pickups_3d() -> void:
	var active_ids := {}
	for p in _pickups:
		var entity_id := str(p.get_instance_id())
		active_ids[entity_id] = true
		if p.visual == null or not is_instance_valid(p.visual):
			p.visual = _make_pickup_model(p.type)
			p.visual.set_meta("entity_id", entity_id)
			_pickups_root_3d.add_child(p.visual)
		p.visual.position = _to_world(Vector2(p.pos.x, p.pos.y + sin(p.bob) * 3.0), 0.9 + sin(p.bob * 1.5) * 0.12)
		p.visual.rotation = Vector3(p.rot * 0.25, p.rot, p.rot * 0.4)
	_prune_container(_pickups_root_3d, active_ids)


func _sync_fx_3d() -> void:
	if _fx_root_3d == null or not is_instance_valid(_fx_root_3d):
		return

	var active_ids := {}
	for ex in _explosions:
		var entity_id := "ex_%s" % str(ex.get_instance_id())
		active_ids[entity_id] = true
		if ex.visual == null or not is_instance_valid(ex.visual):
			ex.visual = _make_explosion_fx_model(ex.col)
			ex.visual.set_meta("entity_id", entity_id)
			_fx_root_3d.add_child(ex.visual)
		var fx_height := 1.0 + clampf(ex.max_radius * 0.002, 0.0, 0.35)
		ex.visual.position = _to_world(ex.pos, fx_height)
		ex.visual.scale = Vector3.ONE * maxf(ex.radius * 0.02, 0.24)
	for rfx in _ring_fx:
		var entity_id := "ring_%s" % str(rfx.get_instance_id())
		active_ids[entity_id] = true
		if rfx.visual == null or not is_instance_valid(rfx.visual):
			rfx.visual = _make_ring_fx_model(rfx.col)
			rfx.visual.set_meta("entity_id", entity_id)
			_fx_root_3d.add_child(rfx.visual)
		rfx.visual.position = _to_world(rfx.pos, 0.08)
		rfx.visual.scale = Vector3(maxf(rfx.radius * 0.02, 0.15), 1.0, maxf(rfx.radius * 0.02, 0.15))
	for s in _sparks:
		var entity_id := "spark_%s" % str(s.get_instance_id())
		active_ids[entity_id] = true
		if s.visual == null or not is_instance_valid(s.visual):
			s.visual = _make_spark_fx_model(s.col)
			s.visual.set_meta("entity_id", entity_id)
			_fx_root_3d.add_child(s.visual)
		s.visual.position = _to_world(s.pos, 1.0)
		s.visual.scale = Vector3.ONE * maxf(s.life / s.max_life, 0.18)
		var dir := Vector3(s.vel.x, 0.0, s.vel.y).normalized()
		if dir.length() > 0.0:
			s.visual.look_at(s.visual.position + dir, Vector3.UP, true)
	_prune_container(_fx_root_3d, active_ids)


func _sync_missiles_3d() -> void:
	var active_ids := {}
	for m in _missile_pool:
		var entity_id := str(m.get_instance_id())
		active_ids[entity_id] = true
		if m.visual == null or not is_instance_valid(m.visual):
			m.visual = _make_missile_model()
			m.visual.set_meta("entity_id", entity_id)
			_missiles_root_3d.add_child(m.visual)
		var dir := Vector3(cos(m.angle), 0.0, sin(m.angle))
		m.visual.position = _to_world(m.pos, 0.88 + sin(_elapsed * 18.0 + float(m.get_instance_id() % 17)) * 0.03)
		m.visual.look_at(m.visual.position + dir, Vector3.UP, true)
		m.visual.rotation.z += sin(_elapsed * 20.0 + float(m.get_instance_id() % 23)) * 0.08
	_prune_container(_missiles_root_3d, active_ids)


func _sync_boss_3d() -> void:
	if _boss_root_3d == null or not is_instance_valid(_boss_root_3d):
		return

	if _boss != null:
		var entity_id := str(_boss.get_instance_id())
		if _boss.visual == null or not is_instance_valid(_boss.visual):
			_boss.visual = _make_boss_model()
			_boss.visual.set_meta("entity_id", entity_id)
			_boss_root_3d.add_child(_boss.visual)
		var hover := sin(_boss.phase * 1.3) * 0.18
		_boss.visual.position = _to_world(_boss.pos, 1.8 + hover)
		_boss.visual.rotation = Vector3(sin(_boss.phase * 0.8) * 0.03, PI + sin(_boss.phase * 0.3) * 0.06, sin(_boss.phase * 0.5) * 0.05)
		_boss.visual.scale = Vector3.ONE * (_boss.scale * (1.0 + _boss.hit_flash * 0.05))
		_prune_container(_boss_root_3d, {entity_id: true})
	else:
		_prune_container(_boss_root_3d, {})


func _draw_background(offset: Vector2) -> void:
	draw_rect(Rect2(offset, Vector2(VW, VH)), Color(0.015, 0.025, 0.055))
	draw_circle(Vector2(VW * 0.22, VH * 0.18) + offset, 180.0, Color(0.08, 0.16, 0.4, 0.12))
	draw_circle(Vector2(VW * 0.8, VH * 0.28) + offset, 150.0, Color(0.24, 0.08, 0.38, 0.1))
	draw_circle(Vector2(VW * 0.5, VH * 0.82) + offset, 220.0, Color(0.04, 0.18, 0.3, 0.1))

	for nebula in _nebulae:
		var pulse := 0.92 + 0.08 * sin(_elapsed * 0.5 + nebula.phase)
		var c := nebula.pos + offset
		draw_circle(c, nebula.radius * pulse, nebula.col * Color(1, 1, 1, nebula.alpha))
		draw_circle(
			c + Vector2(cos(nebula.phase) * nebula.radius * 0.18, sin(nebula.phase * 1.3) * nebula.radius * 0.12),
			nebula.radius * 0.62 * pulse,
			nebula.col.lightened(0.2) * Color(1, 1, 1, nebula.alpha * 0.75)
		)

	for star in _stars:
		var bright := clampf(star.alpha + 0.18 * sin(_elapsed * 2.4 + star.phase), 0.12, 1.0)
		var p := star.pos + offset
		var col := Color(0.75 + bright * 0.2, 0.82 + bright * 0.12, 0.95 + bright * 0.05, bright)
		draw_circle(p, star.size, col)
		if star.speed > 110.0:
			draw_line(p - Vector2(0.0, 7.0 + star.size * 2.0), p, col * Color(1, 1, 1, 0.25), maxf(star.size - 0.4, 0.6))


func _draw_hud_chrome() -> void:
	var top_rect := Rect2(12.0, 10.0, VW - 24.0, 86.0)
	draw_rect(top_rect, Color(0.01, 0.05, 0.1, 0.72))
	draw_rect(Rect2(12.0, 10.0, VW - 24.0, 2.0), Color(0.18, 0.7, 1.0, 0.55))
	draw_rect(Rect2(12.0, 94.0, VW - 24.0, 2.0), Color(0.2, 0.4, 0.6, 0.22))

	var hp_ratio := float(_hp) / float(MAX_HP)
	draw_rect(Rect2(18.0, 76.0, 210.0, 6.0), Color(0.05, 0.08, 0.12, 0.9))
	draw_rect(Rect2(18.0, 76.0, 210.0 * hp_ratio, 6.0), Color(0.25, 1.0, 0.55, 0.9))

	var weapon_ratio := float(_wpn_level) / float(MAX_WPN_LEVEL)
	draw_rect(Rect2(250.0, 76.0, 220.0, 6.0), Color(0.05, 0.08, 0.12, 0.9))
	draw_rect(Rect2(250.0, 76.0, 220.0 * weapon_ratio, 6.0), Color(1.0, 0.78, 0.28, 0.9))

	var missile_ratio := 1.0 if _missile_cd <= 0.0 else 1.0 - clampf(_missile_cd / MISSILE_COOLDOWN, 0.0, 1.0)
	draw_rect(Rect2(492.0, 76.0, 170.0, 6.0), Color(0.05, 0.08, 0.12, 0.9))
	draw_rect(Rect2(492.0, 76.0, 170.0 * missile_ratio, 6.0), Color(1.0, 0.45, 0.18, 0.9))

	var wave_ratio := 1.0 - clampf(_wave_timer / WAVE_INTERVAL, 0.0, 1.0)
	draw_rect(Rect2(VW - 220.0, 76.0, 190.0, 6.0), Color(0.05, 0.08, 0.12, 0.9))
	draw_rect(Rect2(VW - 220.0, 76.0, 190.0 * wave_ratio, 6.0), Color(0.35, 0.85, 1.0, 0.85))

	if _boss != null:
		var boss_ratio := clampf(float(_boss.hp) / float(_boss.max_hp), 0.0, 1.0)
		draw_rect(Rect2(VW * 0.2, 106.0, VW * 0.6, 10.0), Color(0.05, 0.02, 0.05, 0.85))
		draw_rect(Rect2(VW * 0.2, 106.0, VW * 0.6 * boss_ratio, 10.0), Color(1.0, 0.2, 0.45, 0.9))
		draw_rect(Rect2(VW * 0.2, 106.0, VW * 0.6, 10.0), Color(1.0, 0.4, 0.6, 0.18), false, 1.0)


func _draw_grid(offset: Vector2) -> void:
	for y in range(0, VH, 40):
		var alpha := 0.03 + 0.025 * sin(y * 0.05 + _elapsed * 2.0)
		var width := 1.2 if y % 120 == 0 else 0.8
		draw_line(Vector2(0, y) + offset, Vector2(VW, y) + offset, Color(0.0, 0.3, 0.6, alpha), width)
	for x in range(0, VW, 40):
		var cx_alpha := 0.02 + 0.03 * (1.0 - absf((float(x) - VW * 0.5) / (VW * 0.5)))
		draw_line(Vector2(x, 0) + offset, Vector2(x, VH) + offset, Color(0.0, 0.3, 0.6, cx_alpha))


func _offset_points(points: PackedVector2Array, delta: Vector2) -> PackedVector2Array:
	var shifted := PackedVector2Array(points.duplicate())
	for i in shifted.size():
		shifted[i] += delta
	return shifted


func _draw_poly_with_outline(points: PackedVector2Array, fill_col: Color, stroke_col: Color, stroke_width: float) -> void:
	draw_colored_polygon(points, fill_col)
	var outline := PackedVector2Array(points.duplicate())
	outline.append(outline[0])
	draw_polyline(outline, stroke_col, stroke_width)


func _draw_player(offset: Vector2) -> void:
	var cx := _player.position.x + _player.size.x / 2.0
	var ty := _player.position.y
	var by := _player.position.y + _player.size.y
	var engine_y := by - 1.0

	# Blink during I-frames
	if _invincible > 0.0 and sin(_invincible * 30.0) > 0.0:
		return

	draw_circle(_player.get_center() + offset + Vector2(0, 14), 18.0, Color(0, 0, 0, 0.18))

	var flame_h := 4.5 + sin(_elapsed * 20.0) * 2.2
	for engine_x in [-5.0, 5.0]:
		_draw_poly_with_outline(
			_offset_points(PackedVector2Array([
				Vector2(cx + engine_x - 2.8, engine_y),
				Vector2(cx + engine_x, engine_y + flame_h),
				Vector2(cx + engine_x + 2.8, engine_y),
			]), offset),
			Color(0.05, 0.6, 1.0, 0.8),
			Color(0.8, 0.95, 1.0, 0.4),
			0.8
		)

	var body_local := PackedVector2Array([
		Vector2(cx, ty - 1),
		Vector2(cx + 5, ty + 7),
		Vector2(cx + 14, ty + 11),
		Vector2(cx + 22, ty + 19),
		Vector2(cx + 12, ty + 21),
		Vector2(cx + 19, ty + 30),
		Vector2(cx + 8, by - 8),
		Vector2(cx + 7, by - 2),
		Vector2(cx + 2, by - 7),
		Vector2(cx, by - 4),
		Vector2(cx - 2, by - 7),
		Vector2(cx - 7, by - 2),
		Vector2(cx - 8, by - 8),
		Vector2(cx - 19, ty + 30),
		Vector2(cx - 12, ty + 21),
		Vector2(cx - 22, ty + 19),
		Vector2(cx - 14, ty + 11),
		Vector2(cx - 5, ty + 7),
	])
	var shadow := PackedVector2Array(body_local.duplicate())
	for si in shadow.size():
		shadow[si] += offset + Vector2(0, 6)
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.16))
	var body := _offset_points(body_local, offset)
	_draw_poly_with_outline(body, Color(0.06, 0.14, 0.24), Color(0.05, 0.88, 1.0), 1.5)

	var center_panel := _offset_points(PackedVector2Array([
		Vector2(cx, ty + 7),
		Vector2(cx + 8, ty + 17),
		Vector2(cx + 4, by - 10),
		Vector2(cx, by - 5),
		Vector2(cx - 4, by - 10),
		Vector2(cx - 8, ty + 17),
	]), offset)
	_draw_poly_with_outline(center_panel, Color(0.18, 0.42, 0.62, 0.62), Color(0.45, 0.92, 1.0, 0.5), 1.0)

	var canopy := _offset_points(PackedVector2Array([
		Vector2(cx, ty + 6),
		Vector2(cx + 5, ty + 15),
		Vector2(cx, ty + 22),
		Vector2(cx - 5, ty + 15),
	]), offset)
	_draw_poly_with_outline(canopy, Color(0.38, 0.88, 1.0, 0.34), Color(0.7, 0.96, 1.0, 0.75), 0.9)

	for wing_sign in [-1.0, 1.0]:
		var fin := _offset_points(PackedVector2Array([
			Vector2(cx + wing_sign * 10, ty + 20),
			Vector2(cx + wing_sign * 15, ty + 26),
			Vector2(cx + wing_sign * 10, by - 6),
			Vector2(cx + wing_sign * 6, by - 12),
		]), offset)
		_draw_poly_with_outline(fin, Color(0.12, 0.22, 0.33, 0.78), Color(0.3, 0.75, 1.0, 0.45), 0.8)
		if wing_sign < 0.0:
			draw_circle(Vector2(cx + wing_sign * 18, ty + 20) + offset, 1.6, Color(1.0, 0.3, 0.32, 0.9))
		else:
			draw_circle(Vector2(cx + wing_sign * 18, ty + 20) + offset, 1.6, Color(0.3, 1.0, 0.8, 0.9))

	draw_line(Vector2(cx, ty + 3) + offset, Vector2(cx, by - 7) + offset, Color(0.65, 0.95, 1.0, 0.45), 1.0)
	draw_line(Vector2(cx - 14, ty + 20) + offset, Vector2(cx - 6, ty + 23) + offset, Color(0.45, 0.92, 1.0, 0.55), 1.0)
	draw_line(Vector2(cx + 14, ty + 20) + offset, Vector2(cx + 6, ty + 23) + offset, Color(0.45, 0.92, 1.0, 0.55), 1.0)
	draw_circle(Vector2(cx, ty + 12) + offset, 10.0, Color(0.2, 0.8, 1.0, 0.08))

	# Shield visual
	if _has_shield or _shield_flash > 0.0:
		var col := Color(0.2, 0.6, 1.0, 0.15)
		if _shield_flash > 0.0:
			col = Color(0.5, 0.9, 1.0, _shield_flash * 0.4)
		draw_circle(_player.get_center() + offset, 24.0, col)
		if _has_shield and _shield_flash <= 0.0:
			draw_arc(_player.get_center() + offset, 24.0, 0, TAU, 24, Color(0.3, 0.7, 1.0, 0.5), 1.0)


func _draw_wingmen(offset: Vector2) -> void:
	var cx := _player.position.x + _player.size.x / 2.0
	var cy := _player.position.y + _player.size.y / 2.0
	for wm in _wingmen:
		var wx := cx + wm.offset.x
		var wy := cy + wm.offset.y
		var body := _offset_points(PackedVector2Array([
			Vector2(wx, wy - 8),
			Vector2(wx + 5, wy - 2),
			Vector2(wx + 9, wy + 5),
			Vector2(wx + 2, wy + 3),
			Vector2(wx, wy + 7),
			Vector2(wx - 2, wy + 3),
			Vector2(wx - 9, wy + 5),
			Vector2(wx - 5, wy - 2),
		]), offset)
		_draw_poly_with_outline(body, Color(0.08, 0.22, 0.36), Color(0.42, 1.0, 0.62), 1.0)
		var canopy := _offset_points(PackedVector2Array([
			Vector2(wx, wy - 5),
			Vector2(wx + 2.2, wy - 1),
			Vector2(wx, wy + 2.2),
			Vector2(wx - 2.2, wy - 1),
		]), offset)
		draw_colored_polygon(canopy, Color(0.5, 0.95, 1.0, 0.4))
		draw_line(Vector2(wx - 5, wy + 3) + offset, Vector2(wx + 5, wy + 3) + offset, Color(0.42, 1.0, 0.62, 0.5), 0.8)
		draw_circle(Vector2(wx, wy + 5) + offset, 1.8, Color(0.2, 0.7, 1.0, 0.75))
		draw_circle(Vector2(wx, wy) + offset, 4.0, Color(0.3, 1.0, 0.7, 0.08))


func _draw_bullet(b: Bullet, offset: Vector2) -> void:
	var p := b.pos + offset
	var tail := b.vel.normalized() * -10.0
	draw_circle(p, 10.0, Color(b.col, 0.12))
	draw_line(p + tail, p + Vector2(0, 5), Color(b.col, 0.35), 2.2)
	draw_rect(Rect2(p.x - 1.8, p.y - 7.0, 3.6, 14.0), b.col)
	draw_rect(Rect2(p.x - 0.6, p.y - 9.0, 1.2, 18.0), Color(1, 1, 1, 0.9))


func _draw_enemy(e: EnemyData, offset: Vector2) -> void:
	var ox := e.pos.x + offset.x
	var oy := e.pos.y + offset.y
	var hw := e.w / 2.0
	var hh := e.h / 2.0
	var pts: PackedVector2Array
	var line_w: float
	var fill_col := e.col * Color(0.3, 0.3, 0.35)
	if e.hit_flash > 0.0:
		fill_col = Color(1, 1, 1, e.hit_flash) + fill_col * (1.0 - e.hit_flash)

	match int(e.max_hp):
		1:
			pts = PackedVector2Array([
				Vector2(ox, oy - hh),
				Vector2(ox + hw * 0.45, oy - hh * 0.25),
				Vector2(ox + hw, oy + hh * 0.05),
				Vector2(ox + hw * 0.3, oy + hh * 0.75),
				Vector2(ox, oy + hh * 0.4),
				Vector2(ox - hw * 0.3, oy + hh * 0.75),
				Vector2(ox - hw, oy + hh * 0.05),
				Vector2(ox - hw * 0.45, oy - hh * 0.25),
			]); line_w = 1.0
		3:
			pts = PackedVector2Array([
				Vector2(ox, oy - hh),
				Vector2(ox + hw * 0.42, oy - hh * 0.62),
				Vector2(ox + hw * 0.95, oy - hh * 0.2),
				Vector2(ox + hw, oy + hh * 0.24),
				Vector2(ox + hw * 0.42, oy + hh * 0.46),
				Vector2(ox + hw * 0.18, oy + hh),
				Vector2(ox - hw * 0.18, oy + hh),
				Vector2(ox - hw * 0.42, oy + hh * 0.46),
				Vector2(ox - hw, oy + hh * 0.24),
				Vector2(ox - hw * 0.95, oy - hh * 0.2),
				Vector2(ox - hw * 0.42, oy - hh * 0.62),
			]); line_w = 1.25
		_:
			pts = PackedVector2Array([
				Vector2(ox, oy - hh),
				Vector2(ox + hw * 0.34, oy - hh * 0.82),
				Vector2(ox + hw * 0.8, oy - hh * 0.56),
				Vector2(ox + hw, oy - hh * 0.1),
				Vector2(ox + hw * 0.78, oy + hh * 0.18),
				Vector2(ox + hw * 0.95, oy + hh * 0.66),
				Vector2(ox + hw * 0.32, oy + hh * 0.48),
				Vector2(ox + hw * 0.14, oy + hh),
				Vector2(ox - hw * 0.14, oy + hh),
				Vector2(ox - hw * 0.32, oy + hh * 0.48),
				Vector2(ox - hw * 0.95, oy + hh * 0.66),
				Vector2(ox - hw * 0.78, oy + hh * 0.18),
				Vector2(ox - hw, oy - hh * 0.1),
				Vector2(ox - hw * 0.8, oy - hh * 0.56),
				Vector2(ox - hw * 0.34, oy - hh * 0.82),
			]); line_w = 1.5

	draw_circle(Vector2(ox, oy + hh * 0.35), hw * 0.95, Color(0, 0, 0, 0.14))
	_draw_poly_with_outline(pts, fill_col, e.col, line_w)

	match int(e.max_hp):
		1:
			var cockpit := PackedVector2Array([
				Vector2(ox, oy - hh * 0.42),
				Vector2(ox + hw * 0.14, oy - hh * 0.02),
				Vector2(ox, oy + hh * 0.18),
				Vector2(ox - hw * 0.14, oy - hh * 0.02),
			])
			draw_colored_polygon(cockpit, Color(1.0, 0.88, 0.45, 0.38))
			draw_line(Vector2(ox, oy - hh * 0.26), Vector2(ox, oy + hh * 0.3), Color(1.0, 0.78, 0.32, 0.5), 0.9)
			draw_circle(Vector2(ox - hw * 0.52, oy + hh * 0.12), 2.0, Color(1.0, 0.42, 0.2, 0.55))
			draw_circle(Vector2(ox + hw * 0.52, oy + hh * 0.12), 2.0, Color(1.0, 0.42, 0.2, 0.55))
		3:
			var panel := PackedVector2Array([
				Vector2(ox, oy - hh * 0.42),
				Vector2(ox + hw * 0.26, oy - hh * 0.06),
				Vector2(ox + hw * 0.1, oy + hh * 0.52),
				Vector2(ox - hw * 0.1, oy + hh * 0.52),
				Vector2(ox - hw * 0.26, oy - hh * 0.06),
			])
			_draw_poly_with_outline(panel, e.col * Color(0.55, 0.55, 0.82, 0.42), Color(0.95, 0.92, 0.68, 0.35), 0.8)
			draw_line(Vector2(ox - hw * 0.58, oy + hh * 0.05), Vector2(ox + hw * 0.58, oy + hh * 0.05), Color(1.0, 0.62, 0.22, 0.45), 1.0)
			draw_circle(Vector2(ox - hw * 0.64, oy + hh * 0.22), 3.1, Color(1.0, 0.4, 0.18, 0.62))
			draw_circle(Vector2(ox + hw * 0.64, oy + hh * 0.22), 3.1, Color(1.0, 0.4, 0.18, 0.62))
		_:
			var armor := PackedVector2Array([
				Vector2(ox, oy - hh * 0.56),
				Vector2(ox + hw * 0.18, oy - hh * 0.26),
				Vector2(ox + hw * 0.22, oy + hh * 0.18),
				Vector2(ox, oy + hh * 0.34),
				Vector2(ox - hw * 0.22, oy + hh * 0.18),
				Vector2(ox - hw * 0.18, oy - hh * 0.26),
			])
			_draw_poly_with_outline(armor, Color(0.92, 0.62, 0.2, 0.22), Color(1.0, 0.78, 0.4, 0.35), 0.8)
			draw_line(Vector2(ox - hw * 0.68, oy + hh * 0.02), Vector2(ox + hw * 0.68, oy + hh * 0.02), Color(1.0, 0.42, 0.22, 0.45), 1.2)
			draw_circle(Vector2(ox, oy), 4.0, e.col * Color(1.2, 0.6, 0.4))
			draw_circle(Vector2(ox, oy), 3.0, Color(1.0, 0.7, 0.3))
			draw_circle(Vector2(ox - hw * 0.45, oy + hh * 0.2), 3.2, Color(1.0, 0.35, 0.2, 0.6))
			draw_circle(Vector2(ox + hw * 0.45, oy + hh * 0.2), 3.2, Color(1.0, 0.35, 0.2, 0.6))

	if e.max_hp > 1:
		_draw_hp_bar(ox, oy, e)


func _draw_boss(offset: Vector2) -> void:
	if _boss == null:
		return

	var b := _boss
	var center := b.pos + offset
	var hw := b.w * b.scale * 0.5
	var hh := b.h * b.scale * 0.5
	var body := PackedVector2Array([
		center + Vector2(0.0, -hh),
		center + Vector2(hw * 0.24, -hh * 0.88),
		center + Vector2(hw * 0.56, -hh * 0.7),
		center + Vector2(hw * 1.08, -hh * 0.34),
		center + Vector2(hw * 0.82, -hh * 0.02),
		center + Vector2(hw * 0.98, hh * 0.42),
		center + Vector2(hw * 0.62, hh * 0.32),
		center + Vector2(hw * 0.42, hh * 0.72),
		center + Vector2(hw * 0.14, hh),
		center + Vector2(-hw * 0.14, hh),
		center + Vector2(-hw * 0.42, hh * 0.72),
		center + Vector2(-hw * 0.62, hh * 0.32),
		center + Vector2(-hw * 0.98, hh * 0.42),
		center + Vector2(-hw * 0.82, -hh * 0.02),
		center + Vector2(-hw * 1.08, -hh * 0.34),
		center + Vector2(-hw * 0.56, -hh * 0.7),
		center + Vector2(-hw * 0.24, -hh * 0.88),
	])
	var shadow := PackedVector2Array(body.duplicate())
	for i in shadow.size():
		shadow[i] += Vector2(0.0, 14.0)
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.2))

	var fill_col := b.col * Color(0.24, 0.14, 0.22)
	if b.hit_flash > 0.0:
		fill_col = Color(1, 1, 1, b.hit_flash) + fill_col * (1.0 - b.hit_flash)
	_draw_poly_with_outline(body, fill_col, Color(1.0, 0.35, 0.65, 0.9), 2.0)

	var armor := PackedVector2Array([
		center + Vector2(0.0, -hh * 0.72),
		center + Vector2(hw * 0.3, -hh * 0.32),
		center + Vector2(hw * 0.24, hh * 0.16),
		center + Vector2(0.0, hh * 0.44),
		center + Vector2(-hw * 0.24, hh * 0.16),
		center + Vector2(-hw * 0.3, -hh * 0.32),
	])
	_draw_poly_with_outline(armor, Color(0.32, 0.1, 0.22, 0.85), Color(1.0, 0.55, 0.7, 0.36), 1.2)

	var canopy := PackedVector2Array([
		center + Vector2(0.0, -hh * 0.48),
		center + Vector2(hw * 0.22, -hh * 0.08),
		center + Vector2(0.0, hh * 0.14),
		center + Vector2(-hw * 0.22, -hh * 0.08),
	])
	_draw_poly_with_outline(canopy, Color(0.28, 0.78, 1.0, 0.32), Color(0.86, 0.96, 1.0, 0.55), 1.0)

	for wing_sign in [-1.0, 1.0]:
		var blade := PackedVector2Array([
			center + Vector2(wing_sign * hw * 0.56, -hh * 0.12),
			center + Vector2(wing_sign * hw * 0.92, hh * 0.06),
			center + Vector2(wing_sign * hw * 0.72, hh * 0.38),
			center + Vector2(wing_sign * hw * 0.46, hh * 0.26),
		])
		_draw_poly_with_outline(blade, Color(0.4, 0.12, 0.22, 0.78), Color(1.0, 0.48, 0.56, 0.45), 1.0)
		draw_circle(center + Vector2(wing_sign * hw * 0.74, hh * 0.18), 5.0 * b.scale, Color(1.0, 0.42, 0.18, 0.66))

	draw_circle(center, 20.0 * b.scale, Color(1.0, 0.28, 0.55, 0.14))
	draw_circle(center, 9.0 * b.scale, Color(1.0, 0.88, 0.96, 0.98))
	draw_arc(center, 18.0 * b.scale, b.phase, b.phase + TAU * 0.78, 28, Color(1.0, 0.55, 0.75, 0.4), 1.4)
	draw_line(center + Vector2(-hw * 0.7, hh * 0.14), center + Vector2(hw * 0.7, hh * 0.14), Color(1.0, 0.24, 0.42, 0.36), 2.2)
	draw_line(center + Vector2(0.0, -hh * 0.6), center + Vector2(0.0, hh * 0.64), Color(1.0, 0.48, 0.68, 0.22), 1.4)


func _draw_hp_bar(cx: float, cy: float, e: EnemyData) -> void:
	var bw := e.w + 6
	var bh := 3
	var px := cx - bw / 2.0
	var py := cy - e.h / 2.0 - 8
	draw_rect(Rect2(px, py, bw, bh), Color(0.1, 0.1, 0.1, 0.8))
	var ratio := float(e.hp) / float(e.max_hp)
	var hp_c := Color(1.0, 0.3, 0.3) if ratio < 0.3 else Color(0.3, 1.0, 0.5)
	draw_rect(Rect2(px, py, bw * ratio, bh), hp_c)
	draw_rect(Rect2(px, py, bw, bh), Color(0.5, 0.5, 0.5), false, 0.5)


func _draw_enemy_bullet(pos: Vector2, offset: Vector2) -> void:
	var p := pos + offset
	draw_circle(p, 8.0, Color(1.0, 0.2, 0.2, 0.08))
	draw_line(p - Vector2(0, 8), p + Vector2(0, 1), Color(1.0, 0.3, 0.15, 0.25), 2.2)
	draw_circle(p, 4.0, Color(1.0, 0.35, 0.15, 0.5))
	draw_circle(p, 2.5, Color(1.0, 0.5, 0.2))
	draw_circle(p, 1.0, Color(1.0, 0.9, 0.6))


func _draw_pickup(p: Pickup, offset: Vector2) -> void:
	var y := p.pos.y + sin(p.bob) * 3.0
	var alpha := minf(p.life, 1.0)
	var center := Vector2(p.pos.x, y) + offset

	draw_circle(center, 10.0, Color(0.3, 0.3, 0.3, alpha * 0.3))

	match p.type:
		PickupType.WEAPON:
			var pts := PackedVector2Array([
				Vector2(p.pos.x, y - 7), Vector2(p.pos.x + 7, y),
				Vector2(p.pos.x, y + 7), Vector2(p.pos.x - 7, y),
			])
			var cos_r := cos(p.rot); var sin_r := sin(p.rot)
			for i in pts.size():
				var dx := pts[i].x - p.pos.x
				var dy := pts[i].y - y
				pts[i] = Vector2(p.pos.x + dx * cos_r - dy * sin_r, y + dx * sin_r + dy * cos_r) + offset
			draw_colored_polygon(pts, Color(1.0, 0.85, 0.2, alpha * 0.7))
			pts.append(pts[0])
			draw_polyline(pts, Color(1.0, 1.0, 0.5, alpha), 1.0)
		PickupType.HEAL:
			var pulse := 1.0 + sin(p.bob * 2.0) * 0.15
			draw_rect(Rect2(p.pos.x - 2 * pulse, y - 6 * pulse, 4 * pulse, 12 * pulse), Color(0.3, 1.0, 0.4, alpha))
			draw_rect(Rect2(p.pos.x - 6 * pulse, y - 2 * pulse, 12 * pulse, 4 * pulse), Color(0.3, 1.0, 0.4, alpha))
		PickupType.SHIELD:
			draw_circle(center, 6.0, Color(0.3, 0.6, 1.0, alpha * 0.7))
			draw_arc(center, 8.0, p.rot, TAU + p.rot, 12, Color(0.5, 0.8, 1.0, alpha), 1.0)
		PickupType.BOMB:
			draw_circle(center, 12.0, Color(1.0, 0.1, 0.1, alpha * 0.2))
			var bomb_pts := PackedVector2Array()
			for i in 8:
				var angle := TAU * float(i) / 8 + p.rot
				bomb_pts.append(Vector2(p.pos.x + cos(angle) * 7, y + sin(angle) * 7))
			draw_colored_polygon(bomb_pts.duplicate(), Color(1.0, 0.2, 0.2, alpha * 0.7))
			bomb_pts.append(bomb_pts[0])
			for i in bomb_pts.size():
				bomb_pts[i] += offset
			draw_polyline(bomb_pts, Color(1.0, 0.8, 0.5, alpha), 1.2)
		PickupType.MISSILE:
			var oct := PackedVector2Array()
			for i in 8:
				var a := TAU * float(i) / 8.0
				oct.append(Vector2(p.pos.x + cos(a) * 7.0, y + sin(a) * 7.0) + offset)
			draw_colored_polygon(oct, Color(1.0, 0.5, 0.2, alpha * 0.6))
			oct.append(oct[0])
			draw_polyline(oct, Color(1.0, 0.7, 0.3, alpha), 1.0)


# --- Homing missile visual ---
func _draw_missile(m: HomingMissile, offset: Vector2) -> void:
	# Smoke trail
	for si in m.smoke.size():
		var sa := 0.15 * float(si) / float(m.smoke.size())
		draw_circle(m.smoke[si] + offset, 2.2, Color(0.4, 0.4, 0.4, sa))
	# Missile body
	var p := m.pos + offset
	var dir := Vector2.from_angle(m.angle)
	var side := dir.orthogonal()
	var tail := p - dir * 8.0
	draw_circle(p, 7.0, Color(1.0, 0.4, 0.1, 0.15))
	var body := PackedVector2Array([
		p + dir * 6.0,
		p + side * 2.0,
		tail + side * 3.0,
		tail,
		tail - side * 3.0,
		p - side * 2.0,
	])
	_draw_poly_with_outline(body, Color(0.95, 0.56, 0.2, 0.92), Color(1.0, 0.84, 0.62, 0.78), 1.0)
	_draw_poly_with_outline(PackedVector2Array([
		tail + side * 3.0,
		tail + side * 5.4 - dir * 2.2,
		tail + side * 1.2 - dir * 1.4,
	]), Color(0.92, 0.48, 0.18, 0.9), Color(1.0, 0.78, 0.58, 0.5), 0.8)
	_draw_poly_with_outline(PackedVector2Array([
		tail - side * 3.0,
		tail - side * 5.4 - dir * 2.2,
		tail - side * 1.2 - dir * 1.4,
	]), Color(0.92, 0.48, 0.18, 0.9), Color(1.0, 0.78, 0.58, 0.5), 0.8)
	draw_line(tail + side * 1.6, p + dir * 2.0, Color(1.0, 0.92, 0.72, 0.75), 0.8)
	draw_line(tail - side * 1.6, p + dir * 2.0, Color(1.0, 0.92, 0.72, 0.75), 0.8)
	draw_circle(p + dir * 1.2, 2.1, Color(1.0, 0.86, 0.58, 0.95))
	# Flame
	draw_circle(tail, 2.5, Color(1.0, 0.3, 0.1, 0.7))


# --- Small text popup at position ---
func _make_text_popup(pos: Vector2, text: String, col: Color) -> void:
	var tfx := TextFX.new()
	tfx.pos = pos
	tfx.text = text
	tfx.life = 0.8
	tfx.max_life = 0.8
	tfx.vel = Vector2.UP * 50.0
	tfx.col = col
	_text_fx.append(tfx)


# --- Wingmen ---
func _update_wingmen(dt: float) -> void:
	if _wpn_level >= 3 and _wingmen.is_empty():
		_add_wingman(Vector2(-30, -12))
		_add_wingman(Vector2(30, -12))

	for wm in _wingmen:
		wm.missile_cd = maxf(wm.missile_cd - dt, 0.0)
		if wm.missile_cd <= 0.0 and _missile_pool.size() < MAX_MISSILES:
			_fire_wingman_missile(wm)
			wm.missile_cd = 8.0


func _add_wingman(off: Vector2) -> void:
	var wm := Wingman.new()
	wm.offset = off
	_wingmen.append(wm)


func _fire_wingman_missile(wm: Wingman) -> void:
	var m := HomingMissile.new()
	m.pos = _player.get_center() + wm.offset
	m.angle = -PI / 2
	m.speed = MISSILE_SPEED * 0.85
	m.dmg = 2
	m.life = MISSILE_LIFE * 0.9
	_missile_pool.append(m)
