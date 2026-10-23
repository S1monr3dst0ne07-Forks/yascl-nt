

bind GetDC       ~ "USER32.DLL"
bind ReleaseDC   ~ "USER32.DLL"
bind ExitProcess ~ "KERNEL32.DLL"
bind SetPixel    ~ "GDI32.DLL"


fn main()
{
	put dc = GetDC(0);
	put red = 255;

	SetPixel(dc, 100, 100, red);
	ReleaseDC(0, dc);

	ExitProcess(0);
}


