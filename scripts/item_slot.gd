extends PanelContainer

@onready var tex: TextureRect = %TextureRect

func display(item: Item):
	tex.texture = item.icon
