


bind ExitProcess   ~ "KERNEL32.DLL"
bind WriteFile     ~ "KERNEL32.DLL"
bind GetStdHandle  ~ "KERNEL32.DLL"

//use "lib/mem.yap"

fn main()
{
	put qstr = "hello world\n";
    put count = 12;

	static 123 ~ bstr;
	//Mem::ToBytes(bstr, qstr, 12);

    put src = qstr;
    put dst = bstr;
    put i = 0;
    lab loop;
        put (dst+i).0 = (src.i) & 255;
        put i = i + 1;
    jump loop ~ i < count;

    put stdout = GetStdHandle(0 - 11);
    WriteFile(stdout, bstr, count, 0, 0);

    ExitProcess(0);
}



