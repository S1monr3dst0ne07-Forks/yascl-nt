

use "lib/chunk.yap"
use "lib/str.yap"

bind WriteFile     ~ "KERNEL32.DLL"
bind GetStdHandle  ~ "KERNEL32.DLL"

fn IO::GetStdin () { return GetStdHandle(0 - 10); }
fn IO::GetStdout() { return GetStdHandle(0 - 11); }
fn IO::GetStderr() { return GetStdHandle(0 - 12); }


fn IO::Write(handle, qstr, len)
{
    // syscall are slow anyways.
    put bstr = Chunk::New(len);
    Mem::ToBytes(bstr, qstr, len);
    WriteFile(handle, bstr, len, 0, 0);
    Chunk::Void(bstr);
}

fn IO::Print(str)
{
    put len = Str::Len(str);
    IO::Write(IO::GetStdout(), str, len);
}

fn IO::Error(str)
{
    put len = Str::Len(str);
    IO::Write(IO::GetStderr(), str, len);
}




