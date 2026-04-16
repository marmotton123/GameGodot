extends Interactable
class_name Client

# --- RÉFÉRENCES ---
@onready var dialogue_ui_node = get_tree().root.find_child("CanvasLayer_Dialogue", true, false)
@export var anim_player : AnimationPlayer

@onready var destination_node = get_tree().root.find_child("DestinationClient", true, false)
@onready var point_intermediaire = get_tree().root.find_child("PointDePassage", true, false)

# --- VARIABLES INTERNES ---
@export var vitesse_de_marche : float = 1.5
@export var vitesse_animation_base : float = 1.5
@export var phrase_bizarre : String = "La chair... a-t-elle pleuré ?"

var en_attente_kebab : bool = false

# --- PERSONNALISATION ET HISTOIRE ---
@export var skins_possibles : Array[Texture] # Glisse tes différentes images ici pour les couleurs/vêtements

var identites_possibles = ["Dave", "Claire", "Verrue"]
var mon_identite : String = ""
var ma_phrase_choisie : String = ""

# NOTRE BASE DE DONNÉES NARRATIVE
var dialogues_histoire = {
	"Dave": [
		"Salut l'ami ! Sers-moi une belle portion, j'ai 800 bornes dans les pattes.", # Jour 1
		"Tu as de drôles de bêtes dans tes bois... Sers-moi vite.",                 # Jour 2
		"..."                                                                       # Jour 3
	],
	"Claire": [
		"Bonjour ! Les vieux parlent de disparitions près de la cabane...",         # Jour 1
		"J'ai peur de faire ma tournée avec ce brouillard ce matin.",               # Jour 2
		"Vous y êtes allé, n'est-ce pas ? Ne me mentez pas."                        # Jour 3
	],
	"Verrue": [
		"Bonjour jeune homme, un petit morceau bien tendre pour mon chat.",         # Jour 1
		"Pompon a tellement faim... Encore de la viande, s'il vous plaît.",         # Jour 2
		"Pompon n'est pas rentré. Donnez-moi ce morceau sombre avec le sang."       # Jour 3
	]
}


func _ready() -> void:
	add_to_group("Clients")
	preparer_identite_et_dialogue()
	
	if anim_player:
		anim_player.play("Idle")


func preparer_identite_et_dialogue():
	# 1. CHANGER LE SKIN (Si tu as mis des textures dans l'Inspecteur)
	if skins_possibles.size() > 0:
		var index_skin = randi() % skins_possibles.size()
		
		# /!\ ATTENTION : Remplace "Mesh_Du_PNJ" par le vrai nom de ton noeud Mesh 3D dans ta scène !
		if has_node("Mesh_Du_PNJ"):
			var mat = $Mesh_Du_PNJ.get_active_material(0) 
			if mat is StandardMaterial3D:
				mat.albedo_texture = skins_possibles[index_skin]

	# 2. CHOISIR L'IDENTITÉ ET LA PHRASE
	var phrases_de_ce_perso = dialogues_histoire[mon_identite]
	
	# L'index du tableau commence à 0. Donc Jour 1 = index 0.
	# (Assure-toi d'avoir bien créé la variable 'jour_actuel' dans ton script Global !)
	var index_du_jour = Global.jour_actuel - 1
	
	# On vérifie que le personnage a bien une phrase prévue pour ce jour précis
	if index_du_jour < phrases_de_ce_perso.size():
		ma_phrase_choisie = phrases_de_ce_perso[index_du_jour]
	else:
		ma_phrase_choisie = "Je veux juste mon kebab."


