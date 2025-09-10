class_name Inventory

var contents: Array[Item] = []

func add_item(item:Item):
	contents.append(item)
	
func remove_item(item:Item):
	contents.erase(item)
	
func get_items() -> Array[Item]:
	return contents
