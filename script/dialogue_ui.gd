extends CanvasLayer

# --- RÉGLAGES ---
@export var typewriter_speed : float = 0.03 # Temps entre chaque lettre (en s)

# --- RÉFÉRENCES ---
@onready var text_label = $Panel/RichTextLabel
@onready var dialogue_timer = $Panel/DialogueTimer

# --- VARIABLES INTERNES ---
var dialogue_text : String = "" # Le texte complet à afficher
var current_index : int = 0     # Index de la lettre actuelle
var is_active : bool = false    # Est-ce que le dialogue est affiché ?

func _ready() -> void:
	# On cache le dialogue au lancement du jeu
	self.hide()
	is_active = false
	
	# On connecte le signal timeout du Timer à notre fonction d'écriture
	dialogue_timer.timeout.connect(_on_dialogue_timer_timeout)

## Démarre un dialogue complet
func start_dialogue(subject: String, full_text: String) -> void:
	# On formate le texte avec BBCode : Sujet en jaune, puis texte en blanc
	dialogue_text = subject + " : " + full_text
	
	# On réinitialise l'affichage
	text_label.text = ""
	current_index = 0
	
	# On affiche la boîte
	self.show()
	is_active = true
	
	# On démarre le Timer
	dialogue_timer.wait_time = typewriter_speed
	dialogue_timer.start()

## Appelé à chaque "tic" du Timer pour écrire la lettre suivante
func _on_dialogue_timer_timeout() -> void:
	if current_index < dialogue_text.length():
		# On ajoute la lettre suivante au Label
		text_label.text += dialogue_text[current_index]
		current_index += 1
	else:
		# L'écriture est finie
		dialogue_timer.stop()

## Gère la touche 'Interact' pour passer ou fermer le dialogue
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and is_active:
		if current_index == dialogue_text.length():
			# Le texte est fini d'écrire, on ferme le dialogue
			self.hide()
			is_active = false
		else:
			# L'écriture est en cours, on affiche tout le texte d'un coup
			dialogue_timer.stop()
			text_label.text = dialogue_text
			current_index = dialogue_text.length()
