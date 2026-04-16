extends Interactable
class_name Client

# --- RÉFÉRENCES (À remplir dans l'Inspecteur) ---
@export var dialogue_ui_node : Node
@export var anim_player : AnimationPlayer # Plus sûr que le get_node("$...") !

@export var point_intermediaire : Marker3D # Le point pour tourner
@export var destination_node : Marker3D    # La cible finale devant le comptoir
@export var vitesse_de_marche : float = 1.5 
@export var vitesse_animation_base : float = 1.5 
@export var phrase_bizarre : String = "La chair... a-t-elle pleuré ?"

var en_attente_kebab : bool = false
func _ready() -> void:
	# NOUVEAU : On donne le badge "Clients" à ce PNJ
	add_to_group("Clients")
	
	if anim_player:
		anim_player.play("Idle")
	arriver_au_comptoir()

func arriver_au_comptoir() -> void:
	await get_tree().create_timer(3.0).timeout
	
	if destination_node == null or point_intermediaire == null:
		push_error("Il manque un Marker3D dans l'inspecteur !")
		return
		
	# --- SYNCHRONISATION DE L'ANIMATION ---
	if anim_player:
		anim_player.speed_scale = vitesse_de_marche / vitesse_animation_base
		anim_player.play("Walk_Formal")

	# On crée notre "liste de courses" d'animations
	var tween = create_tween()
	
	# --- ÉTAPE 1 : PIVOTER DOUCEMENT VERS LE POINT DE PASSAGE ---
	var cible_1 = Vector3(point_intermediaire.global_position.x, global_position.y, point_intermediaire.global_position.z)
	# On calcule la position qu'il DEVRAIT avoir
	var transform_cible_1 = global_transform.looking_at(cible_1, Vector3.UP)
	# On lui dit de tourner jusqu'à cette position en 0.5 seconde
	tween.tween_property(self, "quaternion", transform_cible_1.basis.get_rotation_quaternion(), 0.5)
	
	# --- ÉTAPE 2 : MARCHER VERS LE POINT DE PASSAGE ---
	var distance_1 = global_position.distance_to(point_intermediaire.global_position)
	var temps_1 = distance_1 / vitesse_de_marche
	tween.tween_property(self, "global_position", point_intermediaire.global_position, temps_1)
	
	# --- ÉTAPE 3 : PIVOTER DOUCEMENT VERS LE COMPTOIR (Le Virage) ---
	# On utilise tween_callback pour exécuter du code entre deux marches
	tween.tween_callback(func():
		var cible_2 = Vector3(destination_node.global_position.x, global_position.y, destination_node.global_position.z)
		var transform_cible_2 = global_transform.looking_at(cible_2, Vector3.UP)
		
		# On crée un mini-tween juste pour ce virage (0.5 seconde)
		var rotation_tween = create_tween()
		rotation_tween.tween_property(self, "quaternion", transform_cible_2.basis.get_rotation_quaternion(), 0.5)
	)
	
	# On ajoute une petite pause de 0.5s au tween principal pour le laisser finir de tourner
	tween.tween_interval(0.5)
	
	# --- ÉTAPE 4 : MARCHER VERS LE COMPTOIR ---
	var distance_2 = point_intermediaire.global_position.distance_to(destination_node.global_position)
	var temps_2 = distance_2 / vitesse_de_marche
	tween.tween_property(self, "global_position", destination_node.global_position, temps_2)
	
# --- ÉTAPE 5 : ARRÊT FINAL ---
	tween.tween_callback(func():
		anim_player.play("Idle")
		anim_player.speed_scale = 1.0
		
		# Le client attend son kebab
		en_attente_kebab = true
		
		# (Optionnel) Le dialogue s'affiche
		if dialogue_ui_node:
			dialogue_ui_node.start_dialogue("Client", "Faites-moi un kebab complet s'il vous plaît !")
			
		# L'APPEL MAGIQUE : Il crie au groupe "Station" de lancer la fonction "demarrer_commande"
		get_tree().call_group("station", "demarrer_commande")
	)
	
# --- FONCTION D'INTERACTION (Héritée de Interactable) ---
func interact(player) -> void:
	if dialogue_ui_node == null:
		push_error("UI Dialogue non assignée dans le Client !")
		return
		
	# Si on a de la viande de la nuit
	if Global.inventaire_nuit.size() > 0:
		var article_vendu = Global.inventaire_nuit.pop_front()
		var dialogue_complet : String = ""
		
		if article_vendu == "Chair non identifiée":
			dialogue_complet = "Ah... " + phrase_bizarre + " Je vous l'achète à très bon prix."
		else:
			dialogue_complet = "Un simple " + article_vendu + "... C'est décevant, mais je le prends."
			
		# On affiche le texte à l'écran
		dialogue_ui_node.start_dialogue("Client", dialogue_complet)
		
	else:
		# Si le joueur n'a rien à vendre
		dialogue_ui_node.start_dialogue("Client", "Votre frigo est vide. Pourquoi me faire perdre mon temps ? *Il vous fixe*")

# --- NOUVELLES FONCTIONS DE DÉPART ---
func recevoir_kebab() -> void:
	en_attente_kebab = false
	print("Le client a reçu son Kebab !")
	
	if dialogue_ui_node:
		dialogue_ui_node.start_dialogue("Client", "C'est exactement ce que je voulais... Voici votre argent.")
		
	
	# Il a eu ce qu'il voulait, il repart !
	partir()

func partir() -> void:
	var tween = create_tween()
	
	# Il se retourne vers son point de départ (on triche en reprenant sa position initiale)
	# (Pour faire plus propre, tu peux ajouter un nouveau Marker3D "SortieNode" dans l'inspecteur)
	tween.tween_callback(func(): 
		anim_player.play("Idle")
		anim_player.speed_scale = 1.0
	)
	
	# Il fait demi-tour vers le point intermédiaire
	var transform_depart = global_transform.looking_at(point_intermediaire.global_position, Vector3.UP)
	tween.tween_property(self, "quaternion", transform_depart.basis.get_rotation_quaternion(), 0.5)
	
	tween.tween_callback(func(): 
		anim_player.speed_scale = vitesse_de_marche / vitesse_animation_base
		anim_player.play("Walk_Formal")
	)
	
	# Il marche vers le point de passage
	var distance = global_position.distance_to(point_intermediaire.global_position)
	tween.tween_property(self, "global_position", point_intermediaire.global_position, distance / vitesse_de_marche)
	
	# Quand il arrive au bout, on supprime le client (il a quitté le magasin)
	tween.tween_callback(func(): queue_free())
	
