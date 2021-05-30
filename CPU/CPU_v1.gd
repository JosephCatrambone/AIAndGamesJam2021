
extends Node2D

# CPU v1
# 256 bytes of memory.
# 1 pc.
# ADD/SUB/MUL/DIV/MOD/AND/OR/XOR/NOT arithmetic.
# JE, JGT, SPC logic.

# CPU internals.
var pause_execution:bool = false;
export(int) var clock_frequency:int = 10; # Higher = more instructions per cycle.
export(String, MULTILINE) var source_code = "";
export(String, MULTILINE) var recovery_firmware = ""; # We can always reset to this value. 
var memory = null;
var pc:int = 0;
var remaining_cycles:int = 0;

const DEREF_MARKER= '*';
# VTable
const NOP=0x00;
const ADD=0x10;
const SUB=0x20;
const MUL=0x30;
const DIV=0x40;
const MOD=0x50;
const AND=0x60;
const OR =0x70;
const XOR=0x80;
const NOT=0x90;

#const MOV=0xA0;
const JE=0xA0;
const JG=0xB0;
const SPC=0xC0;

#const INSTRUCTION_TABLE = StringArray(["NOP", "ADD", "SUB", "MUL", "DIV", "MOD", "AND", "OR", "XOR", "NOT", "MOV", "JE", "JG"]);
const OPERAND_COUNT = {
	NOP: 0,
	ADD: 3, SUB: 3, MUL: 3, DIV: 3, MOD: 3,
	AND: 3, OR: 3, XOR: 3, NOT: 2,
	JE: 3, JG: 3, SPC: 1
}
const INSTRUCTION_MAP = {
	"NOP":NOP, 
	"ADD":ADD, "SUB":SUB, "MUL":MUL, "DIV":DIV, "MOD":MOD,
	"AND":AND, "OR" :OR,  "XOR":XOR, "NOT":NOT,
	"JE" :JE,  "JG" :JG, 
	"SPC":SPC
}

const LEFT_DEREFERENCE_FLAG =0x08;
const RIGHT_DEREFERENCE_FLAG=0x04;
const TARGET_DEREFERENCE_FLAG =0x02;
const UNUSED=0x01;

# Begin:
func _ready():
	# Initialize device memory.
	self.memory = PoolByteArray();
	self.memory.resize(256);
	# Initialize registers and PC.
	self.pc = 0;
	# Reset our source and compile it.
	self.reset_source();
	self.compile_source();
	
func reset_source():
	self.source_code = self.recovery_firmware + "\n"; # Add an empty string to avoid assignment by mistake.

func compile_source(verbose=true):
	"""Compiles the source_code variable and sets the memory of the device.  Returns a toast-message for the user."""
	# TODO: Add !reserve <addr> to advance the token if it's in the reserved space.
	# TODO: Figure out a better trick than chaking for an empty space after a token.
	var response = ""
	var rewritten_source = self.source_code.to_upper()
	# Build up our rewrite rules:
	var rewrite_rules = Dictionary()
	rewrite_rules["MOV"] = "OR 0x00"
	rewrite_rules["JMP"] = "JE 0x00 0x00"
	# Disable preprocessor rewrite for now.
	response += "REWRITE RULES:\n"
	for line in rewritten_source.split("\n", false):
		if line.begins_with("!DEF"):
			var rule = line.split(" ", false, 2) # Split into three pieces on space. #DEF rulename rest of the sentence.
			response += "RULE: "+ str(rule) + "\n"
			rewrite_rules[rule[1]] = rule[2]
	response += "\n"
	# We need to worry about two special identifiers: * for deref and : for labels.
	var token_stream = PoolStringArray();
	for line in rewritten_source.split("\n", false): # Split on newlines so we can ignore line-comments.
		# TODO: Make a token -> line map for debugging.
		if line.begins_with("!DEF"):
			continue
		# Remove comments.
		var semicolon_position = line.find(";");
		if semicolon_position != -1:
			line = line.left(semicolon_position);
		# Convert commas into spaces and split on spaces.
		line = line.replace(",", " ");
		line = line.replace("\t", " ");
		# Handle rewrites from !DEF
		var line_rewrite = PoolStringArray([])
		for token in line.split(" ", false):
			# Handle variations on REF and *REF
			if token in rewrite_rules:
				line_rewrite.append(rewrite_rules[token])
			elif token.begins_with("*") and token.substr(1) in rewrite_rules:
				line_rewrite.append("*" + rewrite_rules[token.substr(1)])
			else:
				line_rewrite.append(token)
		line = line_rewrite.join(" ")
		# Split the line and add each replaced token into the stream.
		for token in line.split(" ", false):
			token_stream.append(token)
	# Log the token stream.
	response += "TOKEN STREAM:\n"
	for token in token_stream:
		response += token + " "
	response += "\n"
	# Now that we've got a token stream, we need to emit an instruction for each token.
	# Clear the memory of the target.
	for i in range(self.memory.size()):
		self.memory[i] = 0x00;
	# Set up our memory address lookup map.
	var address_lookup_map = {}
	var current_token_index = 0;
	var current_instruction_index = 0;
	while current_token_index < token_stream.size():
		# TODO: Seek through the entire stream and get token positions so we can reference stuff in the future.
		var active_token = token_stream[current_token_index]
		if active_token.ends_with(":"):
			address_lookup_map[active_token.replace(":", "")] = current_instruction_index;
		else:
			current_instruction_index += 1;
		current_token_index += 1;
	# Log the lookup table.
	response += "LOOKUP TABLE: \n"
	for lookup_name in address_lookup_map.keys():
		response += lookup_name + " -> " + str(address_lookup_map[lookup_name]) + "\n"
	response += "\n"
	# Iterate over tokens again and convert them to instructions.
	current_instruction_index = 0;
	current_token_index = 0; # Reset this.
	while current_token_index < token_stream.size():
		# Decode the instruction.
		# If this token ends in a ':', it's a label.  Ignore it, since we've captured it above.
		if token_stream[current_token_index].ends_with(":"):
			current_token_index += 1;
			continue;
		# Allow literal tokens if you're a boss.
		if token_stream[current_token_index].to_lower().begins_with("0x"):
			self.memory[current_instruction_index] = parse_numerical_token(token_stream[current_token_index])
			current_token_index += 1;
			current_instruction_index += 1;
			continue;
		# Now it's either an instruction or a reference to a label.
		var uncompiled_instruction = token_stream[current_token_index]
		if not INSTRUCTION_MAP.has(uncompiled_instruction):
			var problem = "Unrecognized instruction " + uncompiled_instruction + " | Token " + str(current_token_index);
			if not verbose:
				return problem
			else:
				response += problem
				return response
		var instruction = INSTRUCTION_MAP[uncompiled_instruction];
		self.memory[current_instruction_index] = instruction
		current_token_index += 1;
		for i in range(1, 1+OPERAND_COUNT[instruction]):
			if current_token_index >= len(token_stream):
				var problem = "ERROR: Operator count mismatch while processing instruction " + str(current_token_index) + ": " + str(instruction)
				if not verbose:
					return problem
				else:
					response += problem
					return response
			# TODO: Deref isn't reading right.  Address is always zero.
			if token_stream[current_token_index].substr(0,1) == DEREF_MARKER:
				# Strip the '*' marker in the token stream and make this operator take a pointer.
				token_stream[current_token_index] = token_stream[current_token_index].replace(DEREF_MARKER, '');
				if i == 1: # Left operator.
					self.memory[current_instruction_index] |= LEFT_DEREFERENCE_FLAG;
				elif i == 2:
					self.memory[current_instruction_index] |= RIGHT_DEREFERENCE_FLAG;
				elif i == 3:
					self.memory[current_instruction_index] |= TARGET_DEREFERENCE_FLAG;
			# If this is an identifier we know, set the memory address.
			if address_lookup_map.has(token_stream[current_token_index].to_upper()):
				self.memory[current_instruction_index+i] = address_lookup_map[token_stream[current_token_index].to_upper()];
			else: # Otherwise, perhaps this is an integer literal.
				self.memory[current_instruction_index+i] = parse_numerical_token(token_stream[current_token_index]);
			# TODO: If none of these apply and it's not a number, raise some exception.
			current_token_index += 1;
		current_instruction_index += 4;
	self.pc = 0;
	if not verbose:
		return "None.  Compile succeeded.";
	else:
		return response + "\nNo compilation errors."

