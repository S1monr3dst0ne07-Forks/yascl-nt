
use "lib/net.yap"



seq Http::MethodKind
{
    GET,
    POST,
}

fn Http::GetMethodKind(string)
{
    jump skip_GET  ~ Str::Diff(string, "GET");  return Http::MethodKind::GET;  lab skip_GET;
    jump skip_POST ~ Str::Diff(string, "POST"); return Http::MethodKind::POST; lab skip_POST;
}

seq Http::Request
{
    METHOD,  
    PATH,
    PARAMS,
    //DATA,
}


seq Http::Config
{
    // i pray to shiva "let my buffers be sufficient!"
    // but shiva answered with segfault.
    RECV_BUFFER_SIZE = 1000000,
    SEND_BUFFER_SIZE = 1000000,
}

fn Http::LocalRecvMore(socket)
{
    static Http::Config::RECV_BUFFER_SIZE ~ buffer;
    put nbytes = Net::Read(socket, buffer, Http::Config::RECV_BUFFER_SIZE);
    jump error ~ Sys::Error(nbytes);
    put buffer.nbytes = '\0';
    return buffer;

lab error;
	return Mem::NULL;
}


fn Http::Recv(socket)
{
	put buffer = Http::LocalRecvMore(socket);
    jump error ~ buffer == Mem::NULL;
    put req    = Chunk::New(Http::Request);

    put method_string = buffer; put buffer = Str::Token(buffer, ' ');
    put path          = buffer; put buffer = Str::Token(buffer, ' ');
    put version       = buffer; put buffer = Str::Token(buffer, '\n');

    put table = HT::Create();

    put req.Http::Request::METHOD = Http::GetMethodKind(method_string);
    put req.Http::Request::PATH   = Str::Copy(path);
    put req.Http::Request::PARAMS = table;

    lab loop;
        jump more ~ (buffer.0) == '\0';
        jump done ~ (buffer.0) == '\n';
        jump done ~ (buffer.0) == '\r';

        put key   = buffer; put buffer = Str::Token(buffer, ':' ) : 1;
        put value = buffer; put buffer = Str::Token(buffer, '\r') : 1;

        HT::Set(table, key, Str::Copy(value));

        jump loop;
    lab done;

    return req;

lab more;
	put buffer = Http::LocalRecvMore(socket);
    jump error ~ buffer == Mem::NULL;
	jump loop;

lab error;
    return Mem::NULL;
}



fn Http::SendHeader(socket, status_code, params)
{
    static Http::Config::SEND_BUFFER_SIZE ~ buffer;
    put ptr = buffer;

    put ptr = Str::Format(ptr, "HTTP/1.1 %d\r\n", [status_code]);

    put it = HT::MakeIter(params);
    lab loop;
        jump done ~ Bool::Not(HT::Next(it));

        put ptr = Str::Format(ptr, "%s: %s\r\n", [
            it.HT::Iter::KEY,
            it.HT::Iter::VALUE,
        ]);

        jump loop;
    lab done;

    put ptr.0 = '\r';
    put ptr.1 = '\n';
    put ptr = ptr : 2;

    put header_length = (ptr - buffer) >> 3;
    Net::Write(socket, buffer, header_length);
}

fn Http::Send(socket, status_code, params, content, content_length)
{
    Http::SendHeader(socket, status_code, params);
    Net::Write(socket, content, content_length);
}


fn Http::VoidReq(req)
{
    put it = HT::MakeIter(req.Http::Request::PARAMS);
    lab loop;
        jump done ~ Bool::Not(HT::Next(it));
        Chunk::Void(it.HT::Iter::VALUE);
        jump loop;
    lab done;

    Chunk::Void(req.Http::Request::PATH);
    HT::Void(req.Http::Request::PARAMS);
    Chunk::Void(req);
}

fn Http::Unescape(src)
{
    put dst = Chunk::New(Str::Len(src));
    put dst_i = 0;

    lab loop;
        put char = src.0;
        put src = src : 1;
        jump done    ~ char == '\0';
        jump special ~ char == '%';

        put dst.dst_i = char;
        put dst_i = dst_i + 1;
        jump loop;

    lab special;
        put char = 0;

        put digits = "0123456789ABCDEF";
        put char = (char << 4) + Mem::Offset(digits, src.0, 16, 0);
        put char = (char << 4) + Mem::Offset(digits, src.1, 16, 0);
        put src = src : 2;

        put dst.dst_i = char;
        put dst_i = dst_i + 1;
        jump loop;

    lab done;
        put dst.dst_i = '\0';
        return dst; 
}

