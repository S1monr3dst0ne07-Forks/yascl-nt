

use "lib/mem.yap"

bind GetProcessHeap ~ "KERNEL32.DLL"
bind HeapAlloc      ~ "KERNEL32.DLL"
bind HeapFree       ~ "KERNEL32.DLL"


fn Chunk::Handle()
{
	static 1 ~ handle;
	jump present ~ handle.0;
		put handle.0 = GetProcessHeap();
	lab present;
	return handle.0;
}


fn Chunk::New(words)
{
	put handle = Chunk::Handle();
	return HeapAlloc(handle, 0, words * 8);
}

fn Chunk::Void(ptr)
{
	put handle = Chunk::Handle();
	HeapFree(handle, 0, ptr);

	
}

