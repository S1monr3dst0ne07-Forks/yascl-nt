
use "lib/mem.yap"

bind ReadFile         ~ "KERNEL32.DLL"
bind WriteFile        ~ "KERNEL32.DLL"
bind GetModuleHandleA ~ "KERNEL32.DLL"
bind CreateWindowExA  ~ "USER32.DLL"
bind RegisterClassA   ~ "USER32.DLL"
bind DefWindowProcA   ~ "USER32.DLL"
bind ShowWindow       ~ "USER32.DLL"
bind GetMessageA      ~ "USER32.DLL"
bind TranslateMessage ~ "USER32.DLL"
bind DispatchMessageA ~ "USER32.DLL"


fn Win::ReadFile(handle, buffer, len)
{
    static 1 ~ nbytes;
    ReadFile(handle, buffer, len, nbytes, Mem::NULL);
    return nbytes.0;
}
fn Win::WriteFile(handle, buffer, len)
{
    static 1 ~ nbytes;
    WriteFile(handle, buffer, len, nbytes, Mem::NULL);
    return nbytes.0;
}





seq Win::Style
{
    OVERLAPPED = 0,
}
seq Win::CreateWindow
{
    USEDEFAULT = 2147483648,
}
seq Win::Show
{
    SHOW = 5,
}

seq Win::Class
{
    cbSize        =  0,
    style         =  4,
    lpfnWndProc   =  8,
    cbClsExtra    = 16,
    cbWndExtra    = 20,
    hInstance     = 24,
    hIcon         = 32,
    hCursor       = 40,
    hbrBackground = 48,
    lpszMenuName  = 56,
    lpszClassName = 64,
    hIconSm       = 72,
    __last        = 80,
}


seq Win::MsgObj
{
    hwnd     =  0,
    message  =  8,
    wParam   = 12,
    lParam   = 14,
    time     = 18,
    x        = 20,
    y        = 28,
    lPrivate = 36,
}


seq Win::MsgIden
{
    CREATE  = 1,
    DESTROY = 2,
}

