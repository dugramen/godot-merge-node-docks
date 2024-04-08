@tool
extends EditorPlugin

var node_dock: Control;
var inspector_dock: Control;
var inspector: Control
var tab_container := TabContainer.new()
var signals_dock: Control
var groups_dock: Control
var signals_container := MarginContainer.new()
var groups_container := MarginContainer.new()

func create_dummy(on_node_found := func(n: Node): pass, node_name := "Node") -> Control:
	var control := Control.new()
	control.name = "dummy_" + node_name 
	control.ready.connect(func():
		var parent := control.get_parent_control()
		if parent.has_node(node_name):
			on_node_found.call(parent.get_node(node_name))
		control.queue_free()
	)
	return control

func _handles(object):
	return object is Node

func _edit(object):
	if object is Node:
		tab_container = inspector_dock.get_node("MergedTabs")
		if tab_container:
			for tab in ["Signals", "Groups"]:
				var n: Control = tab_container.get_node(tab)
				if n:
					n.get_child(0).visible = true

func _enter_tree():
	for i in EditorPlugin.DOCK_SLOT_MAX:
		var node_dummy := create_dummy(func(n: Node): node_dock = n)
		add_control_to_dock(i, node_dummy)
		var inspector_dummy := create_dummy(func(n: Node): 
			inspector_dock = n;
			after_inspector_found()
		, "Inspector")
		add_control_to_dock(i, inspector_dummy)
	
	await get_tree().process_frame
	EditorInterface.get_file_system_dock().get_parent().tab_changed.emit(0)

func after_inspector_found():
	if inspector_dock and node_dock:
		inspector = inspector_dock.get_child(-1)
		signals_dock = node_dock.get_child(1)
		groups_dock = node_dock.get_child(2)
		inspector.name = "Properties"
		signals_container.name = "Signals"
		groups_container.name = "Groups"
		tab_container.name = "MergedTabs"
		
		for n: Control in [signals_container, signals_dock, groups_container, groups_dock, inspector, tab_container]:
			n.size_flags_vertical = Control.SIZE_EXPAND_FILL
			n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		inspector_dock.add_child(tab_container)
		inspector.reparent(tab_container)
		tab_container.add_child(signals_container)
		tab_container.add_child(groups_container)
		signals_dock.reparent(signals_container)
		groups_dock.reparent(groups_container)
		
		get_tree().process_frame.connect(func():
			remove_control_from_docks(node_dock)
		, CONNECT_ONE_SHOT)

func _exit_tree():
	# Clean-up of the plugin goes here.
	var accept := AcceptDialog.new()
	accept.dialog_text = "Restart the editor to revert the Node dock."
	EditorInterface.popup_dialog_centered(accept)
	pass
