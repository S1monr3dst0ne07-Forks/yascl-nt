#!/usr/bin/python3

import sys, os
from dataclasses import dataclass as dc
from typing import Literal, Any

# 64-bit compiler
WORD_SIZE = 8

SPY_ADDR = None

def fresh_gen():
	i = 0
	while True:
		yield f"__fresh_{i}"
		i += 1

fresh = fresh_gen()
consts = {}
strings = {}
statics = {}
bindings = {}
extern_funcs = set()

def tokenize(path):
	with open(path) as f:
		src = f.read()

	def get(char):
		match char:
			case x if x.isalpha(): return 'iden'
			case '_': return 'iden'
			case ':': return 'iden'
			case x if x.isdigit(): return 'iden'
			case '{': return 'bo'
			case '}': return 'bc'
			case '(': return 'po'
			case ')': return 'pc'
			case '[': return 'ao'
			case ']': return 'ac'
			case ';': return 'eos'
			case '"': return 'quote'
			case "'": return 'single'
			case ' ' | '\t' | '\n': return 'format'
			case _: return 'symb'

	@dc
	class Token:
		content : str
		lineno : int
		path : str

	@dc
	class Streamer:
		toks : list[str]

		def peek(self, offset=0):
			return self.toks[offset].content
		def _pop(self):
			return self.toks.pop(0)
		def pop(self):
			return self._pop().content
		def has(self):
			return len(self.toks) > 0
		def expect(self, should):
			be = self._pop()
			if be.content != should:
				print(f"Error in `{be.path}` at line {be.lineno}: Expected `{should}` got `{be.content}`")
				sys.exit(1)

	toks = []
	buffer = ''
	string	= False
	comment = False
	literal = False
	state = None
	lineno = 1
	for char in src:
		kind = get(char)
		if char == '\n': lineno += 1


		if buffer == '//'	: comment = True
		if state  == 'quote': string = not string
		if state  == 'single': literal = not literal

		if (state != kind or state in ('bo', 'bc', 'po', 'pc')) and not string and not comment and not literal:
			if state not in (None, 'format'):
				toks.append(Token(buffer, lineno, path))
			buffer = ''

		if char == '\n' and comment: 
			buffer = ''
			comment = False
			literal = False
			string	= False

		buffer += char
		state = kind

	
	return Streamer(toks)

# shares ABI with linux system calls
ABI = ('rcx', 'rdx', 'r8', 'r9')


@dc
class AstLeaf:
	value : Any
	kind : Literal['lit', 'var', 'call', 'const', 'meta', 'string', 'array', 'char']

	@classmethod
	def parse(cls, stream):
		match stream.pop():
			case '(': #)
				expr = AstExpr.parse(stream)
				stream.expect(')')
				return expr
			case '[':
				elems = []
				while stream.peek() != ']':
					elems.append(AstExpr.parse(stream))
					if stream.peek() == ',': stream.pop()
				stream.expect(']')
				return cls(elems, 'array')
			case x if x.startswith("'"):
				char = x.strip("'")
				match char:
					case '\\n': char = '\n'
					case '\\r': char = '\r'
					case '\\t': char = '\t'
					case '\\0': char = '\0'
					case '\\\\': char = '\\'
				return cls(char, 'char')

			case name if stream.peek() == '(': #)
				stream.pop()
				params = []
				while stream.peek() != ')':
					params.append(AstExpr.parse(stream))
					if stream.peek() == ',': stream.pop()
				stream.expect(')')
				return cls((name, params), 'call')

			case string if '"' in string: return cls(string.strip('"'), 'string')
			case number if number.isdigit(): return cls(number, 'lit')
			case x: return cls(x, 'meta') #resolve during compile

	def _resolve(self, scope, store=False):
		if self.kind != 'meta': return

		if self.value in consts: self.kind = 'const'
		else                   : self.kind = 'var'

	def eval(self, scope):
		self._resolve(scope)
		match self.kind:
			case 'lit':	  return self.value
			case 'char':  return ord(self.value)
			case 'const': return consts[self.value]

			case x:
				print(f"Unsupported compiler-time leaf: `{self.value}`")
				exit(1)

	def collect(self, scope):
		self._resolve(scope)
		if self.kind == 'var':
			scope.alloc(self.value)
			return 1
		return 0

	def load(self, emit, scope): #load into rax
		self._resolve(scope)
		match self.kind:
			case 'lit':	  emit(f'mov rax, {self.value}')
			case 'char':  emit(f'mov rax, {ord(self.value)}')
			case 'const': emit(f'mov rax, {consts[self.value]}')
			case 'var':	  emit(f'mov rax, [rbp - {scope[self.value]}]')
			case 'call':
				name, params = self.value

				quick_params  = params[:4]
				stack_params = params[4:]

				# save base pointer 
				emit("push rbp")
				emit("sub rsp, 8") # alignment placeholder

				space_raw   = 0x20 + 8 * len(stack_params)
				space_align = (space_raw + 15) & ~15
				emit(f"sub rsp, {space_align}")

				# load stack parameters
				for i, param in enumerate(stack_params):
					param.load(emit, scope)
					addr = 32 + i * 8
					emit(f"mov [rsp+{addr}], rax")

				# load quick register parameters
				#  the effect of this on stack alignment can be ignored.
				regs = ABI[:len(quick_params)]
				for param in quick_params:
					param.load(emit, scope)
					emit('push rax')
				for reg in regs[::-1]:
					emit(f"pop {reg}")

				# set new base pointer
				#  this has to happen after loading the parameters
				#  to allow them to access the local variables.
				emit(f"lea rbp, [rsp+{space_align}]")

				label = name.replace(':', '_')
				if name in extern_funcs: emit(f"call [{label}]")
				else:					 emit(f"call {label}")

				# remove caller stack
				emit("mov rsp, rbp")
				emit("add rsp, 8") # alignment placeholder
				emit("pop rbp")

			case 'string':
				label = next(fresh)
				strings[label] = self.value
				emit(f'mov rax, {label}')

			case 'array':
				name = next(fresh)
				statics[name] = len(self.value)
				for vaddr, expr in enumerate(self.value):
					addr = vaddr * WORD_SIZE
					expr.load(emit, scope)
					emit(f'mov [{name} + {addr}], rax')
				emit(f'mov rax, {name}')



	def store(self, emit, scope): #store from rax
		self._resolve(scope, store=True)
		if self.kind != 'var':
			print("Error: Trying to store into non-variable value")
			sys.exit(1)

		scope.alloc(self.value)
		emit(f'mov [rbp - {scope[self.value]}], rax')

		




