class_name HealthComponent
extends Node

# Testing out custom components

signal died
signal changed(current: float, last: float)

@export var max_health: float = 100.0

var health: float

func _ready() -> void:
	reset()
	
func reset() -> void:
	health = max_health
	

func apply_damage(amount: float) -> void:
	var last = health
	health -= amount
	if health <= 0:
		died.emit()
	else:
		changed.emit(health, last)
