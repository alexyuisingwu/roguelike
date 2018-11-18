
extends HButtonArray

# preload classes
onready var hud = get_node("../")
const slot = preload("slot.gd")
const attack = preload("attack.gd")

# member variables here
#var hud_helper = hud.new()
const NUM_SLOTS = 9
var slots_array = [1, null, null, null, null, null, null, null, null]


func _ready():
	# add buttons 1 through 5
	for i in range(1, NUM_SLOTS + 1):
		if i == 1:
			add_button("[" + str(i) + "] Attack")
		else:
			add_button("[" + str(i) + "] (Empty)")
	
	# anchor
	anchor()

func anchor():
	var top_offset = hud.get_offset(0.85).y
	var bottom_offset = hud.get_offset(0.03).y
	#var center_offset = hud_helper.get_offset(0.20).x
	var center_offset = hud.get_offset(0.15).x
	set_anchor_and_margin(MARGIN_TOP, ANCHOR_BEGIN, top_offset)
	set_anchor_and_margin(MARGIN_BOTTOM, ANCHOR_END, bottom_offset)
	#set_anchor_and_margin(MARGIN_LEFT, ANCHOR_CENTER, center_offset)
	#set_anchor_and_margin(MARGIN_LEFT, ANCHOR_BEGIN, center_offset)

# add a slot to the action bar
func add_slot(s):
	"""
	var size = slots_array.size()
	if (s extends slot):
		
		# add new slot to action bar
		if (size == 0):
			slots_array.append(s)
		elif (size < NUM_SLOTS):
			slots_array[size] = s
	
		# edit the slot label
		set_button_text(size, "[" + str(size + 1) + "] " + s.label)
	"""
	var pos = get_empty_slot_pos()
	if pos == null:
		return null
	else:
		slots_array[pos] = s
		return pos
	

func add_item(var item):
	var s = slot.new()
	s.init(item, item.name)
	print(slots_array)
	
	var pos = add_slot(s)
	
	if pos == null:
		return false
	else:
		#set_button_text(pos, "[" + str(pos + 1) + "] " + item.name)
		set_button_text(pos, "")
		set_button_icon(pos, item.texture)
		return true
	
func get_empty_slot_pos():
	for i in range(slots_array.size()):
		if slots_array[i] == null:
			return i
	return null

func use_slot(var number):
	var s = slots_array[number - 1]
	if s != null:
		var usesLeft = s.use()
		print("uses left = ", usesLeft)
		if usesLeft <= 0:
			clear_slot(number)

func clear_slot(var number):
	set_button_text(number - 1, "[" + str(number) + "] (Empty)")
	set_button_icon(number - 1, null)
	slots_array[number - 1] = null
	
func is_full():
	for s in slots_array:
		if s == null:
			return false
	return true