OPS = (
	'+', '-', '.', ':', '==', '!=', '<', '>', '*', '/', '&', '|', '^', '<<', '>>', '%',
	'~+', '~-','~*','~/', '~<', '~>', '~%',
)

@dc
class AstExpr:
	left  : "AstExpr | AstLeaf"
	right : "AstExpr | AstLeaf"
	op	  : str

	debug_src_token : ""

	@classmethod
	def parse(cls, stream):
		left = AstLeaf.parse(stream)

		if stream.peek() not in OPS:
			return left

		op = stream._pop()
		right = AstExpr.parse(stream)
		return cls(left, right, op.content, op)

	def collect(self, scope):
		return 0

	def load(self, emit, scope):
		self.right.load(emit, scope)
		emit('push rax')
		self.left.load(emit, scope)
		emit('pop rbx')

		match self.op:
			case '+': emit('add rax, rbx')
			case '-': emit('sub rax, rbx')
			case '.':
				emit(f"mov rax, [rax + rbx*{WORD_SIZE}]")
			case ':':
				emit(f"lea rax, [rax + rbx*{WORD_SIZE}]")
			case '==' | '!=' | '<' | '>':
				emit('cmp rax, rbx')
				match self.op:
					case '==': emit('sete cl')
					case '!=': emit('setne cl')
					case '>':  emit("seta cl")
					case '<':  emit("setb cl")
				emit('movzx rax, cl')
			case '*': emit('mul rbx')
			case '/':
				emit('xor rdx, rdx')
				emit('div rbx')
			case '%':
				emit('xor rdx, rdx')
				emit('div rbx')
				emit('mov rax, rdx')
			case '&': emit('and rax, rbx')
			case '|': emit('or	rax, rbx')
			case '^': emit('xor rax, rbx')
			case '>>': 
				emit('mov rcx, rbx')
				emit('shr rax, cl')
			case '<<': 
				emit('mov rcx, rbx')
				emit('shl rax, cl')

	def store(self, emit, scope):
		if self.op != '.':
			print("Error: Non-dot-operator lvalue")
			sys.exit(1)

		emit('push rax')
		self.right.load(emit, scope)
		emit('push rax')
		self.left.load(emit, scope)
		emit('pop rbx')
		emit(f"lea rbx, [rbx*{WORD_SIZE}]")
		emit("add rax, rbx")


		if SPY_ADDR:
			skip = next(fresh)
			msg	 = next(fresh)
			message = str(self.debug_src_token) + '\n'
			strings[msg] = message

			emit(f'cmp rax, {SPY_ADDR}')
			emit(f'jne {skip}')
			emit("push rax")

			emit(f"mov rax, 1")
			emit(f"mov rsi, {msg}")
			emit(f"mov rdi, 1")
			emit(f"mov rdx, {len(message)*8}")
			emit("syscall")

			emit("pop rax")
			emit(f'{skip}:')

		emit('pop rbx')
		emit("mov [rax], rbx")






