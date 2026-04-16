extends Node

func _ready() -> void:
	# Dès que le jeu se lance, on force l'affichage sur le bureau !
	$AtlasWindow.show()
	$PhoneWindow.show()
