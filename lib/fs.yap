
use "lib/chunk.yap"
use "lib/bool.yap"
use "lib/win.yap"

bind OpenFile    ~ "KERNEL32.DLL"
bind GetFileSize ~ "KERNEL32.DLL"
bind CloseHandle ~ "KERNEL32.DLL"


seq FS::Mode
{
	RDONLY = 0,
	WRONLY = 1,
	RDWR   = 2,
	CREATE = 4096,
}


fn FS::ConvertPath(qpath)
{
    static 4096 ~ bpath;
    Str::ToBytes(bpath, qpath);
    return bpath;
}

fn FS::Sys::DummyOFStruct()
{
	static 128 ~ struct;
	return struct;
}

fn FS::Sys::Open(path, mode)
{
	return OpenFile(
		FS::ConvertPath(path),
		FS::Sys::DummyOFStruct(),
		mode,
	);
}

fn FS::Read(path)
{
    put handle = FS::Sys::Open(path, FS::Mode::RDONLY);
    put size = GetFileSize(handle, Mem::NULL) + 1;

	// 8 times too big. doesn't matter, will get deallocated anyways.
    put bfile = Chunk::New(size); 
    put qfile = Chunk::New(size);

    Win::ReadFile(
    	handle,
    	bfile,
    	size,
    );

    Mem::FromBytes(qfile, bfile, size);

    Chunk::Void(bfile);
    CloseHandle(handle);

    put qfile.(size - 1) = 0;
    return qfile;
}



