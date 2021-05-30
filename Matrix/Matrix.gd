extends Node

class_name Matrix

var rows:int = 0
var columns:int = 0
var data:PoolRealArray

func init(r:int, c:int, value:float):
	self.rows = r
	self.columns = c
	for i in range(r):
		for j in range(c):
			data.append(value)

func zeros(r:int, c:int):
	self.init(r, c, 0)

func ones(r:int, c:int):
	self.init(r, c, 1)

func unary_op(fn):
	for i in range(len(self.data)):
		self.data[i] = fn.call_func(i, self.data[i])
	# Store a function reference.
	#var my_func = funcref(my_node, "my_function")
	# Call stored function reference.
	#my_func.call_func(args)

