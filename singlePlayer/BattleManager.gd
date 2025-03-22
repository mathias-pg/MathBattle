extends Node

# Définition des tours
enum Turn { PLAYER, BOT }
var current_turn: Turn = Turn.PLAYER

# Timer pour gérer l'attente du bot
@onready var battle_timer = $BattleTimer

# On récupère tous les noeuds dont on a besoin dans la scène
@onready var label_tour = $"../LabelTour"             
@onready var target_score_label = $"../LabelScore"      
@onready var player_hand = $"../PlayerHand"            
@onready var enemy_hand = $"../EnnemyHand"             
@onready var player_slot = $"../CardSlotPlayer"        
@onready var enemy_slot = $"../CardSlotOtherPlayer"     
@onready var player_deck = $"../Deck"                  
@onready var enemy_deck = $"../OpponentDeck"           

# Score cible
var target_score: int = 0

func _ready():
	# Configuration du Timer
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	
	# Génère le score cible entre 80 et 150
	randomize()
	target_score = randi() % (150 - 80 + 1) + 80
	target_score_label.text = "Score à atteindre : " + str(target_score)
	
	# Remplit les mains si elles contiennent moins de 5 cartes
	fill_hand_if_needed()
	
	# Démarre le tour du joueur
	start_player_turn()

# Remplit la main de chaque côté jusqu'à 5 cartes
func fill_hand_if_needed():
	while player_hand.player_hand.size() < 5:
		player_deck.draw_card()
	while enemy_hand.player_hand.size() < 5:
		enemy_deck.draw_card()

# -----------------------
#      Tour du joueur
# -----------------------

func start_player_turn():
	current_turn = Turn.PLAYER
	label_tour.text = "Tour du joueur"
	set_player_cards_interaction(true)
	# Le joueur joue. À la fin de son action, on doit appeler end_player_turn() 
	# (depuis le script CardSlot.gd ou autre, après le calcul).

func end_player_turn():
	# Vérifie la victoire du joueur
	if check_win(player_slot):
		game_over("Joueur")
		return
	# Sinon, passe au bot
	fill_hand_if_needed()
	start_bot_turn()

# -----------------------
#      Tour du bot
# -----------------------

func start_bot_turn():
	current_turn = Turn.BOT
	label_tour.text = "Tour du bot"
	set_player_cards_interaction(false)
	fill_hand_if_needed()
	
	# Appelle la fonction du bot (il tire une carte et attend 1 seconde)
	await opponent_turn()
	
	# Le bot choisit ensuite une carte et la joue
	var move = choose_bot_move()
	if move:
		var chosen_card = move.card
		var target_slot = move.slot
		enemy_hand.remove_card_from_hand(chosen_card)
		play_bot_card(chosen_card, target_slot)
		
		# Laisse la carte posée pendant 1 seconde
		await get_tree().create_timer(1.0).timeout
		chosen_card.queue_free()
		
		# Vérifie la victoire du bot
		if check_win(enemy_slot):
			game_over("Bot")
			return
	
	# Retour au joueur
	start_player_turn()

# Cette fonction est réellement définie ICI,
# donc "opponent_turn()" existe bien dans CE script.
func opponent_turn() -> void:
	# Le bot pioche une carte
	enemy_deck.draw_card()
	# Lance le timer et attend son expiration
	battle_timer.start()
	await battle_timer.timeout
	# À la fin de cette attente, on revient dans start_bot_turn()

# -----------------------
#   (Dés)activation des cartes du joueur
# -----------------------

func set_player_cards_interaction(active: bool) -> void:
	for card in player_hand.player_hand:
		if card.has_node("Area2D/CollisionShape2D"):
			var collision_shape = card.get_node("Area2D/CollisionShape2D")
			collision_shape.disabled = not active

# -----------------------
#   IA du bot
# -----------------------

class BotMove:
	var card
	var slot
	func _init(card, slot):
		self.card = card
		self.slot = slot

func choose_bot_move() -> BotMove:
	var enemy_score = int(enemy_slot.label_score_reference.text)
	var player_score = int(player_slot.label_score_reference.text)
	var best_move: BotMove = null
	var best_diff = INF
	
	for card in enemy_hand.player_hand:
		# Option 1 : jouer sur sa propre table
		var new_enemy_score = apply_operation(enemy_score, card.card_sign, card.card_value)
		var diff_enemy = abs(new_enemy_score - target_score)
		# Option 2 : jouer sur la table adverse
		var new_player_score = apply_operation(player_score, card.card_sign, card.card_value)
		var diff_player = abs(new_player_score - target_score)
		
		# Si coup gagnant immédiat
		if new_enemy_score == target_score:
			return BotMove.new(card, enemy_slot)
		
		# Choisit le coup qui rapproche le bot du score cible
		if diff_enemy < abs(enemy_score - target_score) and diff_enemy < best_diff:
			best_diff = diff_enemy
			best_move = BotMove.new(card, enemy_slot)
		# Sinon, essaie d'éloigner le joueur
		elif diff_player > abs(player_score - target_score):
			var delta = diff_player - abs(player_score - target_score)
			if delta > best_diff:
				best_diff = delta
				best_move = BotMove.new(card, player_slot)
	
	# Si aucun coup intéressant, joue la première carte disponible
	if best_move == null and enemy_hand.player_hand.size() > 0:
		best_move = BotMove.new(enemy_hand.player_hand[0], enemy_slot)
	
	return best_move

func apply_operation(current: int, sign: String, value: int) -> int:
	match sign:
		"+":
			return current + value
		"-":
			return current - value
		"x":
			return current * value
		"÷":
			if value != 0:
				return int(current / value)
			else:
				return current
	return current

func play_bot_card(card, slot):
	var current_score = int(slot.label_score_reference.text)
	var new_score = apply_operation(current_score, card.card_sign, card.card_value)
	slot.label_score_reference.text = str(new_score)

# -----------------------
#   Vérification victoire
# -----------------------

func check_win(slot) -> bool:
	var score = int(slot.label_score_reference.text)
	return score == target_score

func game_over(winner: String):
	label_tour.text = winner + " a gagné !"
	set_player_cards_interaction(false)
	# Ajouter popup ou retour menu si souhaité
