extends Node3D

const SAVE_PATH := "user://black_file_save.json"
const EPISODES := [
    ["THE SUIT", "Recupere o artefato roubado.", "Zona industrial"],
    ["CLEAN ENTRY", "Invada o armazém da ECLIPSE.", "Armazém noturno"],
    ["DEAD DROP", "Encontre o agente desaparecido.", "Bairro financeiro"],
    ["NO WITNESSES", "Escape do prédio comprometido.", "Torre corporativa"],
    ["THE BOX", "Recupere o fragmento de Anomalia.", "Laboratório móvel"],
    ["GHOST SIGNAL", "Investigue o sinal impossível.", "Instalação abandonada"],
    ["ECLIPSE", "Identifique a organização criminosa.", "Base clandestina"],
    ["FIRST CONTACT", "Enfrente o comandante da ECLIPSE.", "Complexo subterrâneo"]
]

var current_episode := 0
var completed: Array = []
var selected_character := "ZERO"
var player: CharacterBody3D
var camera: Camera3D
var weapon_mesh: MeshInstance3D
var portal: Area3D
var enemies: Array = []
var rng := RandomNumberGenerator.new()
var hp := 100.0
var max_hp := 100.0
var weapon_index := 0
var ammo := 30
var reserve := 120
var reload_time := 0.0
var shoot_cooldown := 0.0
var ability_cooldown := 0.0
var objective_done := false
var episode_active := false
var paused := false
var briefing_panel: Panel
var pause_panel: Panel
var hp_label: Label
var ammo_label: Label
var objective_label: Label
var weapon_label: Label
var status_label: Label
var save_label: Label
var crosshair: Label

var weapons := [
    {"name":"AK-47", "mag":30, "reserve":120, "damage":32.0, "cooldown":0.18, "color":Color("#e5a34b")},
    {"name":"PISTOLA", "mag":12, "reserve":999, "damage":22.0, "cooldown":0.28, "color":Color("#9eb9d9")},
    {"name":"FACA", "mag":-1, "reserve":-1, "damage":55.0, "cooldown":0.55, "color":Color("#dfe7ee")}
]

func _ready() -> void:
    rng.randomize()
    _setup_world()
    _setup_ui()
    _load_save()
    _show_briefing()
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _setup_world() -> void:
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color("#07101d")
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#72839b")
    env.ambient_light_energy = 0.45
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.fog_enabled = true
    env.fog_light_color = Color("#263342")
    env.fog_density = 0.012
    environment.environment = env
    add_child(environment)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-50, -25, 0)
    sun.light_color = Color("#b8ccff")
    sun.light_energy = 1.2
    sun.shadow_enabled = true
    add_child(sun)

    var fill := OmniLight3D.new()
    fill.position = Vector3(0, 5, 2)
    fill.light_color = Color("#d97968")
    fill.light_energy = 5.0
    fill.omni_range = 18.0
    add_child(fill)

    _box(self, Vector3(38, 0.3, 28), Vector3(0, -0.15, 0), Color("#202b38"))
    _box(self, Vector3(38, 5, 0.4), Vector3(0, 2.5, -14), Color("#121a27"))
    _box(self, Vector3(0.4, 5, 28), Vector3(-19, 2.5, 0), Color("#121a27"))
    _box(self, Vector3(0.4, 5, 28), Vector3(19, 2.5, 0), Color("#121a27"))

    for i in range(12):
        var x := rng.randf_range(-16.0, 16.0)
        var z := rng.randf_range(-9.0, 8.0)
        _box(self, Vector3(rng.randf_range(0.8, 2.3), rng.randf_range(1.0, 3.2), rng.randf_range(0.8, 2.3)), Vector3(x, 1.0, z), Color("#273c50"))

    for z in [-10.0, -4.0, 2.0, 8.0]:
        _box(self, Vector3(0.08, 3.0, 0.08), Vector3(-8.0, 3.0, z), Color("#e4474e"), Color("#e4474e"))
        _box(self, Vector3(0.08, 3.0, 0.08), Vector3(8.0, 3.0, z), Color("#5be4ec"), Color("#5be4ec"))

    player = CharacterBody3D.new()
    player.name = "JackReed"
    player.position = Vector3(0, 1.1, 10)
    player.set_meta("is_player", true)
    add_child(player)
    var player_shape := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.42
    capsule.height = 1.8
    player_shape.shape = capsule
    player_shape.position.y = 0.95
    player.add_child(player_shape)
    _box(player, Vector3(0.9, 1.5, 0.55), Vector3(0, 1.0, 0), Color("#111827"))
    _sphere(player, 0.36, Vector3(0, 2.0, 0), Color("#e2b294"))
    _box(player, Vector3(0.72, 0.14, 0.52), Vector3(0, 2.26, 0), Color("#11151c"))
    weapon_mesh = _box(player, Vector3(0.12, 0.12, 1.0), Vector3(0.62, 1.1, -0.3), weapons[0].color)

    camera = Camera3D.new()
    camera.position = Vector3(0, 3.7, 6.8)
    camera.rotation_degrees = Vector3(-13, 180, 0)
    player.add_child(camera)
    camera.current = true

    portal = Area3D.new()
    portal.name = "ExtractionPortal"
    portal.position = Vector3(0, 1.7, -11.5)
    portal.set_meta("extraction", true)
    add_child(portal)
    var portal_shape := CollisionShape3D.new()
    var portal_box := BoxShape3D.new()
    portal_box.size = Vector3(3.5, 3.5, 0.6)
    portal_shape.shape = portal_box
    portal.add_child(portal_shape)
    _box(portal, Vector3(3.5, 3.5, 0.12), Vector3.ZERO, Color("#246c91"), Color("#5be4ec"))
    var portal_light := OmniLight3D.new()
    portal_light.light_color = Color("#5be4ec")
    portal_light.light_energy = 10.0
    portal_light.omni_range = 8.0
    portal.add_child(portal_light)

