

import gdb


inf = gdb.inferiors()[0]

def read_string(ptr):
	buffer = inf.read_memory(ptr, 128).tobytes()

	len = 0
	while buffer[len]:
		len += 1

	return buffer[:len].decode('ascii')


def read_name():
	rip  = int(gdb.parse_and_eval("$rip"))
	name = read_string(rip)

	print(name)



