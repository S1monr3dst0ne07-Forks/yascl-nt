

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


//use "lib/fs.yap"
//use "lib/mem.yap"
//
//fn dump_heap(path)
//{
//    print("[DEBUG] heap dump in progress\n");
//    Chunk::Local::Init();
//    put primal = Chunk::PrimalPtr();
//
//    put prim_next = primal.Chunk::FB::NEXT;
//    jump primal_good ~ prim_next != primal;
//        print("[WARNING] heap empty. aborting dump.\n");
//        jump done;
//    lab primal_good;
//
//    put brk_start = primal.Chunk::FB::NEXT;
//    put brk_end   = syscall(SYSCALL::BRK, 0);
//    put heap_size = brk_end - brk_start;
//
//    print("[DEBUG] brk_start: %d\n", [brk_start]);
//    print("[DEBUG] brk_end  : %d\n", [brk_end]);
//    print("[DEUBG] heap_size: %d\n", [heap_size]);
//
//    
//    put fd = FS::Sys::Open(path, 
//        FS::Mode::WRONLY |
//        FS::Mode::CREATE |
//        FS::Mode::TRUNC
//    );
//    Sys::TryCall(
//        "dump_heap",
//        SYSCALL::WRITE,
//        fd,
//        brk_start,
//        heap_size,
//    );
//    FS::Sys::Close(fd);
//
//    print("[DEUBG] heap dump success\n");
//
//lab done;
//}
//
//use "lib/ht.yap"
//
//fn dump_ht(path, pattern, ht)
//{
//    put fd = FS::Sys::Open(path, 
//        FS::Mode::WRONLY |
//        FS::Mode::CREATE |
//        FS::Mode::TRUNC
//    );
//
//    static 4096 ~ qbuffer;
//    static 1024 ~ bbuffer;
//
//    put it = HT::MakeIter(ht);
//    lab loop;
//        jump done ~ Bool::Not(HT::Next(it));
//
//        Str::Format(qbuffer, pattern, [
//            it.HT::Iter::KEY,
//            it.HT::Iter::VALUE,
//        ]);
//
//        put char_count = Str::Len(qbuffer);
//        Mem::ToBytes(bbuffer, qbuffer, char_count);
//
//        Sys::TryCall(
//            "dump_ht",
//            SYSCALL::WRITE,
//            fd,
//            bbuffer,
//            char_count,
//        );
//
//        jump loop;
//    lab done;
//
//    FS::Sys::Close(fd);
//}
//
//
//
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