func _setup_ui() -> void:
    var layer := CanvasLayer.new()
    layer.name = "Interface"
    add_child(layer)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(root)

    var top := ColorRect.new()
    top.color = Color(0.02, 0.03, 0.06, 0.82)
    top.position = Vector2(22, 18)
    top.size = Vector2(360, 82)
    root.add_child(top)
    hp_label = _label(root, "VITALIDADE 100 / 100", Vector2(40, 30), 18, Color("#f08b88"))
    ammo_label = _label(root, "30 / 120", Vector2(40, 56), 17, Color("#f6c85f"))
    weapon_label = _label(root, "AK-47", Vector2(185, 58), 13, Color("#5be4ec"))
    status_label = _label(root, "MIB // AGENT ZERO", Vector2(40, 82), 10, Color("#aebdce"))

    var objective_box := ColorRect.new()
    objective_box.color = Color(0.02, 0.03, 0.06, 0.82)
    objective_box.position = Vector2(22, 120)
    objective_box.size = Vector2(410, 65)
    root.add_child(objective_box)
    _label(root, "OBJETIVO ATUAL", Vector2(38, 130), 10, Color("#e4474e"))
    objective_label = _label(root, "", Vector2(38, 150), 14, Color("#e8edf4"))

    crosshair = _label(root, "+", Vector2(638, 337), 27, Color(1, 1, 1, 0.8))
    crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    crosshair.size = Vector2(28, 35)
    _label(root, "1 AK-47   2 PISTOLA   3 FACA   |   R RECARREGAR   |   Q HABILIDADE   |   ESC PAUSA", Vector2(25, 680), 11, Color("#9aa9bb"))
    save_label = _label(root, "", Vector2(1050, 30), 11, Color("#73e5a3"))
    save_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    save_label.size = Vector2(205, 24)

    briefing_panel = Panel.new()
    briefing_panel.position = Vector2(310, 180)
    briefing_panel.size = Vector2(660, 330)
    root.add_child(briefing_panel)
    var bt := _label(briefing_panel, "MIB // TRANSMISSÃO SEGURA", Vector2(32, 28), 12, Color("#5be4ec"))
    bt.name = "BriefTag"
    var bh := _label(briefing_panel, "", Vector2(32, 65), 30, Color("#e4474e"))
    bh.name = "BriefTitle"
    var body := _label(briefing_panel, "", Vector2(32, 120), 17, Color("#d7e0ea"))
    body.name = "BriefBody"
    body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.size = Vector2(590, 100)
    var start := Button.new()
    start.text = "INICIAR OPERAÇÃO"
    start.position = Vector2(32, 250)
    start.size = Vector2(230, 42)
    start.pressed.connect(_begin_episode)
    briefing_panel.add_child(start)

    pause_panel = Panel.new()
    pause_panel.position = Vector2(470, 240)
    pause_panel.size = Vector2(340, 230)
    root.add_child(pause_panel)
    var ph := _label(pause_panel, "PAUSADO", Vector2(30, 28), 28, Color("#e4474e"))
    var pp := _label(pause_panel, "BLACK FILE // PROTOCOLO OFFLINE", Vector2(30, 75), 13, Color("#aebdce"))
    var resume := Button.new()
    resume.text = "CONTINUAR"
    resume.position = Vector2(30, 125)
    resume.size = Vector2(130, 40)
    resume.pressed.connect(func(): _toggle_pause(false))
    pause_panel.add_child(resume)
    var menu := Button.new()
    menu.text = "MENU"
    menu.position = Vector2(175, 125)
    menu.size = Vector2(100, 40)
    menu.pressed.connect(_quit_to_menu)
    pause_panel.add_child(menu)
    briefing_panel.visible = false
    pause_panel.visible = false

