extends Window

func _ready() -> void:
	# On connecte le signal du clic sur la croix rouge à notre propre fonction
	close_requested.connect(_on_close_requested)

# Cette fonction est appelée quand le joueur clique sur le 'X' de la fenêtre Windows
func _on_close_requested() -> void:
	pass # On cache la fenêtre au lieu de la détruire
