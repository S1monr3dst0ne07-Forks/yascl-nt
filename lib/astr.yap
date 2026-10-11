
use "lib/dyn.yap"

fn AStr::Create()
{
	return Dyn::Create();
}

fn AStr::AppendBuffer(self, buf, len)
{
	put i = 0;
	lab loop;
		jump done ~ i == len;
		Dyn::Push(self, buf.i);
		put i = i + 1;
		jump loop;
	lab done;
}

fn AStr::AppendStr(self, str)
{
	AStr::AppendBuffer(self, str, Str::Len(str));
}

fn AStr::AppendChar(self, char)
{
	Dyn::Push(self, char);
}

fn AStr::AppendCharTimes(self, char, n)
{
	put i = 0;
	lab loop;
		jump done ~ i == n;
		put i = i + 1;

		AStr::AppendChar(self, char);
		jump loop;
	lab done;
}


fn AStr::DetachStr(self)
{
	put buffer = Dyn::Ptr(self);
	Chunk::Void(self);
	return buffer;
}

