extends StaticBody3D

@export var nom_ingredient : String = "pain"
@export var temps_requis : float = 2.0 # 2 secondes pour salade, tomate, viande
@export var station_kebab : Node3D 
@onready var progress_circle = get_tree().root.find_child("KebabProgressBar", true, false)

var temps_maintenu : float = 0.0
var joueur_regarde : bool = false # Sera géré par le RayCast de ton joueur
# Référence à ta barre de progression (à adapter selon ton chemin)
var action_terminee : bool = false

func _process(delta):
	# 1. Si le joueur NE REGARDE PAS ce bac
	if not joueur_regarde:
		action_terminee = false
		
		# NOUVEAU : Le bac ne cache l'UI que s'il était en train de s'en servir !
		if temps_maintenu > 0:
			reset_ui()
		return
		
	# 2. L'ACTION : Si on regarde, que c'est le bon moment, et qu'on maintient E
	if est_disponible() and Input.is_action_pressed("interact") and not action_terminee:
		temps_maintenu += delta
		
		if progress_circle:
			# NOUVEAU : Évite un bug si tu as mis "0 seconde" pour le pain
			if temps_requis > 0:
				progress_circle.show()
				progress_circle.value = clamp((temps_maintenu / temps_requis) * 100, 0, 100)
			
		if temps_maintenu >= temps_requis:
			valider_ingredient()
			action_terminee = true # On verrouille
			reset_ui()
			
	# 3. L'ANNULATION : Si on lâche la touche
	elif not Input.is_action_pressed("interact") or not est_disponible():
		# On ne cache l'UI que si on avait commencé à remplir la jauge
		if temps_maintenu > 0:
			reset_ui()

func reset_ui():
	temps_maintenu = 0.0
	if progress_circle:
		progress_circle.hide()
		progress_circle.value = 0

func valider_ingredient():
	if station_kebab == null: return
	
	match nom_ingredient:
		"pain":
			station_kebab.essayer_ajouter_pain()
		"salade":
			station_kebab.essayer_ajouter_salade()
		"tomates":
			station_kebab.essayer_ajouter_tomates()
		"viande":
			station_kebab.essayer_ajouter_viande()

func est_disponible() -> bool:
	if station_kebab:
		return station_kebab.peut_ajouter(nom_ingredient)
	return false
