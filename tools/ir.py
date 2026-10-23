
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

has_arg = (
	Op.ref,
	Op.load_int,
	Op.load_string,
	Op.load_static,
	Op.load_quick,
	Op.store_quick,
	Op.load_local,
	Op.store_local,
	Op.rsp_down,
	Op.rsp_up,
	Op.call,
	Op.jmp,
	Op.jnz,
	Op.float,
	Op.indirect_store,
	Op.offset_store,
)

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

def maybe_string_ptr(ptr):
	block = core.lookup(ptr)
	if block is None: return ptr

	return bytes(
		block.data[i*8] for i in 
		range(len(block.data) // 8)
	)


iter = read(head_addr)

program = ""
while True:
	if iter.next == 0: break
	iter = decode(iter.next)

	inst = iter.opcode.name.strip('_')
	arg  = maybe_string_ptr(iter.arg) if iter.opcode in has_arg else ""

	if iter.opcode == Op.ref: program += '\n'
	program += f"{inst.ljust(15)} {arg}\n"

print(program)

