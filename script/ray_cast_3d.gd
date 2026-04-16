extends RayCast3D

# --- RÉFÉRENCES ---
@onready var player = owner # Le joueur (ProtoController)
@onready var interact_text = owner.get_node("UI/InteractText")

# --- VARIABLES INTERNES ---
# NOUVEAU : On le type en 'Node3D' plutôt que 'Interactable' 
# pour qu'il accepte aussi les bacs de cuisine (StaticBody3D)
var current_target : Node3D = null

func _physics_process(_delta: float) -> void:
	
	# --- PHASE 1 : DÉTECTION ---
	if is_colliding():
		var hit = get_collider()
		
		# Le RayCast valide la cible SI c'est un Interactable OU s'il possède la variable "joueur_regarde"
		if hit is Interactable or "joueur_regarde" in hit:
			
			interact_text.show()
			
			# -- LE JOUEUR REGARDE UN NOUVEL OBJET VALIDE --
			if current_target != hit:
				# On éteint l'ancien objet proprement
				_cleanup_target()
				
				# On cible le nouveau
				current_target = hit
				
				# Si c'est un vieil Interactable, on l'allume
				if current_target.has_method("activate_highlight"):
					current_target.activate_highlight()
					
				# Si c'est un élément de cuisine, on lui dit qu'on le regarde !
				if "joueur_regarde" in current_target:
					current_target.joueur_regarde = true
					
			
			# --- PHASE 2 : ACTION (CLIC SIMPLE) ---
			# On garde ça uniquement pour les objets qui utilisent la fonction 'interact()'
			# (Les bacs gèrent leur propre maintien de touche dans leur script)
			if Input.is_action_just_pressed("interact"): 
				if current_target.has_method("interact"):
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
