extends CanvasLayer

onready var display = $UI
onready var error_display = $UI/ErrorDisplay
onready var main_panel = $UI/MainPanel
var target_cpu = null
onready var editor = $UI/MainPanel/Editor
onready var memory_viewer = $UI/MainPanel/MemoryViewer
onready var run_toggle_button:Button = $UI/HBoxContainer/RunToggle

func _ready():
	# Register with global.
	#main_panel = get_node("MainPanel");
	#editor = get_node("MainPanel/Editor");
	#memory_viewer = get_node("MainPanel/MemoryViewer");
	self.display.hide()
	self.set_process_input(true)
	Globals.terminal_ref = self

func attach_to_cpu(cpu_target):
	self.set_process(true)
	self.target_cpu = cpu_target
	self.editor.set_text(self.target_cpu.source_code)
	self.display.show()
	#self.set_global_pos(global.player.get_pos() - self.get_size()/2);
	self.run_toggle_button.pressed = not self.target_cpu.pause_execution

func _process(delta):
	if is_active():
		self.update_memory_view();

func update_memory_view():
	self.memory_viewer.clear()
	self.memory_viewer.set_max_columns(16) # sqrt(256)
	self.memory_viewer.set_same_column_width(true)
	for i in self.target_cpu.memory:
		self.memory_viewer.add_item("%02x" % i)

func is_active():
	return self.target_cpu != null

func _input(event):
	if(event is InputEventKey): #Input.is_action_pressed("ui_cancel") or Input.is_key_pressed(KEY_ESCAPE):
		if event.scancode == KEY_ESCAPE and event.pressed == false:
			# When escape is hit the first time, close the error display.
			# If it's not visible, detach.
			if self.error_display.visible:
				self.error_display_close()
			else:
				self.detach()
		if event.scancode == KEY_ENTER and event.control and event.pressed == false: # On release...
			self.compile()

func error_display_close():
	self.error_display.hide()

func compile():
	self.target_cpu.source_code = self.editor.get_text()
	var result = self.target_cpu.compile_source()
	error_display.show()
	error_display.text = result

func run_toggle(state):
	self.target_cpu.pause_execution = not state

func step():
	self.target_cpu.step()

func reset():
	self.target_cpu.reset_source()
	self.editor.text = self.target_cpu.source_code
	self.target_cpu.compile_source()

func detach():
	self.set_process(false)
	self.target_cpu.pause_execution = false
	self.target_cpu = null
	self.display.hide()
