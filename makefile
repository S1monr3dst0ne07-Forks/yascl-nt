.PHONY: stage0 stage1 run

test:
	./bootstrap.py src/main.yap
	fasm build.asm test.exe
	wine test.exe prg/hello.yap | tee log
	grep "IR_ROOT" log | sed 's/IR_ROOT: //' | xargs python3 tools/ir.py 
	

run: stage0

stage1: stage0 src/** lib/*
	./compiler src/main.yap yascl
	rm compiler

stage0: src/** lib/*
	./bootstrap.py src/main.yap
	fasm build.asm compiler
	chmod +x compiler
	rm build.asm