func _show_briefing() -> void:
    episode_active = false
    briefing_panel.visible = true
    var data = EPISODES[current_episode]
    briefing_panel.get_node("BriefTitle").text = "EPISÓDIO %02d — %s" % [current_episode + 1, data[0]]
    briefing_panel.get_node("BriefBody").text = "LOCAL: %s\n\n%s\n\nJack, do you copy?" % [data[2], data[1]]

func _begin_episode() -> void:
    briefing_panel.visible = false
    episode_active = true
    objective_done = false
    hp = max_hp
    ammo = weapons[weapon_index].mag
    reserve = weapons[weapon_index].reserve
    shoot_cooldown = 0.0
    reload_time = 0.0
    ability_cooldown = 0.0
    player.position = Vector3(0, 1.1, 10)
    _clear_enemies()
    var amount := 4 + min(current_episode, 3)
    for i in range(amount):
        _spawn_enemy(i == amount - 1 and current_episode == 7)
    portal.position = Vector3(rng.randf_range(-12.0, 12.0), 1.7, rng.randf_range(-11.0, -7.0))
    _set_status("Operação iniciada.")
    _update_hud()

func _spawn_enemy(commander: bool) -> void:
    var e := CharacterBody3D.new()
    e.name = "EclipseCommander" if commander else "EclipseOperative"
    e.position = Vector3(rng.randf_range(-14.0, 14.0), 0.9, rng.randf_range(-7.0, 2.0))
    e.set_meta("enemy", true)
    e.set_meta("enemy_token", e.get_instance_id())
    add_child(e)
    var shape := CollisionShape3D.new()
    var box_shape := BoxShape3D.new()
    box_shape.size = Vector3(0.9, 1.8, 0.65)
    shape.shape = box_shape
    shape.position.y = 0.9
    e.add_child(shape)
    var color := Color("#8b3e91") if commander else Color("#b53f52")
    _box(e, Vector3(0.9, 1.7, 0.6), Vector3(0, 0.9, 0), color)
    _sphere(e, 0.33, Vector3(0, 1.9, 0), Color("#d89e86"))
    _box(e, Vector3(0.6, 0.12, 0.5), Vector3(0, 2.15, 0), Color("#1a1821"))
    enemies.append({"node":e, "hp":260.0 if commander else 75.0, "max_hp":260.0 if commander else 75.0, "cool":rng.randf_range(0.3, 1.5), "commander":commander})

func _physics_process(delta: float) -> void:
    if not episode_active or paused:
        return
    _move_player(delta)
    _update_enemies(delta)
    if shoot_cooldown > 0.0:
        shoot_cooldown -= delta
    if ability_cooldown > 0.0:
        ability_cooldown -= delta
    if reload_time > 0.0:
        reload_time -= delta
        if reload_time <= 0.0:
            _finish_reload()
    if Input.is_key_pressed(KEY_R):
        if reload_time <= 0.0:
            _reload()
    if Input.is_key_pressed(KEY_Q) and ability_cooldown <= 0.0:
        _ability()
    if Input.is_key_pressed(KEY_E) and objective_done and player.global_position.distance_to(portal.global_position) < 4.0:
        _complete_episode()
    _update_hud()

