extends Node

@export var scene_client : PackedScene
@export var point_apparition : Marker3D

var clients_servis_aujourdhui : int = 0

# LE PLANNING PRÉCIS : On définit l'ordre exact pour chaque jour
var planning_journalier = {
	1: ["Dave", "Claire", "Verrue"], # Jour 1 : 3 clients précis
	2: ["Claire", "Verrue", "Dave", "Le Shérif"], # Jour 2 : 4 clients
}

func _ready():
	await get_tree().create_timer(2.0).timeout
	faire_apparaitre_client()

func demarrer_chrono_prochain_client():
	clients_servis_aujourdhui += 1
	
	var liste_du_jour = planning_journalier.get(Global.jour_actuel, [])
	
	# Si on a servi tout le monde dans la liste du jour
	if clients_servis_aujourdhui >= liste_du_jour.size():
		print("Fin de la journée, le quota est atteint !")
		return 

	var temps_attente = randf_range(5.0, 10.0)
	await get_tree().create_timer(temps_attente).timeout
	faire_apparaitre_client()

func faire_apparaitre_client():
	if scene_client and point_apparition:
		var nouveau_client = scene_client.instantiate()
		
		# ON DÉCIDE DE L'IDENTITÉ ICI AVANT DE L'AJOUTER
		var liste_du_jour = planning_journalier.get(Global.jour_actuel, ["Dave"])
		var nom_du_client = liste_du_jour[clients_servis_aujourdhui]
		
		# On transmet le nom au script du client
		nouveau_client.mon_identite = nom_du_client
		
		add_child(nouveau_client)
		nouveau_client.global_position = point_apparition.global_position
		
		if nouveau_client.has_method("arriver_au_comptoir"):
			nouveau_client.arriver_au_comptoir()
