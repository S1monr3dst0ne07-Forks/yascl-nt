

WINE8  := WINEPREFIX=/var/.wine8  /usr/lib/wine/wine
WINE11 := WINEPREFIX=/var/.wine11 /opt/wine-stable/bin/wine

run:
	$(WINE11) yascl prg/win-test.yap
	#$(WINE11) build

build:
	$(WINE8) mkboot


