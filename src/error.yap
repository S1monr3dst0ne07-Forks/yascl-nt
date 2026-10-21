
use "lib/io.yap"

bind ExitProcess ~ "KERNEL32.DLL"

fn Error::Error(msg)
{
    IO::Error(msg);
    ExitProcess(1);
}


fn Error::PrintError(pattern, args)
{
    static 16384 ~ buffer1;
    static 16384 ~ buffer2;
    Str::Format(buffer1, pattern, args);
    Str::Format(buffer2, "Error: %s\n", [buffer1]);

    Error::Error(buffer2);
}

fn Error::LexError(info, pattern, args)
{
    static 16384 ~ buffer1;
    static 16384 ~ buffer2;
    Str::Format(buffer1, pattern, args);
    Str::Format(buffer2, "Error in `%s` at line %d: %s\n", [
        info.Lex::Info::PATH,
        info.Lex::Info::LINENO,
        buffer1,
    ]);

    Error::Error(buffer2);
}



