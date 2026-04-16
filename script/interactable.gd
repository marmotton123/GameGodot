extends StaticBody3D
class_name Interactable

# --- RÉFÉRENCES ---
# Nous allons automatiquement chercher un nœud enfant qui s'appelle "Highlight"
@onready var highlight_node: Node3D = get_node_or_null("Highlight")

# --- FONCTION D'INTERACTION PRINCIPALE (A redéfinir dans les enfants) ---
## Cette fonction sera appelée quand le joueur cliquera sur l'objet.
func interact(player) -> void:
	pass # Par défaut, il ne se passe rien. Les enfants devront changer ça.

# --- SYSTÈME DE SURLIGNEMENT (HIGHLIGHT) ---

## Allume le filtre gris-blanc
func activate_highlight() -> void:
	if highlight_node != null:
		highlight_node.visible = true # Affiche le nœud lumineux
		# print("Highlight activé pour :", name)

## Éteint le filtre gris-blanc
func deactivate_highlight() -> void:
	if highlight_node != null:
		highlight_node.visible = false # Cache le nœud lumineux
		# print("Highlight désactivé pour :", name)