func arriver_au_comptoir() -> void:
	if destination_node == null or point_intermediaire == null:
		push_error("Erreur: Impossible de trouver DestinationClient ou PointDePassage dans la scène !")
		return
		
	# --- SYNCHRONISATION DE L'ANIMATION ---
	if anim_player:
		anim_player.speed_scale = vitesse_de_marche / vitesse_animation_base
		anim_player.play("Walk_Formal")

	var tween = create_tween()
	
	# --- ÉTAPE 1 : PIVOTER DOUCEMENT VERS LE POINT DE PASSAGE ---
	var cible_1 = Vector3(point_intermediaire.global_position.x, global_position.y, point_intermediaire.global_position.z)
	var transform_cible_1 = global_transform.looking_at(cible_1, Vector3.UP)
	tween.tween_property(self, "quaternion", transform_cible_1.basis.get_rotation_quaternion(), 0.5)
	
	# --- ÉTAPE 2 : MARCHER VERS LE POINT DE PASSAGE ---
	var distance_1 = global_position.distance_to(point_intermediaire.global_position)
	var temps_1 = distance_1 / vitesse_de_marche
	tween.tween_property(self, "global_position", point_intermediaire.global_position, temps_1)
	
	# --- ÉTAPE 3 : PIVOTER DOUCEMENT VERS LE COMPTOIR (Le Virage) ---
	tween.tween_callback(func():
		var cible_2 = Vector3(destination_node.global_position.x, global_position.y, destination_node.global_position.z)
		var transform_cible_2 = global_transform.looking_at(cible_2, Vector3.UP)
		
		var rotation_tween = create_tween()
		rotation_tween.tween_property(self, "quaternion", transform_cible_2.basis.get_rotation_quaternion(), 0.5)
	)
	
	tween.tween_interval(0.5)
	
	# --- ÉTAPE 4 : MARCHER VERS LE COMPTOIR ---
	var distance_2 = point_intermediaire.global_position.distance_to(destination_node.global_position)
	var temps_2 = distance_2 / vitesse_de_marche
	tween.tween_property(self, "global_position", destination_node.global_position, temps_2)
	
	# --- ÉTAPE 5 : ARRÊT FINAL ---
	tween.tween_callback(func():
		anim_player.play("Idle")
		anim_player.speed_scale = 1.0
		
		en_attente_kebab = true
		
		# Le client utilise la phrase spécifique à son identité et au jour !
		if dialogue_ui_node:
			dialogue_ui_node.start_dialogue(mon_identite, ma_phrase_choisie)
			
		get_tree().call_group("Station", "demarrer_commande")
	)
	
# --- FONCTION D'INTERACTION ---
func interact(player) -> void:
	if dialogue_ui_node == null:
		push_error("UI Dialogue non assignée dans le Client !")
		return
		
	if Global.inventaire_nuit.size() > 0:
		var article_vendu = Global.inventaire_nuit.pop_front()
		var dialogue_complet : String = ""
		
		if article_vendu == "Chair non identifiée":
			dialogue_complet = "Ah... " + phrase_bizarre + " Je vous l'achète à très bon prix."
		else:
			dialogue_complet = "Un simple " + article_vendu + "... C'est décevant, mais je le prends."
			
		dialogue_ui_node.start_dialogue(mon_identite, dialogue_complet)
		
	else:
		dialogue_ui_node.start_dialogue(mon_identite, "Votre frigo est vide. Pourquoi me faire perdre mon temps ? *Il vous fixe*")


func recevoir_kebab() -> void:
	en_attente_kebab = false
	print(mon_identite, " a reçu son Kebab !")
	
	if dialogue_ui_node:
		dialogue_ui_node.start_dialogue(mon_identite, "C'est exactement ce que je voulais... Voici votre argent.")
		
		# On attend 4 secondes pour laisser le joueur lire
		await get_tree().create_timer(4.0).timeout
		
		# On ferme proprement le dialogue !
		dialogue_ui_node.fermer_dialogue()
		
	# Et ensuite, le client s'en va
	partir()


func partir() -> void:
	var tween = create_tween()
	
	tween.tween_callback(func():
		anim_player.play("Idle")
		anim_player.speed_scale = 1.0
	)
	
	var transform_depart = global_transform.looking_at(point_intermediaire.global_position, Vector3.UP)
	tween.tween_property(self, "quaternion", transform_depart.basis.get_rotation_quaternion(), 0.5)
	
	tween.tween_callback(func():
		anim_player.speed_scale = vitesse_de_marche / vitesse_animation_base
		anim_player.play("Walk_Formal")
	)
	
	var distance = global_position.distance_to(point_intermediaire.global_position)
	tween.tween_property(self, "global_position", point_intermediaire.global_position, distance / vitesse_de_marche)
	
	tween.tween_callback(func(): queue_free())
	
