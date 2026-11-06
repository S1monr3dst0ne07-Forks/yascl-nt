
.ONESHELL:

WINE8  := WINEPREFIX=/var/.wine8  /usr/lib/wine/wine
WINE11 := WINEPREFIX=/var/.wine11 /opt/wine-stable/bin/wine

debug: build
	$(WINE11) Z:/usr/share/win64/gdbserver.exe localhost:12345 BUILD.EXE &
	echo $$! > /tmp/gdb_server.pid
	x86_64-w64-mingw32-gdb YASCL.EXE \
		-ex "target extended-remote localhost:12345" \
		-ex "set disassembly-flavor intel" \
		-ex "source gdb.py" -ex "c"
	kill $$(cat /tmp/gdb_server.pid)
	

run: build
	$(WINE8) yascl prg/win-test.yap
	$(WINE11) build

	#$(WINE8) yascl prg/mandel-color.yap
	#$(WINE11) build


build:
	$(WINE8) boot src/main.yap
	mv BUILD.EXE YASCL.EXE


