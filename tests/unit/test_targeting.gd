extends TestCase

var _nodes: Array[Node2D] = []


func after_each() -> void:
	for node in _nodes:
		node.free()
	_nodes.clear()


func test_pick_nearest_valid() -> void:
	var far := _node(Vector2(100, 0))
	var near := _node(Vector2(10, 0))
	var nearest_invalid := _node(Vector2(1, 0))
	var invalid: Array[Node2D] = [nearest_invalid]
	var is_valid := func(candidate: Node2D) -> bool: return not invalid.has(candidate)
	var picked := CombatController.pick_nearest(Vector2.ZERO, [far, near, nearest_invalid], is_valid)
	assert_eq(picked, near)


func test_pick_nearest_none() -> void:
	var only := _node(Vector2(5, 5))
	assert_null(CombatController.pick_nearest(Vector2.ZERO, [], func(_c: Node2D) -> bool: return true))
	assert_null(CombatController.pick_nearest(Vector2.ZERO, [only], func(_c: Node2D) -> bool: return false))


func _node(position: Vector2) -> Node2D:
	var node := Node2D.new()
	node.position = position
	_nodes.append(node)
	return node
