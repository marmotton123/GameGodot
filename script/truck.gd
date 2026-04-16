extends Interactable
class_name Truck

# Une liste (Array) pour mémoriser tout ce qu'on a mis dans le coffre cette nuit
var cargaison: Array[String] = []

func interact(player) -> void:
	if player.is_carrying:
		var item_depose = player.drop_off()
		cargaison.append(item_depose)
		
		print("J'ai chargé : ", item_depose, " dans le camion.")
		
		# On lui envoie la taille de notre liste 'cargaison' (qui correspond au nombre de pièges)
		player.update_trap_counter(cargaison, 3)		
	else:
		print("Je n'ai rien à déposer. Je devrais aller vérifier mes pièges.")
