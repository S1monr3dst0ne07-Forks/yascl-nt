
from dataclasses import dataclass as dc
import json


@dc
class Block:
	size : int
	addr : int
	data : list[int]

	def render(self):
		return {
			"size" : self.size,
			"addr" : self.addr,
			"data" : [int(x) for x in self.data],
		}

@dc
class Heap:
	blocks : list[Block]

	def lookup(self, addr):
		for block in self.blocks:
			if block.addr == addr:
				return block

		return None

	@classmethod
	def read(cls, path):
		fd = open(path, 'rb')
		blocks = []

		while True:
			size_bytes = fd.read(4)
			if size_bytes == b'': break

			size = int.from_bytes(size_bytes, 'little')
			addr = int.from_bytes(fd.read(8), 'little')

			blocks.append(Block(
				size, addr,
				fd.read(size)
			))

		return cls(blocks)