func _move_player(delta: float) -> void:
    var dir := Vector3.ZERO
    if Input.is_key_pressed(KEY_W): dir.z -= 1.0
    if Input.is_key_pressed(KEY_S): dir.z += 1.0
    if Input.is_key_pressed(KEY_A): dir.x -= 1.0
    if Input.is_key_pressed(KEY_D): dir.x += 1.0
    dir = dir.normalized()
    var speed := 5.5 if Input.is_key_pressed(KEY_SHIFT) else 3.5
    player.velocity.x = dir.x * speed
    player.velocity.z = dir.z * speed
    if not player.is_on_floor():
        player.velocity.y -= 18.0 * delta
    else:
        player.velocity.y = 0.0
    player.move_and_slide()
    if dir.length() > 0.1:
        player.rotation.y = lerp_angle(player.rotation.y, atan2(dir.x, dir.z), delta * 8.0)

func _update_enemies(delta: float) -> void:
    var alive := 0
    for item in enemies:
        var e: CharacterBody3D = item.node
        if not is_instance_valid(e):
            continue
        if item.hp <= 0.0:
            continue
        alive += 1
        var to_player := player.global_position - e.global_position
        var distance := to_player.length()
        if distance > 2.3:
            e.velocity = to_player.normalized() * (1.0 if item.commander else 1.4)
            e.move_and_slide()
        else:
            e.velocity = Vector3.ZERO
            hp -= (9.0 if item.commander else 5.0) * delta
            if hp <= 0.0:
                _mission_failed()
        item.cool -= delta
        if item.cool <= 0.0 and distance < 14.0:
            item.cool = 1.4 if item.commander else 2.0
            _set_status("Hostis disparando. Procure cobertura.")
    if alive == 0 and not objective_done:
        objective_done = true
        _set_status("Área segura. Alcance a porta azul e pressione E.")

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and episode_active and not paused:
        player.rotate_y(-event.relative.x * 0.0025)
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and episode_active and not paused:
        _shoot()
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_1: _change_weapon(0)
        elif event.keycode == KEY_2: _change_weapon(1)
        elif event.keycode == KEY_3: _change_weapon(2)
        elif event.keycode == KEY_ESCAPE: _toggle_pause(not paused)

func _shoot() -> void:
    if shoot_cooldown > 0.0 or reload_time > 0.0:
        return
    var weapon: Dictionary = weapons[weapon_index]
    if weapon_index == 2:
        for item in enemies:
            var enemy: CharacterBody3D = item.node
            if is_instance_valid(enemy) and enemy.global_position.distance_to(player.global_position) < 3.0 and item.hp > 0.0:
                _damage_enemy(item, weapon.damage)
        shoot_cooldown = weapon.cooldown
        _set_status("Golpe de faca.")
        return
    if ammo <= 0:
        _reload()
        return
    ammo -= 1
    shoot_cooldown = weapon.cooldown
    var from := camera.global_position
    var direction := -camera.global_transform.basis.z
    var query := PhysicsRayQueryParameters3D.create(from, from + direction * 80.0)
    query.exclude = [player.get_rid()]
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit and hit.collider and hit.collider.has_meta("enemy"):
        for item in enemies:
            if item.node == hit.collider or hit.collider.get_parent() == item.node:
                _damage_enemy(item, weapon.damage)
                break
    _set_status("%s disparou." % weapon.name)

func _damage_enemy(item: Dictionary, damage: float) -> void:
    item.hp -= damage
    if item.hp <= 0.0:
        var enemy: Node = item.node
        _burst(enemy.global_position, Color("#e4474e"))
        enemy.queue_free()
        if item.commander:
            _set_status("COMANDANTE ECLIPSE NEUTRALIZADO.")
        else:
            _set_status("Alvo neutralizado.")

func _reload() -> void:
    if weapon_index == 2 or reload_time > 0.0 or reserve <= 0:
        return
    reload_time = 1.0
    _set_status("Recarregando...")

func _finish_reload() -> void:
    var capacity: int = weapons[weapon_index].mag
    var needed := capacity - ammo
    var taken := min(needed, reserve)
    ammo += taken
    reserve -= taken
    _set_status("Carregador pronto.")

