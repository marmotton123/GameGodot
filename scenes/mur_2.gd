extends Node3D

func _ready():
	# Au lancement, on parcourt tous les enfants de ce noeud
	_add_collisions_recursive(self)

func _add_collisions_recursive(node: Node):
	for child in node.get_children():
		# On vérifie que c'est un MeshInstance3D ET qu'il a bien un mesh (visuel) chargé
		if child is MeshInstance3D and child.mesh != null:
			
			# 1. On crée le corps statique (StaticBody3D)
			var static_body = StaticBody3D.new()
			child.add_child(static_body)
			
			# 2. On crée le noeud de collision (CollisionShape3D)
			var collision_shape = CollisionShape3D.new()
			static_body.add_child(collision_shape)
			
			# 3. On crée la forme de la boîte (BoxShape3D)
			var box_shape = BoxShape3D.new()
			
			# 4. LA MAGIE : On calcule la "Bounding Box" (l'encombrement maximum du mesh)
			var aabb = child.mesh.get_aabb()
			
			# On donne à notre boîte la taille exacte calculée
			box_shape.size = aabb.size
			collision_shape.shape = box_shape
			
			# 5. On centre la collision par rapport au mesh
			collision_shape.position = aabb.get_center()
			
		# On rappelle la fonction pour chercher dans les sous-dossiers/noeuds enfants
		_add_collisions_recursive(child)
