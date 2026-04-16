extends StaticBody3D

@export var nom_ingredient : String = "pain"
@export var temps_requis : float = 2.0 # 2 secondes pour salade, tomate, viande
@export var station_kebab : Node3D 

var temps_maintenu : float = 0.0
var joueur_regarde : bool = false # Sera géré par le RayCast de ton joueur

func _process(delta):
	# Si le joueur regarde ce bac ET qu'il maintient la touche E
	if joueur_regarde and Input.is_action_pressed("interact"):
		temps_maintenu += delta
		
		# Quand les 2 secondes sont atteintes
		if temps_maintenu >= temps_requis:
			valider_ingredient()
			temps_maintenu = 0.0
			joueur_regarde = false # Oblige à relâcher pour en remettre un
			
	# S'il lâche la touche E trop tôt, on remet le compteur à zéro
	elif not Input.is_action_pressed("interact"):
		temps_maintenu = 0.0

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
