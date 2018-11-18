extends Control

var label
var contents = null

func _init():
	pass

func init(var contents, var name):
	self.contents = contents
	self.label = name

func push():
	pass

func set_label(text):
	label = text

func use():
	return contents.use()
	
func is_empty():
	return contents == null