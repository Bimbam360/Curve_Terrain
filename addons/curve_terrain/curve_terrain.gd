tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("Curve_terrain", "Path", preload("Path_Terrain.gd"), preload("icon.png"))


func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_custom_type("Curve_terrain")