func parse_numerical_token(token):
	if token.to_lower().substr(0,2) == "0x":
		return token.to_lower().hex_to_int();
	else:
		return int(token);

func step():
	var instruction_byte = self.memory[self.pc];
	var left_operand = self.memory[(self.pc+1)%self.memory.size()];
	var right_operand = self.memory[(self.pc+2)%self.memory.size()];
	var target_operand = self.memory[(self.pc+3)%self.memory.size()];
	# Decode instruction.
	var operator = instruction_byte & 0xF0;
	var left_operand_is_reference = bool(instruction_byte & LEFT_DEREFERENCE_FLAG);
	var right_operand_is_reference = bool(instruction_byte & RIGHT_DEREFERENCE_FLAG);
	var target_operand_is_reference = bool(instruction_byte & TARGET_DEREFERENCE_FLAG);
	# Advance the PC.
	self.pc += 4;
	self.pc %= self.memory.size();
	# Fetch the data we need by dereferencing.
	var left = left_operand;
	var right = right_operand;
	var target = target_operand;
	if left_operand_is_reference:
		left = self.memory[left];
	if right_operand_is_reference:
		right = self.memory[right];
	if target_operand_is_reference:
		target = self.memory[target];
	# Execute the instruction.
	if operator == NOP:
		return;
	elif operator == JE:
		if left == right:
			self.pc = target;
	elif operator == JG:
		if left > right:
			self.pc = target;
	elif operator == SPC:
		self.memory[target] = pc
	# Arithmetic operators.
	if operator == ADD: # r <- a+b
		self.memory[target] = left+right
	elif operator == SUB:
		self.memory[target] = left-right;
	elif operator == MUL:
		self.memory[target] = left*right;
	elif operator == DIV:
		if right == 0:
			self.memory[target] = 0xFF
		else:
			self.memory[target] = left/right;
	elif operator == AND:
		self.memory[target] = left & right;
	elif operator == OR:
		self.memory[target] = left | right;
	elif operator == XOR:
		self.memory[target] = left ^ right;
	elif operator == NOT:
		self.memory[right] = ~left;
	elif operator == MOD:
		if right == 0:
			self.memory[target] = 0xFF;
		else:
			self.memory[target] = left%right;
	# Handle overflow/underflow.
	#if self.memory[target] > 0xFF || self.register < 0:
	#self.overflow_flag = true;
	#self.register &= 0xFF;

func _process(delta):
	if not self.pause_execution:
		while self.remaining_cycles > 0:
			self.step();
			self.remaining_cycles -= 1;
		self.remaining_cycles = self.clock_frequency;
