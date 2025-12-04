extends Control 

@export var max_hunger: float = 100.0 
@export var decrease_rate: float = 5.0 # fome que cai por segundo 
var current_hunger: float 
@onready var bar: ColorRect = $ColorRect 
@onready var label: Label = $Label 
signal hunger_zero 

func _ready(): 
	current_hunger = max_hunger 
	_update_bar() 
	_update_label() 
	
func _process(delta: float): 
	current_hunger = clamp(current_hunger - decrease_rate * delta, 0, max_hunger) 
	_update_bar() 
	_update_label() 
	if current_hunger <= 0:
		emit_signal("hunger_zero") 
	
# ============================================================
# Atualiza visualmente a barra 
# ============================================================ 
func _update_bar(): 
	var percent := current_hunger / max_hunger 
	bar.scale.x = percent # barra diminui proporcionalmente 
	
# ============================================================ 
# Atualiza o texto (percentual) 
# ============================================================ 
func _update_label(): 
	var percent := int((current_hunger / max_hunger) * 100) 
	label.text = "Fome: %d%%" % percent
	
# ============================================================ 
# Aumenta a fome ao pegar doces 
# ============================================================ 

func add_hunger(amount: float): 
	current_hunger = clamp(current_hunger + amount, 0, max_hunger) 
	_update_bar() 
	_update_label()
