extends RefCounted
# Navegacion con mando por filas, igual en todos los menus: izquierda/derecha cicla dentro de la fila y
# arriba/abajo salta a la fila contigua recordando la columna (abajo y luego arriba vuelve al mismo control).

static var sticky_x := 0.0
static var sticky_for: Control = null
static var veto: Callable = Callable()   # (desde, hasta, dy) -> bool: true = el menú ya hizo otra cosa (p. ej. desplazó el texto que hay entre ambos) y el foco no se mueve


static func focusables(root: Node) -> Array:
	var out: Array = []
	for n in root.find_children("*", "Control", true, false):
		var c := n as Control
		if c.focus_mode != Control.FOCUS_ALL or not c.is_visible_in_tree():
			continue
		if c is BaseButton and (c as BaseButton).disabled:
			continue
		if c is LineEdit:
			continue
		out.append(c)
	return out


# Devuelve true si movio el foco (y hay que tragarse el evento).
static func move(vp: Viewport, event: InputEvent, items: Array) -> bool:
	var dir := Vector2i.ZERO
	if event.is_action_pressed("ui_down", true):
		dir = Vector2i(0, 1)
	elif event.is_action_pressed("ui_up", true):
		dir = Vector2i(0, -1)
	elif event.is_action_pressed("ui_left", true):
		dir = Vector2i(-1, 0)
	elif event.is_action_pressed("ui_right", true):
		dir = Vector2i(1, 0)
	else:
		return false
	var f: Control = vp.gui_get_focus_owner()
	if f == null or f is LineEdit:
		return false
	if dir.x != 0 and (f is Slider or f is OptionButton):
		return false   # el deslizador / selector usa izquierda-derecha para si mismo
	if items.size() < 2 or not items.has(f):
		return false
	# Dentro de un ScrollContainer arriba/abajo recorren primero su propio contenido: los controles desplazados fuera de la
	# vista tienen y global por encima de la barra superior / pestanas y antes el foco saltaba alli, saltandose la lista.
	# Solo desde el primer (ultimo) elemento, y con el scroll ya en su tope, se sale del contenedor.
	var sc: ScrollContainer = scroll_of(f)
	var inner: Array = []
	if sc != null:
		for c in items:
			if c == f or sc.is_ancestor_of(c):
				inner.append(c)
	var target: Control = null
	if inner.size() >= 2:
		target = _pick(f, dir, inner)
		if target == null and dir.x != 0:
			target = _pick(f, dir, items)   # fila de un solo control: izquierda / derecha pueden ir a la columna de al lado
	elif sc == null:
		target = _pick(f, dir, items)
	if target == null and sc != null and dir.y != 0:
		var bar: ScrollBar = sc.get_v_scroll_bar()
		var v: int = sc.scroll_vertical
		if (dir.y < 0 and v > 0) or (dir.y > 0 and float(v) < bar.max_value - bar.page - 0.5):
			return false   # aun queda contenido (texto) por ese lado: lo desplaza quien llama, el foco no sale
		var outer: Array = [f]
		for c in items:
			if not sc.is_ancestor_of(c):
				outer.append(c)
		target = _pick(f, dir, outer)
	elif target == null and sc != null and inner.size() < 2:
		target = _pick(f, dir, items)
	if target == null or target == f:
		return false
	if dir.y != 0 and veto.is_valid() and bool(veto.call(f, target, dir.y)):
		return true
	target.grab_focus()
	sticky_for = target
	var tsc: ScrollContainer = scroll_of(target)
	if tsc != null:
		tsc.ensure_control_visible(target)   # el scroll sigue al foco ya en este fotograma
	return true


static func scroll_of(c: Node) -> ScrollContainer:
	var p: Node = c.get_parent()
	while p != null and not (p is ScrollContainer):
		p = p.get_parent()
	return p as ScrollContainer


# Vecino de f en la direccion dir dentro de items (filas por y global, columna recordada en sticky_x); null si no hay.
static func _pick(f: Control, dir: Vector2i, items: Array) -> Control:
	items = items.duplicate()
	items.sort_custom(func(a: Control, b: Control) -> bool:
		var ac: Vector2 = a.get_global_rect().get_center()
		var bc: Vector2 = b.get_global_rect().get_center()
		if absf(ac.y - bc.y) > 1.0:
			return ac.y < bc.y
		return ac.x < bc.x)
	var rows: Array = []
	for c in items:
		var cc: Vector2 = (c as Control).get_global_rect().get_center()
		var placed := false
		if not rows.is_empty():
			var last: Array = rows[rows.size() - 1]
			var lc: Control = last[0]
			var tol: float = maxf(10.0, 0.45 * minf(lc.size.y, (c as Control).size.y))
			if absf(cc.y - lc.get_global_rect().get_center().y) <= tol:
				last.append(c)
				placed = true
		if not placed:
			rows.append([c])
	var ri := -1
	var ci := -1
	for i in range(rows.size()):
		var idx: int = (rows[i] as Array).find(f)
		if idx >= 0:
			ri = i
			ci = idx
			break
	if ri < 0:
		return null
	if sticky_for != f:
		sticky_x = f.get_global_rect().get_center().x
	var target: Control = null
	if dir.x != 0:
		var row: Array = rows[ri]
		if row.size() < 2:
			return null
		target = row[posmod(ci + dir.x, row.size())]
		sticky_x = target.get_global_rect().get_center().x
	else:
		var nr: int = ri + dir.y
		if nr < 0 or nr >= rows.size():
			return null
		var best := INF
		for c in rows[nr]:
			var dx: float = absf((c as Control).get_global_rect().get_center().x - sticky_x)
			if dx < best:
				best = dx
				target = c
	return target
