
use "lib/mem.yap"
use "lib/debug.yap"
use "lib/win.yap"

bind SetPixel ~ "GDI32.DLL"

fn Paint(hwnd)
{
	static Win::Paint::Struct ~ ps;
	put hdc = BeginPaint(hwnd, ps);

	put i = 0;
	lab loop;
		put x =  i       & 255;
		put y = (i >> 8) & 255;
		
		SetPixel(hdc, x, y, Win::Paint::RGB(255, 0, 0));

		put i = i + 1;
	jump loop ~ i < 65535;

	EndPaint(hwnd, ps);
}



fn WndProc(hwnd, msg, wp, lp)
{
	jump destroy ~ msg == Win::MsgIden::DESTROY;
	jump paint   ~ msg == Win::MsgIden::PAINT;

	return DefWindowProcA(hwnd, msg, wp, lp);

lab destroy;
	PostQuitMessage(0);
	return 0;

lab paint;
	Paint(hwnd);
	return 0;
}

fn main()
{
    put instance = GetModuleHandleA(Mem::NULL);
    static Win::Class ~ wc;

    put (wc + Win::Class::lpfnWndProc)    .0 = @WndProc;
    put (wc + Win::Class::hInstance)      .0 = instance;
    put (wc + Win::Class::lpszClassName)  .0 = Win::Str("MAIN");
    
    RegisterClassA(wc);

    put handle = CreateWindowExA(
        0,
        Win::Str("MAIN"),
        Win::Str("My pretty window"),
        	Win::Style::OVERLAPPED |
		Win::Style::CAPTION |
		Win::Style::SYSMENU,
        Win::CreateWindow::USEDEFAULT,
        Win::CreateWindow::USEDEFAULT,
        640, 480, 
        Mem::NULL,
        Mem::NULL,
        instance,
        Mem::NULL,
    );
    
    ShowWindow(handle, Win::Show::SHOW);

    static Win::MsgObj ~ msg;
    lab loop;
        put res = GetMessageA(msg, Mem::NULL, 0, 0);
        jump done ~ res == 0;

        TranslateMessage(msg);
        DispatchMessageA(msg);
        jump loop;
    lab done;
}


