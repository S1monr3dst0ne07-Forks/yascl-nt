
import json
import sys
from dataclasses import dataclass as dc
from enum import Enum, auto

with open('core.json', 'r') as f:
	core = json.load(f)

head_addr = int(sys.argv[1])

def lookup(addr):
	for block in core:
		if block["addr"] == addr:
			return block

	print(f"address {addr} not found!")
	sys.exit(1)

@dc
class Node:
	opcode : int 
	arg    : int
	addr   : int
	prev   : int
	next   : int

class Op(Enum):
	ref         = auto()

	load_int    = auto()
	load_string = auto()
	load_static = auto()
	
	push        = auto()
	pop         = auto()
	push_aux    = auto()
	pop_aux     = auto()

	load_param  = auto()
	store_param = auto()

	load_local  = auto()
	store_local = auto()

	rsp_down    = auto()
	rsp_up      = auto()

	enter       = auto()
	leave       = auto()

	call        = auto()
	jmp         = auto()
	jnz         = auto()

	add         = auto()
	sub         = auto()
	dot         = auto()
	double_dot  = auto()

	equal       = auto()
	not_equal   = auto()
	lesser      = auto()
	greater     = auto()

	_mul        = auto()
	_div        = auto()
	_mod        = auto()
	_and        = auto()
	_or         = auto()
	_xor        = auto()
	_shr        = auto()
	_shl        = auto()

	float       = auto()

	indirect_store = auto()
	offset_store   = auto()

	syscall        = auto()

def qword(data):
	word = bytes(data.pop(0) for _ in range(8))
	return int.from_bytes(word, 'little')

def read(addr):
	node = lookup(addr)
	data = node["data"]
	assert node["size"] // 8 == 5;

	return Node(
		opcode = qword(data),
		arg    = qword(data),
		addr   = qword(data),
		prev   = qword(data),
		next   = qword(data),
	)

def decode(addr):
	node = read(addr)
	node.opcode = Op(node.opcode)
	return node

print('-' * 10)
root_addr = read(head_addr).next
iter = decode(root_addr)

print(iter)


