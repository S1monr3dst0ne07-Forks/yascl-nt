

// debug functions don't have their own namespace.
// they should only be used during debugging because of this.

use "lib/str.yap"
use "lib/io.yap"

fn fprint(fd, pattern, args)
{
    static 16384 ~ buffer;
    Str::Format(buffer, pattern, args);
    IO::Write(
    	fd,
    	buffer,
    	Str::Len(buffer),
    );
}
fn print(pattern, args)
{
	fprint(IO::GetStdout(), pattern, args);
}
fn eprint(pattern, args)
{
	fprint(IO::GetStderr(), pattern, args);
}



use "lib/ht.yap"

fn dump_ht(path, pattern, ht)
{
    put handle = FS::Sys::Open(
    	path, 
        FS::Mode::WRONLY |
        FS::Mode::CREATE,
    );

    static 4096 ~ qbuffer;
    static 1024 ~ bbuffer;

    put it = HT::MakeIter(ht);
    lab loop;
        jump done ~ Bool::Not(HT::Next(it));

        Str::Format(qbuffer, pattern, [
            it.HT::Iter::KEY,
            it.HT::Iter::VALUE,
        ]);

        put char_count = Str::Len(qbuffer);
        Mem::ToBytes(bbuffer, qbuffer, char_count);

        WriteFile(
        	handle,
        	bbuffer,
        	char_count,
        	0, 0,
        );

        jump loop;
    lab done;

    CloseHandle(handle);
}


//fn dump_buffer(path, buffer, length)
//{
//    put fd = FS::Sys::Open(path, 
//        FS::Mode::WRONLY |
//        FS::Mode::CREATE |
//        FS::Mode::TRUNC
//    );
//
//    Sys::TryCall(
//        "dump_buffer",
//        SYSCALL::WRITE,
//        fd,
//        buffer,
//        length,
//    );
//
//    FS::Sys::Close(fd);
//}
//
