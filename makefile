.PHONY: stage0 stage1 run

test:
	./bootstrap.py prg/test.yap
	FASM.EXE build.asm test.exe

run: stage0

stage1: stage0 src/** lib/*
	./compiler src/main.yap yascl
	rm compiler

stage0: src/** lib/*
	./bootstrap.py src/main.yap
	fasm build.asm compiler
	chmod +x compiler
	rm build.asm

