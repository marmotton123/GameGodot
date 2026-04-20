extends Interactable
class_name Trap

@export var contenu_du_piege: String = "Rien"

func interact(player) -> void:
	if not player.is_carrying:
		if contenu_du_piege == "Rien":
			print("Le piège est vide. Je repasserai plus tard.")
		elif contenu_du_piege == "Chair non identifiée":
			print("Qu'est-ce que... c'est quoi ce truc ? Ça ne ressemble à aucun animal...")
		else:
			print("Super, j'ai attrapé : ", contenu_du_piege)
			player.pick_up(contenu_du_piege)
			contenu_du_piege = "Rien"
	else : 
		print("Je devrais ramener ça au camion avant.")
