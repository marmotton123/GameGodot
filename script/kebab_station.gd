extends StaticBody3D # TRÈS IMPORTANT : Doit être un StaticBody3D pour être cliquable
class_name KebabStation

@export var mesh_pain : Node3D
@export var mesh_salade : Node3D
@export var mesh_tomates : Node3D
@export var mesh_viande : Node3D
@export var mesh_kebab_ferme : Node3D # Remplace l'emballage. C'est le modèle du kebab roulé/fermé

var commande_en_cours : bool = false
var etape_recette : int = 0 
var joueur_regarde : bool = false # Pour que le joueur puisse interagir

func _ready():
	reinitialiser_station()

func reinitialiser_station():
	etape_recette = 0
	commande_en_cours = false
	mesh_pain.visible = false
	mesh_salade.visible = false
	mesh_tomates.visible = false
	mesh_viande.visible = false
	mesh_kebab_ferme.visible = false

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
	mesh_kebab_ferme.visible = true
	
	etape_recette = 5
	print("Kebab fermé !")

func servir_kebab():
	# 1. On donne le kebab au client actuel (ce qui le fait disparaître)
	get_tree().call_group("Client", "recevoir_kebab")
	
	# 2. On nettoie la table et on reverrouille la cuisine
	reinitialiser_station()
	
	# 3. On prévient le GameManager de lancer le compte à rebours aléatoire !
	get_tree().call_group("Manager", "demarrer_chrono_prochain_client")

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

func peut_ajouter(nom_ingredient: String) -> bool:
	# NOUVEAU : Si pas de commande, on bloque tout de suite !
	if not commande_en_cours:
		return false
		
	match nom_ingredient:
		"pain": return etape_recette == 0
		"salade": return etape_recette == 1
		"tomates": return etape_recette == 2
		"viande": return etape_recette == 3
	return false
	
func est_disponible() -> bool:
	# Le Raycast n'affichera le texte "E" sur la table QUE si on est à l'étape 4 ou 5
	if etape_recette == 4 or etape_recette == 5:
		return true
	else:
		return false

func demarrer_commande() -> void:
	commande_en_cours = true
	print("Un client est là ! La cuisine est ouverte.")