@dc
class AstPut:
	dst : AstExpr
	src : AstExpr

	@classmethod
	def parse(cls, stream):
		stream.expect('put')
		dst = AstExpr.parse(stream)
		stream.expect('=')
		src = AstExpr.parse(stream)
		stream.expect(';')
		return cls(dst, src)

	def compile(self, emit, scope):
		self.src.load(emit, scope)
		self.dst.store(emit, scope)

	def collect(self, scope):
		return self.dst.collect(scope)

@dc
class AstReturn:
	value : AstExpr

	def collect(self, scope):
		return 0

	@classmethod
	def parse(cls, stream):
		stream.expect('return')
		value = AstExpr.parse(stream)
		stream.expect(';')
		return cls(value)

	def compile(self, emit, scope):
		self.value.load(emit, scope)
		emit('ret')

@dc
class AstLabel:
	name : str

	@classmethod
	def parse(cls, stream):
		stream.expect('lab')
		name = stream.pop()
		stream.expect(';')
		return cls(name)

	def compile(self, emit, scope):
		emit(scope.render_label(self.name) + ':')

	def collect(self, scope):
		return 0

@dc
class AstJump:
	target : str
	cond   : "AstExpr | None"

	def collect(self, scope):
		return 0

	@classmethod
	def parse(cls, stream):
		stream.expect('jump')
		target = stream.pop()
		cond = None

		if stream.peek() == '~':
			stream.pop()
			cond = AstExpr.parse(stream)

		stream.expect(';')
		return cls(target, cond)

	def compile(self, emit, scope):
		label = scope.render_label(self.target)
		if self.cond is not None:
			self.cond.load(emit, scope)
			emit("cmp rax, 0")
			emit(f"jne {label}")
		else:
			emit(f"jmp {label}")

@dc
class AstInplace:
	expr : AstExpr

	def collect(self, scope):
		return 0

	@classmethod
	def parse(cls, stream):
		expr = AstExpr.parse(stream)
		stream.expect(';')
		return cls(expr)

	def compile(self, emit, scope):
		self.expr.load(emit, scope)

@dc
class AstStatic:
	words : AstExpr
	expr : AstExpr

	def collect(self, scope):
		return 0

	@classmethod
	def parse(cls, stream):
		stream.expect('static')
		words = AstExpr.parse(stream)
		stream.expect('~')
		expr = AstExpr.parse(stream)
		stream.expect(';')
		return cls(words, expr)

	def compile(self, emit, scope):
		name = next(fresh)
		statics[name] = self.words.eval(scope)
		emit(f'mov rax, {name}')
		self.expr.store(emit, scope)


@dc
class AstBlock:
	nodes : list

	@staticmethod
	def node(stream):
		match stream.peek():
			case 'put': return AstPut.parse(stream)
			case 'return': return AstReturn.parse(stream)
			case 'lab': return AstLabel.parse(stream)
			case 'jump': return AstJump.parse(stream)
			case 'static': return AstStatic.parse(stream)

		return AstInplace.parse(stream)

	@classmethod
	def parse(cls, stream):
		stream.expect('{') #}

		nodes = []
		while stream.peek() != '}':
			nodes.append(cls.node(stream))

		stream.expect('}')
		return cls(nodes)

	def compile(self, emit, scope):
		for node in self.nodes:
			node.compile(emit, scope)

	def collect(self, scope):
		return sum(
			node.collect(scope)
			for node in self.nodes
		)


@dc
class AstFnDef:
	name   : str
	params : list[str]
	body   : AstBlock

	@classmethod
	def parse(cls, stream):
		stream.expect('fn')
		name = stream.pop()
		stream.expect('(') #)
		
		params = []
		while stream.peek() != ')':
			params.append(stream.pop())
			if stream.peek() == ',':
				stream.pop()

		stream.expect(')')
		body = AstBlock.parse(stream)
		return cls(name, params, body)

	@dc
	class _LocalScope:
		fn_name : str
		vars : dict[str, int] #variable name to address
		allocer : int = 0

		def alloc(self, name):
			if name in self.vars: return

			self.allocer += 1
			self.vars[name] = self.allocer * WORD_SIZE

		def __getitem__(self, name):
			return self.vars[name]

		def __contains__(self, name):
			return name in self.vars

		def render_label(self, name):
			return f"__local_{self.fn_name}_{name}"

	def collect(self, scope):
		return self.body.collect(scope)

	def compile(self, emit):
		label = self.name.replace(':', '_')
		scope = self._LocalScope(label, {})
		emit(f"{label}:")

		quick_params = self.params[:4]
		stack_params = self.params[4:]

		# this code right here is very tricky.
		# the windows calling conventions make it
		# so that caller allocates the stack space
		# for parameters. meaning we can use that.
		# but the non-paramter local (i have called them
		# "real" locals here) need to have additional
		# space reserved. this also means that the order
		# of local allocation is very very important!

		# fill out caller parameter stack
		for param in stack_params:
			scope.alloc(param)
		
		# allocate and fill out shadow stack space
		regs = ABI[:len(quick_params)]
		for param, reg in zip(quick_params, regs):
			scope.alloc(param)
			emit(f'mov [rbp - {scope[param]}], {reg}')

		# make sure shadow space is fully accounted for
		scope.allocer += 4 - len(quick_params)

		# return address
		# don't touch me in my special stack slot!
		scope.alloc("__return_addr_dont_touch")
		
		# collect and allocate "real" locals
		n_real_local = self.collect(scope)
		local_space = n_real_local * 8

		emit(f"sub rsp, {local_space}")
		self.body.compile(emit, scope)
		emit(f"add rsp, {local_space}")

		emit("xor rax, rax") # return null by default
		emit("ret")

