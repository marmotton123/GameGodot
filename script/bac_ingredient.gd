extends StaticBody3D

@export var nom_ingredient : String = "pain"
@export var temps_requis : float = 2.0 # 2 secondes pour salade, tomate, viande
@export var station_kebab : Node3D 
@onready var progress_circle = get_tree().root.find_child("KebabProgressBar", true, false)

var temps_maintenu : float = 0.0
var joueur_regarde : bool = false # Sera géré par le RayCast de ton joueur
# Référence à ta barre de progression (à adapter selon ton chemin)
var action_terminee : bool = false # Le verrou

func _process(delta):
	# On ajoute "and not action_terminee" dans la condition
	if joueur_regarde and Input.is_action_pressed("interact") and not action_terminee:
		temps_maintenu += delta
		
		if progress_circle:
			progress_circle.show()
			progress_circle.value = (temps_maintenu / temps_requis) * 100
		
		if temps_maintenu >= temps_requis:
			valider_ingredient()
			action_terminee = true # On verrouille !
			reset_ui()
			
	elif not Input.is_action_pressed("interact"):
		temps_maintenu = 0.0
		# On ne reset "action_terminee" que si le joueur ne regarde plus l'objet
		# ou selon ta logique (par exemple, ce bac devient définitivement inutile)
		action_terminee = false
		if progress_circle:
			progress_circle.hide()

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
