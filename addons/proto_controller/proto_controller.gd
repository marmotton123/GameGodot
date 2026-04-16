# ProtoController v1.0 by Brackeys
# CC0 License
# Intended for rapid prototyping of first-person games.
# Happy prototyping!

extends CharacterBody3D

## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = false
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = false

## Can we hold to crouch?
@export var can_crouch : bool = true
## How fast do we crouch walk?
@export var crouch_speed : float = 3.0

## Name of Input Action to Crouch.

@export_group("Crouch Settings")
## Normal height of the collision shape
@export var normal_height : float = 2.0
## Height of the collision shape when crouching
@export var crouch_height : float = 1.0
## How fast the camera/collider goes down and up
@export var crouch_transition_speed : float = 10.0

var is_crouching : bool = false


@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.002
## Normal speed.
@export var base_speed : float = 7.0
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we run?
@export var sprint_speed : float = 10.0
## How fast do we freefly?
@export var freefly_speed : float = 25.0

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "ui_left"
## Name of Input Action to move Right.
@export var input_right : String = "ui_right"
## Name of Input Action to move Forward.
@export var input_forward : String = "ui_up"
## Name of Input Action to move Backward.
@export var input_back : String = "ui_down"
## Name of Input Action to Jump.
@export var input_jump : String = "ui_accept"
## Name of Input Action to Sprint.
@export var input_sprint : String = "sprint"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"
## Name of Input Action to Crouch.
@export var input_crouch : String = "crouch"

## Name of Windows var
@onready var atlas_window = WindowManager.get_node("AtlasWindow")
@onready var phone_window = WindowManager.get_node("PhoneWindow")

# --- SYSTÈME DE FENÊTRES MULTIPLES ---
enum FocusState { MAIN, ATLAS, PHONE }
var current_focus = FocusState.MAIN
var tab_pressed = false # Sécurité pour éviter que ça clignote trop vite

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false

var is_carrying : bool = false
var carried_item_name : String = ""
## IMPORTANT REFERENCES
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
@onready var default_head_y : float = head.position.y
@onready var flashlight: SpotLight3D = $Head/Camera3D/Flashlight
@onready var carried_visual = $Head/Camera3D/CarriedItem # Le cube sur l'épaule
@onready var trap_counter_label = $UI/TrapCounter

func _ready() -> void:
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	
	#On exige que Windows donne le focus à notre fenêtre de jeu
	get_window().grab_focus()
	
	# On utilise call_deferred pour attendre une fraction de seconde 
	# que la fenêtre soit bien active avant de capturer la souris
	call_deferred("capture_mouse")
	
func _unhandled_input(event: InputEvent) -> void:
	if current_focus != FocusState.MAIN:
		return
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()
	
	# Activer / Désactiver la lampe torche
	if Input.is_action_just_pressed("flashlight"):
		flashlight.visible = not flashlight.visible # Alterne entre allumé et éteint

func _process(delta: float) -> void:
	# On interroge directement le clavier physique pour bypasser les fenêtres OS
	if Input.is_key_pressed(KEY_TAB):
		if not tab_pressed:
			tab_pressed = true
			cycle_focus()
	else:
		tab_pressed = false

func _physics_process(delta: float) -> void:

	if current_focus != FocusState.MAIN:
		return
		
	# If freeflying, handle freefly and nothing else
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return
	
	
	# Apply gravity to velocity
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * delta

	# Apply jumping
	if can_jump:
		if Input.is_action_just_pressed(input_jump) and is_on_floor():
			velocity.y = jump_velocity

	# Modify speed based on sprinting
	# Handle crouching state
	if can_crouch:
		is_crouching = Input.is_action_pressed(input_crouch)

	# Modify speed based on sprinting or crouching
	if can_crouch and is_crouching:
		move_speed = crouch_speed
	elif can_sprint and Input.is_action_pressed(input_sprint):
		move_speed = sprint_speed
	else:
		move_speed = base_speed

	# Smoothly adjust collider height and head position
	if can_crouch and collider.shape is CapsuleShape3D:
		var target_height = crouch_height if is_crouching else normal_height
		collider.shape.height = lerp(collider.shape.height, target_height, delta * crouch_transition_speed)
		
		var head_target_y = (default_head_y - (normal_height - crouch_height)) if is_crouching else default_head_y
		head.position.y = lerp(head.position.y, head_target_y, delta * crouch_transition_speed)

	# Apply desired movement to velocity
	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.y = 0
	
	# Use velocity to actually move
	move_and_slide()


## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)


func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


## Checks if some Input Actions haven't been created.
## Disables functionality accordingly.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false
	if can_crouch and not InputMap.has_action(input_crouch):
		push_error("Crouching disabled. No InputAction found for input_crouch: " + input_crouch)
		can_crouch = false

## Appelé par le piège quand on ramasse un truc
func pick_up(item_name: String) -> void:
	is_carrying = true
	carried_item_name = item_name
	carried_visual.visible = true # On affiche le cube sur l'épaule
	print("Je porte maintenant : ", item_name)

## Appelé par le camion quand on dépose un truc
func drop_off() -> String:
	var item = carried_item_name
	is_carrying = false
	carried_item_name = ""
	carried_visual.visible = false # On cache le cube
	print("J'ai déposé : ", item)
	return item

## Met à jour le compteur et vérifie si la nuit est finie
func update_trap_counter(cargaison_du_camion: Array, total_requis: int = 3) -> void:
	var nombre_depose = cargaison_du_camion.size()
	trap_counter_label.text = "Pièges récupérés : " + str(nombre_depose) + " / " + str(total_requis)
	
	if nombre_depose >= total_requis:
		print("Nuit terminée ! Sauvegarde de l'inventaire...")
		
		# On copie la cargaison du camion dans notre script Global immortel !
		Global.inventaire_nuit = cargaison_du_camion.duplicate()
		
		# Et on change de scène !
		get_tree().change_scene_to_file("res://scenes/shop.tscn")


func cycle_focus() -> void:
	match current_focus:
		
		# ÉTAPE 1 : FOCUS SUR L'ATLAS
		FocusState.MAIN:
			current_focus = FocusState.ATLAS
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # Libère la souris
			
			if atlas_window != null:
				atlas_window.grab_focus() 
				atlas_window.get_node("FocusBorder").show() # Allume le jaune de l'Atlas
				
			if phone_window != null:
				phone_window.get_node("FocusBorder").hide() # Éteint le jaune du tél

		# ÉTAPE 2 : FOCUS SUR LE TÉLÉPHONE
		FocusState.ATLAS:
			current_focus = FocusState.PHONE
			
			if phone_window != null:
				phone_window.grab_focus() 
				phone_window.get_node("FocusBorder").show() # Allume le jaune du tél
				
			if atlas_window != null:
				atlas_window.get_node("FocusBorder").hide() # Éteint le jaune de l'Atlas

		# ÉTAPE 3 : RETOUR AU JEU
		FocusState.PHONE:
			current_focus = FocusState.MAIN
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Capture la souris
			get_window().grab_focus() # Redonne le focus au jeu principal
			
			# On éteint juste les bordures jaunes
			if atlas_window != null:
				atlas_window.get_node("FocusBorder").hide()
			if phone_window != null:
				phone_window.get_node("FocusBorder").hide()
