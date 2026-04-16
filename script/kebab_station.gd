extends StaticBody3D # TRÈS IMPORTANT : Doit être un StaticBody3D pour être cliquable
class_name KebabStation

@export var mesh_pain : Node3D
@export var mesh_salade : Node3D
@export var mesh_tomates : Node3D
@export var mesh_viande : Node3D
@export var mesh_kebab_ferme : Node3D # Remplace l'emballage. C'est le modèle du kebab roulé/fermé

var etape_recette : int = 0 
var joueur_regarde : bool = false # Pour que le joueur puisse interagir

func _ready():
	reinitialiser_station()

func reinitialiser_station():
	etape_recette = 0
	mesh_pain.visible = false
	mesh_salade.visible = false
	mesh_tomates.visible = false
	mesh_viande.visible = false
	if mesh_kebab_ferme: mesh_kebab_ferme.visible = false

# --- FONCTION D'INTERACTION DIRECTE (Appelée par le joueur) ---
func _process(_delta):
	# Si le joueur regarde le Kebab sur la table ET fait un clic simple sur E
	if joueur_regarde and Input.is_action_just_pressed("interact"):
		
		if etape_recette == 4: # Viande mise, prêt à fermer
			fermer_kebab()
		elif etape_recette == 5: # Kebab déjà fermé, prêt à servir
			servir_kebab()

func fermer_kebab():
	# On cache tous les ingrédients ouverts...
	mesh_pain.visible = false
	mesh_salade.visible = false
	mesh_tomates.visible = false
	mesh_viande.visible = false
	# ...Et on affiche le modèle du Kebab fermé !
	if mesh_kebab_ferme: mesh_kebab_ferme.visible = true
	
	etape_recette = 5
	print("Kebab fermé !")

func servir_kebab():
	# 1. On cherche tous les objets dans le jeu qui ont le badge "Clients"
	var tous_les_clients = get_tree().get_nodes_in_group("Clients")
	var client_qui_attend = null
	
	# 2. On vérifie s'il y en a un qui est arrivé au comptoir
	for c in tous_les_clients:
		if c.en_attente_kebab == true:
			client_qui_attend = c
			break # On a trouvé notre client, on arrête de chercher
			
	# 3. Si on a trouvé quelqu'un, on lui donne !
	if client_qui_attend != null:
		client_qui_attend.recevoir_kebab()
		reinitialiser_station() # On nettoie la table
		print("Kebab donné au client !")
	else:
		# S'il n'y a personne (ou qu'il est encore en train de marcher)
		print("Personne n'attend de commande !")
		# Optionnel : Tu pourrais afficher un petit texte à l'écran du joueur
# --- LES ACTIONS DES BACS (Restent pareilles) ---
func essayer_ajouter_pain():
	if etape_recette == 0:
		mesh_pain.visible = true
		etape_recette = 1

func essayer_ajouter_salade():
	if etape_recette == 1:
		mesh_salade.visible = true
		etape_recette = 2

func essayer_ajouter_tomates():
	if etape_recette == 2:
		mesh_tomates.visible = true
		etape_recette = 3

func essayer_ajouter_viande():
	if etape_recette == 3:
		mesh_viande.visible = true
		etape_recette = 4
