
import json
import sys
from dataclasses import dataclass as dc
from enum import Enum, auto

from heap import Heap

head_addr = int(sys.argv[1])
core = Heap.read('core')

@dc
class Node:
	opcode : int 
	arg    : int
	addr   : int
	prev   : int
	next   : int

class Op(Enum):
	def _generate_next_value_(name, start, count, last_values):
		return count

	ref            = auto()

	load_int       = auto()
	load_string    = auto()
	load_static    = auto()

	push           = auto()
	pop            = auto()
	push_aux       = auto()
	pop_aux        = auto()

	push_rbp       = auto()
	pop_rbp        = auto()

	load_quick     = auto()
	store_quick    = auto()

	store_rsp      = auto()
	update_rbp     = auto()

	rsp_down       = auto()
	rsp_up         = auto()

	load_local     = auto()
	store_local    = auto()

	ret            = auto()
	call           = auto()
	jmp            = auto()
	jnz            = auto()

	call_dll       = auto()

	add            = auto()
	sub            = auto()
	dot            = auto()
	double_dot     = auto()
    
	equal          = auto()
	not_equal      = auto()
	lesser         = auto()
	greater        = auto()

	_mul           = auto()
	_div           = auto()
	_mod           = auto()
	_and           = auto()
	_or            = auto()
	_xor           = auto()
	_shr           = auto()
	_shl           = auto()

	float          = auto()

	indirect_store = auto()
	offset_store   = auto()

def read(addr):
	node = core.lookup(addr)
	data = node.data
	assert node.size // 8 == 5;

	def qword():
		nonlocal data
		value = int.from_bytes(data[:8], 'little')
		data = data[8:]
		return value

	return Node(
		opcode = qword(),
		arg    = qword(),
		addr   = qword(),
		prev   = qword(),
		next   = qword(),
	)

def decode(addr):
	node = read(addr)
	node.opcode = Op(node.opcode)
	return node

def opcode_has_generic_arg(code):
	return code in (
		Op.load_int,
		Op.load_string,
		Op.load_static,
		Op.load_quick,
		Op.store_quick,
		Op.load_local,
		Op.store_local,
		Op.rsp_down,
		Op.rsp_up,
		Op.jmp,
		Op.jnz,
		Op.float,
		Op.indirect_store,
		Op.offset_store,
	)

def render_arg(node):
	def qstr(node=node):
		data = core.lookup(node.arg).data
		return bytes(
			data[i] for i 
			in range(0, len(data), 8)
		).strip(b'\0').decode('ascii')

	def qint():
		return str(node.arg)

	def qref(): # pointer to node
		ref = decode(node.arg)
		assert ref.opcode == Op.ref
		return qstr(ref)

	match node.opcode:
		case Op.ref     : return qstr()
		case Op.call    : return qstr()
		case Op.call_dll: return qstr()
		case Op.load_string: return f'"{qstr()}"'

		case Op.jmp: return qref()
		case Op.jnz: return qref()

		case x if opcode_has_generic_arg(x):
			return qint()


print(head_addr)
iter = read(head_addr)

program = ""
while True:
	if iter.next == 0: break
	iter = decode(iter.next)

	inst   = iter.opcode.name.strip('_')
	arg    = render_arg(iter)
	indent = "  " if iter.opcode != Op.ref else ""

	if iter.opcode == Op.ref and '/' not in arg:
		program += '\n'
	
	program += f"{(indent+inst).ljust(15)} {arg if arg is not None else ''}\n"

with open("ir.txt", 'w') as f:
	f.write(program)

print(program)