func _change_weapon(index: int) -> void:
    if index < 0 or index >= weapons.size():
        return
    weapon_index = index
    ammo = weapons[index].mag
    reserve = weapons[index].reserve
    reload_time = 0.0
    _set_status("Equipado: %s" % weapons[index].name)

func _ability() -> void:
    ability_cooldown = 7.0
    var nearest := 999.0
    var target: Dictionary = {}
    for item in enemies:
        var d: float = player.global_position.distance_to(item.node.global_position)
        if d < nearest:
            nearest = d
            target = item
    if not target.is_empty():
        _damage_enemy(target, 70.0)
    _set_status("BLACKOUT: pulso de energia disparado.")

func _complete_episode() -> void:
    if not episode_active:
        return
    episode_active = false
    if not completed.has(current_episode):
        completed.append(current_episode)
    if current_episode < EPISODES.size() - 1:
        current_episode += 1
    _save_progress()
    _set_status("PROGRESSO SALVO")
    _show_result("EPISÓDIO CONCLUÍDO", "A operação foi registrada. O próximo episódio está disponível.")

func _mission_failed() -> void:
    if not episode_active:
        return
    episode_active = false
    _show_result("MISSION FAILED", "O checkpoint de emergência foi preservado. Reinicie o episódio para tentar novamente.")

func _show_result(title: String, body: String) -> void:
    briefing_panel.visible = true
    briefing_panel.get_node("BriefTitle").text = title
    briefing_panel.get_node("BriefBody").text = body
    var button: Button = briefing_panel.get_child(3)
    button.text = "CONTINUAR"
    button.pressed.disconnect(_begin_episode)
    button.pressed.connect(_continue_after_result, CONNECT_ONE_SHOT)

func _continue_after_result() -> void:
    if current_episode >= EPISODES.size():
        current_episode = EPISODES.size() - 1
    _show_briefing()
    var button: Button = briefing_panel.get_child(3)
    if not button.pressed.is_connected(_begin_episode):
        button.pressed.connect(_begin_episode)

func _toggle_pause(value: bool) -> void:
    paused = value
    pause_panel.visible = value
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if not value else Input.MOUSE_MODE_VISIBLE)

func _quit_to_menu() -> void:
    episode_active = false
    paused = false
    pause_panel.visible = false
    _show_briefing()

func _update_hud() -> void:
    hp_label.text = "VITALIDADE %d / %d" % [max(0, int(hp)), int(max_hp)]
    ammo_label.text = "∞" if ammo < 0 else "%d / %d" % [ammo, reserve]
    weapon_label.text = weapons[weapon_index].name
    objective_label.text = "Alcance a porta azul e pressione E." if objective_done else EPISODES[current_episode][1]
    save_label.text = "PROGRESSO SALVO" if completed.size() > 0 else "SAVE: SLOT 1"

func _set_status(message: String) -> void:
    status_label.text = message

func _save_progress() -> void:
    var data := {"episode":current_episode, "completed":completed, "character":selected_character}
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data))

func _load_save() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        current_episode = int(parsed.get("episode", 0))
        completed = parsed.get("completed", [])
        selected_character = str(parsed.get("character", "ZERO"))

func _clear_enemies() -> void:
    for item in enemies:
        if is_instance_valid(item.node):
            item.node.queue_free()
    enemies.clear()

func _burst(at: Vector3, color: Color) -> void:
    var light := OmniLight3D.new()
    light.position = at
    light.light_color = color
    light.light_energy = 8.0
    light.omni_range = 4.0
    add_child(light)
    get_tree().create_timer(0.12).timeout.connect(light.queue_free)

func _box(parent: Node, size: Vector3, at: Vector3, color: Color, emission := Color(0,0,0)) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.position = at
    mesh.material_override = _material(color, emission)
    parent.add_child(mesh)
    return mesh

func _sphere(parent: Node, radius: float, at: Vector3, color: Color) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = radius
    sphere.height = radius * 2.0
    mesh.mesh = sphere
    mesh.position = at
    mesh.material_override = _material(color)
    parent.add_child(mesh)
    return mesh

func _material(color: Color, emission := Color(0,0,0)) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.62
    if emission != Color(0,0,0):
        material.emission_enabled = true
        material.emission = emission
        material.emission_energy_multiplier = 3.0
    return material

func _label(parent: Node, content: String, at: Vector2, size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = content
    label.position = at
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", color)
    parent.add_child(label)
    return label
