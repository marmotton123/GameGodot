extends RayCast3D

# --- RÉFÉRENCES ---
@onready var player = owner # Le joueur (ProtoController)
@onready var interact_text = owner.get_node("UI/InteractText")

# --- VARIABLES INTERNES ---
var current_target : Node3D = null

func _physics_process(_delta: float) -> void:
	
	# --- PHASE 1 : DÉTECTION ---
	if is_colliding():
		var hit = get_collider()
		
		# Le RayCast valide la cible SI c'est un Interactable OU s'il possède la variable "joueur_regarde"
		if hit is Interactable or "joueur_regarde" in hit:
			
			# -- 1. CHANGEMENT DE CIBLE --
			if current_target != hit:
				# On éteint l'ancien objet proprement
				_cleanup_target()
				
				# On cible le nouveau
				current_target = hit
				
				if current_target.has_method("activate_highlight"):
					current_target.activate_highlight()
					
				if "joueur_regarde" in current_target:
					current_target.joueur_regarde = true
					
			
			# -- 2. GESTION DE L'AFFICHAGE DU TEXTE "E" --
			# Si l'objet possède une condition d'interaction (comme nos bacs à ingrédients)
			if current_target.has_method("est_disponible"):
				if current_target.est_disponible():
					interact_text.show()
				else:
					interact_text.hide()
			else:
				# Si l'objet est normal (une porte, un PNJ classique...)
				interact_text.show()
					
			
			# --- PHASE 2 : ACTION (CLIC SIMPLE) ---
			if Input.is_action_just_pressed("interact"):
				
				# On empêche le clic si l'objet n'est pas disponible (ex: kebab fermé)
				if current_target.has_method("est_disponible") and not current_target.est_disponible():
					pass # On ne fait rien
					
				# Sinon, on interagit normalement
				elif current_target.has_method("interact"):
					current_target.interact(player)
					
		else:
			# L'objet touché n'est ni interactif ni un bac de cuisine
			_cleanup_target()
			
	else:
		# Le rayon ne touche rien, on éteint tout.
		_cleanup_target()

## Éteint les effets et remet les variables à zéro
func _cleanup_target() -> void:
	if current_target != null:
		# On coupe le highlight si ça en était un
		if current_target.has_method("deactivate_highlight"):
			current_target.deactivate_highlight()
			
		# On dit au bac de cuisine qu'on ne le regarde plus !
		if "joueur_regarde" in current_target:
			current_target.joueur_regarde = false
			
		# On oublie la référence
		current_target = null
		
	interact_text.hide()
