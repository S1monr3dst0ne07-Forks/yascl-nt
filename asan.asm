format ELF64


lea rax, [rsp-8]
test rax, 0xf
jz skip
int3
rb 128
skip:

