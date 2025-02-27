extends Node2D

var player_cards = []
var bot_cards = []
var chosen_card = null
var current_player = "PLAYER"
var number_player = 0
var number_bot = 0
var target_number = 0
var current_turn = 1
var max_turns = 10

func _ready():
	# Initialisation de la partie
	initialiser_partie()
	

func initialiser_partie():
	number_player = randi() % 10 + 1
	number_bot = randi() % 10 + 1
	target_number = randi() % 50 + 30
	current_turn = 1
	current_player = "PLAYER"

	player_cards = generer_cartes_initiales()
	bot_cards = generer_cartes_initiales()

	maj_interface()

func generer_cartes_initiales():
	var cartes = []
	for i in range(5):
		cartes.append(generer_une_carte())
	return cartes

func generer_une_carte():
	# Exemples de cartes
	var possible_ops = [
		{ "type": "+", "value": randi() % 9 + 1 },
		{ "type": "-", "value": randi() % 9 + 1 },
		{ "type": "x", "value": randi() % 8 + 2 },
		{ "type": "÷", "value": randi() % 8 + 2 }
	]
	var op = possible_ops[randi() % possible_ops.size()]
	
	# Chargement de la scène Card.tscn
	var card_scene = load("res://Cards/Card.tscn")
	var card_instance = card_scene.instantiate()  # Godot 4
	
	card_instance.card_type = op.type
	card_instance.card_value = op.value
	card_instance.card_texture_path = "res://Cards/card_minus_1.png"
	# (Ici on met juste un placeholder, 
	#  à adapter si tu as un dictionnaire TEXTURE pour chaque type/valeur)

	return card_instance

func maj_interface():
	# Mise à jour des labels
	$Control/top_info/lbl_tours.text = "Tour %d/%d" % [current_turn, max_turns]
	if current_player == "PLAYER":
		$Control/top_info/lbl_info.text = "Ton tour"
	else:
		$Control/top_info/lbl_info.text = "Le bot joue…"

	$Control/middle_area/player_area/lbl_player_name.text = "Player (%d)" % number_player
	$Control/middle_area/bot_area/lbl_bot_name.text = "Bot (%d)" % number_bot

	# On vide d’abord le container
	var pc = $Control/middle_area/player_area/player_cards_container
	for child in pc.get_children():
		child.queue_free()

	# Puis on y (ré)ajoute les cartes du joueur
	for c in player_cards:
		# On vérifie si c'est déjà connecté avant de re‐connecter
		var callable_bound = Callable(self, "_on_card_clicked").bind(c)
		if c.is_connected("gui_input", callable_bound):
			c.disconnect("gui_input", callable_bound)
		
		c.connect("gui_input", callable_bound)
		pc.add_child(c)

func _on_card_clicked(event: InputEvent, card):
	# Callback quand on clique sur la carte (signal gui_input)
	if current_player != "PLAYER":
		return
	if event is InputEventMouseButton and event.pressed:
		chosen_card = card
		$timer_calcul.start(10)
		$Control/top_info/lbl_info.text = "Carte choisie : %s%d" % [card.card_type, card.card_value]

func _on_btn_valider_pressed():
	if current_player == "PLAYER" and chosen_card != null:
		valider_calcul_joueur()

func valider_calcul_joueur():
	$timer_calcul.stop()
	var reponse_str = $Control/bottom_area/txt_calcul_reponse.text
	var reponse_int = int(reponse_str)

	var result_attendu = applique_operation(number_player, chosen_card.card_type, chosen_card.card_value)
	
	if reponse_int == result_attendu:
		number_player = result_attendu
		player_cards.erase(chosen_card)
		chosen_card.queue_free()
		chosen_card = null
		$Control/bottom_area/txt_calcul_reponse.text = ""
		maj_interface()
		check_fin_de_tour()
	else:
		$Control/top_info/lbl_info.text = "Réponse incorrecte"
		player_cards.erase(chosen_card)
		chosen_card.queue_free()
		chosen_card = null
		$Control/bottom_area/txt_calcul_reponse.text = ""
		maj_interface()
		check_fin_de_tour()

func applique_operation(current_val, op_type, op_value):
	match op_type:
		"+":
			return current_val + op_value
		"-":
			return current_val - op_value
		"x":
			return current_val * op_value
		"÷":
			if op_value != 0 and current_val % op_value == 0:
				return current_val / op_value
			else:
				return current_val
	return current_val

func check_fin_de_tour():
	if number_player == target_number:
		fin_de_partie("PLAYER")
		return
	
	current_player = "BOT"
	maj_interface()
	await get_tree().create_timer(1.0).timeout  # On attend 1s pour simuler réflexion du bot
	tour_du_bot()

func tour_du_bot():
	if bot_cards.size() > 0:
		var target_table = ""
		var idx = randi() % bot_cards.size()
		var c = bot_cards[idx]
		if randf() < 0.5:
			target_table = "BOT"
		else:
			target_table = "PLAYER"

		if target_table == "BOT":
			number_bot = applique_operation(number_bot, c.card_type, c.card_value)
		else:
			number_player = applique_operation(number_player, c.card_type, c.card_value)

		bot_cards.remove(idx)
		c.queue_free()
	
	if number_bot == target_number:
		fin_de_partie("BOT")
		return
	
	current_turn += 1
	if current_turn > max_turns:
		fin_de_partie("DRAW")
	else:
		current_player = "PLAYER"
		maj_interface()

func fin_de_partie(winner):
	var msg = ""
	if winner == "PLAYER":
		msg = "Tu as gagné !"
	elif winner == "BOT":
		msg = "Le bot a gagné !"
	else:
		var dist_p = abs(number_player - target_number)
		var dist_b = abs(number_bot - target_number)
		if dist_p < dist_b:
			msg = "Fin des tours : tu es le plus proche, tu gagnes !"
		elif dist_b < dist_p:
			msg = "Le bot est le plus proche, il gagne !"
		else:
			msg = "Égalité !"
	$Control/top_info/lbl_info.text = msg
	# Optionnel : désactiver l'UI ou ajouter un bouton pour rejouer ou retourner au menu

func _on_timer_timeout():
	# S'il y a un Timer "timer_calcul" relié
	if current_player == "PLAYER":
		$Control/top_info/lbl_info.text = "Temps écoulé, carte perdue !"
		if chosen_card:
			player_cards.erase(chosen_card)
			chosen_card.queue_free()
			chosen_card = null
		check_fin_de_tour()