# prevent redundant uses
using = set()

@dc
class AstProg:
	fns : list[AstFnDef]

	@staticmethod
	def parse_seq(stream):
		stream.expect('seq')
		name = stream.pop()
		stream.expect('{') #}
		i = 0
		while stream.peek() != '}':
			field = stream.pop()
			if stream.peek() == '=':
				stream.expect('=')
				i = int(stream.pop())
			consts[name + "::" + field] = i
			i += 1
			if stream.peek() == ',': stream.pop()
		consts[name] = i #length of sequence
		stream.expect('}')

	@staticmethod
	def parse_bind(stream):
		stream.expect('bind')
		name = stream.pop()
		stream.expect('~')
		library = stream.pop()

		if library not in bindings:
			bindings[library] = []

		bindings[library].append(name)
		extern_funcs.add(name)

	@classmethod
	def parse(cls, stream):
		fns = []
		while stream.has():
			match stream.peek():
				case 'fn': fns.append(AstFnDef.parse(stream))
				case 'seq': cls.parse_seq(stream)
				case 'bind': cls.parse_bind(stream)
				case 'use':
					stream.expect('use')
					path = stream.pop().strip('"')

					if path not in using:
						using.add(path)
						print(f'using: {path}')
						fns += AstProg.file(path).fns
					
				case x: 
					print(f"Error: Invalid toplevel prefix: {x}")
					sys.exit(1)

		return cls(fns)

	@staticmethod
	def file(path):
		return AstProg.parse(tokenize(path))

	def compile(self, emit):
		for fn in self.fns:
			fn.compile(emit)


def runtime(emit):
	# headers
	emit('format PE64 console')
	emit('entry start')
	emit("section '.text' code readable executable")

	emit("start:")

	# setup calling stack frame
	#  system calls with alignment +8 for the returns address.
	#  we push rbp, so 8+8 = 16 which makes the alignment match again.
	emit("push rbp")
	emit("mov  rbp, rsp")
	emit("sub  rsp,  32") # 32 % 16 = 0

	# call into main
	emit("call main")

	# restore
	emit("mov rsp, rbp")
	emit("pop rbp")

	emit("ret")

def finalize(emit):
	emit("section '.data' writeable readable")
	emit("placeholder db 0")

	#emit strings
	for label, string in strings.items():
		string = string.encode('utf-8').decode('unicode_escape')
		emit(f"{label}:")
		for char in string:
			emit(f"\tdq {ord(char)}")
		emit("\tdq 0")

	#emit static buffers
	for label, words in statics.items():
		emit(f"{label}: rq {words}")

	# emit import tables
	emit("section '.idata' import data readable writeable")
	lib_names  = {}
	lib_tables = {}
	for library, procs in bindings.items():
		lib_label = next(fresh)
		lib_table = next(fresh)

		lib_names [lib_label] = library
		lib_tables[lib_table] = procs
		emit(f"dd 0,0,0,RVA {lib_label},RVA {lib_table}")
	emit("dd 0,0,0,0,0")

	# emit library dll names
	for label, name in lib_names.items():
		emit(f"{label} db {name}, 0")

	# emit procedure tables
	all_procs = []
	for label, procs in lib_tables.items():
		emit(f"{label}:")

		for proc in procs:
			all_procs.append(proc)
			emit(f"\t{proc} dq RVA __name_{proc}")
		emit("dq 0")

	# emit procedure names
	for proc in all_procs:
		emit(f"__name_{proc} db 0,0,'{proc}',0")

		


def main():
	root = AstProg.file(sys.argv[1])

	asm = []
	emitter = lambda x: asm.append(x)
	runtime(emitter)
	root.compile(emitter)
	finalize(emitter)

	with open('build.asm', 'w') as f:
		f.write('\n'.join(asm))




if __name__ == '__main__':
	main()
