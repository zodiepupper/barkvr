extends Area3D

@onready var mesh: MeshInstance3D = %mesh
@onready var shape: CollisionShape3D = %shape
@onready var text: Label3D = %text

func _ready() -> void:
	body_entered.connect(entered)
	body_exited.connect(exited)
	area_entered.connect(entered)
	area_exited.connect(exited)

func entered(body:Node3D) -> void:
	pass

func exited(body:Node3D) -> void:
	pass
