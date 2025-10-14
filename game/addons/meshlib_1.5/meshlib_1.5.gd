@tool
extends EditorPlugin

# Custom LineEdit that accepts drag and drop
class DragDropLineEdit:
	extends LineEdit

	func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
		if typeof(data) == TYPE_DICTIONARY and data.has("files"):
			return true
		return false

	func _drop_data(at_position: Vector2, data: Variant) -> void:
		if typeof(data) == TYPE_DICTIONARY and data.has("files"):
			var files = data["files"]
			if files.size() > 0:
				var first_path = files[0]
				if first_path.ends_with("/"):
					text = first_path
				else:
					text = first_path.get_base_dir()

var container : VBoxContainer
var line_edit : LineEdit
var rebuild_button : Button
var convert_button : Button

func _enter_tree():
	print("Entered MeshlibTool plugin!")

	container = VBoxContainer.new()
	container.name = "Meshlib Tool"

	line_edit = DragDropLineEdit.new()
	line_edit.placeholder_text = "Drag folder here or enter path (e.g., res://GridMapTest/Tiles/)"
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	rebuild_button = Button.new()
	rebuild_button.text = "Rebuild Meshlib"
	rebuild_button.pressed.connect(_on_rebuild_button_pressed)

	convert_button = Button.new()
	convert_button.text = "Convert Objects to Tile Scenes"
	convert_button.pressed.connect(_on_convert_button_pressed)

	container.add_child(line_edit)
	container.add_child(convert_button)
	container.add_child(rebuild_button)

	add_control_to_dock(DOCK_SLOT_RIGHT_UL, container)

func _exit_tree():
	print("Exited MeshlibTool plugin!")

	if container:
		remove_control_from_docks(container)
		container.queue_free()

func _on_rebuild_button_pressed():
	print("Meshlib rebuild triggered!")
	regenerate_mesh_library()

func _on_convert_button_pressed():
	print("Convert objects to tile scenes triggered!")
	convert_objects_to_scenes()

func regenerate_mesh_library():
	var folder_path := line_edit.text.strip_edges()
	if folder_path.is_empty():
		push_error("Folder path is empty!")
		show_message("Folder path is empty!", true)
		return

	var meshlib_path := folder_path.rstrip("/") + "/meshes.meshlib"

	var meshlib : MeshLibrary
	if ResourceLoader.exists(meshlib_path):
		meshlib = ResourceLoader.load(meshlib_path) as MeshLibrary
	else:
		meshlib = MeshLibrary.new()

	if not meshlib:
		push_error("Could not load or create MeshLibrary.")
		show_message("Could not create MeshLibrary!", true)
		return

	var dir := DirAccess.open(folder_path)
	if not dir:
		push_error("Could not open directory: " + folder_path)
		show_message("Cannot open directory!", true)
		return

	var files = dir.get_files()
	var success := false

	for file in files:
		if file.ends_with(".tscn") and not file.begins_with("tiles"):
			var id = extract_id_from_filename(file)
			if id < 0:
				print("Skipping file with bad name:", file)
				continue

			var scene = ResourceLoader.load(folder_path.rstrip("/") + "/" + file, "", ResourceLoader.CACHE_MODE_IGNORE)
			if scene == null:
				print("Failed to load scene:", file)
				continue

			var instance = scene.instantiate()
			if instance == null:
				print("Failed to instance scene:", file)
				continue

			var mesh_instance = find_first_mesh_instance(instance)
			if mesh_instance == null:
				print("No MeshInstance3D found in:", file)
				continue

			meshlib.create_item(id)
			meshlib.set_item_mesh(id, mesh_instance.mesh)
			meshlib.set_item_name(id, file.get_basename())
			var static_body = find_first_static_body(instance)
			if static_body != null:
				var shapes = find_static_body_shapes(static_body)
				meshlib.set_item_shapes(id, shapes)

			#var tex = meshlib.get_item_preview(id)
			#meshlib.set_item_preview(id, tex)
			success = true

	var save_result = ResourceSaver.save(meshlib, meshlib_path)
	if save_result != OK:
		push_error("Failed to save MeshLibrary.")
		show_message("Failed to save MeshLibrary!", true)
	else:
		if success:
			print("MeshLibrary regenerated successfully!")
			show_message("MeshLibrary regenerated successfully!")
		else:
			print("No valid .tscn files found!", meshlib_path)
			show_message("No valid .tscn files found!", true)

	EditorInterface.get_resource_filesystem().scan()

func convert_objects_to_scenes():
	var original_folder := line_edit.text.strip_edges()
	if original_folder.is_empty():
		push_error("Folder path is empty!")
		show_message("Folder path is empty!", true)
		return

	var dir := DirAccess.open(original_folder)
	if not dir:
		push_error("Could not open directory: " + original_folder)
		show_message("Cannot open directory!", true)
		return

	var files = dir.get_files()
	if files.is_empty():
		push_error("No files found in folder: " + original_folder)
		show_message("No files found in folder!", true)
		return

	var tile_scene_folder := original_folder.rstrip("/") + "/tile_scenes/"
	DirAccess.make_dir_recursive_absolute(tile_scene_folder)

	var count := 0
	for file in files:
		if file.ends_with(".glb") or file.ends_with(".obj") or file.ends_with(".fbx"):
			var resource_path = original_folder.rstrip("/") + "/" + file
			var output_scene_path := tile_scene_folder + file.get_basename() + ".tscn"

			# Create a text-based scene file that inherits from the original
			var scene_file = FileAccess.open(output_scene_path, FileAccess.WRITE)
			if scene_file:
				# Write the TSCN file header with inheritance
				scene_file.store_line("[gd_scene load_steps=2 format=3 uid=\"uid://\"]")

				# Write the inheritance line
				scene_file.store_line("[ext_resource type=\"PackedScene\" path=\"" + resource_path + "\" id=\"1\"]")

				# Write the node structure with inheritance
				scene_file.store_line("[node name=\"" + file.get_basename() + "\" instance=ExtResource(\"1\")]")

				scene_file.close()
				print("Created inherited scene: " + output_scene_path)
				count += 1
			else:
				print("Failed to create scene file: " + output_scene_path)

	# Force re-scan filesystem
	EditorInterface.get_resource_filesystem().scan()

	# Set the LineEdit temporarily to tile_scenes
	line_edit.text = tile_scene_folder

	show_message("Created " + str(count) + " inherited tile scenes.")

	# Reset LineEdit back to original folder
	line_edit.text = original_folder


func extract_id_from_filename(filename: String) -> int:
	var parts = filename.split("_", false)
	if parts.size() >= 2:
		return parts[0].to_int()
	return -1

func find_first_mesh_instance(root: Node) -> MeshInstance3D:
	if root is MeshInstance3D:
		return root
	for child in root.get_children():
		var result = find_first_mesh_instance(child)
		if result != null:
			return result
	return null

func find_first_static_body(root: Node) -> StaticBody3D:
	if root is StaticBody3D:
		return root
	for child in root.get_children():
		var result = find_first_static_body(child)
		if result != null:
			return result
	return null

func find_static_body_shapes(body: StaticBody3D) -> Array:
	var shapes = []
	for child in body.get_children():
		if child is CollisionShape3D:
			shapes.push_back(child.shape)
			shapes.push_back(child.transform)
	return shapes

func show_message(message: String, is_error: bool = false):
	var dialog := AcceptDialog.new()
	dialog.dialog_text = message
	if is_error:
		dialog.dialog_autowrap = true
		dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered()
