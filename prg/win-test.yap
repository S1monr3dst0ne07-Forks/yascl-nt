
use "lib/mem.yap"
use "lib/debug.yap"
use "lib/win.yap"


fn WndProc(hwnd, msg, wp, lp)
{
    return DefWindowProcA(hwnd, msg, wp, lp);
}

fn str(q)
{
    put len = Str::Len(q);
    put b = Chunk::New(len);
    Mem::ToBytes(b, q, len);
    return b;
}

fn main()
{
    put instance = GetModuleHandleA(Mem::NULL);
    static Win::Class ~ wc;

    put (wc + Win::Class::lpfnWndProc)    .0 = @WndProc;
    put (wc + Win::Class::hInstance)      .0 = instance;
    put (wc + Win::Class::lpszClassName)  .0 = str("MAIN");
    
    RegisterClassA(wc);

    put handle = CreateWindowExA(
        0,
        str("MAIN"),
        str("My pretty window"),
        Win::Style::OVERLAPPED,
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


