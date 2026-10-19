extends Node
# Режим приставки (PortMaster): кнопки приходят клавишами из gptokeyb, а нативный джойстик Godot
# дублирует их (d-pad одновременно кнопками и осью, раскладка SDL не совпадает) — поэтому события
# джойстика отбрасываются раньше остальных обработчиков. Вне приставки ничего не делает.

var active := false


func _ready() -> void:
	active = OS.has_feature("handheld") or "--keys-only" in OS.get_cmdline_user_args()
	set_process_input(active)
	if not active:
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	# _input вызывается с конца дерева: держим узел последним ребёнком корня, чтобы он шёл первым
	var root := get_tree().root
	root.child_entered_tree.connect(func(_n: Node): _to_last.call_deferred())


func _to_last() -> void:
	var root := get_tree().root
	if get_parent() == root and root.get_child(root.get_child_count() - 1) != self:
		root.move_child(self, root.get_child_count() - 1)


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()
