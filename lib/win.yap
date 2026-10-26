
use "lib/mem.yap"

bind ReadFile  ~ "KERNEL32.DLL"
bind WriteFile ~ "KERNEL32.DLL"

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




