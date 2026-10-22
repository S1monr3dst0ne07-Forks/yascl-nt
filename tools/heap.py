
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


def read(path):
	fd = open('core', 'rb')
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

	return blocks


with open('core.json', 'w') as f:
	json.dump([
		block.render()
		for block in
		read('core')
	], f)

