extends FlowContainer

var members :String = "Talha
ParkerK
74hc595
Cubiix
Em
prumbrok
Philiflake
rawpie
Genova
fragilegirl
Nafi
EleanorjMorel
Klaxus
JNP
jeana
Todd
Kostas
Cuddly
Moondancer
koalou
Ginger
John
Luna
NatBard
3x1t_5tyl3
Kitt3ns
Billy
Moonshine
Lyuma
APnda
SemiRandomSevens
Lou
Kloom
Lexevo
laker
glyphli
Pikario
Meow
JNP
Andromeda
Myriad
PlayerDeer
jeana
NatBard
iris"

var MEMBERBOX = load("res://assets/patreon/memberbox.tscn")

func _ready() -> void:
	visibility_changed.connect(func():
		for child in get_children():
			child.queue_free()
		var shuffled_members = Array(members.split("\n"))
		shuffled_members.shuffle()
		for member in shuffled_members:
			var lbl = MEMBERBOX.instantiate()
			add_child(lbl)
			lbl.text = member
		)
